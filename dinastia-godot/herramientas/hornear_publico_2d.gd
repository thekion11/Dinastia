extends Node
## HORNEA EL PÚBLICO 2D (15-11-2026, prototipo): fotografía nuestras propias figuras 3D de la hinchada (`hincha_vat_cerca`, con su
## ropa, bufandas, gorras, pelo y pieles ya variados por `hinchada.gdshader`) en varios clips y fotogramas, y las guarda como un
## atlas de sprites + un atlas de máscaras. El estadio dibuja entonces cada hincha como UN cuadro plano (2 triángulos en vez de
## 80-658) con `hinchada_2d.gdshader`. Sin fotos de personas: solo nuestros modelos.
##   Cuatro pasadas por sprite para separar lo que cambia con el club: base (ropa y bufandas en blanco), ropa en negro,
##   bufanda 1 en negro, bufanda 2 en negro. La diferencia de cada una con la base da la máscara (R = ropa, G = bufanda/raya 1,
##   B = bufanda/raya 2); el resto (piel, pelo, chaqueta) queda como en la base.
##   xvfb-run -a godot --path . --rendering-driver opengl3 res://herramientas/hornear_publico_2d.tscn
## Salida: assets/ciudad/publico/publico2d_albedo.png y publico2d_mascara.png

const VARIANTES := 12
const CLIPS := [0, 1, 2, 6, 7, 10]   ## sentado, charla, aplaude, manos a la cabeza, festejo, abucheo (índices del VAT)
const CUADROS := 3                    ## instantes por clip
const W := 64
const H := 96
const SS := 2                         ## supermuestreo
const ALTO_M := 1.1                   ## alto del sprite en metros (ancho = 2/3); el cuadro del estadio mide lo mismo
const CENTRO_Y := 0.62
const SALIDA := "res://assets/ciudad/publico/"

var _vp: SubViewport
var _mm: MultiMeshInstance3D
var _mat: ShaderMaterial
var _cam: Camera3D

func _ready() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(W * SS, H * SS)
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var cam := Camera3D.new()
	_cam = cam
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = ALTO_M
	cam.position = Vector3(0, CENTRO_Y, 3.0)
	_vp.add_child(cam)
	cam.current = true
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-38, 18, 0)
	sol.light_energy = 1.0
	_vp.add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.72, 0.75)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var malla := PublicoVat.malla("cerca")
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://visor/hinchada.gdshader")
	_mat.set_shader_parameter("cuello_desde", float(malla.get_meta("cuello_desde", 0.70)))
	_mat.set_shader_parameter("cuello_hasta", float(malla.get_meta("cuello_hasta", 0.73)))
	_mat.set_shader_parameter("pelo_desde", float(malla.get_meta("pelo_desde", 0.86)))
	_mat.set_shader_parameter("lado_max", 0.14)
	_mat.set_shader_parameter("amplitud", 0.03)
	PublicoVat.configurar(_mat, malla, "quieto")
	var durs: Array = malla.get_meta("vat_duraciones")
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = malla
	mm.instance_count = 1
	_mm = MultiMeshInstance3D.new()
	_mm.multimesh = mm
	_mm.material_override = _mat
	_vp.add_child(_mm)
	await get_tree().process_frame
	var cols := CLIPS.size() * CUADROS
	var albedo := Image.create(cols * W, VARIANTES * H, false, Image.FORMAT_RGBA8)
	var mascara := Image.create(cols * W, VARIANTES * H, false, Image.FORMAT_RGBA8)
	for v in VARIANTES:
		## Un origen distinto = otro «azar» del hincha (piel, pelo, bufanda, gorra, rayas).
		var origen := Vector3(7.31 * float(v) + 1.7, 0.0, 3.13 * float(v) * float(v) + 0.9)
		mm.set_instance_transform(0, Transform3D(Basis(), origen))
		_cam.position = origen + Vector3(0, CENTRO_Y, 3.0)
		for c in CLIPS.size():
			for f in CUADROS:
				var t := float(f) / float(CUADROS) * maxf(float(durs[CLIPS[c]]), 0.1)
				_mat.set_shader_parameter("clip_fijo", int(CLIPS[c]))
				_mat.set_shader_parameter("tiempo_fijo", t)
				var base := await _foto(Color(1, 1, 1, 1), Color(1, 1, 1), Color(1, 1, 1))
				var sin_ropa := await _foto(Color(0, 0, 0, 1), Color(1, 1, 1), Color(1, 1, 1))
				var sin_b1 := await _foto(Color(1, 1, 1, 1), Color(0, 0, 0), Color(1, 1, 1))
				var sin_b2 := await _foto(Color(1, 1, 1, 1), Color(1, 1, 1), Color(0, 0, 0))
				var ox := (c * CUADROS + f) * W
				var oy := v * H
				for y in H:
					for x in W:
						var p := base.get_pixel(x, y)
						var mr := smoothstep(0.3, 0.75, _dif(p, sin_ropa.get_pixel(x, y)))
						var m1 := smoothstep(0.3, 0.75, _dif(p, sin_b1.get_pixel(x, y)))
						var m2 := smoothstep(0.3, 0.75, _dif(p, sin_b2.get_pixel(x, y)))
						albedo.set_pixel(ox + x, oy + y, p)
						mascara.set_pixel(ox + x, oy + y, Color(mr, m1, m2, 1.0))
		print("variante ", v + 1, "/", VARIANTES)
	albedo.save_png(SALIDA + "publico2d_albedo.png")
	mascara.save_png(SALIDA + "publico2d_mascara.png")
	print("HORNEADO PÚBLICO 2D: ", albedo.get_size(), " ", cols, " columnas x ", VARIANTES, " variantes")
	get_tree().quit()

## Fuerza al máximo la diferencia (normalizada a 0..1) entre la base y la pasada con una parte en negro.
func _dif(a: Color, b: Color) -> float:
	if a.a < 0.05:
		return 0.0
	return clampf(((a.r + a.g + a.b) - (b.r + b.g + b.b)) / maxf(a.r + a.g + a.b, 0.05) * 1.1, 0.0, 1.0)

func _foto(ropa: Color, b1: Color, b2: Color) -> Image:
	_mm.multimesh.set_instance_color(0, ropa)
	_mat.set_shader_parameter("bufanda1", b1)
	_mat.set_shader_parameter("bufanda2", b2)
	for _i in 3:
		await RenderingServer.frame_post_draw
	var img := _vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(W, H, Image.INTERPOLATE_LANCZOS)
	return img
