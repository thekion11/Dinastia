extends Node
## `M.st` + `vPost()` del HTML: se juega un partido entero de verdad -los 90
## minutos, sin atajos- para ver la linea de estadisticas en vivo arriba y, al
## pitido final, el cuadro completo y el informe del ayudante en la cronica.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_estadisticas.tscn

const ESPERA := 12

var _n := 0
var _mundo: Mundo
var _vivo: PartidoVivo

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI", "ARG", "ESP"], 4321)
	_mundo.tomar_el_mando(_mundo.clubes.values()[0].id)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var par := _mundo.proximo_partido()
		var p := Partido.new(par[0], par[1])
		_vivo = PartidoVivo.new()
		_vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_vivo)
		_vivo.abrir(p, _mundo.mi_club())
	if _n == ESPERA + 2:
		for i in 55:
			_vivo.partido.simular_minuto()
		_vivo.call("_refrescar")
	if _n == ESPERA + 4:
		_guardar("res://pruebas/capturas/pantalla_stats_vivo.png")
	if _n == ESPERA + 6:
		## Hasta el pitido final: ahi entra `_al_final()`, que escribe el cuadro
		## de estadisticas y el informe.
		while not _vivo.partido.terminado_ya:
			_vivo.partido.simular_minuto()
		_vivo.call("_refrescar")
		var p2 := _vivo.partido
		print("FINAL %d-%d | posesion %.0f | remates %d-%d | puerta %d-%d | xG %.2f-%.2f | corners %d-%d | faltas %d-%d | fueras %d-%d" % [
			p2.goles_local, p2.goles_visita, p2.posesion_local,
			p2.remates_local, p2.remates_visita,
			p2.tiros_puerta_local, p2.tiros_puerta_visita,
			p2.xg_local, p2.xg_visita,
			p2.corners_local, p2.corners_visita,
			p2.faltas_local, p2.faltas_visita,
			p2.fueras_local, p2.fueras_visita])
	if _n == ESPERA + 10:
		_guardar("res://pruebas/capturas/pantalla_stats_final.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
