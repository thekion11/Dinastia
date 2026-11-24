class_name PrologoPlanos
extends Node
## LOS PLANOS DEL PRÓLOGO (18-11-2026, decisión del dueño: prólogo «mixto» que varíe según el club; paso 2 = planos de cámara por paso).
## Al llegar a cada sala del recorrido, ANTES de que hable el mentor, un plano de establecimiento: franjas de cine, el nombre de la sala con el
## color del club y la cámara recorriendo la sala de una esquina alta a la otra; al final vuelve, suave, a tus ojos (primera persona, orden 45).
## Qué esquina, qué altura y hacia dónde se mueve salen de la semilla club + paso: cada club ve su edificio desde otro sitio.
## Se salta con E / Intro / Espacio / X / A o un clic. Es la base de la cinemática pregrabada (mismos planos, grabados con `--write-movie`).

signal terminado

const SEG_RECORRIDO := 3.0
const SEG_VUELTA := 0.7
const SALAS := ["puerta", "vestuario", "tunel", "campo", "utileria", "enfermeria", "presidente", "video", "prensa", "comedor", "oficina"]
const ALTO_FRANJA := 0.11   ## fracción de la pantalla que tapa cada franja de cine

var _cam: Camera3D
var _expl: Node
var _modo_antes := Node.PROCESS_MODE_INHERIT
var _vuelta := Transform3D.IDENTITY
var _capa: CanvasLayer
var _franjas: Array[ColorRect] = []
var _rotulo: VBoxContainer
var _filtro: ColorRect
var _tw: Tween
var _saltar := false
var _activo := false

## ¿Tiene plano este paso del guion?
static func tiene(clave: String) -> bool:
	return clave in SALAS

## Las dos poses (desde, hasta) del recorrido por la sala `r` (suelo x-z en el mundo; la puerta da a +Z, la pared del fondo es `r.position.y`).
## Tres tipos según la semilla: BARRIDO (de una esquina alta a la otra), FRONTAL (desde la puerta, bajo, avanzando hacia el fondo) y DETALLE (de cerca
## de la pared del fondo, donde van el escudo y la pizarra, alejándose hasta abrir la sala).
const TIPOS := ["barrido", "frontal", "detalle"]

static func tipo_de(semilla: int) -> String:
	return TIPOS[absi(semilla) % TIPOS.size()]

static func poses(r: Rect2, y0: float, semilla: int) -> Array[Transform3D]:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var izq := rng.randf() < 0.5
	var alto := rng.randf_range(2.05, 2.55)
	var m := 0.45
	var x_a := r.position.x + m if izq else r.end.x - m
	var x_b := r.end.x - m if izq else r.position.x + m
	var c := r.get_center()
	var fondo := r.position.y + minf(0.9, r.size.y * 0.25)
	var a: Vector3
	var b: Vector3
	var mira_a: Vector3
	var mira_b: Vector3
	match tipo_de(semilla):
		"frontal":
			a = Vector3(c.x + (0.3 if izq else -0.3), y0 + 1.25, r.end.y - m)
			b = Vector3(c.x + (-0.2 if izq else 0.2), y0 + 1.45, lerpf(r.end.y, c.y, 0.55))
			mira_a = Vector3(c.x, y0 + 1.1, r.position.y)
			mira_b = Vector3(c.x, y0 + 1.3, r.position.y)
		"detalle":
			a = Vector3(c.x + (0.5 if izq else -0.5), y0 + 1.7, r.position.y + 1.3)
			b = Vector3(x_a, y0 + alto, r.end.y - m)
			mira_a = Vector3(c.x, y0 + 1.75, r.position.y)
			mira_b = Vector3(lerpf(c.x, x_b, 0.2), y0 + 1.0, fondo)
		_:
			a = Vector3(x_a, y0 + alto, r.end.y - m)
			b = Vector3(lerpf(x_b, c.x, 0.35), y0 + alto - 0.45, lerpf(r.end.y - m, c.y, rng.randf_range(0.15, 0.4)))
			mira_a = Vector3(lerpf(c.x, x_b, 0.25), y0 + 1.0, fondo)
			mira_b = Vector3(lerpf(c.x, x_a, 0.3), y0 + 1.15, fondo)
	return [Transform3D(Basis.IDENTITY, a).looking_at(mira_a, Vector3.UP), Transform3D(Basis.IDENTITY, b).looking_at(mira_b, Vector3.UP)]

## La fachada del club vista desde la calle (paso «puerta»): de lejos y alto, a la altura de la marquesina, acercándose a la puerta.
## La banda (paso «campo»): a ras de la línea de banda, de un lado a otro del banquillo, mirando al césped y al otro lado del estadio; `banda` es su suelo
## en el mundo y `centro` el centro del campo (`CityBuilder.ESTADIO_EN`). Desde el centro de la zona la cámara quedaba dentro de la red de la portería.
static func poses_banda(banda: Rect2, y0: float, centro: Vector3, semilla: int) -> Array[Transform3D]:
	var c := Vector3(banda.get_center().x, y0, banda.get_center().y)
	var d := Vector3(centro.x - c.x, 0.0, centro.z - c.z).normalized()
	var perp := d.cross(Vector3.UP)
	var lado := 1.0 if absi(semilla) % 2 == 0 else -1.0
	var a := c + perp * 9.0 * lado + Vector3(0, 1.7, 0)
	var b := c + perp * -5.0 * lado + d * 1.5 + Vector3(0, 2.8, 0)
	return [Transform3D(Basis.IDENTITY, a).looking_at(centro + perp * -6.0 * lado + Vector3(0, 1.2, 0), Vector3.UP),
		Transform3D(Basis.IDENTITY, b).looking_at(centro + perp * 8.0 * lado + Vector3(0, 2.0, 0), Vector3.UP)]

