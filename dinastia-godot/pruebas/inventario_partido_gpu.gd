extends Node
## INVENTARIO DE LA GPU DEL PARTIDO 3D (4-11-2026, A4): qué se dibuja con la cámara de TV y cuánto cuesta cada parte, en MÍNIMO y MEDIO.
##   herramientas/hw_modesto.sh res://pruebas/inventario_partido_gpu.tscn -- medio|minimo
## llvmpipe está limitada por RELLENO de píxeles y por vértices, como la GPU de un teléfono: el tiempo de fotograma (reloj de pared, incluye el dibujado) de cada variante
## sirve para COMPARAR qué parte pesa, no para sacar FPS. Cada variante apaga UNA cosa respecto a la base y mide `N` fotogramas.
const CALENTAR := 30
const N := 14
var _vista: VistaEstadio
var _n := 0
var _paso := -1
var _t_ult := 0
var _muestras: Array[float] = []
var _base_ms := 0.0
var _hecho := false
var _ocultos: Array = []
var _env: Environment
var _vp: Viewport

func _ready() -> void:
	var nivel := Calidad.MINIMO if OS.get_environment("NIVEL") == "minimo" or "minimo" in OS.get_cmdline_user_args() else Calidad.MEDIO
	Calidad.elegida = nivel
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _grupo(nombre: String) -> Array:
	var r := []
	for n in _vista.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var es_mm := g is MultiMeshInstance3D
		match nombre:
			"butacas": if String(g.name).begins_with("Butacas"): r.append(g)
			"hinchas": if es_mm and not String(g.name).begins_with("Butacas") and (g as MultiMeshInstance3D).multimesh.instance_count > 200: r.append(g)
			"jugadores": if g.get_parent() is Skeleton3D: r.append(g)
			"entorno": if String(g.name).begins_with("EntornoEstadio") or (g.get_parent() != null and String(g.get_parent().name).begins_with("EntornoEstadio")): r.append(g)
			"vallas_y_carteles": if String(g.name).begins_with("Vallas") or g is Label3D: r.append(g)
	for l in _vista.find_children("*", "Label3D", true, false):
		if nombre == "vallas_y_carteles" and (l as Node3D).is_visible_in_tree():
			r.append(l)
	return r

## Las variantes: [nombre, función que apaga algo].
func _variantes() -> Array:
	var we: WorldEnvironment = null
	for w in _vista.find_children("*", "WorldEnvironment", true, false):
		we = w
	_env = we.environment if we != null else null
	for l in _vista.find_children("*", "Light3D", true, false):
		_sombra_orig[l] = (l as Light3D).shadow_enabled
	_vp = get_viewport()
	return [
		["BASE (como en el juego)", func() -> void: pass],
		["sin ajuste de color (brillo/contraste/saturación)", func() -> void: if _env: _env.adjustment_enabled = false],
		["tonemap lineal (sin ACES)", func() -> void: if _env: _env.tonemap_mode = Environment.TONE_MAPPER_LINEAR],
		["sin niebla", func() -> void: if _env: _env.fog_enabled = false],
		["cielo → color plano (sin shader de cielo)", func() -> void: if _env: _env.background_mode = Environment.BG_COLOR],
		["sin reflejo del cielo/ambiente de cielo", func() -> void: if _env: _env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR],
		["sin MSAA", func() -> void: _vp.msaa_3d = Viewport.MSAA_DISABLED],
		["sin sombras (todas las luces)", func() -> void: for l in _vista.find_children("*", "Light3D", true, false): (l as Light3D).shadow_enabled = false],
		["3D al 50 % de resolución", func() -> void: _vp.scaling_3d_scale = 0.5],
		["3D al 35 % de resolución", func() -> void: _vp.scaling_3d_scale = 0.35],
		["sin hinchas (público)", func() -> void: for g in _grupo("hinchas"): (g as Node3D).visible = false],
		["sin butacas", func() -> void: for g in _grupo("butacas"): (g as Node3D).visible = false],
		["sin jugadores", func() -> void: for g in _grupo("jugadores"): (g as Node3D).visible = false],
		["sin entorno exterior", func() -> void: for g in _grupo("entorno"): (g as Node3D).visible = false],
		["sin rótulos 3D (Label3D)", func() -> void: for l in _vista.find_children("*", "Label3D", true, false): (l as Node3D).visible = false],
		["sin luces de foco (OmniLight/SpotLight)", func() -> void: for l in _vista.find_children("*", "Light3D", true, false): if not l is DirectionalLight3D: (l as Light3D).visible = false],
	]

