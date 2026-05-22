#!/bin/bash
#==============================================================================
# Script de Aprovisionamiento: NFS + API PHP (AWS)
# IP Privada: 10.0.3.240
# HAProxy:    10.0.4.34
#==============================================================================
set -e
hostnamectl set-hostname Ibe-tech-NFS.sh
export DEBIAN_FRONTEND=noninteractive
apt-get update -q && apt-get upgrade -y -q

echo "[1/5] Instalando NFS y PHP..."
apt-get install -y nfs-kernel-server nfs-common php php-mysql curl

echo "[2/5] Creando directorios..."
mkdir -p /var/nfs/shared/api/config
mkdir -p /var/nfs/shared/{uploads,media,static,backups}
chown -R nobody:nogroup /var/nfs/shared
chmod -R 755 /var/nfs/shared

echo "[3/5] Configurando exportaciones NFS..."
cat > /etc/exports <<'EOF'
/var/nfs/shared 10.0.2.0/24(rw,sync,no_subtree_check,no_root_squash)
EOF
exportfs -ra

echo "[4/5] Desplegando API PHP..."

cat > /var/nfs/shared/api/config/db.php <<'PHP'
<?php
define('DB_HOST_WRITE', '10.0.4.34');
define('DB_PORT_WRITE', 3306);
define('DB_HOST_READ',  '10.0.4.34');
define('DB_PORT_READ',  3307);
define('DB_USER', 'app_user');
define('DB_PASS', 'ibetech2024');
define('DB_NAME', 'iberotech');

function getWriteConnection(): PDO {
    $dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
        DB_HOST_WRITE, DB_PORT_WRITE, DB_NAME);
    return new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_TIMEOUT            => 5,
    ]);
}

function getReadConnection(): PDO {
    $dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
        DB_HOST_READ, DB_PORT_READ, DB_NAME);
    return new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_TIMEOUT            => 5,
    ]);
}

