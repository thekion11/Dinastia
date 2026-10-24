extends "res://visor/ciudad_expansion_p4.gd"
## [Capa 5/9 de `ciudad_expansion.gd`] _pisos, _escala_largo, _es_largo_x, _industrial, _cd, _detalle_casa … (+6)

func _pisos(r: Rect2) -> void:
	## Bloques de viviendas: el kit «de poco detalle» alto, en dos hileras con
	## patio en medio. Al este (16-10-2026) son BLOQUES MODULARES armados pieza a
	## pieza, cada uno distinto (`_bloque_modular`).
	if _naves.is_empty():
		return
	var c := Vector3(r.get_center().x, 0.2, r.get_center().y)
	var modular := c.x > 0.0 and not _mallas_mod().is_empty()
	for fila: float in [-1.0, 1.0]:
		for k in 3:
			var x := c.x + (float(k) - 1.0) * r.size.x * 0.3
			var s := 5.6 * _rng.randf_range(0.9, 1.1)
			var pos_p := Vector3(x, 0.2, c.z + fila * r.size.y * 0.27)
			## El azar se consume en el mismo orden que antes (modelo, escala y el
			## tinte de `_kit`), haya bloque modular o no: no se mueve nada más.
			var alto := not _altos.is_empty() and (k + int(fila > 0.0)) % 2 == 0
			var esc: PackedScene = _altos[_rng.randi() % _altos.size()] if alto else _naves[_rng.randi() % _naves.size()]
			var tam := Vector3.ONE * (_rng.randf_range(2.8, 3.6) if alto else s * 1.15)
			if modular:
				if _rng.randf() < 0.45:
					_rng.randi()
				var zf := r.end.y - 1.4 if fila > 0.0 else r.position.y + 1.4
				var puerta := _bloque_modular(Vector3(x, 0.24, zf), 0.0 if fila > 0.0 else PI, hash(Vector2(x, zf)), r.size.x * 0.3 - 4.0, r.size.y * 0.5 - 8.0)
				var fam: String = String(APELLIDOS[absi(hash(puerta)) % APELLIDOS.size()])
				b.puntos_clic.append({"k": "edificio_vivienda|Piso de la familia %s" % fam, "n": "Piso de la familia %s" % fam,
					"pos": Vector3(puerta.x, 0, zf + fila * 2.6), "estado": "ciudad", "radio": 6.0})
			else:
				_kit(esc, pos_p, tam, 0.0 if fila > 0.0 else PI, true)
	## El patio entre las dos hileras: césped, un camino y árboles.
	_lote("cesped", Vector3(c.x, 0.27, c.z), Vector3(r.size.x * 0.82, 0.06, r.size.y * 0.2))
	_lote("solar", Vector3(c.x, 0.3, c.z), Vector3(r.size.x * 0.82, 0.06, 2.4))
	var pts: Array = []
	for k in 5:
		pts.append(c + Vector3((float(k) - 2.0) * r.size.x * 0.17, -0.2, (5.5 if k % 2 == 0 else -5.5)))
	_arboles_en(pts, 0.8)

## La escala para que el lado largo de la pieza mida `metros`.
func _escala_largo(ruta: String, metros: float) -> float:
	var k := _malla_kit(ruta)
	if k.is_empty():
		return 1.0
	var caja: AABB = k["caja"]
	return metros / maxf(maxf(caja.size.x, caja.size.z), 0.01)

## ¿La pieza es más larga en X que en Z? (para girar los contenedores a lo largo de Z).
func _es_largo_x(ruta: String) -> bool:
	var k := _malla_kit(ruta)
	if k.is_empty():
		return false
	var caja: AABB = k["caja"]
	return caja.size.x > caja.size.z

