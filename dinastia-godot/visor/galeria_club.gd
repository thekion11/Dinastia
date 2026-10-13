class_name GaleriaClub
extends RefCounted
## LA GALERÍA SUBTERRÁNEA (estadio interactivo 2.0, fase 6).
##
## Pedido: «a futuro deben conectarse las instalaciones del club con el
## estadio, podría ser subterráneo». Desde el pasillo de la planta −2 del
## edificio del club (`EdificioClub`) sale un pasillo bajo la avenida y los
## campos de entrenamiento hasta el complejo de instalaciones; al final, una
## escalera mecánica sube a la calle, junto a la avenida y delante de la
## primera fila de edificios. También se entra desde arriba (la caseta de la
## escalera).
##
## Solo existe en la CIUDAD (el estadio suelto no tiene complejo al lado: allí
## la puerta queda cerrada con una persiana). Todo va en coordenadas del
## estadio, como las zonas de `TunelVestuario`; el tramo largo corre en +Z a la
## altura de la puerta del club y el corto en X hasta la escalera.

const PLANTA := -2
const MEDIO := 1.6
const ALTO := 3.2
## Mundo: dónde dobla (los campos acaban en z=70) y dónde sale (al este de la
## avenida, que ocupa |x| < 10).
const Z_CRUCE := 74.0
const X_SALIDA := 14.5
const LARGO_ESCALERA := 12.0
## La cinta rodante del tramo largo: se anda más deprisa.
const CINTA := 2.2

## La pone `CityBuilder` mientras levanta el estadio: con galería la puerta del
## sótano queda abierta.
static var en_ciudad := false

static func trazado(est: Dictionary) -> Dictionary:
	var o := CityBuilder.ESTADIO_EN
	var xa := float(est.get("x0", 0.0)) + TunelVestuario.PUERTA_X
	var xb := X_SALIDA - o.x
	## Si la puerta cae casi encima de la escalera, todo recto.
	if absf(xb - xa) < MEDIO * 2.0 + 1.0:
		xb = xa
	var zc := Z_CRUCE - o.z
	return {"xa": xa, "xb": xb, "z0": float(est.get("z_fin", 0.0)), "zc": zc,
		"z_esc": zc + MEDIO, "z_arriba": zc + MEDIO + LARGO_ESCALERA}

## Dónde se sale (y se entra) en la calle, en coordenadas del MUNDO.
static func boca_mundo(est: Dictionary) -> Vector3:
	var t := trazado(est)
	return CityBuilder.ESTADIO_EN + Vector3(float(t["xb"]), 0.0, float(t["z_arriba"]))

static func zonas(est: Dictionary) -> Array:
	var t := trazado(est)
	var xa: float = t["xa"]
	var xb: float = t["xb"]
	var zc: float = t["zc"]
	var z0: float = t["z0"]
	var m := MEDIO - 0.3
	var sal: Array = []
	## La escalera primero: gana al pisar.
	sal.append({"nombre": "Escalera de la galería", "planta": PLANTA, "techo": ALTO,
		"r": Rect2(xb - 1.0, float(t["z_esc"]) - 0.6, 2.0, 4.6)})
	sal.append({"nombre": "Galería", "planta": PLANTA, "techo": ALTO,
		"r": Rect2(xa - m, z0 - 1.0, m * 2.0, zc + m - (z0 - 1.0))})
	if xb != xa:
		sal.append({"nombre": "Galería", "planta": PLANTA, "techo": ALTO,
			"r": Rect2(minf(xa, xb) - m, zc - m, absf(xb - xa) + m * 2.0, m * 2.0)})
	return sal

## ¿Ya arriba del todo de la escalera? (coordenadas del estadio)
static func arriba(est: Dictionary, local: Vector3) -> bool:
	var t := trazado(est)
	return absf(local.x - float(t["xb"])) < 1.2 and local.z > float(t["z_esc"]) + 3.4

## Donde aparece quien baja desde la calle (coordenadas del estadio).
static func pie_de_escalera(est: Dictionary) -> Vector3:
	var t := trazado(est)
	return Vector3(float(t["xb"]), RecorridoClub.y_de(PLANTA), float(t["z_esc"]) + 0.6)