## `obstaculos`: cajas de setos, jardineras y árboles (`PrologoMentor.obstaculos`): se elige el primer punto de partida desde el que se ve la puerta.
static func poses_fachada(puerta: Vector3, semilla: int, obstaculos: Array[AABB] = []) -> Array[Transform3D]:
	var lado := 1.0 if absi(semilla) % 2 == 0 else -1.0
	var a := puerta + Vector3(7.0 * lado, 4.2, 15.0)
	for cand: Vector3 in [Vector3(7.0 * lado, 4.2, 15.0), Vector3(-7.0 * lado, 4.2, 15.0), Vector3(0.0, 5.0, 13.0), Vector3(3.0 * lado, 3.2, 10.0)]:
		var libre := true
		for o: AABB in obstaculos:
			if o.grow(0.3).intersects_segment(puerta + cand, puerta + Vector3(0, 2.0, 0)):
				libre = false
				break
		if libre:
			a = puerta + cand
			lado = signf(cand.x) if not is_zero_approx(cand.x) else lado
			break
	var b := puerta + Vector3(2.5 * lado, 2.2, 7.5)
	return [Transform3D(Basis.IDENTITY, a).looking_at(puerta + Vector3(0, 3.0, 0), Vector3.UP),
		Transform3D(Basis.IDENTITY, b).looking_at(puerta + Vector3(0, 2.0, 0), Vector3.UP)]

## Las copas de los árboles (MultiMesh con el shader de follaje) a menos de `radio` m de `centro`, en cajas del mundo: lo que puede tapar la fachada.
static func copas_cerca(raiz: Node, centro: Vector3, radio := 30.0) -> Array[AABB]:
	var r: Array[AABB] = []
	for n in raiz.find_children("*", "MultiMeshInstance3D", true, false):
		var mm := n as MultiMeshInstance3D
		var sm := mm.material_override as ShaderMaterial
		if mm.multimesh == null or mm.multimesh.mesh == null or sm == null or sm.shader == null or not sm.shader.resource_path.contains("follaje"):
			continue
		var caja := mm.multimesh.mesh.get_aabb()
		for i in mm.multimesh.instance_count:
			var t := mm.global_transform * mm.multimesh.get_instance_transform(i)
			if t.origin.distance_to(centro) < radio:
				r.append(t * caja)
	return r

## Rueda el plano y vuelve a los ojos del explorador. `sala`: el nombre (se traduce); `club`: el nombre visible; `color`: el del club.
func rodar(explorador: Node, r: Rect2, y0: float, semilla: int, sala: String, club: String, color: Color, fijas: Array[Transform3D] = []) -> void:
	_expl = explorador
	_cam = explorador.get("camara") as Camera3D
	if _cam == null or not _cam.is_inside_tree():
		terminado.emit()
		return
	_activo = true
	_vuelta = _cam.global_transform
	_modo_antes = explorador.process_mode
	explorador.process_mode = Node.PROCESS_MODE_DISABLED
	_montar_capa(Idiomas.t(sala), club, color)
	var p := fijas if fijas.size() == 2 else poses(r, y0, semilla)
	_cam.global_transform = p[0]
	_entrar_capa(true)
	_tw = create_tween()
	_tw.tween_method(_poner.bind(p[0], p[1]), 0.0, 1.0, SEG_RECORRIDO).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _tw.finished
	_entrar_capa(false)
	var desde := _cam.global_transform
	_tw = create_tween()
	_tw.tween_method(_poner.bind(desde, _vuelta), 0.0, 1.0, 0.05 if _saltar else SEG_VUELTA).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _tw.finished
	_cerrar()

func _poner(k: float, a: Transform3D, b: Transform3D) -> void:
	if is_instance_valid(_cam):
		_cam.global_transform = PcAnimacion._mezcla(a, b, k)

func _cerrar() -> void:
	_activo = false
	if is_instance_valid(_cam):
		_cam.global_transform = _vuelta
	if is_instance_valid(_expl):
		_expl.process_mode = _modo_antes
	if is_instance_valid(_capa):
		_capa.queue_free()
	terminado.emit()

func _unhandled_input(ev: InputEvent) -> void:
	if not _activo or _saltar:
		return
	var salta := (ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo and (ev as InputEventKey).keycode in [KEY_E, KEY_ENTER, KEY_SPACE]) \
		or (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed and (ev as InputEventJoypadButton).button_index in [JOY_BUTTON_X, JOY_BUTTON_A]) \
		or (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed)
	if salta:
		get_viewport().set_input_as_handled()
		_saltar = true
		if _tw != null and _tw.is_valid():
			_tw.custom_step(SEG_RECORRIDO)   ## acaba el recorrido ya: la vuelta a los ojos es casi inmediata

