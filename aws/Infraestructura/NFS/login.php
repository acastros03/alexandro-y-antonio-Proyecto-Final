<?php
session_start();
// ============================================================
// login.php — Comprueba las credenciales contra la base de datos
// Empleados entran con su Nombre, Clientes con su CIF
// ============================================================

require_once __DIR__ . '/config/db.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') jsonResponse([]);
if ($_SERVER['REQUEST_METHOD'] !== 'POST') errorResponse('Metodo no permitido', 405);

// Recibimos los datos del formulario
$body = json_decode(file_get_contents('php://input'), true) ?? [];
$user = trim($body['nombre']   ?? '');
$pass = trim($body['password'] ?? '');

if (!$user || !$pass) errorResponse('Usuario y contrasena requeridos');

try {
    $pdo = getReadConnection();

    // Primero buscamos en la tabla Empleado por nombre
    $stmt = $pdo->prepare("SELECT ID_Empleado AS id, Nombre, Rol, Password_hash FROM Empleado WHERE Nombre = ? LIMIT 1");
    $stmt->execute([$user]);
    $empleado = $stmt->fetch();
    if ($empleado && password_verify($pass, $empleado['Password_hash'])) {
        // Es un empleado/admin — guardamos su sesion
        $_SESSION['id']     = $empleado['id'];
        $_SESSION['nombre'] = $empleado['Nombre'];
        $_SESSION['rol']    = $empleado['Rol'];
        jsonResponse([
            'ok'       => true,
            'nombre'   => $empleado['Nombre'],
            'rol'      => $empleado['Rol'],
            'redirect' => '/admin.php'  // va al panel de administrador
        ]);
    }

    // Si no es empleado, buscamos en Cliente por CIF
    $stmt = $pdo->prepare("SELECT ID_Cliente AS id, Nombre, CIF, Password_hash FROM Cliente WHERE CIF = ? LIMIT 1");
    $stmt->execute([$user]);
    $cliente = $stmt->fetch();
    if ($cliente && password_verify($pass, $cliente['Password_hash'])) {
        // Es un cliente — guardamos su sesion
        $_SESSION['id']     = $cliente['id'];
        $_SESSION['nombre'] = $cliente['Nombre'];
        $_SESSION['rol']    = 'cliente';
        $_SESSION['cif']    = $cliente['CIF'];
        jsonResponse([
            'ok'       => true,
            'nombre'   => $cliente['Nombre'],
            'rol'      => 'cliente',
            'redirect' => '/cliente.php'  // va al panel de cliente
        ]);
    }

    // Si no coincide nada, error
    errorResponse('Usuario o contrasena incorrectos', 401);

} catch (PDOException $e) {
    errorResponse('Error en la base de datos: ' . $e->getMessage(), 500);
}