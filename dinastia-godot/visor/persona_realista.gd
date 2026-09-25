class_name PersonaRealista
extends RefCounted
## PERSONAS REALISTAS Y PERSONALIZABLES (25-9-2026).
##
## El usuario pidió que el mentor del tutorial dejara de ser un dibujo ("el
## mentor estéticamente es cutre, deben ser personajes realistas y
## personalizables") y dejó en su Drive el modelo para el presentador del
## sorteo. Ese modelo es `navy-jacket-portrait.zip` (`recursos/modelos3d/`): un
## ESCANEO fotogramétrico de una persona real de cuerpo entero, 1,90 m, con
## chaqueta, camiseta, vaqueros y zapatillas. Es lo más realista que tiene el
## proyecto, así que sirve para las dos cosas.
##
## Personalizable con `persona_realista.gdshader`: color de la chaqueta, del
## pantalón, del pelo y de los zapatos, tono de piel, estatura y complexión. Un "aspecto" es un diccionario con esas claves; los que falten
## salen de la semilla, así cada mentor tiene uno propio y estable.
##
## Límite honesto: es un escaneo SIN esqueleto -una estatua fotográfica-. No
## anda ni gesticula; se le da vida con el cuerpo entero (respirar, cambiar el
## peso, girarse), que es lo que se puede hacer sin rig.

const MODELO := "res://assets/personas/persona_realista.glb"
const SHADER := "res://visor/persona_realista.gdshader"
## Alto del escaneo tal como viene (de -0,95 a 0,95).
const ALTO_MODELO := 1.90

const ROPAS := {
	"marino": Color(0.13, 0.16, 0.24), "negro": Color(0.06, 0.06, 0.07),
	"gris": Color(0.30, 0.31, 0.33), "burdeos": Color(0.30, 0.07, 0.10),
	"camel": Color(0.52, 0.38, 0.22), "verde": Color(0.10, 0.25, 0.17),
	"azul": Color(0.10, 0.22, 0.48), "blanco": Color(0.78, 0.78, 0.76),
}
const PANTALONES := {
	"vaquero": Color(0.10, 0.17, 0.30), "negro": Color(0.06, 0.06, 0.07),
	"gris": Color(0.28, 0.29, 0.31), "beige": Color(0.55, 0.48, 0.36),
	"marino": Color(0.10, 0.12, 0.20),
}
const PELOS := {
	"negro": Color(0.05, 0.045, 0.04), "castaño": Color(0.20, 0.12, 0.07),
	"rubio": Color(0.42, 0.31, 0.16), "canoso": Color(0.36, 0.36, 0.35),
	"pelirrojo": Color(0.32, 0.11, 0.04),
}
const PIELES := {
	"clara": Vector3(1.12, 1.08, 1.06), "media": Vector3(1.0, 1.0, 1.0),
	"morena": Vector3(0.78, 0.70, 0.64), "oscura": Vector3(0.52, 0.42, 0.37),
}

static var _escena: PackedScene
static var _mats := {}

static func disponible() -> bool:
	return ResourceLoader.exists(MODELO) and ResourceLoader.exists(SHADER)

## El aspecto completo: el que se pide, y lo que falte, sacado de la semilla.
static func aspecto(semilla: String, pedido: Dictionary = {}) -> Dictionary:
	var h := absi(semilla.hash())
	var a := {
		"ropa": ROPAS.keys()[h % ROPAS.size()],
		"pantalon": PANTALONES.keys()[(h / 7) % PANTALONES.size()],
		"pelo": PELOS.keys()[(h / 31) % PELOS.size()],
		"piel": PIELES.keys()[(h / 131) % PIELES.size()],
		"alto": 1.72 + float((h / 17) % 17) / 100.0,
		"ancho": 0.94 + float((h / 23) % 13) / 100.0,
	}
	for k: String in pedido:
		a[k] = pedido[k]
	return a

## Instancia la persona con ese aspecto, con los pies en y=0 y mirando a +Z.
static func crear(asp: Dictionary) -> Node3D:
	if not disponible():
		return null
	if _escena == null:
		_escena = load(MODELO)
	if _escena == null:
		return null
	var raiz := Node3D.new()
	raiz.name = "PersonaRealista"
	var modelo: Node3D = _escena.instantiate()
	raiz.add_child(modelo)
	var alto := float(asp.get("alto", 1.80))
	var s := alto / ALTO_MODELO
	var ancho := float(asp.get("ancho", 1.0))
	## Sin espejo: una escala negativa invierte las normales del escaneo y la
	## luz lo atraviesa (se probó: la persona salía lavada, como en niebla).
	modelo.scale = Vector3(s * ancho, s, s * ancho)
	modelo.position.y = 0.95 * s
	for m in modelo.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var mat := _material(mi, asp)
		if mat != null:
			mi.material_override = mat
	return raiz