## Franjas de cine (arriba y abajo) y el rótulo de la sala abajo a la izquierda, con una raya del color del club.
func _montar_capa(sala: String, club: String, color: Color) -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 40
	add_child(_capa)
	for arriba in [true, false]:
		var f := ColorRect.new()
		f.color = Color(0, 0, 0, 1)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.anchor_left = 0.0
		f.anchor_right = 1.0
		f.anchor_top = 0.0 if arriba else 1.0
		f.anchor_bottom = 0.0 if arriba else 1.0
		_capa.add_child(f)
		_franjas.append(f)
	_filtro = _crear_filtro()
	_capa.add_child(_filtro)
	_capa.move_child(_filtro, 0)   ## debajo de las franjas y del rótulo
	_rotulo = VBoxContainer.new()
	_rotulo.anchor_top = 1.0 - ALTO_FRANJA - 0.17
	_rotulo.anchor_bottom = 1.0 - ALTO_FRANJA - 0.02
	_rotulo.anchor_left = 0.05
	_rotulo.anchor_right = 0.6
	_rotulo.modulate.a = 0.0
	_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa.add_child(_rotulo)
	var raya := ColorRect.new()
	raya.color = color
	raya.custom_minimum_size = Vector2(90, 4)
	raya.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_rotulo.add_child(raya)
	var t := Label.new()
	t.text = sala.to_upper()
	t.add_theme_font_size_override("font_size", 34)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	t.add_theme_constant_override("outline_size", 6)
	_rotulo.add_child(t)
	var s := Label.new()
	s.text = club
	s.add_theme_font_size_override("font_size", 18)
	s.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))   ## el color del club va en la raya: en letra, los oscuros no se leían sobre paredes claras
	s.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	s.add_theme_constant_override("outline_size", 5)
	_rotulo.add_child(s)

func _entrar_capa(entra: bool) -> void:
	var alto := get_viewport().get_visible_rect().size.y * ALTO_FRANJA
	var tw := create_tween().set_parallel(true)
	for i in _franjas.size():
		var f := _franjas[i]
		var arriba := i == 0
		tw.tween_property(f, "offset_bottom" if arriba else "offset_top", (alto if arriba else -alto) if entra else 0.0, 0.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_filtro.material, "shader_parameter/fuerza", 1.0 if entra else 0.0, 0.5)
	tw.tween_property(_rotulo, "modulate:a", 1.0 if entra else 0.0, 0.5 if entra else 0.25).set_delay(0.35 if entra else 0.0)

## EL FILTRO DE REALISMO (solo mientras dura el plano; 18-11, idea del dueño): un retoque de «cine» sobre lo que ya se ve, en un solo pase de pantalla
## (sirve igual en Compatibility que en Forward+): curva de contraste con hombros suaves, saturación algo contenida, luces cálidas y sombras frías,
## halo suave en las luces fuertes, viñeta, aberración cromática en los bordes y grano de película. `fuerza` (0-1) lo enciende y lo apaga con el fundido.
## SIN_FILTRO_CINE=1 lo apaga (el «antes»).
const SHADER_FILTRO := """
shader_type canvas_item;
uniform sampler2D pantalla : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float fuerza = 0.0;
float ruido(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }   // sin `sin`: sin rayas con coordenadas grandes
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float borde = dot(c, c);
	vec2 ab = c * borde * 0.012 * fuerza;   // aberración cromática: más en los bordes
	vec3 col = vec3(texture(pantalla, uv + ab).r, texture(pantalla, uv).g, texture(pantalla, uv - ab).b);
	vec3 halo = textureLod(pantalla, uv, 3.0).rgb;   // halo: lo claro de alrededor sangra un poco
	col += max(halo - 0.85, 0.0) * 0.18 * fuerza;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(lum), col, 1.0 - 0.1 * fuerza);   // saturación -10 %
	col = mix(col, col * col * (3.0 - 2.0 * col), 0.4 * fuerza);   // curva S: contraste con hombros suaves
	col = mix(col, col * vec3(1.03, 1.0, 0.95), smoothstep(0.5, 1.0, lum) * fuerza);   // luces cálidas
	col = mix(col, col * vec3(0.93, 0.98, 1.06), (1.0 - smoothstep(0.0, 0.45, lum)) * fuerza);   // sombras frías
	col *= 1.0 - smoothstep(0.06, 0.4, borde) * 0.5 * fuerza;   // viñeta
	col += (ruido(uv * vec2(1280.0, 720.0) + fract(TIME) * 100.0) - 0.5) * 0.03 * fuerza;   // grano
	COLOR = vec4(col, 1.0);
}
"""

static func _crear_filtro() -> ColorRect:
	var f := ColorRect.new()
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER_FILTRO
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("fuerza", 0.0)
	f.material = m
	f.visible = OS.get_environment("SIN_FILTRO_CINE") == ""
	return f
