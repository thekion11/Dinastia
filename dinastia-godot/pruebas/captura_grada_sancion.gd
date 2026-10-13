extends Node
## ESTADIO 2.0, fase 3: sentarse en la grada y el DT sancionado viendo el
## partido desde su butaca. Hoja: `pruebas/capturas/grada_sancion.png`.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 res://pruebas/captura_grada_sancion.tscn

var _v1: VistaEstadio
var _v2: VistaEstadio
var _ex: ExploradorEstadio
var _imgs: Array[Image] = []
var _n := 0
var _club: Club
var _rival: Club

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	_club = m.ligas[0].clubes[0]
	_rival = m.ligas[0].clubes[1]
	PersonajeDT.club_usuario = _club.id
	var perfil := EstadioPropio.new().perfil(_club)
	perfil["niveles"] = 2
	_v1 = VistaEstadio.new()
	add_child(_v1)
	_v1.abrir(_club, 0.85, null, null, perfil)

func _foto() -> void:
	var img := get_viewport().get_texture().get_image()
	img.resize(480, 270)
	_imgs.append(img)

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_v1.recorrer()
		_ex = _v1._explorador
		_ex.set_physics_process(false)
		## A la banda de los banquillos, junto a la grada.
		_ex.cuerpo.position = Vector3(35.0, 0.02, 6.0)
		_ex.rumbo = PI / 2.0
		_ex._colocar_camara(1.0)
		_ex._rotulos()
	if _n == 12:
		_foto()                                   # 1: en la banda, «E: sentarse»
		_ex.usar()
		_ex.set_physics_process(true)
	if _n == 18:
		_foto()                                   # 2: sentado, mirando el campo
		_ex._mirada = 0.9
	if _n == 24:
		_foto()                                   # 3: mirando hacia un lado
		_ex.set_physics_process(false)
		_ex.camara.position = _ex.cuerpo.position + Vector3(-6.0, 2.5, -3.0)
		_ex.camara.look_at(_ex.cuerpo.position + Vector3(0, 0.8, 0), Vector3.UP)
	if _n == 30:
		_foto()                                   # 4: tu personaje sentado, visto desde el campo
		_v1.queue_free()
		## Un partido con el DT sancionado.
		PersonajeDT.sancionado = true
		var p := Partido.new(_club, _rival)
		var perfil := EstadioPropio.new().perfil(_club)
		perfil["niveles"] = 2
		_v2 = VistaEstadio.new()
		add_child(_v2)
		_v2.abrir(_club, 0.85, _rival, p, perfil)
	if _n == 60:
		_foto()                                   # 5: la cámara del sancionado
		print("CAMARA ", (_v2.get("_rig") as CameraRig).current_name())
		(_v2.get("_rig") as CameraRig).switch_to(0)
	if _n == 66:
		_foto()                                   # 6: la tele, sin DT en la banda
		var hoja := Image.create(480 * 3, 270 * 2, false, Image.FORMAT_RGBA8)
		for k in _imgs.size():
			hoja.blit_rect(_imgs[k], Rect2i(0, 0, 480, 270), Vector2i((k % 3) * 480, (k / 3) * 270))
		hoja.save_png("res://pruebas/capturas/grada_sancion.png")
		print("HOJA OK cámara=", (_v2.get("_rig") as CameraRig).current_name())
		get_tree().quit()
