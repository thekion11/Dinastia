class_name RellenoClub
extends RefCounted
## RELLENO DE LAS SALAS VACÍAS DEL EDIFICIO DEL CLUB (10-11, sesión 7, «solo club» paso 2). Piezas de `assets/kenney/muebles` que nadie usaba
## (`docs/04_auditorias/recursos_sin_usar.md`) para la enfermería, la sala de vídeo, el cuarto de máquinas y los pasillos. Todo pasa por
## `EdificioClub._mod` (catálogo común `Modulos`, escala medida, apoyado en el suelo de la planta); lo grande lleva caja de choque. Sin la pieza
## (`Modulos.existe`), simplemente no se pone. Se llama desde `EdificioClub.montar` tras amueblar cada sala. En ULTRA BAJA (la orden es no subir el dibujo
## ahí) el relleno decorativo NO se pone: lo existente queda igual y las salas nuevas se llenan en BAJA o más.

## `caja`: el suelo libre de la sala (x, z); las salas miran a +Z (el pasillo está en `caja.end.y`).
static func sala(nodo: Node3D, nombre: String, caja: Rect2, y0: float, c1: Color) -> void:
	if Calidad.elegida <= Calidad.MINIMO:
		return
	var cx := caja.get_center().x
	_zocalo(nodo, caja, y0, c1)
	match nombre:
		"Enfermería":
			## Lavabo y botiquín junto a la puerta (contra el tabique del pasillo, de cara a la sala) y una caja de material.
			EdificioClub._mod(nodo, "bathroomSink", Vector3(caja.position.x + 0.45, y0, caja.end.y - 0.35), PI, true)
			EdificioClub._mod(nodo, "bathroomCabinet", Vector3(caja.position.x + 1.15, y0, caja.end.y - 0.3), PI, true)
			EdificioClub._mod(nodo, "cardboardBoxOpen", Vector3(caja.end.x - 0.35, y0, caja.position.y + 0.4), 0.3, true)
		"Sala de vídeo":
			## Una planta y una lámpara a cada lado de la pantalla (el sofá largo se quitó: tapaba la puerta y no cabía).
			EdificioClub._mod(nodo, "pottedPlant", Vector3(caja.position.x + 0.4, y0, caja.position.y + 0.5), 0.0, true, 2.2)
			EdificioClub._mod(nodo, "lampRoundFloor", Vector3(caja.end.x - 0.35, y0, caja.position.y + 0.5), 0.0, true)
			## (12-11, sesión 16, primera persona) Sombra de contacto bajo cada fila de butacas (las mismas filas que pone `EdificioClub`):
			## sin ella, de cerca parecían flotar sobre la moqueta. Una pieza translúcida por fila; en ULTRA BAJA no se pone (como todo el relleno).
			var filas := clampi(1 + EdificioClub.nivel("video") / 3, 1, 4)
			var n_but := int((caja.size.x - 1.0) / 0.8)
			for f in filas:
				PiezasObra._caja(nodo, Vector3(caja.position.x + 0.9 + float(n_but - 1) * 0.4, y0 + 0.034, caja.position.y + 2.2 + f * 1.1),
					Vector3(float(n_but) * 0.8, 0.002, 0.8), _sombra_contacto(), false)
		"Cuarto de máquinas":
			## Cajas de repuestos apiladas en la esquina del fondo.
			EdificioClub._mod(nodo, "cardboardBoxClosed", Vector3(caja.position.x + 0.45, y0, caja.end.y - 0.45), 0.2, true)
			EdificioClub._mod(nodo, "cardboardBoxOpen", Vector3(caja.position.x + 1.2, y0, caja.end.y - 0.45), -0.15, true)
			EdificioClub._mod(nodo, "cardboardBoxClosed", Vector3(caja.position.x + 0.45, y0 + EdificioClub._alto_mod("cardboardBoxClosed"), caja.end.y - 0.45), 0.5)
		"Utilería":
			EdificioClub._mod(nodo, "cardboardBoxOpen", Vector3(caja.end.x - 0.45, y0, caja.end.y - 0.45), 0.4, true)
		"Oficina del DT":
			_oficina_dt(nodo, caja, y0, c1)
		"Despacho del presidente":
			_despacho(nodo, caja, y0)
	_cc0(nodo, nombre, caja, y0)

