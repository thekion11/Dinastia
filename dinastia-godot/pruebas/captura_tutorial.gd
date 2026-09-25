extends Node
## EL TUTORIAL, RECORRIDO DE VERDAD (25-9-2026).
##
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 \
##         res://pruebas/captura_tutorial.tscn
##
## Abre la pantalla principal, arranca el recorrido de entrenador y comprueba
## lo que un jugador haría: que "Siguiente" avanza, que HACER lo que pide la
## tarjeta (cambiar de bloque, abrir el plantel) también avanza, que
## "Muéstramelo" lo hace por él, que cada paso con objetivo encuentra su
## control en pantalla y que al cerrar queda marcado como visto. Deja fotos de
## tres pasos. Sale con código 1 si algo falla.
##
## Toca `user://ajustes.cfg` -el mismo del juego, este build no aísla el
## directorio de usuario- y deja la marca de "visto" como estaba.

var _pantalla: Node
var _tut: Tutorial
var _n := 0
var _fallos := 0
var _visto_antes := false

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
			_pantalla.call("abrir_tutorial", "dt")
			_tut = _pantalla.get("_tutorial")
			_comprobar(_tut != null, "el tutorial se abre")
		25:
			_foto("res://pruebas/tutorial_1.png")
			## Cada paso con objetivo tiene que encontrar su control.
			var faltan: Array[String] = []
			for p: Dictionary in Tutorial.pasos_para("dt", "X"):
				if p.has("objetivo") and _pantalla.call("tutorial_objetivo", String(p["objetivo"])) == null:
					faltan.append(String(p["objetivo"]))
			_comprobar(faltan.is_empty(), "todos los objetivos existen en pantalla %s" % str(faltan))
			_tut.call("_mostrar", 2)
		35:
			_comprobar(String(_tut.paso_actual().get("hecho", "")) == "grupo", "el paso 3 es el de los bloques")
			_foto("res://pruebas/tutorial_2.png")
			## El jugador toca CLUB por su cuenta: el paso tiene que avanzar solo.
			_pantalla.call("_elegir_grupo", "club")
		75:
			_comprobar(_tut.indice() == 3, "tocar un bloque completa el paso sin pulsar Siguiente (paso %d)" % (_tut.indice() + 1))
			_tut.call("_mostrar", 4)
		80:
			## "Muéstramelo" en el paso del plantel.
			_tut.call("_hacer_por_mi")
		115:
			_comprobar(_tut.indice() == 5, "Muéstramelo abre el plantel y el paso avanza (paso %d)" % (_tut.indice() + 1))
			_foto("res://pruebas/tutorial_3.png")
			_tut.call("_terminar", false)
		120:
			_comprobar(Tutorial.visto(), "al cerrarlo queda marcado como visto")
			_comprobar(_pantalla.get("_tutorial") == null, "y la pantalla lo suelta")
			if not _visto_antes:
				var c := ConfigFile.new()
				c.load(Tutorial.AJUSTES)
				if c.has_section_key(Tutorial.SECCION, "general"):
					c.erase_section_key(Tutorial.SECCION, "general")
				c.save(Tutorial.AJUSTES)
			print("captura_tutorial: %d fallos" % _fallos)
			get_tree().quit(1 if _fallos > 0 else 0)

func _foto(ruta: String) -> void:
	get_viewport().get_texture().get_image().save_png(ruta)