## Cuánto ha subido la escalera mecánica a esta z (coordenadas del estadio):
## la cámara va por encima de los peldaños, no dentro de la rampa.
static func alto_rampa(est: Dictionary, z_local: float) -> float:
	var t := trazado(est)
	var sube := -float(PLANTA) * EdificioClub.ALTO_PLANTA
	return clampf((z_local - float(t["z_esc"])) / LARGO_ESCALERA, 0.0, 1.0) * sube

static func metros_hasta(est: Dictionary, local: Vector3) -> int:
	var t := trazado(est)
	return int(absf(float(t["zc"]) - local.z) + absf(float(t["xb"]) - local.x))

# ============================================================== EL MONTAJE

## Bajo tierra, dentro del nodo del estadio (`padre`, coordenadas del estadio).
static func montar(padre: Node3D, est: Dictionary, c1: Color, c2: Color, nombre_club: String) -> void:
	var t := trazado(est)
	var xa: float = t["xa"]
	var xb: float = t["xb"]
	var zc: float = t["zc"]
	var z0: float = t["z0"]
	var y := float(PLANTA) * EdificioClub.ALTO_PLANTA
	var s := signf(xb - xa)
	var nodo := Node3D.new()
	nodo.name = "GaleriaClub"
	padre.add_child(nodo)
	var horm := TunelVestuario._mat(Color(0.42, 0.42, 0.44), 0.95)
	var suelo := TunelVestuario._mat(Color(0.72, 0.72, 0.7), 0.55)
	var pared := TunelVestuario._mat(Color(0.93, 0.93, 0.9), 0.8)
	var franja := TunelVestuario._mat(c1, 0.5)
	var franja2 := TunelVestuario._mat(c2.lerp(Color.WHITE, 0.15), 0.5)
	var techo := TunelVestuario._mat(Color(0.86, 0.86, 0.84), 0.9)
	var luz := StandardMaterial3D.new()
	luz.albedo_color = Color(1, 0.98, 0.9)
	luz.emission_enabled = true
	luz.emission = Color(1, 0.97, 0.88)
	luz.emission_energy_multiplier = 2.2
	## Los dos tramos: suelo, techo y paredes con la franja del club.
	var largo_a := zc + MEDIO - z0
	_tramo(nodo, Vector3(xa, y, z0 + largo_a / 2.0), Vector2(MEDIO * 2.0, largo_a), horm, suelo, techo)
	if s != 0.0:
		var largo_b := absf(xb - xa) + MEDIO * 2.0
		_tramo(nodo, Vector3((xa + xb) / 2.0, y, zc), Vector2(largo_b, MEDIO * 2.0), horm, suelo, techo)
	## Paredes del tramo largo. La del lado del giro se corta donde empieza el
	## corto; la del otro lado llega hasta el fondo.
	var lado_giro := s if s != 0.0 else 1.0
	for lado in [-1.0, 1.0]:
		var z_hasta := zc - MEDIO if (s != 0.0 and lado == lado_giro) else zc + MEDIO
		_muro_z(nodo, xa + lado * (MEDIO + 0.15), z0, z_hasta, y, horm, pared, franja, franja2, -lado)
	if s != 0.0:
		## El tramo corto: pared del cruce (lado de los campos) y la de enfrente,
		## con el hueco de la escalera; el fondo cierra al otro lado.
		_muro_x(nodo, zc - MEDIO - 0.15, xa + s * MEDIO, xb + s * MEDIO, y, horm, pared, franja, franja2, 1.0)
		var a := xa - s * MEDIO
		var b := xb - s * 1.2
		_muro_x(nodo, zc + MEDIO + 0.15, a, b, y, horm, pared, franja, franja2, -1.0)
		_muro_x(nodo, zc + MEDIO + 0.15, xb + s * 1.2, xb + s * (MEDIO + 0.3), y, horm, pared, franja, franja2, -1.0)
		_muro_z(nodo, xb + s * (MEDIO + 0.15), zc - MEDIO - 0.3, zc + MEDIO + 0.3, y, horm, pared, franja, franja2, -s)
	else:
		for lado2 in [-1.0, 1.0]:
			_muro_x(nodo, zc + MEDIO + 0.15, xa + lado2 * 1.2, xa + lado2 * (MEDIO + 0.3), y, horm, pared, franja, franja2, -1.0)
	## La cinta rodante por el centro del tramo largo, con bordes amarillos.
	var cinta := TunelVestuario._mat(Color(0.16, 0.16, 0.18), 0.4)
	var borde := TunelVestuario._mat(Color(0.95, 0.8, 0.15), 0.5)
	var c0 := z0 + 3.0
	var c_fin := zc - MEDIO - 2.0
	if c_fin > c0 + 4.0:
		TunelVestuario._caja(nodo, Vector3(xa, y + 0.06, (c0 + c_fin) / 2.0), Vector3(1.4, 0.08, c_fin - c0), cinta, false)
		for lado3 in [-1.0, 1.0]:
			TunelVestuario._caja(nodo, Vector3(xa + lado3 * 0.74, y + 0.07, (c0 + c_fin) / 2.0), Vector3(0.08, 0.1, c_fin - c0), borde, false)
		for zz in [c0, c_fin]:
			TunelVestuario._caja(nodo, Vector3(xa, y + 0.065, zz), Vector3(1.6, 0.09, 0.2), borde, false)
	## Luz: tiras en el techo cada 8 m y una lámpara de verdad cada 16.
	var k := 0
	var zl := z0 + 2.0
	while zl < zc + MEDIO - 1.0:
		TunelVestuario._caja(nodo, Vector3(xa, y + ALTO - 0.04, zl), Vector3(1.2, 0.04, 0.3), luz, false)
		if k % 2 == 0:
			_lampara(nodo, Vector3(xa, y + ALTO - 0.4, zl))
		k += 1
		zl += 8.0
	if s != 0.0:
		var xl := xa + s * 6.0
		while (xb - xl) * s > -1.0:
			TunelVestuario._caja(nodo, Vector3(xl, y + ALTO - 0.04, zc), Vector3(0.3, 0.04, 1.2), luz, false)
			_lampara(nodo, Vector3(xl, y + ALTO - 0.4, zc))
			xl += s * 9.0
	## Rótulos con la distancia, en las dos direcciones, y paneles del club en
	## las paredes (como una galería de verdad: es lo que la hace del club).
	var total := int(largo_a + absf(xb - xa))
	var zr := z0 + 10.0
	var n_panel := 0
	var paneles := [Idiomas.t("CANTERA"), nombre_club.to_upper(), Idiomas.t("CIUDAD DEPORTIVA"), Idiomas.t("AFICIÓN"), Idiomas.t("HISTORIA")]
	while zr < zc - MEDIO - 4.0:
		var falta := total - int(zr - z0)
		TunelVestuario._rotulo(nodo, "⇢ %s · %d m" % [Idiomas.t("COMPLEJO DEL CLUB"), falta],
			Vector3(xa, y + ALTO - 0.55, zr), PI, 30, Color(0.15, 0.16, 0.2))
		TunelVestuario._rotulo(nodo, "⇠ %s · %d m" % [Idiomas.t("ESTADIO"), int(zr - z0)],
			Vector3(xa, y + ALTO - 0.55, zr + 0.05), 0.0, 30, Color(0.15, 0.16, 0.2))
		## Un panel a cada lado, alternando los colores del club.
		for lado4 in [-1.0, 1.0]:
			var col: Color = c1 if (n_panel % 2 == 0) == (lado4 < 0.0) else c2
			var px: float = xa + lado4 * (MEDIO - 0.02)
			TunelVestuario._caja(nodo, Vector3(px, y + 1.75, zr + 4.0), Vector3(0.04, 1.3, 3.2), TunelVestuario._mat(col, 0.6), false)
			var l := Label3D.new()
			l.text = String(paneles[n_panel % paneles.size()])
			l.font_size = 44
			l.pixel_size = 0.006
			l.outline_size = 6
			l.modulate = Color.WHITE if col.get_luminance() < 0.6 else Color(0.08, 0.08, 0.1)
			l.position = Vector3(px - lado4 * 0.04, y + 1.75, zr + 4.0)
			l.rotation.y = -lado4 * PI / 2.0
			nodo.add_child(l)
		n_panel += 1
		zr += 18.0
	## La entrada desde el edificio: pórtico con el nombre.
	TunelVestuario._rotulo(nodo, Idiomas.t("GALERÍA DEL CLUB · AL COMPLEJO"),
		Vector3(xa, y + ALTO - 0.4, z0 + 0.35), PI, 34, c1.lerp(Color(0.08, 0.08, 0.1), 0.3))
	## La escalera mecánica hasta la calle (8 m de subida en 12 de largo).
	_escalera(nodo, Vector3(xb, y, float(t["z_esc"])), c1, horm, pared)

