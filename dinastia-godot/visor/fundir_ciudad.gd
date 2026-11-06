class_name FundirCiudad
extends RefCounted
## (6-11, meta de llamadas) Las mallas SUELTAS de la ciudad: `Optimizar.agrupar` junta las piezas iguales en MultiMesh, pero deja solas las que son únicas por material y
## celda (cajas, cilindros, esferas, placas con su propio material: ~4.700 grupos de un elemento). Aquí se funden, solo en ULTRA BAJA, en UNA malla por (material, sombra,
## capa, corte por distancia, celda de 160 m): se dibuja lo mismo, pero con una llamada en vez de decenas. Los materiales son los mismos objetos; las piezas con
## script, grupo, hijos, esqueleto o más de `MAX_TRIS` triángulos ya quedaron fuera de `agrupar` o se dejan como están.
const MAX_TRIS := 600

## `grupos`: los de `agrupar` (clave → {malla, mi, lista, t}); `inv`: inversa del transform global de `raiz`. Devuelve los padres que se quedaron sin hijos
## (para `PodaVacios`) y deja en `cuenta` cuántas piezas se fundieron.
static func sueltos(raiz: Node3D, grupos: Dictionary, inv: Transform3D, cuenta: Dictionary) -> Array:
	var por_clave := {}
	for k: String in grupos:
		var g: Dictionary = grupos[k]
		if (g["lista"] as Array).size() != 1:
			continue
		var mi: MeshInstance3D = g["mi"]
		var malla: Mesh = g["malla"]
		var mat: Material = mi.material_override
		if mat == null and malla.get_surface_count() == 1:
			mat = malla.surface_get_material(0)
		if mat == null or Optimizar._tris(malla) > MAX_TRIS:
			continue
		var t: Transform3D = (g["t"] as Array)[0]
		var formato: int = (malla as ArrayMesh).surface_get_format(0) if malla is ArrayMesh else 0   ## las primitivas traen todos los atributos
		var clave := "%d|%d|%d|%d|%s|%d,%d" % [mat.get_instance_id(), mi.cast_shadow, mi.layers, formato, str(mi.visibility_range_end), floori(t.origin.x / Optimizar.CELDA), floori(t.origin.z / Optimizar.CELDA)]
		if not por_clave.has(clave):
			por_clave[clave] = []
		(por_clave[clave] as Array).append(g)
	var vaciados: Array = []
	for clave: String in por_clave:
		var gs: Array = por_clave[clave]
		if gs.size() < 2:
			continue
		var modelo: MeshInstance3D = (gs[0] as Dictionary)["mi"]
		var mat: Material = modelo.material_override if modelo.material_override != null else ((gs[0] as Dictionary)["malla"] as Mesh).surface_get_material(0)
		var sombra: int = modelo.cast_shadow
		var capas: int = modelo.layers
		var corte: float = modelo.visibility_range_end
		var margen: float = modelo.visibility_range_end_margin
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for g: Dictionary in gs:
			var malla: Mesh = g["malla"]
			for s in malla.get_surface_count():
				st.append_from(malla, s, inv * ((g["t"] as Array)[0] as Transform3D))
			var mi: MeshInstance3D = g["mi"]
			var pa := mi.get_parent()
			pa.remove_child(mi)
			mi.free()
			vaciados.append(pa)
		var fundida := ArrayMesh.new()
		st.commit(fundida)
		fundida.surface_set_material(0, mat)
		var nodo := MeshInstance3D.new()
		nodo.name = "Fundido"
		nodo.mesh = fundida
		nodo.cast_shadow = sombra as GeometryInstance3D.ShadowCastingSetting
		nodo.layers = capas
		nodo.visibility_range_end = corte
		nodo.visibility_range_end_margin = margen
		raiz.add_child(nodo)
		cuenta["fundidas"] = int(cuenta.get("fundidas", 0)) + gs.size()
	return vaciados

## Depuración (`DETALLE=1`): qué clase de malla queda sola tras agrupar.
static func informe_solos(grupos: Dictionary) -> void:
	var sol := {}
	for k2: String in grupos:
		if (grupos[k2]["lista"] as Array).size() == 1:
			var mi0: MeshInstance3D = grupos[k2]["mi"]
			var c2 := mi0.mesh.get_class() + (" ovr" if mi0.material_override != null else "") + " " + mi0.mesh.resource_name.left(20)
			sol[c2] = int(sol.get(c2, 0)) + 1
	Registro.depurar("AGRUPAR", "solos %s" % str(sol))
