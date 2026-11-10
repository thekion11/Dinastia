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

## Un banco en el pasillo de cada planta, contra la pared del fondo y sin tapar el ascensor ni las puertas. (Las plantas grandes que se probaron en los
## extremos costaban ~38 llamadas de dibujo cada una en ALTA, y la orden es no subir el dibujo: se quedaron fuera.)
static func pasillo(nodo: Node3D, x0: float, z_fin: float, y0: float) -> void:
	if Calidad.elegida <= Calidad.MINIMO:
		return
	EdificioClub._mod(nodo, "bench", Vector3(x0 + 5.2, y0, z_fin - 0.4), PI, true)
