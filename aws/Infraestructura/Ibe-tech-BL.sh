#!/bin/bash
#==============================================================================
# Script de Aprovisionamiento: Balanceador Nginx (AWS)
# IP Privada:  10.0.1.28
#==============================================================================
set -e
hostnamectl set-hostname Ibe-tech-BL.sh
export DEBIAN_FRONTEND=noninteractive
apt-get update -q && apt-get upgrade -y -q
apt-get install -y nginx curl

cat > /etc/nginx/nginx.conf <<'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
events { worker_connections 1024; }
http {
    sendfile on; tcp_nopush on;
    types_hash_max_size 2048;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    gzip on;
    upstream web_backend {
        server 10.0.2.123:80 max_fails=3 fail_timeout=30s;
        server 10.0.2.87:80  max_fails=3 fail_timeout=30s;
    }
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;
        location / {
            proxy_pass http://web_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }
        location /balancer-health {
            access_log off;
            return 200 "Balanceador OK - Ibe-tech\n";
            add_header Content-Type text/plain;
        }
        location /nginx-status {
            stub_status on;
            access_log off;
            allow 10.0.0.0/8;
            allow 127.0.0.1;
            deny all;
        }
    }
}
EOF

nginx -t
systemctl restart nginx
systemctl enable nginx
echo "OK - Balanceador configurado."