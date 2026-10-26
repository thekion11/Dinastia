extends BaseIdea
## OPCIÓN A (26-10-2026): el DT con el modelo actual se ve como una persona: de pie con las
## piernas cerradas (no en guardia), vivo en reposo, con la edad visible y forma de cara/cejas.

func _probar() -> void:
	_titulo("OPCIÓN A: EL DT COMO UNA PERSONA")
	var raiz := Node3D.new()
	add_child(raiz)
	for cuerpo: String in ["male", "female"]:
		var d := PersonajeDT.crear(raiz, {"cuerpo": cuerpo, "edad": 64})
		var ap: AnimationPlayer = d["anim"]
		var esq: Skeleton3D = d["esqueleto"]
		_comprobar(ap.current_animation == "persona/parado", "%s: reposo «persona/parado»" % cuerpo)
		ap.seek(0.6, true)
		var pie_l := esq.get_bone_global_pose(esq.find_bone("foot_l")).origin
		var pie_r := esq.get_bone_global_pose(esq.find_bone("foot_r")).origin
		var rod_l := esq.get_bone_global_pose(esq.find_bone("calf_l")).origin
		var rod_r := esq.get_bone_global_pose(esq.find_bone("calf_r")).origin
		var pelvis := esq.get_bone_global_pose(esq.find_bone("pelvis")).origin
		var rest_pelvis := esq.get_bone_global_rest(esq.find_bone("pelvis")).origin
		var cab := esq.get_bone_global_pose(esq.find_bone("Head")).origin
		## Antes (guardia): 45 cm entre pies y uno 46 cm por delante del otro.
		_comprobar(absf(pie_l.x - pie_r.x) < 0.24 and absf(pie_l.x - pie_r.x) > 0.1, "%s: pies a la anchura de la cadera (%.2f m)" % [cuerpo, absf(pie_l.x - pie_r.x)])
		_comprobar(absf(pie_l.z - pie_r.z) < 0.03, "%s: ningún pie adelantado (%.3f m)" % [cuerpo, absf(pie_l.z - pie_r.z)])
		_comprobar(absf(rod_l.x - rod_r.x) < 0.3, "%s: rodillas juntas (%.2f m)" % [cuerpo, absf(rod_l.x - rod_r.x)])
		_comprobar(absf(pelvis.y - rest_pelvis.y) < 0.01, "%s: rodillas rectas (cadera a su altura)" % cuerpo)
		_comprobar(cab.y > pelvis.y + 0.6 and absf(cab.z - pelvis.z) < 0.15, "%s: la cabeza sobre la cadera, sin inclinarse" % cuerpo)
		_comprobar((d["nodo"] as Node).get_node_or_null("Vida") != null, "%s: respira y se balancea (nodo Vida)" % cuerpo)
		## Canas: el pelo pasa al shader de canas con la cantidad de su edad.
		var con_canas := 0
		var anc := esq.get_node_or_null("Pelo")
		if anc != null:
			for mi: MeshInstance3D in anc.find_children("*", "MeshInstance3D", false, false):
				if mi.material_override is ShaderMaterial and float((mi.material_override as ShaderMaterial).get_shader_parameter("canas")) > 0.3:
					con_canas += 1
		_comprobar(con_canas > 0, "%s: 64 años, canas en el pelo (%d mallas)" % [cuerpo, con_canas])
		(d["nodo"] as Node).free()
	## Joven: nada de canas ni arrugas.
	var j := PersonajeDT.crear(raiz, {"edad": 28})
	var hay := false
	for mi: MeshInstance3D in (j["nodo"] as Node).find_children("*", "MeshInstance3D", true, false):
		if mi.material_overlay != null or mi.material_override is ShaderMaterial and (mi.material_override as ShaderMaterial).shader.resource_path == PersonajeVida.SHADER_CANAS:
			hay = true
	_comprobar(not hay, "28 años: sin arrugas ni canas")
	_comprobar(PersonajeVida.arrugas_de(30) == 0.0 and PersonajeVida.arrugas_de(65) > 0.95, "arrugas: nada a los 30, del todo a los 65")
	_comprobar(PersonajeVida.canas_de(70) <= 0.85 and PersonajeVida.entradas_de(30) == 0.0, "canas con tope; sin entradas a los 30")
	(j["nodo"] as Node).free()
	## Forma de cara: el hueso «Head» se ensancha o se alarga.
	var ancha := PersonajeDT._objetivos(PersonajeDT.aspecto({"forma_cara": 1.0, "ropa": "traje"}))["Head"] as Vector3
	var larga := PersonajeDT._objetivos(PersonajeDT.aspecto({"forma_cara": -1.0, "ropa": "traje"}))["Head"] as Vector3
	_comprobar(ancha.x > larga.x and ancha.y < larga.y, "forma de cara: ancha más ancha y menos alta que alargada")
	## La edad de Datos viaja en el aspecto al cerrar el personaje (la banda la ve).
	var p := PersonajeDatos.nuevo()
	p["edad"] = 61
	_comprobar(int((PersonajeDatos.cerrar(p)["aspecto"] as Dictionary)["edad"]) == 61, "la edad va en el aspecto guardado")
