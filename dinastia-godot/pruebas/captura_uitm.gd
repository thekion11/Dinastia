extends Node
## PAQUETE uitm (25-10-2026): el lenguaje visual común, antes y después.
## Seis pantallas distintas con el partido real cargado: el centro con avisos y
## el consejo del presidente encima, el cajón del panel lateral con el foco del
## mando, un menú a pantalla completa con su fondo animado, el cuadro de
## diálogo con respuestas, el álbum (pintado con `Tema.*`) y una pestaña con el
## foco en un botón.
##   MOMENTO=antes RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_uitm.tscn
##   ACCES=1 → el álbum sale con daltonismo y letra al 130 % (Tema.daltonico / Tema.escala_texto).
## Va por TIEMPO y no por fotogramas: sin GPU cada fotograma tarda lo que quiere,
## y las animaciones (tweens) también van por tiempo.

var _p: Node
var _t := 0.0
var _hecho := {}
var _sufijo := ""

func _ready() -> void:
	_sufijo = OS.get_environment("MOMENTO")
	if _sufijo == "":
		_sufijo = "x"
	_sufijo += "_" + OS.get_environment("RESOLUCION").replace("x", "_")
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(d: float) -> void:
	## Los primeros fotogramas montan el partido: el reloj empieza después.
	if Engine.get_process_frames() < 12:
		return
	_t += minf(d, 0.25)
	var mun = _p.get("mundo")
	var ml: MenuLateral = _p.get("_menu_lateral")
	if _una("avisos", 0.2):
		var mio: Club = mun.mi_club()
		mun.logros.logro_desbloqueado.emit("primer_titulo", "🏆", "Primer título", "Levantaste tu primer trofeo como entrenador.")
		mun.mercado.oferta_recibida.emit(mio.plantilla[1], mun.ligas[0].clubes[1], 8400000)
		MentorVoz.decir(_p as Control, mun, "Un consejo", "La plantilla está cansada: rota en el próximo partido y no fuerces a los que vienen de lesión.")
	if _una("f1", 1.6):
		_foto("hub_avisos")
	if _una("cajon", 5.0):
		ml.desplegar()
	if _una("foco_cajon", 5.4):
		var b := _primer_boton(ml.get_child(2), 2)
		if b != null:
			b.grab_focus()
	if _una("f2", 5.9):
		_foto("cajon")
	if _una("menu", 6.5):
		ml.abrir_menu("historia", -1)
	if _una("f3", 8.0):
		_foto("menu_historia")
	if _una("dialogo", 8.5):
		if is_instance_valid(ml.pantalla_abierta):
			ml.pantalla_abierta.cerrar()
		var cd := CuadroDialogo.new()
		cd.name = "DialogoUitm"
		_p.add_child(cd)
		cd.decir("El hincha", "Tengo el abono desde los once años. Este año, ¿peleamos el ascenso o qué?", Color(1.0, 0.8, 0.35), 1, 3)
		cd.completar()
		var fila := HBoxContainer.new()
		fila.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		fila.position = Vector2(-260, -96)
		fila.add_theme_constant_override("separation", 10)
		cd.get_child(0).add_child(fila)
		for s: String in ["Vamos a por todas", "Paso a paso", "Ya veremos"]:
			fila.add_child(CuadroDialogo.respuesta(Button.new()))
			(fila.get_child(fila.get_child_count() - 1) as Button).text = s
	if _una("foco_dialogo", 9.0):
		var fila2: Node = _p.get_node("DialogoUitm").get_child(0).get_child(1)
		(fila2.get_child(1) as Button).grab_focus()
	if _una("f4", 9.6):
		_foto("dialogo")
	if _una("album", 10.0):
		_p.get_node("DialogoUitm").queue_free()
		if OS.get_environment("ACCES") == "1":
			Tema.daltonico = true
			Tema.escala_texto = 1.3
		PanelMeta.abrir(_p as Control, mun)
	if _una("f5", 11.5):
		_foto("album" + ("_acces" if OS.get_environment("ACCES") == "1" else ""))
	if _una("pestana", 12.0):
		Tema.daltonico = false
		Tema.escala_texto = 1.0
		for n in _p.get_children():
			if n is Control and n.get_script() == PanelMeta:
				n.queue_free()
		var tabs: TabContainer = _p.get("_pestanas")
		for i in tabs.get_tab_count():
			if tabs.get_child(i).name == "Club":
				tabs.current_tab = i
	if _una("foco_pestana", 12.8):
		var b2 := _primer_boton(_p.get("_lista_club"), 0)
		if b2 != null:
			b2.grab_focus()
	if _una("f6", 13.4):
		_foto("club_foco")
		get_tree().quit()

func _una(clave: String, seg: float) -> bool:
	if _t >= seg and not _hecho.has(clave):
		_hecho[clave] = true
		return true
	return false

## El botón visible número `n` dentro de `raiz` (recorrido en profundidad).
func _primer_boton(raiz: Node, n: int) -> Button:
	if raiz == null:
		return null
	var vistos := 0
	var pila: Array[Node] = [raiz]
	while not pila.is_empty():
		var x: Node = pila.pop_front()
		if x is Button and (x as Button).is_visible_in_tree():
			if vistos == n:
				return x as Button
			vistos += 1
		pila.append_array(x.get_children())
	return null

func _foto(nombre: String) -> void:
	var ruta := "res://pruebas/capturas/uitm_%s_%s.png" % [nombre, _sufijo]
	get_viewport().get_texture().get_image().save_png(ruta)
	print("captura guardada: %s" % ruta)
