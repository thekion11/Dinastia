class_name PublicoVat
extends RefCounted
## LA HINCHADA ANIMADA (26-10-2026): carga las mallas con textura de vértices
## que hornea `herramientas/hornear_publico_vat.gd` y configura el material de
## `hinchada.gdshader` de cada grupo. Si el recurso no está, o con
## SIN_VAT_PUBLICO=1 (para medir antes/después), devuelve vacío y el estadio
## monta las poses quietas de siempre (`StadiumBuilder._hinchas_horneados`).

const RUTA := "res://assets/ciudad/publico/hincha_vat_%s.res"
## Pose quieta de cada grupo de `POSES_PUBLICO` -> clip de reposo (índices de
## `hornear_publico_vat.gd::CLIPS`): quieto→sentado, charla→charla,
## aplaude→aplaude, aplaude_arriba→escucha, puno→asiente, pulgar→sentado,
## cruzados→cruzados, cabeza→charla.
const REPOSO_DE := {"quieto": 0, "charla": 1, "aplaude": 2, "aplaude_arriba": 3, "puno": 4,
	"pulgar": 0, "cruzados": 5, "cabeza": 1}

static var _cache: Dictionary = {}

static func malla(nivel: String) -> Mesh:
	if OS.get_environment("SIN_VAT_PUBLICO") != "":
		return null
	if _cache.has(nivel):
		return _cache[nivel]
	var ruta := RUTA % nivel
	var m: Mesh = null
	if ResourceLoader.exists(ruta):
		m = load(ruta) as Mesh
		if m != null and not (m.has_meta("vat_tex") and m.has_meta("vat_duraciones")):
			m = null
	_cache[nivel] = m
	return m

static func es_vat(m: Mesh) -> bool:
	return m != null and m.has_meta("vat_tex")

## Deja el material listo para la malla VAT `m`, con el reposo de la pose `pose`.
static func configurar(mat: ShaderMaterial, m: Mesh, pose: String) -> void:
	mat.set_shader_parameter("vat_tex", m.get_meta("vat_tex"))
	mat.set_shader_parameter("vat_min", m.get_meta("vat_min"))
	mat.set_shader_parameter("vat_max", m.get_meta("vat_max"))
	var d: Array = m.get_meta("vat_duraciones")
	var dur := PackedFloat32Array()
	for x in d:
		dur.append(float(x))
	mat.set_shader_parameter("vat_dur", dur)
	mat.set_shader_parameter("vat_reposo", int(REPOSO_DE.get(pose, 0)))
	mat.set_shader_parameter("vat_activo", 1.0)