static func _tramo(nodo: Node3D, centro: Vector3, tam: Vector2, horm: Material, suelo: Material, techo: Material) -> void:
	TunelVestuario._caja(nodo, centro + Vector3(0, -0.15, 0), Vector3(tam.x + 0.6, 0.3, tam.y), horm, true)
	TunelVestuario._caja(nodo, centro + Vector3(0, 0.015, 0), Vector3(tam.x, 0.02, tam.y), suelo, false)
	TunelVestuario._caja(nodo, centro + Vector3(0, ALTO + 0.2, 0), Vector3(tam.x + 0.6, 0.4, tam.y), horm, true)
	TunelVestuario._caja(nodo, centro + Vector3(0, ALTO - 0.01, 0), Vector3(tam.x, 0.02, tam.y), techo, false)

## Pared a lo largo de Z (en `x`), con su cara interior hacia `hacia` (±1 en X).
static func _muro_z(nodo: Node3D, x: float, z_a: float, z_b: float, y: float, horm: Material, pared: Material,
		franja: Material, franja2: Material, hacia: float) -> void:
	var largo := absf(z_b - z_a)
	if largo < 0.05:
		return
	var zm := (z_a + z_b) / 2.0
	TunelVestuario._caja(nodo, Vector3(x, y + ALTO / 2.0, zm), Vector3(0.3, ALTO, largo), horm, true)
	var xi := x + hacia * 0.16
	TunelVestuario._caja(nodo, Vector3(xi, y + ALTO / 2.0, zm), Vector3(0.02, ALTO, largo), pared, false)
	TunelVestuario._caja(nodo, Vector3(xi + hacia * 0.01, y + 1.05, zm), Vector3(0.02, 0.18, largo), franja, false)
	TunelVestuario._caja(nodo, Vector3(xi + hacia * 0.01, y + 0.86, zm), Vector3(0.02, 0.08, largo), franja2, false)
	TunelVestuario._caja(nodo, Vector3(xi + hacia * 0.01, y + 0.08, zm), Vector3(0.02, 0.16, largo), horm, false)

