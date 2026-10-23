extends "res://ui/componentes/interior_instalacion_p1.gd"
## (Parte 2 de 7 de `interior_instalacion.gd`.)

## Cierra la fachada (antes baja, para ver dentro) dejando un hueco de puerta de
## 3 m, y pone techo a toda la sala con sus plafones.
func _cerrar_para_pasear() -> void:
	var m := Mini3D.mat(_col_pared, 0.9)
	var zf := _tam.z * 0.5 + 0.15
	var lado := (_tam.x - 3.0) * 0.5
	for sx: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(sx * (1.5 + lado * 0.5), _tam.y * 0.5, zf), Vector3(lado, _tam.y, 0.3), m)
		## Zócalo también en la fachada, por dentro.
		Mini3D.caja(_raiz, Vector3(sx * (1.5 + lado * 0.5), 0.06, zf - 0.165), Vector3(lado, 0.12, 0.03), Mini3D.mat(_col_pared.darkened(0.35), 0.7))
	Mini3D.caja(_raiz, Vector3(0, (_tam.y + 2.6) * 0.5, zf), Vector3(3.0, _tam.y - 2.6, 0.3), m)
	## Techo entero y plafones donde están las luces.
	Mini3D.caja(_raiz, Vector3(0, _tam.y + 0.1, 0), Vector3(_tam.x + 0.6, 0.2, _tam.z + 0.6), Mini3D.mat(Color(0.94, 0.94, 0.92), 0.95))
	var plafon := Mini3D.mat(Color(1.0, 0.97, 0.9), 0.3, 2.0)
	for q: Vector3 in _luces:
		Mini3D.caja(_raiz, Vector3(q.x, _tam.y - 0.02, q.z), Vector3(1.2, 0.04, 0.6), plafon)
	## Marco de la puerta, felpudo y la claridad de la calle al otro lado.
	var marco := Mini3D.mat(Color(0.3, 0.2, 0.14), 0.6)
	for sx: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(sx * 1.55, 1.3, zf), Vector3(0.12, 2.6, 0.4), marco)
	Mini3D.caja(_raiz, Vector3(0, 2.6, zf), Vector3(3.2, 0.14, 0.4), marco)
	_poner("rugDoormat", Vector3(0, 0, zf - 0.6), 0.0, 2.4, {"carpet": Color(0.42, 0.2, 0.16), "carpetDarker": Color(0.3, 0.14, 0.1)})
	Mini3D.caja(_raiz, Vector3(0, 1.3, zf + 0.7), Vector3(3.2, 2.7, 0.05), Mini3D.mat(Color(0.86, 0.9, 0.95), 0.9, 0.9))
	_vaciar_lotes()
	## Luz de ambiente propia: aquí no hay sol.
	var luz := OmniLight3D.new()
	luz.position = Vector3(0, _tam.y - 0.8, 0)
	luz.omni_range = maxf(_tam.x, _tam.z) * 0.9
	luz.light_energy = 0.6
	luz.shadow_enabled = false
	_raiz.add_child(luz)

