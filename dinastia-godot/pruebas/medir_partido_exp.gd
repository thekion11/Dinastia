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
	if OS.get_environment("MESH_LOD") != "":
		## MESH_LOD=6 (o 12, 24…): `mesh_lod_threshold` del viewport (píxeles de error admitidos al elegir el LOD de cada malla: más alto = lo lejano baja antes a mallas más simples; el esqueleto y la animación no cambian).
		vista.get_viewport().mesh_lod_threshold = float(OS.get_environment("MESH_LOD"))
		print("MESH_LOD: mesh_lod_threshold = %.1f" % vista.get_viewport().mesh_lod_threshold)
	if OS.get_environment("INFORME_JUGADORES") != "":
		## INFORME_JUGADORES=1: por cada jugador del campo, las piezas visibles que dibuja (nombre, triángulos, rango de visibilidad) y su distancia a la cámara de TV.
		var cam := vista.get_viewport().get_camera_3d()
		var tot_pz := 0
		var tot_tr := 0
		var por_nombre := {}
		var n_j := 0
		for f: Dictionary in vista.get("_en_campo"):
			var nodo: Node = f.get("node")
			if nodo == null:
				continue
			n_j += 1
			var d := (nodo as Node3D).global_position.distance_to(cam.global_position) if cam != null else 0.0
			var piezas := 0
			var tris := 0
			for m in nodo.find_children("*", "MeshInstance3D", true, false):
				var mi := m as MeshInstance3D
				if not mi.is_visible_in_tree() or mi.mesh == null:
					continue
				var rango := mi.visibility_range_end
				if rango > 0.0 and d > rango:
					continue
				piezas += 1
				var tr := Optimizar._tris(mi.mesh)
				tris += tr
				var k := String(mi.name).rstrip("0123456789@")
				if not por_nombre.has(k):
					por_nombre[k] = Vector2.ZERO
				por_nombre[k] += Vector2(1, tr)
			tot_pz += piezas
			tot_tr += tris
			if n_j <= 3:
				print("JUGADOR %d a %.0f m: %d piezas, %d triángulos" % [n_j, d, piezas, tris])
		print("JUGADORES %d en el campo: %d piezas dibujables (%.1f por jugador), %d triángulos (%.0f por jugador, a máxima calidad de malla)" % [n_j, tot_pz, float(tot_pz) / maxf(n_j, 1), tot_tr, float(tot_tr) / maxf(n_j, 1)])
		var ks := por_nombre.keys()
		ks.sort_custom(func(a, b): return por_nombre[a].y > por_nombre[b].y)
		for k in ks:
			print("  PIEZA %-24s x%3d  %7d triángulos" % [k, int(por_nombre[k].x), int(por_nombre[k].y)])
	if OS.get_environment("SIN_SOMBRA_FINOS") != "":
		var nf := 0
		for g in vista.find_children("*", "MeshInstance3D", true, false):
			var nom := String(g.name)
			var pn := String(g.get_parent().name) if g.get_parent() != null else ""
			if nom.begins_with("Eye") or nom.begins_with("Pestana") or nom.begins_with("Pelo") or pn == "PeloCapas":
				(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				nf += 1
		print("SIN_SOMBRA_FINOS: %d piezas sin sombra" % nf)
