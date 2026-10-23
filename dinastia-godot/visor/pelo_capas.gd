class_name PeloCapas
extends "res://visor/pelo_capas_p1.gd"
## (Parte 2 de 2 de `pelo_capas.gd`.)

## Pone cuero cabelludo, barba, cejas y pestañas. `k` = metros del modelo por
## cm de la malla canónica. Devuelve true si puso el pelo de la cabeza (y quien
## llama esconde el peinado genérico de `PeloQ`).
static func poner(d: Dictionary, datos: Dictionary, foto: Texture2D, pos: PackedVector3Array,
		uv: PackedVector2Array, tri: PackedInt32Array, k: float, nivel: int = 1) -> bool:
	var esq: Skeleton3D = d.get("esqueleto")
	if esq == null or not ResourceLoader.exists(SHADER):
		return false
	var hueso := esq.find_bone("Head")
	if hueso < 0:
		return false
	var anc := BoneAttachment3D.new()
	anc.name = "PeloCapas"
	anc.bone_name = "Head"
	esq.add_child(anc)
	var al_hueso := esq.get_bone_global_rest(hueso).affine_inverse()
	var reduce := 1.0 if nivel >= 1 else 0.6
	var normales := _normales(pos, tri)
	## BARBA y CEJAS: sobre la malla de la cara, con el color de la foto.
	## PASO 1 (orden del usuario: primero la piel/cara, después el pelo): la
	## barba y las cejas por capas quedan apagadas; la piel replicada ya las
	## trae. Se encienden en el paso 2 (`BARBA_CEJAS_3D`).
	var barba := _densidades(String(datos.get("b", "")) if BARBA_CEJAS_3D else "", pos.size())
	## Solo dentro de la cara (no en el borde que se funde con el cuello: ahí
	## quedaban pelos flotando bajo el mentón).
	## Solo barba de verdad: por debajo de 0,2 era ruido de la foto (salían
	## motas junto a los labios de jugadores sin barba, Haaland).
	## Colores del pelo medido (para barba y cejas).
	var hm: Variant = datos.get("h")
	var c_pelo := Color(String(hm.get("c", "#2a211b"))) if hm is Dictionary and not bool(hm.get("gorro", false)) else Color("#2a211b")
	var c_raiz := Color(String(hm.get("r", "#1a1411"))) if hm is Dictionary and not bool(hm.get("gorro", false)) else Color("#1a1411")
	var cerca_labios := _anillo(LABIOS, tri, 2)
	for i in barba.size():
		barba[i] = smoothstep(0.3, 0.65, barba[i])
		if i < CaraMalla._alfa.size() and CaraMalla._alfa[i] < 0.99:
			barba[i] = 0.0
		## Nada sobre los labios ni pegado a ellos (motas rojas en Haaland):
		## el bigote y la perilla empiezan un poco más allá.
		if cerca_labios.has(i):
			barba[i] *= 0.0 if LABIOS.has(i) else 0.35
	if _max(barba) > 0.05:
		## Solo triángulos con dos puntos de barba: sin puntos sueltos.
		var m := _capas_sobre(pos, normales, uv, _solo_con(tri, barba, 2), barba, barba, int(CAPAS_BARBA * reduce), false)
		if m != null:
			var mat := _material({"usa_foto": true, "foto": foto, "balance": _wb(datos),
				"color_punta": _lineal(c_pelo), "color_raiz": _lineal(c_raiz), "grosor": 0.0026, "caida": 0.55, "nucleo": 0.6, "mezcla_foto": 0.55,
				"hebras_cm": 16.0, "radio": 0.44, "oscurecer_foto": 1.0, "sombra_raiz": 0.9})
			_colgar(anc, al_hueso, m, mat, "Barba")
	var cejas := _densidades(String(datos.get("e", "")) if BARBA_CEJAS_3D else "", pos.size())
	if _max(cejas) > 0.05:
		## Solo los triángulos de la propia ceja (los de la frente de MediaPipe
		## son grandes: repartir la densidad a los vecinos llenaba la frente
		## de puntos).
		var m2 := _capas_sobre(pos, normales, uv, _solo_con(tri, cejas, 2), cejas, cejas, int(CAPAS_CEJAS * reduce), false)
		if m2 != null:
			var mat2 := _material({"usa_foto": true, "foto": foto, "balance": _wb(datos),
				"color_punta": _lineal(c_pelo), "color_raiz": _lineal(c_raiz), "grosor": 0.0011, "caida": -0.2, "nucleo": 0.6, "mezcla_foto": 0.5,
				"hebras_cm": 18.0, "radio": 0.44, "estirar": 3.0, "oscurecer_foto": 0.95, "sombra_raiz": 0.9})
			_colgar(anc, al_hueso, m2, mat2, "Cejas")
	## PESTAÑAS: tiras de verdad sobre el párpado de arriba.
	var clave_p := hash(pos)
	var pest: ArrayMesh = _cache_pestanas.get(clave_p)
	if pest == null:
		pest = _pestanas(pos, normales)
		if pest != null:
			_cache_pestanas[clave_p] = pest
	if pest != null and ResourceLoader.exists(SHADER_PESTANAS):
		var mp := ShaderMaterial.new()
		mp.shader = load(SHADER_PESTANAS)
		_colgar(anc, al_hueso, pest, mp, "Pestanas")
	## CUERO CABELLUDO.
	var h: Variant = datos.get("h")
	if not (h is Dictionary):
		return false
	var hd := h as Dictionary
	if bool(hd.get("gorro", false)):
		return false
	var cuerpo := _malla_cuerpo(d.get("modelo"))
	if cuerpo.is_empty():
		return false
	var alto_cm := clampf(float(hd.get("alto", 7.0)) - CRANEO_CM, 0.25, 6.0)
	if bool(hd.get("cortado", false)):
		alto_cm = maxf(alto_cm, 2.0)
	var clave_cuero := "%s|%d|%d|%d" % [String(cuerpo.get("id", "")), hash(hd), hash(pos), int(CAPAS_CUERO * reduce)]
	var cuero: ArrayMesh = _cache_cuero.get(clave_cuero)
	if cuero == null:
		cuero = _cuero(cuerpo, pos, datos, hd, int(CAPAS_CUERO * reduce))
		if cuero != null:
			_cache_cuero[clave_cuero] = cuero
	if cuero == null:
		return false
	var rizo := float(hd.get("rizo", 0.0))
	var punta := _lineal(Color(String(hd.get("c", "#2a211b"))))
	var raiz := _lineal(Color(String(hd.get("c", "#2a211b"))).lerp(Color(String(hd.get("r", "#1a1411"))), 0.5))
	## AFRO: mucho volumen y rizo -> masa casi maciza con borde de rizos.
	var corte := corte_de(hd)
	var afro := corte == "afro" or corte == "melena_rizada"
	if corte == "melena_rizada":
		alto_cm = maxf(alto_cm, 4.5)
		rizo = maxf(rizo, 0.8)
	if corte == "tupe":
		## Un tupé o engominado no es tan alto como mide la foto (cabeza
		## inclinada, pelo hacia atrás): como mucho 3,5 cm.
		alto_cm = minf(alto_cm, 3.5)
		rizo = 0.0
	var calvo := bool(hd.get("calvo", false))
	var mat3 := _material({"color_punta": punta, "color_raiz": raiz, "grosor": alto_cm * k,
		"caida": lerpf(0.35, 0.05, rizo), "hebras_cm": 2.0 if afro else lerpf(3.6, 2.4, rizo),
		"radio": 0.46 if afro else lerpf(0.3, 0.4, rizo),
		"rizo": rizo, "base_opaca": true, "nucleo": 0.78 if afro else 0.45})
	## Calvo: cabeza afeitada, sin capas. La herradura por capas (de pelo
	## normal o de pocos días) se veía como puntos de suciedad detrás de la
	## oreja (última pasada, 5-10). Se devuelve true: el peinado del pack se
	## esconde igual.
	if calvo:
		return true
	var cerca := _colgar(anc, al_hueso, cuero, mat3, "Cuero")
	## DETALLE SEGÚN LA DISTANCIA (17-10-2026, MEGA AUDITORÍA 2 punto 14): las
	## 15 capas costaban 14 mil triángulos por cabeza (≈180 mil en el plano de
	## TV, donde una cabeza mide 20-30 píxeles). Desde `DIST_CUERO` m se cambia
	## a la misma forma con `CAPAS_LEJOS` capas: igual de alta (la capa de
	## arriba no se mueve) y del mismo color; solo se pierde la separación
	## entre capas, que de lejos no llega a un píxel.
	var capas_cerca := int(CAPAS_CUERO * reduce)
	if capas_cerca > CAPAS_LEJOS:
		var clave_l := "%s|%d|%d|%d" % [String(cuerpo.get("id", "")), hash(hd), hash(pos), CAPAS_LEJOS]
		var lejos: ArrayMesh = _cache_cuero.get(clave_l)
		if lejos == null:
			lejos = _cuero(cuerpo, pos, datos, hd, CAPAS_LEJOS)
			if lejos != null:
				_cache_cuero[clave_l] = lejos
		if lejos != null:
			cerca.visibility_range_end = DIST_CUERO
			cerca.visibility_range_end_margin = 2.0
			var mi_l := _colgar(anc, al_hueso, lejos, mat3, "CueroLejos")
			mi_l.visibility_range_begin = DIST_CUERO
			mi_l.visibility_range_begin_margin = 2.0
	## Melena (llega a la mandíbula o más): quien llama pone además el peinado
	## largo del pack encima (el pelo por capas no cuelga).
	return float(hd.get("largo", 0.0)) < LARGO_MELENA or corte == "melena_rizada"

## Reparte un poco de cada valor a sus vecinos (la forma de la ceja entre los
## puntos que marca MediaPipe).
static func _suavizar(a: PackedFloat32Array, tri: PackedInt32Array, f: float) -> PackedFloat32Array:
	var out := a.duplicate()
	for t in range(0, tri.size() - 2, 3):
		for j in 3:
			var i0 := tri[t + j]
			for kk in 3:
				var i1 := tri[t + kk]
				if i0 < a.size() and i1 < a.size():
					out[i1] = maxf(out[i1], a[i0] * f)
	return out