## Pared a lo largo de X (en `z`), con su cara interior hacia `hacia` (±1 en Z).
static func _muro_x(nodo: Node3D, z: float, x_a: float, x_b: float, y: float, horm: Material, pared: Material,
		franja: Material, franja2: Material, hacia: float) -> void:
	var largo := absf(x_b - x_a)
	if largo < 0.05:
		return
	var xm := (x_a + x_b) / 2.0
	TunelVestuario._caja(nodo, Vector3(xm, y + ALTO / 2.0, z), Vector3(largo, ALTO, 0.3), horm, true)
	var zi := z + hacia * 0.16
	TunelVestuario._caja(nodo, Vector3(xm, y + ALTO / 2.0, zi), Vector3(largo, ALTO, 0.02), pared, false)
	TunelVestuario._caja(nodo, Vector3(xm, y + 1.05, zi + hacia * 0.01), Vector3(largo, 0.18, 0.02), franja, false)
	TunelVestuario._caja(nodo, Vector3(xm, y + 0.86, zi + hacia * 0.01), Vector3(largo, 0.08, 0.02), franja2, false)
	TunelVestuario._caja(nodo, Vector3(xm, y + 0.08, zi + hacia * 0.01), Vector3(largo, 0.16, 0.02), horm, false)

static func _lampara(nodo: Node3D, p: Vector3) -> void:
	var o := OmniLight3D.new()
	o.position = p
	o.omni_range = 11.0
	o.light_energy = 1.1
	o.light_color = Color(1, 0.96, 0.88)
	nodo.add_child(o)

