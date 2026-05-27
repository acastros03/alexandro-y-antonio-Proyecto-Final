<?php
// Cerramos la sesion y mandamos al usuario al inicio
session_start();
session_destroy();
header('Location: /index.html');
exit;