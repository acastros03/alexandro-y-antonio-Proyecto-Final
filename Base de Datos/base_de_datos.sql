-- ==========================================
-- TABLA: Departamento (actualizada)
-- ==========================================

DROP TABLE IF EXISTS Departamento;

CREATE TABLE Departamento (
    ID_Departamento INT PRIMARY KEY AUTO_INCREMENT,
    Nombre_DEPT VARCHAR(100) NOT NULL,
    Nombre_USU VARCHAR(100),
    Descripcion VARCHAR(255)
);

-- Insertamos un departamento base para los administradores
INSERT INTO Departamento (Nombre_DEPT, Nombre_USU, Descripcion)
VALUES ('Administración', 'Antonio', 'Departamento de administración general');

-- ==========================================
-- TABLA: Empleado (incluye campo Rol)
-- ==========================================

DROP TABLE IF EXISTS Empleado;

CREATE TABLE Empleado (
    ID_Empleado INT PRIMARY KEY AUTO_INCREMENT,
    Nombre VARCHAR(100) NOT NULL,
    Telefono VARCHAR(20),
    Tipo VARCHAR(50),
    Grupo VARCHAR(100),
    ID_Departamento INT,
    Rol VARCHAR(50) DEFAULT 'Empleado',
    FOREIGN KEY (ID_Departamento) REFERENCES Departamento(ID_Departamento)
);

-- Insertamos los dos administradores
INSERT INTO Empleado (Nombre, Telefono, Tipo, Grupo, ID_Departamento, Rol)
VALUES
('Antonio', '600111222', 'Admin', 'Admins', 1, 'Administrador'),
('Alexandro', '600333444', 'Admin', 'Admins', 1, 'Administrador');

-- ==========================================
-- RESTO DE TABLAS DEL PROYECTO
-- ==========================================

DROP TABLE IF EXISTS Tipo_Emple;
CREATE TABLE Tipo_Emple (
    ID_Tipo_Emple INT PRIMARY KEY AUTO_INCREMENT,
    Salario DECIMAL(10,2) NOT NULL,
    ID_Empleado INT,
    FOREIGN KEY (ID_Empleado) REFERENCES Empleado(ID_Empleado)
);

DROP TABLE IF EXISTS Cliente;
CREATE TABLE Cliente (
    ID_Cliente INT PRIMARY KEY AUTO_INCREMENT,
    Nombre VARCHAR(150) NOT NULL,
    CIF VARCHAR(20) NOT NULL UNIQUE,
    Telefono VARCHAR(20),
    Direccion VARCHAR(255)
);

DROP TABLE IF EXISTS Proveedor;
CREATE TABLE Proveedor (
    ID_Proveedor INT PRIMARY KEY AUTO_INCREMENT,
    Nombre VARCHAR(150) NOT NULL,
    Servicio_suministrado VARCHAR(150),
    Direccion VARCHAR(255),
    Codigo_Postal VARCHAR(10),
    CIF VARCHAR(20) NOT NULL UNIQUE,
    Fecha_ini DATE,
    Fecha_fin DATE,
    ID_Departamento INT,
    FOREIGN KEY (ID_Departamento) REFERENCES Departamento(ID_Departamento)
);

DROP TABLE IF EXISTS Servicios;
CREATE TABLE Servicios (
    ID_Servicio INT PRIMARY KEY AUTO_INCREMENT,
    Producto VARCHAR(150) NOT NULL,
    Precio DECIMAL(10,2) NOT NULL,
    ID_Proveedor INT NOT NULL,
    FOREIGN KEY (ID_Proveedor) REFERENCES Proveedor(ID_Proveedor)
);

DROP TABLE IF EXISTS Catalogo;
CREATE TABLE Catalogo (
    ID_Tipo_Servicio INT PRIMARY KEY AUTO_INCREMENT,
    Nombre_servicio VARCHAR(150) NOT NULL,
    Descripcion VARCHAR(255),
    Precio DECIMAL(10,2) NOT NULL
);

DROP TABLE IF EXISTS Contrato;
CREATE TABLE Contrato (
    ID_Contrato INT PRIMARY KEY AUTO_INCREMENT,
    Nombre VARCHAR(150) NOT NULL,
    Fecha_inicio DATE NOT NULL,
    Fecha_fin DATE,
    Estado VARCHAR(50) NOT NULL,
    ID_Cliente INT NOT NULL,
    ID_Empleado INT NOT NULL,
    ID_Tipo_Servicio INT NOT NULL,
    FOREIGN KEY (ID_Cliente) REFERENCES Cliente(ID_Cliente),
    FOREIGN KEY (ID_Empleado) REFERENCES Empleado(ID_Empleado),
    FOREIGN KEY (ID_Tipo_Servicio) REFERENCES Catalogo(ID_Tipo_Servicio)
);

DROP TABLE IF EXISTS Incidencia;
CREATE TABLE Incidencia (
    ID_Incidencia INT PRIMARY KEY AUTO_INCREMENT,
    Tipo VARCHAR(100) NOT NULL,
    Descripcion VARCHAR(255),
    Severidad VARCHAR(20),
    ID_Contrato INT NOT NULL,
    FOREIGN KEY (ID_Contrato) REFERENCES Contrato(ID_Contrato)
);

DROP TABLE IF EXISTS Tipo_Inci;
CREATE TABLE Tipo_Inci (
    ID_Tipo_Inci INT PRIMARY KEY AUTO_INCREMENT,
    Descripcion VARCHAR(255),
    ID_Incidencia INT UNIQUE,
    FOREIGN KEY (ID_Incidencia) REFERENCES Incidencia(ID_Incidencia)
);

DROP TABLE IF EXISTS Atiende;
CREATE TABLE Atiende (
    ID_Empleado INT NOT NULL,
    ID_Incidencia INT NOT NULL,
    Fecha_hallazgo DATE,
    PRIMARY KEY (ID_Empleado, ID_Incidencia),
    FOREIGN KEY (ID_Empleado) REFERENCES Empleado(ID_Empleado),
    FOREIGN KEY (ID_Incidencia) REFERENCES Incidencia(ID_Incidencia)
);

DROP TABLE IF EXISTS Accion;
CREATE TABLE Accion (
    ID_Accion INT PRIMARY KEY AUTO_INCREMENT,
    Descripcion VARCHAR(255) NOT NULL,
    Estado VARCHAR(50) NOT NULL,
    Fecha DATE,
    ID_Incidencia INT NOT NULL,
    FOREIGN KEY (ID_Incidencia) REFERENCES Incidencia(ID_Incidencia)
);
