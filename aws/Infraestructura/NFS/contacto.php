<?php
require_once __DIR__ . '/config/db.php';
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') jsonResponse([]);
if ($_SERVER['REQUEST_METHOD'] !== 'POST') errorResponse('Metodo no permitido', 405);

$body     = json_decode(file_get_contents('php://input'), true) ?? [];
$nombre   = trim($body['nombre']    ?? '');
$cif      = trim($body['cif']       ?? '');
$telefono = trim($body['telefono']  ?? '');
$email    = trim($body['email']     ?? '');
$direccion= trim($body['direccion'] ?? '');

if (!$nombre || !$cif || !$email) errorResponse('Nombre, CIF y email son obligatorios');

try {
    $pdo = getWriteConnection();
    $check = $pdo->prepare("SELECT ID_Cliente FROM Cliente WHERE CIF = ?");
    $check->execute([$cif]);
    if ($check->fetch()) errorResponse('Ya existe un cliente con ese CIF', 409);

    $password = substr(str_shuffle('abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789'), 0, 8);
    $hash = password_hash($password, PASSWORD_BCRYPT);

    $stmt = $pdo->prepare("INSERT INTO Cliente (Nombre, CIF, Telefono, Direccion, Email, Password_hash) VALUES (?,?,?,?,?,?)");
    $stmt->execute([$nombre, $cif, $telefono, $direccion, $email, $hash]);
    $id = $pdo->lastInsertId();

    // Mandar correo con las credenciales usando mail() de PHP
    $asunto  = 'Bienvenido a IberoTech - Tus datos de acceso';
    $mensaje = "Hola $nombre,\n\n";
    $mensaje .= "Tu cuenta ha sido creada correctamente en IberoTech.\n\n";
    $mensaje .= "Tus datos de acceso son:\n";
    $mensaje .= "  Usuario (CIF): $cif\n";
    $mensaje .= "  Contrasena:    $password\n\n";
    $mensaje .= "Accede en: http://labs-iberotech.ddns.net\n\n";
    $mensaje .= "Si tienes cualquier duda contacta con nosotros.\n\n";
    $mensaje .= "Un saludo,\nEl equipo de IberoTech\nMerida, Extremadura";
    $cabeceras = "From: IberoTech <iberotech.proyectoasir@gmail.com>\r\n";
    $cabeceras .= "Reply-To: iberotech.proyectoasir@gmail.com\r\n";
    $cabeceras .= "Content-Type: text/plain; charset=UTF-8\r\n";

    $enviado = mail($email, $asunto, $mensaje, $cabeceras);

    jsonResponse([
        'ok'     => true,
        'id'     => $id,
        'correo' => $enviado ? 'enviado' : 'error al enviar'
    ], 201);

} catch (PDOException $e) {
    errorResponse('Error en la base de datos: ' . $e->getMessage(), 500);
}