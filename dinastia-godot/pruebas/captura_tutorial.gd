extends Node
## EL TUTORIAL INMERSIVO, RECORRIDO DE VERDAD (25-9-2026).
##
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 \
##         res://pruebas/captura_tutorial.tscn
##
## Abre la pantalla principal y juega el primer día del entrenador como lo
## haría un jugador: el prólogo se escribe y "Entrar" lo cierra; la misión
## del plantel se cumple abriendo el plantel A MANO (se marca con ✔ y el
## mentor sigue solo); la de la ficha de la estrella, con "Muéstramelo"; cada
## paso con objetivo encuentra su control en pantalla; el epílogo cuenta las
## misiones cumplidas; y al cerrar queda marcado como visto. Después abre el
## prólogo del interinato, para ver que cada modo tiene el suyo. Deja fotos.
## Sale con código 1 si algo falla.
##
## Toca `user://ajustes.cfg` -el mismo del juego- y deja la marca de "visto"
## como estaba.

var _pantalla: Node
var _tut: Tutorial
var _n := 0
var _fallos := 0
var _visto_antes := false
var _i_plantel := -1
var _i_ficha := -1

func _ready() -> void:
	_visto_antes = Tutorial.visto()
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _comprobar(cond: bool, que: String) -> void:
	print(("  ok    " if cond else "  FALLO ") + que)
	if not cond:
		_fallos += 1

func _process(_d: float) -> void:
	_n += 1
	match _n:
		15:
			_pantalla.call("_ir_a_pestana", "Inicio")
			_pantalla.call("abrir_tutorial", "dt")
			_tut = _pantalla.get("_tutorial")
			_comprobar(_tut != null and _tut.fase() == "prologo", "el tutorial arranca con el prólogo")
		40:
			_comprobar(_tut.escribiendo(), "el prólogo se va escribiendo a máquina")
			_foto("res://pruebas/tutorial_prologo_escribiendo.png")
			_tut.pulsar_prologo()
		45:
			_comprobar(not _tut.escribiendo() and _tut.fase() == "prologo", "el primer clic termina de escribirlo, sin saltarlo")
			_foto("res://pruebas/tutorial_prologo.png")
			_tut.pulsar_prologo()
		50:
			_comprobar(_tut.fase() == "dialogo", "\"Entrar\" pasa al mentor")
			var pasos: Array = _tut.guion_actual()["pasos"]
			for k in pasos.size():
				var h := String((pasos[k] as Dictionary).get("hecho", ""))
				if h == "tab:Mi plantel" and _i_plantel < 0:
					_i_plantel = k
				if h.begins_with("ficha:") and _i_ficha < 0:
					_i_ficha = k
			var faltan: Array[String] = []
			for p: Dictionary in pasos:
				if p.has("objetivo") and _pantalla.call("tutorial_objetivo", String(p["objetivo"])) == null:
					faltan.append(String(p["objetivo"]))
			_comprobar(faltan.is_empty(), "todos los objetivos existen en pantalla %s" % str(faltan))
		100:
			## ✎: cambiarle la chaqueta al mentor la cambia y la recuerda.
			(_tut.get("_panel_aspecto") as Control).visible = true
			_tut.cambiar_aspecto("ropa", "burdeos")
			_comprobar(String(Tutorial.aspecto_mentor("dt", _tut.guion_actual()["mentor"]).get("ropa")) == "burdeos",
				"el aspecto elegido para el mentor se guarda")
		110:
			_foto("res://pruebas/tutorial_mentor.png")
			(_tut.get("_panel_aspecto") as Control).visible = false
			_tut.call("_mostrar", _i_plantel)
		150:
			## El jugador abre el plantel por su cuenta.
			_pantalla.call("_ir_a_pestana", "Mi plantel")
		175:
			_comprobar(_tut.misiones_cumplidas() == 1, "abrir el plantel a mano cumple la misión")
			_foto("res://pruebas/tutorial_mision_cumplida.png")
		260:
			_comprobar(_tut.indice() == _i_plantel + 1, "y el mentor sigue solo al paso siguiente (%d)" % _tut.indice())
			_tut.call("_mostrar", _i_ficha)
		300:
			_tut.call("_hacer_por_mi")
		330:
			_comprobar(_tut.misiones_cumplidas() == 2, "\"Muéstramelo\" abre la ficha de la estrella y cumple la misión")
			_foto("res://pruebas/tutorial_ficha.png")
			var pasos: Array = _tut.guion_actual()["pasos"]
			_tut.call("_mostrar", pasos.size() - 1)
		420:
			_comprobar(String(_tut.paso_actual().get("titulo", "")) == "¡A jugar!", "el último paso es el epílogo")
			_foto("res://pruebas/tutorial_final.png")
			_tut.pulsar_siguiente()
			_tut.pulsar_siguiente()
		430:
			_comprobar(Tutorial.visto(), "al terminar queda marcado como visto")
			_comprobar(_pantalla.get("_tutorial") == null, "y la pantalla lo suelta")
			_pantalla.call("abrir_tutorial", "interino")
			_tut = _pantalla.get("_tutorial")
		520:
			_foto("res://pruebas/tutorial_prologo_interino.png")
			_tut.call("_terminar", false)
		525:
			if not _visto_antes:
				var c := ConfigFile.new()
				c.load(Tutorial.AJUSTES)
				if c.has_section_key(Tutorial.SECCION, "general"):
					c.erase_section_key(Tutorial.SECCION, "general")
				if c.has_section_key(Tutorial.SECCION_ASPECTO, "dt"):
					c.erase_section_key(Tutorial.SECCION_ASPECTO, "dt")
				c.save(Tutorial.AJUSTES)
			print("captura_tutorial: %d fallos" % _fallos)
			get_tree().quit(1 if _fallos > 0 else 0)

func _foto(ruta: String) -> void:
	get_viewport().get_texture().get_image().save_png(ruta)
