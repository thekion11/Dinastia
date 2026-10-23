extends "res://visor/ciudad_expansion_p7.gd"
## [Capa 8/9 de `ciudad_expansion.gd`] _libre_farola, _textura_charco, _farolas, _mobiliario_urbano, _placas_de_calle, _orillas_nucleo … (+2)

func _libre_farola(nodo: Vector3, d: Vector3) -> float:
	var mc := medio_cruce(nodo, d)
	if mc <= 0.0:
		return 0.0
	return (fin_de_cebra(mc) if tiene_semaforo(nodo) else mc) + 5.0

func _textura_charco() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(float(x) - 31.5, float(y) - 31.5).length() / 32.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	return ImageTexture.create_from_image(img)

func _farolas() -> void:
	var postes: Array[Transform3D] = []
	var cabezas: Array[Transform3D] = []
	var charcos: Array[Transform3D] = []
	var conos: Array[Transform3D] = []
	## FAROLA CURVA DE KENNEY (15-10-2026): antes, un cilindro con una losa amarilla
	## encima. El brazo (+Z del modelo) da a la calzada; la luz, el charco y el cono
	## van en la punta del brazo, medida con la caja del modelo.
	var kf := _malla_kit("res://assets/ciudad/kenney_roads/light-curved.glb")
	var farolas_k: Array[Transform3D] = []
	var punta := Vector3(0, 8.0, 1.4)
	if not kf.is_empty():
		var cf: AABB = kf["caja"]
		var ef := 8.4 / maxf(cf.size.y, 0.01)
		punta = Vector3(0, cf.end.y * ef - 0.35, cf.end.z * ef * 0.88)
	for t: Dictionary in tramos:
		if bool(t["puente"]):
			continue
		var a: Vector3 = t["a"]
		var c: Vector3 = t["b"]
		var ancho: float = t["ancho"]
		var vertical := absf(a.x - c.x) < 0.1
		var largo := a.distance_to(c)
		var n := maxi(1, int(largo / 33.0))
		## (16-10-2026) Repartidas por el tramo libre entre cruces (antes la de la
		## punta caía junto a los bolardos de la esquina), en la franja del
		## bordillo para dejar libre el paso.
		var dd := (c - a).normalized()
		var la := _libre_farola(a, dd)
		var util := largo - la - _libre_farola(c, -dd)
		for q in n:
			var p := a + dd * (la + util * (float(q) + 0.5) / float(n))
			var lado := 1.0 if q % 2 == 0 else -1.0
			var off := (ancho * 0.5 + 0.6) * lado
			var base := p + (Vector3(off, 0, 0) if vertical else Vector3(0, 0, off))
			## Nunca plantada delante de un portal (16-10-2026: en los bloques
			## modulares del este una farola caía justo ante la puerta).
			for pm: Vector3 in _puertas_mod:
				var rel := pm - base
				var a_lo_largo := rel.dot(dd)
				if absf(a_lo_largo) < 3.2 and (rel - dd * a_lo_largo).length() < 12.0:
					var corre := (3.4 - absf(a_lo_largo)) * (-1.0 if a_lo_largo >= 0.0 else 1.0)
					p += dd * corre
					base += dd * corre
					break
			var dir := Vector3(-lado, 0, 0) if vertical else Vector3(0, 0, -lado)
			if kf.is_empty():
				postes.append(Transform3D(Basis.from_scale(Vector3(0.16, 8.0, 0.16)), base + Vector3(0, 4.0, 0)))
			else:
				var cf2: AABB = kf["caja"]
				var ef2 := 8.4 / maxf(cf2.size.y, 0.01)
				## Girar +Z del modelo hacia `dir`.
				var bas := Basis(Vector3.UP, atan2(dir.x, dir.z)).scaled(Vector3.ONE * ef2)
				farolas_k.append(Transform3D(bas, base + Vector3(0, 0.2, 0) - bas * Vector3(0, cf2.position.y, 0)))
			var luz := base + dir * punta.z + Vector3(0, punta.y, 0)
			cabezas.append(Transform3D(Basis.from_scale(Vector3(0.55, 0.12, 0.55)), luz))
			charcos.append(Transform3D(Basis.from_scale(Vector3(13.0, 1.0, 13.0)), Vector3(luz.x, 0.3, luz.z) + dir * 0.6))
			## Cono de luz: del farol al suelo, ancho abajo (10 m de diámetro).
			conos.append(Transform3D(Basis.from_scale(Vector3(10.0, luz.y - 0.3, 10.0)), Vector3(luz.x, luz.y * 0.5 + 0.1, luz.z)))
	var gris := b._mat_simple(Color(0.25, 0.26, 0.27), 0.5)
	_multimesh(CylinderMesh.new(), gris, postes, Vector3.ONE)
	if not farolas_k.is_empty():
		_multimesh(kf["malla"], null, farolas_k, Vector3.ONE)
	_multimesh(BoxMesh.new(), _mat_luz_farola(), cabezas, Vector3.ONE)
	_farola_charco = StandardMaterial3D.new()
	_farola_charco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_farola_charco.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_farola_charco.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_farola_charco.albedo_texture = _textura_charco()
	_farola_charco.albedo_color = Color(1.0, 0.75, 0.45, 0.0)
	var pl := PlaneMesh.new()
	pl.size = Vector2(1, 1)
	_multimesh(pl, _farola_charco, charcos, Vector3.ONE)
	## Los conos de luz: visibles solo al caer la noche (`encender`).
	var cono := CylinderMesh.new()
	cono.top_radius = 0.04
	cono.bottom_radius = 0.5
	cono.height = 1.0
	cono.cap_top = false
	cono.cap_bottom = false
	## Haz con degradado y sin contorno (`cono_farola.gdshader`).
	_farola_cono = ShaderMaterial.new()
	_farola_cono.shader = load("res://visor/cono_farola.gdshader")
	_multimesh(cono, _farola_cono, conos, Vector3.ONE)
	cuenta["farolas"] = postes.size()