static func _textura_suelo(piso: String) -> Texture2D:
	if _texturas_suelo.has(piso):
		return _texturas_suelo[piso]
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(piso)
	match piso:
		"parquet":
			## 8 hileras de tablas de largo variable, con veta y junta oscura.
			for fila in 8:
				var x0 := rng.randi_range(0, 120)
				var x := -x0
				while x < n:
					var largo := rng.randi_range(90, 170)
					var tono := rng.randf_range(0.78, 1.0)
					var veta := rng.randf_range(0.0, 6.28)
					for px in range(maxi(x, 0), mini(x + largo, n)):
						for py in range(fila * 32, fila * 32 + 32):
							var v := tono * (0.94 + 0.06 * sin(float(px) * 0.09 + float(py) * 0.6 + veta))
							if py == fila * 32 or px == x:
								v *= 0.55
							img.set_pixel(px, py, Color(v, v, v))
					x += largo
		"losa":
			for i in 4:
				for j in 4:
					var tono := rng.randf_range(0.92, 1.0)
					for px in range(i * 64, i * 64 + 64):
						for py in range(j * 64, j * 64 + 64):
							var v := tono * rng.randf_range(0.97, 1.0)
							if px - i * 64 < 2 or py - j * 64 < 2:
								v = 0.62
							img.set_pixel(px, py, Color(v, v, v))
		"moqueta":
			for px in n:
				for py in n:
					var v := rng.randf_range(0.86, 1.0)
					img.set_pixel(px, py, Color(v, v, v))
		_:
			var ruido := FastNoiseLite.new()
			ruido.seed = 7
			ruido.frequency = 0.02
			for px in n:
				for py in n:
					var v := 0.88 + ruido.get_noise_2d(float(px), float(py)) * 0.1 + rng.randf_range(-0.03, 0.03)
					img.set_pixel(px, py, Color(v, v, v))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_texturas_suelo[piso] = t
	return t

## Material del suelo: una textura clara con el dibujo (tablas, baldosas,
## moqueta, hormigón) que el color tiñe. Se genera una vez por tipo.
static func _mat_suelo(piso: String, col: Color, tam: Vector3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.albedo_texture = _textura_suelo(piso)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var rep: float = {"parquet": 2.0, "losa": 2.4, "moqueta": 1.5, "hormigon": 6.0}.get(piso, 2.4)
	m.uv1_scale = Vector3(tam.x / rep, tam.z / rep, 1.0)
	m.roughness = {"parquet": 0.5, "losa": 0.35, "moqueta": 0.95, "hormigon": 0.8}.get(piso, 0.6)
	return m

# ------------------------------------------------------------------ la sala

## La caja de la sala a ESCALA HUMANA (15-10-2026: antes eran naves de 22-30 m
## con 5,5-7 m de techo y los muebles se perdían). Las paredes quedan FUERA de
## `tam` (su cara interior es el borde de la sala). `piso`: «parquet», «losa»,
## «moqueta» u «hormigon». `friso` (alfa > 0) pinta el metro bajo de las paredes.
func _sala(tam: Vector3, suelo: Color, pared: Color, piso: String = "losa", friso: Color = Color(0, 0, 0, 0)) -> void:
	_tam = tam
	_col_pared = pared
	var pm := PlaneMesh.new()
	pm.size = Vector2(tam.x, tam.z)
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = _mat_suelo(piso, suelo, tam)
	_raiz.add_child(mi)
	Mini3D.caja(_raiz, Vector3(0, -0.11, 0), Vector3(tam.x + 0.6, 0.2, tam.z + 0.6), Mini3D.mat(suelo.darkened(0.4), 0.9))
	var m := Mini3D.mat(pared, 0.9)
	var hx := tam.x * 0.5
	var hz := tam.z * 0.5
	## Fondo y laterales enteros; la fachada, baja, para ver dentro (al pasear
	## la cierra `_cerrar_para_pasear` con su puerta).
	Mini3D.caja(_raiz, Vector3(0, tam.y * 0.5, -hz - 0.15), Vector3(tam.x + 0.6, tam.y, 0.3), m)
	for lado: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(lado * (hx + 0.15), tam.y * 0.5, 0), Vector3(0.3, tam.y, tam.z), m)
	if not _paseo:
		Mini3D.caja(_raiz, Vector3(0, 0.5, hz + 0.15), Vector3(tam.x + 0.6, 1.0, 0.3), m)
	## Zócalo, friso y moldura del techo.
	var zoc := Mini3D.mat(pared.darkened(0.35), 0.7)
	Mini3D.caja(_raiz, Vector3(0, 0.06, -hz + 0.015), Vector3(tam.x, 0.12, 0.03), zoc)
	for lado: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(lado * (hx - 0.015), 0.06, 0), Vector3(0.03, 0.12, tam.z), zoc)
	if friso.a > 0.0:
		var fm := Mini3D.mat(friso, 0.75)
		Mini3D.caja(_raiz, Vector3(0, 0.55, -hz + 0.01), Vector3(tam.x, 1.1, 0.02), fm)
		for lado: float in [-1.0, 1.0]:
			Mini3D.caja(_raiz, Vector3(lado * (hx - 0.01), 0.55, 0), Vector3(0.02, 1.1, tam.z), fm)
		var listel := Mini3D.mat(friso.darkened(0.3), 0.6)
		Mini3D.caja(_raiz, Vector3(0, 1.11, -hz + 0.025), Vector3(tam.x, 0.04, 0.05), listel)
		for lado: float in [-1.0, 1.0]:
			Mini3D.caja(_raiz, Vector3(lado * (hx - 0.025), 1.11, 0), Vector3(0.05, 0.04, tam.z), listel)
	var mold := Mini3D.mat(pared.lightened(0.25), 0.8)
	Mini3D.caja(_raiz, Vector3(0, tam.y - 0.05, -hz + 0.04), Vector3(tam.x, 0.1, 0.08), mold)
	for lado: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(lado * (hx - 0.04), tam.y - 0.05, 0), Vector3(0.08, 0.1, tam.z), mold)
	## Lámparas en rejilla, una cada ~6 m; las dos primeras con sombra.
	_luces.clear()
	var nx := maxi(1, ceili(tam.x / 6.5))
	var nz := maxi(1, ceili(tam.z / 6.5))
	var sombras := 0
	for i in nx:
		for j in nz:
			var p := Vector3((float(i) + 0.5) / float(nx) * tam.x - hx, tam.y - 0.35, (float(j) + 0.5) / float(nz) * tam.z - hz)
			_luces.append(p)
			var o := OmniLight3D.new()
			o.position = p
			o.omni_range = maxf(tam.x / float(nx), tam.z / float(nz)) * 1.25 + tam.y
			o.light_energy = 0.75
			o.light_color = Color(1.0, 0.95, 0.86)
			o.shadow_enabled = sombras < 2 and nx * nz <= 6
			if o.shadow_enabled:
				sombras += 1
			_raiz.add_child(o)

