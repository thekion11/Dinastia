extends Control
## Los minijuegos de la ciudad en 3D: autógrafos, pesca, karting y penales.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_minijuegos_3d.tscn
var _t := 0.0
var _paso := 0
var _mj: Control

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1280, 720)

func _foto(n: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/%s.png" % n)
	var cam: Camera3D = _mj.get("_cam") if _mj != null and _mj.get("_cam") != null else null
	if cam:
		var vp := cam.get_viewport() as SubViewport
		print("FOTO ", n, " cam=", cam.global_position, " fov=", cam.fov, " vp=", vp.size if vp else Vector2i(), " cur=", cam.current, " cont=", (_mj.get("_v")["cont"] as Control).size if _mj.get("_v") else Vector2())
	else:
		print("FOTO ", n)

func _abrir(j: String) -> void:
	if _mj != null:
		_mj.queue_free()
	var n := MinijuegosCiudad.new()
	n.juego = j
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(n)
	n._montar()
	_mj = n

func _process(d: float) -> void:
	_t += d
	match _paso:
		0:
			if _t > 0.5:
				_abrir("autografos"); _paso = 1; _t = 0.0
		1:
			if _t > 7.0:
				_foto("mini3d_0_autografos_piden"); _mj.call("_firmar_mas_cercano"); _paso = 2; _t = 0.0
		2:
			if _t > 0.5:
				_foto("mini3d_1_autografos"); _paso = 3; _t = 0.0
		3:
			if _t > 0.3:
				_abrir("pesca"); _paso = 4; _t = 0.0
		4:
			if _t > 0.95:
				_foto("mini3d_2_pesca_lanza"); _paso = 5; _t = 0.0
		5:
			if _t > 1.2:
				_mj.set("_estado_pesca", "pica"); _mj.set("_t", 5.0); _paso = 6; _t = 0.0
		6:
			if _t > 0.4:
				_mj.call("_tirar"); _paso = 7; _t = 0.0
		7:
			if _t > 0.5:
				_foto("mini3d_3_pesca_pez"); _paso = 8; _t = 0.0
		8:
			if _t > 0.3:
				_abrir("karting"); _paso = 9; _t = 0.0
		9:
			if _t > 1.0:
				_foto("mini3d_4_karting_parrilla"); _mj.set("_cuenta", -2.0); _mj.set("_kv", 20.0); _mj.set("_empezado", true); _paso = 10; _t = 0.0
		10:
			_mj.set("_kv", 20.0)
			if _t > 2.2:
				_foto("mini3d_5_karting_carrera"); _paso = 11; _t = 0.0
		11:
			var cam: Camera3D = (_mj.get("_cam") as Camera3D)
			cam.position = Vector3(0, 80, 75)
			cam.look_at(Vector3(0, 0, 0), Vector3.UP)
			_mj.set("_fin_kart", true)
			if _t > 0.3:
				_foto("mini3d_6_karting_alto"); _paso = 12; _t = 0.0
		12:
			if _mj != null:
				_mj.queue_free(); _mj = null
			_mj = MinijuegoPenales.mostrar(self, null)
			_paso = 13; _t = 0.0
		13:
			if _t > 1.0:
				_foto("mini3d_7_penales"); _mj.call("_patear", 0); _paso = 14; _t = 0.0
		14:
			if _t > 0.75:
				_foto("mini3d_8_penales_tiro"); _paso = 15; _t = 0.0
		15:
			if _t > 0.45:
				_foto("mini3d_9_penales_estirada"); _paso = 16; _t = 0.0
		16:
			if _t > 0.5:
				get_tree().quit()
