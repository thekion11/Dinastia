class_name FundirPiezas
extends RefCounted

## R2 (3-11): apagable para las capturas «antes» (`captura_rebajas.tscn` con R2=0).
static var activo_r2 := true
## UNA MALLA POR MATERIAL (31-10-2026, M-476). Los modelos hechos a mano con cajas, cilindros y placas (el autobús, los
## paraderos) eran decenas de `MeshInstance3D` sueltas: una llamada de dibujo cada una, y `Optimizar.agrupar` no las junta
## porque cuelgan de nodos con script o de un grupo. Como no se mueven entre sí, se funden en una `ArrayMesh` con una
## superficie por (material, sombra): los MISMOS materiales (quien los cambie después, como las luces, sigue funcionando).
## Solo los hijos directos con `material_override`; rótulos, luces y lo que tenga hijos o nombre propio se quedan.

## Funde los hijos directos de `raiz`. `corte` > 0 pone ese `visibility_range_end` a la malla fundida. Devuelve cuántas
## piezas fundió. `excluir`: nodos que se quedan sueltos (puertas que se deslizan, etc.).
static func fundir(raiz: Node3D, corte := 0.0, nombre := "Fundido", excluir: Array = []) -> int:
	var por_clave := {}
	var orden: Array = []
	var n := 0
	for h in raiz.get_children():
		var mi := h as MeshInstance3D
		if mi == null or mi.mesh == null or mi.material_override == null or mi.get_child_count() > 0 or not mi.visible or excluir.has(mi):
			continue
		var clave := [mi.material_override, mi.cast_shadow]
		if not por_clave.has(clave):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			por_clave[clave] = st
			orden.append(clave)
		for k in mi.mesh.get_surface_count():
			(por_clave[clave] as SurfaceTool).append_from(mi.mesh, k, mi.transform)
		raiz.remove_child(mi)
		mi.free()
		n += 1
	## Una MeshInstance por modo de sombra (la sombra es de la instancia, no de la superficie).
	var por_sombra := {}
	for clave: Array in orden:
		var sombra: int = clave[1]
		if not por_sombra.has(sombra):
			por_sombra[sombra] = ArrayMesh.new()
		var malla: ArrayMesh = por_sombra[sombra]
		(por_clave[clave] as SurfaceTool).commit(malla)
		malla.surface_set_material(malla.get_surface_count() - 1, clave[0])
	for sombra: int in por_sombra:
		var mi := MeshInstance3D.new()
		mi.name = nombre
		mi.mesh = por_sombra[sombra]
		mi.cast_shadow = sombra
		if corte > 0.0:
			mi.visibility_range_end = corte
			mi.visibility_range_end_margin = corte * 0.1
		raiz.add_child(mi)
	return n

## Como `fundir`, pero con TODAS las mallas de los descendientes (no solo los hijos directos): para recintos hechos de nodos anidados
## (el túnel de vestuarios: taquillas, bancos, duchas). Cada malla se funde con su transformación acumulada hasta `raiz`; solo las que
## llevan `material_override`, no tienen hijos, son visibles y no están en `excluir`. Los nodos que quedan vacíos no se tocan.
static func fundir_profundo(raiz: Node3D, nombre := "FundidoProfundo", excluir: Array = [], por_firma := false) -> int:
	## Por superficie: (material activo, sombra). Sin `material_override` vale el de cada superficie de la malla.
	## `por_firma`: materiales distintos pero IGUALES en lo que se ve (mismos colores, brillo, textura) comparten superficie: una llamada de dibujo
	## en vez de una por instancia (el primero de cada firma es el que queda). Solo para piezas cuyos materiales nadie cambia después por separado.
	var por_clave := {}
	var orden: Array = []
	var rep := {}   ## firma -> el material que queda
	var n := 0
	for mi: MeshInstance3D in raiz.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.get_child_count() > 0 or not mi.visible or excluir.has(mi) or mi.name == nombre or mi.skin != null or mi.layers != 1:
			continue
		var xf := mi.transform
		var p := mi.get_parent()
		var ok := true
		while p != raiz and p != null:
			## Solo nodos 3D simples: un esqueleto, un hueso o un nodo con script/animación se mueven y no se funden.
			if p.get_class() != "Node3D" or not (p as Node3D).visible or p.get_script() != null:
				ok = false
				break
			xf = (p as Node3D).transform * xf
			p = p.get_parent()
		if not ok or p == null:
			continue
		var mats: Array = []
		for k in mi.mesh.get_surface_count():
			var mat: Material = mi.material_override if mi.material_override != null else mi.get_active_material(k)
			if mat == null:
				ok = false
				break
			mats.append(mat)
		if not ok:
			continue
		for k in mi.mesh.get_surface_count():
			var mat_k: Material = mats[k]
			if por_firma:
				var fm := _firma_material(mat_k)
				if not rep.has(fm):
					rep[fm] = mat_k
				mat_k = rep[fm]
			var clave := [mat_k, mi.cast_shadow]
			if not por_clave.has(clave):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				por_clave[clave] = st
				orden.append(clave)
			(por_clave[clave] as SurfaceTool).append_from(mi.mesh, k, xf)
		mi.get_parent().remove_child(mi)
		mi.free()
		n += 1
	var por_sombra := {}
	for clave: Array in orden:
		var sombra: int = clave[1]
		if not por_sombra.has(sombra):
			por_sombra[sombra] = ArrayMesh.new()
		var malla: ArrayMesh = por_sombra[sombra]
		(por_clave[clave] as SurfaceTool).commit(malla)
		malla.surface_set_material(malla.get_surface_count() - 1, clave[0])
	for sombra: int in por_sombra:
		var m := MeshInstance3D.new()
		m.name = nombre
		m.mesh = por_sombra[sombra]
		m.cast_shadow = sombra
		raiz.add_child(m)
	return n