func _industrial(r: Rect2) -> void:
	b._caja_en(Vector3(r.get_center().x, 0.06, r.get_center().y), Vector3(r.size.x, 0.12, r.size.y), b._mat_simple(Color(0.42, 0.42, 0.41), 0.9))
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	var color_nave: Color = [Color(0.62, 0.64, 0.66), Color(0.55, 0.5, 0.42), Color(0.5, 0.56, 0.6)][_rng.randi() % 3]
	var w := r.size.x * 0.62
	var f := r.size.y * 0.55
	var centro_nave := c + Vector3(-r.size.x * 0.12, 0.12, -r.size.y * 0.1)
	var h := absi(hash(Vector2(c.x, c.z)))
	var ruta_nave := RUTA_IND + "building-%s.glb" % NAVES[h % NAVES.size()]
	var kn := _malla_kit(ruta_nave)
	if kn.is_empty():
		## Sin el kit: la nave de cajas de antes.
		var nave := b._mat_simple(color_nave, 0.6)
		b._caja_en(c + Vector3(-r.size.x * 0.12, 5.0, -r.size.y * 0.1), Vector3(w, 10.0, f), nave)
		for k in 5:
			var d := b._caja_en(c + Vector3(-r.size.x * 0.12 - w * 0.4 + float(k) * w * 0.2, 11.2, -r.size.y * 0.1), Vector3(w * 0.18, 2.4, f), b._mat_simple(Color(0.4, 0.42, 0.45), 0.5))
			d.rotation.z = 0.35
	else:
		var caja: AABB = kn["caja"]
		## Que quepa en la parcela de la nave, sin pasar de ×10 (medida real).
		var esc := minf(10.0, minf(w / maxf(caja.size.x, 0.01), f / maxf(caja.size.z, 0.01)))
		## Sin `tenir`: está hecho para la paleta del kit comercial y en la del
		## industrial pintaba las naves de bloques de colores sin sentido.
		_pieza_kit(ruta_nave, centro_nave, esc, PI if h % 2 == 0 else 0.0)
	## Contenedores: tres pisos en tres filas, como antes.
	for k in 10:
		var p := c + Vector3(r.size.x * 0.32, 0.12 + float(k % 3) * 2.6, -r.size.y * 0.35 + float(k / 3) * 6.5)
		var tipo := _rng.randi() % 4
		var ruta_c := RUTA_IND + "shipping-container-%s.glb" % ["a", "b", "c", "a"][tipo]
		## Medida real: 6 m de largo (a ×7,4, como se propuso, salían bloques de 15 m
		## que parecían edificios con tuberías).
		if _pieza_kit(ruta_c, p, _escala_largo(ruta_c, 6.0), PI * 0.5 if _es_largo_x(ruta_c) else 0.0) == null:
			b._caja_en(p + Vector3(0, 1.18, 0), Vector3(2.5, 2.6, 6.0), b._mat_simple([Color(0.75, 0.2, 0.15), Color(0.15, 0.35, 0.7), Color(0.2, 0.55, 0.3), Color(0.85, 0.6, 0.15)][tipo], 0.6))
	if _rng.randf() < 0.5:
		var pc := c + Vector3(-r.size.x * 0.38, 0.12, r.size.y * 0.3)
		## ×4: a ×9 parecía una torre de refrigeración de 25 m de ancho.
		if _pieza_kit(RUTA_IND + "chimney-large.glb", pc, 4.0, 0.0) == null:
			b._cil_en(c + Vector3(-r.size.x * 0.38, 14.0, r.size.y * 0.3), 1.4, 28.0, b._mat_simple(Color(0.55, 0.3, 0.25), 0.8))
	cuenta["edificios"] = int(cuenta.get("edificios", 0)) + 1

func _cd(pos: Vector3, tam: Vector3, col: Color) -> void:
	_det_t.append(Transform3D(Basis.from_scale(tam), pos))
	_det_c.append(col)

