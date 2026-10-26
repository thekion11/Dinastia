extends BaseIdea
## PRUEBA DIFERENCIAL DEL SONIDO (fase 0, 25-10-2026).
##
## Para partir `Sonido._sintetizar` (tres funciones de ~380 líneas) en recetas pequeñas
## SIN cambiar ni una muestra hace falta algo más fino que «suena / no suena»: la huella
## SHA-256 de los bytes de cada `AudioStreamWAV`. Se toma de cada sonido del catálogo en
## las cuatro variantes del juego (`sal` = 0, 0.25, 0.5, 0.75) y en `sal` = 1.0, que es la
## que usa `banco_p16`.
##
##   F0S_ETIQUETA=antes herramientas/ideas.sh f0s_huellas_sonido   → guarda la referencia
##   herramientas/ideas.sh f0s_huellas_sonido                      → compara con ella
##
## Las huellas se escriben en `/tmp/aud/f0s_<etiqueta>.json`. Si no hay referencia (otra
## máquina, contenedor nuevo), la comparación se salta y quedan solo las comprobaciones de
## estructura: no se guarda una referencia en el repo porque `sin()`/`exp()` pueden
## redondear distinto en otra CPU y la prueba daría falsos fallos.

const DIR := "/tmp/aud"
const SALES := [0.0, 0.25, 0.5, 0.75, 1.0]

## Los sonidos que el pulido de audio (paso 4) cambió A PROPÓSITO: se espera que su huella
## difiera de la referencia de antes. Todos los demás tienen que quedar idénticos.
## Paso 4 (25-10-2026): `_mezclar()` ahora alarga el destino en vez de tirar la cola; estas
## son las 30 recetas que perdían una parte (19 de forma audible, >5 % del pico; las 11 de
## la última línea, colas casi mudas de 0-4 %).
const RETOCADOS: Array[String] = ["roja", "moneda", "atajada", "trofeo", "cambio",
	"saque_puerta", "rebote", "gol_chilena", "alarido_atajada", "animador_grada",
	"sesion_tactica", "reunion_directiva", "elecciones_club", "rumor_fichaje",
	"celebracion_grupal", "festejo_hinchada_extra", "tarjeta_banco", "ventaja", "cambio_ritmo",
	"corner", "lesion", "travesano", "abucheo", "gol_cabeza", "gol_falta", "gol_penal", "despeje",
	"premio_liga", "remontada", "choque_coche"]

## Lo que se pierda al final del buffer por encima de este pico relativo cuenta como
## recorte. Cero: con `_mezclar` alargando el destino no se tiene que perder nada.
const UMBRAL_RECORTE := 0.0

## Los sonidos de interfaz (clics, menús y avisos) cuyo nivel se compara en la tabla.
const INTERFAZ := ["clic", "clic_suave", "menu_mover", "menu_aceptar", "menu_atras",
	"menu_cambio", "menu_seccion", "abrir", "cerrar", "error", "aviso", "correo", "guardado",
	"moneda", "logro", "seleccionar", "deseleccionar", "arrastrar", "soltar", "desbloqueo",
	"nivel_subido", "notificacion", "confirmar", "cancelar", "deslizar", "cambio"]

func _probar() -> void:
	_titulo("SONIDO: huellas de cada muestra (fase 0, f0s)")
	var etiqueta := OS.get_environment("F0S_ETIQUETA")
	if etiqueta == "":
		etiqueta = "despues"
	var huellas := {}
	var sin_receta: Array[String] = []
	for nombre: String in Sonido.NOMBRES:
		var lista: Array = []
		for sal: float in SALES:
			var w: AudioStreamWAV = Sonido._sintetizar(nombre, sal)
			if w.data.is_empty():
				sin_receta.append(nombre)
			lista.append(_sha(w.data))
		huellas[nombre] = lista
	_comprobar(sin_receta.is_empty(), "todos los nombres del catálogo tienen receta (%s)" % (
		"todos" if sin_receta.is_empty() else ", ".join(sin_receta)))
	var unicos := {}
	for n: String in Sonido.NOMBRES:
		unicos[n] = true
	_comprobar(unicos.size() == Sonido.NOMBRES.size(), "sin nombres repetidos en el catálogo (%d)" % Sonido.NOMBRES.size())
	_comprobar(Sonido._sintetizar("no_existe", 0.0).data.is_empty(), "un nombre que no existe da un sonido vacío, no un error")
	_despacho()
	_tamanos()

	DirAccess.make_dir_recursive_absolute(DIR)
	var ruta := "%s/f0s_%s.json" % [DIR, etiqueta]
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	_comprobar(f != null, "se escriben las huellas en %s" % ruta)
	if f != null:
		f.store_string(JSON.stringify(huellas, " ", true))
		f.close()

	var ref_ruta := "%s/f0s_antes.json" % DIR
	if etiqueta == "antes" or not FileAccess.file_exists(ref_ruta):
		_linea("  (sin comparación: esta pasada ES la referencia o no hay referencia)")
	else:
		_comparar(huellas, JSON.parse_string(FileAccess.get_file_as_string(ref_ruta)))
	_medir()

