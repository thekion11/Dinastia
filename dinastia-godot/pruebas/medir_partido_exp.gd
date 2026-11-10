class_name MedirPartidoExp
extends RefCounted
## EXPERIMENTOS DE RENDIMIENTO PARA `medir_partido.gd` (10-11-2026, rendimiento en móvil): cada variable de entorno apaga una cosa en el fotograma CALENTAR para medir cuánto cuesta (norma de 450 líneas: viven aquí).
##   SIN_OMNI=1          apaga las luces omni (túneles y edificio del club): en Compatibilidad cada luz cuesta en el sombreado de los objetos que toca.
##   SIN_ENTORNO_FX=1    apaga glow, niebla, ajuste de color y SSAO del WorldEnvironment (post-proceso a pantalla completa).
##   SIN_SOMBRA_FINOS=1  las piezas diminutas de los personajes (ojos, cejas, pestañas, pelo) no proyectan sombra: ¿cuántas llamadas de la pasada de sombras ahorra?

static func aplicar(vista: Node) -> void:
	if OS.get_environment("SIN_OMNI") != "":
		for l in vista.find_children("*", "OmniLight3D", true, false):
			(l as Light3D).visible = false
	if OS.get_environment("SIN_ENTORNO_FX") != "":
		for we in vista.find_children("*", "WorldEnvironment", true, false):
			var en: Environment = (we as WorldEnvironment).environment
			if en != null:
				en.glow_enabled = false
				en.fog_enabled = false
				en.adjustment_enabled = false
				en.ssao_enabled = false
	if OS.get_environment("SIN_SOMBRA_FINOS") != "":
		var nf := 0
		for g in vista.find_children("*", "MeshInstance3D", true, false):
			var nom := String(g.name)
			var pn := String(g.get_parent().name) if g.get_parent() != null else ""
			if nom.begins_with("Eye") or nom.begins_with("Pestana") or nom.begins_with("Pelo") or pn == "PeloCapas":
				(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				nf += 1
		print("SIN_SOMBRA_FINOS: %d piezas sin sombra" % nf)
