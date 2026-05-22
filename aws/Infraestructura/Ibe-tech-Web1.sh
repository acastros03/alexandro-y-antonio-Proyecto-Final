#!/bin/bash
#==============================================================================
# Script de Aprovisionamiento: Web Server 1 (AWS)
# IP Privada: 10.0.2.123
# NFS:        10.0.3.240
#==============================================================================
set -e
hostnamectl set-hostname Ibe-tech-Web1.sh
export DEBIAN_FRONTEND=noninteractive
apt-get update -q && apt-get upgrade -y -q
apt-get install -y apache2 php libapache2-mod-php php-mysql php-cli nfs-common curl

mkdir -p /var/www/shared
chown www-data:www-data /var/www/shared

echo "Esperando servidor NFS en 10.0.3.240..."
for i in {1..60}; do
    if ping -c 1 -W 1 10.0.3.240 &>/dev/null; then
        echo "NFS alcanzable"
        break
    fi
    echo -n "."
    sleep 2
done

echo "10.0.3.240:/var/nfs/shared /var/www/shared nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" >> /etc/fstab
mount -a || echo "NFS no disponible aun, se montara automaticamente"

cat > /etc/apache2/sites-available/000-default.conf <<'EOF'
<VirtualHost *:80>
    ServerAdmin webmaster@ibe-tech.local
    DocumentRoot /var/www/shared
    <Directory /var/www/shared>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

a2enmod rewrite headers
systemctl restart apache2
systemctl enable apache2
echo "OK - Web Server 1 configurado. NFS: 10.0.3.240"