## Medidas (m) de una pieza a la escala con la que se pone.
func _medida(nombre: String, escala: Variant = null) -> Vector3:
	return (_pieza(nombre)["caja"] as AABB).size * _escala_de(nombre, escala)

## Altura de la pelvis de pie (pose de reposo) respecto al origen de la persona,
## con las escalas de todos los nodos de por medio. 0 si no se encuentra.
static func _altura_cadera(nodo: Node3D) -> float:
	var esqueletos := nodo.find_children("*", "Skeleton3D", true, false)
	if esqueletos.is_empty():
		return 0.0
	var sk: Skeleton3D = esqueletos[0]
	var b := sk.find_bone("pelvis")
	if b < 0:
		b = sk.find_bone("Hips")
	if b < 0:
		return 0.0
	var t := sk.get_bone_global_rest(b)
	var n: Node = sk
	while n != null and n != nodo:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t.origin.y

# ------------------------------------------------------------------ gente

## Alguien en su puesto: quieto (o sentado) y de vez en cuando un gesto.
## Sentado: `p` es el CENTRO DEL ASIENTO a ras del suelo del mueble y `asiento`
## su altura. El clip «sentado» dobla las piernas pero deja la cadera a la altura
## de estar de pie (medido: la de la pose de reposo ×0,99), así que hay que bajar a cada uno
## según su esqueleto; antes se colocaban a ojo y quedaban sentados en el aire.
func _trabajador(p: Vector3, giro: float, sentado: bool, gestos: Array = ["charla", "saludo_mano", "brazos_jarra", "pedir_calma"], deporte: Array = [], asiento: float = 0.45) -> void:
	var d := Mini3D.persona(_raiz, _rng, p, deporte)
	if d.is_empty():
		return
	(d["nodo"] as Node3D).rotation.y = giro
	if sentado:
		var cadera := _altura_cadera(d["nodo"])
		if cadera > 0.0:
			(d["nodo"] as Node3D).position.y = p.y + asiento + 0.08 - cadera * 0.99
	Mini3D.anim(d, "sentado" if sentado else "parado", "")
	(d["anim"] as AnimationPlayer).seek(_rng.randf() * 0.5, true)
	_fijos.append({"d": d, "gestos": [] if sentado else gestos, "t": _rng.randf_range(1.0, 5.0), "base": "sentado" if sentado else "parado"})

