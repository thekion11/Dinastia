extends BaseIdea
## SESIÓN 6 · AUDITORÍA VISUAL (26-10-2026). Desde el mapa, a más de 520 m, el
## estadio salía como un bloque BLANCO: el LOD jerárquico de `Optimizar.agrupar`
## le ponía caja «de color medio» a las mallas que SOLO proyectan sombra
## (`StadiumBuilder._sombra_unica`, material por defecto = blanco) y cortaba las
## gradas. Ahora ni las de solo sombra ni lo que cuelga de `sin_corte` llevan LOD;
## un edificio pesado normal sigue con su caja lejana.

func _malla_pesada() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 1700:
		var x := float(i % 40)
		var z := float(i / 40)
		st.add_vertex(Vector3(x, 0, z))
		st.add_vertex(Vector3(x + 1, 5, z))
		st.add_vertex(Vector3(x, 5, z + 1))
	return st.commit()

func _mi(padre: Node3D, nombre: String, sombra: GeometryInstance3D.ShadowCastingSetting) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nombre
	mi.mesh = _malla_pesada()
	mi.cast_shadow = sombra
	padre.add_child(mi)
	return mi

func _probar() -> void:
	_titulo("S6: AUDITORÍA · el estadio no se vuelve un bloque blanco de lejos")
	var raiz := Node3D.new()
	add_child(raiz)
	var estadio := Node3D.new()
	estadio.set_meta("sin_corte", true)
	raiz.add_child(estadio)
	var grada := _mi(estadio, "Grada", GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var sombra := _mi(raiz, "SombraUnica0", GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	var edificio := _mi(raiz, "Edificio", GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	Optimizar.agrupar(raiz)
	var proxies := 0
	for n in raiz.find_children("EdificiosLejos*", "MultiMeshInstance3D", true, false):
		proxies += (n as MultiMeshInstance3D).multimesh.instance_count
	_comprobar(sombra.visibility_range_end == 0.0, "la malla de solo sombra no se corta por distancia")
	_comprobar(grada.visibility_range_end == 0.0, "lo que cuelga de «sin_corte» (el estadio) tampoco")
	_comprobar(edificio.visibility_range_end > 0.0 and proxies == 1, "un edificio pesado normal sigue con su caja lejana (%d caja)" % proxies)
	raiz.queue_free()
