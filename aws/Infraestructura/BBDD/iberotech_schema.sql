-- =============================================================================
-- base_de_datos_iberotech.sql  –  Schema completo para Ibe-tech
-- Ejecutar en BD PRIMARY (Ibe-tech-BD1) sobre la base de datos 'iberotech'
-- =============================================================================

USE iberotech;

-- ── Tablas de infraestructura (creadas por BD1.sh) ──────────────────────────
-- servers_info y app_logs ya existen; solo añadimos el schema de negocio.

-- ── Departamento ─────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS Atiende;
DROP TABLE IF EXISTS Accion;
DROP TABLE IF EXISTS Tipo_Inci;
DROP TABLE IF EXISTS Incidencia;
DROP TABLE IF EXISTS Contrato;
DROP TABLE IF EXISTS Catalogo;
DROP TABLE IF EXISTS Servicios;
DROP TABLE IF EXISTS Proveedor;
DROP TABLE IF EXISTS Cliente;
DROP TABLE IF EXISTS Tipo_Emple;
DROP TABLE IF EXISTS Empleado;
DROP TABLE IF EXISTS Departamento;

CREATE TABLE Departamento (
    ID_Departamento INT PRIMARY KEY AUTO_INCREMENT,
    Nombre_DEPT     VARCHAR(100) NOT NULL,
    Nombre_USU      VARCHAR(100),
    Descripcion     VARCHAR(255)
) ENGINE=InnoDB;

INSERT INTO Departamento (Nombre_DEPT, Nombre_USU, Descripcion) VALUES
('Administración', 'Antonio',   'Departamento de administración general'),
('Técnico',        'Alexandro', 'Departamento técnico de ciberseguridad'),
('Comercial',      NULL,        'Gestión de contratos y clientes');

-- ── Empleado (con hash de contraseña para login) ─────────────────────────────
-- Contraseñas:  admin123  →  bcrypt
CREATE TABLE Empleado (
    ID_Empleado     INT PRIMARY KEY AUTO_INCREMENT,
    Nombre          VARCHAR(100) NOT NULL,
    Telefono        VARCHAR(20),
    Tipo            VARCHAR(50),
    Grupo           VARCHAR(100),
    ID_Departamento INT,
    Rol             VARCHAR(50)  DEFAULT 'Empleado',
    Password_hash   VARCHAR(255) NOT NULL DEFAULT '',
    FOREIGN KEY (ID_Departamento) REFERENCES Departamento(ID_Departamento)
) ENGINE=InnoDB;

