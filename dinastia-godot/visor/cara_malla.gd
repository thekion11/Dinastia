class_name CaraMalla
extends "res://visor/cara_malla_p1.gd"
## (Parte 2 de 2 de `cara_malla.gd`.)

static func _armar(nombre: String, datos: Array, cuerpo: Dictionary) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pos: PackedVector3Array = datos[0]
	var pegada := _pegar_borde(pos, cuerpo)
	var uv: PackedVector2Array = datos[1]
	## COLOR.g = tapado en la foto (una mano, un brazo): ahí se pinta su piel.
	var tapado := PeloCapas._densidades(String(entrada(nombre).get("t", "")), _n)
	## Las normales, de la forma SIN pegar: con el anillo doblado hacia el
	## cráneo, la fila del borde se sombreaba oscura (una línea en la frente).
	var normales := _normales_cara(pos, _tri, _n)
	for i in _n:
		st.set_normal(normales[i])
		st.set_uv(uv[i])
		var alfa := _alfa[i] if i < _alfa.size() else 1.0
		if alfa < 1.0 and i < _lejos.size():
			alfa *= 1.0 - smoothstep(0.006, 0.014, _lejos[i])
		st.set_color(Color(1, tapado[i], 1, alfa))
		st.add_vertex(pegada[i])
	## Godot toma como cara de delante la de vértices en sentido horario vista
	## desde fuera; la malla de MediaPipe viene al revés.
	## Los ojos de la foto NO se pintan: se abre el ojo en la malla y se ven los
	## globos 3D detrás, mirando al frente con el color de su iris. (En fotos
	## de tres cuartos el espejo copiaba el mismo ojo a los dos lados y parecía
	## bizco.) Se quitan los triángulos que tienen los tres puntos en el
	## contorno de un ojo.
	for t in range(0, _tri.size() - 2, 3):
		if _en_ojo(_tri[t]) and _en_ojo(_tri[t + 1]) and _en_ojo(_tri[t + 2]):
			continue
		st.add_index(_tri[t])
		st.add_index(_tri[t + 2])
		st.add_index(_tri[t + 1])
	return st.commit()

static func _vestir_cara(_d: Dictionary, esq: Skeleton3D, hueso: int, nombre: String, tex: Texture2D,
		piel: Color, malla: ArrayMesh) -> MeshInstance3D:
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER)
	mat.set_shader_parameter("foto", tex)
	## Luminancia media de su piel (lineal): la referencia para quitarle a la
	## foto la luz con que se sacó.
	var pl := piel.srgb_to_linear()
	mat.set_shader_parameter("piel_lin", Vector3(pl.r, pl.g, pl.b))
	if String(entrada(nombre).get("a", "")) != "":
		## Piel replicada: la luz y el balance ya vienen quitados del motor.
		mat.set_shader_parameter("quitar_luz", 0.0)
		mat.set_shader_parameter("balance", Vector3.ONE)
	else:
		mat.set_shader_parameter("balance", balance(nombre))
	mat.set_shader_parameter("lum_media", 0.2126 * pl.r + 0.7152 * pl.g + 0.0722 * pl.b)
	var mi := MeshInstance3D.new()
	mi.name = "CaraReal"
	if Calidad.lod_cabeza() < 1.0:   ## (10-11) en calidad baja la cara real solo de cerca; más lejos se ve la cabeza del cuerpo (sin rasgos: menos de un píxel)
		mi.visibility_range_end = 33.0 * Calidad.lod_cabeza()
		mi.visibility_range_end_margin = 3.0
	mi.mesh = malla
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var anc := BoneAttachment3D.new()
	anc.name = "CaraRealHueso"
	anc.bone_name = "Head"
	esq.add_child(anc)
	mi.transform = esq.get_bone_global_rest(hueso).affine_inverse()
	anc.add_child(mi)
	return mi
