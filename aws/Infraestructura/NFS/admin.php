<?php
ini_set('session.save_path', '/var/www/shared/sessions');
session_start();
require_once __DIR__ . '/api/config/db.php';

// Si no hay sesión o es un cliente, lo mandamos al inicio
if (!isset($_SESSION['rol']) || $_SESSION['rol'] === 'cliente') {
    header('Location: /index.html');
    exit;
}

$nombre_admin = htmlspecialchars($_SESSION['nombre'] ?? 'Administrador');
?>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Panel Admin - IberoTech</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css" rel="stylesheet">
  <style>
    body { background: #f0f2f5; }

    /* Barra superior */
    .topbar { background: #0d2a4a; color: #fff; padding: 15px 30px; }
    .topbar span { color: #e8621a; font-weight: bold; }

    /* Colores de severidad */
    .badge-Alta  { background: #dc3545 !important; color: #fff; }
    .badge-Media { background: #fd7e14 !important; color: #fff; }
    .badge-Baja  { background: #198754 !important; color: #fff; }

    /* Tarjetas de estado de servidores */
    .estado-card {
      background: #fff;
      border-radius: 10px;
      padding: 1rem 1.2rem;
      margin-bottom: .6rem;
      border: 1px solid #dee2e6;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .estado-card .label { font-weight: 600; color: #0d2a4a; }
    .estado-card .ip    { font-size: .8rem; color: #888; }

    /* Puntos de estado (verde/rojo) */
    .dot { width: 12px; height: 12px; border-radius: 50%; display: inline-block; margin-right: 8px; }
    .dot-ok  { background: #198754; box-shadow: 0 0 6px rgba(25,135,84,.5); }
    .dot-err { background: #dc3545; box-shadow: 0 0 6px rgba(220,53,69,.5); }

    /* Visor de logs */
    #log-output {
      background: #1e1e1e;
      color: #d4d4d4;
      font-family: 'Courier New', monospace;
      font-size: .82rem;
      padding: 1rem;
      border-radius: 8px;
      height: 400px;
      overflow-y: auto;
      white-space: pre-wrap;
      word-break: break-all;
    }
  </style>
</head>
<body>

<!-- Barra superior -->
<div class="topbar d-flex justify-content-between align-items-center">
  <div><i class="bi bi-shield-check"></i> <span>IberoTech</span> — Panel de administración</div>
  <div>
    <span class="me-3">Hola, <?= $nombre_admin ?></span>
    <a href="/api/logout.php" class="btn btn-outline-light btn-sm">
      <i class="bi bi-box-arrow-left"></i> Salir
    </a>
  </div>
</div>

<div class="container py-4">

  <!-- Pestañas -->
  <ul class="nav nav-tabs mb-4" id="tabs-admin">
    <li class="nav-item"><a class="nav-link active" href="#" onclick="verTab('clientes',this)"><i class="bi bi-people"></i> Clientes</a></li>
    <li class="nav-item"><a class="nav-link" href="#" onclick="verTab('incidencias',this)"><i class="bi bi-exclamation-triangle"></i> Incidencias</a></li>
    <li class="nav-item"><a class="nav-link" href="#" onclick="verTab('web',this)"><i class="bi bi-globe"></i> Actualizar web</a></li>
    <li class="nav-item"><a class="nav-link" href="#" onclick="verTab('estado',this)"><i class="bi bi-hdd-network"></i> Estado servidores</a></li>
    <li class="nav-item"><a class="nav-link" href="#" onclick="verTab('logs',this)"><i class="bi bi-terminal"></i> Logs</a></li>
    <li class="nav-item"><a class="nav-link" href="#" onclick="verTab('backup',this)"><i class="bi bi-database-down"></i> Backup BD</a></li>
  </ul>

  <!-- ── Clientes ── -->
  <div id="tab-clientes">
    <h5 class="mb-3">Clientes registrados</h5>
    <input type="text" id="buscador" class="form-control mb-3" style="max-width:300px"
           placeholder="Buscar cliente..." oninput="buscarCliente()">
    <div id="lista-clientes"><p class="text-muted">Cargando...</p></div>
  </div>

  <!-- ── Incidencias ── -->
  <div id="tab-incidencias" style="display:none">
    <h5 class="mb-3">Todas las incidencias</h5>
    <div id="lista-incidencias"><p class="text-muted">Cargando...</p></div>
  </div>

  <!-- ── Actualizar web ── -->
  <div id="tab-web" style="display:none">
    <h5 class="mb-3">Actualizar página web</h5>
    <div class="card shadow-sm" style="max-width:500px">
      <div class="card-body">
        <p>Sube un archivo HTML para reemplazar el <code>index.html</code> del NFS.</p>
        <input type="file" id="archivo-html" class="form-control mb-3" accept=".html">
        <button class="btn btn-primary" onclick="subirWeb()">
          <i class="bi bi-upload"></i> Subir y publicar
        </button>
        <div id="msg-web" class="mt-3"></div>
      </div>
    </div>
  </div>

  <!-- ── Estado servidores ── -->
  <div id="tab-estado" style="display:none">
    <div class="d-flex align-items-center justify-content-between mb-3">
      <h5 class="mb-0">Estado de los servidores</h5>
      <button class="btn btn-sm btn-outline-primary" onclick="cargarEstado()">
        <i class="bi bi-arrow-clockwise"></i> Actualizar
      </button>
    </div>
    <div id="lista-estado"><p class="text-muted">Cargando...</p></div>
  </div>

  <!-- ── Logs ── -->
  <div id="tab-logs" style="display:none">
    <h5 class="mb-3">Visor de logs</h5>
    <div class="row g-2 mb-3 align-items-end">
      <div class="col-auto">
        <select id="sel-servidor-log" class="form-select">
          <option value="balanceador">Balanceador (Nginx)</option>
          <option value="web1">WEB1 (Apache)</option>
          <option value="web2">WEB2 (Apache)</option>
          <option value="haproxy">HAProxy</option>
          <option value="bd1">MariaDB BD1</option>
          <option value="bd2">MariaDB BD2</option>
          <option value="nfs">NFS</option>
        </select>
      </div>
      <div class="col-auto">
        <button class="btn btn-primary" onclick="cargarLogs()">
          <i class="bi bi-search"></i> Ver logs
        </button>
      </div>
    </div>
    <div id="log-output">Selecciona un servidor y pulsa "Ver logs".</div>
  </div>

  <!-- ── Backup ── -->
  <div id="tab-backup" style="display:none">
    <h5 class="mb-3">Backup de base de datos</h5>
    <div class="card shadow-sm" style="max-width:550px">
      <div class="card-body">
        <p>Genera un volcado completo de <strong>BD1 PRIMARY</strong> y lo guarda en <code>/var/nfs/shared/backups/</code>.</p>
        <p class="text-muted small">Los backups con más de 7 días se eliminan automáticamente.</p>
        <button class="btn btn-danger" id="btn-backup" onclick="hacerBackup()">
          <i class="bi bi-database-down"></i> Generar backup ahora
        </button>
        <div id="backup-resultado"></div>
      </div>
    </div>
  </div>

</div><!-- /container -->

<!-- ── Modal: detalle de cliente ── -->
<div class="modal fade" id="modalCliente" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header" style="background:#0d2a4a; color:#fff;">
        <h5 class="modal-title"><i class="bi bi-person-circle"></i> Detalle del cliente</h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body" id="modal-cliente-contenido">
        Cargando...
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>

// ── Tabs ─────────────────────────────────────────────────
function verTab(cual, el) {
  document.querySelectorAll('[id^="tab-"]').forEach(t => t.style.display = 'none');
  document.getElementById('tab-' + cual).style.display = 'block';
  document.querySelectorAll('#tabs-admin .nav-link').forEach(l => l.classList.remove('active'));
  el.classList.add('active');
  if (cual === 'clientes')    cargarClientes();
  if (cual === 'incidencias') cargarIncidencias();
  if (cual === 'estado')      cargarEstado();
}

// ── Clientes ─────────────────────────────────────────────
function cargarClientes(q) {
  const url = '/api/clientes.php' + (q ? '?q=' + encodeURIComponent(q) : '');
  fetch(url).then(r => r.json()).then(data => {
    const div = document.getElementById('lista-clientes');
    if (!data.length) { div.innerHTML = '<p class="text-muted">No hay clientes.</p>'; return; }
    div.innerHTML = `
      <table class="table table-hover">
        <thead class="table-dark">
          <tr><th>#</th><th>Nombre</th><th>CIF</th><th>Teléfono</th><th>Email</th><th>Acciones</th></tr>
        </thead>
        <tbody>
          ${data.map(c => `
            <tr>
              <td>${c.ID_Cliente}</td>
              <td>${c.Nombre}</td>
              <td>${c.CIF}</td>
              <td>${c.Telefono || '—'}</td>
              <td>${c.Email || '—'}</td>
              <td>
                <button class="btn btn-sm btn-primary" onclick="verCliente(${c.ID_Cliente})">
                  <i class="bi bi-eye"></i> Ver
                </button>
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>`;
  });
}

function buscarCliente() {
  cargarClientes(document.getElementById('buscador').value);
}

// Abre el modal con los datos del cliente
function verCliente(id) {
  const contenido = document.getElementById('modal-cliente-contenido');
  contenido.innerHTML = '<p class="text-muted">Cargando...</p>';
  new bootstrap.Modal(document.getElementById('modalCliente')).show();

  fetch('/api/clientes.php?id=' + id).then(r => r.json()).then(d => {
    const c = d.cliente;
    const contratos   = d.contratos;
    const incidencias = d.incidencias;

    contenido.innerHTML = `
      <!-- Datos del cliente -->
      <h6 class="fw-bold text-primary mb-2"><i class="bi bi-person"></i> Datos</h6>
      <table class="table table-sm table-bordered mb-4">
        <tr><th>Nombre</th><td>${c.Nombre}</td><th>CIF</th><td>${c.CIF}</td></tr>
        <tr><th>Teléfono</th><td>${c.Telefono || '—'}</td><th>Email</th><td>${c.Email || '—'}</td></tr>
        <tr><th colspan="4">${c.Direccion || '—'}</th></tr>
      </table>

      <!-- Contratos -->
      <h6 class="fw-bold text-primary mb-2"><i class="bi bi-file-earmark-text"></i> Contratos (${contratos.length})</h6>
      ${contratos.length ? `
        <table class="table table-sm table-hover mb-4">
          <thead class="table-light">
            <tr><th>Nombre</th><th>Servicio</th><th>Precio</th><th>Inicio</th><th>Estado</th></tr>
          </thead>
          <tbody>
            ${contratos.map(c => `
              <tr>
                <td>${c.Nombre}</td>
                <td>${c.Nombre_servicio}</td>
                <td>${c.Precio} €</td>
                <td>${c.Fecha_inicio}</td>
                <td><span class="badge ${c.Estado === 'Activo' ? 'bg-success' : 'bg-secondary'}">${c.Estado}</span></td>
              </tr>
            `).join('')}
          </tbody>
        </table>` : '<p class="text-muted">Sin contratos.</p>'}

      <!-- Incidencias -->
      <h6 class="fw-bold text-primary mb-2"><i class="bi bi-exclamation-triangle"></i> Incidencias (${incidencias.length})</h6>
      ${incidencias.length ? `
        <table class="table table-sm table-hover">
          <thead class="table-light">
            <tr><th>Tipo</th><th>Descripción</th><th>Severidad</th><th>Contrato</th></tr>
          </thead>
          <tbody>
            ${incidencias.map(i => `
              <tr>
                <td>${i.Tipo}</td>
                <td>${i.Descripcion}</td>
                <td><span class="badge badge-${i.Severidad}">${i.Severidad}</span></td>
                <td>${i.Contrato}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>` : '<p class="text-muted">Sin incidencias.</p>'}
    `;
  });
}

// ── Incidencias ───────────────────────────────────────────
function cargarIncidencias() {
  fetch('/api/incidencias.php').then(r => r.json()).then(data => {
    const div = document.getElementById('lista-incidencias');
    if (!data.length) { div.innerHTML = '<p class="text-muted">No hay incidencias.</p>'; return; }
    div.innerHTML = `
      <table class="table table-hover">
        <thead class="table-dark">
          <tr><th>#</th><th>Tipo</th><th>Cliente</th><th>Severidad</th><th>Contrato</th><th>Acción</th></tr>
        </thead>
        <tbody>
          ${data.map(i => `
            <tr>
              <td>${i.ID_Incidencia}</td>
              <td>${i.Tipo}</td>
              <td>${i.Cliente}</td>
              <td><span class="badge badge-${i.Severidad}">${i.Severidad}</span></td>
              <td>${i.Contrato}</td>
              <td>
                <button class="btn btn-sm btn-success" onclick="resolverIncidencia(${i.ID_Incidencia})">
                  <i class="bi bi-check-lg"></i> Resolver
                </button>
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>`;
  });
}

function resolverIncidencia(id) {
  if (!confirm('¿Marcar esta incidencia como resuelta y eliminarla?')) return;
  fetch('/api/incidencias.php?id=' + id, { method: 'DELETE', credentials: 'same-origin' })
    .then(r => r.json())
    .then(res => {
      if (res.ok) {
        cargarIncidencias();
      } else {
        alert('Error: ' + (res.error || 'No se pudo resolver'));
      }
    });
}

// ── Actualizar web ────────────────────────────────────────
function subirWeb() {
  const file = document.getElementById('archivo-html').files[0];
  const msg  = document.getElementById('msg-web');
  if (!file) { msg.innerHTML = '<div class="alert alert-danger">Selecciona un archivo HTML.</div>'; return; }
  const fd = new FormData();
  fd.append('html_file', file);
  fetch('/api/subir_web.php', { method: 'POST', body: fd })
    .then(r => r.json())
    .then(r => {
      msg.innerHTML = r.ok
        ? '<div class="alert alert-success">Web actualizada correctamente.</div>'
        : '<div class="alert alert-danger">Error: ' + (r.error || 'desconocido') + '</div>';
    });
}

// ── Estado servidores ─────────────────────────────────────
async function cargarEstado() {
  const div = document.getElementById('lista-estado');
  div.innerHTML = '<p class="text-muted"><i class="bi bi-hourglass-split"></i> Comprobando servidores...</p>';

  const data = await fetch('/api/gestor.php?accion=estado', { credentials: 'same-origin' }).then(r => r.json());

  if (!Array.isArray(data)) {
    div.innerHTML = '<div class="alert alert-danger">Error al obtener el estado.</div>';
    return;
  }

  div.innerHTML = data.map(s => `
    <div class="estado-card">
      <div>
        <span class="dot ${s.ok ? 'dot-ok' : 'dot-err'}"></span>
        <span class="label">${s.label}</span>
        <span class="ip ms-2">${s.ip}</span>
        ${s.servicio !== 'replicacion' ? `<small class="text-muted ms-2">(${s.servicio})</small>` : ''}
      </div>
      <div>
        <span class="badge ${s.ok ? 'bg-success' : 'bg-danger'}">${s.estado}</span>
      </div>
    </div>
  `).join('');
}

// ── Logs ──────────────────────────────────────────────────
async function cargarLogs() {
  const servidor = document.getElementById('sel-servidor-log').value;
  const out = document.getElementById('log-output');
  out.textContent = 'Cargando logs de ' + servidor + '...';

  const data = await fetch(`/api/gestor.php?accion=logs&servidor=${servidor}`, { credentials: 'same-origin' }).then(r => r.json());

  if (data.error) { out.textContent = 'Error: ' + data.error; return; }
  out.textContent = data.output || '(sin salida)';
  out.scrollTop = out.scrollHeight;
}

// ── Backup ────────────────────────────────────────────────
async function hacerBackup() {
  const btn = document.getElementById('btn-backup');
  const res = document.getElementById('backup-resultado');

  btn.disabled = true;
  btn.innerHTML = '<i class="bi bi-hourglass-split"></i> Generando backup...';
  res.innerHTML = '';

  const data = await fetch('/api/gestor.php?accion=backup', { credentials: 'same-origin' }).then(r => r.json());

  btn.disabled = false;
  btn.innerHTML = '<i class="bi bi-database-down"></i> Generar backup ahora';

  res.innerHTML = data.ok
    ? `<div class="alert alert-success mt-3">
        <i class="bi bi-check-circle"></i> Backup generado correctamente.<br>
        <strong>Archivo:</strong> <code>${data.archivo}</code><br>
        <small>Guardado en <code>/var/nfs/shared/backups/</code></small>
       </div>`
    : `<div class="alert alert-danger mt-3">
        <i class="bi bi-x-circle"></i> Error al generar el backup.<br>
        <code>${data.output || 'Sin detalle'}</code>
       </div>`;
}

// Carga inicial al entrar al panel
cargarClientes();
</script>
</body>
</html>