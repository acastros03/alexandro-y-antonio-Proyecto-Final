import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import nmap
import threading
import datetime

try:
    from reportlab.lib.pagesizes import A4
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib import colors
    PDF = True
except ImportError:
    PDF = False

PUERTOS_PELIGROSOS = {
    21: "FTP sin cifrar",
    23: "Telnet sin cifrar",
    25: "SMTP - relay de correo",
    135: "RPC - vulnerable",
    139: "NetBIOS - inseguro",
    445: "SMB - WannaCry",
    1433: "SQL Server expuesto",
    3306: "MySQL expuesto",
    3389: "Escritorio remoto",
    5900: "VNC sin cifrar",
    8080: "HTTP alternativo",
}

class App:
    def __init__(self, root):
        self.root = root
        self.root.title("Escaner de puertos")
        self.root.geometry("800x520")
        self.resultados = []
        self.scanning = False
        self._ui()

    def _ui(self):
        f1 = tk.Frame(self.root)
        f1.pack(fill="x", padx=15, pady=8)
        tk.Label(f1, text="Puertos del").pack(side="left")
        self.p_ini = tk.Entry(f1, width=7)
        self.p_ini.insert(0, "1")
        self.p_ini.pack(side="left", padx=4)
        tk.Label(f1, text="al").pack(side="left")
        self.p_fin = tk.Entry(f1, width=7)
        self.p_fin.insert(0, "1024")
        self.p_fin.pack(side="left", padx=4)
        for txt, a, b in [("Comunes", "1", "1024"), ("Extendido", "1", "5000"), ("Todos", "1", "65535")]:
            tk.Button(f1, text=txt, command=lambda i=a, f=b: self._rango(i, f)).pack(side="left", padx=3)

        f2 = tk.Frame(self.root)
        f2.pack(fill="x", padx=15, pady=6)
        self.btn_scan = tk.Button(f2, text="Escanear", command=self._escanear_ini)
        self.btn_scan.pack(side="left", padx=4)
        tk.Button(f2, text="Exportar PDF", command=self._pdf).pack(side="left", padx=4)

        tf = tk.Frame(self.root)
        tf.pack(fill="both", expand=True, padx=15, pady=4)
        cols = ("Puerto", "Servicio", "Riesgo", "Descripcion")
        self.tabla = ttk.Treeview(tf, columns=cols, show="headings")
        for col, w in zip(cols, [80, 130, 100, 400]):
            self.tabla.heading(col, text=col)
            self.tabla.column(col, width=w)
        sc = ttk.Scrollbar(tf, orient="vertical", command=self.tabla.yview)
        self.tabla.configure(yscrollcommand=sc.set)
        sc.pack(side="right", fill="y")
        self.tabla.pack(fill="both", expand=True)

    def _rango(self, a, b):
        self.p_ini.delete(0, tk.END); self.p_ini.insert(0, a)
        self.p_fin.delete(0, tk.END); self.p_fin.insert(0, b)

    def _escanear_ini(self):
        if self.scanning:
            return
        try:
            a, b = int(self.p_ini.get()), int(self.p_fin.get())
            if a < 1 or b > 65535 or a > b:
                raise ValueError
        except ValueError:
            messagebox.showerror("Error", "Rango no valido.")
            return
        self.tabla.delete(*self.tabla.get_children())
        self.resultados = []
        self.scanning = True
        self.btn_scan.config(state="disabled", text="Escaneando...")
        threading.Thread(target=self._scan, args=(a, b), daemon=True).start()

    def _scan(self, a, b):
        try:
            nm = nmap.PortScanner()
            nm.scan("127.0.0.1", f"{a}-{b}", arguments="-sV --open -T4")
            for host in nm.all_hosts():
                for proto in nm[host].all_protocols():
                    for p in sorted(nm[host][proto].keys()):
                        info = nm[host][proto][p]
                        if info["state"] == "open":
                            srv = f"{info.get('name','?')} {info.get('version','')}".strip()
                            if p in PUERTOS_PELIGROSOS:
                                riesgo, desc = "PELIGROSO", PUERTOS_PELIGROSOS[p]
                            else:
                                riesgo, desc = "Normal", "Sin riesgo conocido"
                            self.resultados.append({"puerto": p, "servicio": srv,
                                                    "riesgo": riesgo, "descripcion": desc})
            self.root.after(0, self._mostrar)
        except Exception as e:
            self.root.after(0, self._error, str(e))

    def _mostrar(self):
        self.scanning = False
        self.btn_scan.config(state="normal", text="Escanear")
        for r in self.resultados:
            self.tabla.insert("", "end", values=(r["puerto"], r["servicio"], r["riesgo"], r["descripcion"]))
        if not self.resultados:
            messagebox.showinfo("Resultado", "No se encontraron puertos abiertos.")

    def _error(self, msg):
        self.scanning = False
        self.btn_scan.config(state="normal", text="Escanear")
        messagebox.showerror("Error", f"No se pudo escanear.\n{msg}\n\nAsegurate de tener Nmap instalado y ejecutar como administrador.")

    def _pdf(self):
        if not self.resultados:
            messagebox.showwarning("Aviso", "Haz un escaneo primero.")
            return
        if not PDF:
            messagebox.showerror("Error", "Instala reportlab: pip install reportlab")
            return
        ruta = filedialog.asksaveasfilename(defaultextension=".pdf", filetypes=[("PDF", "*.pdf")],
            initialfile=f"escaneo_{datetime.datetime.now().strftime('%Y%m%d_%H%M')}.pdf")
        if not ruta:
            return
        doc = SimpleDocTemplate(ruta, pagesize=A4)
        estilos = getSampleStyleSheet()
        estilos["BodyText"].leftIndent = 0
        contenido = [
            Paragraph("Informe de escaneo de puertos", estilos["Title"]),
            Paragraph(f"Fecha: {datetime.datetime.now().strftime('%d/%m/%Y %H:%M')}", estilos["BodyText"]),
            Spacer(1, 12),
        ]
        datos = [["Puerto", "Servicio", "Riesgo", "Descripcion"]]
        for r in self.resultados:
            datos.append([str(r["puerto"]), r["servicio"], r["riesgo"], r["descripcion"]])
        tabla = Table(datos, colWidths=[60, 110, 80, 270])
        tabla.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.grey),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, -1), 9),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.lightgrey]),
        ]))
        contenido.append(tabla)
        doc.build(contenido)
        messagebox.showinfo("Hecho", f"PDF guardado en:\n{ruta}")

if __name__ == "__main__":
    root = tk.Tk()
    App(root)
    root.mainloop()
