#!/bin/bash

# ============================================================
#   GESTOR DE INFRAESTRUCTURA IBE-TECH - 5 CAPAS
# ============================================================

# ===== MÁQUINAS VIRTUALES =====
VM_BALANCEADOR="Ibe-tech-Balanceador"
VM_WEB1="Ibe-tech-WEB1"
VM_WEB2="Ibe-tech-WEB2"
VM_NFS="Ibe-tech-NFS"
VM_PROXY_BD="Ibe-tech-proxy"
VM_BD_PRIMARIA="Ibe-tech-BD1"
VM_BD_SECUNDARIA="Ibe-tech-BD2"

# ===== FUNCIONES BASE =====

# Comprueba si una VM esta encendida
vm_encendida() {
    vagrant status "$1" 2>/dev/null | grep -q "running"
}

# Ejecuta un comando en una VM por SSH
ejecutar_ssh() {
    local vm=$1
    local cmd=$2
    local clave=$(vagrant ssh-config "$vm" 2>/dev/null | grep IdentityFile | awk '{print $2}')
    local puerto=$(vagrant ssh-config "$vm" 2>/dev/null | grep Port | awk '{print $2}')
    [ -z "$clave" ] || [ -z "$puerto" ] && return 1
    ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$clave" -p "$puerto" vagrant@127.0.0.1 "$cmd"
}

# Muestra el estado de un servicio en una VM
comprobar_servicio() {
    local vm=$1
    local servicio=$2
    local etiqueta=$3

    echo -n "$etiqueta: "

    if ! vm_encendida "$vm"; then
        echo "VM APAGADA"
        return
    fi

    if ejecutar_ssh "$vm" "systemctl is-active $servicio" | grep -q "^active$"; then
        echo "ACTIVO"
    else
        echo "INACTIVO"
    fi
}

# ===== MENU PRINCIPAL =====
mostrar_menu() {
    echo "========================================"
    echo "   GESTOR DE INFRAESTRUCTURA IBE-TECH"
    echo "========================================"
    echo " 1) Estado de los servidores"
    echo " 2) Ver logs"
    echo " 3) Actualizar contenido web"
    echo " 4) Backup de emergencia"
    echo " 0) Salir"
    echo "========================================"
    read -r opcion
}

# ===== OPCION 1 - ESTADO =====
ver_estado() {
    echo "=== ESTADO DE LOS SERVIDORES ==="
    echo ""
    echo "-- Capa 1: Balanceador --"
    comprobar_servicio "$VM_BALANCEADOR" "nginx" "Nginx"
    echo ""
    echo "-- Capa 2: Servidores Web --"
    comprobar_servicio "$VM_WEB1" "apache2" "Apache WEB1"
    comprobar_servicio "$VM_WEB2" "apache2" "Apache WEB2"
    echo ""
    echo "-- Capa 3: Almacenamiento --"
    comprobar_servicio "$VM_NFS" "nfs-kernel-server" "NFS"
    echo ""
    echo "-- Capa 4: Proxy BD --"
    comprobar_servicio "$VM_PROXY_BD" "haproxy" "HAProxy"
    echo ""
    echo "-- Capa 5: Bases de Datos --"
    comprobar_servicio "$VM_BD_PRIMARIA" "mariadb" "MariaDB Primaria"
    comprobar_servicio "$VM_BD_SECUNDARIA" "mariadb" "MariaDB Secundaria"
    echo ""
    echo "-- Replicacion --"
    if vm_encendida "$VM_BD_SECUNDARIA"; then
        IO=$(ejecutar_ssh "$VM_BD_SECUNDARIA" "mysql -u root -pibetech2024 -e 'SHOW SLAVE STATUS\G' 2>/dev/null | grep -w 'Slave_IO_Running' | awk '{print \$2}'")
        SQL=$(ejecutar_ssh "$VM_BD_SECUNDARIA" "mysql -u root -pibetech2024 -e 'SHOW SLAVE STATUS\G' 2>/dev/null | grep -w 'Slave_SQL_Running' | awk '{print \$2}'")
        if [ "$IO" = "Yes" ] && [ "$SQL" = "Yes" ]; then
            echo "Replicacion: ACTIVA"
        else
            echo "Replicacion: INACTIVA (IO=$IO | SQL=$SQL)"
        fi
    else
        echo "Replicacion: BD Secundaria apagada"
    fi
    echo ""
    read -r _
}