## La escalera mecánica: rampa de peldaños, pasamanos del club y el pozo con
## su techo inclinado. Arranca en `pie` (abajo) y sube en +Z.
static func _escalera(nodo: Node3D, pie: Vector3, c1: Color, horm: Material, pared: Material) -> void:
	var sube := -pie.y
	var largo := LARGO_ESCALERA
	var ang := atan2(sube, largo)
	var hip := Vector2(largo, sube).length()
	var centro := pie + Vector3(0, sube / 2.0, largo / 2.0)
	var acero := TunelVestuario._mat(Color(0.55, 0.57, 0.6), 0.35)
	acero.metallic = 0.7
	var peldano := TunelVestuario._mat(Color(0.22, 0.22, 0.24), 0.5)
	var pasa := TunelVestuario._mat(c1.darkened(0.2), 0.4)
	## Rampa y peldaños (cajitas a lo largo de la diagonal).
	var rampa := TunelVestuario._caja(nodo, centro, Vector3(1.4, 0.3, hip), acero, false)
	rampa.rotation.x = -ang
	var n := 28
	for i in n:
		var f := (float(i) + 0.5) / float(n)
		TunelVestuario._caja(nodo, pie + Vector3(0, sube * f + 0.16, largo * f), Vector3(1.0, 0.05, largo / float(n) * 0.85), peldano, false)
	for lado in [-1.0, 1.0]:
		var bal := TunelVestuario._caja(nodo, centro + Vector3(lado * 0.72, 0.55, 0), Vector3(0.08, 0.9, hip), acero, false)
		bal.rotation.x = -ang
		var mano := TunelVestuario._caja(nodo, centro + Vector3(lado * 0.72, 1.02, 0), Vector3(0.12, 0.08, hip), pasa, false)
		mano.rotation.x = -ang
	## El pozo: paredes y techo en rebanadas verticales que siguen la rampa
	## (giradas asomaban por delante, dentro del pasillo). Llega hasta donde su
	## techo toca la calle; de ahí arriba manda la caseta.
	var rebanadas := 12
	for i in rebanadas:
		var f := (float(i) + 0.5) / float(rebanadas)
		var y_r := pie.y + sube * f
		var techo_y := y_r + ALTO + 0.3
		if techo_y > -0.2:
			break
		var zs := pie.z + largo * f
		var paso := largo / float(rebanadas) + 0.02
		for lado2 in [-1.0, 1.0]:
			var abajo := y_r - 1.2
			TunelVestuario._caja(nodo, Vector3(pie.x + lado2 * 1.25, (abajo + techo_y) / 2.0, zs), Vector3(0.3, techo_y - abajo, paso), horm, false)
			TunelVestuario._caja(nodo, Vector3(pie.x + lado2 * 1.09, (abajo + techo_y) / 2.0, zs), Vector3(0.02, techo_y - abajo, paso), pared, false)
		TunelVestuario._caja(nodo, Vector3(pie.x, techo_y + 0.15, zs), Vector3(2.8, 0.3, paso), horm, false)
	## Luz de día arriba y un rótulo al pie.
	_lampara(nodo, pie + Vector3(0, sube + 1.5, largo - 0.5))
	_lampara(nodo, pie + Vector3(0, 2.6, 0.8))
	TunelVestuario._rotulo(nodo, "⇡ %s" % Idiomas.t("SALIDA · COMPLEJO DEL CLUB"), pie + Vector3(0, ALTO - 0.3, -0.35), PI, 20, c1.lerp(Color(0.08, 0.08, 0.1), 0.3))

