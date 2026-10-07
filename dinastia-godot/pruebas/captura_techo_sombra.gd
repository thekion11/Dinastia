extends Node
## SOMBRA DEL TECHO SOBRE LA GRADA (MEGAPLAN fase 2): estadio con techo de
## anillo, de día, cámara de TV y la general.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_techo_sombra.tscn
var _n := 0
var _vista: VistaEstadio

func _ready() -> void:
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 777)
	mundo.tomar_el_mando(mundo.ligas[0].clubes[0].id)
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	var clima := OS.get_environment("CLIMA") if OS.get_environment("CLIMA") != "" else "tarde"
	var perfil: Dictionary = (par[0] as Club).perfil_estadio().duplicate()
	perfil["techo"] = "anillo"
	perfil["clima"] = clima
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]), perfil)

func _process(_d: float) -> void:
	_n += 1
	## LED=1: las vallas en modo gol (MEGAPLAN fase 2).
	if _n == 18 and OS.get_environment("LED") != "":
		_vista.call("_vallas_evento", ["¡GOOOL!", "LAUTARO FC"], _vista.get("club"))
	if _n == 25:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % ("vallas_gol" if OS.get_environment("LED") != "" else "techo_sombra"))
		get_tree().quit()