## (12-11, sesión 16) MUEBLES CC0 DE POLY HAVEN (`ModeloCC0`: solo MEDIA y ALTA; en el resto no se pone nada y la sala queda como estaba)
## en la prensa, la enfermería y la utilería: lo que se ve a la altura de los ojos en primera persona (orden 45). Texturas de 256 px en las
## piezas pequeñas y 512 en las estanterías (`herramientas/bajar_cc0_modelos.py`). `SIN_MUEBLES_CC0=1` las quita para medir el «antes».
static func _cc0(nodo: Node3D, nombre: String, caja: Rect2, y0: float) -> void:
	var cx := caja.get_center().x
	match nombre:
		"Enfermería":
			ModeloCC0.poner(nodo, "wheelchair_01", Vector3(caja.end.x - 1.0, y0, caja.end.y - 1.0), PI * 0.8, 1.0, false, false)   ## (18-11) silla de ruedas de Poly Haven (CC0)
			ModeloCC0.poner(nodo, "steel_frame_shelves_03", Vector3(caja.end.x - 0.32, y0, caja.position.y + 2.6), -PI * 0.5, 1.8, true, false)
			ModeloCC0.poner(nodo, "metal_stool_02", Vector3(caja.position.x + 1.0, y0, caja.position.y + 2.75), 0.4, 0.5, true, false)
			ModeloCC0.poner(nodo, "wall_clock", Vector3(cx + 1.3, y0 + 2.05, caja.position.y + 0.0), 0.0, 0.32, false, false)
		"Sala de prensa":
			ModeloCC0.poner(nodo, "wall_clock", Vector3(caja.position.x + 0.0, y0 + 2.1, caja.get_center().y + 0.5), PI * 0.5, 0.36, false, false)
			ModeloCC0.poner(nodo, "korean_fire_extinguisher_01", Vector3(caja.end.x - 0.25, y0, caja.end.y - 0.25), -PI * 0.5, 0.6, true, false)
		"Utilería":
			ModeloCC0.poner(nodo, "worn_metal_rack", Vector3(cx - 0.9, y0, caja.position.y + 0.35), 0.0, 1.8, true, false)   ## entre la estantería de la izquierda y la jaula de balones
			ModeloCC0.poner(nodo, "WetFloorSign_01", Vector3(cx - 0.6, y0, caja.end.y - 1.3), 0.5, 0.62, true, false)

static var _sombra: StandardMaterial3D = null
static func _sombra_contacto() -> StandardMaterial3D:
	if _sombra == null:
		_sombra = StandardMaterial3D.new()
		_sombra.albedo_color = Color(0.0, 0.0, 0.0, 0.38)
		_sombra.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_sombra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _sombra

## Un banco en el pasillo de cada planta, contra la pared del fondo y sin tapar el ascensor ni las puertas. (Las plantas grandes que se probaron en los
## extremos costaban ~38 llamadas de dibujo cada una en ALTA, y la orden es no subir el dibujo: se quedaron fuera.)
static func pasillo(nodo: Node3D, x0: float, z_fin: float, y0: float) -> void:
	if Calidad.elegida <= Calidad.MINIMO:
		return
	EdificioClub._mod(nodo, "bench", Vector3(x0 + 5.2, y0, z_fin - 0.4), PI, true)
	## (12-11) CC0 (MEDIA y ALTA): reloj sobre el banco y extintor al otro extremo, contra la pared del fondo.
	ModeloCC0.poner(nodo, "wall_clock", Vector3(x0 + 5.2, y0 + 2.15, z_fin - 0.08), PI, 0.34, false, false)
	ModeloCC0.poner(nodo, "korean_fire_extinguisher_01", Vector3(x0 - 5.6, y0, z_fin - 0.25), PI, 0.6, true, false)