## Un asiento del kit con gente: `plazas` son los desplazamientos laterales (m)
## de quien se sienta (vacío = libre). La persona queda en el centro del
## asiento medido del modelo, a su altura, mirando a `giro`.
func _asiento(nombre: String, p: Vector3, giro: float, plazas: Array = [0.0], deporte: Array = [], escala: Variant = null, tonos: Dictionary = {}) -> void:
	_poner(nombre, p, giro, escala, tonos)
	var a: Vector2 = _pieza(nombre)["asiento"]
	if a.x <= 0.0:
		return
	var s := _escala_de(nombre, escala)
	var f := Vector3(sin(giro), 0, cos(giro))
	var lado := Vector3(cos(giro), 0, -sin(giro))
	for x: float in plazas:
		## (+5 cm: con el clip «sentado» la pelvis queda 4-6 cm detrás del origen)
		var c := p + f * (a.y * s.z + 0.05) + lado * x
		_trabajador(c, giro, true, [], deporte, a.x * s.y)

## Un puesto de trabajo: mesa, ordenador y silla, con alguien sentado mirando a
## `giro` (la mesa queda delante de él). `p`: centro de la mesa.
func _puesto(p: Vector3, giro: float, pantalla: bool = true, ocupado: bool = true, deporte: Array = [], mesa: String = "desk") -> void:
	var f := Vector3(sin(giro), 0, cos(giro))
	var lado := Vector3(cos(giro), 0, -sin(giro))
	_poner(mesa, p, giro)
	var m := _medida(mesa)
	var arriba := Vector3(0, m.y, 0)
	if pantalla:
		_poner("computerScreen", p + arriba + f * (m.z * 0.18), giro + PI, 1.5)
		_poner("computerKeyboard", p + arriba - f * (m.z * 0.15), giro + PI, 1.6)
		_poner("computerMouse", p + arriba - f * (m.z * 0.15) + lado * 0.32, giro + PI, 1.6)
	else:
		_poner("books", p + arriba + lado * 0.3, giro + _rng.randf_range(-0.4, 0.4), 1.6)
	_poner("comida/mug", p + arriba - lado * (m.x * 0.32), _rng.randf() * TAU)
	_asiento("chairDesk", p - f * (m.z * 0.5 + 0.3), giro, [0.0] if ocupado else [], deporte)
# ------------------------------------------------------------------ recetas
## Todas con muebles de los kits (15-10-2026, pedido: «a ese nivel debe estar
## todo en la ciudad»). Convenciones: la puerta está en z = +fondo/2 y su paso
## (|x| < 2 y los 2,6 m de delante) queda libre para entrar caminando.

## Ropa de calle de un vecino cualquiera (dos colores al azar).
func _calle() -> Array:
	return [Color.from_hsv(_rng.randf(), _rng.randf_range(0.3, 0.6), _rng.randf_range(0.45, 0.8)), Color.from_hsv(_rng.randf_range(0.55, 0.7), 0.3, _rng.randf_range(0.2, 0.4))]

