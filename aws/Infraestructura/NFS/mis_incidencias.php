<?php
// ============================================================
// mis_incidencias.php — Devuelve las incidencias o contratos
// de un cliente especifico (para el panel de cliente)
// ============================================================

require_once __DIR__ . '/config/db.php';
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') jsonResponse([]);

$id_cliente = isset($_GET['id_cliente']) ? (int)$_GET['id_cliente'] : 0;
$tipo       = $_GET['tipo'] ?? 'incidencias'; // 'incidencias' o 'contratos'

if (!$id_cliente) errorResponse('Falta el ID del cliente', 400);

try {
    $pdo = getReadConnection();

    if ($tipo === 'contratos') {
        // Devolvemos los contratos del cliente
        $stmt = $pdo->prepare("
            SELECT c.ID_Contrato, c.Nombre, c.Fecha_inicio, c.Fecha_fin, c.Estado,
                   cat.Nombre_servicio
            FROM Contrato c
            JOIN Catalogo cat ON c.ID_Tipo_Servicio = cat.ID_Tipo_Servicio
            WHERE c.ID_Cliente = ?
            ORDER BY c.Fecha_inicio DESC
        ");
        $stmt->execute([$id_cliente]);
    } else {
        // Devolvemos las incidencias del cliente
        $stmt = $pdo->prepare("
            SELECT i.ID_Incidencia, i.Tipo, i.Descripcion, i.Severidad,
                   cont.Nombre AS Contrato
            FROM Incidencia i
            JOIN Contrato cont ON i.ID_Contrato = cont.ID_Contrato
            WHERE cont.ID_Cliente = ?
            ORDER BY i.ID_Incidencia DESC
        ");
        $stmt->execute([$id_cliente]);
    }

    jsonResponse($stmt->fetchAll());

} catch (PDOException $e) {
    errorResponse('Error en la base de datos: ' . $e->getMessage(), 500);
}