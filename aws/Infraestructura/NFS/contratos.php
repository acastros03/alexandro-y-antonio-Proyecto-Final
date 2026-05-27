<?php

session_start();
require_once __DIR__ . '/config/db.php';
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') jsonResponse([]);

$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : null;

try {

    // ---- GET ----
    if ($method === 'GET') {
        $pdo = getReadConnection();

        // Devuelve el catálogo de servicios disponibles
        if (isset($_GET['catalogo'])) {
            $stmt = $pdo->query("SELECT ID_Tipo_Servicio, Nombre_servicio, Descripcion, Precio FROM Catalogo ORDER BY Nombre_servicio");
            jsonResponse($stmt->fetchAll());
        }

        // Devuelve contratos de un cliente concreto
        if (isset($_GET['id_cliente'])) {
            $id_cliente = (int)$_GET['id_cliente'];
            $stmt = $pdo->prepare("
                SELECT c.ID_Contrato, c.Nombre, c.Fecha_inicio, c.Fecha_fin, c.Estado,
                       cat.Nombre_servicio, cat.Descripcion AS Descripcion_servicio, cat.Precio,
                       e.Nombre AS Empleado
                FROM Contrato c
                JOIN Catalogo cat ON c.ID_Tipo_Servicio = cat.ID_Tipo_Servicio
                JOIN Empleado e   ON c.ID_Empleado      = e.ID_Empleado
                WHERE c.ID_Cliente = ?
                ORDER BY c.Fecha_inicio DESC
            ");
            $stmt->execute([$id_cliente]);
            jsonResponse($stmt->fetchAll());
        }

        // Lista todos los contratos (panel admin)
        $stmt = $pdo->query("
            SELECT c.ID_Contrato, c.Nombre, c.Fecha_inicio, c.Fecha_fin, c.Estado,
                   cl.Nombre AS Cliente, cat.Nombre_servicio, cat.Precio,
                   e.Nombre AS Empleado
            FROM Contrato c
            JOIN Cliente  cl  ON c.ID_Cliente       = cl.ID_Cliente
            JOIN Catalogo cat ON c.ID_Tipo_Servicio  = cat.ID_Tipo_Servicio
            JOIN Empleado e   ON c.ID_Empleado       = e.ID_Empleado
            ORDER BY c.Fecha_inicio DESC
        ");
        jsonResponse($stmt->fetchAll());
    }

    // ---- POST: crear contrato ----
    if ($method === 'POST') {
        // Solo clientes autenticados (o admins) pueden crear contratos
        if (!isset($_SESSION['id'])) errorResponse('No autenticado', 401);

        $body            = json_decode(file_get_contents('php://input'), true) ?? [];
        $nombre          = trim($body['nombre']          ?? '');
        $id_tipo_servicio = (int)($body['id_tipo_servicio'] ?? 0);
        $fecha_inicio    = trim($body['fecha_inicio']    ?? date('Y-m-d'));

        // El id_cliente lo sacamos de la sesión (si es cliente) o del body (si es admin)
        if ($_SESSION['rol'] === 'cliente') {
            $id_cliente = (int)$_SESSION['id'];
        } else {
            $id_cliente = (int)($body['id_cliente'] ?? 0);
        }

        if (!$nombre || !$id_tipo_servicio || !$id_cliente) {
            errorResponse('Nombre, servicio y cliente son obligatorios', 400);
        }

        $pdo = getWriteConnection();

        // Verificamos que el tipo de servicio existe
        $check = $pdo->prepare("SELECT ID_Tipo_Servicio FROM Catalogo WHERE ID_Tipo_Servicio = ?");
        $check->execute([$id_tipo_servicio]);
        if (!$check->fetch()) errorResponse('Servicio no encontrado en el catálogo', 404);

        // Asignamos automáticamente al empleado con menos contratos activos
        $emp = $pdo->query("
            SELECT e.ID_Empleado
            FROM Empleado e
            LEFT JOIN Contrato c ON c.ID_Empleado = e.ID_Empleado AND c.Estado = 'Activo'
            WHERE e.Rol != 'Administrador'
            GROUP BY e.ID_Empleado
            ORDER BY COUNT(c.ID_Contrato) ASC
            LIMIT 1
        ")->fetch();

        // Si no hay empleados técnicos, usamos el 1 (Antonio)
        $id_empleado = $emp ? (int)$emp['ID_Empleado'] : 1;

        $stmt = $pdo->prepare("
            INSERT INTO Contrato (Nombre, Fecha_inicio, Estado, ID_Cliente, ID_Empleado, ID_Tipo_Servicio)
            VALUES (?, ?, 'Activo', ?, ?, ?)
        ");
        $stmt->execute([$nombre, $fecha_inicio, $id_cliente, $id_empleado, $id_tipo_servicio]);

        jsonResponse(['ok' => true, 'id' => $pdo->lastInsertId()], 201);
    }

    // ---- DELETE: cancelar contrato ----
    if ($method === 'DELETE') {
        if (!isset($_SESSION['id'])) errorResponse('No autenticado', 401);
        if (!$id) errorResponse('Falta el ID del contrato', 400);

        $pdo = getWriteConnection();

        // Si es cliente, verificamos que el contrato le pertenece
        if ($_SESSION['rol'] === 'cliente') {
            $check = $pdo->prepare("SELECT ID_Contrato FROM Contrato WHERE ID_Contrato = ? AND ID_Cliente = ?");
            $check->execute([$id, $_SESSION['id']]);
            if (!$check->fetch()) errorResponse('Ese contrato no te pertenece', 403);
        }

        // Primero recogemos los IDs de incidencias de este contrato
        $stmt = $pdo->prepare("SELECT ID_Incidencia FROM Incidencia WHERE ID_Contrato = ?");
        $stmt->execute([$id]);
        $incidencias = $stmt->fetchAll(PDO::FETCH_COLUMN);

        // Borramos dependencias de cada incidencia
        if (!empty($incidencias)) {
            $placeholders = implode(',', array_fill(0, count($incidencias), '?'));
            $pdo->prepare("DELETE FROM Accion    WHERE ID_Incidencia IN ($placeholders)")->execute($incidencias);
            $pdo->prepare("DELETE FROM Atiende   WHERE ID_Incidencia IN ($placeholders)")->execute($incidencias);
            $pdo->prepare("DELETE FROM Tipo_Inci WHERE ID_Incidencia IN ($placeholders)")->execute($incidencias);
            $pdo->prepare("DELETE FROM Incidencia WHERE ID_Incidencia IN ($placeholders)")->execute($incidencias);
        }

        // Finalmente borramos el contrato
        $pdo->prepare("DELETE FROM Contrato WHERE ID_Contrato = ?")->execute([$id]);

        jsonResponse(['ok' => true]);
    }

    errorResponse('Método no permitido', 405);

} catch (PDOException $e) {
    errorResponse('Error en la base de datos: ' . $e->getMessage(), 500);
}