class_name ImpostorLejano
## (14-11, orden del dueño: «siluetas de jugadores a más de 30 m») Los jugadores y árbitros lejanos dejan de dibujar sus mallas con piel y
## se ven como una cápsula simple del color de su camiseta: 6 caras, unos 70 triángulos contra ~5.000 de un cuerpo con su pelo.
## Usa el rango de visibilidad del motor (sin código por fotograma): el cuerpo se oculta a más de `DISTANCIA` m y la cápsula aparece
## desde ahí. El esqueleto y su animación siguen corriendo (cerca se ven igual que siempre). Solo en niveles «ligeros» (BAJA e inferiores
## más MEDIA BAJA): el jugador de MEDIA hacia arriba no cambia. Apagable con la variable de entorno `SIN_IMPOSTORES=1`.
const DISTANCIA := 30.0
const MARGEN := 2.0
static var _mats: Dictionary = {}
static var _malla: CapsuleMesh

static func activo(nivel: int) -> bool:
	return nivel <= Calidad.MEDIA_BAJA and OS.get_environment("SIN_IMPOSTORES") == ""

## Se llama con el jugador YA vestido (cuerpo, ropa, pelo, cara). `altura` = metros del jugador; `color` = color de la camiseta.
static func aplicar(nodo: Node3D, altura: float, color: Color, nivel: int, ap: AnimationPlayer = null) -> void:
	if nodo == null or not activo(nivel):
		return
	var piezas := 0
	for g in nodo.find_children("*", "GeometryInstance3D", true, false):
		if g is Label3D:
			continue
		var gi := g as GeometryInstance3D
		gi.visibility_range_end = DISTANCIA
		gi.visibility_range_end_margin = MARGEN
		gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		piezas += 1
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
	mi.scale = Vector3(1.0, altura, 1.0)
	mi.position.y = altura * 0.5
	mi.material_override = _material(color)
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
