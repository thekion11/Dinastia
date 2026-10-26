extends Control
## SONDA (borrar al acabar): los trofeos 3D y los logos de cada tipo.
const TIPOS := ["liga", "copa", "supercopa", "continental", "continental2", "mundial_clubes", "mundial_sel"]
const NOMBRES := ["Liga Argentina", "Copa Argentina", "Supercopa de Argentina", "Copa Cóndor", "Copa Cruz del Sur",
	"Mundial de Clubes", "Copa del Mundo", "Copa América"]
var _n := 0

var _w: Node3D

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color(0.16, 0.17, 0.2)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var vc := SubViewportContainer.new()
	vc.stretch = true
	vc.position = Vector2(0, 0)
	vc.size = Vector2(1280, 470)
	add_child(vc)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vc.add_child(vp)
	_w = Node3D.new()
	vp.add_child(_w)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.17, 0.2)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.ambient_light_energy = 0.6
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	we.environment = env
	_w.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, 30, 0)
	sol.light_energy = 1.6
	_w.add_child(sol)
	var omni := OmniLight3D.new()
	omni.position = Vector3(0, 1.2, 1.5)
	omni.light_energy = 2.0
	omni.omni_range = 6
	_w.add_child(omni)
	for i in TIPOS.size():
		var t := Trofeo3D.crear(TIPOS[i], 0.5)
		t.position = Vector3(-1.95 + float(i) * 0.65, 0, 0)
		_w.add_child(t)
	var cam := Camera3D.new()
	cam.fov = 40
	_w.add_child(cam)
	cam.look_at_from_position(Vector3(0, 0.6, 3.3), Vector3(0, 0.28, 0), Vector3.UP)
	var capa := self
	var fila := HBoxContainer.new()
	fila.position = Vector2(30, 490)
	fila.add_theme_constant_override("separation", 14)
	capa.add_child(fila)
	for nom: String in NOMBRES:
		var col := VBoxContainer.new()
		col.add_child(LogoCompeticion.control(nom, 96))
		var l := Label.new()
		l.text = "%s\n(%s)" % [CompeticionInfo.nombre_visible(nom), CompeticionInfo.tipo_de(nom)]
		l.custom_minimum_size = Vector2(120, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 12)
		col.add_child(l)
		fila.add_child(col)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/rp_trofeos.png")
		get_tree().quit()