func _cartel(texto: String, pos: Vector3, tam: int = 64, col: Color = Color.WHITE, giro: float = 0.0) -> void:
	var l := Label3D.new()
	l.rotation.y = giro
	l.text = texto
	l.font_size = tam
	l.pixel_size = 0.01
	l.modulate = col
	l.outline_size = 8
	l.outline_modulate = Color(0, 0, 0, 0.7)
	l.position = pos
	_raiz.add_child(l)

## Mesa con sillas a lo largo de sus dos lados largos (X local) y gente sentada
## con probabilidad `ocupa`; un plato (y lo que se pida) delante de cada silla.
func _mesa_con_sillas(p: Vector3, giro: float, mesa: String, escala_mesa: Variant, por_lado: int, silla: String,
		ocupa: float, deporte: Array = [], plato: String = "comida/plate", encima: Array = [], tonos_silla: Dictionary = {}) -> void:
	_poner(mesa, p, giro, escala_mesa)
	var m := _medida(mesa, escala_mesa)
	var f := Vector3(sin(giro), 0, cos(giro))
	var lado := Vector3(cos(giro), 0, -sin(giro))
	for k in por_lado:
		var x := (float(k) + 0.5) / float(por_lado) * m.x - m.x * 0.5
		for s: float in [-1.0, 1.0]:
			## La silla mira a la mesa: la de −Z, hacia +Z (giro), y al revés.
			var c := p + lado * x + f * (s * (m.z * 0.5 + 0.2))
			var g := giro if s < 0.0 else giro + PI
			_asiento(silla, c, g, [0.0] if _rng.randf() < ocupa else [], deporte, null, tonos_silla)
			var sobre := p + lado * x + f * (s * (m.z * 0.5 - 0.22)) + Vector3(0, m.y, 0)
			if plato != "":
				_poner(plato, sobre, 0.0)
			if not encima.is_empty():
				_poner(String(encima[_rng.randi() % encima.size()]), sobre + lado * 0.2 + Vector3(0, 0.01, 0), _rng.randf() * TAU)

func _pantalla(p: Vector3, tam: Vector2, col: Color, giro: float = 0.0) -> MeshInstance3D:
	var marco := Mini3D.caja(_raiz, p, Vector3(tam.x + 0.08, tam.y + 0.08, 0.06), Mini3D.mat(Color(0.06, 0.06, 0.07), 0.3))
	marco.rotation.y = giro
	var mi := Mini3D.caja(_raiz, p + Vector3(sin(giro), 0, cos(giro)) * 0.035, Vector3(tam.x, tam.y, 0.01), Mini3D.mat(col, 0.2, 1.4))
	mi.rotation.y = giro
	return mi

## Una planta en maceta (las grandes de Kenney, con un poco de variedad).
func _planta(p: Vector3, grande: bool = true) -> void:
	## (escala por lotes de dos tamaños: si cada maceta tuviera la suya, cada una
	## sería un MultiMesh aparte)
	_poner("pottedPlant", p, _rng.randf() * TAU, 2.2 if grande else 1.5)

