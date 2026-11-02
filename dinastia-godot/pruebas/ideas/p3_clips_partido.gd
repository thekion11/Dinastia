extends BaseIdea
## Auditoría (2-11-2026, M-095): todo clip que el partido pide por su nombre existe en el AnimationPlayer de un futbolista
## de verdad (si no, `_ejecutar_accion` y `_animar` lo descartan en silencio y el jugador se queda quieto).

## Nombres que el partido 3D pide con una cadena literal (`_ejecutar_accion`, `quiere = ...`), más las tablas de clips.
const PEDIDOS := ["parado", "caminar", "trotar", "correr", "conducir", "celebrar", "portero_listo", "patear", "pase",
	"cabezazo", "dolor", "falta_barrida", "regate_finta", "regate_pausa", "arbitro_silbato"]

func _probar() -> void:
	_titulo("CLIPS DEL PARTIDO: LOS PEDIDOS EXISTEN EN UN FUTBOLISTA")
	var d := FutbolistaQ.crear(1.80)
	if d.is_empty():
		_comprobar(true, "(sin modelo de futbolista en este entorno)")
		return
	add_child(d["nodo"])
	FutbolistaQ.terminar(d, true)   ## igual que `PlayerSpawner` en el partido
	var ap: AnimationPlayer = d["anim"]
	var faltan: Array[String] = []
	var nombres: Array = PEDIDOS.duplicate()
	for tabla: Dictionary in [AnimQuaternius.CLIP_RECORTES, AnimQuaternius.CLIP_FUTBOL, AnimQuaternius.CLIP_FUTBOL_NUEVO]:
		nombres.append_array(tabla.keys())
	for n: String in nombres:
		if not ap.has_animation(n):
			faltan.append(n)
	_linea("  %d clips pedidos, el jugador tiene %d animaciones" % [nombres.size(), ap.get_animation_list().size()])
	_comprobar(faltan.is_empty(), "faltan %d de %d: %s" % [faltan.size(), nombres.size(), ", ".join(faltan)])
	## Cada categoría de variantes (golpeos, festejos, lamentos…) tiene al menos un clip real.
	var vacias: Array[String] = []
	var cats: Dictionary = AnimExtra.categorias()
	for cat: String in cats:
		if AnimExtra.variantes(ap, cat).is_empty():
			vacias.append(cat)
	_comprobar(vacias.is_empty(), "categorías de variantes sin ningún clip (%d de %d): %s" % [vacias.size(), cats.size(), ", ".join(vacias)])
	## CADA CLIP, USADO O DESCARTADO A PROPÓSITO (2-11-2026, M-095): los que nadie pide (ni por nombre, ni por tabla, ni
	## por categoría de variantes) se listan en `docs/05_referencia/clips_sin_uso.md` (CLIPS_LISTA=<ruta> lo reescribe).
	## El número no puede crecer sin decidirlo: si se añade un clip, se usa o se sube `MAX_SIN_USO` diciendo por qué.
	var usados := {}
	for n: String in nombres:
		usados[n] = true
	for cat: String in cats:
		for n: String in AnimExtra.variantes(ap, cat):
			usados[n] = true
	## Lo que se pide por código fuera de las tablas (visor/ y ui/), buscado como cadena literal.
	var codigo := _codigo_visor()
	var sin_uso: Array[String] = []
	for n: String in ap.get_animation_list():
		## `X_espejo` lo pide `motor_jugable_p9` sumando el sufijo cuando el jugador va por la izquierda.
		var base := n.trim_suffix("_espejo")
		var pedido := usados.has(n) or codigo.contains("\"%s\"" % n) or (base != n and (usados.has(base) or codigo.contains("\"%s\"" % base)))
		if not pedido:
			sin_uso.append(n)
	sin_uso.sort()
	_linea("  usados %d · sin uso %d de %d" % [ap.get_animation_list().size() - sin_uso.size(), sin_uso.size(), ap.get_animation_list().size()])
	if OS.get_environment("CLIPS_LISTA") != "":
		var f := FileAccess.open(OS.get_environment("CLIPS_LISTA"), FileAccess.WRITE)
		f.store_string("# Clips del futbolista que el juego no usa\n\nGenerado por `pruebas/ideas/p3_clips_partido` (CLIPS_LISTA=<ruta>). Son animaciones del paquete que ningún sistema pide: quedan como reserva; usarlas o descartarlas es decisión de cada pasada visual.\n\n" + "\n".join(sin_uso.map(func(s: String) -> String: return "- `%s`" % s)) + "\n")
	_comprobar(sin_uso.size() <= MAX_SIN_USO, "clips sin uso: %d (tope %d; si sube, úsalos o súbelo diciendo por qué)" % [sin_uso.size(), MAX_SIN_USO])
	d["nodo"].queue_free()

const MAX_SIN_USO := 4   ## 2-11: las 4 variantes «_mano» de centro y pase, de reserva (docs/05_referencia/clips_sin_uso.md)

func _codigo_visor() -> String:
	var t := ""
	for carpeta in ["res://visor", "res://ui"]:
		for f in DirAccess.get_files_at(carpeta):
			if f.ends_with(".gd"):
				t += FileAccess.get_file_as_string(carpeta + "/" + f)
	return t
