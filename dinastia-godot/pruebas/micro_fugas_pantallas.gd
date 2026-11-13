extends Node
## FUGAS AL ENTRAR Y SALIR DE PANTALLAS (13-11, sesión 16, optimización de código): abre `Principal`, recorre todas las pestañas del menú N rondas
## y, tras cada una, anota objetos, nodos, nodos huérfanos y recursos. Tras la ronda de calentamiento no deben crecer (construir y soltar N veces:
## memoria igual). Corre sin pantalla.   godot --headless --path . res://pruebas/micro_fugas_pantallas.tscn   (RONDAS=6, SOLO=Mercado,Ajustes)
const PESTANAS := ["Mi plantel", "Táctica", "Mercado", "Finanzas", "Clubes", "Selección", "Ajustes", "Calendario", "Inicio"]
var _p: Node
var _previa := {}

## Nodos por «clase (script)» bajo `raiz`.
func _contar(raiz: Node) -> Dictionary:
	var c := {}
	var pila: Array = [raiz]
	while not pila.is_empty():
		var nd: Node = pila.pop_back()
		var sc := nd.get_script() as Script
		var k := nd.get_class() + ("(" + String(sc.get_global_name()) + ")" if sc != null and String(sc.get_global_name()) != "" else "")
		c[k] = int(c.get(k, 0)) + 1
		for h in nd.get_children():
			pila.append(h)
	return c

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	for i in 60:
		await get_tree().process_frame
	var rondas := int(OS.get_environment("RONDAS")) if OS.get_environment("RONDAS") != "" else 6
	var solo := OS.get_environment("SOLO")
	var base := {}
	for r in rondas + 1:
		for nombre in PESTANAS:
			if solo != "" and not nombre in solo.split(","):
				continue
			_p.call("_ir_a_pestana", nombre)
			for i in 6:
				await get_tree().process_frame
			await _cerrar_capas()
		_p.call("_abrir_competicion")
		for i in 6:
			await get_tree().process_frame
		await _cerrar_capas()
		for i in 10:
			await get_tree().process_frame
		var o := int(Performance.get_monitor(Performance.OBJECT_COUNT))
		var n := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var h := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		var rc := int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
		if r == 0:
			base = {"o": o, "n": n, "h": h, "rc": rc}
		var cuenta := _contar(get_tree().root)
		if OS.get_environment("DETALLE") != "" and _previa.size() > 0:
			var dif: Array = []
			for k: String in cuenta:
				var d := int(cuenta[k]) - int(_previa.get(k, 0))
				if d != 0:
					dif.append([d, k])
			dif.sort_custom(func(a: Array, b: Array) -> bool: return absi(a[0]) > absi(b[0]))
			print("   DIF ronda %d: %s" % [r, str(dif.slice(0, 12))])
		_previa = cuenta
		if OS.get_environment("ARBOL") != "":
			var partes: Array = []
			for h2: Node in get_tree().root.get_children():
				partes.append("%s:%d" % [h2.name, _contar(h2).values().reduce(func(a, b): return a + b)])
			for h2: Node in _p.get_children():
				partes.append("P/%s:%d" % [h2.name, _contar(h2).values().reduce(func(a, b): return a + b)])
			print("   ARBOL ", r, " ", " ".join(partes))
			var vb: Node = null
			for h3: Node in _p.get_children():
				if h3 is VBoxContainer:
					vb = h3
			if vb != null:
				var sub: Array = []
				for h4: Node in vb.get_children():
					sub.append("%s(%s):%d" % [h4.name, h4.get_class(), _contar(h4).values().reduce(func(a, b): return a + b)])
				print("   SUB ", r, " ", " ".join(sub))
				var gran: Node = vb.get_child(vb.get_child_count() - 1)
				var det: Array = []
				for h5: Node in gran.get_children():
					var sub2: Array = []
					for h6: Node in h5.get_children():
						sub2.append("%s:%d" % [h6.name, _contar(h6).values().reduce(func(a, b): return a + b)])
					det.append("%s(%s):%d[%s]" % [h5.name, h5.get_class(), _contar(h5).values().reduce(func(a, b): return a + b), " ".join(sub2)])
				print("   COL ", r, " ", " | ".join(det))
		print("FUGAS ronda %d: objetos %d (%+d) · nodos %d (%+d) · huérfanos %d · recursos %d (%+d)" % [r, o, o - int(base["o"]), n, n - int(base["n"]), h, rc, rc - int(base["rc"])])
	print("===== FIN. 0 fallos =====")
	get_tree().quit()

func _cerrar_capas() -> void:
	for h: Node in _p.get_children():
		if h is PantallaMenu and not (h as PantallaMenu).cerrando():
			(h as PantallaMenu).cerrar()
		elif h is EventoPantallaCompleta or h is Competicion or h.name == "CapaTutorial":
			h.queue_free()
	for i in 10:
		await get_tree().process_frame
