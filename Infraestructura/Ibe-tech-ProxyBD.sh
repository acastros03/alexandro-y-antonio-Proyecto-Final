#!/bin/bash
#==============================================================================
# Script de Aprovisionamiento: HAProxy (Debian Bookworm)
# Hostname: Ibe-tech-proxy
# Red 4 (NFS): 192.168.4.2
# Red 5 (Bases de Datos): 192.168.5.1
#==============================================================================

set -e

echo "=========================================="
echo "Aprovisionando HAProxy"
echo "Hostname: Ibe-tech-proxy"
echo "=========================================="

# Actualizar sistema
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Instalar HAProxy y socat
echo "[1/4] Instalando HAProxy..."
apt-get install -y haproxy socat curl

# Configurar HAProxy para balanceo de bases de datos
echo "[2/4] Configurando HAProxy..."
cat > /etc/haproxy/haproxy.cfg <<'EOF'
#==============================================================================
# HAProxy Configuration - Ibe-tech Database Load Balancer
#==============================================================================

global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 10s
    timeout client  1m
    timeout server  1m
    timeout check   10s
    maxconn 3000

#==============================================================================
# HAProxy Statistics Dashboard
#==============================================================================
listen stats
    bind 192.168.4.2:8080
    mode http
    stats enable
    stats uri /stats
    stats realm HAProxy\ Statistics\ -\ Ibe-tech
    stats auth admin:ibetech2024
    stats refresh 10s
    stats show-legends
    stats show-node
    stats admin if TRUE

#==============================================================================
# MySQL/MariaDB Write Connections (Primary + Backup)
#==============================================================================
listen mysql-write
    bind 192.168.5.1:3306
    mode tcp
    option tcplog
    option mysql-check user haproxy_check
    balance leastconn
    
    # Servidor primario para escrituras
    server bd-primary 192.168.5.3:3306 check inter 3000 rise 2 fall 3 weight 100
    # Servidor secundario como backup
    server bd-secondary 192.168.5.2:3306 check inter 3000 rise 2 fall 3 backup

#==============================================================================
# MySQL/MariaDB Read Connections (Load Balanced)
#==============================================================================
listen mysql-read
    bind 192.168.5.1:3307
    mode tcp
    option tcplog
    option mysql-check user haproxy_check
    balance roundrobin
    
    # Balanceo entre ambos servidores para lecturas
    server bd-primary 192.168.5.3:3306 check inter 3000 rise 2 fall 3 weight 100
    server bd-secondary 192.168.5.2:3306 check inter 3000 rise 2 fall 3 weight 100

#==============================================================================
# Health Check Endpoint
#==============================================================================
frontend health_check
    bind 192.168.4.2:8888
    mode http
    monitor-uri /health

EOF

# Crear script de monitoreo
echo "[3/4] Creando scripts de monitoreo..."
cat > /usr/local/bin/haproxy-status.sh <<'MONITOR'
#!/bin/bash
echo "=========================================="
echo "HAProxy - Estado del Sistema"
echo "Proyecto: Ibe-tech"
echo "=========================================="
echo ""
echo "Estado del Servicio:"
systemctl status haproxy --no-pager | head -n 5
echo ""
echo "Servidores Backend MySQL:"
echo "show stat" | socat stdio /run/haproxy/admin.sock 2>/dev/null | \
    grep -E "bd-|mysql" | cut -d',' -f1,2,18,19 | column -t -s',' || echo "No disponible"
echo ""
echo "Conexiones Actuales:"
echo "show info" | socat stdio /run/haproxy/admin.sock 2>/dev/null | \
    grep -E "Curr|Max|Rate" || echo "No disponible"
echo ""
echo "=========================================="
echo "Dashboard Web: http://192.168.4.2:8080/stats"
echo "Usuario: admin | Contraseña: ibetech2024"
echo "Health Check: http://192.168.4.2:8888/health"
echo "=========================================="
MONITOR

chmod +x /usr/local/bin/haproxy-status.sh

# Crear script SQL para ejecutar en las bases de datos
cat > /root/create_haproxy_user.sql <<'SQL'
-- ============================================================================
-- Script para crear usuarios de HAProxy en las bases de datos
-- Ejecutar este script en AMBOS servidores: Ibe-tech-BD1 y Ibe-tech-BD2
-- ============================================================================

-- Usuario para health checks de HAProxy (sin password)
CREATE USER IF NOT EXISTS 'haproxy_check'@'%';
GRANT USAGE ON *.* TO 'haproxy_check'@'%';

-- Usuario para aplicaciones (con password)
CREATE USER IF NOT EXISTS 'app_user'@'192.168.%' IDENTIFIED BY 'ibetech2024';
GRANT ALL PRIVILEGES ON *.* TO 'app_user'@'192.168.%';

-- Crear base de datos principal
CREATE DATABASE IF NOT EXISTS ibe_tech_db;

FLUSH PRIVILEGES;

-- Verificar usuarios creados
SELECT User, Host FROM mysql.user WHERE User IN ('haproxy_check', 'app_user');

SHOW DATABASES;
SQL

# Configurar firewall
echo "[4/4] Configurando firewall..."
apt-get install -y iptables iptables-persistent

iptables -F
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s 192.168.4.0/24 -p tcp --dport 8080 -j ACCEPT  # Stats
iptables -A INPUT -s 192.168.4.0/24 -p tcp --dport 8888 -j ACCEPT  # Health
iptables -A INPUT -s 192.168.5.0/24 -j ACCEPT                       # BDs
iptables -A INPUT -s 192.168.3.0/24 -j ACCEPT                       # NFS
netfilter-persistent save

# Habilitar y reiniciar HAProxy
systemctl enable haproxy
systemctl restart haproxy

# Esperar a que HAProxy inicie
sleep 3

# Verificar configuración
haproxy -c -f /etc/haproxy/haproxy.cfg

echo ""
echo "=========================================="
echo "✅ HAProxy configurado exitosamente"
echo "=========================================="
echo "Hostname: Ibe-tech-proxy"
echo "IP NFS: 192.168.4.2"
echo "IP Bases de Datos: 192.168.5.1"
echo ""
echo "Servicios MySQL disponibles:"
echo "  📝 Escritura (Primary):   192.168.5.1:3306"
echo "  📖 Lectura (Balanceada):  192.168.5.1:3307"
echo ""
echo "Monitoreo:"
echo "  📊 Dashboard: http://192.168.4.2:8080/stats"
echo "  🔍 Usuario: admin"
echo "  🔑 Password: ibetech2024"
echo "  ❤️  Health: http://192.168.4.2:8888/health"
echo ""
echo "Script de estado: /usr/local/bin/haproxy-status.sh"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   Ejecutar /root/create_haproxy_user.sql"
echo "   en AMBOS servidores de base de datos"
echo "   (Ibe-tech-BD1 y Ibe-tech-BD2)"
echo "=========================================="