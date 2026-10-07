class_name CasaNaturaleza
extends RefCounted
## LO NATURAL DE LA ESCENA DE TU CASA (28-9-2026, "el ambiente se ve poco
## natural"). Todo procedural y animado, sin modelos importados:
##   - el cielo con nubes que se mueven y el disco del sol (`material_cielo`);
##   - el césped de verdad: miles de briznas que se mecen con el viento
##     (`cesped`), en vez de un plano liso;
##   - árboles con tronco que se afina y copa de varias masas, que el viento
##     mece (`arbol`), en vez de un cono o una esfera;
##   - el agua de la piscina con oleaje (`material_agua`);
##   - pájaros que cruzan el cielo aleteando (`pajaros`).

const CIELO := """
shader_type sky;
uniform vec3 arriba : source_color = vec3(0.30, 0.52, 0.84);
uniform vec3 horizonte : source_color = vec3(0.86, 0.80, 0.72);
uniform vec3 suelo : source_color = vec3(0.42, 0.40, 0.36);
uniform float nubes = 0.5;
uniform vec3 color_nube : source_color = vec3(1.0, 0.98, 0.95);
float h2(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p){ vec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1.0, 0.0)), u.x), mix(h2(i + vec2(0.0, 1.0)), h2(i + vec2(1.0, 1.0)), u.x), u.y); }
float fbm(vec2 p){ float v = 0.0; float a = 0.5; for (int k = 0; k < 5; k++){ v += a * ruido(p); p *= 2.03; a *= 0.5; } return v; }
void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 col = mix(horizonte, arriba, clamp(pow(max(h, 0.0), 0.55), 0.0, 1.0));
	if (h < 0.0) { col = mix(horizonte, suelo, clamp(-h * 4.0, 0.0, 1.0)); }
	if (LIGHT0_ENABLED) {
		float s = max(dot(d, LIGHT0_DIRECTION), 0.0);
		col += LIGHT0_COLOR * (pow(s, 1200.0) * 8.0 + pow(s, 10.0) * 0.18);
	}
	if (h > 0.01) {
		vec2 uv = d.xz / (h + 0.12) * 1.4 + vec2(TIME * 0.008, TIME * 0.003);
		float c = smoothstep(1.0 - nubes, 1.05 - nubes * 0.5, fbm(uv));
		float sombra = fbm(uv + vec2(0.08, 0.05));
		vec3 nube = mix(color_nube, color_nube * 0.72, smoothstep(0.4, 0.8, sombra));
		col = mix(col, nube, c * smoothstep(0.01, 0.2, h) * 0.92);
	}
	COLOR = col;
}
"""