## (18-11, «mejorar el mundo 3D») LA OFICINA DEL DT, la sala donde te sientas al PC: sobre la mesa el ratón, una taza y una pila de libros (donde
## apoyan las manos de `PcAnimacion`), y en la pared del sofá un reloj y tres cuadros enmarcados con los colores del club. Mismas coordenadas que
## el escritorio de `EdificioClub` (mesa en cz − 0,6, teclado en cz − 0,45). Sin la pieza, no se pone.
static func _oficina_dt(nodo: Node3D, caja: Rect2, y0: float, c1: Color) -> void:
	var cx := caja.get_center().x
	var cz := caja.get_center().y
	var sobre := y0 + EdificioClub._alto_mod("desk")
	EdificioClub._mod(nodo, "computerMouse", Vector3(cx + 0.42, sobre, cz - 0.45), 0.0)
	EdificioClub._mod(nodo, "comida/mug", Vector3(cx - 0.7, sobre, cz - 0.5), 0.6)
	EdificioClub._mod(nodo, "books", Vector3(cx - 0.62, sobre, cz - 0.78), 0.2)
	var x_pared := caja.end.x - 0.05
	ModeloCC0.poner(nodo, "wall_clock", Vector3(x_pared, y0 + 2.15, cz - 0.7), -PI * 0.5, 0.34, false, false)
	var marco := PiezasObra._mat(Color(0.14, 0.1, 0.07), 0.5)
	var papel := PiezasObra._mat(Color(0.93, 0.92, 0.88), 0.9)
	var color := PiezasObra._mat(c1, 0.7)
	for k in 3:
		var z := cz + 0.1 + k * 0.62
		## Con los marcos reales de Poly Haven (CC0, MEDIA/ALTA) en los dos primeros; sin ellos (o el tercero), el cuadro de cajas con los colores del club.
		if k < 2 and ModeloCC0.poner(nodo, "hanging_picture_frame_0%d" % (k + 1), Vector3(x_pared - 0.02, y0 + 1.45, z), -PI * 0.5, 0.55, false, false) != null:
			continue
		PiezasObra._caja(nodo, Vector3(x_pared - 0.02, y0 + 1.7, z), Vector3(0.04, 0.5, 0.46), marco, false)
		PiezasObra._caja(nodo, Vector3(x_pared - 0.045, y0 + 1.7, z), Vector3(0.02, 0.4, 0.36), papel, false)
		PiezasObra._caja(nodo, Vector3(x_pared - 0.06, y0 + 1.62 + 0.05 * k, z), Vector3(0.01, 0.2 + 0.08 * k, 0.24 - 0.02 * k), color, false)
	## Más piezas reales de Poly Haven (CC0): marco de sobremesa, lámpara de brazo, papelería, papelera, estantería gastada, enciclopedias, busto y copas
	## sobre el aparador, lámpara de techo. Cada una solo se pone si existe el recurso (MEDIA/ALTA).
	ModeloCC0.poner(nodo, "standing_picture_frame_01", Vector3(cx + 0.78, sobre, cz - 0.42), PI + 0.3, 0.2, false, false)
	ModeloCC0.poner(nodo, "desk_lamp_arm_01", Vector3(cx - 0.95, sobre, cz - 0.72), 0.5, 0.42, false, false)
	ModeloCC0.poner(nodo, "stationery_supplies", Vector3(cx + 0.55, sobre, cz - 0.72), -0.3, 0.1, false, false)
	ModeloCC0.poner(nodo, "metal_trash_can", Vector3(cx - 1.05, y0, cz + 0.15), 0.0, 0.4, false, false)
	ModeloCC0.poner(nodo, "wooden_bookshelf_worn", Vector3(caja.position.x + 0.3, y0, cz + 1.15), PI * 0.5, 1.9, true, false)
	ModeloCC0.poner(nodo, "book_encyclopedia_set_01", Vector3(caja.position.x + 0.45, y0 + 0.74, cz - 0.1), PI * 0.5, 0.26, false, false)
	ModeloCC0.poner(nodo, "marble_bust_01", Vector3(caja.position.x + 0.45, y0 + 0.74, cz - 0.7), PI * 0.5, 0.36, false, false)
	ModeloCC0.poner(nodo, "brass_goblets", Vector3(caja.position.x + 0.45, y0 + 0.74, cz - 0.4), PI * 0.5, 0.2, false, false)
	ModeloCC0.poner(nodo, "modern_ceiling_lamp_01", Vector3(cx, y0 + EdificioClub.ALTO_LIBRE - 0.3, cz), 0.0, 0.3, false, false)