## Una ventana en una pared lateral (`lado` −1 izquierda, +1 derecha) centrada en
## `z`: cristal claro (la luz de fuera), marco, alféizar y, si se pide, las
## cortinas dobles de Quaternius.
func _ventana(lado: float, z: float, ancho: float = 1.6, cortinas: bool = true) -> void:
	var x := lado * (_tam.x * 0.5 - 0.02)
	var alto := minf(1.5, _tam.y - 1.3)
	var yc := 0.95 + alto * 0.5
	Mini3D.caja(_raiz, Vector3(x, yc, z), Vector3(0.03, alto, ancho), Mini3D.mat(Color(0.78, 0.88, 1.0), 0.2, 1.1))
	var marco := Mini3D.mat(Color(0.95, 0.95, 0.93), 0.5)
	for s: float in [-1.0, 1.0]:
		Mini3D.caja(_raiz, Vector3(x - lado * 0.03, yc, z + s * ancho * 0.5), Vector3(0.08, alto + 0.1, 0.08), marco)
		Mini3D.caja(_raiz, Vector3(x - lado * 0.03, yc + s * alto * 0.5, z), Vector3(0.08, 0.08, ancho), marco)
	Mini3D.caja(_raiz, Vector3(x - lado * 0.03, yc, z), Vector3(0.05, alto, 0.05), marco)
	Mini3D.caja(_raiz, Vector3(x - lado * 0.1, 0.93, z), Vector3(0.22, 0.05, ancho + 0.2), marco)
	if cortinas:
		var sy := minf(0.68, (_tam.y - 0.15) / 4.34)
		_poner("quaternius/cortinas_dobles", Vector3(x - lado * 0.22, 0, z), -lado * PI * 0.5, Vector3((ancho + 0.9) / 3.47, sy, 0.6))

## Alguien que va y viene entre varios puntos de la sala.
func _caminante(puntos: Array, deporte: Array = [], correr: bool = false) -> void:
	## Cada uno con su desvío y empezando en un punto distinto del recorrido:
	## si no, iban todos en fila india.
	var desvio := Vector3(_rng.randf_range(-0.8, 0.8), 0, _rng.randf_range(-0.8, 0.8))
	var pts: Array = []
	for q: Vector3 in puntos:
		pts.append(q + desvio)
	var i := _rng.randi() % pts.size()
	var siguiente := (i + 1) % pts.size()
	var inicio: Vector3 = (pts[i] as Vector3).lerp(pts[siguiente], _rng.randf())
	var d := Mini3D.persona(_raiz, _rng, inicio, deporte)
	if d.is_empty():
		return
	Mini3D.anim(d, "trotar" if correr else "caminar", "")
	(d["anim"] as AnimationPlayer).seek(_rng.randf(), true)
	_caminantes.append({"d": d, "puntos": pts, "i": siguiente, "espera": 0.0, "vel": (3.2 if correr else 1.3) * _rng.randf_range(0.85, 1.15), "clip": "trotar" if correr else "caminar"})

