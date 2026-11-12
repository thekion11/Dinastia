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
		"Cuarto de máquinas":
			## Cajas de repuestos apiladas en la esquina del fondo.
			EdificioClub._mod(nodo, "cardboardBoxClosed", Vector3(caja.position.x + 0.45, y0, caja.end.y - 0.45), 0.2, true)
			EdificioClub._mod(nodo, "cardboardBoxOpen", Vector3(caja.position.x + 1.2, y0, caja.end.y - 0.45), -0.15, true)
			EdificioClub._mod(nodo, "cardboardBoxClosed", Vector3(caja.position.x + 0.45, y0 + EdificioClub._alto_mod("cardboardBoxClosed"), caja.end.y - 0.45), 0.5)
		"Utilería":
			EdificioClub._mod(nodo, "cardboardBoxOpen", Vector3(caja.end.x - 0.45, y0, caja.end.y - 0.45), 0.4, true)
	_cc0(nodo, nombre, caja, y0)

## (12-11, sesión 16) MUEBLES CC0 DE POLY HAVEN (`ModeloCC0`: solo MEDIA y ALTA; en el resto no se pone nada y la sala queda como estaba)
## en la prensa, la enfermería y la utilería: lo que se ve a la altura de los ojos en primera persona (orden 45). Texturas de 256 px en las
## piezas pequeñas y 512 en las estanterías (`herramientas/bajar_cc0_modelos.py`). `SIN_MUEBLES_CC0=1` las quita para medir el «antes».
static func _cc0(nodo: Node3D, nombre: String, caja: Rect2, y0: float) -> void:
	var cx := caja.get_center().x
	match nombre:
		"Enfermería":
			ModeloCC0.poner(nodo, "steel_frame_shelves_03", Vector3(caja.end.x - 0.32, y0, caja.position.y + 2.6), -PI * 0.5, 1.8, true, false)
			ModeloCC0.poner(nodo, "metal_stool_02", Vector3(caja.position.x + 1.0, y0, caja.position.y + 2.75), 0.4, 0.5, true, false)
			ModeloCC0.poner(nodo, "wall_clock", Vector3(cx + 1.3, y0 + 2.05, caja.position.y + 0.0), 0.0, 0.32, false, false)
		"Sala de prensa":
			ModeloCC0.poner(nodo, "wall_clock", Vector3(caja.position.x + 0.0, y0 + 2.1, caja.get_center().y + 0.5), PI * 0.5, 0.36, false, false)
			ModeloCC0.poner(nodo, "korean_fire_extinguisher_01", Vector3(caja.end.x - 0.25, y0, caja.end.y - 0.25), -PI * 0.5, 0.6, true, false)
		"Utilería":
			ModeloCC0.poner(nodo, "worn_metal_rack", Vector3(cx - 0.9, y0, caja.position.y + 0.35), 0.0, 1.8, true, false)   ## entre la estantería de la izquierda y la jaula de balones
			ModeloCC0.poner(nodo, "WetFloorSign_01", Vector3(cx - 0.6, y0, caja.end.y - 1.3), 0.5, 0.62, true, false)

## Un banco en el pasillo de cada planta, contra la pared del fondo y sin tapar el ascensor ni las puertas. (Las plantas grandes que se probaron en los
## extremos costaban ~38 llamadas de dibujo cada una en ALTA, y la orden es no subir el dibujo: se quedaron fuera.)
static func pasillo(nodo: Node3D, x0: float, z_fin: float, y0: float) -> void:
	if Calidad.elegida <= Calidad.MINIMO:
		return
	EdificioClub._mod(nodo, "bench", Vector3(x0 + 5.2, y0, z_fin - 0.4), PI, true)
	## (12-11) CC0 (MEDIA y ALTA): reloj sobre el banco y extintor al otro extremo, contra la pared del fondo.
	ModeloCC0.poner(nodo, "wall_clock", Vector3(x0 + 5.2, y0 + 2.15, z_fin - 0.08), PI, 0.34, false, false)
	ModeloCC0.poner(nodo, "korean_fire_extinguisher_01", Vector3(x0 - 5.6, y0, z_fin - 0.25), PI, 0.6, true, false)
