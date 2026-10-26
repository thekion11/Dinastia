class_name PiezasVestuario
extends RefCounted
## LAS TAQUILLAS DEL VESTUARIO, DE VERDAD (26-10-2026, paquete pint).
##
## Antes cada taquilla era un bloque de madera con una placa negra delante y
## el nombre del jugador flotando encima: los nombres largos se montaban sobre
## los del vecino («Óscar ObezoFernando de Pedro») y no se veía camiseta
## ninguna. Ahora cada una es un cubículo abierto como el de un vestuario de
## primera: laterales, fondo, balda con la bolsa, asiento acolchado del color
## del club con las botas encima, la camiseta colgada de espaldas con el
## apellido y el dorsal, una tira de luz cálida arriba y la placa con el
## nombre. Los textos se ajustan al ancho de la taquilla (nunca se salen).
##
## Todas las cajas de todas las taquillas se juntan en UNA malla por material
## (`Lote`): 16 taquillas son unas 10 llamadas de dibujo, no 200.

## Medidas de una taquilla (m): ancho, fondo y alto.
const ANCHO := 0.98
const FONDO := 0.62
const ALTO := 2.3
## Tamaño de un píxel de los textos de la taquilla.
const PIXEL := 0.004

## Junta cajas por material y las monta como una malla por material.
class Lote:
	var _st: Dictionary = {}
	## Lo que ocupa cada pieza: [AABB, material] (para las pruebas de apoyo).
	var piezas: Array = []

	func caja(mat: Material, xf: Transform3D, tam: Vector3) -> void:
		var bm := BoxMesh.new()
		bm.size = tam
		malla(mat, xf, bm)

	## Cualquier malla primitiva (esfera, cilindro, toro…) en `xf`.
	func malla(mat: Material, xf: Transform3D, m: Mesh) -> void:
		var st: SurfaceTool = _st.get(mat)
		if st == null:
			st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			_st[mat] = st
		st.append_from(m, 0, xf)
		piezas.append([xf * m.get_aabb(), mat])

	func montar(padre: Node3D, nombre: String) -> void:
		var k := 0
		for mat: Material in _st:
			var mi := MeshInstance3D.new()
			mi.name = "%s%d" % [nombre, k]
			mi.mesh = (_st[mat] as SurfaceTool).commit()
			mi.material_override = mat
			padre.add_child(mi)
			k += 1

## El apellido para la espalda de la camiseta: lo que va tras el nombre de pila
## («Fernando de Pedro» → «DE PEDRO»); un nombre solo se queda entero.
static func apellido(nombre: String) -> String:
	var partes := nombre.strip_edges().split(" ", false)
	if partes.size() < 2:
		return nombre.strip_edges().to_upper()
	return " ".join(partes.slice(1)).to_upper()

## El tamaño de letra para que `texto` quepa en `ancho` metros (entre `minimo`
## y `maximo`). Cuenta ~0,6 del cuerpo por carácter (fuente de la interfaz).
static func letra_para(texto: String, ancho: float, maximo: int, minimo := 12) -> int:
	var n := maxi(1, texto.length())
	return clampi(int(ancho / (float(n) * 0.6 * PIXEL)), minimo, maximo)

## Un texto pegado a una cara (mira a +Z del nodo `padre`).
static func texto(padre: Node3D, t: String, pos: Vector3, tam: int, col: Color, contorno := 4) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.font_size = tam
	l.pixel_size = PIXEL
	l.modulate = col
	l.outline_size = contorno
	l.outline_modulate = Color(0, 0, 0, 0.55)
	l.position = pos
	l.double_sided = false
	l.shaded = false
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	## No más ancho que la taquilla: si aun así no cabe, parte en dos líneas.
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.width = (ANCHO - 0.2) / PIXEL
	l.visibility_range_end = 16.0
	padre.add_child(l)
	return l

