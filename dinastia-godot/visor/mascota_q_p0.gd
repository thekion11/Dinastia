extends Node
## [Capa 1/3 de `mascota_q.gd`] material_pelaje, _pegar, _mat, _esf, _cono, _pelaje_oscuro … (+6)

## LA MASCOTA DEL CLUB, REHECHA (26-9-2026). Pedido del usuario: *"pueden
## mejorar las mascotas"*.
##
## Antes: una persona con la equipación y, pegadas a la cabeza, cuatro esferas
## de color plano (cabeza, hocico, ojos) y dos orejas; ocho animales, quieta
## saludando en bucle. Se leía como "un jugador con un globo en la cabeza".
##
## Ahora es un traje de mascota de verdad:
##   - PELAJE (`pelaje.gdshader`): mechones, grano, manchas, pelusa en el
##     borde a contraluz; rayas para el tigre y escamas para dragón, cocodrilo
##     y tiburón.
##   - CABEZA de dibujo animado: ojos grandes con iris, pupila y brillo, cejas,
##     sonrisa, mejillas, nariz, y un hocico o pico con la forma del animal.
##   - OREJAS, CUERNOS, CRESTAS Y MELENAS propios de cada uno de los 17
##     animales (antes 8).
##   - GUANTES enormes en las manos, PATAS en los pies y COLA (que se mueve).
##   - EL CUERPO: camiseta del club de manga larga y piernas del color del
##     pelaje, como los trajes de verdad.
##   - SE MUEVE: alterna saludo, aplauso, baile, salto, llamar a la hinchada…
##     y cada tanto da un paseo por la banda, en vez de un solo gesto en bucle.
## El animal sale del hash del club (`EstadioExtras.animal_de`): siempre el
## mismo para el mismo club.

## animal -> [color natural, orejas, hocico, cola, extra, mezcla con el club]
const ANIMALES := {
	"perro":     [Color(0.78, 0.58, 0.36), "caidas", "largo", "larga", "lengua", 0.30],
	"gato":      [Color(0.88, 0.62, 0.30), "puntiagudas", "redondo", "larga", "bigotes", 0.35],
	"oso":       [Color(0.46, 0.30, 0.18), "redondas", "redondo", "bola", "", 0.25],
	"aguila":    [Color(0.95, 0.95, 0.93), "", "pico", "plumas", "ceño", 0.10],
	"leon":      [Color(0.88, 0.66, 0.30), "redondas", "redondo", "larga_borla", "melena", 0.20],
	"toro":      [Color(0.30, 0.18, 0.12), "puntiagudas", "ancho", "larga_borla", "cuernos", 0.30],
	"zorro":     [Color(0.92, 0.46, 0.14), "puntiagudas", "largo", "tupida", "mejillas_blancas", 0.15],
	"lobo":      [Color(0.52, 0.52, 0.55), "puntiagudas", "largo", "tupida", "mejillas_blancas", 0.25],
	"tigre":     [Color(0.96, 0.56, 0.14), "redondas", "redondo", "larga", "rayas", 0.10],
	"gallo":     [Color(0.96, 0.95, 0.92), "", "pico", "plumas", "cresta", 0.20],
	"dragon":    [Color(0.22, 0.62, 0.32), "", "largo", "larga", "cuernos_dragon", 0.35],
	"caballo":   [Color(0.52, 0.33, 0.18), "caballo", "largo", "crin", "crin", 0.25],
	"conejo":    [Color(0.93, 0.91, 0.89), "largas", "redondo", "pompon", "dientes", 0.20],
	"pinguino":  [Color(0.08, 0.08, 0.11), "", "pico", "plumas", "antifaz", 0.15],
	"cocodrilo": [Color(0.26, 0.46, 0.22), "", "cocodrilo", "larga", "dientes_cocodrilo", 0.25],
	"buho":      [Color(0.56, 0.41, 0.26), "penachos", "pico", "plumas", "anteojos", 0.25],
	"mono":      [Color(0.46, 0.31, 0.20), "laterales", "redondo", "larga", "cara_clara", 0.20],
	"tiburon":   [Color(0.46, 0.52, 0.62), "", "tiburon", "aleta", "aleta_dorsal", 0.30],
}
const CON_ESCAMAS := ["dragon", "cocodrilo", "tiburon"]
const GESTOS := ["saludar_publico", "llamar_hinchada", "aplaudir", "baile", "puno_al_aire",
	"corazon_manos", "celebrar", "aplauso_arriba", "mano_oido", "saludo_mano"]

var _ap: AnimationPlayer
var _cuerpo: Node3D
var _cola: Node3D
var _soporte: Node3D
## En la configuración del club no hay banda: no pasea (si no se sale del cuadro).
var en_sitio := false
var _esq: Skeleton3D
var _i_pelvis := -1
var _desde_pelvis := Transform3D.IDENTITY
var _t := 0.0
var _hasta := 0.0
var _caminando := false
var _dir := 1.0
var _giro0 := 0.0
var _rng := RandomNumberGenerator.new()

# -----------------------------------------------------------------------------
#  MATERIALES Y PIEZAS
# -----------------------------------------------------------------------------

static var _cache_pelaje: Dictionary = {}

static func material_pelaje(col: Color, animal: String) -> ShaderMaterial:
	var clave := col.to_html() + "|" + animal
	if _cache_pelaje.has(clave):
		return _cache_pelaje[clave]
	var m := ShaderMaterial.new()
	m.shader = load("res://visor/pelaje.gdshader")
	m.set_shader_parameter("color", col)
	m.set_shader_parameter("color_puntas", col.lightened(0.25))
	m.set_shader_parameter("rayas", 0.85 if animal == "tigre" else 0.0)
	m.set_shader_parameter("escamas", 1.0 if animal in CON_ESCAMAS else 0.0)
	_cache_pelaje[clave] = m
	return m

## Un nodo pegado a un hueso, con la escala del modelo compensada: dentro,
## las medidas son metros reales.
static func _pegar(esq: Skeleton3D, hueso: String, k: float) -> Node3D:
	var ba := BoneAttachment3D.new()
	ba.bone_name = hueso
	esq.add_child(ba)
	var n := Node3D.new()
	n.scale = Vector3.ONE * k
	ba.add_child(n)
	return n

static func _mat(col: Color, rug: float = 0.7, emision: float = 0.0, alfa: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col, alfa)
	m.roughness = rug
	if emision > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emision
	if alfa < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

static func _esf(root: Node3D, pos: Vector3, r: float, m: Material, esc := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 20
	sm.rings = 10
	mi.mesh = sm
	mi.material_override = m
	mi.position = pos
	mi.scale = esc
	root.add_child(mi)
	return mi

static func _cono(root: Node3D, pos: Vector3, giro: Vector3, r: float, h: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = r
	cm.height = h
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = giro
	root.add_child(mi)
	return mi

static func _pelaje_oscuro(col: Color) -> ShaderMaterial:
	return material_pelaje(col.darkened(0.3), "")

static func _caps(root: Node3D, pos: Vector3, giro: Vector3, r: float, h: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = h
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = giro
	root.add_child(mi)
	return mi

static func _cil(root: Node3D, pos: Vector3, giro: Vector3, r: float, h: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = giro
	root.add_child(mi)
	return mi
