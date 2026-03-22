#!/bin/bash
#==============================================================================
# Script de Aprovisionamiento: Balanceador Nginx (Debian Bookworm)
# Hostname: Ibe-tech-Balanceador
# Red 1 (Pública): 192.168.1.1
# Red 2 (Web Servers): 192.168.2.1
#==============================================================================

set -e  # Salir si hay errores

echo "=========================================="
echo "Aprovisionando Balanceador Nginx"
echo "Hostname: Ibe-tech-Balanceador"
echo "=========================================="

# Actualizar sistema
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Instalar Nginx
echo "[1/5] Instalando Nginx..."
apt-get install -y nginx curl net-tools

# Habilitar IP forwarding
echo "[2/5] Habilitando IP forwarding..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Configurar Nginx como balanceador de carga
echo "[3/5] Configurando Nginx como balanceador..."
cat > /etc/nginx/nginx.conf <<'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
}

http {
    # Basic Settings
    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging Settings
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip Settings
    gzip on;

    # Upstream para los servidores web
    upstream web_backend {
        # Algoritmo Round Robin (por defecto en Nginx)
        server 192.168.2.2:80 max_fails=3 fail_timeout=30s;
        server 192.168.2.3:80 max_fails=3 fail_timeout=30s;
    }

    # Servidor principal
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
            
            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # Endpoint de salud del balanceador
        location /balancer-health {
            access_log off;
            return 200 "Balanceador OK - Ibe-tech\n";
            add_header Content-Type text/plain;
        }

        # Estadísticas básicas de Nginx
        location /nginx-status {
            stub_status on;
            access_log off;
            allow 192.168.0.0/16;
            allow 127.0.0.1;
            deny all;
        }
    }
}
EOF

# Verificar configuración de Nginx
echo "[4/5] Verificando configuración de Nginx..."
nginx -t

# Configurar firewall básico con iptables
echo "[5/5] Configurando firewall..."
apt-get install -y iptables iptables-persistent

# Limpiar reglas existentes
iptables -F
iptables -X

# Politicas por defecto
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Permitir trafico establecido
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permitir loopback
iptables -A INPUT -i lo -j ACCEPT

# Permitir SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Permitir HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Permitir desde red interna
iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT

# Guardar reglas
netfilter-persistent save

# Reiniciar Nginx
systemctl restart nginx
systemctl enable nginx

# Información final
echo ""
echo "=========================================="
echo "✅ Balanceador Nginx configurado"
echo "=========================================="
echo "Hostname: Ibe-tech-Balanceador"
echo "IP Red Pública: 192.168.1.1"
echo "IP Red Web: 192.168.2.1"
echo "Backend Servers: 192.168.2.2, 192.168.2.3"
echo ""
echo "Acceso:"
echo "  • http://192.168.1.1"
echo "  • http://localhost:8081 (desde host)"
echo "  • Estado: http://192.168.1.1/balancer-health"
echo "  • Stats: http://192.168.1.1/nginx-status"
echo "=========================================="