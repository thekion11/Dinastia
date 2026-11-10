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
	if OS.get_environment("LODS_RUNTIME") != "":
		## LODS_RUNTIME=1: a las mallas que se construyen en tiempo de ejecución y NO tienen LODs (pelo por capas `Cuero*`, peinados del pack, cara real) se les generan LODs con `ImporterMesh.generate_lods`
		## (el mismo simplificador que el importador) y se sustituyen; el motor elige el LOD por distancia (`mesh_lod_threshold` del viewport).
		var n_l := 0
		var antes_t := 0
		var despues_t := 0
		var hechas := {}
		for g in vista.find_children("*", "MeshInstance3D", true, false):
			var mi := g as MeshInstance3D
			var nom := String(mi.name).rstrip("0123456789@_")
			var solo := OS.get_environment("LODS_SOLO")
			if solo != "" and not nom.begins_with(solo):
				continue
			if not (nom.begins_with("Cuero") or nom.begins_with("Hair") or nom.begins_with("PeloDrive") or nom.begins_with("CaraReal") or nom.begins_with("Pelo")):
				continue
			var m := mi.mesh as ArrayMesh
			if m == null or m.get_surface_count() == 0:
				continue
			if hechas.has(m):
				mi.mesh = hechas[m]
				continue
			var im := ImporterMesh.new()
			for sf in m.get_surface_count():
				var arr := m.surface_get_arrays(sf)
				antes_t += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if arr[Mesh.ARRAY_INDEX] != null else 0
				im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, m.surface_get_material(sf), "s%d" % sf, m.surface_get_format(sf) & (((1 << 12) - 1) << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT))
			im.generate_lods(25.0, 60.0, [])
			var nuevo := im.get_mesh()
			hechas[m] = nuevo
			mi.mesh = nuevo
			n_l += 1
		print("LODS_RUNTIME: %d mallas con LODs nuevos (%d triángulos base)" % [n_l, antes_t])
	if OS.get_environment("IMPOSTOR") != "":
		## IMPOSTOR=<metros> (p. ej. 30): TECHO de lo que ahorraría un impostor de cuerpo: los jugadores del campo a más de esa distancia de la cámara pierden todas sus mallas (cuerpo, cara, pelo) y se dibujan como una
		## cápsula de ~60 triángulos del color de la camiseta (sin animación). No es el impostor final (no conserva la animación ni los detalles): solo mide el máximo ahorro posible de llamadas y triángulos.
		var cam_i := vista.get_viewport().get_camera_3d()
		var lejos := float(OS.get_environment("IMPOSTOR"))
		var n_i := 0
		var cap := CapsuleMesh.new()
		cap.radius = 0.3
		cap.height = 1.75
		cap.radial_segments = 6
		cap.rings = 1
		for f: Dictionary in vista.get("_en_campo"):
			var nodo_i: Node = f.get("node")
			if nodo_i == null or cam_i == null or (nodo_i as Node3D).global_position.distance_to(cam_i.global_position) < lejos:
				continue
			for m in nodo_i.find_children("*", "MeshInstance3D", true, false):
				(m as MeshInstance3D).visible = false
			var imp := MeshInstance3D.new()
			imp.mesh = cap
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.85, 0.25, 0.2) if n_i % 2 == 0 else Color(0.2, 0.35, 0.85)
			imp.material_override = mat
			imp.position = Vector3(0, 0.9, 0)
			nodo_i.add_child(imp)
			n_i += 1
		print("IMPOSTOR: %d jugadores a más de %.0f m sustituidos por una cápsula" % [n_i, lejos])
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

## EFECTO=glow|niebla|ajuste|ssao|ssr|tonemap|debanding|fxaa|brillo|cielo (uno solo; varios separados por coma): apaga ESE efecto de la cadena de MEDIA y nada más, para la tabla por efecto de `rendimiento_movil_2026-11-10.md`.
## DIAG_ENTORNO=1 escribe qué trae el Environment y el viewport.
static func efecto(vista: Node) -> void:
	var lista := OS.get_environment("EFECTO").split(",", false)
	var vp: Viewport = vista.get_viewport()
	for we in vista.find_children("*", "WorldEnvironment", true, false):
		var en: Environment = (we as WorldEnvironment).environment
		if en == null:
			continue
		if OS.get_environment("DIAG_ENTORNO") != "":
			print("ENTORNO %s: glow=%s niebla=%s ajuste=%s ssao=%s ssr=%s tonemap=%d fondo=%d ambiente=%d | vp msaa=%d fxaa=%d debanding=%s escala=%.2f" % [
				we.name, en.glow_enabled, en.fog_enabled, en.adjustment_enabled, en.ssao_enabled, en.ssr_enabled, en.tonemap_mode, en.background_mode, en.ambient_light_source,
				vp.msaa_3d, vp.screen_space_aa, vp.use_debanding, vp.scaling_3d_scale])
		for e in lista:
			match e:
				"glow": en.glow_enabled = false
				"niebla": en.fog_enabled = false
				"ajuste": en.adjustment_enabled = false
				"ssao": en.ssao_enabled = false
				"ssr": en.ssr_enabled = false
				"tonemap": en.tonemap_mode = Environment.TONE_MAPPER_LINEAR
				"cielo": en.background_mode = Environment.BG_COLOR
	for e in lista:
		match e:
			"debanding": vp.use_debanding = false
			"fxaa": vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