## Los materiales de las taquillas de un vestuario, de una vez (se comparten).
static func materiales(c1: Color, c2: Color) -> Dictionary:
	var madera := TunelVestuario._mat(Color(0.56, 0.4, 0.25).lerp(c1, 0.12), 0.55)
	var fondo := TunelVestuario._mat(Color(0.2, 0.21, 0.23).lerp(c1, 0.25), 0.7)
	var cojin := TunelVestuario._mat(c1.lerp(Color(0.08, 0.08, 0.1), 0.15), 0.9)
	var placa := TunelVestuario._mat(Color(0.1, 0.1, 0.12), 0.35)
	placa.metallic = 0.4
	var tira := TunelVestuario._mat(Color(1, 0.93, 0.78), 0.4)
	tira.emission_enabled = true
	tira.emission = Color(1, 0.88, 0.62)
	tira.emission_energy_multiplier = 1.8
	tira.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var bota := TunelVestuario._mat(Color(0.07, 0.07, 0.08), 0.35)
	var suela := TunelVestuario._mat(c2.lerp(Color(0.9, 0.9, 0.9), 0.4), 0.5)
	var bolsa := TunelVestuario._mat(c1.lerp(Color(0.05, 0.05, 0.06), 0.45), 0.8)
	var toalla := TunelVestuario._mat(Color(0.94, 0.94, 0.92), 0.95)
	var metal: StandardMaterial3D = Texturas.metal(Color(0.75, 0.76, 0.78), 0.3)
	return {"madera": madera, "fondo": fondo, "cojin": cojin, "placa": placa, "tira": tira, "bota": bota,
		"suela": suela, "bolsa": bolsa, "toalla": toalla, "metal": metal,
		"cam1": TunelVestuario._mat(c1, 0.85), "cam2": TunelVestuario._mat(c2, 0.85), "c1": c1, "c2": c2}

## Una caja de la taquilla en coordenadas locales (girada `gz` en Z, `gy` en Y).
static func _pon(lote: Lote, xf: Transform3D, p: Vector3, tam: Vector3, mat: Material, gz := 0.0, gy := 0.0) -> void:
	lote.caja(mat, xf * Transform3D(Basis.from_euler(Vector3(0, gy, gz)), p), tam)

## Una camiseta colgada, de espaldas, con el centro del pecho en `xf` (mira a
## +Z local). `m1` el color principal y `m2` cuello, puños y bajo.
static func camiseta(lote: Lote, xf: Transform3D, m1: Material, m2: Material) -> void:
	_pon(lote, xf, Vector3.ZERO, Vector3(0.5, 0.66, 0.035), m1)
	for s: float in [-1.0, 1.0]:
		_pon(lote, xf, Vector3(s * 0.3, 0.22, 0), Vector3(0.2, 0.2, 0.034), m1, s * 0.55)
		_pon(lote, xf, Vector3(s * 0.36, 0.14, 0.001), Vector3(0.2, 0.04, 0.034), m2, s * 0.55)
	_pon(lote, xf, Vector3(0, 0.33, 0.002), Vector3(0.16, 0.04, 0.034), m2)
	_pon(lote, xf, Vector3(0, -0.32, 0.001), Vector3(0.5, 0.03, 0.036), m2)

