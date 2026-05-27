<?php
session_start();
// Si no hay sesión o no es cliente, redirigir al login
if (!isset($_SESSION['rol']) || $_SESSION['rol'] !== 'cliente') {
    header('Location: /index.html');
    exit;
}
$nombre_cliente = htmlspecialchars($_SESSION['nombre'] ?? 'Cliente');
$id_cliente     = (int)($_SESSION['id'] ?? 0);
$cif_cliente    = htmlspecialchars($_SESSION['cif'] ?? '');
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>IberoTech — Mi Panel</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;600;700;800&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet">
<style>
  :root {
    --navy:   #0d2a4a;
    --orange: #e8621a;
    --orange2:#f5834a;
    --bg:     #f0f2f6;
    --card:   #ffffff;
    --text:   #1a1a2e;
    --muted:  #6b7a8f;
    --border: #dde2ea;
    --green:  #1a9e6e;
    --red:    #d63031;
    --yellow: #f39c12;
    --shadow: 0 4px 24px rgba(13,42,74,.10);
  }
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: 'DM Sans', sans-serif;
    background: var(--bg);
    color: var(--text);
    min-height: 100vh;
  }

  /* ── Header ── */
  header {
    background: var(--navy);
    padding: 0 2rem;
    display: flex;
    align-items: center;
    justify-content: space-between;
    height: 64px;
    position: sticky; top: 0; z-index: 100;
    box-shadow: 0 2px 16px rgba(0,0,0,.25);
  }
  .logo { font-family: 'Syne', sans-serif; font-size: 1.4rem; font-weight: 800; color: #fff; letter-spacing: -.5px; }
  .logo span { color: var(--orange); }
  .header-right { display: flex; align-items: center; gap: 1.2rem; }
  .user-badge {
    background: rgba(255,255,255,.1);
    border: 1px solid rgba(255,255,255,.15);
    color: #fff;
    padding: .4rem 1rem;
    border-radius: 999px;
    font-size: .85rem;
    font-weight: 500;
  }
  .btn-logout {
    background: var(--orange);
    color: #fff;
    border: none;
    padding: .45rem 1.1rem;
    border-radius: 8px;
    font-size: .85rem;
    font-weight: 600;
    cursor: pointer;
    font-family: 'DM Sans', sans-serif;
    transition: background .2s;
  }
  .btn-logout:hover { background: var(--orange2); }

  /* ── Layout ── */
  .page { max-width: 1100px; margin: 0 auto; padding: 2rem 1.5rem 4rem; }

  /* ── Welcome strip ── */
  .welcome {
    background: linear-gradient(120deg, var(--navy) 0%, #163a5f 100%);
    border-radius: 16px;
    padding: 2rem 2.5rem;
    margin-bottom: 2rem;
    color: #fff;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
  }
  .welcome h1 { font-family: 'Syne', sans-serif; font-size: 1.7rem; font-weight: 700; }
  .welcome p  { margin-top: .3rem; color: rgba(255,255,255,.7); font-size: .95rem; }
  .welcome-cif {
    background: rgba(255,255,255,.1);
    border: 1px solid rgba(255,255,255,.2);
    padding: .5rem 1.2rem;
    border-radius: 10px;
    font-size: .85rem;
    color: rgba(255,255,255,.85);
    white-space: nowrap;
  }

  /* ── Tabs ── */
  .tabs { display: flex; gap: .5rem; margin-bottom: 1.8rem; flex-wrap: wrap; }
  .tab {
    padding: .55rem 1.4rem;
    border-radius: 10px;
    border: 2px solid var(--border);
    background: var(--card);
    color: var(--muted);
    font-family: 'Syne', sans-serif;
    font-size: .9rem;
    font-weight: 600;
    cursor: pointer;
    transition: all .2s;
  }
  .tab:hover  { border-color: var(--orange); color: var(--orange); }
  .tab.active { background: var(--orange); border-color: var(--orange); color: #fff; }

  /* ── Section panels ── */
  .panel { display: none; }
  .panel.active { display: block; }

  /* ── Cards ── */
  .card {
    background: var(--card);
    border-radius: 14px;
    padding: 1.5rem;
    box-shadow: var(--shadow);
    margin-bottom: 1rem;
    border: 1px solid var(--border);
    transition: box-shadow .2s;
  }
  .card:hover { box-shadow: 0 8px 32px rgba(13,42,74,.14); }

  /* ── Contrato card ── */
  .contrato-card {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 1rem;
    flex-wrap: wrap;
  }
  .contrato-info { flex: 1; min-width: 0; }
  .contrato-nombre {
    font-family: 'Syne', sans-serif;
    font-size: 1.05rem;
    font-weight: 700;
    color: var(--navy);
    margin-bottom: .3rem;
  }
  .contrato-servicio {
    font-size: .88rem;
    color: var(--muted);
    margin-bottom: .5rem;
  }
  .contrato-meta { display: flex; flex-wrap: wrap; gap: .6rem; align-items: center; }
  .badge {
    display: inline-flex;
    align-items: center;
    gap: .3rem;
    padding: .25rem .75rem;
    border-radius: 999px;
    font-size: .78rem;
    font-weight: 600;
  }
  .badge-activo    { background: #d4f4e9; color: var(--green); }
  .badge-finalizado{ background: #eaecf0; color: var(--muted); }
  .badge-precio    { background: #fff3e0; color: var(--orange); border: 1px solid #ffe0c0; }
  .badge-fecha     { background: #e8f0fe; color: #1967d2; }

  .contrato-actions { display: flex; gap: .6rem; flex-shrink: 0; }

  /* ── Incidencias ── */
  .inci-card {
    display: flex;
    gap: 1rem;
    align-items: flex-start;
  }
  .sev-dot {
    width: 12px; height: 12px;
    border-radius: 50%;
    margin-top: .35rem;
    flex-shrink: 0;
  }
  .sev-Alta   { background: var(--red); box-shadow: 0 0 8px rgba(214,48,49,.4); }
  .sev-Media  { background: var(--yellow); box-shadow: 0 0 8px rgba(243,156,18,.4); }
  .sev-Baja   { background: var(--green); box-shadow: 0 0 8px rgba(26,158,110,.4); }
  .inci-tipo  { font-family: 'Syne', sans-serif; font-weight: 700; font-size: .95rem; color: var(--navy); }
  .inci-desc  { font-size: .87rem; color: var(--muted); margin-top: .2rem; }
  .inci-contrato { font-size: .8rem; color: var(--muted); margin-top: .4rem; }

  /* ── Catálogo / nueva contratación ── */
  .catalogo-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(290px, 1fr));
    gap: 1rem;
  }
  .catalogo-item {
    background: var(--card);
    border: 2px solid var(--border);
    border-radius: 14px;
    padding: 1.4rem;
    cursor: pointer;
    transition: all .2s;
    position: relative;
    overflow: hidden;
  }
  .catalogo-item::before {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--orange), var(--orange2));
    transform: scaleX(0);
    transform-origin: left;
    transition: transform .25s;
  }
  .catalogo-item:hover { border-color: var(--orange); box-shadow: 0 6px 24px rgba(232,98,26,.15); }
  .catalogo-item:hover::before { transform: scaleX(1); }
  .catalogo-item.selected { border-color: var(--orange); background: #fff8f4; }
  .catalogo-item.selected::before { transform: scaleX(1); }
  .cat-nombre { font-family: 'Syne', sans-serif; font-size: 1rem; font-weight: 700; color: var(--navy); margin-bottom: .4rem; }
  .cat-desc   { font-size: .85rem; color: var(--muted); line-height: 1.5; margin-bottom: .8rem; }
  .cat-precio { font-size: 1.15rem; font-weight: 700; color: var(--orange); }
  .cat-precio span { font-size: .8rem; font-weight: 400; color: var(--muted); }

  /* ── Formulario contrato ── */
  #form-contrato {
    background: var(--card);
    border: 2px solid var(--orange);
    border-radius: 14px;
    padding: 1.8rem;
    margin-top: 1.5rem;
    box-shadow: 0 4px 24px rgba(232,98,26,.1);
    display: none;
  }
  #form-contrato h3 {
    font-family: 'Syne', sans-serif;
    font-size: 1.1rem;
    font-weight: 700;
    color: var(--navy);
    margin-bottom: 1.2rem;
  }
  .form-group { margin-bottom: 1rem; }
  .form-group label {
    display: block;
    font-size: .85rem;
    font-weight: 500;
    color: var(--navy);
    margin-bottom: .4rem;
  }
  .form-group input {
    width: 100%;
    padding: .65rem .9rem;
    border: 1.5px solid var(--border);
    border-radius: 8px;
    font-size: .92rem;
    font-family: 'DM Sans', sans-serif;
    color: var(--text);
    transition: border-color .2s;
    background: var(--bg);
  }
  .form-group input:focus { outline: none; border-color: var(--orange); background: #fff; }
  .form-actions { display: flex; gap: .8rem; margin-top: 1.2rem; }
  .btn-primary {
    background: var(--orange);
    color: #fff;
    border: none;
    padding: .6rem 1.5rem;
    border-radius: 9px;
    font-size: .9rem;
    font-weight: 600;
    cursor: pointer;
    font-family: 'DM Sans', sans-serif;
    transition: background .2s;
  }
  .btn-primary:hover { background: var(--orange2); }
  .btn-secondary {
    background: transparent;
    color: var(--muted);
    border: 1.5px solid var(--border);
    padding: .6rem 1.2rem;
    border-radius: 9px;
    font-size: .9rem;
    font-weight: 500;
    cursor: pointer;
    font-family: 'DM Sans', sans-serif;
    transition: all .2s;
  }
  .btn-secondary:hover { border-color: var(--navy); color: var(--navy); }

  /* ── Nueva incidencia ── */
  #form-incidencia { display: none; }
  #form-incidencia select {
    width: 100%;
    padding: .65rem .9rem;
    border: 1.5px solid var(--border);
    border-radius: 8px;
    font-size: .92rem;
    font-family: 'DM Sans', sans-serif;
    color: var(--text);
    background: var(--bg);
    transition: border-color .2s;
  }
  #form-incidencia select:focus { outline: none; border-color: var(--orange); background: #fff; }
  #form-incidencia textarea {
    width: 100%;
    padding: .65rem .9rem;
    border: 1.5px solid var(--border);
    border-radius: 8px;
    font-size: .92rem;
    font-family: 'DM Sans', sans-serif;
    color: var(--text);
    background: var(--bg);
    resize: vertical;
    min-height: 90px;
    transition: border-color .2s;
  }
  #form-incidencia textarea:focus { outline: none; border-color: var(--orange); background: #fff; }

  /* ── Estado / mensajes ── */
  .msg {
    padding: .9rem 1.2rem;
    border-radius: 10px;
    font-size: .9rem;
    margin-bottom: 1rem;
    font-weight: 500;
    display: none;
  }
  .msg.ok    { background: #d4f4e9; color: var(--green); border: 1px solid #b2e8d3; }
  .msg.error { background: #fde8e8; color: var(--red);   border: 1px solid #f5c2c2; }
  .msg.show  { display: block; }

  /* ── Empty state ── */
  .empty {
    text-align: center;
    padding: 3rem 1rem;
    color: var(--muted);
  }
  .empty .icon { font-size: 3rem; margin-bottom: .8rem; opacity: .5; }
  .empty p { font-size: .95rem; }

  /* ── Loading ── */
  .loading {
    text-align: center;
    padding: 2rem;
    color: var(--muted);
    font-size: .9rem;
  }
  .spinner {
    width: 32px; height: 32px;
    border: 3px solid var(--border);
    border-top-color: var(--orange);
    border-radius: 50%;
    animation: spin .7s linear infinite;
    margin: 0 auto .8rem;
  }
  @keyframes spin { to { transform: rotate(360deg); } }

  /* ── Confirm modal ── */
  .modal-overlay {
    position: fixed; inset: 0;
    background: rgba(0,0,0,.45);
    display: flex; align-items: center; justify-content: center;
    z-index: 1000;
    display: none;
  }
  .modal-overlay.show { display: flex; }
  .modal {
    background: var(--card);
    border-radius: 16px;
    padding: 2rem;
    max-width: 420px;
    width: 90%;
    box-shadow: 0 20px 60px rgba(0,0,0,.25);
  }
  .modal h3 { font-family: 'Syne', sans-serif; font-size: 1.15rem; font-weight: 700; color: var(--navy); margin-bottom: .6rem; }
  .modal p  { font-size: .9rem; color: var(--muted); line-height: 1.6; margin-bottom: 1.5rem; }
  .modal-actions { display: flex; gap: .8rem; justify-content: flex-end; }
  .btn-danger {
    background: var(--red);
    color: #fff;
    border: none;
    padding: .6rem 1.4rem;
    border-radius: 8px;
    font-size: .88rem;
    font-weight: 600;
    cursor: pointer;
    font-family: 'DM Sans', sans-serif;
    transition: opacity .2s;
  }
  .btn-danger:hover { opacity: .85; }

  @media (max-width: 600px) {
    .welcome { flex-direction: column; }
    header { padding: 0 1rem; }
  }
</style>
</head>
<body>


<header>
  <div class="logo">Ibero<span>Tech</span></div>
  <div class="header-right">
    <span class="user-badge">👤 <?= $nombre_cliente ?></span>
    <button class="btn-logout" onclick="window.location='/api/logout.php'">Cerrar sesión</button>
  </div>
</header>

<div class="page">

  <div class="welcome">
    <div>
      <h1>Bienvenido, <?= $nombre_cliente ?></h1>
      <p>Gestiona tus servicios e incidencias desde aquí.</p>
    </div>
    <?php if ($cif_cliente): ?>
    <div class="welcome-cif">CIF: <?= $cif_cliente ?></div>
    <?php endif; ?>
  </div>

  <!-- Tabs -->
  <div class="tabs">
    <button class="tab active" onclick="switchTab('contratos', this)">📋 Mis Servicios</button>
    <button class="tab" onclick="switchTab('catalogo', this)">🛒 Contratar Servicio</button>
    <button class="tab" onclick="switchTab('incidencias', this)">⚠️ Mis Incidencias</button>
    <button class="tab" onclick="switchTab('nueva-inci', this)">➕ Nueva Incidencia</button>
    <a href="/api/descargar_app.php" class="tab" style="margin-left:auto;background:var(--navy);border-color:var(--navy);color:#fff;text-decoration:none;display:inline-block;">⬇️ Descargar</a>
  </div>

  <!-- ── Panel: Mis contratos ── -->
  <div id="panel-contratos" class="panel active">
    <div id="msg-contratos" class="msg"></div>
    <div id="lista-contratos">
      <div class="loading"><div class="spinner"></div>Cargando servicios...</div>
    </div>
  </div>

  <!-- ── Panel: Catálogo / Contratar ── -->
  <div id="panel-catalogo" class="panel">
    <div id="msg-catalogo" class="msg"></div>
    <p style="color:var(--muted);font-size:.9rem;margin-bottom:1.2rem;">
      Selecciona el servicio que quieres contratar y completa el formulario.
    </p>
    <div id="lista-catalogo" class="catalogo-grid">
      <div class="loading"><div class="spinner"></div>Cargando catálogo...</div>
    </div>

    <div id="form-contrato">
      <h3>📝 Datos del nuevo contrato</h3>
      <div id="form-contrato-resumen" style="background:#fff8f4;border:1px solid #ffd4b8;border-radius:8px;padding:.8rem 1rem;margin-bottom:1rem;font-size:.87rem;color:var(--orange);font-weight:600;"></div>
      <div class="form-group">
        <label>Nombre del contrato</label>
        <input type="text" id="contrato-nombre" placeholder="Ej: Auditoría Q1 2025">
      </div>
      <div class="form-group">
        <label>Fecha de inicio</label>
        <input type="date" id="contrato-fecha">
      </div>
      <div class="form-actions">
        <button class="btn-primary" onclick="confirmarContrato()">Contratar</button>
        <button class="btn-secondary" onclick="cancelarFormContrato()">Cancelar</button>
      </div>
    </div>
  </div>

  <!-- ── Panel: Incidencias ── -->
  <div id="panel-incidencias" class="panel">
    <div id="lista-incidencias">
      <div class="loading"><div class="spinner"></div>Cargando incidencias...</div>
    </div>
  </div>

  <!-- ── Panel: Nueva incidencia ── -->
  <div id="panel-nueva-inci" class="panel">
    <div id="msg-nueva-inci" class="msg"></div>
    <div class="card">
      <h3 style="font-family:'Syne',sans-serif;font-size:1.05rem;font-weight:700;color:var(--navy);margin-bottom:1.2rem;">Reportar una nueva incidencia</h3>
      <div id="form-incidencia">
        <div class="form-group">
          <label>Contrato relacionado</label>
          <select id="inci-contrato"></select>
        </div>
        <div class="form-group">
          <label>Tipo de incidencia</label>
          <input type="text" id="inci-tipo" placeholder="Ej: Acceso no autorizado, Certificado caducado...">
        </div>
        <div class="form-group">
          <label>Descripción</label>
          <textarea id="inci-desc" placeholder="Describe el problema con el mayor detalle posible..."></textarea>
        </div>
        <div class="form-group">
          <label>Severidad</label>
          <select id="inci-severidad">
            <option value="Baja">🟢 Baja</option>
            <option value="Media" selected>🟡 Media</option>
            <option value="Alta">🔴 Alta</option>
          </select>
        </div>
        <div class="form-actions">
          <button class="btn-primary" onclick="enviarIncidencia()">Enviar incidencia</button>
        </div>
      </div>
      <div id="no-contratos-msg" style="display:none;" class="empty">
        <div class="icon">📭</div>
        <p>No tienes contratos activos para asociar una incidencia.<br>Contrata un servicio primero.</p>
      </div>
    </div>
  </div>

</div><!-- /page -->
<!-- Modal eliminar incidencia -->
<div class="modal-overlay" id="modal-incidencia">
  <div class="modal">
    <h3>¿Eliminar esta incidencia?</h3>
    <p></p>
    <div class="modal-actions">
      <button class="btn-secondary" onclick="cerrarModalIncidencia()">Volver</button>
      <button class="btn-danger" onclick="ejecutarEliminarIncidencia()">Sí, eliminar</button>
    </div>
  </div>
</div>

<script>
const ID_CLIENTE  = <?= $id_cliente ?>;
const API         = '/api';
let catalogoData  = [];
let contratosData = [];
let servicioSeleccionado = null;
let incidenciaAEliminar = null;

// ── Tabs ─────────────────────────────────────────────────────
function switchTab(nombre, btn) {
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
  btn.classList.add('active');
  document.getElementById('panel-' + nombre).classList.add('active');

  if (nombre === 'contratos'  && contratosData.length === 0) cargarContratos();
  if (nombre === 'catalogo'   && catalogoData.length  === 0) cargarCatalogo();
  if (nombre === 'incidencias') cargarIncidencias();
  if (nombre === 'nueva-inci') cargarContratosSelect();
}

// ── Helpers ──────────────────────────────────────────────────
function mostrarMsg(id, texto, tipo) {
  const el = document.getElementById(id);
  el.textContent = texto;
  el.className = 'msg ' + tipo + ' show';
  setTimeout(() => el.classList.remove('show'), 4000);
}

async function apiFetch(endpoint, opciones = {}) {
  const resp = await fetch(API + endpoint, {
    credentials: 'same-origin',
    headers: { 'Content-Type': 'application/json' },
    ...opciones
  });
  return resp.json();
}

// ── Mis contratos ─────────────────────────────────────────────
async function cargarContratos() {
  const cont = document.getElementById('lista-contratos');
  cont.innerHTML = '<div class="loading"><div class="spinner"></div>Cargando...</div>';
  const data = await apiFetch('/contratos.php?id_cliente=' + ID_CLIENTE);
  contratosData = Array.isArray(data) ? data : [];
  renderContratos();
}

function renderContratos() {
  const cont = document.getElementById('lista-contratos');
  if (!contratosData.length) {
    cont.innerHTML = '<div class="empty"><div class="icon">📋</div><p>No tienes servicios contratados todavía.<br>Ve a "Contratar Servicio" para empezar.</p></div>';
    return;
  }
  cont.innerHTML = contratosData.map(c => `
    <div class="card">
      <div class="contrato-card">
        <div class="contrato-info">
          <div class="contrato-nombre">${esc(c.Nombre)}</div>
          <div class="contrato-servicio">${esc(c.Nombre_servicio)}</div>
          <div class="contrato-meta">
            <span class="badge badge-${c.Estado === 'Activo' ? 'activo' : 'finalizado'}">
              ${c.Estado === 'Activo' ? '✔' : '✘'} ${esc(c.Estado)}
            </span>
            <span class="badge badge-precio">€${parseFloat(c.Precio).toLocaleString('es-ES')}/año</span>
            <span class="badge badge-fecha">Desde ${formatFecha(c.Fecha_inicio)}</span>
            ${c.Fecha_fin ? `<span class="badge" style="background:#eee;color:var(--muted)">Hasta ${formatFecha(c.Fecha_fin)}</span>` : ''}
          </div>
          ${c.Descripcion_servicio ? `<div style="margin-top:.5rem;font-size:.83rem;color:var(--muted)">${esc(c.Descripcion_servicio)}</div>` : ''}
        </div>
      </div>
    </div>
  `).join('');
}

// ── Catálogo ──────────────────────────────────────────────────
async function cargarCatalogo() {
  const cont = document.getElementById('lista-catalogo');
  cont.innerHTML = '<div class="loading"><div class="spinner"></div>Cargando catálogo...</div>';
  const data = await apiFetch('/contratos.php?catalogo=1');
  catalogoData = Array.isArray(data) ? data : [];
  renderCatalogo();
}

function renderCatalogo() {
  const cont = document.getElementById('lista-catalogo');
  if (!catalogoData.length) {
    cont.innerHTML = '<p style="color:var(--muted)">No hay servicios disponibles.</p>';
    return;
  }
  cont.innerHTML = catalogoData.map(s => `
    <div class="catalogo-item" id="cat-${s.ID_Tipo_Servicio}" onclick="seleccionarServicio(${s.ID_Tipo_Servicio})">
      <div class="cat-nombre">${esc(s.Nombre_servicio)}</div>
      <div class="cat-desc">${esc(s.Descripcion)}</div>
      <div class="cat-precio">€${parseFloat(s.Precio).toLocaleString('es-ES')}<span>/año</span></div>
    </div>
  `).join('');
}

function seleccionarServicio(id) {
  document.querySelectorAll('.catalogo-item').forEach(el => el.classList.remove('selected'));
  document.getElementById('cat-' + id).classList.add('selected');
  servicioSeleccionado = catalogoData.find(s => s.ID_Tipo_Servicio == id);

  const form = document.getElementById('form-contrato');
  form.style.display = 'block';
  document.getElementById('form-contrato-resumen').textContent =
    `Servicio seleccionado: ${servicioSeleccionado.Nombre_servicio} — €${parseFloat(servicioSeleccionado.Precio).toLocaleString('es-ES')}/año`;

  // Fecha de inicio por defecto: hoy
  document.getElementById('contrato-fecha').value = new Date().toISOString().split('T')[0];
  document.getElementById('contrato-nombre').value = servicioSeleccionado.Nombre_servicio + ' — <?= addslashes($nombre_cliente) ?>';

  form.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function cancelarFormContrato() {
  document.getElementById('form-contrato').style.display = 'none';
  document.querySelectorAll('.catalogo-item').forEach(el => el.classList.remove('selected'));
  servicioSeleccionado = null;
}

async function confirmarContrato() {
  if (!servicioSeleccionado) return;
  const nombre = document.getElementById('contrato-nombre').value.trim();
  const fecha  = document.getElementById('contrato-fecha').value;
  if (!nombre) { mostrarMsg('msg-catalogo', 'Escribe un nombre para el contrato.', 'error'); return; }
  if (!fecha)  { mostrarMsg('msg-catalogo', 'Selecciona la fecha de inicio.',       'error'); return; }

  const res = await apiFetch('/contratos.php', {
    method: 'POST',
    body: JSON.stringify({
      nombre,
      id_tipo_servicio: servicioSeleccionado.ID_Tipo_Servicio,
      fecha_inicio: fecha
    })
  });

  if (res.ok) {
    mostrarMsg('msg-catalogo', '✔ Servicio contratado correctamente.', 'ok');
    cancelarFormContrato();
    contratosData = []; // forzar recarga la próxima vez
  } else {
    mostrarMsg('msg-catalogo', '✘ ' + (res.error || 'Error al contratar.'), 'error');
  }
}


// ── Incidencias ───────────────────────────────────────────────
async function cargarIncidencias() {
  const cont = document.getElementById('lista-incidencias');
  cont.innerHTML = '<div class="loading"><div class="spinner"></div>Cargando...</div>';
  const data = await apiFetch('/mis_incidencias.php?id_cliente=' + ID_CLIENTE + '&tipo=incidencias');
  const arr = Array.isArray(data) ? data : [];
  if (!arr.length) {
    cont.innerHTML = '<div class="empty"><div class="icon">✅</div><p>No tienes incidencias registradas. ¡Todo en orden!</p></div>';
    return;
  }
cont.innerHTML = arr.map(i => `
    <div class="card">
      <div class="inci-card">
        <div class="sev-dot sev-${esc(i.Severidad)}"></div>
        <div style="flex:1">
          <div class="inci-tipo">${esc(i.Tipo)}</div>
          <div class="inci-desc">${esc(i.Descripcion)}</div>
          <div class="inci-contrato">
            <span class="badge badge-${i.Severidad === 'Alta' ? 'activo' : 'finalizado'}" style="${i.Severidad === 'Alta' ? 'background:#fde8e8;color:var(--red)' : ''}">
              ${esc(i.Severidad)}
            </span>
            &nbsp;· Contrato: ${esc(i.Contrato)}
          </div>
        </div>
        <button onclick="pedirEliminarIncidencia(${i.ID_Incidencia}, '${esc(i.Tipo)}')" style="background:#fff0f0;color:var(--red);border:1.5px solid #ffd6d6;padding:.4rem .9rem;border-radius:8px;font-size:.82rem;font-weight:600;cursor:pointer;flex-shrink:0;">
          🗑 Eliminar
        </button>
      </div>
    </div>
  `).join('');
}
// ── Nueva incidencia ──────────────────────────────────────────
async function cargarContratosSelect() {
  const data = await apiFetch('/mis_incidencias.php?id_cliente=' + ID_CLIENTE + '&tipo=contratos');
  const arr  = Array.isArray(data) ? data.filter(c => c.Estado === 'Activo') : [];
  const form = document.getElementById('form-incidencia');
  const noC  = document.getElementById('no-contratos-msg');

  if (!arr.length) {
    form.style.display = 'none';
    noC.style.display = 'block';
    return;
  }
  form.style.display = 'block';
  noC.style.display  = 'none';

  const sel = document.getElementById('inci-contrato');
  sel.innerHTML = arr.map(c => `<option value="${c.ID_Contrato}">${esc(c.Nombre)} — ${esc(c.Nombre_servicio)}</option>`).join('');
}

async function enviarIncidencia() {
  const tipo       = document.getElementById('inci-tipo').value.trim();
  const descripcion= document.getElementById('inci-desc').value.trim();
  const severidad  = document.getElementById('inci-severidad').value;
  const id_contrato= parseInt(document.getElementById('inci-contrato').value);

  if (!tipo || !descripcion) {
    mostrarMsg('msg-nueva-inci', 'Rellena el tipo y la descripción.', 'error');
    return;
  }

  const res = await apiFetch('/nueva_incidencia.php', {
    method: 'POST',
    body: JSON.stringify({ tipo, descripcion, severidad, id_contrato })
  });

  if (res.ok) {
    mostrarMsg('msg-nueva-inci', '✔ Incidencia registrada. Nuestro equipo la revisará pronto.', 'ok');
    document.getElementById('inci-tipo').value  = '';
    document.getElementById('inci-desc').value  = '';
  } else {
    mostrarMsg('msg-nueva-inci', '✘ ' + (res.error || 'Error al enviar.'), 'error');
  }
}
// ── Eliminar incidencia ───────────────────────────────────────
function pedirEliminarIncidencia(id, tipo) {
  incidenciaAEliminar = id;
  document.querySelector('#modal-incidencia p').textContent =
    `Vas a eliminar la incidencia "${tipo}". Esta acción no se puede deshacer.`;
  document.getElementById('modal-incidencia').classList.add('show');
}

function cerrarModalIncidencia() {
  document.getElementById('modal-incidencia').classList.remove('show');
  incidenciaAEliminar = null;
}

async function ejecutarEliminarIncidencia() {
  if (!incidenciaAEliminar) return;
  const idAEliminar = incidenciaAEliminar;
  cerrarModalIncidencia();
  const res = await apiFetch('/incidencias.php?id=' + idAEliminar, { method: 'DELETE' });
  if (res.ok) {
    cargarIncidencias();
  } else {
    alert('Error al eliminar: ' + (res.error || 'desconocido'));
  }
  incidenciaAEliminar = null;
}
// ── Utilidades ────────────────────────────────────────────────

function esc(s) {
  if (s == null) return '';
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
function formatFecha(f) {
  if (!f) return '—';
  const [y,m,d] = f.split('-');
  return `${d}/${m}/${y}`;
}

// Cargar contratos al inicio
cargarContratos();
</script>
</body>
</html>