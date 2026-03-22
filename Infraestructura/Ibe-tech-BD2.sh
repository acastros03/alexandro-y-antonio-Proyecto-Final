#!/bin/bash
#==============================================================================
# Script de Aprovisionamiento: Base de Datos 2 SECONDARY (Debian Bookworm)
# Hostname: Ibe-tech-BD2
# IP: 192.168.5.2
# Role: SECONDARY (Slave/Replica)
#==============================================================================

set -e

echo "=========================================="
echo "Aprovisionando Base de Datos SECONDARY"
echo "Hostname: Ibe-tech-BD2"
echo "=========================================="

# Actualizar sistema
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get upgrade -y -q

# Instalar MariaDB
echo "[1/6] Instalando MariaDB Server..."
apt-get install -y mariadb-server mariadb-client curl

# Configurar MariaDB
echo "[2/6] Configurando MariaDB como SECONDARY..."
cat > /etc/mysql/mariadb.conf.d/99-ibe-tech.cnf <<'EOF'
[mysqld]
# Server Configuration - SECONDARY (SLAVE)
server-id = 2
bind-address = 0.0.0.0
port = 3306

# Character Set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# InnoDB Settings
innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Connection Settings
max_connections = 200
max_allowed_packet = 64M
connect_timeout = 10
wait_timeout = 600

# Logging
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# Binary Logging
log_bin = /var/log/mysql/mysql-bin.log
expire_logs_days = 7
max_binlog_size = 100M
binlog_format = ROW

# Relay Log
relay-log = /var/log/mysql/relay-bin
relay-log-index = /var/log/mysql/relay-bin.index

# Solo lectura (replica)
read_only = 1
EOF

# Crear directorios de logs
mkdir -p /var/log/mysql
chown mysql:mysql /var/log/mysql

# Reiniciar MariaDB
echo "[3/6] Iniciando MariaDB..."
systemctl restart mariadb
systemctl enable mariadb

sleep 5

# Configuracion de seguridad (sin password todavia)
echo "[4/6] Configurando seguridad..."
mysql --connect-timeout=30 <<'SQLSEC'
ALTER USER 'root'@'localhost' IDENTIFIED BY 'ibetech2024';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
SQLSEC

# Guardar credenciales en fichero seguro
cat > /root/.my.cnf <<'MYCNF'
[client]
user=root
password=ibetech2024
MYCNF
chmod 600 /root/.my.cnf

# Crear usuarios
echo "[5/6] Creando usuarios..."
mysql <<'SQLUSERS'
-- Usuario para HAProxy health checks (sin password)
CREATE USER IF NOT EXISTS 'haproxy_check'@'%';
GRANT USAGE ON *.* TO 'haproxy_check'@'%';

-- Usuario de aplicacion (solo sobre la base de datos del proyecto)
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'ibetech2024';
GRANT ALL PRIVILEGES ON ibe_tech_db.* TO 'app_user'@'%';

-- Usuario de replicacion
CREATE USER IF NOT EXISTS 'repl_user'@'192.168.5.%' IDENTIFIED BY 'repl_pass_2024';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'192.168.5.%';

FLUSH PRIVILEGES;
SQLUSERS

# Esperar a que el servidor PRIMARY este disponible
echo "Esperando a que el servidor PRIMARY este disponible..."
PRIMARY_UP=false
for i in $(seq 1 60); do
    if mysql -h 192.168.5.3 -u haproxy_check --connect-timeout=3 -e "SELECT 1;" &>/dev/null; then
        echo "OK - Servidor PRIMARY alcanzable"
        PRIMARY_UP=true
        break
    fi
    echo -n "."
    sleep 3
done

if [ "$PRIMARY_UP" = false ]; then
    echo ""
    echo "AVISO: No se pudo contactar con PRIMARY. Configurando replicacion con posicion inicial."
    echo "Ejecute /root/restart-replication.sh manualmente tras levantar BD1."
fi

# Configurar replicacion automaticamente
echo "Configurando replicacion con PRIMARY..."
MASTER_FILE=$(mysql -h 192.168.5.3 -u repl_user -prepl_pass_2024 -e "SHOW MASTER STATUS\G" 2>/dev/null | grep -w "File" | awk '{print $2}')
MASTER_POS=$(mysql -h 192.168.5.3 -u repl_user -prepl_pass_2024 -e "SHOW MASTER STATUS\G" 2>/dev/null | grep -w "Position" | awk '{print $2}')