## La caseta de la escalera en la calle (coordenadas del MUNDO, la pone la
## ciudad): marquesina de cristal con el techo del club y el rótulo.
static func montar_caseta(padre: Node3D, est: Dictionary, c1: Color) -> void:
	var b := boca_mundo(est)
	var nodo := Node3D.new()
	nodo.name = "CasetaGaleria"
	padre.add_child(nodo)
	var acero := TunelVestuario._mat(Color(0.35, 0.37, 0.4), 0.4)
	var techo := TunelVestuario._mat(c1, 0.5)
	## Cristal ahumado (el claro se leía como una caja blanca desde la calle).
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.16, 0.24, 0.3, 0.55)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.roughness = 0.08
	vidrio.metallic = 0.3
	var oscuro := TunelVestuario._mat(Color(0.12, 0.12, 0.13), 0.8)
	## La boca: el hueco oscuro por donde asoma la escalera (de z−4 a z).
	## Planos y no cajas: desde abajo (en la escalera) no se ven y asoma el cielo.
	_plano(nodo, b + Vector3(0, 0.03, -2.2), Vector2(2.4, 4.4), oscuro)
	_plano(nodo, b + Vector3(0, 0.05, -2.2), Vector2(1.0, 4.0), TunelVestuario._mat(Color(0.5, 0.52, 0.55), 0.4))
	for lado in [-1.0, 1.0]:
		## Laterales de cristal y antepecho; el frente (+Z) queda abierto.
		TunelVestuario._caja(nodo, b + Vector3(lado * 1.35, 0.55, -2.2), Vector3(0.12, 1.1, 4.6), acero, false)
		TunelVestuario._caja(nodo, b + Vector3(lado * 1.35, 1.9, -2.2), Vector3(0.05, 1.6, 4.6), vidrio, false)
		for zz in [-4.4, 0.0]:
			TunelVestuario._caja(nodo, b + Vector3(lado * 1.35, 1.5, zz), Vector3(0.12, 3.0, 0.12), acero, false)
	TunelVestuario._caja(nodo, b + Vector3(0, 1.5, -4.5), Vector3(2.8, 3.0, 0.12), vidrio, false)
	## Marquesina volada con el canto del club.
	TunelVestuario._caja(nodo, b + Vector3(0, 3.05, -1.8), Vector3(3.6, 0.16, 6.0), acero, false)
	TunelVestuario._caja(nodo, b + Vector3(0, 3.2, -1.8), Vector3(3.7, 0.16, 6.1), techo, false)
	TunelVestuario._rotulo(nodo, "⇩ %s" % Idiomas.t("GALERÍA AL ESTADIO"), b + Vector3(0, 3.2, 1.22), 0.0, 40, Color(1, 0.96, 0.8))
	## El tótem, para encontrarla desde lejos.
	var totem := b + Vector3(2.6, 0, 0.4)
	TunelVestuario._caja(nodo, totem + Vector3(0, 1.8, 0), Vector3(0.6, 3.6, 0.35), techo, false)
	TunelVestuario._caja(nodo, totem + Vector3(0, 3.75, 0), Vector3(0.7, 0.3, 0.45), acero, false)
	for giro in [0.0, PI]:
		TunelVestuario._rotulo(nodo, "⇣\n%s\n%s" % [Idiomas.t("GALERÍA"), Idiomas.t("ESTADIO")],
			totem + Vector3(0, 2.6, 0.19 if giro == 0.0 else -0.19), giro, 30, Color.WHITE if techo.albedo_color.get_luminance() < 0.6 else Color(0.08, 0.08, 0.1))
	var o := OmniLight3D.new()
	o.position = b + Vector3(0, 2.6, -1.5)
	o.omni_range = 7.0
	o.light_energy = 0.8
	nodo.add_child(o)

static func _plano(nodo: Node3D, p: Vector3, tam: Vector2, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = tam
	mi.mesh = pm
	mi.material_override = mat
	mi.position = p
	nodo.add_child(mi)