const BRIZNA := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;
uniform vec3 base : source_color = vec3(0.13, 0.26, 0.08);
uniform vec3 punta : source_color = vec3(0.46, 0.62, 0.24);
varying float alto;
varying vec3 tinte;
void vertex() {
	alto = UV.y;
	tinte = COLOR.rgb;
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float viento = sin(TIME * 1.7 + w.x * 0.35 + w.z * 0.22) * 0.5 + sin(TIME * 3.1 + w.x * 1.3) * 0.2;
	VERTEX.x += viento * 0.09 * UV.y * UV.y;
	VERTEX.z += viento * 0.04 * UV.y * UV.y;
}
void fragment() {
	vec3 c = mix(base, punta, alto) * tinte;
	ALBEDO = c;
	ROUGHNESS = 0.9;
	BACKLIGHT = vec3(0.25, 0.35, 0.1) * alto;
}
"""

const FOLLAJE := """
shader_type spatial;
uniform vec3 color_hoja : source_color = vec3(0.2, 0.38, 0.14);
uniform float fase = 0.0;
varying vec3 pos_mundo;
float h2(vec3 p){ return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float v = sin(TIME * 1.2 + fase + pos_mundo.x * 0.3) * 0.06 + sin(TIME * 2.3 + fase * 2.0 + pos_mundo.y) * 0.025;
	VERTEX.x += v * max(VERTEX.y + 0.5, 0.0);
	VERTEX.z += v * 0.6 * max(VERTEX.y + 0.5, 0.0);
}
void fragment() {
	// Manchas de luz y sombra dentro de la copa: se lee como follaje, no
	// como una bola lisa.
	vec3 q = pos_mundo * 2.2;
	float n = sin(q.x + sin(q.y * 1.3)) * sin(q.z * 1.1 + q.y * 0.7) * 0.5 + 0.5;
	float fino = sin(q.x * 4.1 + q.z * 3.3) * sin(q.y * 3.7) * 0.5 + 0.5;
	ALBEDO = color_hoja * (0.7 + n * 0.45 + fino * 0.12);
	ROUGHNESS = 0.95;
	BACKLIGHT = vec3(0.12, 0.2, 0.05);
}
"""

const AGUA := """
shader_type spatial;
render_mode blend_mix, cull_back;
uniform vec3 color_agua : source_color = vec3(0.08, 0.45, 0.62);
void fragment() {
	vec2 uv = UV * 8.0;
	float t = TIME * 0.7;
	vec3 n = normalize(vec3(sin(uv.x * 2.7 + t) * 0.12 + sin(uv.y * 3.3 - t * 1.4) * 0.08,
		1.0, cos(uv.y * 2.9 + t * 0.9) * 0.12 + sin(uv.x * 1.7 - t) * 0.06));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(color_agua, vec3(0.75, 0.88, 0.95), fres * 0.6);
	ROUGHNESS = 0.04;
	METALLIC = 0.15;
	SPECULAR = 0.9;
	ALPHA = 0.86;
}
"""

static var _sh := {}

static func _shader(clave: String, codigo: String) -> Shader:
	if not _sh.has(clave):
		var s := Shader.new()
		s.code = codigo
		_sh[clave] = s
	return _sh[clave]

static func material_cielo() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader("cielo", CIELO)
	return m

static func material_agua() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader("agua", AGUA)
	return m

## Una brizna: una tira de 3 tramos que se afina hacia la punta.
static func _malla_brizna() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tramos := 3
	var puntos: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	for i in tramos + 1:
		var y := float(i) / float(tramos)
		var ancho := 0.025 * (1.0 - y * 0.85)
		var curva := y * y * 0.06
		puntos.append(Vector3(-ancho, y, curva))
		puntos.append(Vector3(ancho, y, curva))
		uvs.append(Vector2(0.0, y))
		uvs.append(Vector2(1.0, y))
	for i in tramos:
		var a := i * 2
		for k: int in [a, a + 1, a + 2, a + 1, a + 3, a + 2]:
			st.set_uv(uvs[k])
			st.set_normal(Vector3(0, 0, 1))
			st.add_vertex(puntos[k])
	return st.commit()

## EL CÉSPED: `cuantas` briznas en el rectángulo, salvo donde `evitar` (una
## lista de Rect2 en XZ: la terraza, la casa, la piscina...).
static func cesped(padre: Node3D, desde: Vector2, hasta: Vector2, cuantas: int, evitar: Array, semilla: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _malla_brizna()
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var xfs: Array[Transform3D] = []
	var cols: Array[Color] = []
	var intentos := 0
	while xfs.size() < cuantas and intentos < cuantas * 3:
		intentos += 1
		var p := Vector2(rng.randf_range(desde.x, hasta.x), rng.randf_range(desde.y, hasta.y))
		var fuera := true
		for r: Rect2 in evitar:
			if r.has_point(p):
				fuera = false
				break
		if not fuera:
			continue
		var alto := rng.randf_range(0.18, 0.42)
		var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(1.0, alto, 1.0))
		b = b.rotated(Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized(), rng.randf_range(0.0, 0.25))
		xfs.append(Transform3D(b, Vector3(p.x, 0.0, p.y)))
		var v := rng.randf_range(0.8, 1.15)
		cols.append(Color(v * rng.randf_range(0.92, 1.05), v, v * rng.randf_range(0.85, 1.0)))
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, cols[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = _shader("brizna", BRIZNA)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mi)
	return mi

## UN ÁRBOL: tronco que se afina, dos ramas y una copa de 6 a 9 masas de
## hojas de tamaños distintos, cada una con su vaivén.
static func arbol(padre: Node3D, pos: Vector3, alto: float, rng: RandomNumberGenerator) -> Node3D:
	var a := Node3D.new()
	a.position = pos
	a.rotation.y = rng.randf() * TAU
	padre.add_child(a)
	var corteza := StandardMaterial3D.new()
	corteza.albedo_color = Color(0.3, 0.22, 0.15).darkened(rng.randf_range(0.0, 0.2))
	corteza.roughness = 0.95
	var tronco := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = alto * 0.025
	cm.bottom_radius = alto * 0.05
	cm.height = alto * 0.6
	cm.radial_segments = 8
	tronco.mesh = cm
	tronco.material_override = corteza
	tronco.position = Vector3(0, alto * 0.3, 0)
	a.add_child(tronco)
	for s in [-1.0, 1.0]:
		var rama := MeshInstance3D.new()
		var rm := CylinderMesh.new()
		rm.top_radius = alto * 0.008
		rm.bottom_radius = alto * 0.018
		rm.height = alto * 0.3
		rm.radial_segments = 6
		rama.mesh = rm
		rama.material_override = corteza
		rama.position = Vector3(s * alto * 0.07, alto * 0.55, 0)
		rama.rotation.z = -s * 0.7
		a.add_child(rama)
	var hoja := ShaderMaterial.new()
	hoja.shader = _shader("follaje", FOLLAJE)
	hoja.set_shader_parameter("color_hoja", Color(0.18, 0.36, 0.13).lerp(Color(0.32, 0.45, 0.16), rng.randf()))
	hoja.set_shader_parameter("fase", rng.randf() * TAU)
	var masas := rng.randi_range(6, 9)
	for i in masas:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var r := alto * rng.randf_range(0.14, 0.22)
		sm.radius = r
		sm.height = r * 1.7
		sm.radial_segments = 12
		sm.rings = 6
		mi.mesh = sm
		mi.material_override = hoja
		var ang := float(i) / float(masas) * TAU + rng.randf_range(-0.3, 0.3)
		var rad := alto * rng.randf_range(0.08, 0.2)
		mi.position = Vector3(cos(ang) * rad, alto * rng.randf_range(0.62, 0.92), sin(ang) * rad)
		a.add_child(mi)
	return a

## PÁJAROS: una bandada pequeña que cruza el cielo en círculos amplios,
## aleteando.
static func pajaros(padre: Node3D, centro: Vector3, cuantos: int, semilla: int) -> Node3D:
	var b := _Bandada.new()
	b.centro = centro
	padre.add_child(b)
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var negro := StandardMaterial3D.new()
	negro.albedo_color = Color(0.08, 0.08, 0.1)
	negro.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in cuantos:
		var p := Node3D.new()
		b.add_child(p)
		for s in [-1.0, 1.0]:
			var ala := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(0.45, 0.14)
			ala.mesh = q
			ala.material_override = negro
			ala.rotation_degrees.x = -90.0
			ala.position = Vector3(s * 0.22, 0, 0)
			ala.set_meta("lado", s)
			p.add_child(ala)
		b.pajaros.append([p, rng.randf() * TAU, rng.randf_range(10.0, 22.0), rng.randf_range(14.0, 22.0), rng.randf_range(0.18, 0.3)])
	return b

class _Bandada extends Node3D:
	var centro := Vector3.ZERO
	var pajaros: Array = []   ## [nodo, fase, radio, alto, velocidad]
	var _t := 0.0
	func _process(delta: float) -> void:
		_t += delta
		for d: Array in pajaros:
			var p: Node3D = d[0]
			var ang := float(d[1]) + _t * float(d[4])
			var r := float(d[2])
			p.position = centro + Vector3(cos(ang) * r, float(d[3]) + sin(_t * 0.7 + float(d[1])) * 1.2, sin(ang) * r * 0.6)
			p.rotation.y = -ang
			var aleteo := sin(_t * 9.0 + float(d[1]) * 5.0) * 0.6
			for ala in p.get_children():
				(ala as Node3D).rotation.z = aleteo * float(ala.get_meta("lado"))