## Oficinas y Ayuntamiento (16 × 12 m): mostrador de atención con sus puestos,
## sillas para el público, mesa de reuniones (oficina) o banderas (ayuntamiento).
func _oficina() -> void:
	var ayto := clave.begins_with("ciudad_ayuntamiento")
	_tonos_sala = _MADERA_CLARA if not ayto else _MADERA_OSCURA
	if ayto:
		_sala(Vector3(16, 3.6, 12), Color(0.75, 0.7, 0.62), Color(0.92, 0.89, 0.82), "losa", Color(0.52, 0.38, 0.26))
	else:
		_sala(Vector3(16, 3.2, 12), Color(0.44, 0.47, 0.53), Color(0.92, 0.92, 0.9), "moqueta")
	## Los cuatro puestos de atención, de cara al público.
	for k in 4:
		var x := -4.5 + float(k) * 3.0
		_puesto(Vector3(x, 0, -3.4), 0.0)
		_asiento("chair", Vector3(x + 0.25, 0, -2.45), PI, [0.0] if _rng.randf() < 0.5 else [], _calle(), null, {"wood": Color(0.25, 0.27, 0.32)})
	## La cola de vecinos esperando turno.
	for k in 3:
		_trabajador(Vector3(1.6 + float(k) * 0.1, 0, -0.9 + float(k) * 0.8), PI, false, ["charla", "brazos_jarra", "cruzar_brazos"], _calle())
	## Archivo al fondo.
	for k in 4:
		_poner("bookcaseClosedWide", Vector3(-7.0 + float(k) * 1.62, 0, -5.75), 0.0, null, {"wood": Color(0.7, 0.72, 0.74)})
	_poner("cardboardBoxClosed", Vector3(-0.2, 0, -5.6), 0.3)
	_poner("cardboardBoxClosed", Vector3(0.25, 0, -5.65), -0.2)
	if ayto:
		for k in 3:
			var bandera := Mini3D.caja(_raiz, Vector3(3.0 + float(k) * 1.1, 2.3, -5.92), Vector3(0.9, 1.3, 0.03), Mini3D.mat([Color(0.8, 0.1, 0.1), Color(0.95, 0.8, 0.1), _c1][k], 0.6))
			bandera.rotation.z = 0.04
			Mini3D.cilindro(_raiz, Vector3(3.0 + float(k) * 1.1 - 0.47, 1.6, -5.85), 0.02, 3.0, Mini3D.mat(Color(0.8, 0.65, 0.3), 0.3))
		_cartel("🏛️ ATENCIÓN AL VECINO", Vector3(-3.0, 2.85, -5.95), 36)
		## Folletos y la máquina de turnos.
		_poner("mini_arcade/ticket-machine", Vector3(-3.6, 0, 5.0), PI)
	else:
		_cartel("💼 " + _sala_nombre().to_upper(), Vector3(4.2, 2.55, -5.95), 32)
		_mesa_con_sillas(Vector3(4.6, 0, 1.6), 0.0, "table", 2.2, 2, "chairModernCushion", 0.5, _calle(), "", ["laptop", "books", "comida/cup-coffee"])
		_pantalla(Vector3(7.96, 1.7, 1.6), Vector2(1.5, 0.85), Color(0.3, 0.5, 0.75), -PI * 0.5)
	## Dos puestos más contra la pared izquierda.
	for z: float in [-0.4, 1.8]:
		_puesto(Vector3(-7.5, 0, z), -PI * 0.5, true, true, [], "desk")
	## Zona de espera a la derecha (ayuntamiento) o al fondo.
	for k in 4:
		var z := -1.2 + float(k) * 0.62
		if ayto or k < 2:
			_asiento("chairCushion", Vector3(7.45, 0, z - (0.0 if ayto else 2.0)), -PI * 0.5, [0.0] if _rng.randf() < 0.45 else [], _calle())
	_poner("mini_arcade/vending-machine", Vector3(7.3, 0, 4.9), -PI * 0.5, 2.2)
	_planta(Vector3(-7.4, 0, 5.4))
	_planta(Vector3(7.4, 0, -5.4))
	_planta(Vector3(-7.4, 0, -5.4))
	_poner("trashcan", Vector3(3.2, 0, 5.6), 0.0, 1.4)
	_ventana(-1.0, 4.0)
	_caminante([Vector3(-5.2, 0, 3.6), Vector3(5.6, 0, 3.6), Vector3(5.6, 0, -1.4), Vector3(-5.2, 0, -1.4)])

func _alto(nombre: String, escala: Variant = null) -> float:
	return _medida(nombre, escala).y

