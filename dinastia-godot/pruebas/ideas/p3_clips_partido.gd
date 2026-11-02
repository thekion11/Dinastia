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
