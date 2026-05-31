# IberoTech — Documentación técnica
## Parte individual: Alexandro Castro Serrano
**IES Albarregas · Mérida, Extremadura · 2025**

---

## Índice
1. Descripción general
2. Aplicación de escaneo de puertos
3. Sistema de correo automático

---

## 1. Descripción general

Este documento describe las dos partes individuales desarrolladas por Alexandro Castro Serrano dentro del proyecto IberoTech:

- Una **aplicación de escritorio** para escanear puertos de red en Windows
- Un **sistema de correo automático** que envía las credenciales de acceso a los nuevos clientes cuando se registran en la web

---

## 2. Aplicación de escaneo de puertos

### 2.1. Qué hace

La aplicación permite analizar los puertos de red abiertos en el equipo donde se ejecuta. Muestra qué puertos están abiertos, qué servicio los usa y si representan un riesgo de seguridad. Al terminar el escaneo se puede exportar un informe en PDF con los resultados.

### 2.2. Tecnologías utilizadas

| Tecnología | Para qué se usa |
|------------|-----------------|
| Python 3 | Lenguaje principal |
| Tkinter | Interfaz gráfica |
| Nmap / python-nmap | Escaneo de puertos |
| ReportLab | Generación del PDF |
| PyInstaller | Convertir a .exe para Windows |

### 2.3. Funcionamiento

**1. Elegir rango de puertos**
El usuario elige el rango a analizar. Hay tres opciones rápidas: Comunes (1-1024), Extendido (1-5000) y Todos (1-65535). También se puede escribir un rango personalizado.

**2. Escanear**
Al pulsar Escanear, la app lanza Nmap en segundo plano para no bloquear la interfaz. Nmap analiza cada puerto del rango en la IP local (127.0.0.1) y detecta qué servicio está usando cada puerto abierto.

**3. Ver resultados**
Los resultados aparecen en una tabla con cuatro columnas: puerto, servicio, nivel de riesgo y descripción. Los puertos considerados peligrosos se marcan como PELIGROSO.

**4. Exportar PDF**
El usuario puede guardar un informe PDF con los resultados. El informe incluye la fecha y una tabla con todos los puertos encontrados.

### 2.4. Puertos considerados peligrosos

| Puerto | Servicio | Por qué es peligroso |
|--------|----------|----------------------|
| 21 | FTP | Transfiere archivos sin cifrar |
| 23 | Telnet | Acceso remoto sin cifrar |
| 25 | SMTP | Puede usarse para mandar spam |
| 135 | RPC | Muy explotado por hackers |
| 139 | NetBIOS | Compartición de archivos insegura |
| 445 | SMB | Usado por el virus WannaCry |
| 1433 | SQL Server | Base de datos expuesta |
| 3306 | MySQL | Base de datos expuesta |
| 3389 | RDP | Escritorio remoto, muy atacado |
| 5900 | VNC | Escritorio remoto sin cifrar |
| 8080 | HTTP alternativo | Puede exponer servicios internos |

### 2.5. Estructura del código

| Método | Qué hace |
|--------|----------|
| `__init__` | Inicializa la ventana y las variables |
| `_ui` | Construye la interfaz gráfica |
| `_rango` | Cambia el rango al pulsar un botón rápido |
| `_escanear_ini` | Valida el rango y lanza el escaneo en un hilo separado |
| `_scan` | Ejecuta Nmap y recoge los resultados |
| `_mostrar` | Muestra los resultados en la tabla |
| `_error` | Muestra un mensaje de error si el escaneo falla |
| `_pdf` | Genera el informe PDF con ReportLab |

### 2.6. Cómo se distribuye

La aplicación se convierte a `.exe` con PyInstaller para que cualquier usuario de Windows pueda usarla sin tener Python instalado. Se empaqueta junto al manual de usuario en un archivo `.rar` que los clientes de IberoTech pueden descargar desde su panel en la web.

**Requisitos:**
- Nmap instalado (descargable desde nmap.org)
- Ejecutar como administrador de Windows

---

## 3. Sistema de correo automático

### 3.1. Qué hace

Cuando un visitante rellena el formulario de contacto de la web de IberoTech, el sistema crea automáticamente un usuario en la base de datos con una contraseña aleatoria y le envía un correo electrónico con sus credenciales de acceso. Así el cliente puede entrar directamente al portal sin que ningún administrador tenga que hacer nada manualmente.

### 3.2. Tecnologías utilizadas

| Tecnología | Para qué se usa |
|------------|-----------------|
| PHP | Procesar el formulario y conectar con la BD |
| MariaDB | Almacenar los datos del nuevo cliente |
| Postfix | Servidor de correo en WEB1 y WEB2 |
| Brevo | Servicio SMTP relay que envía los correos |
| Gmail | Cuenta remitente verificada en Brevo |

### 3.3. Funcionamiento

**1. El cliente rellena el formulario**
El visitante introduce su nombre, CIF, teléfono y email en el formulario de contacto de la web.

**2. El formulario llama a la API**
El JavaScript hace una petición POST a `/api/contacto.php` con los datos del formulario.

**3. Se crea el usuario en la BD**
El PHP comprueba que el CIF no existe ya, genera una contraseña aleatoria de 8 caracteres, la cifra con bcrypt y guarda el cliente en MariaDB.

**4. Se envía el correo**
PHP usa la función `mail()` que internamente usa Postfix. Postfix está configurado con Brevo como relay SMTP, que envía el correo al destinatario.

**5. El cliente recibe sus credenciales**
El cliente recibe un correo con su CIF como usuario y la contraseña generada, con un enlace para acceder al portal.

### 3.4. Archivos involucrados

| Archivo | Ubicación | Qué hace |
|---------|-----------|----------|
| `contacto.php` | `/var/nfs/shared/api/` | Recibe los datos, crea el cliente en BD y manda el correo |
| `mail.php` | `/var/nfs/shared/api/config/` | Configuración del correo: credenciales de Gmail y Brevo |
| `db.php` | `/var/nfs/shared/api/config/` | Configuración de la conexión a MariaDB via HAProxy |
| `index.html` | `/var/nfs/shared/` | Contiene el formulario y el JavaScript que llama a la API |
| `main.cf` | `/etc/postfix/` | Configuración de Postfix en WEB1 y WEB2 |

### 3.5. Por qué se usa Brevo en vez de Gmail directamente

AWS bloquea las conexiones SMTP directas desde instancias EC2 para evitar spam. Por eso no se puede conectar PHPMailer directamente a Gmail. La solución fue instalar Postfix en los servidores web y configurarlo para que use Brevo como relay SMTP, que sí está permitido por AWS.

---

*IberoTech · IES Albarregas · Mérida, Extremadura · 2025*
