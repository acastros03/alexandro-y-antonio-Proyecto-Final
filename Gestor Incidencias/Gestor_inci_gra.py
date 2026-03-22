#!/usr/bin/env python3
import tkinter as tk
from tkinter import scrolledtext, filedialog, messagebox
import subprocess
import threading
import os

# ── Configuracion ─────────────────────────────────────────────────────────────
DIRECTORIO  = os.path.dirname(os.path.abspath(__file__))
SCRIPT      = os.path.join(DIRECTORIO, "Gestor_inci.sh")

LINEAS_MENU = ["GESTOR DE INFRAESTRUCTURA", "Estado de los servidores", "Ver logs",
               "Actualizar contenido", "Backup de emergencia", "Salir", "Opcion:",
               "========", "VISOR DE LOGS", "Opcion no valida", "Presiona Enter",
               "1) Estado", "2) Ver", "3) Actualizar", "4) Backup", "0) Salir",
               "1) Balanceador", "2) Apache", "3) Apache", "4) HAProxy",
               "5) MariaDB", "6) MariaDB", "7) Todos", "0) Volver", "Adios"]

def encontrar_bash():
    for c in [r"C:/Program Files/Git/bin/bash.exe",
              r"C:/Program Files (x86)/Git/bin/bash.exe",
              r"C:/Git/bin/bash.exe"]:
        if os.path.isfile(c):
            return c
    return "bash"

BASH_EXE = encontrar_bash()

mi_env = os.environ.copy()
mi_env["PATH"] = (
    "C:/Program Files/Git/usr/bin;"
    "C:/Program Files/Git/bin;"
    "C:/HashiCorp/Vagrant/bin;"
    + mi_env.get("PATH", "")
)
mi_env["VAGRANT_CWD"] = DIRECTORIO
mi_env["TERM"]        = "dumb"

# ── Abrir ventana de resultado ────────────────────────────────────────────────
def nueva_ventana(titulo):
    v = tk.Toplevel()
    v.title(titulo)
    v.geometry("700x450")
    area = scrolledtext.ScrolledText(v, font=("Courier", 10), state="disabled")
    area.pack(fill="both", expand=True, padx=5, pady=5)
    return area

# ── Ejecutar script con input en una ventana propia ───────────────────────────
def ejecutar(entrada, titulo, area=None):
    if area is None:
        area = nueva_ventana(titulo)

    def tarea():
        area.config(state="normal")
        area.delete("1.0", "end")
        area.insert("end", "Ejecutando...\n")
        area.update_idletasks()
        try:
            script_bash = SCRIPT.replace("\\", "/")
            if len(script_bash) >= 2 and script_bash[1] == ":":
                script_bash = "/" + script_bash[0].lower() + script_bash[2:]

            entrada_esc = entrada.replace("'", "'\\''")
            cmd = f"printf '%b' '{entrada_esc}' | bash '{script_bash}'"
            p = subprocess.Popen(
                [BASH_EXE, "-c", cmd],
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, env=mi_env, cwd=DIRECTORIO
            )
            area.config(state="normal")
            area.delete("1.0", "end")
            for linea in p.stdout:
                if linea.strip() and not any(x in linea for x in LINEAS_MENU):
                    area.insert("end", linea)
                    area.see("end")
                    area.update_idletasks()
            p.wait()

        except subprocess.TimeoutExpired:
            area.config(state="normal")
            area.delete("1.0", "end")
            area.insert("end", "TIMEOUT: operacion supero 3 minutos.\n")
        except Exception as e:
            area.config(state="normal")
            area.delete("1.0", "end")
            area.insert("end", f"ERROR: {e}\n")
        finally:
            area.config(state="disabled")

    threading.Thread(target=tarea, daemon=True).start()

# ── Ventana de logs ────────────────────────────────────────────────────────────
def ver_logs():
    v = tk.Toplevel()
    v.title("Logs")
    v.geometry("750x500")
    area = scrolledtext.ScrolledText(v, font=("Courier", 10), state="disabled")
    area.pack(fill="both", expand=True)
    panel = tk.Frame(v)
    panel.pack()
    opciones = [("Balanceador","1"),("WEB1","2"),("WEB2","3"),("HAProxy","4"),
                ("MariaDB1","5"),("MariaDB2","6"),("Todos","7")]
    for texto, num in opciones:
        tk.Button(panel, text=texto,
                  command=lambda n=num: ejecutar(f"2\n{n}\n\n0\n0\n", f"Logs - {texto}", area)
                  ).pack(side="left", padx=3, pady=5)

# ── Actualizar web ─────────────────────────────────────────────────────────────
def actualizar_web():
    ruta = filedialog.askopenfilename(filetypes=[("HTML","*.html"),("Todos","*.*")])
    if not ruta:
        return
    if messagebox.askyesno("Confirmar", "Subir archivo:\n" + ruta):
        ruta_bash = ruta.replace("\\", "/")
        if len(ruta_bash) >= 2 and ruta_bash[1] == ":":
            ruta_bash = "/" + ruta_bash[0].lower() + ruta_bash[2:]
        ejecutar(f"3\n{ruta_bash}\n\n0\n", "Actualizar web")

# ── Backup ─────────────────────────────────────────────────────────────────────
def backup():
    if messagebox.askyesno("Confirmar", "Realizar backup de emergencia?"):
        ejecutar("4\nSI\n\n0\n", "Backup")

# ── Ventana principal ──────────────────────────────────────────────────────────
root = tk.Tk()
root.title("Gestor Ibe-tech")
root.geometry("600x150")
root.resizable(False, False)

tk.Label(root, text="GESTOR DE INFRAESTRUCTURA IBERO-TECH", font=("Courier", 13, "bold")).pack(pady=15)

panel = tk.Frame(root)
panel.pack()
tk.Button(panel, text="1) Estado",         width=18, command=lambda: ejecutar("1\n\n0\n", "Estado")).pack(side="left", padx=5, pady=5)
tk.Button(panel, text="2) Logs",           width=18, command=ver_logs).pack(side="left", padx=5, pady=5)
tk.Button(panel, text="3) Actualizar web", width=18, command=actualizar_web).pack(side="left", padx=5, pady=5)
tk.Button(panel, text="4) Backup",         width=18, command=backup).pack(side="left", padx=5, pady=5)

root.mainloop()