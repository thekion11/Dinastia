extends "res://visor/pelo_capas_p1_p1.gd"
## (Parte 2 de 2 de `pelo_capas_p1.gd`.)

static func _cuero(cuerpo: Dictionary, cara: PackedVector3Array, _datos: Dictionary, h: Dictionary,
		capas: int) -> ArrayMesh:
	var v: PackedVector3Array = cuerpo["v"]
	var nor: PackedVector3Array = cuerpo["n"]
	## Solo la parte alta de la cabeza puede llevar pelo (ver `_candidatos_cuero`).
	var cand := _candidatos_cuero(cuerpo)
	var ind: PackedInt32Array = cand[1]
	## La línea de la frente: los vértices del anillo que suben (y > ojos), en
	## orden de x, con su altura; donde la foto no ve pelo encima, sube 1,5 cm.
	var linea: Array = h.get("linea", [])
	var puntos: Array = []
	var n0 := CaraMalla.N
	for kk in linea.size():
		var i := n0 + kk
		if i >= cara.size():
			break
		var p := cara[i]
		if p.y < CaraMalla.OJO_Y + 0.02:
			continue
		puntos.append(Vector2(p.x, p.y + (0.0 if int(linea[kk]) == 1 else 0.015)))
	puntos.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	## Suavizada (media de 5): con los saltos de 1,5 cm punto a punto la línea
	## salía con muescas rectangulares.
	var suave: Array = []
	for i in puntos.size():
		var acc := 0.0
		var n := 0
		for j in range(maxi(0, i - 2), mini(puntos.size(), i + 3)):
			acc += (puntos[j] as Vector2).y
			n += 1
		suave.append(Vector2((puntos[i] as Vector2).x, acc / n))
	puntos = suave
	var lados := float(h.get("lados", 0.5))
	var corte := corte_de(h)
	if corte == "afro" or corte == "melena_rizada":
		lados = 1.0
	var dens := PackedFloat32Array()
	var alto := PackedFloat32Array()
	dens.resize(v.size())
	alto.resize(v.size())
	for i: int in cand[0]:
		var p := v[i]
		var yl := _linea_en(puntos, p.x)
		var frente := smoothstep(-0.02, 0.04, p.z)
		var lateral := smoothstep(0.05, 0.08, absf(p.x))
		## La nuca nace a la altura del lóbulo de la oreja (12-11): con 1,575 (la altura del mentón) el
		## pelo bajaba hasta el cuello de la camiseta y de espaldas o de perfil parecía un «mullet».
		var y_atras := lerpf(1.575 if corte == "melena_rizada" else 1.612, 1.67, lateral)
		var y_lim := lerpf(y_atras, yl, frente)
		## Nacimiento difuso: el pelo se aclara en ~1,6 cm, no corta en seco.
		dens[i] = smoothstep(y_lim - 0.006, y_lim + 0.016, p.y)
		## Lados rapados (degradado): más corto y más ralo a los costados.
		var corto := lerpf(1.0, lerpf(0.25, 1.0, lados), lateral * (1.0 - smoothstep(1.72, 1.77, p.y)))
		## LA FORMA DEL CORTE (pasada 2): no un casco parejo.
		var arriba := smoothstep(1.72, 1.80, p.y)
		match corte:
			"tupe":
				## Alto arriba y hacia la frente; costados casi al ras.
				corto = lerpf(0.12, 1.0, (1.0 - lateral) * arriba) * (1.0 + 0.6 * frente * arriba)
			"degradado":
				## Arriba normal; abajo de los costados, degradado al ras.
				corto = lerpf(lerpf(0.1, 0.5, smoothstep(1.64, 1.74, p.y)), 1.0, (1.0 - lateral) * arriba + arriba * 0.3)
			"normal":
				## Domo: más en la coronilla y la frente que sobre las orejas.
				corto *= lerpf(0.7, 1.0, arriba)
			"rapado":
				corto = lerpf(0.6, 1.0, arriba)
		## Y corto en la nuca y sobre las orejas: si no, colgaba hasta el
		## cuello (parecía una melena "mullet").
		if corte != "melena_rizada":
			corto *= lerpf(0.15, 1.0, smoothstep(1.6, 1.74, p.y))
		alto[i] = corto
		## Calvo: solo la herradura de los lados y la nuca (hoy `poner` no la
		## cuelga: cabeza afeitada).
		if bool(h.get("calvo", false)):
			dens[i] *= 1.0 - smoothstep(1.695, 1.725, p.y)
		dens[i] *= lerpf(1.0, lerpf(0.55, 1.0, lados), lateral)
		## LA OREJA no lleva pelo (salía con pelo encima: manchas oscuras o
		## doradas en la oreja). Es lo que sobresale del cráneo a esa altura.
		var oreja := smoothstep(0.068, 0.073, absf(p.x)) * smoothstep(1.63, 1.645, p.y) \
				* (1.0 - smoothstep(1.735, 1.75, p.y))
		dens[i] *= 1.0 - oreja
	var uv := PackedVector2Array()
	uv.resize(v.size())
	## UV2 del cuero: por el ángulo, no por x (si no, las hebras se estiran en los costados).
	## Sale ya hecha de `_capas_sobre` (antes se armaba la malla y se rehacía con la UV2 nueva).
	return _capas_sobre(v, nor, uv, ind, dens, alto, capas, true, true)
