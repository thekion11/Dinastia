class_name Publico2D
extends RefCounted
## EL PÚBLICO 2D (15-11-2026, prototipo): en lugar de miles de figuras 3D, un cuadro plano por hincha con sprites horneados de nuestras
## propias figuras (`herramientas/hornear_publico_2d.gd`, `hinchada_2d.gdshader`). Apagado por defecto; `PUBLICO_2D=1` o `Publico2D.forzar = true`.
## Sin los atlas (`assets/ciudad/publico/publico2d_*.png`) devuelve false y el estadio monta el público 3D de siempre.

const ATLAS := "res://assets/ciudad/publico/publico2d_albedo.png"
const MASCARA := "res://assets/ciudad/publico/publico2d_mascara.png"
const ANCHO := 0.7333   ## mismo encuadre que el hornero: alto 1,1 m, ancho 2/3 del alto
const ALTO := 1.1
const CENTRO_Y := 0.62

static var forzar := false
static var _mat: ShaderMaterial
static var _malla: QuadMesh

static func activo() -> bool:
	return (forzar or OS.get_environment("PUBLICO_2D") == "1") and ResourceLoader.exists(ATLAS) and ResourceLoader.exists(MASCARA)

static func _material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://visor/hinchada_2d.gdshader")
		_mat.set_shader_parameter("atlas", load(ATLAS))
		_mat.set_shader_parameter("mascara", load(MASCARA))
	return _mat

static func _quad() -> QuadMesh:
	if _malla == null:
		_malla = QuadMesh.new()
		_malla.size = Vector2(ANCHO, ALTO)
		_malla.center_offset = Vector3(0, CENTRO_Y, 0)
	return _malla

## Monta TODO el público de una grada (cerca, medio y resto) como cuadros planos. `gt` = el `_Gente` del estadio (det_xf/det_col, med_xf/med_col, hinchas_xf/hinchas_col).
## Un MultiMesh por tribuna, con el material compartido: así `OlaGrada` y `FestejoGrada` lo encuentran (`hinchada` en la ruta del shader).
static func montar(deck: Node3D, gt: Object) -> bool:
	if not activo():
		return false
	var xf: Array[Transform3D] = []
	var col: Array[Color] = []
	for par in [["det_xf", "det_col"], ["med_xf", "med_col"], ["hinchas_xf", "hinchas_col"]]:
		xf.append_array(gt.get(par[0]))
		col.append_array(gt.get(par[1]))
	if xf.is_empty():
		return true
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _quad()
	mm.instance_count = xf.size()
	for k in xf.size():
		mm.set_instance_transform(k, xf[k])
		mm.set_instance_color(k, col[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _material()
	mmi.name = "Publico2D"
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	deck.add_child(mmi)
	gt.get("det_xf").clear()
	gt.get("det_col").clear()
	return true
