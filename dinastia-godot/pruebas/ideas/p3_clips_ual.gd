extends BaseIdea
## Auditoría (27-10-2026): TODOS los clips que `AnimExtra.UAL` promete se pueden cargar en un peatón (la «charla» no se cargaba por el sufijo «_Loop»).

func _probar() -> void:
	_titulo("CLIPS DE LA UAL: LOS PEDIDOS Y NO ENCONTRADOS")
	var d := PeatonVida.nuevo(self, 5)
	if d.is_empty():
		_comprobar(true, "(sin modelo de peatón en este entorno)")
		return
	var ap: AnimationPlayer = d["anim"]
	var esq := FutbolistaQ.esqueleto_de(d["nodo"])
	var faltan: Array[String] = []
	var bucles_mal: Array[String] = []
	for clave: String in AnimExtra.UAL.keys():
		if not AnimExtra.asegurar(ap, esq, clave):
			faltan.append("%s (%s)" % [clave, String(AnimExtra.UAL[clave])])
		elif String(AnimExtra.UAL[clave]).ends_with("Loop") and ap.get_animation(clave).loop_mode == Animation.LOOP_NONE:
			bucles_mal.append(clave)
	_comprobar(faltan.is_empty(), "no se encuentran %d de %d clips: %s" % [faltan.size(), AnimExtra.UAL.size(), ", ".join(faltan)])
	_comprobar(bucles_mal.is_empty(), "los «_Loop» se repiten (mal: %s)" % ", ".join(bucles_mal))
	## Los clips de `AnimQuaternius` (CLIP_REAL, CLIP_CAMINATA) y su nombre de pack, tal como los pide `cargar_real`.
	var perdidos: Array[String] = []
	var prefijo := str(ap.get_path_to(esq))
	for tabla: Dictionary in [AnimQuaternius.CLIP_REAL, AnimQuaternius.CLIP_CAMINATA]:
		for clave: String in tabla.keys():
			var nombre := String(tabla[clave])
			if AnimQuaternius.cargar_real(nombre, prefijo) == null:
				perdidos.append("%s (%s)" % [clave, nombre])
	_comprobar(perdidos.is_empty(), "clips de AnimQuaternius sin encontrar: %s" % ", ".join(perdidos))

