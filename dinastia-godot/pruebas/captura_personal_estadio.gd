extends Node
## ESTADIO 2.0, fase 4: la gente del club en su puesto. Una foto por persona
## (de frente) y la última con la conversación abierta.
## Hoja: `pruebas/capturas/personal_estadio.png`.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 res://pruebas/captura_personal_estadio.tscn

var _vista: VistaEstadio
var _ex: ExploradorEstadio
var _pe: PersonalEstadio
var _imgs: Array[Image] = []
var _n := 0
var _k := 0
var _m: Mundo

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var club: Club = m.ligas[0].clubes[0]
	PersonajeDT.club_usuario = club.id
	m.tomar_el_mando(club.id)
	if m.gente == null:
		m.gente = Gente.new(m)
	m.gente.armar()
	EdificioClub.mundo_ref = weakref(m)
	_m = m
	EdificioClub.ctx = {"inst": {"park": 4, "med": 6, "video": 6, "museo": 6}, "dentro": {"sala_prensa": "decente"},
		"plantilla": [], "titulos": 3, "presidente": "Ramiro Ficticio", "gente": m.gente.fichas}
	var perfil := EstadioPropio.new().perfil(club)
	perfil["niveles"] = 2
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.85, null, null, perfil)

func _foto() -> void:
	var img := get_viewport().get_texture().get_image()
	img.resize(480, 270)
	_imgs.append(img)

func _ir_a(g: Dictionary, retrato := true) -> void:
	var n: Node3D = g["nodo"]
	_ex.ir_a_planta(int(g["planta"]))
	## Hacia el centro de su zona: de ahí se le mira.
	var z := _ex.zona_en(n.position)
	var centro := n.position + Vector3(0, 0, -1)
	if not z.is_empty():
		var r: Rect2 = z["r"]
		centro = Vector3(r.get_center().x, n.position.y, r.get_center().y)
	var dir := centro - n.position
	dir.y = 0
	if dir.length() < 0.5:
		dir = Vector3(0, 0, -1)
	dir = dir.normalized()
	n.rotation.y = atan2(dir.x, dir.z)
	_ex.cuerpo.position = n.position + dir * (1.5 if not retrato else 3.0)
	_ex.cuerpo.position.y = RecorridoClub.y_de(int(g["planta"]))
	var v := n.position - _ex.cuerpo.position
	_ex.rumbo = atan2(v.x, v.z)
	_ex.paso(Vector2.ZERO, false, 0.0)
	_ex.cuerpo.visible = not retrato
	_ex._colocar_camara(1.0)
	if retrato:
		_ex.camara.position = n.position + dir * 2.6 + Vector3(0.6, 1.65, 0)
		_ex.camara.look_at(n.position + Vector3(0, 1.45, 0), Vector3.UP)
	print("PERSONA ", g["clave"], " ", g["nombre"], " planta ", g["planta"])

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_vista.recorrer()
		_ex = _vista._explorador
		_ex.set_physics_process(false)
	if _n == 12:
		_pe = _ex._personal()
		## Todos quietos en su puesto para la foto.
		for g: Dictionary in _pe.gente:
			g["quieto"] = true
		print("PERSONAS ", _pe.gente.size())
	if _n >= 14 and (_n - 14) % 6 == 0:
		if _k > 0:
			_foto()
		if _k >= _pe.gente.size():
			if _imgs.size() < 12:
				## La última: la charla con el primero (el conserje).
				_ir_a(_pe.gente[3], false)
				_ex.usar()
				_k += 1
				return
		if _imgs.size() >= 12 or _k > _pe.gente.size():
			var hoja := Image.create(480 * 4, 270 * 3, false, Image.FORMAT_RGBA8)
			for i in _imgs.size():
				hoja.blit_rect(_imgs[i], Rect2i(0, 0, 480, 270), Vector2i((i % 4) * 480, (i / 4) * 270))
			hoja.save_png("res://pruebas/capturas/personal_estadio.png")
			print("HOJA OK")
			get_tree().quit()
			return
		_ir_a(_pe.gente[_k])
		_k += 1
