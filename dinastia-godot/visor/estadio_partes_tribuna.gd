extends "res://visor/stadium_builder_p9.gd"
## [Capa de `stadium_builder.gd`] LAS ZONAS DE UNA TRIBUNA (FASE 0, 25-10-2026): el muro y el zócalo,
## el material de la grada, las bandejas con sus rampas y petos, el techo y el paño de fuera. Salieron
## de `build_1` (365 líneas de un tirón) sin cambiar nada de lo que se construye ni su orden: lo vigila
## `pruebas/ideas/f0b_huella.gd` (misma huella del árbol antes y después).

## Muro exterior del recinto (la fachada). El interior NO se rellena con una caja solida: si se hace,
## la rampa de asientos queda dentro de ella y el publico no se ve desde ninguna camara.
static func _muro_y_zocalo(obra: EstadioObra, t: EstadioObra.Tribuna) -> void:
	var root := obra.root
	var stand_mat := obra.stand_mat
	var muro_pos: Vector3 = t.pos + t.cara * (-t.fondo_s / 2.0 + 0.5)
	var muro_size := Vector3(1.0, t.alto_s, t.size.z) if t.lateral else Vector3(t.size.x, t.alto_s, 1.0)
	var pie: Vector3 = t.pos - t.cara * (t.fondo_s / 2.0 - FONDO_BANDEJA / 2.0)
	## EL TÚNEL ATRAVIESA ESTA TRIBUNA (7-10-2026, pedido: «la zona del
	## túnel debe ser más real; el estadio será navegable»). En la tribuna
	## del túnel (+Z) el muro, el zócalo y la primera bandeja se parten y
	## dejan un hueco de verdad: ahí va el pasillo de `TunelVestuario`.
	if t.hueco:
		var tunel_x0 := obra.tunel_x0
		for tr: Vector2 in _tramos_sin_hueco(t.pos.x, t.size.x, tunel_x0 - TUNEL_HUECO, tunel_x0 + TUNEL_HUECO):
			_box(root, Vector3(tr.x, muro_pos.y, muro_pos.z), Vector3(tr.y, t.alto_s, 1.0), stand_mat)
			_box(root, Vector3(tr.x, ALTURA_PIE / 2.0, pie.z), Vector3(tr.y, ALTURA_PIE, FONDO_BANDEJA), stand_mat)
		## Sobre la puerta del muro, el muro sigue.
		var alto_puerta: float = TunelVestuario.ALTO + 0.4
		if t.alto_s > alto_puerta:
			_box(root, Vector3(tunel_x0, (t.alto_s + alto_puerta) / 2.0, muro_pos.z),
				Vector3(TUNEL_HUECO * 2.0, t.alto_s - alto_puerta, 1.0), stand_mat)
	else:
		_box(root, muro_pos, muro_size, stand_mat)
		# Zocalo bajo la primera bandeja, para que no se vea el hueco desde el
		# campo. Va pegado a la cara interior, no al centro de la tribuna: con
		# varias bandejas el centro se va muy hacia atras.
		var zocalo_size := Vector3(FONDO_BANDEJA, ALTURA_PIE, t.size.z) if t.lateral \
			else Vector3(t.size.x, ALTURA_PIE, FONDO_BANDEJA)
		_box(root, Vector3(pie.x, ALTURA_PIE / 2.0, pie.z), zocalo_size, stand_mat)

