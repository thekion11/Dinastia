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

## Cuelga las camisetas en la pared del fondo de `caja` (el lado de −Z, que es donde mira el recorrido). `c2`: el segundo color del club
## (cuello y bajo de la camiseta). (12-11) Cuadros más grandes (de lejos se perdían), camiseta con forma (mangas caídas, cuello, bajo),
## paño iluminado detrás, placa dorada con el nombre y una lámpara de cuadro encendida encima. Una rama `CamisetaRetirada` por dorsal.
static func poner(nodo: Node3D, caja: Rect2, y0: float, c1: Color, retiradas: Array = [], c2 := Color(0.95, 0.95, 0.95)) -> void:
	var lista_ := retiradas if not retiradas.is_empty() else lista()
	var n := mini(lista_.size(), MAXIMO)
	if n == 0:
		return
	var oro: StandardMaterial3D = Texturas.metal(Color(0.95, 0.78, 0.3), 0.22)
	var fondo := PiezasObra._mat(Color(0.06, 0.07, 0.09), 0.9)
	var pano := PiezasObra._mat(Color(0.17, 0.19, 0.24), 0.95)
	var tela := PiezasObra._mat(c1, 0.8)
	var vivo := PiezasObra._mat(c2 if absf(c2.get_luminance() - c1.get_luminance()) > 0.12 else c1.lerp(Color(1, 1, 1) if c1.get_luminance() < 0.5 else Color(0, 0, 0), 0.6), 0.8)
	var luz := PiezasObra._mat_unico(Color(1.0, 0.93, 0.75), 0.4)
	luz.emission_enabled = true
	luz.emission = Color(1.0, 0.88, 0.6)
	luz.emission_energy_multiplier = 1.6
	var tinta := Color(1, 1, 1) if c1.get_luminance() < 0.6 else Color(0.08, 0.08, 0.1)
	var z := caja.position.y + 0.12
	var ancho := caja.size.x - 1.2
	var paso := ancho / float(n)
	var w := clampf(paso - 0.14, 0.7, 1.25)
	for k in n:
		var e: Dictionary = lista_[lista_.size() - n + k]   ## las más recientes
		var r := Node3D.new()
		r.name = "CamisetaRetirada%d" % k
		r.position = Vector3(caja.position.x + 0.6 + paso * (float(k) + 0.5), y0 + 2.05, z)
		nodo.add_child(r)
		PiezasObra._caja(r, Vector3.ZERO, Vector3(w, 1.6, 0.05), oro, false)
		PiezasObra._caja(r, Vector3(0, 0, 0.012), Vector3(w - 0.1, 1.5, 0.04), fondo, false)
		PiezasObra._caja(r, Vector3(0, 0.12, 0.02), Vector3(w - 0.26, 1.0, 0.03), pano, false)   ## el paño que alumbra la lámpara
		## La camiseta: cuerpo, dos mangas caídas, cuello y bajo en el segundo color.
		PiezasObra._caja(r, Vector3(0, 0.1, 0.045), Vector3(0.46, 0.66, 0.02), tela, false)
		for lado: float in [-1.0, 1.0]:
			var manga := PiezasObra._caja(r, Vector3(lado * 0.31, 0.31, 0.044), Vector3(0.3, 0.2, 0.02), tela, false)
			manga.rotation.z = -lado * 0.55
		PiezasObra._caja(r, Vector3(0, 0.425, 0.05), Vector3(0.17, 0.05, 0.02), vivo, false)
		PiezasObra._caja(r, Vector3(0, -0.215, 0.05), Vector3(0.46, 0.035, 0.02), vivo, false)
		PiezasObra._rotulo(r, str(int(e.get("dorsal", 0))), Vector3(0, 0.1, 0.062), 0.0, 56, tinta)
		## La placa con el apellido y el año, y la lámpara de cuadro.
		PiezasObra._caja(r, Vector3(0, -0.55, 0.045), Vector3(minf(w - 0.3, 0.7), 0.2, 0.02), oro, false)
		PiezasObra._rotulo_ajustado(r, "%s · '%s" % [String(e.get("nombre", "")).split(" ")[-1].to_upper(), str(int(e.get("anio", 0))).right(2)],
			Vector3(0, -0.55, 0.06), 0.0, 20, Color(0.12, 0.09, 0.03), minf(w - 0.34, 0.66))
		PiezasObra._caja(r, Vector3(0, 0.86, 0.1), Vector3(0.03, 0.06, 0.16), oro, false)
		PiezasObra._caja(r, Vector3(0, 0.88, 0.19), Vector3(0.5, 0.05, 0.07), luz, false)
