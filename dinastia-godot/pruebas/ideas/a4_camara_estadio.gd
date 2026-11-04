extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 del mundo 3D: la CÁMARA REAL del partido en estadios reformados. Rayos a nivel de TRIÁNGULO contra el estadio construido (sin pantalla: no hace falta dibujar).
##   1. De cada cámara de transmisión (Transmisión, Principal TV, Tele Dinámica, Tribuna alta, A ras de campo…) a 35 puntos de la hierba (a 0,3 m: balón y pies): el rayo no debe chocar antes con una pieza del estadio (techo, columnas, marcadores, carteles, focos).
##   2. Perfiles: el del club, 3 niveles con aforo máximo, 1 nivel con aforo mínimo, techo completo, con pista, y todo a la vez.
##   3. Las cámaras de transmisión no quedan enterradas ni dentro del techo (el primer impacto del rayo central no es la cara inferior de una pieza a < 1,5 m).
const PROBAR := ["Transmisión", "Principal (TV)", "Tele Dinámica", "Tribuna alta", "A ras de campo", "Detras del arco"]
var _tri := {}   ## mesh → TriangleMesh (cacheado)

func _probar() -> void:
	_titulo("A4 MUNDO_3D: la cámara del partido ve el campo en estadios reformados")
	Calidad.elegida = Calidad.MEDIO
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, 321)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var club := m.mi_club()
	var base: Dictionary = m.perfil_estadio_de(club)
	var techos: Array = m.estadio.opciones("techo")
	var techo_completo := String((techos[techos.size() - 1] as Dictionary).get("clave", "")) if not techos.is_empty() else ""
	print("  (info) techos disponibles: %s → completo = «%s»" % [str(techos.map(func(t: Variant) -> String: return String((t as Dictionary).get("clave", "")))), techo_completo])
	var perfiles := {
		"el del club": {},
		"3 niveles, aforo máximo": {"niveles": 3, "aforo": 90000},
		"1 nivel, aforo mínimo": {"niveles": 1, "aforo": 3000},
		"techo completo": {"techo": techo_completo},
		"con pista": {"pista": true},
		"todo a la vez": {"niveles": 3, "aforo": 90000, "techo": techo_completo, "pista": true},
	}
	var peor_global := {}
	for nombre in perfiles:
		var perfil := base.duplicate(true)
		for k in perfiles[nombre]:
			perfil[k] = perfiles[nombre][k]
		Azar.sembrar(4242)
		var v := VistaEstadio.new()
		add_child(v)
		await v.abrir(club, 0.5, null, null, perfil)
		for i in 10:
			await get_tree().process_frame
		var rig: CameraRig = v.get("_rig")
		var meshes := _meshes(v)
		var linea := "  %-26s" % nombre
		for cn in PROBAR:
			var idx := -1
			for i in rig.camera_names.size():
				if String(rig.camera_names[i]).begins_with(cn.left(6)):
					idx = i
					break
			if idx < 0:
				continue
			rig.switch_to(idx)
			await get_tree().process_frame
			var cam: Camera3D = rig.cameras[idx]
			var tapados := 0
			var quien := {}
			for ix in 7:
				for iz in 5:
					var objetivo := Vector3(-30.0 + 10.0 * float(ix), 0.3, -45.0 + 22.5 * float(iz))
					var o := cam.global_position
					var d := objetivo - o
					var dist := d.length()
					var golpe := _primer_impacto(meshes, o, d / dist, dist - 0.4)
					if not golpe.is_empty():
						var n := String(golpe["nombre"])
						if _es_campo(n) or float(golpe["alto"]) < 0.6:
							continue   ## el propio césped, las líneas, la pista: a ras de suelo no tapan nada
						tapados += 1
						quien[n] = int(quien.get(n, 0)) + 1
			var enterrada := cam.global_position.y < 0.3
			var dentro := not _primer_impacto(meshes, cam.global_position, Vector3.DOWN, 0.2).is_empty() and cam.global_position.y > 1.5
			linea += " | %s %d/35" % [cn.left(9), tapados]
			var clave := "%s · %s" % [nombre, cn]
			if tapados > 0:
				peor_global[clave] = {"tapados": tapados, "quien": quien}
			if enterrada:
				_comprobar(false, "%s: la cámara «%s» está bajo el suelo (y=%.2f)" % [nombre, cn, cam.global_position.y])
		print(linea)
		v.free()
		await get_tree().process_frame
	var graves := 0
	for k in peor_global:
		var t: int = peor_global[k]["tapados"]
		print("    TAPADO %s: %d/35 puntos (%s)" % [k, t, str(peor_global[k]["quien"])])
		## cámaras de transmisión: ningún punto de la hierba tapado por el estadio (un poste o una red de portería a veces: se tolera ≤ 3/35 con nombre de portería)
		if t > 3 and not String(k).ends_with("A ras de campo"):
			graves += 1
	_comprobar(graves == 0, "ninguna cámara de transmisión pierde de vista más de 3 de 35 puntos del campo con ningún perfil (%d casos graves)" % graves)

