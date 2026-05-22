#!/bin/bash
#==============================================================================
# Script de Aprovisionamiento: BD1 PRIMARY (AWS)
# IP Privada: 10.0.5.118
# BD2:        10.0.5.231
#==============================================================================
set -e
hostnamectl set-hostname Ibe-tech-BD1
export DEBIAN_FRONTEND=noninteractive
apt-get update -q && apt-get upgrade -y -q
apt-get install -y mariadb-server mariadb-client curl

cat > /etc/mysql/mariadb.conf.d/99-ibe-tech.cnf <<'EOF'
[mysqld]
server-id       = 1
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

CREATE DATABASE IF NOT EXISTS iberotech CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE iberotech;

CREATE TABLE IF NOT EXISTS servers_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hostname VARCHAR(100) NOT NULL,
    ip_address VARCHAR(50) NOT NULL,
    server_role VARCHAR(50) NOT NULL,
    layer_number INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO servers_info (hostname, ip_address, server_role, layer_number) VALUES
('Ibe-tech-Balanceador', '10.0.1.28',  'NGINX_LB',           1),
('Ibe-tech-WEB1',        '10.0.2.123', 'WEBSERVER',          2),
('Ibe-tech-WEB2',        '10.0.2.87',  'WEBSERVER',          2),
('Ibe-tech-NFS',         '10.0.3.240', 'NFS_SERVER',         3),
('Ibe-tech-proxy',       '10.0.4.34',  'HAPROXY',            4),
('Ibe-tech-BD1',         '10.0.5.118', 'DATABASE_PRIMARY',   5),
('Ibe-tech-BD2',         '10.0.5.231', 'DATABASE_SECONDARY', 5);

CREATE TABLE IF NOT EXISTS app_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_level VARCHAR(20) NOT NULL,
    log_message TEXT NOT NULL,
    source_server VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO app_logs (log_level, log_message, source_server) VALUES
('INFO', 'Base de datos PRIMARY inicializada', 'Ibe-tech-BD1');

CREATE TABLE IF NOT EXISTS replication_test (
    id INT AUTO_INCREMENT PRIMARY KEY,
    test_data VARCHAR(255),
    created_on_server VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO replication_test (test_data, created_on_server) VALUES ('Test inicial', 'Ibe-tech-BD1');
SQL

mysql -e "SHOW MASTER STATUS\G" > /root/master_status.txt
echo "OK - BD1 PRIMARY configurada. IP: 10.0.5.118"