## Una taquilla con su camiseta. `xf`: dónde está su base (centro del suelo)
## mirando a +Z local hacia el centro del vestuario. `dorsal` y `nombre`
## (nombre vacío = sin plantilla: solo el número). `rng` varía bolsa, botas y toalla.
static func taquilla(lote: Lote, padre: Node3D, xf: Transform3D, m: Dictionary, dorsal: int, nombre: String,
		rng: RandomNumberGenerator) -> void:
	var w := ANCHO - 0.04
	## El mueble: fondo, laterales, techo, balda y el asiento-cajón.
	_pon(lote, xf, Vector3(0, ALTO / 2.0, -FONDO / 2.0 + 0.01), Vector3(w, ALTO, 0.02), m["fondo"])
	for s: float in [-1.0, 1.0]:
		_pon(lote, xf, Vector3(s * (w / 2.0 - 0.015), ALTO / 2.0, 0), Vector3(0.03, ALTO, FONDO), m["madera"])
	_pon(lote, xf, Vector3(0, ALTO - 0.02, 0), Vector3(w, 0.04, FONDO), m["madera"])
	_pon(lote, xf, Vector3(0, 1.98, -0.02), Vector3(w - 0.06, 0.025, FONDO - 0.04), m["madera"])
	_pon(lote, xf, Vector3(0, 0.2, 0.03), Vector3(w - 0.06, 0.4, FONDO - 0.04), m["madera"])
	_pon(lote, xf, Vector3(0, 0.425, 0.03), Vector3(w - 0.08, 0.05, FONDO - 0.06), m["cojin"])
	## La tira de luz bajo el techo, al frente (se ve el interior iluminado).
	_pon(lote, xf, Vector3(0, ALTO - 0.05, FONDO / 2.0 - 0.05), Vector3(w - 0.1, 0.02, 0.03), m["tira"])
	## La placa del nombre, arriba al frente.
	_pon(lote, xf, Vector3(0, ALTO - 0.17, FONDO / 2.0 + 0.006), Vector3(w - 0.12, 0.17, 0.012), m["placa"])
	## La barra y la camiseta colgada de espaldas (se ven apellido y dorsal).
	_pon(lote, xf, Vector3(0, 1.86, -0.08), Vector3(w - 0.06, 0.018, 0.018), m["metal"])
	var zc := -0.06
	_pon(lote, xf, Vector3(0, 1.84, zc + 0.01), Vector3(0.36, 0.02, 0.02), m["metal"])
	camiseta(lote, xf * Transform3D(Basis.IDENTITY, Vector3(0, 1.46, zc)), m["cam1"], m["cam2"])
	## Las botas sobre el asiento (una algo girada) y la bolsa en la balda.
	var gb := rng.randf_range(-0.35, 0.35)
	for s: float in [-1.0, 1.0]:
		var px := s * 0.1 + rng.randf_range(-0.02, 0.02)
		_pon(lote, xf, Vector3(px, 0.495, 0.1), Vector3(0.1, 0.09, 0.27), m["bota"], 0.0, gb if s > 0 else 0.0)
		_pon(lote, xf, Vector3(px, 0.455, 0.1), Vector3(0.105, 0.015, 0.28), m["suela"], 0.0, gb if s > 0 else 0.0)
	var bx := rng.randf_range(-0.18, 0.18)
	_pon(lote, xf, Vector3(bx, 2.11, -0.04), Vector3(0.48, 0.22, 0.3), m["bolsa"])
	_pon(lote, xf, Vector3(bx, 2.23, -0.04), Vector3(0.3, 0.02, 0.04), m["suela"])
	if rng.randf() < 0.6:
		## Una toalla doblada colgando del lateral.
		var sx := -1.0 if rng.randf() < 0.5 else 1.0
		_pon(lote, xf, Vector3(sx * (w / 2.0 - 0.06), 1.05, FONDO / 2.0 - 0.12), Vector3(0.05, 0.5, 0.22), m["toalla"])
	## Los textos: en la placa el nombre completo; en la camiseta el apellido
	## y el dorsal, como en la espalda de la de partido.
	var raiz := Node3D.new()
	raiz.transform = xf
	padre.add_child(raiz)
	var c2: Color = m["c2"]
	var tinta := c2 if (c2 as Color).get_luminance() > 0.3 or (m["c1"] as Color).get_luminance() < 0.3 else Color(0.97, 0.97, 0.97)
	texto(raiz, str(dorsal), Vector3(0, 1.4, zc + 0.02), 62, tinta, 6)
	if nombre != "":
		var ape := apellido(nombre)
		texto(raiz, ape, Vector3(0, 1.66, zc + 0.02), letra_para(ape, 0.42, 22, 10), tinta, 3)
		var placa := "%d · %s" % [dorsal, nombre]
		texto(raiz, placa, Vector3(0, ALTO - 0.17, FONDO / 2.0 + 0.015), letra_para(placa, w - 0.18, 26, 11), Color(0.96, 0.9, 0.7), 2)
