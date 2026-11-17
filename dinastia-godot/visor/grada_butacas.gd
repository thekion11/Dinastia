class_name GradaButacas
extends RefCounted
## Piezas de las butacas de la grada que salieron de `stadium_builder_p6.gd` (17-11, tope de 450 líneas): el color de un grupo
## según sus asientos vacíos y el nodo `MultiMesh` con su plástico.

## LAS BUTACAS VACÍAS, EN SOMBRA (17-11, comparación con FC Mobile): con la cámara de TV la grada se leía como plástico del club con
## gente suelta encima (en MÍNIMA hay un hincha por grupo de tres asientos). Cada grupo se oscurece y apaga según cuántos de sus TRES
## asientos quedan libres: la grada llena sigue igual y la vacía se hunde hacia el tono del hormigón, como la sombra entre la gente.
## Sin coste: es el color de instancia que ya llevaba cada grupo; el azar no cambia (se mira después de repartir la hinchada).
static func color_vacia(col: Color, vacias: int) -> Color:
	var v := clampf(float(vacias) / 3.0, 0.0, 1.0)
	var gris := col.get_luminance()
	var c := col.lerp(Color(gris, gris, gris, col.a), 0.45 * v)
	return c.darkened(0.58 * v)

## Un MultiMesh de butacas colgado del deck, con su plástico barnizado. SIN SOMBRA PROPIA (25-9-2026, `pruebas/medir_partido.gd`): miles de butacas
## proyectando sombra se dibujaban otra vez en CADA cascada del sol; bajo el techo no se ve y la de la grada entera (el `deck`) sigue estando.
static func nodo(deck: MeshInstance3D, mm: MultiMesh, nombre: String, rugosidad: float, metal: float, barniz: float, barniz_rug: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(0.9, 0.9, 0.9)
	mat.roughness = rugosidad
	if metal > 0.0:
		mat.metallic = metal
	mat.clearcoat_enabled = true
	mat.clearcoat = barniz
	mat.clearcoat_roughness = barniz_rug
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	mi.name = nombre
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	deck.add_child(mi)
