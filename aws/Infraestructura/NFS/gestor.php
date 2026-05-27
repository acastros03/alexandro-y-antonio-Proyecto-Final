<?php
// ============================================================
// gestor.php — Ejecuta comandos SSH en las máquinas AWS
// Solo accesible para administradores
// ============================================================

ini_set('session.save_path', '/var/www/shared/sessions');
session_start();
require_once __DIR__ . '/config/db.php';

if (!isset($_SESSION['rol']) || $_SESSION['rol'] === 'cliente') {
    errorResponse('No autorizado', 403);
}

// ── IPs y nombres de cada servidor ───────────────────────
$SERVERS = [
    'balanceador' => ['ip' => '10.0.1.28',  'label' => 'Balanceador (Nginx)'],
    'web1'        => ['ip' => '10.0.2.123', 'label' => 'WEB1 (Apache)'],
    'web2'        => ['ip' => '10.0.2.87',  'label' => 'WEB2 (Apache)'],
    'nfs'         => ['ip' => '10.0.3.240', 'label' => 'NFS'],
    'proxy'       => ['ip' => '10.0.4.34',  'label' => 'HAProxy'],
    'bd1'         => ['ip' => '10.0.5.118', 'label' => 'BD1 PRIMARY'],
    'bd2'         => ['ip' => '10.0.5.231', 'label' => 'BD2 SECONDARY'],
];

// Ruta a la clave SSH
$PEM = '/var/www/shared/.labsuser.pem';

// ── Función para ejecutar un comando en un servidor por SSH ──
function ssh_exec(string $ip, string $cmd, string $pem): array {
    $ssh    = "ssh -i $pem -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes admin@$ip \"$cmd\" 2>&1";
    $output = shell_exec($ssh);
    return [
        'output' => $output ?? 'Sin respuesta',
        'ok'     => $output !== null,
    ];
}

$accion = $_GET['accion'] ?? '';

// ── ESTADO: comprueba si cada servicio está activo ────────
if ($accion === 'estado') {
    $resultado = [];

    // Qué servicio tiene cada servidor
    $servicios = [
        'balanceador' => 'nginx',
        'web1'        => 'apache2',
        'web2'        => 'apache2',
        'nfs'         => 'nfs-kernel-server',
        'proxy'       => 'haproxy',
        'bd1'         => 'mariadb',
        'bd2'         => 'mariadb',
    ];

    foreach ($SERVERS as $key => $srv) {
        $servicio = $servicios[$key];
        $res      = ssh_exec($srv['ip'], "systemctl is-active $servicio", $PEM);
        $activo   = trim($res['output']) === 'active';

        $resultado[] = [
            'label'    => $srv['label'],
            'ip'       => $srv['ip'],
            'servicio' => $servicio,
            'estado'   => $activo ? 'ACTIVO' : 'INACTIVO',
            'ok'       => $activo,
        ];
    }

    // Comprobamos también la replicación entre BD1 y BD2
    $repl = ssh_exec(
        '10.0.5.231',
        "mysql -u root -pibetech2024 -e 'SHOW SLAVE STATUS\\G' 2>/dev/null | grep -E 'Slave_IO_Running|Slave_SQL_Running'",
        $PEM
    );

    $resultado[] = [
        'label'    => 'Replicación BD',
        'ip'       => '10.0.5.231',
        'servicio' => 'replicacion',
        'estado'   => $repl['output'],
        'ok'       => strpos($repl['output'], 'Yes') !== false,
    ];

    jsonResponse($resultado);
}

// ── LOGS: devuelve las últimas líneas del log de un servidor ──
if ($accion === 'logs') {
    $servidor = $_GET['servidor'] ?? 'web1';

    // Comando a ejecutar en cada servidor para ver sus logs
    $comandos = [
        'balanceador' => ['ip' => '10.0.1.28',  'cmd' => 'sudo tail -n 30 /var/log/nginx/access.log'],
        'web1'        => ['ip' => '10.0.2.123', 'cmd' => 'sudo tail -n 30 /var/log/apache2/error.log'],
        'web2'        => ['ip' => '10.0.2.87',  'cmd' => 'sudo tail -n 30 /var/log/apache2/error.log'],
        'haproxy'     => ['ip' => '10.0.4.34',  'cmd' => 'sudo journalctl -u haproxy -n 30 --no-pager'],
        'bd1'         => ['ip' => '10.0.5.118', 'cmd' => 'sudo tail -n 30 /var/log/mysql/error.log'],
        'bd2'         => ['ip' => '10.0.5.231', 'cmd' => 'sudo tail -n 30 /var/log/mysql/error.log'],
        'nfs'         => ['ip' => '10.0.3.240', 'cmd' => 'sudo journalctl -n 30 --no-pager'],
    ];

    if (!isset($comandos[$servidor])) errorResponse('Servidor no válido', 400);

    $c   = $comandos[$servidor];
    $res = ssh_exec($c['ip'], $c['cmd'], $PEM);

    jsonResponse(['servidor' => $servidor, 'output' => $res['output']]);
}

// ── BACKUP: genera un volcado de la BD y lo guarda en el NFS ──
if ($accion === 'backup') {
    $nombre  = 'backup_' . date('Ymd_His') . '.sql';
    $tmp     = '/tmp/' . $nombre;
    $destino = '/var/www/shared/backups/' . $nombre;

    // 1. Hacemos el mysqldump en BD1 y lo guardamos en /tmp de BD1
    $res = ssh_exec(
        '10.0.5.118',
        "mysqldump -u root -pibetech2024 --all-databases > $tmp 2>&1 && echo OK",
        $PEM
    );

    $ok = strpos($res['output'], 'OK') !== false || trim($res['output']) === '';

    if ($ok) {
        // 2. Copiamos el backup desde BD1 al NFS con scp
        $scp = "scp -i $PEM -o StrictHostKeyChecking=no -o BatchMode=yes admin@10.0.5.118:$tmp $destino 2>&1";
        shell_exec($scp);

        // 3. Borramos el archivo temporal de BD1
        ssh_exec('10.0.5.118', "rm -f $tmp", $PEM);

        // 4. Eliminamos backups con más de 7 días
        shell_exec("find /var/www/shared/backups -name 'backup_*.sql' -mtime +7 -delete 2>/dev/null");

        $ok = file_exists($destino);
    }

    jsonResponse([
        'ok'      => $ok,
        'archivo' => $nombre,
        'output'  => $res['output'],
    ]);
}