## EL MOBILIARIO URBANO (7-10-2026, «agrega cosas que tiene una ciudad real…
## me gustan los detalles, el alcantarillado»): tapas de alcantarilla en los
## carriles, sumideros junto al bordillo, papeleras, bancos, hidrantes,
## contenedores de reciclaje, bolardos en las esquinas, señales de STOP y
## ceda el paso en las calles sin semáforo, kioscos y aparcabicis en las
## avenidas. Todo en lotes (MultiMesh): miles de piezas, pocas llamadas.
func _mobiliario_urbano() -> void:
	var cil := CylinderMesh.new()
	cil.height = 1.0
	cil.top_radius = 0.5
	cil.bottom_radius = 0.5
	cil.radial_segments = 12
	var octo := CylinderMesh.new()
	octo.height = 1.0
	octo.top_radius = 0.5
	octo.bottom_radius = 0.5
	octo.radial_segments = 8
	var caja := BoxMesh.new()
	var tapas: Array[Transform3D] = []
	var sumideros: Array[Transform3D] = []
	var papeleras: Array[Transform3D] = []
	var tapas_pap: Array[Transform3D] = []
	var hidrantes: Array[Transform3D] = []
	var bancos_a: Array[Transform3D] = []
	var bancos_p: Array[Transform3D] = []
	var contenedores: Array[Transform3D] = []
	var cont_col: Array[Color] = []
	var bolardos: Array[Transform3D] = []
	var postes: Array[Transform3D] = []
	var stops: Array[Transform3D] = []
	var cedas: Array[Transform3D] = []
	var kioscos: Array[Transform3D] = []
	var techos_k: Array[Transform3D] = []
	var bicis: Array[Transform3D] = []
	var mesas: Array[Transform3D] = []
	var patas: Array[Transform3D] = []
	var sombrillas: Array[Transform3D] = []
	var somb_col: Array[Color] = []
	var sillas_t: Array[Transform3D] = []
	var vallas: Array[Transform3D] = []
	var valla_col: Array[Color] = []
	var k_tramo := 0
	for t: Dictionary in tramos:
		k_tramo += 1
		if bool(t["puente"]):
			continue
		var a: Vector3 = t["a"]
		var c: Vector3 = t["b"]
		var ancho: float = t["ancho"]
		var largo := a.distance_to(c)
		if largo < 30.0:
			continue
		var dir := (c - a).normalized()
		var lat := Vector3(-dir.z, 0, dir.x)
		var giro := atan2(dir.x, dir.z)
		var rot := Basis(Vector3.UP, giro)
		## ACERA CON PASO LIBRE (16-10-2026): lo que se pone en la acera va
		## pegado al bordillo (≤1 m) o a la fachada (≥3 m); el medio (1,2-3 m) queda
		## libre para caminar y para la cámara de tercera persona, que va 5,5 m
		## detrás del personaje por la misma línea.
		var acera := ancho * 0.5 + 3.4
		## Alcantarillas: en el centro de cada carril, cada ~45 m.
		var n := int(largo / 45.0)
		for q in n:
			var p := a + dir * (largo * (float(q) + 0.5) / float(n))
			var carril := ancho * 0.25 * (1.0 if q % 2 == 0 else -1.0)
			tapas.append(Transform3D(Basis.from_scale(Vector3(0.9, 0.05, 0.9)), p + lat * carril + Vector3(0, 0.33, 0)))
		## Sumideros junto a los dos bordillos, cada 25 m.
		n = int(largo / 25.0)
		for q in n:
			var p := a + dir * (largo * (float(q) + 0.5) / float(n))
			for lado: float in [-1.0, 1.0]:
				sumideros.append(Transform3D(rot * Basis.from_scale(Vector3(0.45, 0.04, 1.0)), p + lat * lado * (ancho * 0.5 - 0.35) + Vector3(0, 0.32, 0)))
		## En la acera: papelera, banco e hidrante, alternando lados.
		n = int(largo / 55.0)
		for q in n:
			var f := (float(q) + 0.3) / float(maxi(n, 1))
			var lado := 1.0 if (q + k_tramo) % 2 == 0 else -1.0
			var p := a + dir * (largo * f) + lat * lado * acera
			papeleras.append(Transform3D(Basis.from_scale(Vector3(0.5, 0.95, 0.5)), p + Vector3(0, 0.75, 0)))
			tapas_pap.append(Transform3D(Basis.from_scale(Vector3(0.56, 0.08, 0.56)), p + Vector3(0, 1.26, 0)))
			if q % 2 == 1:
				var pb := a + dir * (largo * (f + 0.12)) + lat * lado * (ancho * 0.5 + 3.2)
				var rb := Basis(Vector3.UP, giro + (PI * 0.5 if lado > 0.0 else -PI * 0.5))
				bancos_a.append(Transform3D(rb * Basis.from_scale(Vector3(1.9, 0.08, 0.5)), pb + Vector3(0, 0.75, 0)))
				bancos_a.append(Transform3D(rb * Basis.from_scale(Vector3(1.9, 0.45, 0.07)), pb + Vector3(0, 1.0, 0) + lat * lado * 0.25))
				bancos_p.append(Transform3D(rb * Basis.from_scale(Vector3(0.08, 0.45, 0.45)), pb + Vector3(0, 0.5, 0) + dir * 0.8))
				bancos_p.append(Transform3D(rb * Basis.from_scale(Vector3(0.08, 0.45, 0.45)), pb + Vector3(0, 0.5, 0) - dir * 0.8))
			if q % 3 == 0:
				var ph := a + dir * (largo * (f + 0.06)) + lat * -lado * (ancho * 0.5 + 0.7)
				hidrantes.append(Transform3D(Basis.from_scale(Vector3(0.3, 0.75, 0.3)), ph + Vector3(0, 0.62, 0)))
				hidrantes.append(Transform3D(Basis.from_scale(Vector3(0.42, 0.12, 0.42)), ph + Vector3(0, 1.02, 0)))
				hidrantes.append(Transform3D(rot * Basis.from_scale(Vector3(0.62, 0.12, 0.12)), ph + Vector3(0, 0.8, 0)))
		## Contenedores de reciclaje (vidrio, envases, papel, resto), uno por tramo.
		if k_tramo % 2 == 0:
			var lado2 := 1.0 if k_tramo % 4 == 0 else -1.0
			var pc := a + dir * (largo * 0.62) + lat * lado2 * (ancho * 0.5 - 1.2)
			var colores := [Color(0.2, 0.55, 0.25), Color(0.95, 0.8, 0.15), Color(0.15, 0.35, 0.75), Color(0.35, 0.35, 0.35)]
			for i in 4:
				contenedores.append(Transform3D(rot * Basis.from_scale(Vector3(1.5, 1.5, 1.4)), pc + dir * (float(i) - 1.5) * 1.7 + Vector3(0, 1.05, 0)))
				cont_col.append(colores[i])
		## Las esquinas: bolardos en el borde de la acera.
		## (16-10-2026) Pasada la cebra, no donde la gente baja de ella.
		for punta: Array in [[a, dir], [c, -dir]]:
			var pn: Vector3 = punta[0]
			var hd: Vector3 = punta[1]
			var mc := medio_cruce(pn, hd)
			if mc <= 0.0:
				continue
			var extremo := pn + hd * ((fin_de_cebra(mc) if tiene_semaforo(pn) else mc) + 2.8)
			for lado: float in [-1.0, 1.0]:
				for i in 3:
					bolardos.append(Transform3D(Basis.from_scale(Vector3(0.22, 0.9, 0.22)), extremo + lat * lado * (ancho * 0.5 + 0.45) + hd * (float(i) - 1.0) * 1.3 + Vector3(0, 0.75, 0)))
		## Señal al final de las calles sin semáforo: STOP o ceda el paso.
		## (16-10-2026) Antes salía también en los cruces CON semáforo; ahora va en
		## la punta sin semáforo y en el lado derecho de quien llega a ella.
		var punta_sin := c if not tiene_semaforo(c) else (a if not tiene_semaforo(a) else Vector3.INF)
		if not bool(t["av"]) and punta_sin != Vector3.INF:
			var hacia := (punta_sin - (c if punta_sin == a else a)).normalized()
			var der := hacia.cross(Vector3.UP)
			var ps := punta_sin - hacia * (medio_cruce(punta_sin, hacia) + 7.0) + der * (ancho * 0.5 + 0.6)
			postes.append(Transform3D(Basis.from_scale(Vector3(0.08, 2.6, 0.08)), ps + Vector3(0, 1.6, 0)))
			var placa := Transform3D(Basis(Vector3.UP, atan2(hacia.x, hacia.z)) * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(0.75, 0.05, 0.75)), ps + Vector3(0, 2.95, 0) - hacia * 0.06)
			if k_tramo % 3 == 0:
				stops.append(placa)
			else:
				cedas.append(placa)
		## Terrazas de bar en las avenidas: mesas con sombrilla en la acera.
		if bool(t["av"]) and largo > 90.0 and k_tramo % 3 == 0:
			for i in 4:
				var pt := a + dir * (largo * 0.2 + float(i) * 3.2) - lat * (ancho * 0.5 + 2.8)
				mesas.append(Transform3D(Basis.from_scale(Vector3(0.9, 0.05, 0.9)), pt + Vector3(0, 0.95, 0)))
				patas.append(Transform3D(Basis.from_scale(Vector3(0.08, 0.7, 0.08)), pt + Vector3(0, 0.6, 0)))
				sombrillas.append(Transform3D(Basis.from_scale(Vector3(2.6, 0.5, 2.6)), pt + Vector3(0, 2.6, 0)))
				somb_col.append([Color(0.85, 0.2, 0.15), Color(0.95, 0.95, 0.9), Color(0.2, 0.45, 0.3), Color(0.95, 0.75, 0.2)][(k_tramo + i) % 4])
				for q in 2:
					sillas_t.append(Transform3D(Basis.from_scale(Vector3(0.45, 0.5, 0.45)), pt + dir * (0.9 if q == 0 else -0.9) + Vector3(0, 0.55, 0)))
		## Vallas publicitarias en algunos cruces de avenida.
		if bool(t["av"]) and k_tramo % 7 == 0:
			var pv := c - dir * (ancho * 0.5 + 20.0) + lat * (ancho * 0.5 + 5.0)
			postes.append(Transform3D(Basis.from_scale(Vector3(0.3, 6.0, 0.3)), pv + Vector3(0, 3.0, 0)))
			vallas.append(Transform3D(rot * Basis.from_scale(Vector3(0.3, 3.2, 7.0)), pv + Vector3(0, 7.2, 0)))
			valla_col.append(Color.from_hsv(fmod(float(k_tramo) * 0.13, 1.0), 0.6, 0.85))
		## En las avenidas: un kiosco y un aparcabicis por tramo largo.
		if bool(t["av"]) and largo > 90.0:
			var pk := a + dir * (largo * 0.4) + lat * (ancho * 0.5 + 2.75)
			kioscos.append(Transform3D(rot * Basis.from_scale(Vector3(2.4, 2.6, 2.0)), pk + Vector3(0, 1.6, 0)))
			techos_k.append(Transform3D(rot * Basis.from_scale(Vector3(2.6, 0.25, 2.8)), pk + Vector3(0, 3.05, 0)))
			for i in 5:
				bicis.append(Transform3D(rot * Basis.from_scale(Vector3(0.06, 0.8, 0.9)), a + dir * (largo * 0.7 + float(i) * 0.7) - lat * (ancho * 0.5 + 0.7) + Vector3(0, 0.7, 0)))
	var hierro := b._mat_simple(Color(0.14, 0.14, 0.15), 0.45)
	hierro.metallic = 0.6
	_multimesh(cil, hierro, tapas, Vector3.ONE)
	_multimesh(caja, b._mat_simple(Color(0.1, 0.1, 0.11), 0.5), sumideros, Vector3.ONE)
	_multimesh(cil, b._mat_simple(Color(0.2, 0.42, 0.25), 0.5), papeleras, Vector3.ONE)
	_multimesh(cil, b._mat_simple(Color(0.12, 0.12, 0.12), 0.5), tapas_pap, Vector3.ONE)
	_multimesh(cil, b._mat_simple(Color(0.85, 0.12, 0.1), 0.4), hidrantes, Vector3.ONE)
	_multimesh(caja, _mat["tronco"], bancos_a, Vector3.ONE)
	_multimesh(caja, hierro, bancos_p, Vector3.ONE)
	_multimesh(caja, null, contenedores, Vector3.ONE, cont_col)
	_multimesh(cil, b._mat_simple(Color(0.2, 0.2, 0.22), 0.5), bolardos, Vector3.ONE)
	_multimesh(cil, b._mat_simple(Color(0.6, 0.62, 0.64), 0.4), postes, Vector3.ONE)
	_multimesh(octo, b._mat_simple(Color(0.8, 0.08, 0.08), 0.5), stops, Vector3.ONE)
	var ceda_m := b._mat_simple(Color(0.95, 0.95, 0.95), 0.5)
	_multimesh(cil, ceda_m, cedas, Vector3.ONE)
	_multimesh(caja, b._mat_simple(Color(0.15, 0.4, 0.3), 0.6), kioscos, Vector3.ONE)
	_multimesh(caja, b._mat_simple(Color(0.1, 0.28, 0.22), 0.6), techos_k, Vector3.ONE)
	_multimesh(caja, hierro, bicis, Vector3.ONE)
	_multimesh(cil, b._mat_simple(Color(0.92, 0.92, 0.9), 0.4), mesas, Vector3.ONE)
	_multimesh(cil, hierro, patas, Vector3.ONE)
	var cono := CylinderMesh.new()
	cono.top_radius = 0.02
	cono.bottom_radius = 0.5
	cono.height = 1.0
	cono.radial_segments = 8
	_multimesh(cono, null, sombrillas, Vector3.ONE, somb_col)
	_multimesh(caja, b._mat_simple(Color(0.35, 0.25, 0.18), 0.6), sillas_t, Vector3.ONE)
	_multimesh(caja, b._mat_simple(Color(0.95, 0.95, 0.95), 0.4, 0.3), vallas, Vector3.ONE)
	if not vallas.is_empty():
		## El cartel de la valla: el color de cada anuncio, encima del marco.
		var anuncios: Array[Transform3D] = []
		for tv in vallas:
			anuncios.append(Transform3D(tv.basis * Basis.from_scale(Vector3(1.4, 0.88, 0.94)), tv.origin))
		_multimesh(caja, null, anuncios, Vector3.ONE, valla_col)
	cuenta["mobiliario"] = tapas.size() + sumideros.size() + papeleras.size() + hidrantes.size() / 3 + bancos_a.size() / 2 \
		+ contenedores.size() + bolardos.size() + postes.size() + kioscos.size() + bicis.size()

