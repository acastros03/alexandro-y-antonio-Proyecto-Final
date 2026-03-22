#!/bin/bash
#==============================================================================
# Script de Aprovisionamiento: Web Server 2 (Debian Bookworm)
# Hostname: Ibe-tech-WEB2
# Red 2 (Balanceador): 192.168.2.3
# Red 3 (NFS): 192.168.3.2
#==============================================================================

set -e

echo "=========================================="
echo "Aprovisionando Web Server 2"
echo "Hostname: Ibe-tech-WEB2"
echo "=========================================="

# Actualizar sistema
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Instalar Apache, PHP y cliente NFS
echo "[1/5] Instalando Apache, PHP y NFS client..."
apt-get install -y apache2 php libapache2-mod-php php-mysql php-cli nfs-common curl

# Crear directorio para montaje NFS
echo "[2/5] Configurando montaje NFS..."
mkdir -p /var/www/shared
chown www-data:www-data /var/www/shared

# Esperar a que el servidor NFS esté disponible
echo "Esperando servidor NFS..."
for i in {1..60}; do
    if ping -c 1 -W 1 192.168.3.1 &> /dev/null; then
        echo "✓ Servidor NFS alcanzable"
        break
    fi
    echo -n "."
    sleep 2
done

# Configurar montaje NFS automático
echo "192.168.3.1:/var/nfs/shared /var/www/shared nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" >> /etc/fstab

# Intentar montar NFS
mount -a || echo "⚠ NFS no disponible aún, se montará automáticamente"

# Configurar Apache para usar el directorio NFS
echo "[3/5] Configurando Apache..."
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

# Habilitar módulos de Apache
a2enmod rewrite
a2enmod headers

# Crear página de prueba local (fallback si NFS no está montado)
echo "[4/5] Creando contenido web..."
cat > /var/www/html/index.php <<'EOF'
<?php
$hostname = gethostname();
$server_ip = $_SERVER['SERVER_ADDR'];
$client_ip = $_SERVER['REMOTE_ADDR'];
$nfs_mounted = file_exists('/var/www/shared') && is_dir('/var/www/shared');
$nfs_files = $nfs_mounted ? count(scandir('/var/www/shared')) - 2 : 0;
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Web Server 2 - Ibe-tech</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #134E5E 0%, #71B280 100%);
            min-height: 100vh;
            padding: 40px 20px;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: rgba(255,255,255,0.95);
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.4);
        }
        h1 {
            color: #134E5E;
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
        }
        .server-badge {
            display: inline-block;
            padding: 10px 20px;
            background: #2196F3;
            color: white;
            border-radius: 25px;
            font-weight: bold;
            margin-left: 15px;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .info-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 12px;
            border-left: 4px solid #134E5E;
        }
        .info-card.success {
            border-left-color: #4CAF50;
        }
        .info-card.warning {
            border-left-color: #ff9800;
        }
        .info-label {
            font-weight: bold;
            color: #555;
            font-size: 0.9em;
            margin-bottom: 8px;
            text-transform: uppercase;
        }
        .info-value {
            color: #333;
            font-size: 1.2em;
            word-break: break-all;
        }
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 8px;
        }
        .status-ok {
            background: #4CAF50;
            box-shadow: 0 0 10px #4CAF50;
        }
        .status-error {
            background: #f44336;
            box-shadow: 0 0 10px #f44336;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid #e0e0e0;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>
            🖥️ Web Server 2
            <span class="server-badge">ONLINE</span>
        </h1>
        
        <div class="info-grid">
            <div class="info-card success">
                <div class="info-label">🏷️ Hostname</div>
                <div class="info-value"><?php echo $hostname; ?></div>
            </div>
            
            <div class="info-card">
                <div class="info-label">📡 IP del Servidor</div>
                <div class="info-value"><?php echo $server_ip; ?></div>
            </div>
            
            <div class="info-card">
                <div class="info-label">👤 IP del Cliente</div>
                <div class="info-value"><?php echo $client_ip; ?></div>
            </div>
            
            <div class="info-card <?php echo $nfs_mounted ? 'success' : 'warning'; ?>">
                <div class="info-label">📁 Estado NFS</div>
                <div class="info-value">
                    <span class="status-indicator <?php echo $nfs_mounted ? 'status-ok' : 'status-error'; ?>"></span>
                    <?php echo $nfs_mounted ? 'Montado (' . $nfs_files . ' archivos)' : 'No montado'; ?>
                </div>
            </div>
            
            <div class="info-card">
                <div class="info-label">⏰ Timestamp</div>
                <div class="info-value"><?php echo date('Y-m-d H:i:s'); ?></div>
            </div>
            
            <div class="info-card">
                <div class="info-label">📊 Carga del Sistema</div>
                <div class="info-value"><?php echo sys_getloadavg()[0]; ?></div>
            </div>
        </div>
        
        <div class="footer">
            <p><strong>Proyecto Ibe-tech</strong></p>
            <p>Infraestructura 5 Capas - Debian Bookworm</p>
            <p>Servidor Apache con PHP <?php echo phpversion(); ?></p>
        </div>
    </div>
</body>
</html>
EOF

# Configurar firewall
echo "[5/5] Configurando firewall..."
apt-get install -y iptables iptables-persistent

iptables -F
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -s 192.168.2.0/24 -j ACCEPT
iptables -A INPUT -s 192.168.3.0/24 -j ACCEPT
netfilter-persistent save

# Reiniciar Apache
systemctl restart apache2
systemctl enable apache2

echo ""
echo "=========================================="
echo "✅ Web Server 2 configurado"
echo "=========================================="
echo "Hostname: Ibe-tech-WEB2"
echo "IP Balanceador: 192.168.2.3"
echo "IP NFS: 192.168.3.2"
echo "Servidor NFS: 192.168.3.1"
echo "DocumentRoot: /var/www/shared"
echo ""
echo "Test local: curl http://localhost"
echo "=========================================="