var _vars: Array = []

func _process(_d: float) -> void:
	if _hecho:
		return
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
		return
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
		return
	_n += 1
	if _n == 5:
		(_vista.get("_rig") as CameraRig).switch_to(0)
	if _n < CALENTAR:
		return
	if _vars.is_empty():
		_vars = _variantes()
		_paso = 0
		_vars[0][1].call()
		_t_ult = Time.get_ticks_usec()
		_n = 0
		return
	var ahora := Time.get_ticks_usec()
	_muestras.append(float(ahora - _t_ult) / 1000.0)
	_t_ult = ahora
	if _muestras.size() < N + 4:
		return
	var m := _muestras.slice(4)   ## se descartan los primeros fotogramas tras cada cambio
	m.sort()
	var mediana: float = m[m.size() / 2]
	var llam := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var tri := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	if _paso == 0:
		_base_ms = mediana
	print("GPU %-58s %7.0f ms (%+5.0f%%)  llamadas %4.0f  triángulos %8.0f" % [String(_vars[_paso][0]), mediana, (mediana / maxf(_base_ms, 0.001) - 1.0) * 100.0, llam, tri])
	_muestras.clear()
	## Cada variante se mide por separado: se deshace lo anterior reiniciando el estado visible/env/viewport.
	_paso += 1
	if _paso >= _vars.size():
		_hecho = true
		_inventario()
		get_tree().quit()
		return
	_restaurar()
	_vars[_paso][1].call()
	_t_ult = Time.get_ticks_usec()

var _guardado: Dictionary = {}
func _restaurar() -> void:
	if _env != null:
		_env.adjustment_enabled = true
		_env.tonemap_mode = Environment.TONE_MAPPER_ACES
		_env.fog_enabled = true
		_env.background_mode = Environment.BG_SKY
		_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	Calidad.aplicar_viewport(_vp, Calidad.elegida)
	for n in _vista.find_children("*", "GeometryInstance3D", true, false):
		(n as GeometryInstance3D).visible = true
	for l in _vista.find_children("*", "Light3D", true, false):
		(l as Light3D).visible = true
	## las sombras se vuelven a encender según el nivel (Ambience las puso): se reaplican las de la luz solar
	for l in _vista.find_children("*", "Light3D", true, false):
		(l as Light3D).shadow_enabled = _sombra_orig.get(l, (l as Light3D).shadow_enabled)

var _sombra_orig := {}

## Qué hay: materiales transparentes, de shader, luces, texturas.
func _inventario() -> void:
	var transp := 0
	var shaders := {}
	var unshaded := 0
	var tot_mat := {}
	var mallas := 0
	var luces := {}
	for n in _vista.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		mallas += 1
		var mats: Array = []
		if g.material_override != null:
			mats.append(g.material_override)
		var mi := g as MeshInstance3D
		if mi != null and mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				var mt := mi.get_active_material(s)
				if mt != null:
					mats.append(mt)
		var mmi := g as MultiMeshInstance3D
		if mmi != null and mmi.multimesh != null and mmi.multimesh.mesh != null:
			for s in mmi.multimesh.mesh.get_surface_count():
				var mt2 := mmi.multimesh.mesh.surface_get_material(s)
				if mt2 != null:
					mats.append(mt2)
		for mt in mats:
			tot_mat[mt] = true
			if mt is BaseMaterial3D:
				var b := mt as BaseMaterial3D
				if b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					transp += 1
				if b.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
					unshaded += 1
			elif mt is ShaderMaterial and (mt as ShaderMaterial).shader != null:
				shaders[(mt as ShaderMaterial).shader.resource_path if (mt as ShaderMaterial).shader.resource_path != "" else str((mt as ShaderMaterial).shader.get_instance_id())] = true
	for l in _vista.find_children("*", "Light3D", true, false):
		var k := (l as Node).get_class()
		luces[k] = int(luces.get(k, 0)) + 1
	print("INV geometrías visibles ", mallas, " · materiales distintos ", tot_mat.size(), " · con transparencia ", transp, " · sin sombreado ", unshaded, " · shaders propios ", shaders.size())
	print("INV luces ", luces, " · MSAA ", _vp.msaa_3d, " · escala 3D ", _vp.scaling_3d_scale, " · nivel ", Calidad.elegida)
	if _env != null:
		print("INV entorno: tonemap ", _env.tonemap_mode, " ajuste ", _env.adjustment_enabled, " niebla ", _env.fog_enabled, " glow ", _env.glow_enabled, " ssao ", _env.ssao_enabled, " cielo ", _env.background_mode)
