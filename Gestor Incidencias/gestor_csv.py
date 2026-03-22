import csv
import os
import re

class GestorCSV:
    def __init__(self):
        # Carpeta donde está este archivo (para que encuentre los CSV siempre)
        self.ruta_dir = os.path.dirname(os.path.abspath(__file__))
        # Rutas completas de los CSV
        self.archivo_clientes = os.path.join(self.ruta_dir, 'Clientes.csv')
        self.archivo_incidencias = os.path.join(self.ruta_dir, 'Incidencias.csv')
        self.archivo_precios = os.path.join(self.ruta_dir, 'Automatizacion_Precio.csv')
        # Columnas que deben tener los CSV (para escribirlos bien)
        self.columnas_clientes = ['Id_Cliente', 'Nombre', 'Telefono', 'CIF', 'Direccion']
        self.columnas_incidencias = ['Id_Incidencia', 'Id_Cliente', 'Descripcion', 'Severidad']
        self.columnas_precios = ['Id_Catalogo', 'Id_Cliente', 'Servicio', 'Descripcion', 'Precio']
        # Cargamos los CSV en memoria (listas de diccionarios)
        self.clientes = self._leer(self.archivo_clientes)
        self.incidencias = self._leer(self.archivo_incidencias)
        self.precios = self._leer(self.archivo_precios)

    def _leer(self, archivo):
        # Si el archivo no existe, devuelvo lista vacía
        if not os.path.exists(archivo): return []
        # Leemos el CSV y lo convertimos en lista de diccionarios
        with open(archivo, 'r', encoding='utf-8') as f:
            return list(csv.DictReader(f))

    def _guardar(self, archivo, datos, columnas):
        # Guarda una lista de diccionarios en un CSV
        try:
            with open(archivo, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=columnas)
                writer.writeheader()
                writer.writerows(datos)
            return True
        except Exception as e:
            print(f" Error al guardar: {e}")
            return False

    # ---------------- VALIDACIONES ----------------

    def validar_telefono(self, telefono):
        # Acepta números con espacios y opcionalmente un +
        patron = r'^\+?[\d\s]{9,15}$'
        return bool(re.match(patron, telefono))

    def validar_direccion(self, direccion):
        # Que tenga al menos 5 caracteres
        return len(direccion.strip()) >= 5

    # ---------------- AUTOMATIZACIÓN DE PRECIOS ----------------

    def obtener_servicios_cliente(self, id_cliente):
        # Devuelve todos los servicios que pertenecen a un cliente
        return [p for p in self.precios if p['Id_Cliente'] == str(id_cliente)]

    def agregar_servicio(self, id_cliente, servicio, descripcion, precio):
        # Generamos un nuevo ID_Catalogo automático
        nuevo_id = str(max([int(p['Id_Catalogo']) for p in self.precios], default=0) + 1)
        # Creamos el nuevo servicio
        nuevo = {
            'Id_Catalogo': nuevo_id,
            'Id_Cliente': str(id_cliente),
            'Servicio': servicio,
            'Descripcion': descripcion,
            'Precio': precio
        }
        # Lo añadimos a la lista y guardamos el CSV
        self.precios.append(nuevo)
        self._guardar(self.archivo_precios, self.precios, self.columnas_precios)
        return True

    # ---------------- BÚSQUEDA MANUAL ----------------

    def buscar_manual(self):
        print("\n" + " BÚSQUEDA POR NOMBRE O INCIDENCIA ".center(50, "="))
        print("1. Buscar Cliente por Nombre")
        print("2. Buscar en el texto de Incidencias")
        op = input("Seleccione tipo de búsqueda: ")

        if op == "1":
            # Buscar clientes por nombre
            nombre_buscado = input("Introduce el nombre (o parte de él): ").strip().lower()
            encontrados = [c for c in self.clientes if nombre_buscado in c['Nombre'].lower()]
            
            if encontrados:
                print(f"\n--- Se han encontrado {len(encontrados)} clientes ---")
                for cliente in encontrados:
                    self._imprimir_ficha_completa(cliente)
            else:
                print("❌ No se encontró ningún cliente con ese nombre.")

        elif op == "2":
            # Buscar incidencias por palabra clave
            termino = input("Palabra clave de la incidencia: ").lower()
            encontradas = [i for i in self.incidencias if termino in i['Descripcion'].lower()]
            if encontradas:
                print(f"\n--- INCIDENCIAS ENCONTRADAS ({len(encontradas)}) ---")
                for inc in encontradas:
                    c = next((cl for cl in self.clientes if cl['Id_Cliente'] == inc['Id_Cliente']), {"Nombre": "Desconocido"})
                    print(f"Incidencia: {inc['Id_Incidencia']} | Cliente: {c['Nombre']} | [{inc['Severidad']}]")
                    print(f"   Detalle: {inc['Descripcion']}\n")
            else:
                print("❌ No hay coincidencias en las descripciones.")

    # ---------------- FICHA COMPLETA ----------------

    def _imprimir_ficha_completa(self, c):
        # Muestra toda la info de un cliente en consola
        print("\n" + "█" * 50)
        print(f"ID: {c['Id_Cliente']} | NOMBRE: {c['Nombre']}")
        print(f"CIF: {c['CIF']} | TEL: {c['Telefono']}")
        print(f"DIRECCIÓN: {c['Direccion']}")
        # Incidencias del cliente
        relacionadas = [i for i in self.incidencias if i['Id_Cliente'] == c['Id_Cliente']]
        if relacionadas:
            print(f"\nINCIDENCIAS REGISTRADAS ({len(relacionadas)}):")
            for i in relacionadas:
                icon = "🔴" if i['Severidad'] == "Crítica" else "🟠" if i['Severidad'] == "Alta" else "🟡"
                print(f"  {icon} [{i['Severidad']}] {i['Descripcion']}")
        else:
            print("\n Sin incidencias.")
        # Servicios del cliente
        servicios = self.obtener_servicios_cliente(c['Id_Cliente'])
        if servicios:
            print(f"\nSERVICIOS CONTRATADOS ({len(servicios)}):")
            for s in servicios:
                print(f"  💼 {s['Servicio']} - {s['Precio']}€")
                print(f"     {s['Descripcion']}")
        else:
            print("\n Sin servicios contratados.")

        print("█" * 50)

    # ---------------- ELIMINAR CLIENTE ----------------

    def eliminar_cliente(self):
        # Elimina cliente + incidencias + servicios desde consola
        nombre_borrar = input("\nNombre del cliente a eliminar: ").strip().lower()
        encontrados = [c for c in self.clientes if nombre_borrar in c['Nombre'].lower()]

        if not encontrados:
            print(" No se encontró ningún cliente con ese nombre.")
            return

        if len(encontrados) > 1:
            print("\n Se han encontrado varios clientes. Por favor, sea más específico:")
            for c in encontrados:
                print(f" - {c['Nombre']} (ID: {c['Id_Cliente']})")
            return

        cliente = encontrados[0]
        id_cliente = cliente['Id_Cliente']

        confirmar = input(f"¿Desea borrar a '{cliente['Nombre']}' y todo su historial? (S/N): ").upper()
        if confirmar == 'S':
            # Borramos todo lo relacionado con ese cliente
            self.clientes = [c for c in self.clientes if c['Id_Cliente'] != id_cliente]
            self.incidencias = [i for i in self.incidencias if i['Id_Cliente'] != id_cliente]
            self.precios = [p for p in self.precios if p['Id_Cliente'] != id_cliente]
            # Guardamos los CSV actualizados
            self._guardar(self.archivo_clientes, self.clientes, self.columnas_clientes)
            self._guardar(self.archivo_incidencias, self.incidencias, self.columnas_incidencias)
            self._guardar(self.archivo_precios, self.precios, self.columnas_precios)

            print(f" '{cliente['Nombre']}' ha sido eliminado junto con incidencias y servicios.")
        else:
            print("Operación cancelada.")

    # ---------------- AGREGAR CLIENTE ----------------

    def agregar_cliente_manual(self):
        #Agregor cliente desde consola con validaciones básicas
        print("\n  NUEVO CLIENTE ")
        nombre = input("Nombre: ").strip()
        while len(nombre) < 3:
            nombre = input("Nombre demasiado corto. Intente de nuevo: ").strip()

        nuevo_id = str(max([int(c['Id_Cliente']) for c in self.clientes], default=0) + 1)

        nuevo = {
            'Id_Cliente': nuevo_id,
            'Nombre': nombre,
            'Telefono': input("Teléfono: "),
            'CIF': input("CIF: "),
            'Direccion': input("Dirección: ")
        }

        self.clientes.append(nuevo)
        if self._guardar(self.archivo_clientes, self.clientes, self.columnas_clientes):
            print(f" Cliente guardado con ID {nuevo_id}")