## R2 (3-11, MÍNIMO): las piezas SUELTAS del estadio. Cajas, cilindros y placas que el constructor deja como hijos directos de la raíz sin nombre
## propio (`@MeshInstance3D@N`: cercos, mástiles, soportes, marcas): ~130 llamadas de dibujo con solo ~27 materiales entre todas. Se funden en una
## superficie por (material, sombra). Solo las primitivas de pocos triángulos con `StandardMaterial3D`, sin nombre elegido (nadie las busca), sin
## grupo, meta, script ni corte por distancia, visibles y en la capa 1. Devuelve cuántas piezas fundió.
static func fundir_sueltas(raiz: Node3D, nombre := "SueltasFundidas") -> int:
	var elegidas: Array = []
	for h in raiz.get_children():
		var mi := h as MeshInstance3D
		if mi == null or not String(mi.name).begins_with("@") or mi.mesh == null or mi.get_child_count() > 0 or not mi.visible:
			continue
		if not (mi.mesh is BoxMesh or mi.mesh is CylinderMesh or mi.mesh is PlaneMesh or mi.mesh is QuadMesh):
			continue
		if mi.get_script() != null or not mi.get_groups().is_empty() or not mi.get_meta_list().is_empty() or mi.layers != 1 or mi.visibility_range_end > 0.0 or mi.skin != null:
			continue
		if mi.mesh.get_surface_count() != 1 or mi.mesh.get_faces().size() / 3 > 200:
			continue
		var mat: Material = mi.material_override if mi.material_override != null else mi.get_active_material(0)
		if not (mat is StandardMaterial3D):
			continue
		elegidas.append(mi)
	if elegidas.size() < 2:
		return 0
	var por_clave := {}
	var orden: Array = []
	for mi: MeshInstance3D in elegidas:
		var mat: Material = mi.material_override if mi.material_override != null else mi.get_active_material(0)
		var clave := [mat, mi.cast_shadow]
		if not por_clave.has(clave):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			por_clave[clave] = st
			orden.append(clave)
		(por_clave[clave] as SurfaceTool).append_from(mi.mesh, 0, mi.transform)
		raiz.remove_child(mi)
		mi.free()
	var por_sombra := {}
	for clave: Array in orden:
		var sombra: int = clave[1]
		if not por_sombra.has(sombra):
			por_sombra[sombra] = ArrayMesh.new()
		var malla: ArrayMesh = por_sombra[sombra]
		(por_clave[clave] as SurfaceTool).commit(malla)
		malla.surface_set_material(malla.get_surface_count() - 1, clave[0])
	for sombra: int in por_sombra:
		var m := MeshInstance3D.new()
		m.name = nombre
		m.mesh = por_sombra[sombra]
		m.cast_shadow = sombra
		raiz.add_child(m)
	return elegidas.size()

