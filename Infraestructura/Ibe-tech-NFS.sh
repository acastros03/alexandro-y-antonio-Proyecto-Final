#!/bin/bash
#==============================================================================
# Script de Aprovisionamiento: Servidor NFS (Debian Bookworm)
# Hostname: Ibe-tech-NFS
# Red 3 (Web Servers): 192.168.3.1
# Red 4 (ProxyBD): 192.168.4.1
#==============================================================================

set -e

echo "=========================================="
echo "Aprovisionando Servidor NFS"
echo "Hostname: Ibe-tech-NFS"
echo "=========================================="

# Actualizar sistema
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Instalar servidor NFS
echo "[1/5] Instalando servidor NFS..."
apt-get install -y nfs-kernel-server nfs-common

# Crear directorio de exportación NFS
echo "[2/5] Creando directorio de exportación..."
mkdir -p /var/nfs/shared
chown nobody:nogroup /var/nfs/shared
chmod 755 /var/nfs/shared

# Crear subdirectorios
mkdir -p /var/nfs/shared/{uploads,media,static,config}
chown -R nobody:nogroup /var/nfs/shared
chmod -R 755 /var/nfs/shared

# Configurar exportaciones NFS
echo "[3/5] Configurando exportaciones NFS..."
cat > /etc/exports <<'EOF'
# Exportación para servidores web (red 192.168.3.0/24)
/var/nfs/shared 192.168.3.0/24(rw,sync,no_subtree_check,no_root_squash)
EOF

# Aplicar configuración de exportaciones
exportfs -ra

# Crear contenido web principal
echo "[4/5] Creando contenido web compartido..."
cat > /var/nfs/shared/index.html <<'EOF'

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Infraestructura Ibe-tech</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1000px;
            margin: 0 auto;
        }

        .header {
            text-align: center;
            color: white;
            margin-bottom: 40px;
        }

        .header h1 {
            font-size: 3em;
            text-shadow: 3px 3px 6px rgba(0,0,0,0.3);
            margin-bottom: 10px;
        }

        .header p {
            font-size: 1.2em;
            opacity: 0.95;
        }

        .arquitectura {
            background: rgba(255,255,255,0.95);
            border-radius: 15px;
            padding: 35px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
        }

        .arquitectura h2 {
            color: #667eea;
            margin-bottom: 25px;
            text-align: center;
            font-size: 2em;
        }

        .capa {
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            padding: 18px;
            margin: 12px 0;
            border-radius: 12px;
            border-left: 5px solid #667eea;
        }

        .capa-titulo {
            font-weight: bold;
            color: #667eea;
            font-size: 1.2em;
            margin-bottom: 8px;
        }

        .capa-detalle {
            color: #444;
            font-size: 0.95em;
            margin: 3px 0;
        }
    </style>
</head>
<body>
    <div class="container">

        <div class="header">
            <h1>Infraestructura Ibe-tech</h1>
        </div>

        <div class="arquitectura">
            <h2>Arquitectura de Red - 5 Capas</h2>

            <div class="capa">
                <div class="capa-titulo">Capa 1: Balanceador de Carga (Nginx)</div>
                <div class="capa-detalle">• Hostname: Ibe-tech-Balanceador</div>
                <div class="capa-detalle">• IP Pública: 192.168.1.1</div>
                <div class="capa-detalle">• IP Privada: 192.168.2.1</div>
                <div class="capa-detalle">• Función: Distribuye tráfico HTTP entre servidores web</div>
            </div>

            <div class="capa">
                <div class="capa-titulo">Capa 2: Servidores Web (Apache + PHP)</div>
                <div class="capa-detalle">• Web Server 1: Ibe-tech-WEB1 (192.168.2.2 → 192.168.3.3)</div>
                <div class="capa-detalle">• Web Server 2: Ibe-tech-WEB2 (192.168.2.3 → 192.168.3.2)</div>
                <div class="capa-detalle">• Función: Procesamiento de aplicaciones web PHP</div>
            </div>

            <div class="capa">
                <div class="capa-titulo">Capa 3: Servidor de Archivos (NFS)</div>
                <div class="capa-detalle">• Hostname: Ibe-tech-NFS</div>
                <div class="capa-detalle">• IP Web: 192.168.3.1</div>
                <div class="capa-detalle">• IP Proxy: 192.168.4.1</div>
                <div class="capa-detalle">• Función: Almacenamiento compartido de archivos</div>
            </div>

            <div class="capa">
                <div class="capa-titulo">Capa 4: Balanceador de BD (HAProxy)</div>
                <div class="capa-detalle">• Hostname: Ibe-tech-proxy</div>
                <div class="capa-detalle">• IP NFS: 192.168.4.2</div>
                <div class="capa-detalle">• IP BD: 192.168.5.1</div>
                <div class="capa-detalle">• Función: Balanceo y alta disponibilidad de consultas SQL</div>
            </div>

            <div class="capa">
                <div class="capa-titulo">Capa 5: Bases de Datos (MariaDB)</div>
                <div class="capa-detalle">• BD Primary: Ibe-tech-BD1 (192.168.5.3)</div>
                <div class="capa-detalle">• BD Secondary: Ibe-tech-BD2 (192.168.5.2)</div>
                <div class="capa-detalle">• Función: Almacenamiento persistente con replicación</div>
            </div>
        </div>

    </div>
</body>
</html>
EOF

chown nobody:nogroup /var/nfs/shared/index.html

# Crear archivo de información
cat > /var/nfs/shared/README.txt <<EOF
Servidor NFS - Ibe-tech
=======================
Hostname: Ibe-tech-NFS
IP Web Servers: 192.168.3.1
IP ProxyBD: 192.168.4.1
Directorio: /var/nfs/shared
Red permitida: 192.168.3.0/24
Fecha: $(date)
EOF

# Configurar firewall
echo "[5/5] Configurando firewall..."
apt-get install -y iptables iptables-persistent

iptables -F
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s 192.168.3.0/24 -p tcp --dport 2049 -j ACCEPT
iptables -A INPUT -s 192.168.3.0/24 -p tcp --dport 111 -j ACCEPT
iptables -A INPUT -s 192.168.4.0/24 -j ACCEPT
netfilter-persistent save

# Reiniciar servicios NFS
systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server
systemctl enable rpcbind
systemctl restart rpcbind

echo ""
echo "=========================================="
echo "✅ Servidor NFS configurado"
echo "=========================================="
echo "Hostname: Ibe-tech-NFS"
echo "IP Web Servers: 192.168.3.1"
echo "IP ProxyBD: 192.168.4.1"
echo "Directorio exportado: /var/nfs/shared"
echo "Red permitida: 192.168.3.0/24"
echo ""
echo "Exportaciones activas:"
exportfs -v
echo "=========================================="