# ---------------- MENÚ ----------------

def menu():
    g = GestorCSV()
    while True:
        print("\n" + " GESTIÓN DE CLIENTES ".center(40, "■"))
        print("1. Ver lista de clientes")
        print("2. Buscar (por Nombre o Incidencia)")
        print("3. Agregar cliente")
        print("4. Eliminar cliente (por Nombre)")
        print("5. Ver servicios de un cliente")
        print("6. Salir")

        op = input("\nElija una opción: ")

        if op == "1":
            print(f"\n{'NOMBRE':<25} | {'CIF':<12}")
            print("-" * 40)
            for c in g.clientes:
                print(f"{c['Nombre']:<25} | {c['CIF']:<12}")

        elif op == "2":
            g.buscar_manual()

        elif op == "3":
            g.agregar_cliente_manual()

        elif op == "4":
            g.eliminar_cliente()

        elif op == "5":
            idc = input("ID del cliente: ")
            servicios = g.obtener_servicios_cliente(idc)
            if servicios:
                print("\nSERVICIOS:")
                for s in servicios:
                    print(f"- {s['Servicio']} | {s['Precio']}€")
                    print(f"  {s['Descripcion']}")
            else:
                print("Este cliente no tiene servicios registrados.")

        elif op == "6":
            break


if __name__ == "__main__":
    menu()
