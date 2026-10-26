extends "res://visor/estadio_partes_tribuna.gd"
## [Capa 10/12 de `stadium_builder.gd`] _preparar_obra, _tribunas, _tribuna_de
##
## FASE 0 (25-10-2026): esto era `build_1`, 365 líneas de un tirón que devolvían un Array de 13
## posiciones. Ahora se parte por zonas: aquí se prepara la obra (forma, medidas, materiales compartidos)
## y se resuelve cada tribuna; lo que se levanta de cada una está en `estadio_partes_tribuna.gd`, y el
## resto del recinto (esquinas, vallas, fachada…) en `stadium_builder_p10.gd`. Mismo árbol, mismo orden:
## lo vigila `pruebas/ideas/f0b_huella.gd`.

## Lo que se calcula una vez al empezar: la geometría de la forma, las bandejas, la altura y los
## materiales que comparten todas las tribunas.
static func _preparar_obra(root: Node3D, est: Dictionary, cap_efectiva: int, ocupacion: float, seed_val: int, mi: Club) -> EstadioObra:
	_tm("")
	var obra := EstadioObra.new()
	obra.root = root
	obra.cap_efectiva = cap_efectiva
	obra.ocupacion = ocupacion
	obra.seed_val = seed_val
	obra.mi = mi
	## La ropa de la hinchada, de los colores del CLUB (M-047; antes salía de los
	## de las butacas). Copia: el perfil del estadio no se toca.
	if mi != null and not est.has("hincha1"):
		est = est.duplicate()
		est["hincha1"] = mi.color1
		est["hincha2"] = mi.color2
	obra.est = est
	_explanada_de_fondo(root)
	var forma := str(est.get("forma", "cuenco"))
	var g := geom_de_forma(forma)
	obra.g = g
	obra.dz = g["dz"]
	obra.dx = g["dx"]
	obra.abierta = g["abierta"]
	## Tribunas que no se construyen: la de `abierta` o varias ("dos").
	obra.abiertas = g.get("abiertas", [obra.abierta] if obra.abierta >= 0 else [])
	obra.principal = int(g.get("principal", -1))
	## Dónde cruza el túnel la tribuna del fondo +Z (-1000 = sin túnel).
	obra.tunel_x0 = tunel_x(est) if not (0 in obra.abiertas) else -1000.0

	# Niveles: los que el club realmente construyo, pero nunca mas bandejas de
	# las que el aforo justifica (un estadio de 8.000 con 3 bandejas seria falso).
	obra.niveles = niveles_de(est, cap_efectiva)
	obra.alto = altura_de(est, cap_efectiva)
	obra.techo = str(est.get("techo", "anillo"))

	## RONDA 5 DE CALIDAD VISUAL (17-9-2026): `stand_mat`/`roof_mat` eran color
	## plano puro -y no son un detalle chico como los banderines de corner, son
	## LA FACHADA ENTERA de las 4 tribunas y todo el techo, la superficie mas
	## grande y mas a la vista de todo el estadio despues del cesped. Hormigon
	## de verdad para el muro (misma factoria que ya usa el tunel y la
	## ciudad), y el techo por tipo: membrana es LONA tensada de verdad -PTFE/
	## ETFE, lo mismo que ya modela `Texturas.tela()`, no pintura sobre metal-,
	## el resto es la cubierta metalica estructural de siempre.
	## B6 (25-9-2026): la fachada y el techo, del material y color elegidos.
	obra.stand_mat = _mat_fachada(str(est.get("fachada", "hormigon")), str(est.get("fachadaCol", "")))
	obra.techo_col = str(est.get("techoCol", ""))
	obra.roof_mat = _techo_mat(obra.techo, obra.techo_col)
	var crowd_mat := StandardMaterial3D.new()
	crowd_mat.albedo_texture = _make_stand_texture(
		str(est.get("asientoP", "franjas")),
		_c(est.get("asiento1"), "#2b6b45"), _c(est.get("asiento2"), "#ffffff"),
		_c(est.get("asiento3"), "#20272a"), seed_val, clampf(ocupacion, 0.05, 0.98))
	crowd_mat.roughness = 1.0
	## BUG REAL, SEGUNDA PARTE (21-9-2026): generar mipmaps en la imagen (mas
	## arriba en `_make_stand_texture()`) no alcanzo por si solo -la grada se
	## ve casi rasante desde una camara a nivel de cancha, y el filtro por
	## defecto de un material (`LINEAR_WITH_MIPMAPS`, sin anisotropico) igual
	## sub-muestrea fuerte en ese angulo: sigue aliasing. El "publico" de esta
	## textura es ruido pixel a pixel -sin coherencia local que un mip
	## isotropico pueda promediar bien-, asi que es el caso de libro para
	## filtrado anisotropico explicito.
	crowd_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	obra.crowd_mat = crowd_mat
	_tm("textura_grada")
	obra.fondo_trib = fondo_tribuna(obra.niveles)
	# El graderio va INCLINADO, no como un muro vertical: es lo que hace que se
	# lea como estadio y no como una caja, y ademas la superficie raqueada recibe
	# de frente la luz de los focos, asi que el publico se ve tambien de noche.
	# La pendiente ya NO sale de dividir la altura total entre el fondo total
	# -eso daba 58,6 grados con 3 bandejas-: es fija y acotada, y lo que crece
	# con las bandejas es el numero de rampas, no su inclinacion.
	obra.ang = deg_to_rad(RAKE_GRADOS)
	obra.subida_b = subida_bandeja()
	return obra