func _detalle_casa(hr: RandomNumberGenerator, arq: int, x: float, z: float, zf: float, ancho: float,
		fondo: float, alto: float, lado: float, paso_x: float, col: Color, tejado: Color) -> void:
	var piedra := Color(0.72, 0.7, 0.66)
	var blanco := Color(0.96, 0.95, 0.92)
	var acento := [Color(0.15, 0.35, 0.3), Color(0.45, 0.18, 0.15), Color(0.2, 0.3, 0.5), Color(0.25, 0.25, 0.27), Color(0.55, 0.45, 0.2)][hr.randi() % 5] as Color
	## Escalones y umbral a la puerta.
	_cd(Vector3(x, 0.1, zf + lado * 0.55), Vector3(2.2, 0.2, 1.1), piedra)
	_cd(Vector3(x, 0.28, zf + lado * 0.25), Vector3(1.9, 0.2, 0.5), piedra)
	## Alféizares y contraventanas en cada ventana de la fachada.
	for k: float in [-1.0, 1.0]:
		for piso in (2 if alto > 6.2 else 1):
			var py := 1.6 + float(piso) * 2.8
			var px := x + k * ancho * 0.3
			_cd(Vector3(px, py - 0.8, zf + lado * 0.1), Vector3(1.95, 0.1, 0.28), blanco)
			for sx: float in [-1.0, 1.0]:
				_cd(Vector3(px + sx * 1.05, py, zf + lado * 0.05), Vector3(0.42, 1.5, 0.08), acento)
	## Ventanas en los laterales (antes eran paredes ciegas).
	for sx: float in [-1.0, 1.0]:
		for piso in (2 if alto > 6.2 else 1):
			var pl := Vector3(x + sx * (ancho * 0.5 + 0.05), 1.6 + float(piso) * 2.8, z + lado * fondo * 0.12)
			_marcos_t.append(Transform3D(Basis.from_scale(Vector3(0.1, 1.5, 1.7)), pl))
			_vidrios_t.append(Transform3D(Basis.from_scale(Vector3(0.12, 1.2, 1.4)), pl + Vector3(sx * 0.02, 0, 0)))
	## Parterres con flores a los lados de la puerta.
	for sx: float in [-1.0, 1.0]:
		_cd(Vector3(x + sx * 1.7, 0.18, zf + lado * 0.5), Vector3(1.2, 0.36, 0.6), Color(0.35, 0.22, 0.14))
		_cd(Vector3(x + sx * 1.7, 0.42, zf + lado * 0.5), Vector3(1.0, 0.12, 0.45), [Color(0.9, 0.3, 0.4), Color(0.95, 0.8, 0.2), Color(0.8, 0.4, 0.9)][hr.randi() % 3])
	## Aire acondicionado en un lateral de la planta alta.
	if hr.randf() < 0.5:
		_cd(Vector3(x + ancho * 0.5 + 0.25, alto * 0.6, z + lado * fondo * 0.1), Vector3(0.5, 0.6, 0.9), Color(0.8, 0.82, 0.84))
	match arq:
		0:  ## Chalet: un ala más baja al lado y una buhardilla en el tejado.
			_cd(Vector3(x + ancho * 0.62, alto * 0.3, z - lado * fondo * 0.08), Vector3(ancho * 0.5, alto * 0.6, fondo * 0.8), col * 0.96)
			_cd(Vector3(x + ancho * 0.62, alto * 0.6 + 0.2, z - lado * fondo * 0.08), Vector3(ancho * 0.56, 0.4, fondo * 0.88), tejado)
			_cd(Vector3(x - ancho * 0.15, alto + 1.5, zf - lado * 1.4), Vector3(1.8, 1.4, 1.4), col)
			_cd(Vector3(x - ancho * 0.15, alto + 2.3, zf - lado * 1.4), Vector3(2.1, 0.25, 1.7), tejado)
		1:  ## Adosado de azotea plana con parapeto.
			_cd(Vector3(x, alto + 0.12, z), Vector3(ancho + 0.4, 0.24, fondo + 0.4), piedra)
			for sz: float in [-1.0, 1.0]:
				_cd(Vector3(x, alto + 0.55, z + sz * (fondo * 0.5 + 0.1)), Vector3(ancho + 0.4, 0.6, 0.2), col * 0.92)
			for sx: float in [-1.0, 1.0]:
				_cd(Vector3(x + sx * (ancho * 0.5 + 0.1), alto + 0.55, z), Vector3(0.2, 0.6, fondo + 0.4), col * 0.92)
			## Valla blanca baja delante.
			var zv := zf + lado * 4.2
			_cd(Vector3(x, 0.78, zv), Vector3(paso_x * 0.8, 0.07, 0.06), blanco)
			for q in 9:
				_cd(Vector3(x - paso_x * 0.38 + float(q) * paso_x * 0.095, 0.4, zv), Vector3(0.06, 0.8, 0.06), blanco)
		2:  ## Con porche: tejadillo sobre columnas.
			_cd(Vector3(x, 2.95, zf + lado * 1.3), Vector3(3.4, 0.18, 2.6), tejado)
			for sx: float in [-1.0, 1.0]:
				_cd(Vector3(x + sx * 1.5, 1.45, zf + lado * 2.3), Vector3(0.16, 2.9, 0.16), blanco)
			_cd(Vector3(x, 0.08, zf + lado * 1.4), Vector3(3.4, 0.16, 2.6), piedra)
		3:  ## Con garaje y camino de entrada.
			_cd(Vector3(x - ancho * 0.66, 1.8, z + lado * fondo * 0.05), Vector3(ancho * 0.42, 3.6, fondo * 0.7), col * 0.95)
			_cd(Vector3(x - ancho * 0.66, 3.7, z + lado * fondo * 0.05), Vector3(ancho * 0.48, 0.25, fondo * 0.78), tejado)
			_cd(Vector3(x - ancho * 0.66, 1.15, z + lado * (fondo * 0.4 + 0.02)), Vector3(ancho * 0.34, 2.3, 0.1), Color(0.88, 0.88, 0.86))
			_cd(Vector3(x - ancho * 0.66, 0.1, z + lado * (fondo * 0.4 + 3.2)), Vector3(ancho * 0.34, 0.05, 6.4), Color(0.45, 0.45, 0.46))
		4:  ## Con balcón corrido en la planta alta.
			if alto > 6.2:
				_cd(Vector3(x, 4.35, zf + lado * 0.65), Vector3(ancho * 0.7, 0.15, 1.3), piedra)
				_cd(Vector3(x, 4.95, zf + lado * 1.25), Vector3(ancho * 0.7, 0.07, 0.07), blanco)
				for q in 8:
					_cd(Vector3(x - ancho * 0.33 + float(q) * ancho * 0.66 / 7.0, 4.7, zf + lado * 1.25), Vector3(0.06, 0.6, 0.06), blanco)
			else:
				_cd(Vector3(x, 2.7, zf + lado * 0.4), Vector3(ancho * 0.8, 0.5, 0.8), acento)  ## marquesina

