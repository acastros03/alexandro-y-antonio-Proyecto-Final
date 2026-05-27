<?php
session_start();
require_once __DIR__ . '/config/db.php';
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') jsonResponse([]);

// ---- DELETE: eliminar incidencia ----
if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    if (!isset($_SESSION['id'])) errorResponse('No autenticado', 401);
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if (!$id) errorResponse('Falta el ID de la incidencia', 400);

    try {
        $pdo = getWriteConnection();

        // Verificar que la incidencia pertenece al cliente
        if ($_SESSION['rol'] === 'cliente') {
            $check = $pdo->prepare("
                SELECT i.ID_Incidencia FROM Incidencia i
                JOIN Contrato c ON i.ID_Contrato = c.ID_Contrato
                WHERE i.ID_Incidencia = ? AND c.ID_Cliente = ?
            ");
            $check->execute([$id, $_SESSION['id']]);
            if (!$check->fetch()) errorResponse('Esa incidencia no te pertenece', 403);
        }

        // Borrar dependencias
        $pdo->prepare("DELETE FROM Accion    WHERE ID_Incidencia = ?")->execute([$id]);
        $pdo->prepare("DELETE FROM Atiende   WHERE ID_Incidencia = ?")->execute([$id]);
        $pdo->prepare("DELETE FROM Tipo_Inci WHERE ID_Incidencia = ?")->execute([$id]);
        $pdo->prepare("DELETE FROM Incidencia WHERE ID_Incidencia = ?")->execute([$id]);

        jsonResponse(['ok' => true]);
    } catch (PDOException $e) {
        errorResponse('Error BD: ' . $e->getMessage(), 500);
    }
}

// ---- GET: listar incidencias ----
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