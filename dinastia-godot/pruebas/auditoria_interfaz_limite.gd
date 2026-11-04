extends Node
## MEGA AUDITORÍA 4, repaso 5 (interfaz, 4-11-2026): la interfaz llevada al límite.
##   godot --headless --path . res://pruebas/auditoria_interfaz_limite.tscn
## Abre y cierra los menús laterales 100 veces y mide nodos y huérfanos; cambia de idioma con una pantalla abierta;
## sube el texto al 160 %; pulsa dos veces seguidas y mide en 2400×1080 y 1280×720 qué se sale de la ventana.
## Termina en «===== FIN. n fallos =====»; los errores de script salen como SCRIPT ERROR.
var _p: Node
var _n := 0
var _fallos := 0
var _fase := 0
var _ciclo := 0
var _nodos_base := 0
var _huerfanos_base := 0
var _ids: Array = []

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _fuera(ancho: float) -> int:
	var fuera := 0
	for n in _p.find_children("*", "Control", true, false):
		var c := n as Control
		if not (c is Button or c is Label) or not c.is_visible_in_tree() or c.get_viewport() != get_viewport():   ## (lo de un SubViewport pinta en su propia textura)
			continue
		if String(c.get("text")).strip_edges() == "" or c.size.x < 4.0:
			continue
		var r := c.get_global_rect()
		if r.end.x > ancho + 2.0 and r.position.x < ancho:
			fuera += 1
			print("    se sale %d px: %s | %s" % [int(r.end.x - ancho), c.get_path().get_concatenated_names().right(70), String(c.get("text")).left(50)])
	return fuera

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		for i in 4:
			_p.call("_avanzar_semana")
		for m: Dictionary in MenuLateral.MENUS:
			_ids.append(String(m["id"]))
		return
	if _n < 10:
		return
	var ml: MenuLateral = _p.get("_menu_lateral")
	if _n % 20 == 0: print("  fase %d ciclo %d" % [_fase, _ciclo])
	match _fase:
		0:
			## 100 aperturas/cierres de los menús laterales: ni nodos ni huérfanos ni memoria crecen sin parar.
			if _ciclo == 30:   ## las primeras vueltas construyen (y guardan) las pantallas perezosas
				_nodos_base = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
				_huerfanos_base = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
			if _ciclo % 20 == 10:
				print("    ciclo %d: %d nodos" % [_ciclo, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
			if _ciclo < 110:
				var id: String = _ids[_ciclo % _ids.size()]
				ml.abrir_menu(id, 0)
				ml.abrir_menu(id, 0)   ## pulsación doble: no debe apilar dos pantallas
				if is_instance_valid(ml.pantalla_abierta):
					ml.pantalla_abierta.cerrar()
				_ciclo += 1
				return
			## Hay que dejar que se liberen (queue_free) antes de medir.
			_fase = 1
			_ciclo = 0
		1:
			_ciclo += 1
			if _ciclo < 6:
				return
			var nodos := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
			var huerf := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
			_comprobar(nodos <= _nodos_base + 60, "100 aperturas y cierres de menú: los nodos no crecen (%d → %d)" % [_nodos_base, nodos])
			_comprobar(huerf <= _huerfanos_base + 20, "100 aperturas y cierres de menú: sin nodos huérfanos nuevos (%d → %d)" % [_huerfanos_base, huerf])
			_comprobar(_hijos_menu(ml) <= 1, "tras cerrar, no queda ninguna pantalla de menú apilada (%d)" % _hijos_menu(ml))
			_fase = 2
			_ciclo = 0
		2:
			## Idioma a mitad de pantalla: los 9 idiomas, con un menú abierto y refrescando.
			var langs: Array = ["es"] + Array(Idiomas.ORDEN)
			if _ciclo == 0:
				ml.abrir_menu(_ids[0], 0)
			if _ciclo < langs.size():
				Idiomas.idioma = langs[_ciclo]
				_p.call("_refrescar")
				_ciclo += 1
				return
			Idiomas.idioma = "es"
			_comprobar(is_instance_valid(ml.pantalla_abierta), "cambiar de idioma con un menú abierto no lo cierra ni lo rompe (%d idiomas)" % langs.size())
			if is_instance_valid(ml.pantalla_abierta):
				ml.pantalla_abierta.cerrar()
			_fase = 3
			_ciclo = 0
		3:
			## Texto al 160 % y ventanas distintas.
			var esc_antes: float = float(_p.get("_escala_texto"))
			_p.set("_escala_texto", 1.6)
			Tema.escala_texto = 1.6
			_p.call("_refrescar")
			_ciclo += 1
			if _ciclo < 3:
				return
			var ancho := get_viewport().get_visible_rect().size.x
			var f160 := _fuera(ancho)
			_comprobar(f160 <= 3, "texto al 160 %%: como mucho 3 textos se salen de la ventana (%d, ancho %d)" % [f160, int(ancho)])
			_p.set("_escala_texto", esc_antes)
			Tema.escala_texto = esc_antes
			_p.call("_refrescar")
			_fase = 4
			_ciclo = 0
		4:
			var ventana := get_window()
			var original := ventana.size
			for tam: Vector2i in [Vector2i(2400, 1080), Vector2i(1280, 720)]:
				ventana.size = tam
				_p.call("_refrescar")
				var w := get_viewport().get_visible_rect().size.x
				var f := _fuera(w)
				_comprobar(f <= 2, "ventana %dx%d: como mucho 2 textos se salen (%d, ancho útil %d)" % [tam.x, tam.y, f, int(w)])
			ventana.size = original
			_fase = 5
		5:
			print("===== FIN. %d fallos =====" % _fallos)
			get_tree().quit()

func _hijos_menu(ml: MenuLateral) -> int:
	var k := 0
	for h in _p.get_children():
		if h is PantallaMenu and not h.is_queued_for_deletion():
			k += 1
	return k
