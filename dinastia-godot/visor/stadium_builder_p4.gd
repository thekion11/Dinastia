extends "res://visor/stadium_builder_p4_p1.gd"
## (Parte 2 de 2 de `stadium_builder_p4.gd`.)

# ------------------------------------------------------------------ estadio

## El material del techo, por tipo -"membrana"/"retractil" son lona tensada
## de verdad (`Texturas.tela()`, mas clara y sin metal), el resto es la
## cubierta metalica estructural de siempre (`Texturas.metal()`, oscura).
## Ambas funciones cachean por color, asi que llamarla dos veces con el mismo
## `tipo` devuelve el mismo material -barato, y consistente con como ya
## comparten material las 4 tribunas cuando ninguna pide un techo distinto.
static func _techo_mat(tipo: String, col: String = "") -> StandardMaterial3D:
	if tipo == "membrana" or tipo == "retractil":
		return Texturas.tela(_c(col, "#e0e3d9"), 0.5)
	## LA CUBIERTA CON SU ESTRUCTURA (25-10-2026, ultra pulido): era una losa de
	## metal liso, y desde la cámara de TV (que ve el techo de enfrente POR DEBAJO)
	## y desde fuera se leía como una tabla. Ahora lleva la chapa grecada y la
	## retícula de vigas, proyectadas en el mundo (cada 2 m), así que da igual el
	## tamaño de la losa. Misma malla, mismas llamadas; uno por color, cacheado.
	var clave := "techo|" + col
	if _techos_mat.has(clave):
		return _techos_mat[clave]
	var m: StandardMaterial3D = Texturas.metal(_c(col, "#33383f"), 0.55).duplicate()
	m.albedo_texture = _tex_cubierta()
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.25, 0.25, 0.25)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_techos_mat[clave] = m
	return m

## LA FACHADA (B6.2). Cinco pieles para el mismo muro; el color vacío deja el
## tono propio de cada material.
static func _mat_fachada(tipo: String, col: String) -> StandardMaterial3D:
	match tipo:
		"ladrillo":
			return Texturas.ladrillo(_c(col, "#8a4a2b"))
		"vidrio":
			var v: StandardMaterial3D = Texturas.cristal(true, false).duplicate()
			v.albedo_color = _c(col, "#6f8fa6")
			v.metallic = 0.6
			v.roughness = 0.12
			return v
		"membrana":
			return Texturas.tela(_c(col, "#e8e8e2"), 0.6)
		"metal":
			return Texturas.metal(_c(col, "#8a9097"), 0.45)
	return Texturas.hormigon(_c(col, "#6b7079"), 51)