## R2 (3-11, MÍNIMO): los MultiMesh PEQUEÑOS de la grada (pasillos, barandillas, cantos, zancas, vomitorios: instancias de 12 triángulos) llegan en un
## nodo por tribuna y por tramo: ~90 llamadas de dibujo para ~12 tipos distintos. Se unen en un MultiMesh por (nombre, malla, material, sombra, color por
## instancia) y por sector (`sectores` × `sectores` cuadrantes del campo, para que la cámara siga descartando lo que no mira). Conservan el nombre
## (el recorrido del club busca «Pasillos»). Las butacas y los hinchas NO se tocan (`OptimizarGrada` ya los parte por trozos). Sin pantalla los MultiMesh no
## guardan sus datos y no se hace nada. Devuelve cuántos nodos quitó.
static func unir_multimesh(raiz: Node3D, nombres: Array, sectores := 2) -> int:
	if DisplayServer.get_name() == "headless" or not raiz.is_inside_tree():
		return 0
	var grupos := {}
	var muestra := {}
	var orden: Array = []
	var inv := raiz.global_transform.affine_inverse()
	for n in raiz.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		var mm := mmi.multimesh
		var base := String(mmi.name).rstrip("0123456789")
		if mm == null or mm.mesh == null or not nombres.has(base) or not mmi.visible or mmi.layers != 1 or mmi.visibility_range_end > 0.0:
			continue
		if mm.transform_format != MultiMesh.TRANSFORM_3D or mm.use_custom_data or mm.instance_count == 0 or not mmi.is_inside_tree():
			continue
		var c := (inv * mmi.global_transform).origin
		## Sector = la tribuna a la que pertenece (los cuatro lados del campo), por el eje en que más lejos está del centro.
		var sector := Vector2i.ZERO
		if sectores > 1:
			sector = Vector2i(1 if c.x >= 0.0 else -1, 0) if absf(c.x) >= absf(c.z) else Vector2i(0, 1 if c.z >= 0.0 else -1)
		var clave := [base, _firma_malla(mm.mesh) + ("" if mmi.material_override != null else str(mm.mesh.get_instance_id())), _firma_material(mmi.material_override), mmi.cast_shadow, mm.use_colors, sector]
		if not grupos.has(clave):
			## (la primera malla y el primer material del grupo se usan para todos: son iguales en lo que se ve)
			muestra[clave] = [mm.mesh, mmi.material_override]
		if not grupos.has(clave):
			grupos[clave] = []
			orden.append(clave)
		grupos[clave].append(mmi)
	var quitados := 0
	for clave: Array in orden:
		var lista: Array = grupos[clave]
		if lista.size() < 2:
			continue
		var total := 0
		for mmi: MultiMeshInstance3D in lista:
			total += mmi.multimesh.instance_count
		var nuevo := MultiMesh.new()
		nuevo.transform_format = MultiMesh.TRANSFORM_3D
		nuevo.use_colors = clave[4]
		nuevo.mesh = muestra[clave][0]
		nuevo.instance_count = total
		var k := 0
		for mmi: MultiMeshInstance3D in lista:
			var mm := mmi.multimesh
			var rel := inv * mmi.global_transform
			for i in mm.instance_count:
				nuevo.set_instance_transform(k, rel * mm.get_instance_transform(i))
				if nuevo.use_colors:
					nuevo.set_instance_color(k, mm.get_instance_color(i))
				k += 1
			mmi.get_parent().remove_child(mmi)
			mmi.free()
			quitados += 1
		var m := MultiMeshInstance3D.new()
		m.name = String(clave[0])
		m.multimesh = nuevo
		m.material_override = muestra[clave][1]
		m.cast_shadow = clave[3]
		raiz.add_child(m)
	return quitados

## Dos mallas / materiales hechos aparte pero iguales (cada tribuna crea los suyos) tienen la misma firma.
static func _firma_malla(m: Mesh) -> String:
	return "%s|%d|%s" % [m.get_class(), m.get_faces().size(), var_to_str(snappedf(m.get_aabb().size.length(), 0.001))]

static func _firma_material(m: Material) -> String:
	if m == null:
		return "-"
	var sm := m as StandardMaterial3D
	if sm == null:
		return str(m.get_instance_id())
	return var_to_str([sm.albedo_color, sm.roughness, sm.metallic, sm.emission_enabled, sm.emission, sm.emission_energy_multiplier, sm.transparency, sm.cull_mode, sm.shading_mode,
		sm.vertex_color_use_as_albedo, sm.albedo_texture.get_instance_id() if sm.albedo_texture != null else 0, sm.uv1_scale, sm.uv1_offset, sm.uv1_triplanar,
		sm.normal_enabled, sm.normal_texture.get_instance_id() if sm.normal_texture != null else 0, sm.normal_scale,
		sm.roughness_texture.get_instance_id() if sm.roughness_texture != null else 0, sm.metallic_texture.get_instance_id() if sm.metallic_texture != null else 0,
		sm.emission_texture.get_instance_id() if sm.emission_texture != null else 0, sm.texture_filter, sm.depth_draw_mode, sm.alpha_scissor_threshold, sm.metallic_specular,
		sm.rim_enabled, sm.clearcoat_enabled, sm.refraction_enabled, sm.billboard_mode, sm.no_depth_test, sm.disable_receive_shadows, sm.blend_mode])

