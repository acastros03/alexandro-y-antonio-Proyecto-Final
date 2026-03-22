import tkinter as tk
from tkinter import messagebox, ttk
from gestor_csv import GestorCSV   # Archivo que maneja los CSV

class AppGestor:
    def __init__(self, root):
        # Ventana principal
        self.root = root
        self.root.title("Sistema de Gestión de Clientes")
        self.root.geometry("900x600")

        # Cargamos el gestor de CSV (clientes, incidencias, servicios)
        self.gestor = GestorCSV()

        # Marco principal donde va todo
        self.marco_principal = tk.Frame(self.root, padx=20, pady=20)
        self.marco_principal.pack(fill=tk.BOTH, expand=True)

        # ---------------- BARRA SUPERIOR ----------------
        barra_superior = tk.Frame(self.marco_principal)
        barra_superior.pack(fill=tk.X, pady=10)

        tk.Label(barra_superior, text="Buscar:").pack(side=tk.LEFT)

        # Caja de búsqueda
        self.caja_busqueda = tk.Entry(barra_superior)
        self.caja_busqueda.pack(side=tk.LEFT, padx=10, expand=True, fill=tk.X)
        self.caja_busqueda.bind("<KeyRelease>", lambda e: self.actualizar_tabla_clientes())

        # Botón para crear cliente nuevo
        tk.Button(barra_superior, text="+ Nuevo Cliente", command=self.ventana_crear_cliente,
                  bg="#4CAF50", fg="white").pack(side=tk.LEFT, padx=5)

        # ---------------- TABLA PRINCIPAL ----------------
        self.tabla_clientes = ttk.Treeview(
            self.marco_principal,
            columns=("ID", "Nombre", "CIF", "Teléfono", "Dirección"),
            show='headings'
        )

        for columna in ("ID", "Nombre", "CIF", "Teléfono", "Dirección"):
            self.tabla_clientes.heading(columna, text=columna)
            self.tabla_clientes.column(columna, width=150)

        self.tabla_clientes.pack(fill=tk.BOTH, expand=True)

        # ---------------- BOTONES INFERIORES ----------------
        zona_botones = tk.Frame(self.marco_principal)
        zona_botones.pack(fill=tk.X, pady=10)

        tk.Button(zona_botones, text="Incidencias del Cliente",
                  command=self.ventana_incidencias_cliente,
                  bg="#8E24AA", fg="white").pack(side=tk.RIGHT, padx=5)

        tk.Button(zona_botones, text="Servicios del Cliente",
                  command=self.ventana_servicios_cliente,
                  bg="#3F51B5", fg="white").pack(side=tk.RIGHT, padx=5)

        tk.Button(zona_botones, text="Eliminar Cliente",
                  command=self.eliminar_cliente,
                  bg="#f44336", fg="white").pack(side=tk.RIGHT, padx=5)

        # Cargar tabla al inicio
        self.actualizar_tabla_clientes()

    # ---------------- ACTUALIZAR TABLA PRINCIPAL ----------------
    def actualizar_tabla_clientes(self):
        # Limpiar tabla
        for fila in self.tabla_clientes.get_children():
            self.tabla_clientes.delete(fila)

        texto_busqueda = self.caja_busqueda.get().lower()

        # Insertar clientes que coincidan
        for cliente in self.gestor.clientes:
            if texto_busqueda in cliente['Nombre'].lower() or texto_busqueda in cliente['CIF'].lower():
                self.tabla_clientes.insert("", tk.END,
                    values=(cliente['Id_Cliente'], cliente['Nombre'], cliente['CIF'],
                            cliente['Telefono'], cliente['Direccion']))

    # ---------------- VENTANA: NUEVO CLIENTE + INCIDENCIA ----------------
    def ventana_crear_cliente(self):
        ventana_nueva = tk.Toplevel(self.root)
        ventana_nueva.title("Agregar Nuevo Cliente")
        ventana_nueva.geometry("400x600")
        ventana_nueva.grab_set()

        campos_cliente = ["Nombre", "Teléfono", "CIF", "Dirección"]
        entradas_cliente = {}

        tk.Label(ventana_nueva, text="Datos del Cliente", font=("Arial", 14, "bold")).pack(pady=10)

        for campo in campos_cliente:
            marco_campo = tk.Frame(ventana_nueva, pady=10)
            marco_campo.pack(fill=tk.X, padx=20)
            tk.Label(marco_campo, text=campo, font=("Arial", 10, "bold")).pack(anchor=tk.W)
            entrada = tk.Entry(marco_campo)
            entrada.pack(fill=tk.X)
            entradas_cliente[campo] = entrada

        # ---------------- INCIDENCIA INICIAL ----------------
        tk.Label(ventana_nueva, text="Incidencia Inicial", font=("Arial", 14, "bold")).pack(pady=10)

        marco_desc = tk.Frame(ventana_nueva, pady=10)
        marco_desc.pack(fill=tk.X, padx=20)
        tk.Label(marco_desc, text="Descripción", font=("Arial", 10, "bold")).pack(anchor=tk.W)
        entrada_descripcion_incidencia = tk.Entry(marco_desc)
        entrada_descripcion_incidencia.pack(fill=tk.X)

        marco_severidad = tk.Frame(ventana_nueva, pady=10)
        marco_severidad.pack(fill=tk.X, padx=20)
        tk.Label(marco_severidad, text="Severidad", font=("Arial", 10, "bold")).pack(anchor=tk.W)

        selector_severidad = ttk.Combobox(marco_severidad, values=["Crítica", "Alta", "Media", "Baja"], state="readonly")
        selector_severidad.pack(fill=tk.X)

        # ---------------- GUARDAR CLIENTE ----------------
        def guardar_cliente():
            nombre = entradas_cliente["Nombre"].get().strip()
            telefono = entradas_cliente["Teléfono"].get().strip()
            cif = entradas_cliente["CIF"].get().strip()
            direccion = entradas_cliente["Dirección"].get().strip()

            descripcion_inc = entrada_descripcion_incidencia.get().strip()
            severidad_inc = selector_severidad.get().strip()

            # Validaciones básicas
            if len(nombre) < 3:
                messagebox.showerror("Error", "Nombre demasiado corto.")
                return
            if not self.gestor.validar_telefono(telefono):
                messagebox.showerror("Error", "Teléfono inválido.")
                return
            if not self.gestor.validar_direccion(direccion):
                messagebox.showerror("Error", "Dirección demasiado corta.")
                return
            if not descripcion_inc:
                messagebox.showerror("Error", "La incidencia no puede estar vacía.")
                return
            if not severidad_inc:
                messagebox.showerror("Error", "Seleccione una severidad.")
                return

            # Crear ID nuevo
            nuevo_id_cliente = str(max([int(c['Id_Cliente']) for c in self.gestor.clientes], default=0) + 1)

            # Guardar cliente
            nuevo_cliente = {
                'Id_Cliente': nuevo_id_cliente,
                'Nombre': nombre,
                'Telefono': telefono,
                'CIF': cif,
                'Direccion': direccion
            }

            self.gestor.clientes.append(nuevo_cliente)
            self.gestor._guardar(self.gestor.archivo_clientes,
                                 self.gestor.clientes,
                                 self.gestor.columnas_clientes)

            # Guardar incidencia inicial
            nuevo_id_incidencia = str(max([int(i['Id_Incidencia']) for i in self.gestor.incidencias], default=0) + 1)

            nueva_incidencia = {
                'Id_Incidencia': nuevo_id_incidencia,
                'Id_Cliente': nuevo_id_cliente,
                'Descripcion': descripcion_inc,
                'Severidad': severidad_inc
            }

            self.gestor.incidencias.append(nueva_incidencia)
            self.gestor._guardar(self.gestor.archivo_incidencias,
                                 self.gestor.incidencias,
                                 self.gestor.columnas_incidencias)

            messagebox.showinfo("Éxito", "Cliente e incidencia guardados.")
            self.actualizar_tabla_clientes()
            ventana_nueva.destroy()

        tk.Button(ventana_nueva, text="Guardar Cliente e Incidencia", command=guardar_cliente,
                  bg="#2196F3", fg="white", pady=10).pack(pady=20)

    # ---------------- ELIMINAR CLIENTE ----------------
    def eliminar_cliente(self):
        fila_seleccionada = self.tabla_clientes.selection()
        if not fila_seleccionada:
            return

        datos_fila = self.tabla_clientes.item(fila_seleccionada)
        id_cliente_seleccionado = str(datos_fila['values'][0])

        if messagebox.askyesno("Confirmar", "¿Eliminar cliente, incidencias y servicios?"):
            self.gestor.clientes = [c for c in self.gestor.clientes if c['Id_Cliente'] != id_cliente_seleccionado]
            self.gestor.incidencias = [i for i in self.gestor.incidencias if i['Id_Cliente'] != id_cliente_seleccionado]
            self.gestor.precios = [p for p in self.gestor.precios if p['Id_Cliente'] != id_cliente_seleccionado]

            self.gestor._guardar(self.gestor.archivo_clientes, self.gestor.clientes, self.gestor.columnas_clientes)
            self.gestor._guardar(self.gestor.archivo_incidencias, self.gestor.incidencias, self.gestor.columnas_incidencias)
            self.gestor._guardar(self.gestor.archivo_precios, self.gestor.precios, self.gestor.columnas_precios)

            self.actualizar_tabla_clientes()

    # ---------------- VENTANA: SERVICIOS ----------------
    def ventana_servicios_cliente(self):
        fila_seleccionada = self.tabla_clientes.selection()
        if not fila_seleccionada:
            messagebox.showwarning("Aviso", "Seleccione un cliente.")
            return

        datos_fila = self.tabla_clientes.item(fila_seleccionada)
        id_cliente_seleccionado = datos_fila['values'][0]
        nombre_cliente = datos_fila['values'][1]

        ventana_servicios = tk.Toplevel(self.root)
        ventana_servicios.title(f"Servicios de {nombre_cliente}")
        ventana_servicios.geometry("700x450")
        ventana_servicios.grab_set()

        tk.Label(ventana_servicios, text=f"Servicios contratados por {nombre_cliente}",
                 font=("Arial", 14, "bold")).pack(pady=10)

        self.tabla_servicios = ttk.Treeview(
            ventana_servicios,
            columns=("ID", "Servicio", "Descripción", "Precio"),
            show='headings'
        )

        for col in ("ID", "Servicio", "Descripción", "Precio"):
            self.tabla_servicios.heading(col, text=col)
            self.tabla_servicios.column(col, width=150)

        self.tabla_servicios.pack(fill=tk.BOTH, expand=True, padx=15, pady=10)

        servicios_cliente = self.gestor.obtener_servicios_cliente(id_cliente_seleccionado)
        for servicio in servicios_cliente:
            self.tabla_servicios.insert("", tk.END,
                values=(servicio['Id_Catalogo'], servicio['Servicio'], servicio['Descripcion'], servicio['Precio']))

        zona_botones = tk.Frame(ventana_servicios)
        zona_botones.pack(pady=15)

        tk.Button(zona_botones, text="Agregar Servicio",
                  command=lambda: self.ventana_agregar_servicio(id_cliente_seleccionado, self.tabla_servicios),
                  bg="#009688", fg="white", width=18, height=2).grid(row=0, column=0, padx=10)

        tk.Button(zona_botones, text="Eliminar Servicio",
                  command=lambda: self.eliminar_servicio(id_cliente_seleccionado, self.tabla_servicios),
                  bg="#e53935", fg="white", width=18, height=2).grid(row=0, column=1, padx=10)

        tk.Button(zona_botones, text="Volver Atrás",
                  command=ventana_servicios.destroy,
                  bg="#757575", fg="white", width=18, height=2).grid(row=0, column=2, padx=10)

    # ---------------- ELIMINAR SERVICIO ----------------
    def eliminar_servicio(self, id_cliente, tabla_servicios):
        fila_seleccionada = tabla_servicios.selection()
        if not fila_seleccionada:
            messagebox.showwarning("Aviso", "Seleccione un servicio para eliminar.")
            return

        datos_fila = tabla_servicios.item(fila_seleccionada)
        id_catalogo = str(datos_fila['values'][0]).strip()

        if not messagebox.askyesno("Confirmar", f"¿Eliminar el servicio con ID {id_catalogo}?"):
            return

        nueva_lista = []
        eliminado = False

        for servicio in self.gestor.precios:
            if servicio['Id_Catalogo'].strip() == id_catalogo:
                eliminado = True
                continue
            nueva_lista.append(servicio)

        if not eliminado:
            messagebox.showerror("Error", "No se pudo eliminar el servicio del CSV.")
            return

        self.gestor.precios = nueva_lista
        self.gestor._guardar(self.gestor.archivo_precios,
                             self.gestor.precios,
                             self.gestor.columnas_precios)

        tabla_servicios.delete(fila_seleccionada)
        messagebox.showinfo("Éxito", "Servicio eliminado correctamente.")

    # ---------------- VENTANA: INCIDENCIAS ----------------
    def ventana_incidencias_cliente(self):
        fila_seleccionada = self.tabla_clientes.selection()
        if not fila_seleccionada:
            messagebox.showwarning("Aviso", "Seleccione un cliente.")
            return

        datos_fila = self.tabla_clientes.item(fila_seleccionada)
        id_cliente_seleccionado = str(datos_fila['values'][0])
        nombre_cliente = datos_fila['values'][1]

        ventana_incidencias = tk.Toplevel(self.root)
        ventana_incidencias.title(f"Incidencias de {nombre_cliente}")
        ventana_incidencias.geometry("700x450")
        ventana_incidencias.grab_set()

        tk.Label(ventana_incidencias, text=f"Incidencias registradas por {nombre_cliente}",
                 font=("Arial", 14, "bold")).pack(pady=10)

        self.tabla_incidencias = ttk.Treeview(
            ventana_incidencias,
            columns=("ID", "Descripción", "Severidad"),
            show='headings'
        )

        for col in ("ID", "Descripción", "Severidad"):
            self.tabla_incidencias.heading(col, text=col)
            self.tabla_incidencias.column(col, width=200)

        self.tabla_incidencias.pack(fill=tk.BOTH, expand=True, padx=15, pady=10)

        incidencias_cliente = [i for i in self.gestor.incidencias if i['Id_Cliente'] == id_cliente_seleccionado]
        for inc in incidencias_cliente:
            self.tabla_incidencias.insert("", tk.END,
                values=(inc['Id_Incidencia'], inc['Descripcion'], inc['Severidad']))

        zona_botones = tk.Frame(ventana_incidencias)
        zona_botones.pack(pady=15)

        tk.Button(zona_botones, text="Eliminar Incidencia",
                  command=lambda: self.eliminar_incidencia(id_cliente_seleccionado, self.tabla_incidencias),
                  bg="#e53935", fg="white", width=18, height=2).grid(row=0, column=0, padx=10)

        tk.Button(zona_botones, text="Volver Atrás",
                  command=ventana_incidencias.destroy,
                  bg="#757575", fg="white", width=18, height=2).grid(row=0, column=1, padx=10)

    # ---------------- ELIMINAR INCIDENCIA ----------------
    def eliminar_incidencia(self, id_cliente, tabla_incidencias):
        fila_seleccionada = tabla_incidencias.selection()
        if not fila_seleccionada:
            messagebox.showwarning("Aviso", "Seleccione una incidencia para eliminar.")
            return

        datos_fila = tabla_incidencias.item(fila_seleccionada)
        id_incidencia = str(datos_fila['values'][0]).strip()

        if not messagebox.askyesno("Confirmar", f"¿Eliminar la incidencia con ID {id_incidencia}?"):
            return

        nueva_lista = []
        eliminado = False

        for incidencia in self.gestor.incidencias:
            if incidencia['Id_Incidencia'].strip() == id_incidencia:
                eliminado = True
                continue
            nueva_lista.append(incidencia)

        if not eliminado:
            messagebox.showerror("Error", "No se pudo eliminar la incidencia del CSV.")
            return

        self.gestor.incidencias = nueva_lista
        self.gestor._guardar(self.gestor.archivo_incidencias,
                             self.gestor.incidencias,
                             self.gestor.columnas_incidencias)

        tabla_incidencias.delete(fila_seleccionada)
        messagebox.showinfo("Éxito", "Incidencia eliminada correctamente.")

    # ---------------- AGREGAR SERVICIO ----------------
    def obtener_precios_base(self):
        precios_base = {}
        for servicio in self.gestor.precios:
            if servicio['Servicio'] not in precios_base:
                precios_base[servicio['Servicio']] = servicio['Precio']
        return precios_base

    def ventana_agregar_servicio(self, id_cliente, tabla_servicios):
        # Ventana para añadir un servicio nuevo al cliente
        ventana_agregar_servicio = tk.Toplevel(self.root)
        ventana_agregar_servicio.title("Agregar Servicio")
        ventana_agregar_servicio.geometry("350x350")
        ventana_agregar_servicio.grab_set()

        # Obtenemos los servicios base (para que el precio salga solo)
        precios_base = self.obtener_precios_base()
        lista_servicios_disponibles = list(precios_base.keys())

        # Selector del tipo de servicio
        marco_servicio = tk.Frame(ventana_agregar_servicio, pady=10)
        marco_servicio.pack(fill=tk.X, padx=20)
        tk.Label(marco_servicio, text="Servicio", font=("Arial", 10, "bold")).pack(anchor=tk.W)

        selector_servicio = ttk.Combobox(marco_servicio, values=lista_servicios_disponibles, state="readonly")
        selector_servicio.pack(fill=tk.X)

        # Descripción del servicio
        marco_descripcion = tk.Frame(ventana_agregar_servicio, pady=10)
        marco_descripcion.pack(fill=tk.X, padx=20)
        tk.Label(marco_descripcion, text="Descripción", font=("Arial", 10, "bold")).pack(anchor=tk.W)
        entrada_descripcion_servicio = tk.Entry(marco_descripcion)
        entrada_descripcion_servicio.pack(fill=tk.X)

        # Precio del servicio (se rellena solo)
        marco_precio = tk.Frame(ventana_agregar_servicio, pady=10)
        marco_precio.pack(fill=tk.X, padx=20)
        tk.Label(marco_precio, text="Precio", font=("Arial", 10, "bold")).pack(anchor=tk.W)

        entrada_precio_servicio = tk.Entry(marco_precio, state="readonly")
        entrada_precio_servicio.pack(fill=tk.X)

        # Cuando el usuario elige un servicio, rellenamos el precio automáticamente
        def actualizar_precio(evento):
            servicio_seleccionado = selector_servicio.get()
            entrada_precio_servicio.config(state="normal")
            entrada_precio_servicio.delete(0, tk.END)
            entrada_precio_servicio.insert(0, precios_base[servicio_seleccionado])
            entrada_precio_servicio.config(state="readonly")

        selector_servicio.bind("<<ComboboxSelected>>", actualizar_precio)

        # Guardar el servicio nuevo
        def guardar_servicio():
            servicio = selector_servicio.get()
            descripcion = entrada_descripcion_servicio.get().strip()
            precio = entrada_precio_servicio.get().strip()

            if not servicio:
                messagebox.showerror("Error", "Seleccione un servicio.")
                return
            if not descripcion:
                messagebox.showerror("Error", "La descripción no puede estar vacía.")
                return

            # Guardamos en el CSV
            self.gestor.agregar_servicio(id_cliente, servicio, descripcion, precio)

            # Lo añadimos a la tabla visual
            ultimo_servicio = self.gestor.precios[-1]
            tabla_servicios.insert("", tk.END,
                values=(ultimo_servicio['Id_Catalogo'], servicio, descripcion, precio))

            messagebox.showinfo("Éxito", "Servicio agregado correctamente.")
            ventana_agregar_servicio.destroy()

        tk.Button(ventana_agregar_servicio, text="Guardar Servicio", command=guardar_servicio,
                  bg="#2196F3", fg="white").pack(pady=20)


if __name__ == "__main__":
    root = tk.Tk()
    app = AppGestor(root)
    root.mainloop()
