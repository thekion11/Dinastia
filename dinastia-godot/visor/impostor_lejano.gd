class_name ImpostorLejano
## (14-11, orden del dueño: «siluetas de jugadores a más de 30 m») Los jugadores y árbitros lejanos dejan de dibujar sus mallas con piel y
## se ven como una cápsula simple del color de su camiseta: 6 caras, unos 70 triángulos contra ~5.000 de un cuerpo con su pelo.
## Usa el rango de visibilidad del motor (sin código por fotograma): el cuerpo se oculta a más de `DISTANCIA` m y la cápsula aparece
## desde ahí. El esqueleto y su animación siguen corriendo (cerca se ven igual que siempre). Solo en niveles «ligeros» (BAJA e inferiores
## más MEDIA BAJA): el jugador de MEDIA hacia arriba no cambia. Apagable con la variable de entorno `SIN_IMPOSTORES=1`.
const DISTANCIA := 30.0   ## m: la distancia mínima (y la de partida, antes de ver la cámara)
const MARGEN := 3.0
## (17-11, auditoría) EL UMBRAL VA POR TAMAÑO EN PANTALLA, no por metros fijos: con la cámara de TV cercana (21°) un jugador a 30 m mide
## ~180 px de alto y salía como cápsula al lado de otros con su cuerpo. Ahora la silueta solo aparece por debajo de `PIXELES` de alto
## en la pantalla (con la cámara y la ventana de ese momento) y con un fundido corto (`MARGEN`).
const PIXELES := 40.0
const ALTURA_REF := 1.8
const DIST_MAX := 220.0
static var distancia := DISTANCIA
static var FIJO := OS.get_environment("IMPOSTOR_FIJO") != ""   ## A/B: el umbral de antes (30 m fijos), para medir
static var _piezas: Array = []        ## [WeakRef(GeometryInstance3D), es_silueta]
static var _ultimo_cuadro := -1
const SOMBREADOR := "res://visor/impostor_lejano.gdshader"
const TONOS_PIEL: Array[Color] = [Color("5a3a28"), Color("8d5d42"), Color("c08a68"), Color("e6bfa3")]
static var _mats: Dictionary = {}
static var _malla: CapsuleMesh

## Ajustes → «Jugadores lejanos simplificados» (`Calidad.lejanos_simples`): automático = de ULTRA BAJA a MEDIA BAJA; siempre; nunca.
static func activo(nivel: int) -> bool:
	if OS.get_environment("SIN_IMPOSTORES") != "" or Calidad.lejanos_simples == 2:
		return false
	return Calidad.lejanos_simples == 1 or nivel <= Calidad.MEDIA_BAJA

## Se llama con el jugador YA vestido (cuerpo, ropa, pelo, cara). `altura` = metros del jugador; `color` = color de la camiseta.
## (16-11, frente 2) `piel`: con ella la silueta lleva cabeza y rodillas de piel, y short y medias salen de su equipación.
static func aplicar(nodo: Node3D, altura: float, color: Color, nivel: int, ap: AnimationPlayer = null, piel := Color(0, 0, 0, 0)) -> void:
	if nodo == null or not activo(nivel):
		return
	var piezas := 0
	var equip: ShaderMaterial = null
	var cuerpo: MeshInstance3D = null
	for g in nodo.find_children("*", "GeometryInstance3D", true, false):
		if g is Label3D:
			continue
		var gi := g as GeometryInstance3D
		_poner_rango(gi, 0)
		piezas += 1
		var eq := _equipacion_de(gi)
		if eq != null and gi is MeshInstance3D and (cuerpo == null or _vertices(gi as MeshInstance3D) > _vertices(cuerpo)):
			cuerpo = gi as MeshInstance3D
		if equip == null:
			equip = eq
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
	mi.material_override = _material(color) if piel.a == 0.0 else _material_equipado(color, piel, equip)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_poner_rango(mi, 2)
	_piezas.append([weakref(mi), 2])
	nodo.add_child(mi)
	## (17-11, auditoría) EL CUERPO BARATO de media distancia: una copia del cuerpo (misma malla, esqueleto y material de equipación) sin
	## sombra, sin pelo, cara ni capas de la cabeza, de `DISTANCIA` m hasta que el jugador mide `PIXELES` de alto; luego, la silueta.
	if cuerpo != null:
		var lod := cuerpo.duplicate() as MeshInstance3D
		lod.name = "CuerpoMedio"
		lod.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cuerpo.get_parent().add_child(lod)
		_poner_rango(lod, 1)
		_piezas.append([weakref(lod), 1])
	AnimLejana.poner(nodo, ap)   ## y su animación, a 5 Hz mientras esté lejos

## `tramo`: 0 = el cuerpo completo y sus capas (hasta `DISTANCIA`), 1 = el cuerpo barato (de `DISTANCIA` a `distancia`), 2 = la silueta.
static func _poner_rango(gi: GeometryInstance3D, tramo: int) -> void:
	if tramo != 2:
		gi.visibility_range_end = DISTANCIA if tramo == 0 else maxf(distancia, DISTANCIA)
		gi.visibility_range_end_margin = MARGEN
	if tramo != 0:
		gi.visibility_range_begin = DISTANCIA if tramo == 1 else distancia
		gi.visibility_range_begin_margin = MARGEN
	gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF   ## fundido corto, sin salto

static func _vertices(m: MeshInstance3D) -> int:
	return 0 if m.mesh == null or m.mesh.get_surface_count() == 0 else m.mesh.surface_get_array_len(0)

## La distancia (m) a la que un jugador de `ALTURA_REF` mide `PIXELES` de alto con esta cámara y esta ventana (`alto_px`).
static func distancia_para(fov_vertical: float, alto_px: float) -> float:
	var t := tan(deg_to_rad(clampf(fov_vertical, 5.0, 120.0)) * 0.5)
	return clampf(ALTURA_REF * alto_px / (2.0 * PIXELES * t), DISTANCIA, DIST_MAX)

## Lo llama cada `AnimLejana` (una vez por cuadro en total, y solo cada 15 cuadros): si la cámara o la ventana cambiaron el umbral, lo
## reparte entre todas las piezas vivas. Sin coste por cuadro el resto del tiempo.
static func vigilar(vp: Viewport) -> void:
	var f := Engine.get_process_frames()
	if f == _ultimo_cuadro or f % 15 != 0 or FIJO or Calidad.elegida <= Calidad.MINIMO:
		return   ## (17-11, decisión de la auditoría) en ULTRA BAJA, 30 m fijos (con fundido) mientras el LOD intermedio no lo deje neutro
	_ultimo_cuadro = f
	var cam := vp.get_camera_3d()
	if cam == null:
		return
	var alto := vp.get_visible_rect().size.y
	var fov_v := cam.fov
	if cam.keep_aspect == Camera3D.KEEP_WIDTH:
		var asp := vp.get_visible_rect().size.x / maxf(alto, 1.0)
		fov_v = rad_to_deg(2.0 * atan(tan(deg_to_rad(cam.fov) * 0.5) / maxf(asp, 0.1)))
	var d := distancia_para(fov_v, alto)
	if absf(d - distancia) < 2.0:
		return
	distancia = d
	var vivas: Array = []
	for e: Array in _piezas:
		var gi := (e[0] as WeakRef).get_ref() as GeometryInstance3D
		if gi != null:
			_poner_rango(gi, int(e[1]))
			vivas.append(e)
	_piezas = vivas

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
