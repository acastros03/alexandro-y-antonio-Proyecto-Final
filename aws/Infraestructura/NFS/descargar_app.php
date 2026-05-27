<?php
// ============================================================
// descargar_app.php — Descarga el zip con la app de escritorio
// Solo pueden descargarlo usuarios con sesion iniciada
// ============================================================

session_start();
if (!isset($_SESSION['rol'])) {
    header('Location: /index.html');
    exit;
}

$zip = '/var/www/shared/app/Iberotech_app.rar';

if (!file_exists($zip)) {
    http_response_code(404);
    echo 'La aplicacion no esta disponible todavia. Contacta con el administrador.';
    exit;
}

header('Content-Type: application/x-rar-compressed');
header('Content-Disposition: attachment; filename="IberoTech_App.rar"');
header('Content-Length: ' . filesize($zip));
readfile($zip);
exit;