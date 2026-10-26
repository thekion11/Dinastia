class_name PartidaExportar
extends RefCounted
## EXPORTAR E IMPORTAR UNA PARTIDA A UN ARCHIVO (26-10-2026, plan §10, primer
## paso del guardado entre dispositivos).
##
## Exportar saca una partida de `user://partidas` a donde el jugador diga (un
## pendrive, una carpeta de la nube, Documentos del móvil) en el mismo formato
## DIN2 con huella de `PartidaArchivo`. Importar hace el camino contrario y es
## DESCONFIADO a propósito: el archivo viene de fuera, así que antes de añadirlo
## a la lista se comprueban la firma, la huella, el JSON, la versión (y se
## migra si es vieja) y que de verdad se pueda reconstruir el mundo. Nunca pisa
## una partida que ya existe: si el nombre choca, se devuelve `choca` y un nombre
## libre sugerido para que la interfaz lo pregunte.

## Extensiones que se aceptan al importar; la primera es la que se propone al
## exportar (la misma que usan los guardados internos).
const EXTENSIONES := [".dinastia", ".din2"]

## Lee una partida de la lista y la escribe en `destino`. Devuelve "" si fue
## bien o el motivo (ya traducido) si no. Se lee con respaldo: si el principal
## está roto se exporta la copia buena, no el archivo estropeado.
static func exportar(nombre: String, destino: String) -> String:
	var d := Partida._leer_con_respaldo(Partida.ruta_de(nombre))
	if d.is_empty():
		return Idiomas.t("No se encontró esa partida o está dañada.")
	if destino.get_extension() == "":
		destino += String(EXTENSIONES[0])
	var paquete := PartidaArchivo.empaquetar(JSON.stringify(d).to_utf8_buffer())
	var f := FileAccess.open(destino, FileAccess.WRITE)
	if f == null:
		return Idiomas.t("No se pudo escribir el archivo (¿carpeta sin permiso?).")
	f.store_buffer(paquete)
	var ok := f.get_error() == OK
	f.close()
	## Se relee lo escrito: un archivo exportado a medias no debe parecer bueno.
	if not ok or PartidaArchivo.desempaquetar(FileAccess.get_file_as_bytes(destino)).is_empty():
		return Idiomas.t("El archivo exportado salió incompleto.")
	return ""

## Comprueba un archivo de fuera sin tocar la lista de partidas.
## Devuelve {"error": String} o {"datos": Dictionary, "club": String}.
static func leer_externo(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {"error": Idiomas.t("El archivo no existe.")}
	var b := FileAccess.get_file_as_bytes(ruta)
	## Solo el formato con firma: el viejo (sin huella) no deja saber si un
	## archivo que llega de otro aparato llegó entero.
	if b.size() < 24 or b.slice(0, 4).get_string_from_ascii() != PartidaArchivo.MAGIA:
		return {"error": Idiomas.t("No es un archivo de partida de Dinastía.")}
	var crudo := PartidaArchivo.desempaquetar(b)
	if crudo.is_empty():
		return {"error": Idiomas.t("El archivo está dañado o fue modificado (la huella no cuadra).")}
	var j := JSON.new()
	if j.parse(crudo.get_string_from_utf8()) != OK or not (j.data is Dictionary):
		return {"error": Idiomas.t("El archivo está dañado: su contenido no se puede leer.")}
	var d: Dictionary = j.data
	var v := int(d.get("version", 0))
	if v > Partida.VERSION:
		return {"error": Idiomas.t("La partida es de una versión más nueva del juego (%d > %d). Actualiza Dinastía para abrirla.") % [v, Partida.VERSION]}
	for k: String in ["clubes", "ligas", "mi_club", "semilla", "anio", "semana"]:
		if not d.has(k):
			return {"error": Idiomas.t("Al archivo le faltan datos de la partida.")}
	d = PartidaArchivo.migrar(d, Partida.VERSION)
	return {"datos": d, "club": String(Partida._cabecera_de(d).get("club", ""))}

## ¿Hay ya una partida con ese nombre (principal, temporal o copias)?
static func existe(nombre: String) -> bool:
	for suf: String in PartidaArchivo.sufijos():
		if FileAccess.file_exists(Partida.ruta_de(nombre) + suf):
			return true
	return false

## «Nombre», «Nombre (2)», «Nombre (3)»… el primero que no esté cogido.
static func nombre_libre(base: String) -> String:
	base = base.validate_filename().strip_edges()
	if base.is_empty():
		base = "importada"
	if not existe(base):
		return base
	var i := 2
	while existe("%s (%d)" % [base, i]):
		i += 1
	return "%s (%d)" % [base, i]

## Nombre propuesto para un archivo: su nombre sin extensión.
static func nombre_de_archivo(ruta: String) -> String:
	return ruta.get_file().get_basename()

## Importa `ruta` como la partida `nombre` (vacío = el nombre del archivo).
## Devuelve {"ok": true, "nombre"} o {"error"} o, si el nombre ya existe,
## {"choca": true, "sugerido"} sin escribir nada.
static func importar(ruta: String, nombre: String = "") -> Dictionary:
	var r := leer_externo(ruta)
	if r.has("error"):
		return r
	if nombre.strip_edges().is_empty():
		nombre = nombre_de_archivo(ruta)
	nombre = nombre.validate_filename().strip_edges()
	if nombre.is_empty():
		nombre = "importada"
	if existe(nombre):
		return {"choca": true, "sugerido": nombre_libre(nombre)}
	## Se reconstruye el mundo de prueba antes de añadirlo: un archivo con la
	## huella bien pero con datos que el juego no entiende no entra en la lista.
	## (Reconstruir toca estado global, igual que cargar: es lo que se hará al abrirla.)
	if Partida.desde_instantanea(r["datos"]) == null:
		return {"error": Idiomas.t("La partida no se pudo abrir con esta versión del juego.")}
	if not PartidaArchivo.escribir(Partida.ruta_de(nombre), JSON.stringify(r["datos"]).to_utf8_buffer()):
		return {"error": Idiomas.t("No se pudo guardar la partida importada.")}
	return {"ok": true, "nombre": nombre}

## Carpeta por defecto para exportar: Documentos si el sistema la da (en Android
## e iOS es lo más parecido a «donde el jugador lo encuentra»), si no user://.
static func carpeta_por_defecto() -> String:
	var doc := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if not doc.is_empty() and DirAccess.dir_exists_absolute(doc):
		return doc
	return OS.get_user_data_dir()
