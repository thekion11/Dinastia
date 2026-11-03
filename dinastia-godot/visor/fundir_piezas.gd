class_name FundirPiezas
extends RefCounted
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
static func fundir_profundo(raiz: Node3D, nombre := "FundidoProfundo", excluir: Array = []) -> int:
	## Por superficie: (material activo, sombra). Sin `material_override` vale el de cada superficie de la malla.
	var por_clave := {}
	var orden: Array = []
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
			var clave := [mats[k], mi.cast_shadow]
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