func _casas(r: Rect2) -> void:
	_lote("cesped", Vector3(r.get_center().x, 0.05, r.get_center().y), Vector3(r.size.x, 0.1, r.size.y))
	var cols := 4
	var filas := 2
	var paso_x := r.size.x / float(cols)
	for fi in filas:
		var lado := -1.0 if fi == 0 else 1.0
		for ci in cols:
			var x := r.position.x + paso_x * (float(ci) + 0.5)
			var z := r.get_center().y + lado * r.size.y * 0.22
			var ancho := paso_x * 0.62
			var fondo := r.size.y * 0.24
			var alto := _rng.randf_range(5.0, 7.5)
			var col := COLORES_CASA[_rng.randi() % COLORES_CASA.size()] as Color
			_casas_t.append(Transform3D(Basis.from_scale(Vector3(ancho, alto, fondo)), Vector3(x, alto * 0.5, z)))
			_casas_col.append(col)
			var tejado := [Color(0.62, 0.28, 0.2), Color(0.35, 0.33, 0.33), Color(0.5, 0.36, 0.26)][_rng.randi() % 3] as Color
			## Cada casa es DISTINTA (etapa 6): el arquetipo y sus detalles salen
			## de la posición, no de `_rng`, para no mover nada más de sitio.
			var hr := RandomNumberGenerator.new()
			hr.seed = hash(Vector2(x, z))
			var arq := hr.randi() % 5
			if arq != 1:
				_techos_t.append(Transform3D(Basis.from_scale(Vector3(ancho + 1.0, 3.0, fondo + 1.0)), Vector3(x, alto + 1.5, z)))
				_techos_col.append(tejado)
			## Seto del jardín delantero, hacia la calle.
			var zs := z + lado * (fondo * 0.5 + 5.0)
			_setos_t.append(Transform3D(Basis.from_scale(Vector3(paso_x * 0.9 * 0.42, 1.3, 0.9)), Vector3(x - paso_x * 0.26, 0.65, zs)))
			_setos_t.append(Transform3D(Basis.from_scale(Vector3(paso_x * 0.9 * 0.42, 1.3, 0.9)), Vector3(x + paso_x * 0.26, 0.65, zs)))
			## La fachada que da a la calle: puerta, ventanas con marco, el
			## camino hasta la acera con su buzón, y la chimenea.
			var zf := z + lado * (fondo * 0.5 + 0.06)
			_puertas_t.append(Transform3D(Basis.from_scale(Vector3(1.3, 2.3, 0.12)), Vector3(x, 1.15, zf)))
			for k: float in [-1.0, 1.0]:
				for piso in (2 if alto > 6.2 else 1):
					var pv := Vector3(x + k * ancho * 0.3, 1.6 + float(piso) * 2.8, zf)
					_marcos_t.append(Transform3D(Basis.from_scale(Vector3(1.7, 1.5, 0.1)), pv))
					_vidrios_t.append(Transform3D(Basis.from_scale(Vector3(1.4, 1.2, 0.12)), pv + Vector3(0, 0, lado * 0.02)))
			var largo_c := absf(zs - zf)
			_caminos_t.append(Transform3D(Basis.from_scale(Vector3(1.6, 0.06, largo_c)), Vector3(x, 0.13, (zs + zf) * 0.5)))
			_buzones_t.append(Transform3D(Basis.from_scale(Vector3(0.45, 1.2, 0.35)), Vector3(x + 1.6, 0.6, zs)))
			if _rng.randf() < 0.6:
				_chimeneas_t.append(Transform3D(Basis.from_scale(Vector3(0.8, 2.6, 0.8)), Vector3(x + ancho * 0.28, alto + 2.0, z - lado * fondo * 0.15)))
			_detalle_casa(hr, arq, x, z, zf, ancho, fondo, alto, lado, paso_x, col, tejado)
			## El modelo del kit suburbano: por un hash propio de la posición, para no
			## tocar la secuencia de `_rng` ni de `hr` (todo lo demás sigue en su sitio).
			_kenney_casas.append({"m": absi(hash(Vector2(x, z) + Vector2(1.0, 7.0))) % MODELOS_CASA.size(),
				"x": x, "zf": zf, "lado": lado, "ancho_max": paso_x * 0.8, "col": col, "tejado": tejado})
			## Cada casa es un sitio al que entrar, con la familia que vive allí.
			var fam: String = String(APELLIDOS[hr.randi() % APELLIDOS.size()])
			b.puntos_clic.append({"k": "edificio_vivienda|Casa de la familia %s" % fam, "n": "Casa de la familia %s" % fam,
				"pos": Vector3(x, 0, zf + lado * 3.0), "estado": "ciudad", "radio": 6.0})
	cuenta["casas"] = int(cuenta.get("casas", 0)) + cols * filas