## Placas de calle en las esquinas: un poste con dos placas azules (una por
## calle), como en cualquier ciudad. Solo se dibujan de cerca.
func _placas_de_calle() -> void:
	var postes: Array[Transform3D] = []
	var placas: Array[Transform3D] = []
	var cuantas := 0
	for k: Vector2i in vecinos:
		var p: Vector3 = nodos[k]
		if dentro_nucleo(p.x, p.z, 20.0):
			continue
		var lista: Array = vecinos[k]
		var hay_fila := false
		var hay_col := false
		for v: Vector2i in lista:
			if v.y == k.y:
				hay_fila = true
			if v.x == k.x:
				hay_col = true
		var ax := (ANCHO_AV if k.x % 3 == 0 else ANCHO_CALLE) * 0.5 + 1.0
		var az := (ANCHO_AV if k.y % 3 == 0 else ANCHO_CALLE) * 0.5 + 1.0
		## En los cruces con semáforo la esquina +X+Z ya tiene el poste del
		## semáforo (13,2 m): la placa se va a la esquina -X+Z.
		var sx := -1.0 if tiene_semaforo(p) else 1.0
		var esquina := p + Vector3(ax * sx, 0, az)
		postes.append(Transform3D(Basis.from_scale(Vector3(0.09, 3.4, 0.09)), esquina + Vector3(0, 1.9, 0)))
		for cual in 2:
			if (cual == 0 and not hay_fila) or (cual == 1 and not hay_col):
				continue
			var texto := nombre_fila(k.y) if cual == 0 else nombre_columna(k.x)
			## La placa de la fila mira a lo largo de la fila (se lee desde la calle).
			var giro := 0.0 if cual == 0 else PI * 0.5
			var alto := 3.3 if cual == 0 else 2.75
			var centro := esquina + Vector3(0, alto, 0) + (Vector3(-1.2 * sx, 0, 0) if cual == 0 else Vector3(0, 0, -1.2))
			placas.append(Transform3D(Basis(Vector3.UP, giro) * Basis.from_scale(Vector3(2.4, 0.46, 0.05)), centro))
			for cara: float in [1.0, -1.0]:
				var l := Label3D.new()
				l.text = texto
				l.font_size = 34
				l.pixel_size = 0.0055
				l.modulate = Color.WHITE
				l.outline_size = 0
				l.width = 420.0
				l.autowrap_mode = TextServer.AUTOWRAP_OFF
				l.position = centro + Basis(Vector3.UP, giro) * Vector3(0, 0, 0.035 * cara)
				l.rotation.y = giro + (0.0 if cara > 0.0 else PI)
				l.visibility_range_end = 70.0
				b.add_child(l)
				cuantas += 1
	_multimesh(CylinderMesh.new(), b._mat_simple(Color(0.25, 0.27, 0.3), 0.5), postes, Vector3(1, 0.5, 1))
	var azul := b._mat_simple(Color(0.08, 0.22, 0.55), 0.4)
	_multimesh(BoxMesh.new(), azul, placas, Vector3.ONE)
	cuenta["placas_calle"] = cuantas / 2

