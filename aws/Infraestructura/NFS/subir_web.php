<?php

session_start();
require_once __DIR__ . '/config/db.php';

if (!isset($_SESSION['rol']) || $_SESSION['rol'] === 'cliente') {
    errorResponse('No tienes permiso para hacer esto', 403);
}
if ($_SERVER['REQUEST_METHOD'] !== 'POST') errorResponse('Metodo no permitido', 405);

if (!isset($_FILES['html_file']) || $_FILES['html_file']['error'] !== UPLOAD_ERR_OK) {
    errorResponse('No se recibio el archivo correctamente', 400);
}

$extension = strtolower(pathinfo($_FILES['html_file']['name'], PATHINFO_EXTENSION));
if ($extension !== 'html') {
    errorResponse('Solo se permiten archivos .html', 400);
}

$destino = '/var/www/shared/index.html';

if (file_exists($destino)) {
    copy($destino, '/var/www/shared/backups/index_backup_' . date('Ymd_His') . '.html');
}

if (move_uploaded_file($_FILES['html_file']['tmp_name'], $destino)) {
    chmod($destino, 0644);
    jsonResponse(['ok' => true, 'mensaje' => 'Web actualizada. Ya pueden verla los usuarios.']);
} else {
    errorResponse("Error: " . error_get_last()["message"], 500);
}