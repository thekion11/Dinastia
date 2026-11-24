class_name ImpostorLejano
## (14-11, orden del dueño: «siluetas de jugadores a más de 30 m») Los jugadores y árbitros lejanos dejan de dibujar sus mallas con piel y
## se ven como una cápsula simple del color de su camiseta: 6 caras, unos 70 triángulos contra ~5.000 de un cuerpo con su pelo.
## Usa el rango de visibilidad del motor (sin código por fotograma): el cuerpo se oculta a más de `DISTANCIA` m y la cápsula aparece
## desde ahí. El esqueleto y su animación siguen corriendo (cerca se ven igual que siempre). Solo en niveles «ligeros» (BAJA e inferiores
## más MEDIA BAJA): el jugador de MEDIA hacia arriba no cambia. Apagable con la variable de entorno `SIN_IMPOSTORES=1`.
const DISTANCIA := 30.0
const MARGEN := 2.0
const SOMBREADOR := "res://visor/impostor_lejano.gdshader"
const TONOS_PIEL: Array[Color] = [Color("5a3a28"), Color("8d5d42"), Color("c08a68"), Color("e6bfa3")]
static var _mats: Dictionary = {}
static var _malla: CapsuleMesh

static func activo(nivel: int) -> bool:
	return nivel <= Calidad.MEDIA_BAJA and OS.get_environment("SIN_IMPOSTORES") == ""

## Se llama con el jugador YA vestido (cuerpo, ropa, pelo, cara). `altura` = metros del jugador; `color` = color de la camiseta.
## (16-11, frente 2) `piel`: con ella la silueta lleva cabeza y rodillas de piel, y short y medias salen de su equipación.
static func aplicar(nodo: Node3D, altura: float, color: Color, nivel: int, ap: AnimationPlayer = null, piel := Color(0, 0, 0, 0)) -> void:
	if nodo == null or not activo(nivel):
		return
	var piezas := 0
	var equip: ShaderMaterial = null
	for g in nodo.find_children("*", "GeometryInstance3D", true, false):
		if g is Label3D:
			continue
		var gi := g as GeometryInstance3D
		gi.visibility_range_end = DISTANCIA
		gi.visibility_range_end_margin = MARGEN
		gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		piezas += 1
		if equip == null:
			equip = _equipacion_de(gi)
	if piezas == 0:
		return
	if _malla == null:
		_malla = CapsuleMesh.new()
		_malla.radius = 0.27
		_malla.height = 1.0
		_malla.radial_segments = 6
		_malla.rings = 1
	var mi := MeshInstance3D.new()
	mi.name = "ImpostorLejano"
	mi.mesh = _malla
	## Más estrecha de frente y de perfil (16-11): un cuerpo mide ~45 × 25 cm, no 54 × 54 (se leía como un barril).
	mi.scale = Vector3(0.85, altura, 0.6)
	mi.position.y = altura * 0.5
	mi.material_override = _material(color) if is_zero_approx(piel.a) else _material_equipado(color, piel, equip)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_begin = DISTANCIA
	mi.visibility_range_begin_margin = MARGEN
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	nodo.add_child(mi)
	AnimLejana.poner(nodo, ap)   ## y su animación, a 5 Hz mientras esté lejos

static func _material(c: Color) -> StandardMaterial3D:
	var k := c.to_html(false)
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.9
		_mats[k] = m
	return _mats[k]

## El material de equipación del jugador (`equipacion_q.gdshader`), si lo tiene: de él salen short y medias.
static func _equipacion_de(gi: GeometryInstance3D) -> ShaderMaterial:
	var lista: Array = [gi.material_override]
	var mi := gi as MeshInstance3D
	if mi != null:
		for k in mi.get_surface_override_material_count():
			lista.append(mi.get_surface_override_material(k))
	for m in lista:
		if m is ShaderMaterial and (m as ShaderMaterial).shader != null and (m as ShaderMaterial).shader.resource_path.ends_with("equipacion_q.gdshader"):
			return m
	return null

## Silueta con su equipación (16-11, frente 2): camiseta (el color medio del dibujo), short, medias y piel por alturas.
## Compartido por todos los que visten igual (una clave por combinación de colores).
static func _material_equipado(camiseta: Color, piel: Color, equip: ShaderMaterial) -> Material:
	var short := camiseta
	var medias := camiseta
	if equip != null:
		var sh: Variant = equip.get_shader_parameter("color_pantalon")
		var md: Variant = equip.get_shader_parameter("color_medias")
		short = sh if sh is Color else short
		medias = md if md is Color else medias
		var cols: Variant = equip.get_shader_parameter("cols")
		var fam: Variant = equip.get_shader_parameter("familia")
		if fam is int and int(fam) > 0 and cols is PackedColorArray and (cols as PackedColorArray).size() >= 2:
			camiseta = (cols as PackedColorArray)[0].lerp((cols as PackedColorArray)[1], 0.35)
	## La cabeza mide 2-3 px: cuatro tonos de piel bastan, y así los del mismo equipo comparten material y se dibujan juntos.
	piel = TONOS_PIEL[clampi(int(piel.get_luminance() * 4.0), 0, 3)]
	var k := "%s|%s|%s|%s" % [camiseta.to_html(false), short.to_html(false), medias.to_html(false), piel.to_html(false)]
	if not _mats.has(k):
		var m := ShaderMaterial.new()
		m.shader = load(SOMBREADOR)
		m.set_shader_parameter("c_camiseta", camiseta)
		m.set_shader_parameter("c_short", short)
		m.set_shader_parameter("c_medias", medias)
		m.set_shader_parameter("c_piel", piel)
		_mats[k] = m
	return _mats[k]