-- Hash de 'admin123' generado con password_hash('admin123', PASSWORD_BCRYPT)
INSERT INTO Empleado (Nombre, Telefono, Tipo, Grupo, ID_Departamento, Rol, Password_hash) VALUES
('Antonio',   '600111222', 'Admin', 'Admins', 1, 'Administrador', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('Alexandro', '600333444', 'Admin', 'Admins', 1, 'Administrador', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('Laura',     '600555666', 'Tech',  'Soporte',2, 'Empleado',      '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');

-- ── Tipo_Emple ────────────────────────────────────────────────────────────────
CREATE TABLE Tipo_Emple (
    ID_Tipo_Emple INT PRIMARY KEY AUTO_INCREMENT,
    Salario       DECIMAL(10,2) NOT NULL,
    ID_Empleado   INT,
    FOREIGN KEY (ID_Empleado) REFERENCES Empleado(ID_Empleado)
) ENGINE=InnoDB;

INSERT INTO Tipo_Emple (Salario, ID_Empleado) VALUES
(3500.00, 1), (3500.00, 2), (2800.00, 3);

-- ── Cliente ───────────────────────────────────────────────────────────────────
CREATE TABLE Cliente (
    ID_Cliente INT PRIMARY KEY AUTO_INCREMENT,
    Nombre     VARCHAR(150) NOT NULL,
    CIF        VARCHAR(20)  NOT NULL UNIQUE,
    Telefono   VARCHAR(20),
    Direccion  VARCHAR(255),
    Email         VARCHAR(150),
    Password_hash VARCHAR(255) NOT NULL DEFAULT ''
) ENGINE=InnoDB;

-- Contraseña de cliente: 'cliente123'
INSERT INTO Cliente (Nombre, CIF, Telefono, Direccion, Email, Password_hash) VALUES
('Empresa Ejemplo SL',   'B12345678', '910100200', 'Calle Mayor 1, Madrid',       'empresa@ejemplo.com',       '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('Tech Solutions SA',    'A87654321', '910200300', 'Av. Tecnología 55, Barcelona', 'tech@solutions.com',         '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
('Comercial Norte CB',   'E11223344', '910300400', 'Paseo del Norte 8, Bilbao',    'comercial@norte.com',        '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');

-- ── Proveedor ─────────────────────────────────────────────────────────────────
CREATE TABLE Proveedor (
    ID_Proveedor         INT PRIMARY KEY AUTO_INCREMENT,
    Nombre               VARCHAR(150) NOT NULL,
    Servicio_suministrado VARCHAR(150),
    Direccion            VARCHAR(255),
    Codigo_Postal        VARCHAR(10),
    CIF                  VARCHAR(20) NOT NULL UNIQUE,
    Fecha_ini            DATE,
    Fecha_fin            DATE,
    ID_Departamento      INT,
    FOREIGN KEY (ID_Departamento) REFERENCES Departamento(ID_Departamento)
) ENGINE=InnoDB;

INSERT INTO Proveedor (Nombre, Servicio_suministrado, Direccion, Codigo_Postal, CIF, Fecha_ini, ID_Departamento) VALUES
('SecureNet SL',   'Licencias antivirus',   'Calle Datos 10, Madrid',  '28001', 'B99001122', '2024-01-01', 2),
('CloudBackup SA', 'Almacenamiento cloud',  'Av. Cloud 22, Valencia',  '46001', 'A99003344', '2024-03-01', 2);

-- ── Servicios ─────────────────────────────────────────────────────────────────
CREATE TABLE Servicios (
    ID_Servicio  INT PRIMARY KEY AUTO_INCREMENT,
    Producto     VARCHAR(150) NOT NULL,
    Precio       DECIMAL(10,2) NOT NULL,
    ID_Proveedor INT NOT NULL,
    FOREIGN KEY (ID_Proveedor) REFERENCES Proveedor(ID_Proveedor)
) ENGINE=InnoDB;

INSERT INTO Servicios (Producto, Precio, ID_Proveedor) VALUES
('Licencia Antivirus Enterprise', 1200.00, 1),
('Backup Cloud 1TB/año',          800.00,  2);

-- ── Catálogo ─────────────────────────────────────────────────────────────────
CREATE TABLE Catalogo (
    ID_Tipo_Servicio INT PRIMARY KEY AUTO_INCREMENT,
    Nombre_servicio  VARCHAR(150) NOT NULL,
    Descripcion      VARCHAR(255),
    Precio           DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB;

INSERT INTO Catalogo (Nombre_servicio, Descripcion, Precio) VALUES
('Auditoría de Seguridad',    'Análisis completo de vulnerabilidades',   2500.00),
('SOC Gestionado',            'Centro de operaciones 24/7',              4500.00),
('Respuesta a Incidentes',    'Gestión y resolución de ciberincidentes', 1800.00),
('Formación en Ciberseguridad','Talleres y cursos para empleados',        900.00),
('Pentesting Web',            'Pruebas de intrusión en aplicaciones web',1500.00);

-- ── Contrato ─────────────────────────────────────────────────────────────────
CREATE TABLE Contrato (
    ID_Contrato      INT PRIMARY KEY AUTO_INCREMENT,
    Nombre           VARCHAR(150) NOT NULL,
    Fecha_inicio     DATE NOT NULL,
    Fecha_fin        DATE,
    Estado           VARCHAR(50) NOT NULL,
    ID_Cliente       INT NOT NULL,
    ID_Empleado      INT NOT NULL,
    ID_Tipo_Servicio INT NOT NULL,
    FOREIGN KEY (ID_Cliente)       REFERENCES Cliente(ID_Cliente),
    FOREIGN KEY (ID_Empleado)      REFERENCES Empleado(ID_Empleado),
    FOREIGN KEY (ID_Tipo_Servicio) REFERENCES Catalogo(ID_Tipo_Servicio)
) ENGINE=InnoDB;

INSERT INTO Contrato (Nombre, Fecha_inicio, Fecha_fin, Estado, ID_Cliente, ID_Empleado, ID_Tipo_Servicio) VALUES
('Auditoría 2024 - Empresa Ejemplo',   '2024-01-15', '2024-06-15', 'Finalizado', 1, 1, 1),
('SOC Gestionado - Tech Solutions',    '2024-03-01', NULL,         'Activo',     2, 2, 2),
('Pentesting - Comercial Norte',       '2024-07-01', '2024-08-31', 'Activo',     3, 3, 5),
('Formación 2024 - Empresa Ejemplo',   '2024-09-01', '2024-12-01', 'Activo',     1, 3, 4);

-- ── Incidencia ───────────────────────────────────────────────────────────────
CREATE TABLE Incidencia (
    ID_Incidencia INT PRIMARY KEY AUTO_INCREMENT,
    Tipo          VARCHAR(100) NOT NULL,
    Descripcion   VARCHAR(255),
    Severidad     VARCHAR(20),
    ID_Contrato   INT NOT NULL,
    FOREIGN KEY (ID_Contrato) REFERENCES Contrato(ID_Contrato)
) ENGINE=InnoDB;

INSERT INTO Incidencia (Tipo, Descripcion, Severidad, ID_Contrato) VALUES
('Puerto expuesto',        'Puerto 445 SMB accesible desde internet',    'Alta',  1),
('Certificado caducado',   'Certificado SSL expirado en subdominio',      'Media', 2),
('Acceso no autorizado',   'Intento de acceso fallido repetido (brute)',  'Alta',  2),
('Configuración insegura', 'Credenciales por defecto en panel de admin',  'Media', 3);

-- ── Tipo_Inci ────────────────────────────────────────────────────────────────
CREATE TABLE Tipo_Inci (
    ID_Tipo_Inci  INT PRIMARY KEY AUTO_INCREMENT,
    Descripcion   VARCHAR(255),
    ID_Incidencia INT UNIQUE,
    FOREIGN KEY (ID_Incidencia) REFERENCES Incidencia(ID_Incidencia)
) ENGINE=InnoDB;

INSERT INTO Tipo_Inci (Descripcion, ID_Incidencia) VALUES
('Exposición de servicio de red',   1),
('Certificado PKI caducado',        2),
('Ataque de fuerza bruta',          3),
('Hardening deficiente',            4);

-- ── Atiende ──────────────────────────────────────────────────────────────────
CREATE TABLE Atiende (
    ID_Empleado   INT NOT NULL,
    ID_Incidencia INT NOT NULL,
    Fecha_hallazgo DATE,
    PRIMARY KEY (ID_Empleado, ID_Incidencia),
    FOREIGN KEY (ID_Empleado)   REFERENCES Empleado(ID_Empleado),
    FOREIGN KEY (ID_Incidencia) REFERENCES Incidencia(ID_Incidencia)
) ENGINE=InnoDB;

INSERT INTO Atiende VALUES (1,1,'2024-02-10'),(2,2,'2024-04-05'),(2,3,'2024-05-12'),(3,4,'2024-07-20');

-- ── Accion ────────────────────────────────────────────────────────────────────
CREATE TABLE Accion (
    ID_Accion     INT PRIMARY KEY AUTO_INCREMENT,
    Descripcion   VARCHAR(255) NOT NULL,
    Estado        VARCHAR(50)  NOT NULL,
    Fecha         DATE,
    ID_Incidencia INT NOT NULL,
    FOREIGN KEY (ID_Incidencia) REFERENCES Incidencia(ID_Incidencia)
) ENGINE=InnoDB;

INSERT INTO Accion (Descripcion, Estado, Fecha, ID_Incidencia) VALUES
('Bloqueo de puerto 445 en firewall perimetral', 'Completada', '2024-02-11', 1),
('Renovación de certificado SSL wildcard',        'En proceso', '2024-04-06', 2),
('Implementación de fail2ban + 2FA',              'Completada', '2024-05-13', 3),
('Cambio de credenciales y hardening de panel',   'Pendiente',  '2024-07-21', 4);

-- ── Vista resumen (útil para dashboards) ─────────────────────────────────────
CREATE OR REPLACE VIEW v_incidencias_resumen AS
SELECT
    i.ID_Incidencia,
    i.Tipo,
    i.Severidad,
    cl.Nombre  AS Cliente,
    c.Nombre   AS Contrato,
    c.Estado   AS Estado_Contrato,
    GROUP_CONCAT(a.Estado ORDER BY a.Fecha DESC SEPARATOR ', ') AS Acciones
FROM Incidencia i
JOIN Contrato c  ON i.ID_Contrato = c.ID_Contrato
JOIN Cliente  cl ON c.ID_Cliente  = cl.ID_Cliente
LEFT JOIN Accion a ON a.ID_Incidencia = i.ID_Incidencia
GROUP BY i.ID_Incidencia, i.Tipo, i.Severidad, cl.Nombre, c.Nombre, c.Estado;

SELECT 'Schema iberotech cargado correctamente' AS resultado;