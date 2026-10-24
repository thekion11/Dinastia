extends "res://visor/stadium_builder_p9.gd"
## [Capa 10/12 de `stadium_builder.gd`] build_1

## (Parte 10 de 11 de `stadium_builder.gd`.)

## Tramo 1 de 2 de `build` (la norma de 450 líneas la troceó).
static func build_1(root: Node3D, est: Dictionary, cap_efectiva: int, ocupacion: float, seed_val: int, mi: Club) -> Array:
	_tm("")
	## La ropa de la hinchada, de los colores del CLUB (M-047; antes salía de los
	## de las butacas). Copia: el perfil del estadio no se toca.
	if mi != null and not est.has("hincha1"):
		est = est.duplicate()
		est["hincha1"] = mi.color1
		est["hincha2"] = mi.color2
	_explanada_de_fondo(root)
	var forma := str(est.get("forma", "cuenco"))
	var g := geom_de_forma(forma)
	var dz: float = g["dz"]
	var dx: float = g["dx"]
	var abierta: int = g["abierta"]
	## Tribunas que no se construyen: la de `abierta` o varias ("dos").
	var abiertas: Array = g.get("abiertas", [abierta] if abierta >= 0 else [])
	var principal: int = int(g.get("principal", -1))
	## Dónde cruza el túnel la tribuna del fondo +Z (-1000 = sin túnel).
	var tunel_x0 := tunel_x(est) if not (0 in abiertas) else -1000.0

	# Niveles: los que el club realmente construyo, pero nunca mas bandejas de
	# las que el aforo justifica (un estadio de 8.000 con 3 bandejas seria falso).
	var niveles := niveles_de(est, cap_efectiva)
	var alto := altura_de(est, cap_efectiva)

	var techo := str(est.get("techo", "anillo"))

	## RONDA 5 DE CALIDAD VISUAL (17-9-2026): `stand_mat`/`roof_mat` eran color
	## plano puro -y no son un detalle chico como los banderines de corner, son
	## LA FACHADA ENTERA de las 4 tribunas y todo el techo, la superficie mas
	## grande y mas a la vista de todo el estadio despues del cesped. Hormigon
	## de verdad para el muro (misma factoria que ya usa el tunel y la
	## ciudad), y el techo por tipo: membrana es LONA tensada de verdad -PTFE/
	## ETFE, lo mismo que ya modela `Texturas.tela()`, no pintura sobre metal-,
	## el resto es la cubierta metalica estructural de siempre.
	## B6 (25-9-2026): la fachada y el techo, del material y color elegidos.
	var stand_mat := _mat_fachada(str(est.get("fachada", "hormigon")), str(est.get("fachadaCol", "")))
	var techo_col := str(est.get("techoCol", ""))
	var roof_mat := _techo_mat(techo, techo_col)
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

	# 0 = fondo sur, 1 = fondo norte, 2 = lateral este, 3 = lateral oeste.
	# "cara" apunta desde la tribuna hacia el campo.
	#
	# `pos` ya NO es el eje nominal: es el centro REAL de la tribuna, que se
	# corre hacia afuera a medida que se le suman bandejas (ver
	# `centro_tribuna()`). La cara que da al cesped se queda siempre en el mismo
	# sitio, que es lo que importa para la cancha y las camaras.
	_tm("textura_grada")
	var fondo_trib := fondo_tribuna(niveles)
	var cz := centro_tribuna(dz, niveles)
	var cx := centro_tribuna(dx, niveles)
	var stands := [
		{"i": 0, "pos": Vector3(0, alto / 2.0, cz), "size": Vector3(dx * 2.0 - 4.0, alto, fondo_trib),
			"cara": Vector3(0, 0, -1)},
		{"i": 1, "pos": Vector3(0, alto / 2.0, -cz), "size": Vector3(dx * 2.0 - 4.0, alto, fondo_trib),
			"cara": Vector3(0, 0, 1)},
		{"i": 2, "pos": Vector3(cx, alto / 2.0, 0), "size": Vector3(fondo_trib, alto, dz * 2.0 - 4.0),
			"cara": Vector3(-1, 0, 0)},
		{"i": 3, "pos": Vector3(-cx, alto / 2.0, 0), "size": Vector3(fondo_trib, alto, dz * 2.0 - 4.0),
			"cara": Vector3(1, 0, 0)},
	]

	# El graderio va INCLINADO, no como un muro vertical: es lo que hace que se
	# lea como estadio y no como una caja, y ademas la superficie raqueada recibe
	# de frente la luz de los focos, asi que el publico se ve tambien de noche.
	# La pendiente ya NO sale de dividir la altura total entre el fondo total
	# -eso daba 58,6 grados con 3 bandejas-: es fija y acotada, y lo que crece
	# con las bandejas es el numero de rampas, no su inclinacion.
	var ang := deg_to_rad(RAKE_GRADOS)
	var subida_b := subida_bandeja()

	## LAS CARAS DE FUERA (16-10-2026): cada tribuna y cada torre de esquina
	## deja aquí su paño exterior y `FachadaEstadio` lo viste al final.
	var caras_fachada: Array = []
	for s in stands:
		if s["i"] in abiertas:
			continue
		## FORMA "principal" (MEGAPLAN B6): la tribuna de los banquillos (+X)
		## lleva una bandeja más que el resto, como los estadios con una gran
		## tribuna de honor. Las demás tribunas no cambian.
		var niv_s := niveles
		var alto_s := alto
		var fondo_s := fondo_trib
		var pos: Vector3 = s["pos"]
		var size: Vector3 = s["size"]
		if s["i"] == principal:
			niv_s = mini(niveles + 1, NIVELES_MAX)
			alto_s = ALTURA_PIE + float(niv_s) * subida_bandeja() + float(niv_s - 1) * FRENTE_BANDEJA
			fondo_s = fondo_tribuna(niv_s)
			pos = Vector3(centro_tribuna(dx, niv_s), alto_s / 2.0, 0)
			size = Vector3(fondo_s, alto_s, dz * 2.0 - 4.0)
		var cara: Vector3 = s["cara"]
		var lateral: bool = absf(cara.x) > 0.5
		## BANDEJA (16-9-2026): si esta tribuna tiene un estilo propio en
		## `est["bandejas"]`, se usa en vez del global -asientoP y techo, los dos
		## únicos campos que esta primera fase deja variar por tribuna (altura y
		## forma siguen siendo del recinto entero, ver el comentario del contrato
		## en `estadio_propio.gd`)-. Sin `personalizar_bandejas` activo
		## `est.get("bandejas", {})` da `{}` y `estilo` sale siempre vacío, así
		## que el resto del loop sigue leyendo exactamente `asientoP`/`techo`
		## globales, cero cambio de comportamiento para cualquier estadio que no
		## haya tocado el interruptor -rivales incluidos, que nunca traen la clave.
		var estilo: Dictionary = (est.get("bandejas", {}) as Dictionary).get(NOMBRE_BANDEJA.get(s["i"], ""), {})
		var asientoP_i := str(estilo.get("asientoP", est.get("asientoP", "franjas")))
		var techo_i := str(estilo.get("techo", techo))
		## B6.1: los colores de ESTA tribuna. Si no se tocaron, `est_s` es el
		## mismo diccionario de siempre y nada cambia.
		var est_s: Dictionary = est
		var col_i1 := str(estilo.get("col1", ""))
		var col_i2 := str(estilo.get("col2", ""))
		if col_i1 != "" or col_i2 != "":
			est_s = est.duplicate()
			if col_i1 != "":
				est_s["asiento1"] = col_i1
			if col_i2 != "":
				est_s["asiento2"] = col_i2
		## TRAMO (22-9-2026): si esta tribuna tiene tercios propios en
		## `est["tramos"]" -independiente de "bandejas", ver el contrato en
		## `estadio_propio.gd`-, son 3 patrones ya resueltos (nunca vacíos: la
		## capa de `nucleo` ya rellenó cada tercio en blanco con `asientoP_i`).
		## Sin `personalizar_tramos` activo `est_s.get("tramos", {})` da `{}` y
		## esto sale `[]` siempre, cero cambio para cualquier estadio que no
		## haya tocado el interruptor.
		var tramos_i: Array = (est_s.get("tramos", {}) as Dictionary).get(NOMBRE_BANDEJA.get(s["i"], ""), [])
		# Muro exterior del recinto (la fachada). El interior NO se rellena con
		# una caja solida: si se hace, la rampa de asientos queda dentro de ella
		# y el publico no se ve desde ninguna camara.
		var muro_pos: Vector3 = pos + cara * (-fondo_s / 2.0 + 0.5)
		var muro_size := Vector3(1.0, alto_s, size.z) if lateral else Vector3(size.x, alto_s, 1.0)
		var pie: Vector3 = pos - cara * (fondo_s / 2.0 - FONDO_BANDEJA / 2.0)
		## EL TÚNEL ATRAVIESA ESTA TRIBUNA (7-10-2026, pedido: «la zona del
		## túnel debe ser más real; el estadio será navegable»). En la tribuna
		## del túnel (+Z) el muro, el zócalo y la primera bandeja se parten y
		## dejan un hueco de verdad: ahí va el pasillo de `TunelVestuario`.
		var hueco: bool = int(s["i"]) == 0 and tunel_x0 > -999.0
		if hueco:
			for tr: Vector2 in _tramos_sin_hueco(pos.x, size.x, tunel_x0 - TUNEL_HUECO, tunel_x0 + TUNEL_HUECO):
				_box(root, Vector3(tr.x, muro_pos.y, muro_pos.z), Vector3(tr.y, alto_s, 1.0), stand_mat)
				_box(root, Vector3(tr.x, ALTURA_PIE / 2.0, pie.z), Vector3(tr.y, ALTURA_PIE, FONDO_BANDEJA), stand_mat)
			## Sobre la puerta del muro, el muro sigue.
			var alto_puerta: float = TunelVestuario.ALTO + 0.4
			if alto_s > alto_puerta:
				_box(root, Vector3(tunel_x0, (alto_s + alto_puerta) / 2.0, muro_pos.z),
					Vector3(TUNEL_HUECO * 2.0, alto_s - alto_puerta, 1.0), stand_mat)
		else:
			_box(root, muro_pos, muro_size, stand_mat)
			# Zocalo bajo la primera bandeja, para que no se vea el hueco desde el
			# campo. Va pegado a la cara interior, no al centro de la tribuna: con
			# varias bandejas el centro se va muy hacia atras.
			var zocalo_size := Vector3(FONDO_BANDEJA, ALTURA_PIE, size.z) if lateral \
				else Vector3(size.x, ALTURA_PIE, FONDO_BANDEJA)
			_box(root, Vector3(pie.x, ALTURA_PIE / 2.0, pie.z), zocalo_size, stand_mat)

		var largo_rake := sqrt(FONDO_BANDEJA * FONDO_BANDEJA + subida_b * subida_b)
		## El angulo CON SIGNO, que es el que hay que deshacer en las butacas y
		## los hinchas para que queden de pie (ver `_butacas()`). Sin el signo
		## la mitad de las tribunas quedaria con el publico inclinado el doble
		## en vez de derecho.
		var rake_firmado: float = ang * (signf(-cara.x) if lateral else signf(cara.z))
		# La textura de graderio se repite cada ~20 m a lo largo. Sin esto se
		# estira sobre los 90 m de tribuna y el publico sale como churretones.
		var largo_tribuna: float = size.z if lateral else size.x
		## Si esta tribuna pidió un patrón de asiento propio, se genera SU PROPIA
		## textura -misma función, mismos colores globales (esta fase no varía
		## color por tribuna, solo patrón y techo), solo cambia `asientoP_i`- en
		## vez de reusar la compartida. Si no, sigue compartiendo `crowd_mat` como
		## siempre: nada nuevo se genera para un estadio sin bandejas propias.
		## TRAMO tiene prioridad sobre Bandeja cuando los dos aplican a la misma
		## tribuna: 3 patrones dicen más que 1, y `_tramos_personalizados()` ya
		## usó el patrón de Bandeja como base de los tercios en blanco, así que
		## no se pierde la elección de Bandeja, se refina.
		var deck_mat: StandardMaterial3D
		var es_tramo := tramos_i.size() == 3
		if es_tramo:
			var trio := [_c(est_s.get("asiento1"), "#2b6b45"), _c(est_s.get("asiento2"), "#ffffff"),
				_c(est_s.get("asiento3"), "#20272a")]
			deck_mat = StandardMaterial3D.new()
			deck_mat.albedo_texture = _make_stand_texture_tramos(tramos_i,
				[trio, trio, trio], seed_val, clampf(ocupacion, 0.05, 0.98))
			deck_mat.roughness = 1.0
			## Sin esto, esta textura queda con el filtro por defecto -no el
			## anisotropico que `crowd_mat` sí tiene (ver el bug real de
			## "estática de TV" del 21-9)-, y a la rasante con que se ve una
			## grada desde la cancha eso vuelve a hacer aliasing.
			deck_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		elif asientoP_i != str(est_s.get("asientoP", "franjas")) or est_s != est:
			deck_mat = StandardMaterial3D.new()
			deck_mat.albedo_texture = _make_stand_texture(asientoP_i,
				_c(est_s.get("asiento1"), "#2b6b45"), _c(est_s.get("asiento2"), "#ffffff"),
				_c(est_s.get("asiento3"), "#20272a"), seed_val, clampf(ocupacion, 0.05, 0.98))
			deck_mat.roughness = 1.0
			## Mismo arreglo que arriba -este material tampoco lo heredaba de
			## `crowd_mat`, un vacío ya existente desde la Fase 1 (Bandeja,
			## 16-9), anterior al hallazgo del 21-9. Se corrige de paso.
			deck_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		else:
			deck_mat = crowd_mat.duplicate()
		## El texto del spike lo advierte: la variante de tercios NO puede
		## reusar el repetido-cada-20m -convierte 2 costuras reales en ~13
		## falsas-, tiene que ir a repeticion 1 (la textura ya cubre la
		## tribuna entera, de punta a punta, sin repetir).
		var repite: float = 1.0 if es_tramo else maxf(1.0, largo_tribuna / 20.0)
		## BUG REAL, MEDIDO (23-9-2026, `pruebas/diagnostico_uv_caja.gd`): un
		## `BoxMesh` NO mapea la textura entera a cada cara, reparte las seis
		## en un atlas de 3x2. La cara de arriba del deck -o sea TODA LA GRADA,
		## la superficie mas grande del estadio- solo veia **U 0,333..0,667 y
		## V 0,5..1,0: el 17% de la imagen**, ampliado 3x a lo ancho y 2x a lo
		## largo. Consecuencias que se veian y no se sabian explicar: el patron
		## de butacas que el usuario elige en Club -> Estadio (franjas, damero,
		## sectores, bandera...) se dibujaba entero en `_make_stand_texture()`
		## pero en pantalla solo salia un SEXTO de el, y la densidad real de
		## texeles a lo ancho de la rampa era un tercio de la generada, que es
		## justo el eje que hacia el aliasing de "estatica de TV" del 21-9.
		##
		## Se corrige remapeando ese rectangulo a 0..1 en vez de cambiar la
		## malla: `uv = uv*escala + desplazamiento`, asi que para llevar
		## u:[1/3,2/3] -> [0,1] hace falta escala 3 y desplazamiento -1, y para
		## v:[1/2,1] -> [0,1] escala 2 y desplazamiento -1 (por la repeticion).
		## Las otras cinco caras quedan fuera de rango, y da igual: son los
		## cantos de una losa de 0,4 m que no se ven desde ninguna camara.
		deck_mat.uv1_scale = Vector3(3.0, 2.0 * repite, 1.0)
		deck_mat.uv1_offset = Vector3(-1.0, -repite, 0.0)

		## UNA RAMPA POR BANDEJA, no una sola para toda la tribuna. Cada una
		## arranca mas arriba y mas atras que la de abajo, y entre ellas va un
		## FRENTE vertical -el paño de palcos y pasillo de un estadio real, y
		## la reja de donde cuelgan los trapos-.
		var largo_deck: float = size.z - 1.0 if lateral else size.x - 1.0
		for b in niv_s:
			## El centro de ESTA bandeja, medido desde la cara interior de la
			## tribuna hacia afuera. `cara` apunta al campo, o sea que restarle
			## `cara` es alejarse de la cancha.
			var avance: float = float(b) * RETRANQUEO_BANDEJA + FONDO_BANDEJA / 2.0
			var centro_b: Vector3 = pos + cara * (fondo_s / 2.0) - cara * avance
			var y_pie: float = ALTURA_PIE + float(b) * (subida_b + FRENTE_BANDEJA)
			## La primera bandeja de la tribuna del túnel va en dos trozos.
			var piezas: Array = [Vector2(centro_b.x, largo_deck)]
			if hueco and b == 0:
				piezas = _tramos_sin_hueco(centro_b.x, largo_deck, tunel_x0 - TUNEL_HUECO, tunel_x0 + TUNEL_HUECO)
			for pz: Vector2 in piezas:
				var deck := MeshInstance3D.new()
				var dm := BoxMesh.new()
				dm.size = Vector3(largo_rake, 0.4, pz.y) if lateral \
					else Vector3(pz.y, 0.4, largo_rake)
				deck.mesh = dm
				deck.position = Vector3(pz.x, y_pie + subida_b / 2.0, centro_b.z)
				deck.rotation = Vector3(0, 0, rake_firmado) if lateral \
					else Vector3(rake_firmado, 0, 0)
				## Cada bandeja lleva SU COPIA del material: comparten la misma
				## textura, pero un material compartido significaria que tocarle el
				## `uv1_*` a una se lo toca a las cinco.
				## COLOR POR ANILLO (28-9-2026): si este anillo de esta tribuna
				## tiene color propio, su textura y sus butacas salen con él.
				var niveles_col: Array = estilo.get("niveles", [])
				var col_b := String(niveles_col[b]) if b < niveles_col.size() else ""
				var est_b: Dictionary = est_s
				if col_b != "" and not es_tramo:
					est_b = est_s.duplicate()
					est_b["asiento1"] = col_b
					var mat_b := StandardMaterial3D.new()
					mat_b.albedo_texture = _make_stand_texture(asientoP_i, _c(col_b, "#2b6b45"),
						_c(est_s.get("asiento2"), "#ffffff"), _c(est_s.get("asiento3"), "#20272a"), seed_val + b, clampf(ocupacion, 0.05, 0.98))
					mat_b.roughness = 1.0
					mat_b.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					mat_b.uv1_scale = deck_mat.uv1_scale
					mat_b.uv1_offset = deck_mat.uv1_offset
					deck.material_override = mat_b
				else:
					deck.material_override = deck_mat.duplicate()
				root.add_child(deck)
				## Un trozo más corto repite la textura menos veces (misma densidad).
				if piezas.size() > 1 and not es_tramo and deck.material_override is StandardMaterial3D:
					var rp := maxf(1.0, pz.y / 20.0)
					(deck.material_override as StandardMaterial3D).uv1_scale.y = 2.0 * rp
					(deck.material_override as StandardMaterial3D).uv1_offset.y = -rp
				## EL SECTOR VISITANTE (M-021, 21-10): en la bandeja baja del fondo
				## −Z (enfrente del túnel), una esquina con los colores del rival.
				if est_b.has("visita1") and not lateral and pos.z < 0.0 and b == 0:
					est_b = est_b.duplicate()
					est_b["sector_visita"] = true
				_butacas(deck, dm.size, lateral, est_b, ocupacion, alto_s, rake_firmado, b)
				_telones(deck, dm.size, lateral, est_s, seed_val + int(s["i"]) * 31 + b * 7)
			## El frente vertical bajo la bandeja: tapa el hueco que dejaria ver
			## por debajo y es lo que le da al estadio su perfil escalonado. La
			## primera bandeja no lo lleva -ahi va el zocalo.
			if b > 0:
				## SOLO EL PETO, NO UNA PARED HASTA ABAJO (corregido con una
				## captura, 23-9-2026). El primer intento le dio de alto
				## `FRENTE_BANDEJA + subida_b` = 9,5 m, y el resultado era un
				## muro negro colgando sobre la bandeja de abajo que se comía
				## media tribuna. La cuenta real: entre el borde alto de una
				## bandeja y el borde bajo de la siguiente hay exactamente
				## `FRENTE_BANDEJA`, porque `y_pie` sube `subida_b + FRENTE`.
				## Lo de debajo NO se tapa: es el voladizo, y debajo del
				## voladizo hay butacas de la bandeja de abajo, que es
				## justamente como se ve un estadio de varias bandejas.
				var frente_pos: Vector3 = centro_b + cara * (FONDO_BANDEJA / 2.0 - 0.4)
				var frente_size := Vector3(0.8, FRENTE_BANDEJA, largo_deck) if lateral \
					else Vector3(largo_deck, FRENTE_BANDEJA, 0.8)
				_box(root, Vector3(frente_pos.x, y_pie - FRENTE_BANDEJA / 2.0 + 0.2,
					frente_pos.z), frente_size, stand_mat)
				## La cinta LED del peto (21-10-2026), mirando al campo.
				_cinta_led(root, Vector3(frente_pos.x, y_pie - 1.1, frente_pos.z) + cara * 0.42, cara,
					largo_deck, est)

		var techo_cabeceras_i := techo_i in ["anillo", "total", "membrana", "retractil", "visera"]
		var techo_lados_i := techo_i != "sin"
		var quiere_techo := techo_cabeceras_i if s["i"] < 2 else techo_lados_i
		if quiere_techo:
			## "total" promete "un anillo profundo que llega casi hasta la
			## raya" y dibujaba EXACTAMENTE lo mismo que "anillo" -mismo
			## material, mismas cabeceras, mismo vuelo de 4 m-: dos opciones
			## del catalogo, las dos cobradas, pixel por pixel iguales. Ahora
			## "total" vuela el doble, que es lo unico que promete.
			var vuelo := 7.0 if techo_i == "total" else (4.0 if techo_i == "anillo" else 2.0)
			## BUG REAL DE Z-FIGHTING (23-9-2026): la losa de una cabecera y la
			## de un lateral ocupaban **el mismo volumen** en las 4 esquinas
			## -con el default son 8,5 x 8,5 m con la Y identica y el mismo
			## material-. Dos planos coincidentes parpadean, y encima justo
			## donde apuntan las camaras de dron y cenital. Se recorta la losa
			## de las CABECERAS para que acabe donde empieza la del lateral;
			## la esquina la cubre su propia losa, mas abajo.
			var recorte: float = 2.0 * (fondo_s / 2.0 + vuelo)
			var rs := Vector3(maxf(size.x + 2.0 - recorte, 4.0), 0.5, size.z + vuelo) if not lateral \
				else Vector3(size.x + vuelo, 0.5, size.z + 2.0)
			## Mismo criterio que el `roof_mat` global -ver `_techo_mat()`-. Solo
			## se pide un material nuevo cuando esta tribuna pidió un techo
			## distinto del global; si no, sigue compartiendo `roof_mat` tal
			## cual, igual que antes de esta fase.
			var roof_mat_i := roof_mat if techo_i == techo else _techo_mat(techo_i, techo_col)
			marcar_techo(_box(root, pos + cara * (vuelo / 2.0) + Vector3(0, alto_s / 2.0 + 0.4, 0), rs, roof_mat_i), -cara)
		## El paño de fuera de esta tribuna. En la del túnel, el vestuario y el
		## edificio del club ocupan su tramo: ahí no se viste nada.
		var n_fuera: Vector3 = -cara
		var largo_f: float = size.z if lateral else size.x
		var pie_f := Vector3(pos.x, 0.0, pos.z) + n_fuera * (fondo_s / 2.0)
		var cara_f := FachadaEstadio.cara(pie_f, n_fuera, largo_f, alto_s, "tribuna", quiere_techo,
			fondo_s + (7.0 if techo_i == "total" else (4.0 if techo_i == "anillo" else 2.0)), niv_s)
		var o_f: Vector3 = cara_f["o"]
		var u_f: Vector3 = cara_f["u"]
		if int(s["i"]) == 0:
			var tx_v := tunel_x(est)
			var s_a := (Vector3(tx_v - TunelVestuario.VEST_MEDIO - 0.8, 0, pie_f.z) - o_f).dot(u_f)
			var s_b := (Vector3(tx_v + TunelVestuario.VEST_MEDIO + 0.8, 0, pie_f.z) - o_f).dot(u_f)
			cara_f["excluir"] = [Vector2(minf(s_a, s_b), maxf(s_a, s_b))]
			## El escudo, al oeste del edificio del club: sobre las taquillas.
			cara_f["escudo"] = true
			cara_f["escudo_s"] = (Vector3(tx_v - TunelVestuario.VEST_MEDIO - 9.0, 0, pie_f.z) - o_f).dot(u_f)
		caras_fachada.append(cara_f)
	return [est, g, dz, dx, abierta, abiertas, niveles, alto, techo, stand_mat, fondo_trib, ang, caras_fachada]