## El material de la grada de esta tribuna. Si pidió un patrón de asiento propio, se genera SU PROPIA
## textura -misma función, mismos colores globales (esta fase no varía color por tribuna, solo patrón y
## techo), solo cambia `asiento_p`- en vez de reusar la compartida. Si no, sigue compartiendo
## `crowd_mat` como siempre: nada nuevo se genera para un estadio sin bandejas propias.
## TRAMO tiene prioridad sobre Bandeja cuando los dos aplican a la misma tribuna: 3 patrones dicen más
## que 1, y `_tramos_personalizados()` ya usó el patrón de Bandeja como base de los tercios en blanco,
## así que no se pierde la elección de Bandeja, se refina.
static func _material_grada(obra: EstadioObra, t: EstadioObra.Tribuna) -> StandardMaterial3D:
	var est := obra.est
	var est_s := t.est_s
	var lleno := clampf(obra.ocupacion, 0.05, 0.98)
	# La textura de graderio se repite cada ~20 m a lo largo. Sin esto se
	# estira sobre los 90 m de tribuna y el publico sale como churretones.
	var largo_tribuna: float = t.size.z if t.lateral else t.size.x
	var deck_mat: StandardMaterial3D
	if t.es_tramo:
		var trio := [_c(est_s.get("asiento1"), "#2b6b45"), _c(est_s.get("asiento2"), "#ffffff"),
			_c(est_s.get("asiento3"), "#20272a")]
		deck_mat = StandardMaterial3D.new()
		deck_mat.albedo_texture = _make_stand_texture_tramos(t.tramos_i,
			[trio, trio, trio], obra.seed_val, lleno)
		deck_mat.roughness = 1.0
		## Sin esto, esta textura queda con el filtro por defecto -no el
		## anisotropico que `crowd_mat` sí tiene (ver el bug real de
		## "estática de TV" del 21-9)-, y a la rasante con que se ve una
		## grada desde la cancha eso vuelve a hacer aliasing.
		deck_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	elif t.asiento_p != str(est_s.get("asientoP", "franjas")) or est_s != est:
		deck_mat = StandardMaterial3D.new()
		deck_mat.albedo_texture = _make_stand_texture(t.asiento_p,
			_c(est_s.get("asiento1"), "#2b6b45"), _c(est_s.get("asiento2"), "#ffffff"),
			_c(est_s.get("asiento3"), "#20272a"), obra.seed_val, lleno)
		deck_mat.roughness = 1.0
		## Mismo arreglo que arriba -este material tampoco lo heredaba de
		## `crowd_mat`, un vacío ya existente desde la Fase 1 (Bandeja,
		## 16-9), anterior al hallazgo del 21-9. Se corrige de paso.
		deck_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	else:
		deck_mat = obra.crowd_mat.duplicate()
	## El texto del spike lo advierte: la variante de tercios NO puede
	## reusar el repetido-cada-20m -convierte 2 costuras reales en ~13
	## falsas-, tiene que ir a repeticion 1 (la textura ya cubre la
	## tribuna entera, de punta a punta, sin repetir).
	var repite: float = 1.0 if t.es_tramo else maxf(1.0, largo_tribuna / 20.0)
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
	return deck_mat

## UNA RAMPA POR BANDEJA, no una sola para toda la tribuna. Cada una arranca mas arriba y mas atras que
## la de abajo, y entre ellas va un FRENTE vertical -el paño de palcos y pasillo de un estadio real, y
## la reja de donde cuelgan los trapos-.
static func _bandejas(obra: EstadioObra, t: EstadioObra.Tribuna, deck_mat: StandardMaterial3D) -> void:
	var subida_b := obra.subida_b
	var largo_deck: float = t.size.z - 1.0 if t.lateral else t.size.x - 1.0
	for b in t.niv_s:
		## El centro de ESTA bandeja, medido desde la cara interior de la
		## tribuna hacia afuera. `cara` apunta al campo, o sea que restarle
		## `cara` es alejarse de la cancha.
		var avance: float = float(b) * RETRANQUEO_BANDEJA + FONDO_BANDEJA / 2.0
		var centro_b: Vector3 = t.pos + t.cara * (t.fondo_s / 2.0) - t.cara * avance
		var y_pie: float = ALTURA_PIE + float(b) * (subida_b + FRENTE_BANDEJA)
		## La primera bandeja de la tribuna del túnel va en dos trozos.
		var piezas: Array = [Vector2(centro_b.x, largo_deck)]
		if t.hueco and b == 0:
			piezas = _tramos_sin_hueco(centro_b.x, largo_deck, obra.tunel_x0 - TUNEL_HUECO, obra.tunel_x0 + TUNEL_HUECO)
		for pz: Vector2 in piezas:
			_rampa(obra, t, deck_mat, b, pz, centro_b.z, y_pie, piezas.size() > 1)
		## El frente vertical bajo la bandeja: tapa el hueco que dejaria ver
		## por debajo y es lo que le da al estadio su perfil escalonado. La
		## primera bandeja no lo lleva -ahi va el zocalo.
		if b > 0:
			_peto(obra, t, centro_b, y_pie, largo_deck)