function jsonResponse(array $data, int $status = 200): void {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

function errorResponse(string $msg, int $status = 400): void {
    jsonResponse(['error' => $msg], $status);
}
PHP

cat > /var/nfs/shared/api/login.php <<'PHP'
<?php
require_once __DIR__ . '/config/db.php';
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') jsonResponse([]);
if ($_SERVER['REQUEST_METHOD'] !== 'POST') errorResponse('Metodo no permitido', 405);

$body   = json_decode(file_get_contents('php://input'), true) ?? [];
$nombre = trim($body['nombre']   ?? '');
$pass   = trim($body['password'] ?? '');
if ($nombre === '' || $pass === '') errorResponse('Nombre y contrasena requeridos');

try {
    $pdo = getReadConnection();
    $stmt = $pdo->prepare("SELECT ID_Empleado AS id, Nombre, Rol, Password_hash FROM Empleado WHERE Nombre = ? LIMIT 1");
    $stmt->execute([$nombre]);
    $user = $stmt->fetch();
    if ($user && password_verify($pass, $user['Password_hash'])) {
        jsonResponse(['ok'=>true,'id'=>$user['id'],'nombre'=>$user['Nombre'],'rol'=>$user['Rol']]);
    }
    $stmt = $pdo->prepare("SELECT ID_Cliente AS id, Nombre, Password_hash FROM Cliente WHERE Nombre = ? LIMIT 1");
    $stmt->execute([$nombre]);
    $cliente = $stmt->fetch();
    if ($cliente && password_verify($pass, $cliente['Password_hash'])) {
        jsonResponse(['ok'=>true,'id'=>$cliente['id'],'nombre'=>$cliente['Nombre'],'rol'=>'cliente']);
    }
    errorResponse('Credenciales incorrectas', 401);
} catch (PDOException $e) {
    errorResponse('Error BD: ' . $e->getMessage(), 500);
}
PHP

cat > /var/nfs/shared/api/clientes.php <<'PHP'
<?php
require_once __DIR__ . '/config/db.php';
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') jsonResponse([]);

$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : null;

try {
    if ($method === 'GET') {
        $pdo = getReadConnection();
        if ($id) {
            $stmt = $pdo->prepare("SELECT ID_Cliente,Nombre,CIF,Telefono,Direccion FROM Cliente WHERE ID_Cliente=?");
            $stmt->execute([$id]);
            $c = $stmt->fetch();
            if (!$c) errorResponse('No encontrado', 404);
            $stmt = $pdo->prepare("SELECT c.ID_Contrato,c.Nombre,c.Fecha_inicio,c.Fecha_fin,c.Estado,cat.Nombre_servicio,cat.Precio,e.Nombre AS Empleado FROM Contrato c JOIN Catalogo cat ON c.ID_Tipo_Servicio=cat.ID_Tipo_Servicio JOIN Empleado e ON c.ID_Empleado=e.ID_Empleado WHERE c.ID_Cliente=? ORDER BY c.Fecha_inicio DESC");
            $stmt->execute([$id]);
            $contratos = $stmt->fetchAll();
            $stmt = $pdo->prepare("SELECT i.ID_Incidencia,i.Tipo,i.Descripcion,i.Severidad,cont.Nombre AS Contrato FROM Incidencia i JOIN Contrato cont ON i.ID_Contrato=cont.ID_Contrato WHERE cont.ID_Cliente=? ORDER BY i.ID_Incidencia DESC");
            $stmt->execute([$id]);
            $incidencias = $stmt->fetchAll();
            jsonResponse(['cliente'=>$c,'contratos'=>$contratos,'incidencias'=>$incidencias]);
        }
        $q = trim($_GET['q'] ?? '');
        if ($q !== '') {
            $stmt = $pdo->prepare("SELECT ID_Cliente,Nombre,CIF,Telefono,Direccion FROM Cliente WHERE Nombre LIKE ? OR CIF LIKE ? ORDER BY Nombre LIMIT 50");
            $like = "%$q%";
            $stmt->execute([$like,$like]);
        } else {
            $stmt = $pdo->query("SELECT ID_Cliente,Nombre,CIF,Telefono,Direccion FROM Cliente ORDER BY Nombre LIMIT 100");
        }
        jsonResponse($stmt->fetchAll());
    }
    if ($method === 'POST') {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $nombre = trim($body['nombre'] ?? '');
        $cif    = trim($body['cif']    ?? '');
        $tel    = trim($body['telefono']  ?? '');
        $dir    = trim($body['direccion'] ?? '');
        if (!$nombre || !$cif) errorResponse('Nombre y CIF obligatorios');
        $pdo = getWriteConnection();
        $stmt = $pdo->prepare("INSERT INTO Cliente (Nombre,CIF,Telefono,Direccion,Password_hash) VALUES (?,?,?,?,?)");
        $stmt->execute([$nombre,$cif,$tel,$dir, password_hash('cliente123', PASSWORD_BCRYPT)]);
        jsonResponse(['ok'=>true,'id'=>$pdo->lastInsertId()], 201);
    }
    errorResponse('Metodo no permitido', 405);
} catch (PDOException $e) {
    errorResponse('Error BD: ' . $e->getMessage(), 500);
}
PHP

cat > /var/nfs/shared/api/contratos.php <<'PHP'
<?php
require_once __DIR__ . '/config/db.php';
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') jsonResponse([]);

try {
    $pdo = getReadConnection();
    if (isset($_GET['catalogo'])) {
        $stmt = $pdo->query("SELECT ID_Tipo_Servicio,Nombre_servicio,Descripcion,Precio FROM Catalogo ORDER BY Nombre_servicio");
        jsonResponse($stmt->fetchAll());
    }
    $stmt = $pdo->query("SELECT c.ID_Contrato,c.Nombre,c.Fecha_inicio,c.Fecha_fin,c.Estado,cl.Nombre AS Cliente,cat.Nombre_servicio,cat.Precio,e.Nombre AS Empleado FROM Contrato c JOIN Cliente cl ON c.ID_Cliente=cl.ID_Cliente JOIN Catalogo cat ON c.ID_Tipo_Servicio=cat.ID_Tipo_Servicio JOIN Empleado e ON c.ID_Empleado=e.ID_Empleado ORDER BY c.Fecha_inicio DESC");
    jsonResponse($stmt->fetchAll());
} catch (PDOException $e) {
    errorResponse('Error BD: ' . $e->getMessage(), 500);
}
PHP

cat > /var/nfs/shared/api/incidencias.php <<'PHP'
<?php
require_once __DIR__ . '/config/db.php';
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') jsonResponse([]);

try {
    $pdo = getReadConnection();
    $sev = trim($_GET['severidad'] ?? '');
    if ($sev) {
        $stmt = $pdo->prepare("SELECT i.ID_Incidencia,i.Tipo,i.Descripcion,i.Severidad,cl.Nombre AS Cliente,cont.Nombre AS Contrato FROM Incidencia i JOIN Contrato cont ON i.ID_Contrato=cont.ID_Contrato JOIN Cliente cl ON cont.ID_Cliente=cl.ID_Cliente WHERE i.Severidad=? ORDER BY i.ID_Incidencia DESC");
        $stmt->execute([$sev]);
    } else {
        $stmt = $pdo->query("SELECT i.ID_Incidencia,i.Tipo,i.Descripcion,i.Severidad,cl.Nombre AS Cliente,cont.Nombre AS Contrato FROM Incidencia i JOIN Contrato cont ON i.ID_Contrato=cont.ID_Contrato JOIN Cliente cl ON cont.ID_Cliente=cl.ID_Cliente ORDER BY i.ID_Incidencia DESC");
    }
    jsonResponse($stmt->fetchAll());
} catch (PDOException $e) {
    errorResponse('Error BD: ' . $e->getMessage(), 500);
}
PHP

cat > /var/nfs/shared/api/status.php <<'PHP'
<?php
require_once __DIR__ . '/config/db.php';
$result = ['timestamp' => date('Y-m-d H:i:s')];
try {
    $pdo = getWriteConnection();
    $pdo->query("SELECT 1");
    $result['db_write'] = ['ok'=>true,'host'=>DB_HOST_WRITE.':'.DB_PORT_WRITE];
} catch (Exception $e) {
    $result['db_write'] = ['ok'=>false,'host'=>DB_HOST_WRITE.':'.DB_PORT_WRITE,'error'=>$e->getMessage()];
}
try {
    $pdo = getReadConnection();
    $pdo->query("SELECT 1");
    $result['db_read'] = ['ok'=>true,'host'=>DB_HOST_READ.':'.DB_PORT_READ];
} catch (Exception $e) {
    $result['db_read'] = ['ok'=>false,'host'=>DB_HOST_READ.':'.DB_PORT_READ,'error'=>$e->getMessage()];
}
jsonResponse($result);
PHP

echo "[5/5] Copiando index.html y arrancando NFS..."

if [ -f /tmp/Base_web.html ]; then
    cp /tmp/Base_web.html /var/nfs/shared/index.html
else
    echo "<h1>IberoTech - Base_web.html no encontrado. Subelo con scp.</h1>" > /var/nfs/shared/index.html
fi
chown -R nobody:nogroup /var/nfs/shared

systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server
systemctl enable rpcbind
systemctl restart rpcbind

echo "OK - NFS + API PHP configurados"
echo "Exportacion: /var/nfs/shared -> 10.0.2.0/24"
echo "HAProxy BD:  10.0.4.34:3306 / :3307"