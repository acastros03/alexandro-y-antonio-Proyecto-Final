<?php
define('DB_HOST_WRITE', '10.0.3.240');
define('DB_PORT_WRITE', 3306);
define('DB_HOST_READ',  '10.0.3.240');
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

function iniciarSesionBD(): void {
    session_set_save_handler(
        function($path, $name) { return true; },
        function() { return true; },
        function($id) {
            try {
                $pdo = getReadConnection();
                $stmt = $pdo->prepare("SELECT data FROM php_sessions WHERE id=? AND last_activity > ?");
                $stmt->execute([$id, time() - 7200]);
                $row = $stmt->fetch();
                return $row ? $row['data'] : '';
            } catch(Exception $e) { return ''; }
        },
        function($id, $data) {
            try {
                $pdo = getWriteConnection();
                $stmt = $pdo->prepare("REPLACE INTO php_sessions (id, data, last_activity) VALUES (?,?,?)");
                $stmt->execute([$id, $data, time()]);
                return true;
            } catch(Exception $e) { return false; }
        },
        function($id) {
            try {
                $pdo = getWriteConnection();
                $pdo->prepare("DELETE FROM php_sessions WHERE id=?")->execute([$id]);
                return true;
            } catch(Exception $e) { return false; }
        },
        function($max) {
            try {
                $pdo = getWriteConnection();
                $pdo->prepare("DELETE FROM php_sessions WHERE last_activity < ?")->execute([time() - $max]);
                return true;
            } catch(Exception $e) { return false; }
        }
    );
    session_start();
}