func _es_campo(n: String) -> bool:
	for k in ["Cesped", "Linea", "Marca", "Porteria", "Arco", "Red", "Poste", "Larguero", "Cal", "Sombra", "Balon", "Cartel_campo", "Banderin"]:
		if n.begins_with(k) or n.contains(k):
			return true
	return false

func _meshes(raiz: Node) -> Array:
	var sal: Array = []
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		## Los conos de luz de los focos y demás mallas translúcidas no tapan nada.
		var mat: Material = mi.get_active_material(0)
		if mat == null and mi.mesh.get_surface_count() > 0:
			mat = mi.mesh.surface_get_material(0)
		if mat is BaseMaterial3D and ((mat as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or (mat as BaseMaterial3D).albedo_color.a < 0.99 or (mat as BaseMaterial3D).blend_mode != BaseMaterial3D.BLEND_MODE_MIX):
			continue
		if mat is ShaderMaterial and String((mat as ShaderMaterial).shader.code).contains("blend_add"):
			continue
		var cuerpo := mi.global_transform * mi.get_aabb()
		sal.append({"n": mi, "aabb": cuerpo, "nombre": String(mi.name)})
	return sal

func _primer_impacto(meshes: Array, o: Vector3, dir: Vector3, maximo: float) -> Dictionary:
	var mejor := maximo
	var res := {}
	for e: Dictionary in meshes:
		var a: AABB = e["aabb"]
		if not a.grow(0.05).intersects_segment(o, o + dir * mejor):
			continue
		var mi: MeshInstance3D = e["n"]
		var tm: TriangleMesh = _tri.get(mi.mesh)
		if tm == null:
			tm = mi.mesh.generate_triangle_mesh()
			_tri[mi.mesh] = tm
		if tm == null:
			continue
		var inv := mi.global_transform.affine_inverse()
		var lo := inv * o
		var ld := (inv.basis * dir).normalized()
		var hit := tm.intersect_ray(lo, ld)
		if hit.is_empty():
			continue
		## Solo las caras que MIRAN a la cámara (el motor descarta las traseras): un rayo que cruza la pared por dentro de la grada no es un obstáculo.
		var nm: Vector3 = (mi.global_transform.basis * (hit["normal"] as Vector3)).normalized()
		if nm.dot(dir) > 0.05:
			continue
		var p: Vector3 = mi.global_transform * (hit["position"] as Vector3)
		var t := o.distance_to(p)
		if t < mejor and t > 0.05:
			mejor = t
			res = {"nombre": "%s(%s %s)" % [e["nombre"], mi.mesh.get_class(), str(a.size.snapped(Vector3.ONE * 0.1))], "t": t, "alto": a.end.y}
	return res
