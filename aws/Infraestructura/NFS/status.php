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