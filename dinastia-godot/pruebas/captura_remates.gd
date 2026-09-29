extends Node
## Comprueba las jugadas falladas nuevas (atajada/poste/fallo): que la cronica
## del partido en vivo ya no se queda muda entre gol y gol, y que los cinco
## sonidos nuevos (lesion, cambio, fichaje, ascenso, descenso) y los cinco
## portados del HTML (ocasion, atajada, falta, corner, trofeo) sintetizan sin
## reventar.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_remates.tscn

const ESPERA := 12

var _n := 0
var _mundo: Mundo
var _vivo: PartidoVivo

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI", "ARG", "ESP"], 1234)
	_mundo.tomar_el_mando(_mundo.clubes.values()[0].id)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		## Todos los efectos nuevos + los que ya habia: si alguno revienta al
		## sintetizar, se ve aqui antes de tocar ninguna pantalla.
		for nombre in ["ocasion", "atajada", "falta", "corner", "trofeo",
				"lesion", "cambio", "fichaje", "ascenso", "descenso"]:
			var ok: bool = Sonido.banco(nombre).size() == Sonido.VARIANTES
			print("sonido '%s': %s" % [nombre, "ok" if ok else "FALTA"])
		var par := _mundo.proximo_partido()
		var p := Partido.new(par[0], par[1])
		_vivo = PartidoVivo.new()
		_vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_vivo)
		_vivo.abrir(p, _mundo.mi_club())
	if _n == ESPERA + 2:
		## 60 minutos a pelo alcanzan de sobra para que salgan remates fallados.
		var cuentas := {"atajada": 0, "poste": 0, "fallo": 0}
		_vivo.partido.remate.connect(func(_c, _a, tipo, _m): cuentas[tipo] = cuentas.get(tipo, 0) + 1)
		for i in 60:
			_vivo.partido.simular_minuto()
		print("remates en 60 minutos: ", cuentas, "  (remates_local=%d remates_visita=%d goles=%d-%d)" % [
			_vivo.partido.remates_local, _vivo.partido.remates_visita,
			_vivo.partido.goles_local, _vivo.partido.goles_visita])
		_vivo.call("_poner_velocidad", 0)
		_vivo.call("_refrescar")
	if _n == ESPERA + 6:
		_guardar("res://pruebas/capturas/pantalla_remates.png")
		get_tree().quit()

func _guardar(ruta: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