if [ -z "$MASTER_FILE" ] || [ -z "$MASTER_POS" ]; then
    echo "AVISO: No se pudo obtener posicion del PRIMARY. Usando valores por defecto."
    MASTER_FILE="mysql-bin.000001"
    MASTER_POS=4
fi

mysql <<SQLREPL
STOP SLAVE;

CHANGE MASTER TO
    MASTER_HOST='192.168.5.3',
    MASTER_USER='repl_user',
    MASTER_PASSWORD='repl_pass_2024',
    MASTER_LOG_FILE='${MASTER_FILE}',
    MASTER_LOG_POS=${MASTER_POS};

START SLAVE;
SQLREPL

sleep 3

# Crear script de informacion
cat > /root/db-info.sh <<'INFO'
#!/bin/bash
echo "=========================================="
echo "Ibe-tech-BD2 - Base de Datos SECONDARY"
echo "=========================================="
echo ""
echo "Estado de MariaDB:"
systemctl status mariadb --no-pager | head -n 5
echo ""
echo "Slave Status:"
mysql -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Master_Host|Master_Log_File|Seconds_Behind_Master|Last_Error"
echo ""
echo "Usuarios creados:"
mysql -e "SELECT User, Host FROM mysql.user WHERE User IN ('haproxy_check', 'app_user', 'repl_user');"
echo ""
echo "Bases de datos replicadas:"
mysql -e "SHOW DATABASES;"
echo "=========================================="
INFO
chmod +x /root/db-info.sh

# Script para reiniciar replicacion manualmente
cat > /root/restart-replication.sh <<'RESTART'
#!/bin/bash
echo "=========================================="
echo "Reiniciar Replicacion - Ibe-tech-BD2"
echo "=========================================="
echo ""
echo "Ejecute en PRIMARY: mysql -e 'SHOW MASTER STATUS\G'"
read -rp "MASTER_LOG_FILE (ej: mysql-bin.000001): " LOG_FILE
read -rp "MASTER_LOG_POS  (ej: 4): "               LOG_POS

mysql <<SQL
STOP SLAVE;
CHANGE MASTER TO
    MASTER_HOST='192.168.5.3',
    MASTER_USER='repl_user',
    MASTER_PASSWORD='repl_pass_2024',
    MASTER_LOG_FILE='${LOG_FILE}',
    MASTER_LOG_POS=${LOG_POS};
START SLAVE;
SHOW SLAVE STATUS\G
SQL

echo ""
echo "Replicacion reiniciada. Verifique el estado arriba."
echo "=========================================="
RESTART
chmod +x /root/restart-replication.sh

# Configurar firewall
echo "[6/6] Configurando firewall..."
apt-get install -y iptables iptables-persistent

iptables -F
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s 192.168.5.0/24 -p tcp --dport 3306 -j ACCEPT
iptables -A INPUT -s 192.168.4.0/24 -p tcp --dport 3306 -j ACCEPT
iptables -A INPUT -s 192.168.3.0/24 -p tcp --dport 3306 -j ACCEPT
netfilter-persistent save

# Verificar estado de replicacion
SLAVE_IO=$(mysql -e "SHOW SLAVE STATUS\G" 2>/dev/null | awk '/Slave_IO_Running/{print $2}')
SLAVE_SQL=$(mysql -e "SHOW SLAVE STATUS\G" 2>/dev/null | awk '/Slave_SQL_Running/{print $2}')

echo ""
echo "=========================================="
echo "OK - Base de Datos SECONDARY configurada"
echo "=========================================="
echo "Hostname : Ibe-tech-BD2"
echo "IP       : 192.168.5.2"
echo "Role     : SECONDARY (Slave/Replica)"
echo ""
echo "Credenciales:"
echo "  Root       : root / ibetech2024"
echo "  App User   : app_user / ibetech2024"
echo "  Replication: repl_user / repl_pass_2024"
echo "  HAProxy    : haproxy_check / (sin password)"
echo ""
echo "Estado de Replicacion:"
echo "  Slave IO Running : $SLAVE_IO"
echo "  Slave SQL Running: $SLAVE_SQL"

if [ "$SLAVE_IO" = "Yes" ] && [ "$SLAVE_SQL" = "Yes" ]; then
    echo "  Replicacion funcionando correctamente"
else
    echo "  AVISO: Replicacion no activa todavia"
    echo "  Si BD1 no estaba levantada al aprovisionar, ejecute:"
    echo "    /root/restart-replication.sh"
fi

echo ""
echo "Scripts disponibles:"
echo "  Informacion       : /root/db-info.sh"
echo "  Reiniciar replica : /root/restart-replication.sh"
echo "=========================================="