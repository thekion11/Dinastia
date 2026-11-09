class_name CamisetasMuseo
extends RefCounted
## LAS CAMISETAS RETIRADAS EN EL MUSEO DEL CLUB (9-11): en la pared del fondo de la sala, una camiseta enmarcada por cada dorsal retirado en el
## partido de despedida (`Prensa.dorsales_retirados`): fondo oscuro con filo dorado, la camiseta del club, el número y el nombre con el año.
const MAXIMO := 8

## Datos de la partida en curso (o vacío): [{dorsal, nombre, anio}].
static func lista() -> Array:
	var m := Mundo.actual()
	if m == null or m.prensa == null:
		return []
	return m.prensa.dorsales_retirados

## Cuelga las camisetas en la pared del fondo de `caja` (el lado de −Z, que es donde mira el recorrido).
static func poner(nodo: Node3D, caja: Rect2, y0: float, c1: Color, retiradas: Array = []) -> void:
	var lista_ := retiradas if not retiradas.is_empty() else lista()
	var n := mini(lista_.size(), MAXIMO)
	if n == 0:
		return
	var oro: StandardMaterial3D = Texturas.metal(Color(0.95, 0.78, 0.3), 0.22)
	var fondo := PiezasObra._mat(Color(0.07, 0.08, 0.09), 0.5)
	var tela := PiezasObra._mat(c1, 0.8)
	var z := caja.position.y + 0.12
	var ancho := caja.size.x - 1.2
	var paso := ancho / float(n)
	for k in n:
		var e: Dictionary = lista_[lista_.size() - n + k]   ## las más recientes
		var cx := caja.position.x + 0.6 + paso * (float(k) + 0.5)
		PiezasObra._caja(nodo, Vector3(cx, y0 + 2.1, z), Vector3(minf(paso - 0.12, 0.9), 1.1, 0.04), oro, false)
		PiezasObra._caja(nodo, Vector3(cx, y0 + 2.1, z + 0.015), Vector3(minf(paso - 0.2, 0.82), 1.02, 0.03), fondo, false)
		PiezasObra._caja(nodo, Vector3(cx, y0 + 2.2, z + 0.04), Vector3(0.36, 0.42, 0.02), tela, false)   ## el cuerpo de la camiseta
		PiezasObra._caja(nodo, Vector3(cx, y0 + 2.4, z + 0.04), Vector3(0.58, 0.14, 0.02), tela, false)    ## las mangas
		PiezasObra._rotulo(nodo, str(int(e.get("dorsal", 0))), Vector3(cx, y0 + 2.2, z + 0.06), 0.0, 40, Color(1, 1, 1))
		PiezasObra._rotulo(nodo, "%s\n'%s" % [String(e.get("nombre", "")).split(" ")[-1], str(int(e.get("anio", 0))).right(2)], Vector3(cx, y0 + 1.78, z + 0.06), 0.0, 22, Color(0.95, 0.78, 0.3))
