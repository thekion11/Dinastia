extends BaseIdea
## HINCHADA Y BANQUILLO ANIMADOS (26-10-2026, fila 6 de la investigación s4):
## mallas VAT horneadas, su textura coherente con la pose base, clips de festejo
## que de verdad levantan los brazos, el material configurado y los clips de
## medio cuerpo del banquillo con la cadera de «sentado».

func _probar() -> void:
	_titulo("HINCHADA ANIMADA (VAT) Y BANQUILLO SENTADO")
	for nivel in ["cerca", "medio", "lejos"]:
		var m := PublicoVat.malla(nivel)
		_comprobar(PublicoVat.es_vat(m), "hay malla VAT «%s»" % nivel)
		if m == null:
			continue
		var tex: Texture2D = m.get_meta("vat_tex")
		var img := tex.get_image()
		var arr := m.surface_get_arrays(0)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var clips: Array = m.get_meta("vat_clips")
		var fotos: int = m.get_meta("vat_fotogramas")
		_comprobar(img.get_width() == vs.size() and img.get_height() == clips.size() * fotos * 2,
			"%s: textura %dx%d = vértices x (clips x fotogramas x 2)" % [nivel, img.get_width(), img.get_height()])
		_comprobar((m.get_meta("vat_duraciones") as Array).size() == 13 and clips.size() == 13, "%s: 13 clips con duración (el shader espera 13)" % nivel)
		var lo: Vector3 = m.get_meta("vat_min")
		var hi: Vector3 = m.get_meta("vat_max")
		## La pose base es el clip 0 a mitad: el fotograma 8 debe coincidir con la malla.
		var peor := 0.0
		for k in vs.size():
			var c := img.get_pixel(k, fotos / 2)
			var p := lo + Vector3(c.r, c.g, c.b) * (hi - lo)
			peor = maxf(peor, p.distance_to(vs[k]))
		_comprobar(peor < 0.03, "%s: la textura reproduce la pose base (error máx %.3f m)" % [nivel, peor])
		## Festejo (clip 7) con las manos más altas que en reposo (clip 0).
		var alto_reposo := -1e9
		var alto_festejo := -1e9
		for f in fotos:
			for k in vs.size():
				alto_reposo = maxf(alto_reposo, lo.y + img.get_pixel(k, f).g * (hi.y - lo.y))
				alto_festejo = maxf(alto_festejo, lo.y + img.get_pixel(k, 7 * fotos + f).g * (hi.y - lo.y))
		## «lejos» (62 vértices) pierde las manos al simplificar: le basta con los antebrazos.
		var sube := 0.12 if nivel == "lejos" else 0.2
		_comprobar(alto_festejo > alto_reposo + sube, "%s: en el festejo los brazos suben (%.2f > %.2f m)" % [nivel, alto_festejo, alto_reposo])
		var mat := ShaderMaterial.new()
		mat.shader = load("res://visor/hinchada.gdshader")
		PublicoVat.configurar(mat, m, "cruzados")
		_comprobar(float(mat.get_shader_parameter("vat_activo")) == 1.0 and int(mat.get_shader_parameter("vat_reposo")) == 5,
			"%s: material con VAT activo y el reposo del grupo" % nivel)
		_comprobar((m as ArrayMesh).custom_aabb.end.y >= alto_festejo - 0.001, "%s: la caja de la malla cubre los brazos en alto" % nivel)
	## Las poses quietas siguen ahí como respaldo.
	_comprobar(ResourceLoader.exists("res://assets/ciudad/publico/hincha_quieto_lejos.res"), "las poses quietas siguen (respaldo)")
	## El banquillo: los clips de medio cuerpo, con la cadera de «sentado».
	var d := FutbolistaQ.crear(1.8, "male")
	add_child(d["nodo"])
	FutbolistaQ.terminar(d)
	var ap: AnimationPlayer = d["anim"]
	_comprobar(BanquilloVivo.preparar(ap), "el banquillo tiene sus clips de medio cuerpo")
	for nombre in BanquilloVivo.CLIPS:
		_comprobar(ap.has_animation(nombre), "clip de banquillo «%s»" % nombre)
	## Ante una lesión de los suyos (M-102): todos los clips de `LESIONES` existen y el que lleva las manos a la cabeza es de medio cuerpo.
	var faltan: Array[String] = []
	for c: String in BanquilloVivo.LESIONES:
		if not ap.has_animation(c):
			faltan.append(c)
	_comprobar(faltan.is_empty() and ap.has_animation("sentado_manos_cabeza"), "los clips de lesión del banquillo existen (faltan: %s)" % ", ".join(faltan))
	var prueba := Node3D.new()
	add_child(prueba)
	_comprobar(BanquilloVivo.reaccionar(prueba, "lesion", true) == 0, "sin banquillo no reacciona nadie (y no falla)")
	prueba.queue_free()
	if ap.has_animation("sentado_festeja"):
		var sentado := ap.get_animation("sentado")
		var fest := ap.get_animation("sentado_festeja")
		var pre := BanquilloVivo.prefijo_de(sentado)
		var ti := fest.find_track(NodePath(pre + ":thigh_l"), Animation.TYPE_ROTATION_3D)
		var ts := sentado.find_track(NodePath(pre + ":thigh_l"), Animation.TYPE_ROTATION_3D)
		_comprobar(ti >= 0 and ts >= 0 and (fest.rotation_track_interpolate(ti, 0.5) as Quaternion).is_equal_approx(sentado.rotation_track_interpolate(ts, 0.0)),
			"el muslo del festejo es el de «sentado» (la cadera no se levanta del banco)")
		var tb := fest.find_track(NodePath(pre + ":upperarm_r"), Animation.TYPE_ROTATION_3D)
		_comprobar(tb >= 0 and fest.track_get_key_count(tb) > 4, "el brazo del festejo viene de Mesh2Motion (con claves)")
	(d["nodo"] as Node).queue_free()
