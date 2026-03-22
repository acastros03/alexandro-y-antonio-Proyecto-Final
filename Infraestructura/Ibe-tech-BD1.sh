#!/bin/bash
#==============================================================================
# Script de Aprovisionamiento: Base de Datos 1 PRIMARY (Debian Bookworm)
# Hostname: Ibe-tech-BD1
# IP: 192.168.5.3
# Role: PRIMARY (Master)
#==============================================================================

set -e

echo "=========================================="
echo "Aprovisionando Base de Datos PRIMARY"
echo "Hostname: Ibe-tech-BD1"
echo "=========================================="

# Actualizar sistema
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get upgrade -y -q

# Instalar MariaDB
echo "[1/6] Instalando MariaDB Server..."
apt-get install -y mariadb-server mariadb-client curl

# Configurar MariaDB
echo "[2/6] Configurando MariaDB como PRIMARY..."
cat > /etc/mysql/mariadb.conf.d/99-ibe-tech.cnf <<'EOF'
[mysqld]
# Server Configuration - PRIMARY
server-id = 1
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

# Binary Logging (para replicacion)
log_bin = /var/log/mysql/mysql-bin.log
expire_logs_days = 7
max_binlog_size = 100M
binlog_format = ROW

# Relay Log
relay-log = /var/log/mysql/relay-bin
relay-log-index = /var/log/mysql/relay-bin.index
EOF

# Crear directorios de logs
mkdir -p /var/log/mysql
chown mysql:mysql /var/log/mysql

# Reiniciar MariaDB
echo "[3/6] Iniciando MariaDB..."
systemctl restart mariadb
systemctl enable mariadb

sleep 5

# Configuracion de seguridad basica (sin password todavia)
echo "[4/6] Configurando seguridad..."
mysql --connect-timeout=30 <<'SQLSEC'
ALTER USER 'root'@'localhost' IDENTIFIED BY 'ibetech2024';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
SQLSEC

# Guardar credenciales en fichero seguro para no exponerlas en comandos
cat > /root/.my.cnf <<'MYCNF'
[client]
user=root
password=ibetech2024
MYCNF
chmod 600 /root/.my.cnf

# Crear usuarios y base de datos
echo "[5/6] Creando usuarios y base de datos..."
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

-- Crear base de datos principal
CREATE DATABASE IF NOT EXISTS ibe_tech_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ibe_tech_db;

-- Tabla de informacion de servidores
CREATE TABLE IF NOT EXISTS servers_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(100) NOT NULL,
    ip_address VARCHAR(50) NOT NULL,
    server_role VARCHAR(50) NOT NULL,
    layer_number INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_role (server_role),
    INDEX idx_layer (layer_number)
) ENGINE=InnoDB;

-- Insertar datos de la infraestructura
INSERT INTO servers_info (hostname, ip_address, server_role, layer_number) VALUES
('Ibe-tech-Balanceador', '192.168.1.1',  'NGINX_LB',           1),
('Ibe-tech-WEB1',        '192.168.2.2',  'WEBSERVER',          2),
('Ibe-tech-WEB2',        '192.168.2.3',  'WEBSERVER',          2),
('Ibe-tech-NFS',         '192.168.3.1',  'NFS_SERVER',         3),
('Ibe-tech-proxy',       '192.168.5.1',  'HAPROXY',            4),
('Ibe-tech-BD1',         '192.168.5.3',  'DATABASE_PRIMARY',   5),
('Ibe-tech-BD2',         '192.168.5.2',  'DATABASE_SECONDARY', 5);

-- Tabla de logs de aplicacion
CREATE TABLE IF NOT EXISTS app_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_level VARCHAR(20) NOT NULL,
    log_message TEXT NOT NULL,
    source_server VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_level (log_level),
    INDEX idx_created (created_at)
) ENGINE=InnoDB;

-- Log inicial
INSERT INTO app_logs (log_level, log_message, source_server) VALUES
('INFO', 'Base de datos PRIMARY inicializada correctamente', 'Ibe-tech-BD1'),
('INFO', 'Tablas creadas y datos iniciales insertados', 'Ibe-tech-BD1');

-- Tabla de pruebas de replicacion
CREATE TABLE IF NOT EXISTS replication_test (
    id INT AUTO_INCREMENT PRIMARY KEY,
    test_data VARCHAR(255),
    created_on_server VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO replication_test (test_data, created_on_server) VALUES
('Test inicial de replicacion', 'Ibe-tech-BD1');
SQLUSERS

# Guardar master status para configurar el slave
mysql -e "SHOW MASTER STATUS\G" > /root/master_status.txt

# Crear script de informacion
cat > /root/db-info.sh <<'INFO'
#!/bin/bash
echo "=========================================="
echo "Ibe-tech-BD1 - Base de Datos PRIMARY"
echo "=========================================="
echo ""
echo "Estado de MariaDB:"
systemctl status mariadb --no-pager | head -n 5
echo ""
echo "Master Status:"
mysql -e "SHOW MASTER STATUS\G"
echo ""
echo "Bases de datos:"
mysql -e "SHOW DATABASES;"
echo ""
echo "Usuarios creados:"
mysql -e "SELECT User, Host FROM mysql.user WHERE User IN ('haproxy_check', 'app_user', 'repl_user');"
echo ""
echo "Servidores registrados:"
mysql -e "SELECT hostname, ip_address, server_role FROM ibe_tech_db.servers_info;"
echo "=========================================="
INFO
chmod +x /root/db-info.sh

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

echo ""
echo "=========================================="
echo "OK - Base de Datos PRIMARY configurada"
echo "=========================================="
echo "Hostname : Ibe-tech-BD1"
echo "IP       : 192.168.5.3"
echo "Role     : PRIMARY (Master)"
echo ""
echo "Credenciales:"
echo "  Root       : root / ibetech2024"
echo "  App User   : app_user / ibetech2024"
echo "  Replication: repl_user / repl_pass_2024"
echo "  HAProxy    : haproxy_check / (sin password)"
echo ""
echo "Script de informacion: /root/db-info.sh"
echo "=========================================="