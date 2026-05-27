<?php
// ============================================================
// nueva_incidencia.php — El cliente crea una nueva incidencia
// ============================================================

session_start();
require_once __DIR__ . '/config/db.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') jsonResponse([]);
if ($_SERVER['REQUEST_METHOD'] !== 'POST') errorResponse('Metodo no permitido', 405);

$body        = json_decode(file_get_contents('php://input'), true) ?? [];
$tipo        = trim($body['tipo']        ?? '');
$descripcion = trim($body['descripcion'] ?? '');
$severidad   = trim($body['severidad']   ?? 'Media');
$id_contrato = (int)($body['id_contrato'] ?? 0);

if (!$tipo || !$descripcion || !$id_contrato) errorResponse('Faltan datos obligatorios', 400);
if (!in_array($severidad, ['Baja', 'Media', 'Alta'])) $severidad = 'Media';

try {
    $pdo = getWriteConnection();

    // Comprobamos que el contrato pertenece al cliente que esta logado
    // (para que un cliente no pueda meter incidencias en contratos de otro)
    if (isset($_SESSION['id'])) {
        $check = $pdo->prepare("SELECT ID_Contrato FROM Contrato WHERE ID_Contrato = ? AND ID_Cliente = ?");
        $check->execute([$id_contrato, $_SESSION['id']]);
        if (!$check->fetch()) errorResponse('Ese contrato no te pertenece', 403);
    }

    $stmt = $pdo->prepare("INSERT INTO Incidencia (Tipo, Descripcion, Severidad, ID_Contrato) VALUES (?,?,?,?)");
    $stmt->execute([$tipo, $descripcion, $severidad, $id_contrato]);

    jsonResponse(['ok' => true, 'id' => $pdo->lastInsertId()], 201);

} catch (PDOException $e) {
    errorResponse('Error en la base de datos: ' . $e->getMessage(), 500);
}