## Hospital y centros médicos (22 × 14 m): camas con su mesilla y su monitor,
## cortinas entre camas, recepción con enfermeras y sala de espera.
func _hospital() -> void:
	_sala(Vector3(18, 3.6, 12), Color(0.8, 0.86, 0.86), Color(0.93, 0.97, 0.97), "losa", Color(0.55, 0.76, 0.78))
	var cama := {"carpet": Color(0.55, 0.75, 0.9), "wood": Color(0.86, 0.88, 0.9)}
	var largo_cama := _medida("bedSingle").z
	for k in 5:
		var x := -6.4 + float(k) * 3.2
		var zc := -6.0 + largo_cama * 0.5 + 0.1
		_poner("bedSingle", Vector3(x, 0, zc), 0.0, null, cama)
		_poner("cabinetBedDrawerTable", Vector3(x + 0.95, 0, -5.55), 0.0, null, {"wood": Color(0.86, 0.88, 0.9)})
		_poner("comida/glass", Vector3(x + 0.95, _alto("cabinetBedDrawerTable"), -5.55))
		## Monitor de constantes.
		var gris := Mini3D.mat(Color(0.7, 0.7, 0.72), 0.3)
		Mini3D.cilindro(_raiz, Vector3(x - 0.9, 0.75, -5.6), 0.03, 1.5, gris)
		Mini3D.caja(_raiz, Vector3(x - 0.9, 1.5, -5.6), Vector3(0.4, 0.3, 0.06), Mini3D.mat(Color(0.1, 0.4, 0.2), 0.3, 1.0))
		## Paciente sentado en el borde de la cama, con los pies colgando.
		if k % 2 == 0:
			var a: Vector2 = _pieza("bedSingle")["asiento"]
			_trabajador(Vector3(x - 0.3, 0, zc + 0.3), -PI * 0.5, true, [], [], a.x * 2.0)
		## Cortina entre camas, con su riel.
		if k < 4:
			Mini3D.caja(_raiz, Vector3(x + 1.6, 1.45, -4.8), Vector3(0.04, 2.3, 2.4), Mini3D.mat(Color(0.6, 0.8, 0.85, 0.85), 0.8))
			Mini3D.caja(_raiz, Vector3(x + 1.6, 2.65, -4.8), Vector3(0.05, 0.05, 2.5), gris)
	## Recepción.
	var esc_barra := 2.5
	var ancho := _medida("kitchenBar", esc_barra).x
	for k in 3:
		_poner("kitchenBar", Vector3(4.4 + float(k) * ancho, 0, 2.2), 0.0, esc_barra, {"wood": Color(0.9, 0.93, 0.94), "woodDark": Color(0.3, 0.55, 0.6)})
	_poner("computerScreen", Vector3(5.5, _alto("kitchenBar", esc_barra), 2.1), PI, 1.5)
	var enfermera := [Color(0.4, 0.7, 0.75), Color(0.4, 0.7, 0.75), true]
	_trabajador(Vector3(4.9, 0, 1.3), 0.0, false, ["charla", "pedir_calma", "saludo_mano"], enfermera)
	_trabajador(Vector3(6.3, 0, 1.3), 0.0, false, ["charla", "senalar_cielo"], enfermera)
	Mini3D.caja(_raiz, Vector3(5.5, 3.1, 2.2), Vector3(2.4, 0.45, 0.06), Mini3D.mat(Color(0.3, 0.55, 0.6), 0.6))
	_cartel("RECEPCIÓN", Vector3(5.5, 3.1, 2.25), 26)
	## Sala de espera: dos filas de sillas.
	for fila in 2:
		for k in 5:
			var p := Vector3(-7.6 + float(k) * 0.62, 0, 1.0 + float(fila) * 1.6)
			_asiento("chairModernCushion", p, 0.0, [0.0] if _rng.randf() < 0.4 else [], _calle(), null, {"carpet": Color(0.3, 0.5, 0.7)})
	_poner("mini_arcade/vending-machine", Vector3(-8.4, 0, 4.4), PI * 0.5, 2.2)
	_poner("trashcan", Vector3(-8.5, 0, 3.3), 0.0, 1.4)
	for p: Vector3 in [Vector3(8.4, 0, 5.4), Vector3(-8.4, 0, -1.2), Vector3(8.4, 0, -1.2)]:
		_planta(p)
	## Médicos de bata que pasan de cama en cama.
	for k in 2:
		var pts: Array = []
		for q in 5:
			pts.append(Vector3(-6.4 + float(q) * 3.2, 0, -2.5 + float(k) * 0.6))
		if k == 1:
			pts.reverse()
		_caminante(pts, [Color(0.96, 0.96, 0.97), Color(0.3, 0.45, 0.7), true])
	_cartel("➕ " + _sala_nombre().to_upper(), Vector3(0, 3.1, -5.95), 40, Color(0.25, 0.6, 0.4))
