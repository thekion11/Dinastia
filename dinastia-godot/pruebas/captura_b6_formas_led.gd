extends Node
## MEGAPLAN B6: las dos formas nuevas («dos», «principal») y las paletas de
## las vallas LED. Hoja: `pruebas/capturas/b6_formas_led.png`.
##
##   godot --path . --rendering-driver opengl3 --resolution 960x540 \
##         res://pruebas/captura_b6_formas_led.tscn

## [forma, paleta LED, cámara]
const CASOS := [
	["dos", "marcas", "aerea"], ["principal", "marcas", "aerea"],
	["dos", "arcoiris", "vallas"], ["principal", "neon", "vallas"],
	["cuenco", "propia", "vallas", {"ledFondo": "#6b2d8f", "ledTinta": "#e8c21a"}], ["cuenco", "retro", "vallas"],
]
## Cámaras propias: «aerea» ve el recinto entero desde fuera (la tribuna de
## honor está en +X); «vallas» mira el anillo del fondo de cerca.
const CAMS := {
	"aerea": [Vector3(-110, 48, 120), Vector3(15, 8, 0)],
	"vallas": [Vector3(-14, 3.2, 38), Vector3(2, 0.8, 56)],
}
var _i := 0
var _n := 0
var _vista: VistaEstadio
var _club: Club
var _rival: Club
var _imgs: Array[Image] = []

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	_club = m.ligas[0].clubes[0]
	_rival = m.ligas[0].clubes[1]
	_abrir()

func _abrir() -> void:
	if _vista != null:
		_vista.queue_free()
	var ep := EstadioPropio.new()
	var perfil := ep.perfil(_club)
	perfil["forma"] = CASOS[_i][0]
	perfil["ledPaleta"] = CASOS[_i][1]
	perfil["niveles"] = 2
	if CASOS[_i].size() > 3:
		perfil.merge(CASOS[_i][3], true)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(_club, 0.85, _rival, null, perfil)
	_n = 0

func _process(_d: float) -> void:
	_n += 1
	if _n == 6:
		var rig: CameraRig = _vista.get("_rig")
		if CAMS.has(CASOS[_i][2]):
			var cam := Camera3D.new()
			cam.fov = 60.0
			_vista.add_child(cam)
			var par: Array = CAMS[CASOS[_i][2]]
			cam.look_at_from_position(par[0], par[1])
			cam.far = 900.0
			cam.make_current()
			if CASOS[_i][2] == "aerea":
				var sol := DirectionalLight3D.new()
				sol.light_energy = 2.5
				_vista.add_child(sol)
				sol.look_at_from_position(Vector3(-60, 100, 40), Vector3.ZERO)
		elif rig != null:
			var k := rig.camera_names.find(String(CASOS[_i][2]))
			if k < 0:
				print("cámaras: ", rig.camera_names)
			rig.switch_to(maxi(0, k))
	if _n == 18:
		var img := get_viewport().get_texture().get_image()
		img.resize(480, 270)
		_imgs.append(img)
		_i += 1
		if _i >= CASOS.size():
			var hoja := Image.create(480 * 3, 270 * 2, false, Image.FORMAT_RGBA8)
			for k in _imgs.size():
				hoja.blit_rect(_imgs[k], Rect2i(0, 0, 480, 270), Vector2i((k % 3) * 480, (k / 3) * 270))
			hoja.save_png("res://pruebas/capturas/b6_formas_led.png")
			print("HOJA OK")
			get_tree().quit()
			return
		_abrir()
