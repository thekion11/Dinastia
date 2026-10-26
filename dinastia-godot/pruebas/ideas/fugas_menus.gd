extends BaseIdea
## FUGAS DE NODOS AL ABRIR Y CERRAR MENÚS Y FICHAS (25-10-2026). `estres_menus` veía crecer la
## cuenta de nodos de la Principal (1151 → 2011). Parte de eso es legítimo (pestañas que se pintan
## perezosamente la primera vez), así que aquí se hace UNA vuelta de calentamiento que visita todo,
## se mide, y luego N vueltas iguales: si los nodos siguen subiendo, algo queda sin liberar.
## Pocos fotogramas: en headless cada uno es lento.
const VUELTAS := 3
const MARGEN := 40
var _p: Node

func _ready() -> void:
	await get_tree().process_frame
	_titulo("FUGAS DE NODOS: menús laterales, pestañas y fichas")
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	await _fotogramas(3)
	_p.call("_avanzar_semana")
	await _fotogramas(3)
	await _vuelta()
	var c1 := _contar(get_tree().root)
	var h1 := _histo(_p, {})
	var o1 := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var obj1 := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	for _i in VUELTAS:
		await _vuelta()
	var c2 := _contar(get_tree().root)
	var h2 := _histo(_p, {})
	var o2 := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var obj2 := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	_linea("  huérfanos %d → %d; objetos %d → %d" % [o1, o2, obj1, obj2])
	_linea("  nodos tras calentar %d, tras %d vueltas más %d" % [c1, VUELTAS, c2])
	for k in h2:
		var d: int = int(h2[k]) - int(h1.get(k, 0))
		if d > 2:
			_linea("    +%d %s" % [d, k])
	_comprobar(c2 <= c1 + MARGEN, "tras %d ciclos abrir/cerrar los nodos vuelven cerca del valor inicial (%d → %d, margen %d)" % [VUELTAS, c1, c2, MARGEN])
	## Nodos sacados del árbol con remove_child y nunca liberados (popups, filas viejas).
	_comprobar(o2 <= o1 + 5, "sin nodos huérfanos nuevos tras los ciclos (%d → %d)" % [o1, o2])
	## Objetos vivos (Tweens, recursos, nodos retenidos por señales o Callables).
	_comprobar(obj2 <= obj1 + 4 * MARGEN, "los objetos vivos no crecen sin parar (%d → %d)" % [obj1, obj2])
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _fotogramas(n: int) -> void:
	for _i in n:
		await get_tree().process_frame

## Una vuelta determinista: cada menú y submenú, vecinos, cajón, cada chip de pestaña y unas fichas.
func _vuelta() -> void:
	var ml: MenuLateral = _p.get("_menu_lateral")
	var m: Mundo = _p.get("mundo")
	for menu: Dictionary in MenuLateral.MENUS:
		var subs: Array = menu["subs"]
		for k in range(-1, subs.size()):
			if k >= 0 and (subs[k] as Dictionary).has("accion"):
				continue
			ml.abrir_menu(String(menu["id"]), k)
		ml.menu_vecino(1)
		if is_instance_valid(ml.pantalla_abierta):
			ml.pantalla_abierta.cerrar()
		ml.alternar()
		await _fotogramas(2)
		_fase("menú " + String(menu["id"]))
	for g: Dictionary in Principal.GRUPOS:
		for ch: Dictionary in g["tabs"]:
			if String(ch.get("secc", "")) != "kits":
				_p.call("_ir_a_chip", ch)
	await _fotogramas(2)
	_fase("chips")
	for i in 4:
		_p.call("_ver_ficha", m.mi_club().plantilla[i])
		_p.call("_ver_ficha", m.ligas[0].clubes[1].plantilla[i])
	if is_instance_valid(ml.pantalla_abierta):
		ml.pantalla_abierta.cerrar()
	ml.plegar()
	## El diseñador de Equipación es una capa en la raíz: se cierra como lo haría «Cancelar».
	var capas := get_tree().root.get_children().filter(func(h: Node) -> bool: return String(h.name).begins_with("PantallaEquipacion"))
	_comprobar(capas.size() <= 1, "un solo diseñador de Equipación abierto a la vez (%d)" % capas.size())
	var capa := get_tree().root.get_node_or_null("PantallaEquipacion")
	if capa != null and capa.get_child(0) is DisenadorKit:
		(capa.get_child(0) as DisenadorKit)._cerrar()
	await _fotogramas(3)
	_fase("fotogramas")

var _obj_prev := 0
## Objetos vivos ganados en cada fase de la vuelta (para localizar una retención).
func _fase(que: String) -> void:
	var o := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	_linea("    %s: %+d objetos" % [que, o - _obj_prev])
	_obj_prev = o

func _contar(n: Node) -> int:
	var c := 1
	for h in n.get_children():
		c += _contar(h)
	return c

## Cuenta por «padre/clase» para señalar dónde crece.
func _histo(n: Node, acc: Dictionary) -> Dictionary:
	for h in n.get_children():
		## Los nombres automáticos («@Label@123») cambian al rehacer: se usa la clase del padre.
		var padre := n.get_class() if String(n.name).begins_with("@") else String(n.name)
		var k := "%s/%s" % [padre, h.get_class()]
		acc[k] = int(acc.get(k, 0)) + 1
		_histo(h, acc)
	return acc
