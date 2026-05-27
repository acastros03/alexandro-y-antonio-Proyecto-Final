<?php
// ============================================================
// csv.php — Devuelve los datos de los CSV al panel de admin
// Los CSV estan en /var/nfs/shared/data/
// ============================================================

require_once __DIR__ . '/config/db.php';

$tipo = $_GET['tipo'] ?? 'clientes';

$archivos = [
    'clientes'    => '/var/nfs/shared/data/Clientes.csv',
    'incidencias' => '/var/nfs/shared/data/Incidencias.csv',
    'precios'     => '/var/nfs/shared/data/Automatizacion_Precio.csv',
];

if (!isset($archivos[$tipo])) errorResponse('Tipo de CSV no valido', 400);

$ruta = $archivos[$tipo];
if (!file_exists($ruta)) errorResponse('El archivo CSV no existe en el servidor', 404);

// Leemos el CSV y lo convertimos en array de objetos
$handle   = fopen($ruta, 'r');
$cabeceras = fgetcsv($handle);
$datos    = [];
while (($fila = fgetcsv($handle)) !== false) {
    $datos[] = array_combine($cabeceras, $fila);
}
fclose($handle);

jsonResponse($datos);