## Un trozo de rampa de la bandeja `b` (la losa inclinada con su material, sus butacas y sus telones).
static func _rampa(obra: EstadioObra, t: EstadioObra.Tribuna, deck_mat: StandardMaterial3D, b: int,
		pz: Vector2, centro_z: float, y_pie: float, partida: bool) -> void:
	var subida_b := obra.subida_b
	var largo_rake := sqrt(FONDO_BANDEJA * FONDO_BANDEJA + subida_b * subida_b)
	## El angulo CON SIGNO, que es el que hay que deshacer en las butacas y
	## los hinchas para que queden de pie (ver `_butacas()`). Sin el signo
	## la mitad de las tribunas quedaria con el publico inclinado el doble
	## en vez de derecho.
	var rake_firmado: float = obra.ang * (signf(-t.cara.x) if t.lateral else signf(t.cara.z))
	var est_s := t.est_s
	var deck := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(largo_rake, 0.4, pz.y) if t.lateral \
		else Vector3(pz.y, 0.4, largo_rake)
	deck.mesh = dm
	deck.position = Vector3(pz.x, y_pie + subida_b / 2.0, centro_z)
	deck.rotation = Vector3(0, 0, rake_firmado) if t.lateral \
		else Vector3(rake_firmado, 0, 0)
	## Cada bandeja lleva SU COPIA del material: comparten la misma
	## textura, pero un material compartido significaria que tocarle el
	## `uv1_*` a una se lo toca a las cinco.
	## COLOR POR ANILLO (28-9-2026): si este anillo de esta tribuna
	## tiene color propio, su textura y sus butacas salen con él.
	var niveles_col: Array = t.estilo.get("niveles", [])
	var col_b := String(niveles_col[b]) if b < niveles_col.size() else ""
	var est_b: Dictionary = est_s
	if col_b != "" and not t.es_tramo:
		est_b = est_s.duplicate()
		est_b["asiento1"] = col_b
		var mat_b := StandardMaterial3D.new()
		mat_b.albedo_texture = _make_stand_texture(t.asiento_p, _c(col_b, "#2b6b45"),
			_c(est_s.get("asiento2"), "#ffffff"), _c(est_s.get("asiento3"), "#20272a"), obra.seed_val + b,
			clampf(obra.ocupacion, 0.05, 0.98))
		mat_b.roughness = 1.0
		mat_b.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		mat_b.uv1_scale = deck_mat.uv1_scale
		mat_b.uv1_offset = deck_mat.uv1_offset
		deck.material_override = mat_b
	else:
		deck.material_override = deck_mat.duplicate()
	obra.root.add_child(deck)
	## Un trozo más corto repite la textura menos veces (misma densidad).
	if partida and not t.es_tramo and deck.material_override is StandardMaterial3D:
		var rp := maxf(1.0, pz.y / 20.0)
		(deck.material_override as StandardMaterial3D).uv1_scale.y = 2.0 * rp
		(deck.material_override as StandardMaterial3D).uv1_offset.y = -rp
	## EL SECTOR VISITANTE (M-021, 21-10): en la bandeja baja del fondo
	## −Z (enfrente del túnel), una esquina con los colores del rival.
	if est_b.has("visita1") and not t.lateral and t.pos.z < 0.0 and b == 0:
		est_b = est_b.duplicate()
		est_b["sector_visita"] = true
	_butacas(deck, dm.size, t.lateral, est_b, obra.ocupacion, t.alto_s, rake_firmado, b)
	_telones(deck, dm.size, t.lateral, est_s, obra.seed_val + t.i * 31 + b * 7)

## SOLO EL PETO, NO UNA PARED HASTA ABAJO (corregido con una captura, 23-9-2026). El primer intento le
## dio de alto `FRENTE_BANDEJA + subida_b` = 9,5 m, y el resultado era un muro negro colgando sobre la
## bandeja de abajo que se comía media tribuna. La cuenta real: entre el borde alto de una bandeja y el
## borde bajo de la siguiente hay exactamente `FRENTE_BANDEJA`, porque `y_pie` sube `subida_b + FRENTE`.
## Lo de debajo NO se tapa: es el voladizo, y debajo del voladizo hay butacas de la bandeja de abajo,
## que es justamente como se ve un estadio de varias bandejas.
static func _peto(obra: EstadioObra, t: EstadioObra.Tribuna, centro_b: Vector3, y_pie: float, largo_deck: float) -> void:
	var frente_pos: Vector3 = centro_b + t.cara * (FONDO_BANDEJA / 2.0 - 0.4)
	var frente_size := Vector3(0.8, FRENTE_BANDEJA, largo_deck) if t.lateral \
		else Vector3(largo_deck, FRENTE_BANDEJA, 0.8)
	_box(obra.root, Vector3(frente_pos.x, y_pie - FRENTE_BANDEJA / 2.0 + 0.2,
		frente_pos.z), frente_size, obra.stand_mat)
	## La cinta LED del peto (21-10-2026), mirando al campo.
	_cinta_led(obra.root, Vector3(frente_pos.x, y_pie - 1.1, frente_pos.z) + t.cara * 0.42, t.cara,
		largo_deck, obra.est)

