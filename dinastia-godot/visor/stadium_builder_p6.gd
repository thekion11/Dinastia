extends "res://visor/stadium_builder_p5.gd"
## [Capa 6/12 de `stadium_builder.gd`] _butacas, _vomitorios

static func _butacas(deck: MeshInstance3D, tam: Vector3, lateral: bool, est: Dictionary,
		ocupacion: float, alto: float = 6.5, rake: float = 0.0, bandeja: int = 0) -> void:
	var esc := load(RUTA_BUTACAS)
	if esc == null:
		return
	## Se instancia solo para sacar la malla: el nodo se libera enseguida (antes
	## quedaba suelto, y al cerrar el juego el motor avisaba «material is null»).
	var tmp: Node = esc.instantiate() if esc is PackedScene else null
	var malla: Mesh = _primera_malla(tmp)
	if tmp != null:
		tmp.free()
	if malla == null:
		return

	## Largo de la tribuna y fondo del graderio, en el espacio LOCAL del deck (que
	## ya viene inclinado, asi que las butacas heredan la pendiente gratis).
	var largo: float = tam.z if lateral else tam.x
	var fondo: float = tam.x if lateral else tam.z
	var cuantas_fila: int = maxi(1, int(largo / PASO_BUTACA))
	## `alto/6.5` recupera cuantos niveles tiene ESTE graderio -6.5 es la
	## altura por nivel de `altura_de()`, la misma constante, no un numero
	## nuevo-. `FILAS_REALES` sigue siendo el presupuesto de UN nivel: un
	## estadio de 1 nivel no cambia (5 filas, igual que siempre), uno de 2 o 3
	## cubre proporcionalmente mas alto sin que el costo crezca sin control.
	## EL PRESUPUESTO DE BUTACAS 3D SE GASTA ABAJO (23-9-2026, con el graderío
	## por bandejas). Con 5 bandejas × 4 tribunas son 20 rampas: poner las 5
	## filas de butacas del modelo real en todas serían 8,5 millones de
	## vértices, más que el estadio entero de una sola bandeja. Y no hace falta:
	## el motivo documentado de que exista el modelo detallado es que **la
	## cámara de TV pasa cerca del borde del césped**, o sea de la bandeja de
	## abajo. Las de arriba se ven a 30 m o más, donde la textura de grada +
	## los hinchas 3D ya cuentan la misma historia.
	##   bandeja 0 -> las 5 filas de siempre
	##   bandeja 1 -> 2 filas
	##   bandeja 2+ -> ninguna (textura + hinchas, que sí siguen en todas)
	## Total: ~2,4 millones de vértices, MENOS que antes de esta tanda.
	## Etapa 3 (8-10-2026): en calidad MEDIO -la de un equipo modesto- solo las
	## 2 filas pegadas al césped llevan el modelo real (1.944 triángulos por
	## butaca); el resto, la butaca liviana. Medido en el partido: las butacas
	## eran 4,4 M de triángulos, más que todo lo demás junto.
	var reales: int = 2 if Calidad.elegida == Calidad.MEDIO else FILAS_REALES
	var presupuesto: int = reales if bandeja == 0 \
		else (maxi(1, reales / 2) if bandeja == 1 and reales == FILAS_REALES else 0)
	## LA HINCHADA LLEGA ARRIBA DEL TODO; LAS BUTACAS 3D, NO (23-9-2026).
	##
	## Pedido directo del usuario -"ese modelo de público debe estar en toda la
	## grada, siempre falta una parte"-, y tenía razón: con 3 niveles las 15
	## filas de butacas cubrían 13 m de una rampa de 21, o sea que **el tercio
	## de arriba de cada tribuna no tenía ni una persona en 3D**, solo la
	## textura. Se notaba como un corte horizontal a media grada.
	##
	## Se separan los dos presupuestos, que es lo que faltaba: una fila de tres
	## butacas del modelo real cuesta **988 vértices** y un hincha cuesta
	## **~70**. Subir las butacas a toda la rampa sería pasar de 4,4 a 6,7
	## millones de vértices -una Intel UHD no lo mueve, que es justo el motivo
	## documentado de que estuvieran limitadas-. Subir SOLO los hinchas cuesta
	## unos 400.000 en total: se puede de sobra, y es lo que de verdad se ve,
	## porque las butacas de arriba ya las dibuja la textura de la grada.
	var filas_todas: int = maxi(1, int(fondo / PASO_FILA))
	## LA GRADA ENTERA CON BUTACAS (29-9-2026). Pedido del usuario: «ponelas en
	## la totalidad de la grada, deja de hacer lo de poner una versión fea en la
	## zona de arriba». Ahora TODAS las filas tienen butaca 3D: las cercanas al
	## césped con el modelo real, y el resto con `_malla_butaca_lejos()`, la
	## misma butaca con las medidas del modelo pero ~120 vértices en vez de 994
	## -a esa distancia no se distinguen, y poner el modelo real en toda la
	## rampa serían más de 15 millones de vértices-. La textura con gente
	## pintada desaparece: debajo queda cemento.
	var filas: int = mini(presupuesto, filas_todas)
	## ¿QUÉ BORDE DEL DECK ES EL DE ABAJO? (29-9-2026). Se daba por hecho que
	## el lado local negativo, y en las tribunas giradas al revés -la mitad-
	## las filas de butacas 3D y el público denso acababan ARRIBA DEL TODO,
	## con la parte pegada al césped casi vacía. Se mira la inclinación real.
	var eje_fondo := Vector3(1, 0, 0) if lateral else Vector3(0, 0, 1)
	var sentido: float = 1.0 if (deck.basis * eje_fondo).y >= 0.0 else -1.0
	## HACIA DÓNDE MIRA LA BUTACA (29-9-2026, «las butacas están al revés»).
	## En el modelo el respaldo queda en -Z: la butaca mira a +Z. Tiene que
	## mirar al borde bajo de la rampa, que está en -sentido sobre el eje del
	## fondo. `Basis.rotated(UP, g)` lleva +Z a (sin g, 0, cos g), así que:
	##   tribuna lateral (fondo en X): sin g = -sentido -> g = -sentido·π/2
	##   tribuna de fondo (fondo en Z): cos g = -sentido -> g = π si sentido > 0
	## Antes las tribunas de detrás de los arcos quedaban al revés.
	var giro: float = (-sentido * PI * 0.5) if lateral else (PI if sentido > 0.0 else 0.0)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = malla
	mm.instance_count = cuantas_fila * filas
	var mm_lejos := MultiMesh.new()
	mm_lejos.transform_format = MultiMesh.TRANSFORM_3D
	mm_lejos.use_colors = true
	mm_lejos.mesh = _malla_butaca_lejos()
	mm_lejos.instance_count = cuantas_fila * (filas_todas - filas)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(largo * 100.0) + filas
	var c1 := Color(str(est.get("asiento1", "#1f5f3d")))
	var c2 := Color(str(est.get("asiento2", "#e8e8e8")))
	## Paleta de ropa de hincha: neutros de siempre + los dos colores del club
	## para que se lea "hinchada local", no una multitud generica.
	## M-047 (20-10): unos 6 de cada 10 con la camiseta del club (sus colores,
	## no los de las butacas); el resto, ropa de calle.
	var h1 := Color(str(est.get("hincha1", est.get("asiento1", "#1f5f3d"))))
	var h2 := Color(str(est.get("hincha2", est.get("asiento2", "#e8e8e8"))))
	var colores_hincha := [h1, h1, h1, h1, h1, h1, h2, h2, h2, h2,
		Color(0.85, 0.85, 0.88), Color(0.15, 0.16, 0.2), Color(0.45, 0.5, 0.55), Color(0.78, 0.7, 0.45),
		Color(0.2, 0.3, 0.7), Color(0.55, 0.35, 0.25), Color(0.25, 0.5, 0.35)]
	var visita := bool(est.get("sector_visita", false))
	var v1 := Color(str(est.get("visita1", "#ffffff")))
	var v2 := Color(str(est.get("visita2", "#222222")))
	var corte_visita := largo * 0.22
	var hinchas_xf: Array[Transform3D] = []
	var hinchas_col: Array[Color] = []
	var det_xf: Array[Transform3D] = []
	var det_col: Array[Color] = []
	var med_xf: Array[Transform3D] = []
	var med_col: Array[Color] = []
	## 21-10-2026 («la gente no se ve tan real»; el dueño da el rendimiento por
	## bueno): más filas con la persona de detalle (4 → 7 en ALTO) y con la de
	## nivel medio (8 → 12). Desde la quinta fila se veían bloques sin cabeza.
	var filas_medio := 12
	var filas_detalle: int = (10 if Calidad.elegida >= Calidad.ULTRA else 7) if Calidad.elegida >= Calidad.ALTO else 3
	## Un hincha por asiento ocupado: tres por grupo (dos en calidad Media).
	var por_grupo: int = 3 if Calidad.elegida >= Calidad.ALTO else 2
	var eje_largo := Vector3(0, 0, 1) if lateral else Vector3(1, 0, 0)
	var eje_rake := Vector3(0, 0, 1) if lateral else Vector3(1, 0, 0)
	var i := 0
	var j := 0
	var escalones: Array[Transform3D] = []
	var pasillos_l: Array[float] = []
	for f in range(filas_todas):
		## Se empieza por el borde de abajo del deck (el que da al cesped).
		var d: float = sentido * (-fondo * 0.5 + 0.6 + f * PASO_FILA)
		for c in range(cuantas_fila):
			var l: float = -largo * 0.5 + 0.8 + c * PASO_BUTACA
			var p: Vector3 = Vector3(d, 0.24, l) if lateral else Vector3(l, 0.24, d)
			## La contrarrotacion que las deja DE PIE: primero el giro y despues
			## la contrarrotacion del rake (`rotated()` premultiplica).
			var base := Basis().rotated(Vector3.UP, giro)
			if rake != 0.0:
				base = base.rotated(eje_rake, -rake)
			## Franjas de color del club, con alguna butaca desparejada: una grada
			## de un solo tono se lee como una alfombra pintada.
			var col: Color = c1 if (c / 3) % 2 == 0 else c2
			if rng.randf() < 0.04:
				col = col.lightened(0.25)
			col = col.darkened(rng.randf() * 0.12)
			## LOS PASILLOS CON ESCALERA (21-10-2026, «la tribuna sigue viéndose
			## mal»): cada 8 grupos de butacas, una columna libre con peldaños
			## horizontales y barandilla, como en cualquier estadio. Parte la
			## grada en bloques (de lejos era un muro de ruido) y deja el camino
			## por el que se sube a las filas.
			if es_pasillo(c, cuantas_fila):
				var cero := Transform3D(Basis().scaled(Vector3.ZERO), p)
				if f < filas:
					mm.set_instance_transform(i, cero)
					i += 1
				else:
					mm_lejos.set_instance_transform(j, cero)
					j += 1
				escalones.append(Transform3D(Basis().rotated(Vector3.UP, giro).rotated(eje_rake, -rake) if rake != 0.0 else Basis().rotated(Vector3.UP, giro), p + Vector3(0, -0.13, 0)))
				if f == 0:
					pasillos_l.append(l)
				continue
			if f < filas:
				mm.set_instance_transform(i, Transform3D(base, p))
				mm.set_instance_color(i, col)
				i += 1
			else:
				mm_lejos.set_instance_transform(j, Transform3D(base, p))
				mm_lejos.set_instance_color(j, col)
				j += 1
			## Un hincha por asiento ocupado. Las filas pegadas al césped de la
			## bandeja de abajo llevan el hincha de detalle; el resto, el barato.
			var cerca := bandeja == 0 and f < filas_detalle
			for k in (3 if cerca else por_grupo):
				if rng.randf() >= ocupacion:
					continue
				var desp := (float(k) - 0.5 * float((3 if cerca else por_grupo) - 1)) * 0.48
				var jit := Vector3(rng.randf_range(-0.04, 0.04), 0, rng.randf_range(-0.04, 0.04))
				## NO TODOS MIDEN LO MISMO: ±10% de talla, gratis en la matriz.
				var talla := rng.randf_range(0.9, 1.08)
				var base_h := Basis().rotated(Vector3.UP, giro + rng.randf_range(-0.15, 0.15)).scaled(Vector3(talla, talla, talla))
				if rake != 0.0:
					base_h = base_h.rotated(eje_rake, -rake)
				var xf := Transform3D(base_h, p + eje_largo * desp + jit + Vector3(0, 0.15, 0))
				var col_h: Color = colores_hincha[rng.randi_range(0, colores_hincha.size() - 1)]
				col_h = col_h.darkened(rng.randf() * 0.15)
				## El sector visitante: el último cuarto de la fila, con una franja
				## de butacas vacías que lo separa. El azar se consume igual, así el
				## resto de la grada sale idéntico con o sin rival.
				if visita and l > corte_visita - 1.6:
					if l < corte_visita + 1.6:
						continue
					col_h = (v1 if (int(l * 7.0 + float(f) * 3.0) % 5) < 3 else v2).darkened(rng.randf() * 0.12)
				if cerca:
					det_xf.append(xf)
					det_col.append(col_h)
				## Las filas siguientes con la persona de nivel medio (estaba
				## previsto y nunca se llenaba: desde la 5.ª fila eran todos la
				## malla «lejos», bloques sin cabeza). En ALTO: las 12 filas
				## siguientes de la bandeja baja y las 6 primeras de la segunda.
				elif Calidad.elegida >= Calidad.ALTO and ((bandeja == 0 and f < filas_detalle + filas_medio) or (bandeja == 1 and f < 6)):
					med_xf.append(xf)
					med_col.append(col_h)
				else:
					hinchas_xf.append(xf)
					hinchas_col.append(col_h)

	_montar_pasillos(deck, escalones, pasillos_l, lateral, fondo)
	if bandeja == 0:
		_escaleras_de_acceso(deck, escalones, pasillos_l, lateral)

	## Debajo de las butacas, cemento: la textura con gente pintada ya no hace
	## falta y entre fila y fila se veía como manchas estiradas.
	deck.material_override = _mat_escalones()
	if mm_lejos.instance_count > 0:
		var mil := MultiMeshInstance3D.new()
		mil.multimesh = mm_lejos
		var mat_l := StandardMaterial3D.new()
		mat_l.vertex_color_use_as_albedo = true
		mat_l.albedo_color = Color(0.9, 0.9, 0.9)
		mat_l.roughness = 0.55
		mil.material_override = mat_l
		mil.name = "ButacasLejos"
		mil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		deck.add_child(mil)

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(0.9, 0.9, 0.9)
	mat.roughness = 0.55
	mat.metallic = 0.05
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	mi.name = "ButacasCerca"
	## SIN SOMBRA PROPIA (25-9-2026, `pruebas/medir_partido.gd`). Miles de
	## butacas y de hinchas proyectando sombra se dibujaban otra vez en CADA
	## cascada del sol -cuatro en calidad ALTO-: eran el grueso de los ~2
	## millones de triángulos por fotograma. Bajo el techo de la grada esa
	## sombra no se ve; la de la grada entera (el `deck`) sigue estando.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	deck.add_child(mi)

	## Personas reales (mallas horneadas) en la bandeja baja; el maniquí queda para
	## el resto y como respaldo si faltan los recursos.
	var reales_cerca := _hinchas_horneados("cerca")
	var reales_medio := _hinchas_horneados("medio")
	if not reales_cerca.is_empty() and not det_xf.is_empty():
		_montar_publico_lod(deck, "PersonasCerca", reales_cerca, det_xf, det_col)
		det_xf.clear()
		det_col.clear()
	if not reales_medio.is_empty() and not med_xf.is_empty():
		_montar_publico_lod(deck, "PersonasMedio", reales_medio, med_xf, med_col)
	else:
		hinchas_xf.append_array(med_xf)
		hinchas_col.append_array(med_col)
	## EL RESTO DE LAS FILAS (14-10-2026, «¿y qué hacemos con el resto de las
	## filas?»): también personas reales, con la malla «lejos» (~60 vértices, las
	## mismas poses). El maniquí de 26 triángulos queda solo para calidad MEDIO.
	var reales_lejos := _hinchas_horneados("lejos")
	if not reales_lejos.is_empty() and not hinchas_xf.is_empty() and Calidad.elegida >= Calidad.ALTO:
		_montar_horneados(deck, "PersonasLejos", reales_lejos, hinchas_xf, hinchas_col)
		return
	if not det_xf.is_empty():
		var mmd := MultiMesh.new()
		mmd.transform_format = MultiMesh.TRANSFORM_3D
		mmd.use_colors = true
		mmd.mesh = _malla_hincha_detalle()
		mmd.instance_count = det_xf.size()
		for k in det_xf.size():
			mmd.set_instance_transform(k, det_xf[k])
			mmd.set_instance_color(k, det_col[k])
		var mat_d := ShaderMaterial.new()
		mat_d.shader = load("res://visor/hinchada.gdshader")
		## La malla de detalle tiene el cuello más arriba y pelo.
		mat_d.set_shader_parameter("cuello_desde", 0.535)
		mat_d.set_shader_parameter("cuello_hasta", 0.55)
		mat_d.set_shader_parameter("pelo_desde", 0.715)
		var mid := MultiMeshInstance3D.new()
		mid.multimesh = mmd
		mid.material_override = mat_d
		mid.name = "HinchadaCerca"
		mid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		deck.add_child(mid)
	if hinchas_xf.is_empty():
		return
	var mmh := MultiMesh.new()
	mmh.transform_format = MultiMesh.TRANSFORM_3D
	mmh.use_colors = true
	mmh.mesh = _malla_hincha_cache()
	mmh.instance_count = hinchas_xf.size()
	for k in hinchas_xf.size():
		mmh.set_instance_transform(k, hinchas_xf[k])
		mmh.set_instance_color(k, hinchas_col[k])
	## LA HINCHADA SE MUEVE Y TIENE CARA (23-9-2026). Ver `visor/hinchada.
	## gdshader` para el porqué de cada cosa: balanceo con fase propia, saltos
	## sueltos y la cabeza en tono de piel en vez de ser del color de la
	## camiseta. Cero coste por instancia -sigue siendo UN `MultiMesh` por
	## tribuna- y cero vértices nuevos.
	var mat_h := ShaderMaterial.new()
	mat_h.shader = load("res://visor/hinchada.gdshader")
	var mih := MultiMeshInstance3D.new()
	mih.multimesh = mmh
	mih.material_override = mat_h
	mih.name = "Hinchada"
	mih.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	deck.add_child(mih)