## (18-11, «mejorar el mundo 3D», prólogo) PAREDES MENOS LISAS: un zócalo oscuro al pie y una cenefa con el color del club a 1,05 m en las tres paredes
## cerradas de cada sala (la cuarta es el tabique del pasillo, con sus puertas). Cuatro cajas finas por sala, sin colisión ni sombra.
static func _zocalo(nodo: Node3D, caja: Rect2, y0: float, c1: Color) -> void:
	var zoc := PiezasObra._mat(Color(0.16, 0.13, 0.1), 0.6)
	var cen := PiezasObra._mat(c1, 0.6)
	var x0 := caja.position.x - 0.1 + 0.015
	var x1 := caja.end.x + 0.1 - 0.015
	var zf := caja.position.y - 0.16 + 0.015
	var largo := caja.size.y + 0.1
	var zc := caja.position.y - 0.16 + largo / 2.0
	for x in [x0, x1]:
		PiezasObra._caja(nodo, Vector3(x, y0 + 0.07, zc), Vector3(0.03, 0.14, largo), zoc, false)
		PiezasObra._caja(nodo, Vector3(x, y0 + 1.05, zc), Vector3(0.03, 0.07, largo), cen, false)
	PiezasObra._caja(nodo, Vector3((x0 + x1) / 2.0, y0 + 0.07, zf), Vector3(x1 - x0, 0.14, 0.03), zoc, false)
	PiezasObra._caja(nodo, Vector3((x0 + x1) / 2.0, y0 + 1.05, zf), Vector3(x1 - x0, 0.07, 0.03), cen, false)

## (18-11) EL DESPACHO DEL PRESIDENTE con piezas reales de Poly Haven (CC0; MEDIA/ALTA): reloj de chimenea y jarrón de latón sobre la mesa (sobre = 0,83 m),
## reloj de pie y espejo en la pared izquierda, y un marco grande sobre el sofá. Sin el recurso, no se pone nada.
static func _despacho(nodo: Node3D, caja: Rect2, y0: float) -> void:
	var cx := caja.get_center().x
	var cz := caja.get_center().y
	var mesa := y0 + 0.83
	ModeloCC0.poner(nodo, "mantel_clock_01", Vector3(cx + 0.85, mesa, cz - 0.3), PI, 0.2, false, false)
	ModeloCC0.poner(nodo, "brass_vase_01", Vector3(cx - 0.9, mesa, cz - 0.3), 0.0, 0.3, false, false)
	ModeloCC0.poner(nodo, "vintage_grandfather_clock_01", Vector3(caja.position.x + 0.3, y0, cz + 0.2), PI * 0.5, 1.9, true, false)
	ModeloCC0.poner(nodo, "ornate_mirror_01", Vector3(caja.position.x + 0.05, y0 + 1.15, cz + 1.0), PI * 0.5, 0.9, false, false)
	ModeloCC0.poner(nodo, "fancy_picture_frame_01", Vector3(caja.end.x - 0.05, y0 + 1.5, cz + 0.4), -PI * 0.5, 0.7, false, false)
