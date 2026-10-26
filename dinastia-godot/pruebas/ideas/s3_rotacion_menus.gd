extends "res://pruebas/ideas/fugas_menus.gd"
## s3 (26-10-2026): ROTACIÓN DE NODOS EN LOS MENÚS. `fugas_menus` mide lo que QUEDA vivo (ya no crece);
## esta mide lo que se CREA y se libera en cada vuelta: cada nodo que entra en el árbol (`node_added`)
## cuenta, por fase y por la función que lo creó, para ver qué pestañas se rehacen enteras sin hacer falta.
## Objetivo (plan §8): la mitad de lo que se creaba el 26-10 (línea base medida aquí: ver sesion_3.md).
const LINEA_BASE := 111178
var _creados := 0
var _por_quien := {}
var _por_fase := {}
var _creados_prev := 0
var _detalle := false
## Un nodo que vuelve a entrar (la pantalla del menú muda el contenido de sitio) no es nuevo.
var _vistos := {}
var _reentradas := 0

func _ready() -> void:
	await get_tree().process_frame
	_titulo("ROTACIÓN DE NODOS al recorrer menús, pestañas y fichas")
	get_tree().node_added.connect(_al_entrar)
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	await _fotogramas(3)
	_p.call("_avanzar_semana")
	await _fotogramas(3)
	await _vuelta()
	_creados = 0
	_por_quien.clear()
	_por_fase.clear()
	_creados_prev = 0
	_reentradas = 0
	_detalle = true
	await _vuelta()
	_detalle = false
	_linea("  nodos creados en una vuelta (tras calentar): %d (y %d que solo se mudan de sitio)" % [_creados, _reentradas])
	for f in _por_fase:
		_linea("    %s: %d" % [f, int(_por_fase[f])])
	var claves := _por_quien.keys()
	claves.sort_custom(func(a, b): return int(_por_quien[a]) > int(_por_quien[b]))
	for i in mini(40, claves.size()):
		_linea("    %6d  %s" % [int(_por_quien[claves[i]]), claves[i]])
	if LINEA_BASE > 0:
		_comprobar(_creados * 2 <= LINEA_BASE, "una vuelta crea como mucho la mitad de nodos que antes (%d ≤ %d / 2)" % [_creados, LINEA_BASE])
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _al_entrar(n: Node) -> void:
	var id := n.get_instance_id()
	if _vistos.has(id):
		_reentradas += 1
		return
	_vistos[id] = true
	_creados += 1
	if not _detalle:
		return
	## Las cuatro funciones de `ui/` más cercanas en la pila: quién lo construye y desde dónde se pidió.
	var cadena: Array[String] = []
	for bt: ScriptBacktrace in Engine.capture_script_backtraces():
		for i in bt.get_frame_count():
			var f := bt.get_frame_file(i)
			if (f.contains("/ui/") or f.contains("/visor/")) and cadena.size() < 4:
				cadena.append("%s:%s" % [f.get_file().get_basename(), bt.get_frame_function(i)])
	var quien := " < ".join(cadena) if not cadena.is_empty() else "?"
	_por_quien[quien] = int(_por_quien.get(quien, 0)) + 1

func _fase(que: String) -> void:
	super._fase(que)
	if _detalle:
		_por_fase[que] = _creados - _creados_prev
	_creados_prev = _creados