## La valla: postes y dos barras alrededor, con la entrada abierta al norte.
func _valla_feria(r: Rect2) -> void:
	var postes: Array[Transform3D] = []
	var barras: Array[Transform3D] = []
	var m := 0.6
	var esquinas := [Vector3(r.position.x + m, 0, r.position.y + m), Vector3(r.end.x - m, 0, r.position.y + m),
		Vector3(r.end.x - m, 0, r.end.y - m), Vector3(r.position.x + m, 0, r.end.y - m)]
	var cx := r.get_center().x
	for k in 4:
		var a: Vector3 = esquinas[k]
		var e: Vector3 = esquinas[(k + 1) % 4]
		var tramos_v: Array = [[a, e]]
		if k == 0:   ## lado norte: hueco de 10 m para la entrada
			tramos_v = [[a, Vector3(cx - 5.0, 0, a.z)], [Vector3(cx + 5.0, 0, a.z), e]]
		for tv: Array in tramos_v:
			var p0: Vector3 = tv[0]
			var p1: Vector3 = tv[1]
			var largo := p0.distance_to(p1)
			var n := maxi(1, int(largo / 2.4))
			for q in n + 1:
				postes.append(Transform3D(Basis.from_scale(Vector3(0.12, 1.3, 0.12)), p0.lerp(p1, float(q) / float(n)) + Vector3(0, 0.65, 0)))
			var dir := (p1 - p0).normalized()
			var base := Basis(Vector3.UP, atan2(dir.x, dir.z))
			for y: float in [0.55, 1.2]:
				barras.append(Transform3D(base * Basis.from_scale(Vector3(0.07, 0.07, largo)), (p0 + p1) * 0.5 + Vector3(0, y, 0)))
			## La valla no se salta: una huella fina a lo largo de cada tramo.
			b.huellas.append(Rect2(minf(p0.x, p1.x) - 0.15, minf(p0.z, p1.z) - 0.15, absf(p1.x - p0.x) + 0.3, absf(p1.z - p0.z) + 0.3))
	var verde := _mat_det("feria_valla", Color(0.12, 0.3, 0.2), 0.5)
	_multimesh(BoxMesh.new(), verde, postes, Vector3.ONE)
	_multimesh(BoxMesh.new(), _mat_det("feria_barra", Color(0.92, 0.9, 0.84), 0.5), barras, Vector3.ONE)