## La tabla de despacho es el nombre: `_receta_<nombre>`. Cada nombre del catálogo tiene
## su receta y no queda ninguna receta huérfana (una receta sin nombre en `NOMBRES` no
## suena nunca: `banco()` rechaza lo que no está en el catálogo).
func _despacho() -> void:
	var sin_funcion: Array[String] = []
	for n: String in Sonido.NOMBRES:
		if not Sonido.has_method("_receta_" + n):
			sin_funcion.append(n)
	var huerfanas: Array[String] = []
	for met: Dictionary in Sonido.get_method_list():
		var nm := String(met["name"])
		if nm.begins_with("_receta_") and not Sonido.NOMBRES.has(nm.trim_prefix("_receta_")) and not huerfanas.has(nm):
			huerfanas.append(nm)
	_comprobar(sin_funcion.is_empty(), "cada nombre tiene su función `_receta_` (%s)" % ("todos" if sin_funcion.is_empty() else "faltan: " + ", ".join(sin_funcion)))
	_comprobar(huerfanas.is_empty(), "ninguna `_receta_` sin nombre en el catálogo (%s)" % ("ninguna" if huerfanas.is_empty() else ", ".join(huerfanas)))

## Las capas del sonido no vuelven a crecer en funciones gigantes: ninguna pasa de 100
## líneas (la fase 0 partió tres `match` de ~380).
func _tamanos() -> void:
	var largas: Array[String] = []
	for f: String in DirAccess.get_files_at("res://nucleo"):
		if not (f.begins_with("sonido") and f.ends_with(".gd")):
			continue
		var lineas := FileAccess.get_file_as_string("res://nucleo/" + f).split("\n")
		var actual := ""
		var desde := 0
		for i in lineas.size() + 1:
			var l: String = lineas[i] if i < lineas.size() else "func _fin"
			if l.begins_with("func ") or l.begins_with("static func "):
				if actual != "" and i - desde > 100:
					largas.append("%s:%s (%d)" % [f, actual, i - desde])
				actual = l.get_slice("(", 0).trim_prefix("static ").trim_prefix("func ")
				desde = i
	_comprobar(largas.is_empty(), "ninguna función de sonido*.gd pasa de 100 líneas (%s)" % ("ninguna" if largas.is_empty() else ", ".join(largas)))

## Cada sonido de la referencia tiene que dar EXACTAMENTE las mismas huellas, salvo los
## que el pulido cambió a propósito (`RETOCADOS`), que tienen que haber cambiado.
func _comparar(ahora: Dictionary, antes: Variant) -> void:
	_comprobar(antes is Dictionary and not (antes as Dictionary).is_empty(), "la referencia de antes se lee")
	if not antes is Dictionary:
		return
	var ref: Dictionary = antes
	var distintos: Array[String] = []
	var faltan: Array[String] = []
	var retocados_iguales: Array[String] = []
	for nombre: String in ref:
		if not ahora.has(nombre):
			faltan.append(nombre)
			continue
		var igual: bool = ahora[nombre] == ref[nombre]
		if RETOCADOS.has(nombre):
			if igual:
				retocados_iguales.append(nombre)
		elif not igual:
			distintos.append(nombre)
	_comprobar(faltan.is_empty(), "no falta ningún sonido de la referencia (%s)" % ("ninguno" if faltan.is_empty() else ", ".join(faltan)))
	_comprobar(distintos.is_empty(), "%d sonidos × %d variantes idénticos byte a byte a la referencia (distintos: %s)" % [
		ref.size() - RETOCADOS.size(), SALES.size(), "ninguno" if distintos.is_empty() else ", ".join(distintos)])
	_comprobar(retocados_iguales.is_empty(), "los %d retocados a propósito sí cambiaron (%s)" % [RETOCADOS.size(),
		"todos" if retocados_iguales.is_empty() else "sin cambio: " + ", ".join(retocados_iguales)])