## LAS BOCAS DE ACCESO (23-9-2026). En `ea_fc25_referencia.mp4` la grada del
## fondo está picada de huecos oscuros: son los vomitorios por donde sale la
## gente, y sin ellos una tribuna se lee como un bloque macizo de público.
## Van en lo alto de la rampa -que es donde están en un estadio real- y también
## como hijos del `deck`, por el mismo motivo que los telones: la inclinación
## la pone el nodo, no una cuenta a mano.
static func _vomitorios(deck: MeshInstance3D, largo: float, fondo: float,
		lateral: bool) -> void:
	var boca := StandardMaterial3D.new()
	boca.albedo_color = Color(0.035, 0.04, 0.05)
	boca.roughness = 1.0
	## Uno cada ~26 m, que es el reparto real de un graderío.
	var cuantas: int = clampi(int(largo / 26.0), 2, 6)
	## Al borde de arriba y POR DEBAJO del borde del telón (0,32), para que las
	## dos capas no compitan -ver la nota de `_telones()`-.
	var d: float = fondo * 0.5 - 1.45
	for k in cuantas:
		var centro: float = -largo * 0.5 + largo * (float(k) + 0.5) / float(cuantas)
		var m := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(2.6, 3.0) if lateral else Vector2(3.0, 2.6)
		m.mesh = pm
		m.position = Vector3(d, 0.30, centro) if lateral else Vector3(centro, 0.30, d)
		m.material_override = boca
		m.name = "Vomitorio_%d" % k
		deck.add_child(m)
