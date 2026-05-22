#!/bin/bash
#==============================================================================
# Script de Aprovisionamiento: HAProxy (AWS)
# IP Privada: 10.0.4.34
# BD1:        10.0.5.118
# BD2:        10.0.5.231
#==============================================================================
set -e
hostnamectl set-hostname Ibe-tech-ProxyBD
export DEBIAN_FRONTEND=noninteractive
apt-get update -q && apt-get upgrade -y -q
apt-get install -y haproxy socat curl

cat > /etc/haproxy/haproxy.cfg <<'EOF'
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

listen stats
    bind 10.0.4.34:8080
    mode http
    stats enable
    stats uri /stats
    stats realm HAProxy\ Statistics
    stats auth admin:ibetech2024
    stats refresh 10s
    stats show-legends
    stats show-node
    stats admin if TRUE

listen mysql-write
    bind 10.0.4.34:3306
    mode tcp
    option tcplog
    option mysql-check user haproxy_check
    balance leastconn
    server bd-primary   10.0.5.118:3306 check inter 3000 rise 2 fall 3 weight 100
    server bd-secondary 10.0.5.231:3306 check inter 3000 rise 2 fall 3 backup

listen mysql-read
    bind 10.0.4.34:3307
    mode tcp
    option tcplog
    option mysql-check user haproxy_check
    balance roundrobin
    server bd-primary   10.0.5.118:3306 check inter 3000 rise 2 fall 3 weight 100
    server bd-secondary 10.0.5.231:3306 check inter 3000 rise 2 fall 3 weight 100

frontend health_check
    bind 10.0.4.34:8888
    mode http
    monitor-uri /health
EOF

haproxy -c -f /etc/haproxy/haproxy.cfg
systemctl enable haproxy
systemctl restart haproxy

echo "OK - HAProxy configurado"
echo "Escritura: 10.0.4.34:3306 -> BD1(10.0.5.118) / BD2(10.0.5.231) backup"
echo "Lectura:   10.0.4.34:3307 -> BD1 + BD2 round-robin"
echo "Stats:     http://10.0.4.34:8080/stats  admin/ibetech2024"