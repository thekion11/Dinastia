extends Node
## ESTADIO 2.0, fase 5: decorar. La oficina del DT antes y después (paredes,
## suelo, objetos propios y una foto del modo foto colgada), la sala de
## prensa decorada y el panel abierto. Hoja: `pruebas/capturas/decorar.png`.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 res://pruebas/captura_decorar.tscn

var _vista: VistaEstadio
var _ex: ExploradorEstadio
var _imgs: Array[Image] = []
var _n := 0

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var club: Club = m.ligas[0].clubes[0]
	PersonajeDT.club_usuario = club.id
	## Una «foto del modo foto» de prueba, con el escudo de colores del club.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ModoFoto.CARPETA))
	var img := Image.create(240, 160, false, Image.FORMAT_RGB8)
	img.fill(Color(club.color1))
	for x in 240:
		for y in range(60, 100):
			img.set_pixel(x, y, Color(club.color2))
	img.save_png(ModoFoto.CARPETA + "/foto_prueba-decorar.png")
	EdificioClub.ctx = {"inst": {"video": 4}, "plantilla": [], "titulos": 2, "presidente": "Presidente"}
	var perfil := EstadioPropio.new().perfil(club)
	perfil["niveles"] = 2
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.85, null, null, perfil)

func _foto() -> void:
	var img := get_viewport().get_texture().get_image()
	img.resize(480, 270)
	_imgs.append(img)

func _a_sala(planta: int, sala: String) -> void:
	_ex.ir_a_planta(planta)
	for z: Dictionary in _ex.zonas:
		if int(z.get("planta", 0)) == planta and String(z["nombre"]) == sala and (z["r"] as Rect2).get_area() > 6.0:
			var r: Rect2 = z["r"]
			_ex.cuerpo.position = Vector3(r.get_center().x, RecorridoClub.y_de(planta), r.end.y - 0.2)
			_ex.rumbo = PI
			_ex.paso(Vector2.ZERO, false, 0.0)
			_ex.cuerpo.visible = false
			_ex._colocar_camara(1.0)
			_ex.camara.position = Vector3(r.get_center().x + 0.4, RecorridoClub.y_de(planta) + 1.9, r.end.y + 0.3)
			_ex.camara.look_at(Vector3(r.get_center().x, RecorridoClub.y_de(planta) + 1.0, r.position.y + 0.5), Vector3.UP)
			return

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_vista.recorrer()
		_ex = _vista._explorador
		_ex.set_physics_process(false)
		_a_sala(1, "Oficina del DT")
	if _n == 14:
		_foto()                                    # 1: la oficina de fábrica
		var it := RecorridoClub.interiores()
		it.pintar("Oficina del DT", "pared", "1f3f6b")
		it.pintar("Oficina del DT", "suelo", "e9dcc9")
		for k: String in ["sofa", "bufanda", "planta", "maqueta", "trofeo", "lampara"]:
			it.poner("Oficina del DT", k)
		it.colgar("Oficina del DT", ModoFoto.CARPETA + "/foto_prueba-decorar.png")
		it.colgar("Oficina del DT", ModoFoto.CARPETA + "/foto_prueba-decorar.png")
		EdificioClub.reconstruir(get_tree().get_first_node_in_group("edificio_club"))
	if _n == 20:
		_foto()                                    # 2: la oficina decorada
		var it2 := RecorridoClub.interiores()
		it2.pintar("Sala de prensa", "pared", "7a1f2b")
		for k: String in ["bandera", "tele", "planta", "cafe"]:
			it2.poner("Sala de prensa", k)
		EdificioClub.reconstruir(get_tree().get_first_node_in_group("edificio_club"))
		_a_sala(2, "Sala de prensa")
	if _n == 26:
		_foto()                                    # 3: la sala de prensa decorada
		_a_sala(1, "Oficina del DT")
		_ex._zona_actual = "Oficina del DT"
		_ex.usar()
	if _n == 32:
		_foto()                                    # 4: el panel de decorar
		var hoja := Image.create(480 * 2, 270 * 2, false, Image.FORMAT_RGBA8)
		for k in _imgs.size():
			hoja.blit_rect(_imgs[k], Rect2i(0, 0, 480, 270), Vector2i((k % 2) * 480, (k / 2) * 270))
		hoja.save_png("res://pruebas/capturas/decorar.png")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ModoFoto.CARPETA + "/foto_prueba-decorar.png"))
		print("HOJA OK")
		get_tree().quit()