## (7-11, metas de RAM y de llamadas de dibujo) LA CIUDAD ENTERA: como `fundir_sueltas`, pero con todas las primitivas sin nombre elegido (`@MeshInstance3D@N`) de cualquier nodo de `raiz`
## (la ciudad tenía ~1.400 cajas, cilindros y placas con material propio: una llamada y ~5 KB de RAM cada una). Se juntan por (material, sombra, alcance de dibujo, capa, GI) y por celda de
## `celda` m, para que la cámara siga descartando lo lejano; la malla fundida lleva los vértices en el espacio de `raiz`. Solo piezas quietas (`Optimizar._sin_dinamica`: sin script ni grupo en
## ella ni en sus padres), sin hijos ni meta, visibles, de pocos triángulos, con `StandardMaterial3D` opaco y sin escala desigual (las normales no se deforman). Devuelve cuántas fundió.
static func fundir_ciudad(raiz: Node3D, celda := 80.0, nombre := "FundidoCiudad") -> int:
	var inv := raiz.global_transform.affine_inverse()
	var cubos := {}   ## clave → {"st": SurfaceTool, "mi": plantilla, "n": cuántas}
	var elegidas: Array = []
	for n in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not String(mi.name).begins_with("@") or mi.get_child_count() > 0 or not mi.is_visible_in_tree() or mi.skin != null:
			continue
		if not (mi.mesh is BoxMesh or mi.mesh is CylinderMesh or mi.mesh is PlaneMesh or mi.mesh is QuadMesh or mi.mesh is SphereMesh):
			continue
		if mi.layers != 1 or not mi.get_meta_list().is_empty() or mi.mesh.get_surface_count() != 1 or mi.mesh.get_faces().size() / 3 > 200:
			continue
		if not Optimizar._sin_dinamica(mi, raiz):
			continue
		var mat := (mi.material_override if mi.material_override != null else mi.get_active_material(0)) as StandardMaterial3D
		if mat == null or mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or mi.material_overlay != null:
			continue
		var b := mi.global_transform.basis
		if absf(b.x.length() - b.y.length()) > 0.001 or absf(b.x.length() - b.z.length()) > 0.001 or absf(b.x.dot(b.y)) > 0.001:
			continue   ## escala desigual o torcida: las normales no saldrían igual
		var c := mi.global_transform.origin
		var clave := [mat, mi.cast_shadow, mi.visibility_range_end, mi.visibility_range_end_margin, mi.gi_mode, Vector2i(floori(c.x / celda), floori(c.z / celda))]
		if not cubos.has(clave):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			cubos[clave] = {"st": st, "mi": mi, "n": 0}
		(cubos[clave]["st"] as SurfaceTool).append_from(mi.mesh, 0, inv * mi.global_transform)
		cubos[clave]["n"] = int(cubos[clave]["n"]) + 1
		elegidas.append([mi, clave])
	var vaciados := {}
	var fundidas := 0
	for par: Array in elegidas:
		var mi: MeshInstance3D = par[0]
		if int(cubos[par[1]]["n"]) < 2:
			continue   ## sola en su celda: se queda como estaba
		var pa := mi.get_parent()
		pa.remove_child(mi)
		mi.free()
		vaciados[pa] = true
		fundidas += 1
	for clave: Array in cubos:
		var cubo: Dictionary = cubos[clave]
		if int(cubo["n"]) < 2:
			continue
		var m := MeshInstance3D.new()
		m.name = nombre
		m.mesh = (cubo["st"] as SurfaceTool).commit()
		m.mesh.surface_set_material(0, clave[0])
		m.cast_shadow = clave[1]
		m.visibility_range_end = clave[2]
		m.visibility_range_end_margin = clave[3]
		m.gi_mode = clave[4]
		raiz.add_child(m, true)   ## (sin transformación propia: los vértices ya están en el espacio de `raiz`)
	PodaVacios.de(raiz, vaciados.keys())
	return fundidas