## La tela de las banderas de la feria: tres franjas horizontales con los dos
## colores del club, el más claro fuera (si los dos son oscuros, fuera va blanco).
func _franjas_club() -> ImageTexture:
	var c1 := b._color_club("c1", Color(0.9, 0.2, 0.2))
	var c2 := b._color_club("c2", Color(0.95, 0.95, 0.92))
	var claro := c1 if c1.get_luminance() >= c2.get_luminance() else c2
	var oscuro := c2 if claro == c1 else c1
	if claro.get_luminance() < 0.25:
		claro = Color(0.95, 0.95, 0.92)
	var img := Image.create(4, 24, false, Image.FORMAT_RGB8)
	for y in 24:
		for x in 4:
			img.set_pixel(x, y, oscuro if y >= 8 and y < 16 else claro)
	return ImageTexture.create_from_image(img)

## Un tramo de cable (cilindro de altura 1 a lo largo de su eje Y) de `a` a `c`.
static func _tramo_cable(a: Vector3, c: Vector3, grosor: float) -> Transform3D:
	var d := c - a
	var largo := maxf(d.length(), 0.001)
	var y := d / largo
	var x := y.cross(Vector3.UP if absf(y.y) < 0.99 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	return Transform3D(Basis(x * grosor * 2.0, y * largo, z * grosor * 2.0), (a + c) * 0.5)

func _animar(raiz: Node3D, anim: Animation, nombre: String) -> void:
	var lib := AnimationLibrary.new()
	lib.add_animation(nombre, anim)
	var ap := AnimationPlayer.new()
	ap.name = "Anim"
	ap.add_animation_library("", lib)
	ap.autoplay = nombre
	raiz.add_child(ap)

## LA NORIA: 20 m de diámetro, dieciséis barquillas que se mantienen
## colgadas mientras la rueda gira (una vuelta por minuto) y bombillas en los
## aros. Hecha a mano: el kit no trae noria. `p`: pie, en el centro.
func _noria(p: Vector3) -> void:
	var radio := 10.0
	var eje_y := radio + 3.4
	var acero := _mat_det("noria_acero", Color(0.92, 0.92, 0.94), 0.35)
	acero.metallic = 0.4
	## Huella de la plataforma: no se atraviesa a pie.
	b.huellas.append(Rect2(p.x - 4.0, p.z - 3.5, 8.0, 7.0))
	var raiz := Node3D.new()
	raiz.name = "Noria"
	raiz.position = p
	raiz.add_to_group("feria_animada")
	b.add_child(raiz)
	## Plataforma de embarque con escalera y la caseta del operario.
	Mini3D.caja(raiz, Vector3(0, 0.3, 0), Vector3(8.0, 0.6, 7.0), _mat_det("feria_plataforma", Color(0.55, 0.5, 0.46), 0.85))
	Mini3D.caja(raiz, Vector3(5.2, 1.3, 1.6), Vector3(2.0, 2.6, 2.0), _mat_det("feria_caseta", Color(0.95, 0.85, 0.4), 0.6))
	Mini3D.caja(raiz, Vector3(5.2, 2.7, 1.6), Vector3(2.4, 0.2, 2.4), _mat_det("feria_tejado", Color(0.8, 0.2, 0.18), 0.6))
	## Las dos patas en A a cada lado de la rueda y el eje.
	for sz: float in [-1.0, 1.0]:
		for sx: float in [-1.0, 1.0]:
			var pie := Vector3(sx * 5.5, 0.6, sz * 2.3)
			var arriba := Vector3(0, eje_y, sz * 1.5)
			var mi := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.22
			cm.bottom_radius = 0.32
			cm.height = 1.0
			mi.mesh = cm
			mi.material_override = acero
			mi.transform = _tramo_cable(pie, arriba, 0.25)
			raiz.add_child(mi)
	var eje := MeshInstance3D.new()
	var cme := CylinderMesh.new()
	cme.top_radius = 0.45
	cme.bottom_radius = 0.45
	cme.height = 3.6
	eje.mesh = cme
	eje.material_override = acero
	eje.rotation.x = PI * 0.5
	eje.position = Vector3(0, eje_y, 0)
	raiz.add_child(eje)
	## La rueda: dos aros, radios y bombillas (giran juntos).
	var rueda := Node3D.new()
	rueda.name = "Rueda"
	rueda.position = Vector3(0, eje_y, 0)
	raiz.add_child(rueda)
	for sz: float in [-1.2, 1.2]:
		var aro := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = radio - 0.18
		tm.outer_radius = radio + 0.18
		tm.rings = 48
		tm.ring_segments = 6
		aro.mesh = tm
		aro.material_override = acero
		aro.rotation.x = PI * 0.5
		aro.position.z = sz
		rueda.add_child(aro)
		var aro2 := MeshInstance3D.new()
		var tm2 := TorusMesh.new()
		tm2.inner_radius = radio * 0.55 - 0.1
		tm2.outer_radius = radio * 0.55 + 0.1
		tm2.rings = 32
		tm2.ring_segments = 5
		aro2.mesh = tm2
		aro2.material_override = acero
		aro2.rotation.x = PI * 0.5
		aro2.position.z = sz
		rueda.add_child(aro2)
	var n := 16
	var radios: Array[Transform3D] = []
	var luces: Array[Transform3D] = []
	for k in n:
		var a := TAU * float(k) / float(n)
		var dir := Vector3(cos(a), sin(a), 0)
		for sz: float in [-1.2, 1.2]:
			radios.append(_tramo_cable(Vector3(0, 0, sz * 0.4), dir * radio + Vector3(0, 0, sz), 0.07))
		for q in 3:
			var a2 := a + TAU / float(n) * float(q) / 3.0
			for sz: float in [-1.25, 1.25]:
				luces.append(Transform3D(Basis.from_scale(Vector3.ONE * 0.2), Vector3(cos(a2), sin(a2), 0) * (radio + 0.25) + Vector3(0, 0, sz)))
	var mmr := MultiMesh.new()
	mmr.transform_format = MultiMesh.TRANSFORM_3D
	mmr.mesh = CylinderMesh.new()
	mmr.instance_count = radios.size()
	for i in radios.size():
		mmr.set_instance_transform(i, radios[i])
	var mir := MultiMeshInstance3D.new()
	mir.multimesh = mmr
	mir.material_override = acero
	rueda.add_child(mir)
	var bombilla := StandardMaterial3D.new()
	bombilla.albedo_color = Color(1.0, 0.9, 0.6)
	bombilla.emission_enabled = true
	bombilla.emission = Color(1.0, 0.85, 0.5)
	bombilla.emission_energy_multiplier = 0.2
	_bombillas.append(bombilla)
	var mml := MultiMesh.new()
	mml.transform_format = MultiMesh.TRANSFORM_3D
	var esf := SphereMesh.new()
	esf.radial_segments = 6
	esf.rings = 3
	mml.mesh = esf
	mml.instance_count = luces.size()
	for i in luces.size():
		mml.set_instance_transform(i, luces[i])
	var mil := MultiMeshInstance3D.new()
	mil.multimesh = mml
	mil.material_override = bombilla
	rueda.add_child(mil)
	## Las barquillas: cuelgan de un pivote en el aro y la animación las gira al
	## revés que la rueda, así que siempre quedan derechas.
	var colores := [Color(0.85, 0.2, 0.2), Color(0.98, 0.78, 0.2), Color(0.2, 0.5, 0.88), Color(0.3, 0.7, 0.4)]
	var barquillas: Array[Node3D] = []
	for k in n:
		var a := TAU * float(k) / float(n)
		var piv := Node3D.new()
		piv.name = "Barquilla%d" % k
		piv.position = Vector3(cos(a), sin(a), 0) * radio
		rueda.add_child(piv)
		var mc := _mat_det("noria_barquilla_%d" % (k % colores.size()), colores[k % colores.size()], 0.5)
		Mini3D.caja(piv, Vector3(0, -0.5, 0), Vector3(0.12, 1.0, 0.12), acero)
		Mini3D.caja(piv, Vector3(0, -1.55, 0), Vector3(1.6, 1.1, 1.8), mc)
		Mini3D.caja(piv, Vector3(0, -0.92, 0), Vector3(1.9, 0.14, 2.1), mc)
		Mini3D.caja(piv, Vector3(0, -1.35, 0), Vector3(1.62, 0.5, 1.5), _mat_det("noria_cristal", Color(0.15, 0.2, 0.26), 0.15))
		barquillas.append(piv)
	## La animación: una vuelta por minuto.
	var anim := Animation.new()
	anim.length = 60.0
	anim.loop_mode = Animation.LOOP_LINEAR
	var t0 := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t0, NodePath("Rueda:rotation:z"))
	anim.track_insert_key(t0, 0.0, 0.0)
	anim.track_insert_key(t0, 60.0, -TAU)
	for k in n:
		var tk := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(tk, NodePath("Rueda/Barquilla%d:rotation:z" % k))
		anim.track_insert_key(tk, 0.0, 0.0)
		anim.track_insert_key(tk, 60.0, TAU)
	_animar(raiz, anim, "gira")
	feria["noria"] = raiz
