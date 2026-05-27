<?php
// mail.php — Envia correos usando sendmail via Postfix del balanceador

function enviarCorreo(string $para, string $asunto, string $cuerpo): bool {
    $de      = "iberotech.proyectoasir@gmail.com";
    $cabeceras = implode("\r\n", [
        "From: IberoTech <$de>",
        "Reply-To: $de",
        "MIME-Version: 1.0",
        "Content-Type: text/html; charset=UTF-8",
        "Content-Transfer-Encoding: base64",
    ]);
    $cuerpo_encoded = chunk_split(base64_encode($cuerpo));
    $ok = mail($para, $asunto, $cuerpo_encoded, $cabeceras, "-f $de");
    if (!$ok) error_log("IberoTech - Error al enviar correo a $para");
    return $ok;
}

function correoRegistro(string $email, string $empresa, string $cif, string $password): bool {
    $asunto = "Bienvenido a IberoTech - Tus datos de acceso";
    $cuerpo = "
    <div style='font-family:Arial,sans-serif;max-width:600px;margin:0 auto;'>
        <div style='background:#0d2a4a;padding:30px;text-align:center;'>
            <h1 style='color:#fff;margin:0;'>Ibero<span style='color:#e8621a;'>Tech</span></h1>
        </div>
        <div style='padding:30px;background:#f4f6f9;'>
            <h2 style='color:#0d2a4a;'>Bienvenido, $empresa</h2>
            <p>Tu cuenta ha sido creada. Aqui tienes tus datos de acceso:</p>
            <div style='background:#fff;padding:20px;border-radius:8px;border-left:4px solid;'>
                <p><strong>Usuario:</strong> $cif</p>
                <p><strong>Contrasena:</strong> $password</p>
            </div>
            <p>Accede en: <a href='http://3.82.157.248'>IberoTech</a></p>
        </div>
        <div style='background:#0d2a4a;padding:15px;text-align:center;'>
            <p style='color:#fff;margin:0;font-size:0.85em;'>IberoTech - Merida, Extremadura</p>
        </div>
    </div>";
    return enviarCorreo($email, $asunto, $cuerpo);
}