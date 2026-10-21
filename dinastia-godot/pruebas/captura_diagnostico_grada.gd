extends Node
## DIAGNÓSTICO DE LA GRADA (21-10-2026, «la tribuna sigue viéndose mal, la gente
## no se ve tan real, ¿la estructura es modular y navegable?»). Cinco tomas:
## 1 primeras filas desde la banda · 2 una tribuna entera · 3 cámara de TV ·
## 4 desde dentro de la grada (como espectador) · 5 el estadio por fuera ·
## 6 la gente de cerca.
##   herramientas/captura.sh res://pruebas/captura_diagnostico_grada.tscn  (SUFIJO=_antes)
var _vista: VistaEstadio
var _n := 0
var _cam: Camera3D
const TOMAS := [
	["1_filas", Vector3(30.0, 1.6, 6.0), Vector3(48.0, 4.0, -4.0), 55.0],
	["2_tribuna", Vector3(-10.0, 9.0, 0.0), Vector3(60.0, 10.0, 0.0), 70.0],
	["3_tv", Vector3.ZERO, Vector3.ZERO, 0.0],
	["4_espectador", Vector3(46.0, 6.5, 8.0), Vector3(0.0, 0.0, -2.0), 70.0],
	["5_fuera", Vector3(140.0, 40.0, 110.0), Vector3(0.0, 8.0, 0.0), 50.0],
	["6_gente", Vector3(35.5, 2.6, 3.0), Vector3(44.0, 4.2, -1.0), 42.0],
]

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.9, par[1], Partido.new(par[0], par[1]))

func _process(_d: float) -> void:
	for k in ["_intro", "_ceremonia"]:
		var x: Variant = _vista.get(k)
		if x != null and is_instance_valid(x) and x.activa:
			x.terminar()
			return
	_n += 1
	var i := (_n - 20) / 6
	if _n < 20 or i >= TOMAS.size():
		if i >= TOMAS.size():
			get_tree().quit()
		return
	var t: Array = TOMAS[i]
	if (_n - 20) % 6 == 0:
		if String(t[0]) == "3_tv":
			if _cam != null:
				_cam.current = false
			_vista.set_process(true)
		else:
			_vista.set_process(false)
			if _cam == null:
				_cam = Camera3D.new()
				(_vista.get("_raiz3d") as Node3D).add_child(_cam)
			_cam.global_position = t[1]
			_cam.look_at(t[2])
			_cam.fov = float(t[3])
			_cam.current = true
	if (_n - 20) % 6 == 4:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/diag_grada_%s%s.png" % [t[0], OS.get_environment("SUFIJO")])
		print("FOTO ", t[0])
