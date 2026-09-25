extends Node
## Comprueba el boton de velocidad del visor 3D del partido: que aparece, que
## al pulsarlo de verdad cambia `vel_idx` en `MatchPlayback` -no solo el texto
## del boton- y que cicla Pausa -> Lento -> Normal -> Rapido -> x4 -> Pausa.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_velocidad_partido.tscn

var _n := 0
var _vista: VistaEstadio
var _mundo: Mundo
var _partido: Partido
var _clics := 0
var _vistos: Array = []

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 777)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	var par := _mundo.proximo_partido()
	_partido = Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], _partido)

func _process(_d: float) -> void:
	_n += 1
	if _n == 14:
		var b: Button = _vista.get("_btn_velocidad")
		print("boton existe = %s   texto inicial = '%s'" % [b != null, b.text if b != null else ""])
	if _n > 14 and _n < 14 + 6 * 5 and (_n - 14) % 6 == 0:
		var b: Button = _vista.get("_btn_velocidad")
		var j: MatchPlayback = _vista.get("_juego")
		_vistos.append(j.vel_idx)
		print("clic %d -> vel_idx=%d texto='%s'" % [_clics, j.vel_idx, b.text])
		b.pressed.emit()
		_clics += 1
	if _n == 14 + 6 * 5 + 2:
		print("secuencia de vel_idx tras 5 clics: %s (debe ciclar 2->3->4->0->1->2 o similar, nunca quedarse igual)" % [_vistos])
		get_tree().quit()