static func _material(mi: MeshInstance3D, asp: Dictionary) -> ShaderMaterial:
	var original := mi.get_active_material(0) as StandardMaterial3D
	if original == null:
		return null
	var clave := "%s|%s|%s|%s|%s" % [asp.get("ropa"), asp.get("pantalon"), asp.get("pelo"), asp.get("piel"), asp.get("zapatos", "")]
	if _mats.has(clave):
		return _mats[clave]
	var m := ShaderMaterial.new()
	m.shader = load(SHADER)
	m.set_shader_parameter("albedo_tex", original.albedo_texture)
	m.set_shader_parameter("normal_tex", original.normal_texture)
	m.set_shader_parameter("orm_tex", original.roughness_texture)
	m.set_shader_parameter("uv_escala", Vector2(original.uv1_scale.x, original.uv1_scale.y))
	m.set_shader_parameter("uv_desplaza", Vector2(original.uv1_offset.x, original.uv1_offset.y))
	m.set_shader_parameter("escala_malla", mi.scale.y)
	m.set_shader_parameter("origen_malla", mi.position)
	m.set_shader_parameter("personalizar", true)
	m.set_shader_parameter("color_arriba", _de(ROPAS, asp.get("ropa"), ROPAS["marino"]))
	m.set_shader_parameter("color_abajo", _de(PANTALONES, asp.get("pantalon"), PANTALONES["vaquero"]))
	m.set_shader_parameter("color_pelo", _de(PELOS, asp.get("pelo"), PELOS["negro"]))
	m.set_shader_parameter("color_zapatos", _de(ROPAS, asp.get("zapatos", "negro"), ROPAS["negro"]))
	m.set_shader_parameter("tinte_piel", PIELES.get(String(asp.get("piel", "media")), Vector3.ONE))
	_mats[clave] = m
	return m

static func _de(tabla: Dictionary, clave: Variant, defecto: Color) -> Color:
	if clave is Color:
		return clave
	return tabla.get(String(clave), defecto)

## UN RETRATO VIVO: la persona en un plató pequeño -luz de tres puntos, fondo
## con el color que se pida- dentro de un `SubViewport`. Respira y cambia el
## peso despacio. `plano`: "cara" (cabeza y hombros), "medio" (cintura para
## arriba) o "entero".
static func retrato(asp: Dictionary, tam: Vector2i, fondo: Color, plano: String = "cara") -> SubViewportContainer:
	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.custom_minimum_size = Vector2(tam)
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.size = tam
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_4X
	cont.add_child(vp)
	var plato := PlatoRetrato.new()
	plato.montar(asp, fondo, plano)
	vp.add_child(plato)
	return cont

class PlatoRetrato:
	extends Node3D
	var _persona: Node3D
	var _t := 0.0
	var _giro0 := 0.0

	func montar(asp: Dictionary, fondo: Color, plano: String) -> void:
		var env := WorldEnvironment.new()
		var e := Environment.new()
		e.background_mode = Environment.BG_COLOR
		e.background_color = fondo
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = fondo.lerp(Color(0.8, 0.8, 0.85), 0.6)
		e.ambient_light_energy = 0.35
		e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.environment = e
		add_child(env)
		## Luz de tres puntos: principal cálida, relleno frío y recorte detrás
		## para separar la silueta del fondo.
		for d: Array in [[Vector3(-28, 35, 0), Color(1.0, 0.93, 0.84), 1.0],
				[Vector3(-10, -40, 0), Color(0.75, 0.82, 1.0), 0.45],
				[Vector3(-20, 170, 0), Color(1.0, 1.0, 1.0), 1.1]]:
			var l := DirectionalLight3D.new()
			l.rotation_degrees = d[0]
			l.light_color = d[1]
			l.light_energy = d[2]
			add_child(l)
		_persona = PersonaRealista.crear(asp)
		if _persona != null:
			add_child(_persona)
			_giro0 = deg_to_rad(-12.0)
			_persona.rotation.y = _giro0
		var alto := float(asp.get("alto", 1.80))
		var cam := Camera3D.new()
		match plano:
			"entero":
				cam.fov = 32.0
				cam.position = Vector3(0, alto * 0.55, 3.6)
				cam.look_at_from_position(cam.position, Vector3(0, alto * 0.5, 0))
			"medio":
				cam.fov = 28.0
				cam.position = Vector3(0, alto * 0.82, 1.9)
				cam.look_at_from_position(cam.position, Vector3(0, alto * 0.76, 0))
			_:
				cam.fov = 22.0
				cam.position = Vector3(0, alto * 0.93, 1.05)
				cam.look_at_from_position(cam.position, Vector3(0, alto * 0.905, 0))
		add_child(cam)
		cam.current = true

	func _process(delta: float) -> void:
		_t += delta
		if _persona == null:
			return
		## Respirar y cambiar el peso: mínimo, pero lo separa de una foto.
		_persona.scale = Vector3(1.0, 1.0 + sin(_t * 1.6) * 0.004, 1.0)
		_persona.rotation.y = _giro0 + sin(_t * 0.35) * 0.05
		_persona.rotation.z = sin(_t * 0.5) * 0.008
