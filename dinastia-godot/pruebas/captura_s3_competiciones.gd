extends Node
## s3 (26-10-2026): los nombres de competición que se ven (el ficticio, no el interno).
##   RESOLUCION=1280x720 herramientas/captura.sh res://pruebas/captura_s3_competiciones.tscn
## s3_comp_calendario: el calendario en un año de Mundial (con la noticia del torneo en el registro).
## s3_comp_ficha: la ficha de la competición con el selector desplegado.
## IDIOMA=de para verlo en otro idioma.
var _n := 0
var _p: Principal
var _ficha: Competicion

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _foto(nombre: String) -> void:
	if OS.get_environment("IDIOMA") != "":
		nombre += "_" + OS.get_environment("IDIOMA")
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % nombre)
	print("FOTO ", nombre)

func _process(_d: float) -> void:
	_n += 1
	match _n:
		10:
			## Después de abrir: Principal carga el idioma de las preferencias.
			if OS.get_environment("IDIOMA") != "":
				Idiomas.idioma = OS.get_environment("IDIOMA")
			_p.mundo.anio = 2026
			var c := _p.mundo.mi_club()
			for sem in 60:
				if not Calendario.torneo_en_curso(2026, sem).is_empty():
					_p.mundo.calendario.semana(c, 2026, sem)
					break
			_p._ir_a_pestana("Calendario")
			_p._refrescar()
		40:
			_foto("s3_comp_calendario")
			_ficha = Competicion.new()
			_ficha.set_anchors_preset(Control.PRESET_FULL_RECT)
			_p.add_child(_ficha)
			_ficha.abrir(_p.mundo, _p._liga_de(_p.mundo.mi_club()))
		60:
			var sel: OptionButton = _ficha.get("_selector")
			sel.show_popup()
		80:
			_foto("s3_comp_ficha")
			Idiomas.idioma = "es"
			get_tree().quit()