## Las cuatro tribunas nominales. 0 = fondo sur, 1 = fondo norte, 2 = lateral este, 3 = lateral oeste.
## "cara" apunta desde la tribuna hacia el campo.
##
## `pos` ya NO es el eje nominal: es el centro REAL de la tribuna, que se corre hacia afuera a medida
## que se le suman bandejas (ver `centro_tribuna()`). La cara que da al cesped se queda siempre en el
## mismo sitio, que es lo que importa para la cancha y las camaras.
static func _tribunas(obra: EstadioObra) -> Array:
	var dx := obra.dx
	var dz := obra.dz
	var alto := obra.alto
	var fondo_trib := obra.fondo_trib
	var cz := centro_tribuna(dz, obra.niveles)
	var cx := centro_tribuna(dx, obra.niveles)
	return [
		{"i": 0, "pos": Vector3(0, alto / 2.0, cz), "size": Vector3(dx * 2.0 - 4.0, alto, fondo_trib),
			"cara": Vector3(0, 0, -1)},
		{"i": 1, "pos": Vector3(0, alto / 2.0, -cz), "size": Vector3(dx * 2.0 - 4.0, alto, fondo_trib),
			"cara": Vector3(0, 0, 1)},
		{"i": 2, "pos": Vector3(cx, alto / 2.0, 0), "size": Vector3(fondo_trib, alto, dz * 2.0 - 4.0),
			"cara": Vector3(-1, 0, 0)},
		{"i": 3, "pos": Vector3(-cx, alto / 2.0, 0), "size": Vector3(fondo_trib, alto, dz * 2.0 - 4.0),
			"cara": Vector3(1, 0, 0)},
	]

## Lo que la tribuna `s` resuelve antes de levantarse: su tamaño (la de honor crece) y su estilo propio.
static func _tribuna_de(obra: EstadioObra, s: Dictionary) -> EstadioObra.Tribuna:
	var est := obra.est
	var t := EstadioObra.Tribuna.new()
	t.i = int(s["i"])
	## FORMA "principal" (MEGAPLAN B6): la tribuna de los banquillos (+X)
	## lleva una bandeja más que el resto, como los estadios con una gran
	## tribuna de honor. Las demás tribunas no cambian.
	t.niv_s = obra.niveles
	t.alto_s = obra.alto
	t.fondo_s = obra.fondo_trib
	t.pos = s["pos"]
	t.size = s["size"]
	if s["i"] == obra.principal:
		t.niv_s = mini(obra.niveles + 1, NIVELES_MAX)
		t.alto_s = ALTURA_PIE + float(t.niv_s) * subida_bandeja() + float(t.niv_s - 1) * FRENTE_BANDEJA
		t.fondo_s = fondo_tribuna(t.niv_s)
		t.pos = Vector3(centro_tribuna(obra.dx, t.niv_s), t.alto_s / 2.0, 0)
		t.size = Vector3(t.fondo_s, t.alto_s, obra.dz * 2.0 - 4.0)
	t.cara = s["cara"]
	t.lateral = absf(t.cara.x) > 0.5
	## BANDEJA (16-9-2026): si esta tribuna tiene un estilo propio en
	## `est["bandejas"]`, se usa en vez del global -asientoP y techo, los dos
	## únicos campos que esta primera fase deja variar por tribuna (altura y
	## forma siguen siendo del recinto entero, ver el comentario del contrato
	## en `estadio_propio.gd`)-. Sin `personalizar_bandejas` activo
	## `est.get("bandejas", {})` da `{}` y `estilo` sale siempre vacío, así
	## que el resto sigue leyendo exactamente `asientoP`/`techo`
	## globales, cero cambio de comportamiento para cualquier estadio que no
	## haya tocado el interruptor -rivales incluidos, que nunca traen la clave.
	t.estilo = (est.get("bandejas", {}) as Dictionary).get(NOMBRE_BANDEJA.get(s["i"], ""), {})
	t.asiento_p = str(t.estilo.get("asientoP", est.get("asientoP", "franjas")))
	t.techo_i = str(t.estilo.get("techo", obra.techo))
	## B6.1: los colores de ESTA tribuna. Si no se tocaron, `est_s` es el
	## mismo diccionario de siempre y nada cambia.
	t.est_s = est
	var col_i1 := str(t.estilo.get("col1", ""))
	var col_i2 := str(t.estilo.get("col2", ""))
	if col_i1 != "" or col_i2 != "":
		t.est_s = est.duplicate()
		if col_i1 != "":
			t.est_s["asiento1"] = col_i1
		if col_i2 != "":
			t.est_s["asiento2"] = col_i2
	## TRAMO (22-9-2026): si esta tribuna tiene tercios propios en
	## `est["tramos"]` -independiente de "bandejas", ver el contrato en
	## `estadio_propio.gd`-, son 3 patrones ya resueltos (nunca vacíos: la
	## capa de `nucleo` ya rellenó cada tercio en blanco con `asiento_p`).
	## Sin `personalizar_tramos` activo `est_s.get("tramos", {})` da `{}` y
	## esto sale `[]` siempre, cero cambio para cualquier estadio que no
	## haya tocado el interruptor.
	t.tramos_i = (t.est_s.get("tramos", {}) as Dictionary).get(NOMBRE_BANDEJA.get(s["i"], ""), [])
	t.es_tramo = t.tramos_i.size() == 3
	t.hueco = t.i == 0 and obra.tunel_x0 > -999.0
	return t

## Una tribuna entera, zona por zona (ver `estadio_partes_tribuna.gd`).
static func _levantar_tribuna(obra: EstadioObra, s: Dictionary) -> void:
	var t := _tribuna_de(obra, s)
	_muro_y_zocalo(obra, t)
	_bandejas(obra, t, _material_grada(obra, t))
	_techo_tribuna(obra, t)
	_fachada_tribuna(obra, t)
