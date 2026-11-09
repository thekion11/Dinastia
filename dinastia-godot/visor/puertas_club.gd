class_name PuertasClub
extends RefCounted
## LAS PUERTAS DE LAS SALAS DEL CLUB (9-11, vídeo del dueño: «habitaciones sin marcos ni puertas»). El tabique del pasillo tenía solo el
## hueco: ahora cada hueco lleva su MARCO (dos jambas y dintel, con el color del club) y una HOJA de madera abierta contra la pared del pasillo,
## con su manija y su placa. Todo es visual (sin choque), así que el paso queda libre como antes.
const ALTO := 2.4
const GRUESO := 0.24
const ANCHO_JAMBA := 0.1

## `huecos`: [Vector2(x_izq, x_der)] de cada puerta; `z_tabique`: el plano del tabique; `y0`: el suelo de la planta.
static func poner(nodo: Node3D, huecos: Array, y0: float, z_tabique: float, color_club: Color) -> void:
	var marco := PiezasObra._mat(color_club.lerp(Color(0.12, 0.12, 0.14), 0.35), 0.45)
	var madera := PiezasObra._mat(Color(0.52, 0.36, 0.22), 0.6)
	var metal := PiezasObra._mat(Color(0.75, 0.72, 0.62), 0.3)
	for h: Vector2 in huecos:
		var ancho := h.y - h.x
		var cx := (h.x + h.y) / 2.0
		for lado: float in [h.x, h.y]:
			PiezasObra._caja(nodo, Vector3(lado, y0 + ALTO / 2.0, z_tabique), Vector3(ANCHO_JAMBA, ALTO, GRUESO), marco, false)
		PiezasObra._caja(nodo, Vector3(cx, y0 + ALTO + ANCHO_JAMBA / 2.0 - 0.05, z_tabique), Vector3(ancho + ANCHO_JAMBA, ANCHO_JAMBA, GRUESO), marco, false)
		## La hoja, abierta hasta quedar pegada al tabique del lado del pasillo, con la bisagra en la jamba izquierda.
		var largo := ancho - 0.2
		var bisagra := Node3D.new()
		bisagra.position = Vector3(h.x + 0.05, y0, z_tabique + GRUESO / 2.0 + 0.04)
		bisagra.rotation.y = PI
		nodo.add_child(bisagra)
		PiezasObra._caja(bisagra, Vector3(largo / 2.0, (ALTO - 0.1) / 2.0, 0.0), Vector3(largo, ALTO - 0.1, 0.05), madera, false)
		PiezasObra._caja(bisagra, Vector3(largo - 0.12, 1.0, 0.045), Vector3(0.12, 0.04, 0.05), metal, false)
		PiezasObra._caja(bisagra, Vector3(largo / 2.0, 1.75, 0.03), Vector3(0.3, 0.12, 0.02), metal, false)