## Lo que vuela el techo de un tipo. "total" promete "un anillo profundo que llega casi hasta la raya" y
## dibujaba EXACTAMENTE lo mismo que "anillo" -mismo material, mismas cabeceras, mismo vuelo de 4 m-: dos
## opciones del catalogo, las dos cobradas, pixel por pixel iguales. Ahora "total" vuela el doble, que es
## lo unico que promete.
static func _vuelo_techo(techo_i: String) -> float:
	return 7.0 if techo_i == "total" else (4.0 if techo_i == "anillo" else 2.0)

## El techo de esta tribuna (si su tipo lo cubre: las cabeceras solo con techo de anillo para arriba).
static func _techo_tribuna(obra: EstadioObra, t: EstadioObra.Tribuna) -> void:
	var techo_cabeceras_i := t.techo_i in ["anillo", "total", "membrana", "retractil", "visera"]
	var techo_lados_i := t.techo_i != "sin"
	t.quiere_techo = techo_cabeceras_i if t.i < 2 else techo_lados_i
	if not t.quiere_techo:
		return
	var vuelo := _vuelo_techo(t.techo_i)
	## BUG REAL DE Z-FIGHTING (23-9-2026): la losa de una cabecera y la
	## de un lateral ocupaban **el mismo volumen** en las 4 esquinas
	## -con el default son 8,5 x 8,5 m con la Y identica y el mismo
	## material-. Dos planos coincidentes parpadean, y encima justo
	## donde apuntan las camaras de dron y cenital. Se recorta la losa
	## de las CABECERAS para que acabe donde empieza la del lateral;
	## la esquina la cubre su propia losa, mas abajo.
	var recorte: float = 2.0 * (t.fondo_s / 2.0 + vuelo)
	var rs := Vector3(maxf(t.size.x + 2.0 - recorte, 4.0), 0.5, t.size.z + vuelo) if not t.lateral \
		else Vector3(t.size.x + vuelo, 0.5, t.size.z + 2.0)
	## Mismo criterio que el `roof_mat` global -ver `_techo_mat()`-. Solo
	## se pide un material nuevo cuando esta tribuna pidió un techo
	## distinto del global; si no, sigue compartiendo `roof_mat` tal
	## cual, igual que antes de esta fase.
	var roof_mat_i := obra.roof_mat if t.techo_i == obra.techo else _techo_mat(t.techo_i, obra.techo_col)
	marcar_techo(_box(obra.root, t.pos + t.cara * (vuelo / 2.0) + Vector3(0, t.alto_s / 2.0 + 0.4, 0), rs, roof_mat_i), -t.cara)

## El paño de fuera de esta tribuna. En la del túnel, el vestuario y el edificio del club ocupan su
## tramo: ahí no se viste nada.
static func _fachada_tribuna(obra: EstadioObra, t: EstadioObra.Tribuna) -> void:
	var n_fuera: Vector3 = -t.cara
	var largo_f: float = t.size.z if t.lateral else t.size.x
	var pie_f := Vector3(t.pos.x, 0.0, t.pos.z) + n_fuera * (t.fondo_s / 2.0)
	var cara_f := FachadaEstadio.cara(pie_f, n_fuera, largo_f, t.alto_s, "tribuna", t.quiere_techo,
		t.fondo_s + _vuelo_techo(t.techo_i), t.niv_s)
	var o_f: Vector3 = cara_f["o"]
	var u_f: Vector3 = cara_f["u"]
	if t.i == 0:
		var tx_v := tunel_x(obra.est)
		var s_a := (Vector3(tx_v - TunelVestuario.VEST_MEDIO - 0.8, 0, pie_f.z) - o_f).dot(u_f)
		var s_b := (Vector3(tx_v + TunelVestuario.VEST_MEDIO + 0.8, 0, pie_f.z) - o_f).dot(u_f)
		cara_f["excluir"] = [Vector2(minf(s_a, s_b), maxf(s_a, s_b))]
		## El escudo, al oeste del edificio del club: sobre las taquillas.
		cara_f["escudo"] = true
		cara_f["escudo_s"] = (Vector3(tx_v - TunelVestuario.VEST_MEDIO - 9.0, 0, pie_f.z) - o_f).dot(u_f)
	obra.caras_fachada.append(cara_f)
