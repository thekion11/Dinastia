class_name PartidaArchivo
extends RefCounted
## EL ARCHIVO DE UNA PARTIDA (25-10-2026, paquete «guardado robusto»).
##
## `Partida` decide QUÉ se guarda; esto decide CÓMO llega al disco sin perderse:
##  - Formato con firma y huella: «DIN2» + tamaño sin comprimir + MD5 del JSON +
##    deflate. Antes solo había tamaño + deflate: un byte cambiado en medio del
##    texto podía descomprimir y parsear igual y cargar una partida estropeada en
##    silencio. Con la huella, cualquier bit cambiado se detecta y se tira de la
##    copia. Los guardados viejos (sin firma) se siguen leyendo.
##  - Escritura atómica: temporal → se relee y se comprueba entero → rotación de
##    copias → el temporal ocupa el sitio del principal con un renombrado.
##  - Tres copias rotativas (.bak, .bak2, .bak3): una partida rota hoy y la de
##    ayer también rota (disco malo, un fallo que se arrastró) aún tiene salida.
##  - Migración de versión: cada salto de versión tiene su paso, en orden.
##  - Tiempos del último guardado y de la última carga, para medir y avisar.

const MAGIA := "DIN2"
const TEMPORAL := ".tmp"
## La primera copia conserva el sufijo de siempre: los guardados de antes
## siguen encontrando su copia y las pruebas viejas no cambian.
const COPIAS := [".bak", ".bak2", ".bak3"]
## Tope de seguridad: ni un archivo con la cabecera rota reserva más que esto.
const MAX_CRUDO := 512 * 1024 * 1024

static var ms_guardado := 0
static var ms_carga := 0
static var bytes_guardado := 0

## Empaqueta el JSON ya convertido en bytes.
static func empaquetar(crudo: PackedByteArray) -> PackedByteArray:
	var salida := MAGIA.to_ascii_buffer()
	var tam := PackedByteArray()
	tam.resize(4)
	tam.encode_u32(0, crudo.size())
	salida.append_array(tam)
	salida.append_array(_md5(crudo))
	salida.append_array(crudo.compress(FileAccess.COMPRESSION_DEFLATE))
	return salida

## Devuelve los bytes del JSON, o vacío si el archivo no es una partida sana.
static func desempaquetar(b: PackedByteArray) -> PackedByteArray:
	if b.size() < 5:
		return PackedByteArray()
	if b.size() >= 24 and b.slice(0, 4).get_string_from_ascii() == MAGIA:
		var tam := b.decode_u32(4)
		if tam <= 0 or tam > MAX_CRUDO:
			return PackedByteArray()
		var crudo := b.slice(24).decompress(tam, FileAccess.COMPRESSION_DEFLATE)
		if crudo.size() != tam or _md5(crudo) != b.slice(8, 24):
			push_warning("PartidaArchivo: la huella no cuadra (archivo dañado)")
			return PackedByteArray()
		return crudo
	## Formato viejo (versión 1): tamaño little-endian + deflate, sin huella.
	var tam_v := b.decode_u32(0)
	if tam_v <= 0 or tam_v > MAX_CRUDO:
		return PackedByteArray()
	return b.slice(4).decompress(tam_v, FileAccess.COMPRESSION_DEFLATE)

static func _md5(b: PackedByteArray) -> PackedByteArray:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_MD5)
	h.update(b)
	return h.finish()

## Escribe con temporal, comprobación y rotación de copias. Si algo falla, el
## principal y sus copias quedan como estaban.
static func escribir(ruta: String, crudo: PackedByteArray) -> bool:
	var t0 := Time.get_ticks_msec()
	var paquete := empaquetar(crudo)
	var tmp := ruta + TEMPORAL
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Partida: no puedo escribir %s (error %d)" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_buffer(paquete)
	var ok := f.get_error() == OK
	f.close()
	## Se relee lo escrito y se vuelve a abrir entero: un disco lleno o una
	## escritura a medias se cazan aquí, antes de tocar el principal.
	if not ok or desempaquetar(FileAccess.get_file_as_bytes(tmp)) != crudo:
		push_error("Partida: el guardado temporal %s salió incompleto" % tmp)
		DirAccess.remove_absolute(tmp)
		return false
	if FileAccess.file_exists(ruta):
		_rotar(ruta)
	if DirAccess.rename_absolute(tmp, ruta) != OK:
		push_error("Partida: no puedo mover %s a su sitio" % tmp)
		return false
	bytes_guardado = paquete.size()
	ms_guardado = Time.get_ticks_msec() - t0
	return true

## .bak2 → .bak3, .bak → .bak2, principal → .bak. La más vieja se pierde.
static func _rotar(ruta: String) -> void:
	for i in range(COPIAS.size() - 1, 0, -1):
		var de := ruta + String(COPIAS[i - 1])
		if FileAccess.file_exists(de):
			DirAccess.remove_absolute(ruta + String(COPIAS[i]))
			DirAccess.rename_absolute(de, ruta + String(COPIAS[i]))
	DirAccess.remove_absolute(ruta + String(COPIAS[0]))
	DirAccess.rename_absolute(ruta, ruta + String(COPIAS[0]))

## Por orden de preferencia: principal, temporal entero, copias de la más nueva
## a la más vieja.
static func candidatos(ruta: String) -> Array[String]:
	var r: Array[String] = [ruta, ruta + TEMPORAL]
	for s: String in COPIAS:
		r.append(ruta + s)
	return r

static func sufijos() -> Array[String]:
	var r: Array[String] = ["", TEMPORAL]
	for s: String in COPIAS:
		r.append(s)
	return r

## MIGRACIÓN (M-399). Cada paso lleva un guardado de la versión N a la N+1;
## se aplican en orden hasta la actual. Un guardado de una versión MÁS NUEVA
## que el juego no se toca (lo rechaza `desde_instantanea`).
static func migrar(d: Dictionary, actual: int) -> Dictionary:
	var v := int(d.get("version", 0))
	if v >= actual:
		return d
	## 0 → 1: los guardados más antiguos no traían ni versión ni fecha.
	if v < 1:
		if not d.has("guardado"):
			d["guardado"] = 0
		v = 1
	## 1 → 2: cambió el ENVOLTORIO (firma + huella), no el contenido; solo se
	## marca la versión, y los historiales se recortan a sus topes al cargar.
	if v < 2:
		v = 2
	d["version"] = v
	return d