## Medidas de calidad de las cuatro variantes del juego, sobre un ESPÍA: una copia de
## `Sonido` (fuera del árbol, sin hilo) cuyo `_mezclar` apunta lo que se pierde.
##  · saturadas: muestras pegadas al tope de 16 bits (`_mezclar` recorta a ±1, así que una
##    mezcla que se pasa se aplana ahí y suena áspera).
##  · recortado: hasta el 25-10-2026 `_mezclar` no alargaba el destino, y si una capa con
##    retraso acababa después que el buffer su cola se tiraba (el sonido se cortaba en seco).
##    Se mide el pico de lo tirado respecto del pico del sonido entero.
func _medir() -> void:
	var espia := _espia()
	_comprobar(espia != null, "se monta el espía de `_mezclar`")
	if espia == null:
		return
	var saturados: Array[String] = []
	var recortados: Array[String] = []
	for nombre: String in Sonido.NOMBRES:
		var peor_sat := 0
		var peor_rec := 0.0
		for v in Sonido.VARIANTES:
			espia.set("perdido", 0.0)
			var datos: PackedByteArray = espia.call("_sintetizar", nombre, float(v) / float(Sonido.VARIANTES)).data
			var m := _metricas(datos)
			peor_sat = maxi(peor_sat, int(m["saturadas"]))
			peor_rec = maxf(peor_rec, float(espia.get("perdido")) * 32767.0 / float(maxi(1, int(m["pico"]))))
		if peor_sat > 0:
			saturados.append("%s(%d)" % [nombre, peor_sat])
		if peor_rec > UMBRAL_RECORTE:
			recortados.append("%s(%.0f%%)" % [nombre, peor_rec * 100.0])
	espia.free()
	_linea("  medida · saturados: %s" % ("ninguno" if saturados.is_empty() else ", ".join(saturados)))
	_linea("  medida · recortados (pico de lo tirado / pico del sonido): %s" % ["ninguno" if recortados.is_empty() else ", ".join(recortados)])
	_comprobar(saturados.is_empty(), "ningún sonido satura (muestras en el tope de 16 bits)")
	_comprobar(recortados.is_empty(), "ninguna receta pierde la cola de una capa (`_mezclar` alarga el destino)")
	_niveles_interfaz()

## Los clics y avisos de la interfaz, uno al lado del otro: pico y duración. Es la tabla
## con la que se igualan (un clic el doble de fuerte que su vecino se nota a la tercera vez).
func _niveles_interfaz() -> void:
	for n: String in INTERFAZ:
		var w: AudioStreamWAV = Sonido._sintetizar(n, 0.5)
		var m := _metricas(w.data)
		_linea("  nivel · %-14s pico %5d (%5.1f dBFS)  %.3f s" % [n, int(m["pico"]),
			linear_to_db(float(m["pico"]) / 32767.0), float(w.data.size() / 2) / float(Sonido.FRECUENCIA)])

## Una subclase de `sonido.gd` hecha al vuelo cuyo `_mezclar` hace la mezcla de siempre
## (`super`) y DESPUÉS guarda el pico de lo que haya quedado fuera del destino.
func _espia() -> Node:
	var g := GDScript.new()
	g.source_code = "\n".join([
		"extends \"res://nucleo/sonido.gd\"",
		"var perdido := 0.0",
		"func _mezclar(destino: PackedFloat32Array, fuente: PackedFloat32Array, retraso: float = 0.0) -> void:",
		"\tsuper(destino, fuente, retraso)",
		"\tvar off := int(retraso * float(FRECUENCIA))",
		"\tfor i in range(maxi(0, destino.size() - off), fuente.size()):",
		"\t\tperdido = maxf(perdido, absf(fuente[i]))",
		""])
	if g.reload() != OK:
		return null
	return g.new() as Node

func _metricas(datos: PackedByteArray) -> Dictionary:
	var n := datos.size() / 2
	var pico := 0
	var sat := 0
	for i in n:
		var a := absi(datos.decode_s16(i * 2))
		pico = maxi(pico, a)
		if a >= 32767:
			sat += 1
	return {"pico": pico, "saturadas": sat}

func _sha(datos: PackedByteArray) -> String:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(datos)
	return h.finish().hex_encode()
