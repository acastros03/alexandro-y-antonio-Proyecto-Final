<?php
// ============================================================
// clientes.php — API para gestionar clientes
// GET /api/clientes.php          → lista todos los clientes
// GET /api/clientes.php?id=X     → detalle de un cliente
// POST /api/clientes.php         → crear cliente nuevo
// DELETE /api/clientes.php?id=X  → eliminar cliente y sus datos
// ============================================================

require_once __DIR__ . '/config/db.php';
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') jsonResponse([]);

$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : null;

try {
    // ---- LISTAR O VER DETALLE ----
    if ($method === 'GET') {
        $pdo = getReadConnection();

        // Si nos pasan un ID, devolvemos ese cliente con sus contratos e incidencias
        if ($id) {
            $stmt = $pdo->prepare("SELECT ID_Cliente, Nombre, CIF, Telefono, Direccion, Email FROM Cliente WHERE ID_Cliente = ?");
            $stmt->execute([$id]);
            $c = $stmt->fetch();
            if (!$c) errorResponse('Cliente no encontrado', 404);

            // Sus contratos
            $stmt = $pdo->prepare("
                SELECT c.ID_Contrato, c.Nombre, c.Fecha_inicio, c.Fecha_fin, c.Estado,
                       cat.Nombre_servicio, cat.Precio, e.Nombre AS Empleado
                FROM Contrato c
                JOIN Catalogo cat ON c.ID_Tipo_Servicio = cat.ID_Tipo_Servicio
                JOIN Empleado e   ON c.ID_Empleado = e.ID_Empleado
                WHERE c.ID_Cliente = ?
                ORDER BY c.Fecha_inicio DESC
            ");
            $stmt->execute([$id]);
            $contratos = $stmt->fetchAll();

            // Sus incidencias
            $stmt = $pdo->prepare("
                SELECT i.ID_Incidencia, i.Tipo, i.Descripcion, i.Severidad,
                       cont.Nombre AS Contrato
                FROM Incidencia i
                JOIN Contrato cont ON i.ID_Contrato = cont.ID_Contrato
                WHERE cont.ID_Cliente = ?
                ORDER BY i.ID_Incidencia DESC
            ");
            $stmt->execute([$id]);
            $incidencias = $stmt->fetchAll();

            jsonResponse(['cliente' => $c, 'contratos' => $contratos, 'incidencias' => $incidencias]);
        }

        // Si no, devolvemos todos (con filtro opcional por nombre o CIF)
        $q = trim($_GET['q'] ?? '');
        if ($q !== '') {
            $stmt = $pdo->prepare("SELECT ID_Cliente, Nombre, CIF, Telefono, Direccion, Email FROM Cliente WHERE Nombre LIKE ? OR CIF LIKE ? ORDER BY Nombre LIMIT 200");
            $like = "%$q%";
            $stmt->execute([$like, $like]);
        } else {
            $stmt = $pdo->query("SELECT ID_Cliente, Nombre, CIF, Telefono, Direccion, Email FROM Cliente ORDER BY Nombre LIMIT 200");
        }
        jsonResponse($stmt->fetchAll());
    }

    // ---- CREAR CLIENTE ----
    if ($method === 'POST') {
        $body     = json_decode(file_get_contents('php://input'), true) ?? [];
        $nombre   = trim($body['nombre'] ?? '');
        $cif      = trim($body['cif'] ?? '');
        $tel      = trim($body['telefono'] ?? '');
        $dir      = trim($body['direccion'] ?? '');
        $email    = trim($body['email'] ?? '');

        if (!$nombre || !$cif) errorResponse('Nombre y CIF son obligatorios');

        $pdo = getWriteConnection();

        // Comprobar que el CIF no esta repetido
        $check = $pdo->prepare("SELECT ID_Cliente FROM Cliente WHERE CIF = ?");
        $check->execute([$cif]);
        if ($check->fetch()) errorResponse('Ya existe un cliente con ese CIF', 409);

        // Generar contrasena aleatoria
        $password = substr(str_shuffle('abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789'), 0, 8);
        $hash = password_hash($password, PASSWORD_BCRYPT);

        $stmt = $pdo->prepare("INSERT INTO Cliente (Nombre, CIF, Telefono, Direccion, Email, Password_hash) VALUES (?,?,?,?,?,?)");
        $stmt->execute([$nombre, $cif, $tel, $dir, $email, $hash]);
        $id_nuevo = $pdo->lastInsertId();

        // Mandar correo si tiene email
        $correo_ok = false;
        if ($email) {
            require_once __DIR__ . '/config/mail.php';
            $correo_ok = correoRegistro($email, $nombre, $cif, $password);
        }

        jsonResponse(['ok' => true, 'id' => $id_nuevo, 'correo' => $correo_ok ? 'enviado' : 'sin email'], 201);
    }

    // ---- ELIMINAR CLIENTE ----
    if ($method === 'DELETE') {
        if (!$id) errorResponse('Falta el ID del cliente', 400);
        $pdo = getWriteConnection();

        // Borramos primero las incidencias (estan ligadas a contratos)
        $pdo->prepare("DELETE i FROM Incidencia i JOIN Contrato c ON i.ID_Contrato = c.ID_Contrato WHERE c.ID_Cliente = ?")->execute([$id]);
        // Luego los contratos
        $pdo->prepare("DELETE FROM Contrato WHERE ID_Cliente = ?")->execute([$id]);
        // Y finalmente el cliente
        $pdo->prepare("DELETE FROM Cliente WHERE ID_Cliente = ?")->execute([$id]);

        jsonResponse(['ok' => true]);
    }

    errorResponse('Metodo no permitido', 405);

} catch (PDOException $e) {
    errorResponse('Error en la base de datos: ' . $e->getMessage(), 500);
}