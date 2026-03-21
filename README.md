# 🛡️ IberoTech
### Infraestructura Tecnológica Completa de una Empresa de Ciberseguridad

---

## 👨‍💻 Autores

| Nombre | Usuario GitHub |
|--------|---------------|
| **Alexandro Castro Serrano** | [@acastros03](https://github.com/acastros03) |
| **Antonio Contreras Montaña** | [@antoniocm08](https://github.com/antoniocm08) |


---

## 🏢 ¿De qué va el proyecto?

**IberoTech** es una empresa ficticia del sector de la **ciberseguridad** con sede en Mérida y entre 28 y 36 empleados. Este proyecto consiste en diseñar e implementar **desde cero toda su infraestructura tecnológica**, abarcando desde la gestión interna de usuarios hasta los servicios web de producción.

IberoTech ofrece cuatro líneas de servicio:

- 🔍 **Consultoría** — Asesoramiento técnico y normativo en seguridad
- 🔎 **Auditoría** — Análisis forense y diagnóstico de sistemas
- 🏗️ **Diseño** — Implementación de infraestructuras seguras
- 📊 **Análisis** — Detección y gestión de vulnerabilidades

---

## 🗂️ Módulos del Proyecto

### 🖥️ 1. Windows Server y Active Directory
Dominio `IberoTech.es` con **5 Unidades Organizativas** (una por departamento), **6 grupos de seguridad**, perfiles móviles y **8 GPOs** de seguridad con justificación técnica.

- Restricción de USB, CMD y Panel de Control para usuarios estándar
- Bloqueo automático de pantalla tras inactividad
- Horario de acceso restringido (07:00 – 18:00)
- Acceso SSH a Linux exclusivo para el departamento de Informática

### 🗄️ 2. Base de Datos Relacional
Modelo Entidad-Relación normalizado en **MariaDB** para gestionar departamentos, empleados, clientes, contratos e incidencias de ciberseguridad. Script DDL completo incluido.

### 🌐 3. Servicios en Red — Arquitectura de 5 Capas
Infraestructura de **alta disponibilidad** desplegada sobre Debian 12:

```
Internet → [Nginx LB] → [Apache x2] → [NFS] → [HAProxy] → [MariaDB Cluster]
```

- **Nginx** como balanceador de carga con SSL/TLS y health checks automáticos
- **Apache2** con redirección HTTP → HTTPS obligatoria
- **NFS** como almacenamiento compartido entre nodos web
- **HAProxy** como proxy SQL que protege el acceso directo a la BD
- **Clúster MariaDB** con replicación Galera síncrona (cero pérdida de datos)

### 🐍 4. Aplicación Python — Gestor de Clientes e Incidencias
Aplicación de escritorio con **interfaz gráfica Tkinter** para el personal técnico:

- Búsqueda de clientes en tiempo real por nombre o CIF
- Alta de clientes con incidencia inicial simultánea
- Gestión de incidencias por severidad (Crítica / Alta / Media / Baja)
- Eliminación en cascada con integridad referencial
- Autocompletado de precios desde catálogo de servicios
- Sin dependencias externas — solo Python estándar

### 🐧 5. Scripts Linux de Administración
Herramientas Bash y Python para administrar las 5 capas desde un único punto:

- `monitor_servicios.sh` — Estado de todos los servidores vía SSH
- `backup_mariadb.sh` — Backup automatizado del clúster MariaDB al NFS
- Panel gráfico Python/Tkinter de administración centralizada

---

## 🛠️ Tecnologías Utilizadas

| Categoría | Tecnologías |
|-----------|------------|
| Sistemas Operativos | Windows Server 2022, Debian 12 |
| Gestión de Identidades | Active Directory, GPO, DNS, DHCP |
| Servidores Web | Apache2, Nginx |
| Base de Datos | MariaDB, HAProxy, Galera Cluster |
| Almacenamiento | NFS Server |
| Programación | Python 3, Tkinter, Bash |
| Simulación de Red | Cisco Packet Tracer |
| Virtualización | Vagrant, VirtualBox |

---

## 📁 Estructura del Repositorio

```
alexandro-castro/
│
├── 📄 README.md
├── 📄 documentacion_alexandro_castro.pdf
│
├── 📂 documentacion/             → Manual Técnico, Manual de Usuario, propuestas, ERD
├── 📂 windows-server/            → Proyecto AD, GPOs y estructura de dominio
├── 📂 active-directory/          → Diseño de Active Directory y OUs
├── 📂 base-de-datos/             → DDL SQL + memoria del proyecto de BD
├── 📂 servicios-red/             → Configs de Apache, Nginx y HAProxy
├── 📂 python-gestor-incidencias/ → interfaz.py, gestor_csv.py, CSVs
└── 📂 scripts-linux/             → monitor_servicios.sh, backup_mariadb.sh
```

---

## 📚 Documentación

| Documento | Descripción |
|-----------|-------------|
| [📋 documentacion_alexandro_castro.pdf](./documentacion_alexandro_castro.pdf) | Índice general con enlaces a todos los documentos y archivos de código del proyecto |
| [📖 Manual Técnico](./documentacion/Manual_Tecnico_IberoTech.docx) | Arquitectura, configuración y funcionamiento técnico completo |
| [📗 Manual de Usuario](./documentacion/Manual_Usuario_IberoTech.pdf) | Guía de uso para los empleados de IberoTech |
| [🗺️ Esquema del Proyecto](./documentacion/Esquema_Proyecto_Final_Alexandro_Castro_Antonio_Contreras.pdf) | Visión general de todos los módulos |

---

*Proyecto Final — IES Albarregas · ASIR 2 · 2024/2025*