## Las orillas del río a su paso por el núcleo: paseo y árboles en las dos
## márgenes, entre el anillo exterior y el bulevar.
func _orillas_nucleo() -> void:
	var rx := CityBuilder.RIO_X
	var pts: Array = []
	var z := NUC_Z0 + 20.0
	while z < NUC_Z1 - 20.0:
		if absf(z) > 30.0:   ## el puente del conector
			pts.append(Vector3(rx - 56.0, 0, z))
			pts.append(Vector3(rx + 56.0, 0, z))
		z += 26.0
	_arboles_en(pts, 0.9)
	for lado: float in [-1.0, 1.0]:
		_lote("acera", Vector3(rx + lado * 51.5, 0.1, (NUC_Z0 + NUC_Z1) * 0.5), Vector3(4.0, 0.2, NUC_Z1 - NUC_Z0))

func _prop_kenney(nombre: String, pos: Vector3, giro: float, esc: float = KENNEY_ESC) -> Node3D:
	var e: PackedScene = _kenney_cache.get(nombre)
	if e == null:
		e = load(KENNEY + nombre + ".glb")
		_kenney_cache[nombre] = e
	if e == null:
		return null
	var n: Node3D = e.instantiate()
	n.scale = Vector3.ONE * esc
	n.rotation.y = giro
	n.position = pos
	b.add_child(n)
	return n

