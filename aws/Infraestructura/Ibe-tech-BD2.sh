#!/bin/bash
#==============================================================================
# Script de Aprovisionamiento: BD2 SECONDARY (AWS)
# IP Privada: 10.0.5.231
# BD1:        10.0.5.118
#==============================================================================
set -e
hostnamectl set-hostname Ibe-tech-BD2
export DEBIAN_FRONTEND=noninteractive
apt-get update -q && apt-get upgrade -y -q
apt-get install -y mariadb-server mariadb-client curl

cat > /etc/mysql/mariadb.conf.d/99-ibe-tech.cnf <<'EOF'
[mysqld]
server-id       = 2
bind-address    = 0.0.0.0
port            = 3306
character-set-server  = utf8mb4
collation-server      = utf8mb4_unicode_ci
innodb_buffer_pool_size = 256M
innodb_log_file_size    = 128M
innodb_flush_log_at_trx_commit = 2
max_connections   = 200
max_allowed_packet = 64M
log_error         = /var/log/mysql/error.log
log_bin           = /var/log/mysql/mysql-bin.log
expire_logs_days  = 7
max_binlog_size   = 100M
binlog_format     = ROW
relay-log         = /var/log/mysql/relay-bin
relay-log-index   = /var/log/mysql/relay-bin.index
read_only         = 1
EOF

mkdir -p /var/log/mysql && chown mysql:mysql /var/log/mysql
systemctl restart mariadb && systemctl enable mariadb
sleep 5

mysql --connect-timeout=30 <<'SQL'
ALTER USER 'root'@'localhost' IDENTIFIED BY 'ibetech2024';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
SQL

cat > /root/.my.cnf <<'CNF'
[client]
user=root
password=ibetech2024
CNF
chmod 600 /root/.my.cnf

mysql <<'SQL'
CREATE USER IF NOT EXISTS 'haproxy_check'@'%';
GRANT USAGE ON *.* TO 'haproxy_check'@'%';
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'ibetech2024';
GRANT ALL PRIVILEGES ON iberotech.* TO 'app_user'@'%';
CREATE USER IF NOT EXISTS 'repl_user'@'10.0.5.%' IDENTIFIED BY 'repl_pass_2024';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'10.0.5.%';
FLUSH PRIVILEGES;
SQL

echo "Esperando BD1 en 10.0.5.118..."
PRIMARY_UP=false
for i in $(seq 1 60); do
    if mysql -h 10.0.5.118 -u haproxy_check --connect-timeout=3 -e "SELECT 1;" &>/dev/null; then
        echo "BD1 alcanzable"
        PRIMARY_UP=true
        break
    fi
    echo -n "."
    sleep 3
done

MASTER_FILE=$(mysql -h 10.0.5.118 -u repl_user -prepl_pass_2024 -e "SHOW MASTER STATUS\G" 2>/dev/null | grep -w "File" | awk '{print $2}')
MASTER_POS=$(mysql  -h 10.0.5.118 -u repl_user -prepl_pass_2024 -e "SHOW MASTER STATUS\G" 2>/dev/null | grep -w "Position" | awk '{print $2}')

[ -z "$MASTER_FILE" ] && MASTER_FILE="mysql-bin.000001"
[ -z "$MASTER_POS"  ] && MASTER_POS=4

mysql <<SQLREPL
STOP SLAVE;
CHANGE MASTER TO
    MASTER_HOST='10.0.5.118',
    MASTER_USER='repl_user',
    MASTER_PASSWORD='repl_pass_2024',
    MASTER_LOG_FILE='${MASTER_FILE}',
    MASTER_LOG_POS=${MASTER_POS};
START SLAVE;
SQLREPL

sleep 3
echo "OK - BD2 SECONDARY configurada. IP: 10.0.5.231"
mysql -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Last_Error"