# ===== OPCION 2 - LOGS =====
ver_logs() {
    while true; do
        echo "=== VISOR DE LOGS ==="
        echo " 1) Balanceador"
        echo " 2) Apache WEB1"
        echo " 3) Apache WEB2"
        echo " 4) HAProxy"
        echo " 5) MariaDB 1"
        echo " 6) MariaDB 2"
        echo " 7) Todos"
        echo " 0) Volver"
        read -r opcion_log

        case $opcion_log in
            1)
                echo "--- Balanceador ---"
                vagrant ssh "$VM_BALANCEADOR" -c "sudo tail -n 20 /var/log/nginx/access.log"
                read -r _
                ;;
            2)
                echo "--- Apache WEB1 ---"
                vagrant ssh "$VM_WEB1" -c "sudo tail -n 20 /var/log/apache2/error.log"
                read -r _
                ;;
            3)
                echo "--- Apache WEB2 ---"
                vagrant ssh "$VM_WEB2" -c "sudo tail -n 20 /var/log/apache2/error.log"
                read -r _
                ;;
            4)
                echo "--- HAProxy ---"
                vagrant ssh "$VM_PROXY_BD" -c "sudo journalctl -u haproxy -n 20 --no-pager"
                read -r _
                ;;
            5)
                echo "--- MariaDB 1 ---"
                vagrant ssh "$VM_BD_PRIMARIA" -c "sudo tail -n 20 /var/log/mysql/error.log"
                read -r _
                ;;
            6)
                echo "--- MariaDB 2 ---"
                vagrant ssh "$VM_BD_SECUNDARIA" -c "sudo tail -n 20 /var/log/mysql/error.log"
                read -r _
                ;;
            7)
                echo "=== TODOS LOS LOGS ==="
                echo ""
                echo "--- Balanceador ---"
                vagrant ssh "$VM_BALANCEADOR" -c "sudo tail -n 20 /var/log/nginx/access.log"
                echo ""
                echo "--- Apache WEB1 ---"
                vagrant ssh "$VM_WEB1" -c "sudo tail -n 5 /var/log/apache2/error.log"
                echo ""
                echo "--- Apache WEB2 ---"
                vagrant ssh "$VM_WEB2" -c "sudo tail -n 5 /var/log/apache2/error.log"
                echo ""
                echo "--- HAProxy ---"
                vagrant ssh "$VM_PROXY_BD" -c "sudo journalctl -u haproxy -n 5 --no-pager"
                echo ""
                echo "--- MariaDB 1 ---"
                vagrant ssh "$VM_BD_PRIMARIA" -c "sudo tail -n 5 /var/log/mysql/error.log"
                echo ""
                echo "--- MariaDB 2 ---"
                vagrant ssh "$VM_BD_SECUNDARIA" -c "sudo tail -n 5 /var/log/mysql/error.log"
                read -r _
                ;;
            0) return ;;
            *) echo "Opcion no valida."; sleep 1 ;;
        esac
    done
}

# ===== OPCION 3 - ACTUALIZAR WEB =====
actualizar_web() {
    echo "=== ACTUALIZAR CONTENIDO WEB ==="
    read -r ruta_archivo

    if [ ! -f "$ruta_archivo" ]; then
        echo "Error: archivo no encontrado."
        sleep 2
        return
    fi

    NOMBRE_ARCHIVO=$(basename "$ruta_archivo")
    local clave=$(vagrant ssh-config "$VM_NFS" 2>/dev/null | grep IdentityFile | awk '{print $2}')
    local puerto=$(vagrant ssh-config "$VM_NFS" 2>/dev/null | grep Port | awk '{print $2}')

    echo "Subiendo '$NOMBRE_ARCHIVO' al NFS..."
    scp -q -o StrictHostKeyChecking=no -i "$clave" -P "$puerto" \
        "$ruta_archivo" vagrant@127.0.0.1:/tmp/$NOMBRE_ARCHIVO

    ejecutar_ssh "$VM_NFS" "sudo mv /tmp/$NOMBRE_ARCHIVO /var/nfs/shared/index.html \
        && sudo chown nobody:nogroup /var/nfs/shared/index.html \
        && sudo chmod 644 /var/nfs/shared/index.html"

    echo "Reiniciando servidores web..."
    vagrant ssh "$VM_WEB1" -c "sudo systemctl restart apache2"
    vagrant ssh "$VM_WEB2" -c "sudo systemctl restart apache2"

    echo "Archivo subido: http://localhost:8081/"
    read -r _
}

# ===== OPCION 4 - BACKUP =====
backup_emergencia() {
    echo "=== BACKUP DE EMERGENCIA ==="
    read -r confirmacion
    if [ "$confirmacion" != "SI" ]; then
        echo "Cancelado."
        sleep 2
        return
    fi

    NOMBRE_BACKUP="backup_$(date +%Y%m%d_%H%M%S).sql"
    local clave=$(vagrant ssh-config "$VM_BD_PRIMARIA" 2>/dev/null | grep IdentityFile | awk '{print $2}')
    local puerto=$(vagrant ssh-config "$VM_BD_PRIMARIA" 2>/dev/null | grep Port | awk '{print $2}')

    echo "1. Creando volcado SQL en la BD Primaria..."
    ejecutar_ssh "$VM_BD_PRIMARIA" "mysqldump -u root -pibetech2024 --all-databases > /tmp/$NOMBRE_BACKUP"

    echo "2. Descargando backup a esta maquina..."
    mkdir -p ./backups
    scp -q -o StrictHostKeyChecking=no -i "$clave" -P "$puerto" \
        vagrant@127.0.0.1:/tmp/$NOMBRE_BACKUP ./backups/$NOMBRE_BACKUP

    echo "3. Limpiando temporal en la BD..."
    ejecutar_ssh "$VM_BD_PRIMARIA" "rm /tmp/$NOMBRE_BACKUP"

    echo "4. Eliminando backups antiguos (mas de 7 dias)..."
    find ./backups -name 'backup_*.sql' -mtime +7 -delete 2>/dev/null

    echo ""
    echo "Backup guardado en: ./backups/$NOMBRE_BACKUP"
    read -r _
}

# ===== INICIO =====
while true; do
    mostrar_menu
    case $opcion in
        1) ver_estado ;;
        2) ver_logs ;;
        3) actualizar_web ;; 
        4) backup_emergencia ;;
        0) echo "Adios."; exit 0 ;;
        *) echo "Opcion no valida."; sleep 1 ;;
    esac
done