## OBRAS EN LA CALLE: media calzada cortada con conos, vallas y una zanja.
## Una ciudad de verdad siempre tiene alguna calle levantada.
func _obras_en_calle() -> void:
	var cono := load("res://assets/ciudad/kenney_cars/cone.glb") as PackedScene
	if cono == null:
		return
	var n := 0
	var zanja := b._mat_simple(Color(0.35, 0.27, 0.2), 0.95)
	var valla := b._mat_simple(Color(0.95, 0.55, 0.1), 0.6)
	for t: Dictionary in tramos:
		if bool(t["av"]) or bool(t["puente"]) or _rng.randf() > 0.012:
			continue
		var a: Vector3 = t["a"]
		var c: Vector3 = t["b"]
		var vertical := absf(a.x - c.x) < 0.1
		var m := (a + c) * 0.5
		var lado := ANCHO_CALLE * 0.25
		var centro := m + (Vector3(lado, 0, 0) if vertical else Vector3(0, 0, lado))
		b._caja_en(centro + Vector3(0, 0.14, 0), Vector3(3.0, 0.06, 16.0) if vertical else Vector3(16.0, 0.06, 3.0), zanja)
		for k in 7:
			var f := float(k) / 6.0 - 0.5
			var p := centro + (Vector3(-lado * 0.9, 0, f * 20.0) if vertical else Vector3(f * 20.0, 0, -lado * 0.9))
			_kit(cono, p + Vector3(0, 0.14, 0), Vector3.ONE * 2.0, 0.0)
		var pv := centro + (Vector3(0, 0, 10.5) if vertical else Vector3(10.5, 0, 0))
		if _prop_kenney("construction-barrier", pv + Vector3(0, 0.14, 0), 0.0 if vertical else PI * 0.5, 14.0) == null:
			b._caja_en(pv + Vector3(0, 0.6, 0), Vector3(3.2, 1.0, 0.2) if vertical else Vector3(0.2, 1.0, 3.2), valla)
		_prop_kenney("construction-light", pv + (Vector3(1.6, 0.14, 0) if vertical else Vector3(0, 0.14, 1.6)), 0.0, 14.0)
		for k2 in 2:
			_prop_kenney("construction-fence", centro + (Vector3(1.8, 0.14, (float(k2) - 0.5) * 9.0) if vertical else Vector3((float(k2) - 0.5) * 9.0, 0.14, 1.8)), 0.0 if vertical else PI * 0.5, 12.0)
		n += 1
	cuenta["obras_calle"] = n
