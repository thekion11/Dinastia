class_name FachadaClub
extends RefCounted
## LA FACHADA DEL EDIFICIO DEL CLUB (26-10-2026, paquete pint; pedido de pgra).
##
## Desde la explanada de llegada el edificio del club (vestuario y plantas 1-2,
## pegado detrás de la tribuna) era un bloque de hormigón oscuro y liso junto
## al muro cortina nuevo del estadio. Ahora se viste igual que el estadio:
##   · un aplacado claro sobre el hormigón de los lados y de la fachada de atrás;
##   · en las plantas 1 y 2, bandas de vidrio con montantes blancos cada 1,4 m;
##     en la planta 0 (el vestuario) una franja alta de vidrio, como un
##     vestuario de verdad, y un zócalo de granito;
##   · el canto de cada forjado como una banda blanca que sobresale;
##   · arriba, una cornisa del color del club con su nombre en letras blancas
##     en los dos lados y en la fachada de atrás.
## La planta 0 de atrás (la entrada del club con su pórtico, `EntradaClub`) no
## se toca. Todo va en un `Lote` (pocas mallas) y no lleva choque: es una piel
## de pocos centímetros sobre los muros, que ya son sólidos.

const MONTANTE := 1.4
## Alto del edificio sobre el suelo: tres plantas de `ALTO_PLANTA`, menos el
## forjado de arriba (la última termina en su losa de cubierta).
const PLANTAS_ARRIBA := [0, 1, 2]

static func montar(nodo: Node3D, x0: float, z_out: float, z_fin: float, c1: Color, nombre_club: String) -> PiezasVestuario.Lote:
	var lote := PiezasVestuario.Lote.new()
	var placa := TunelVestuario._mat(Color(0.86, 0.88, 0.9), 0.75)
	var blanco := TunelVestuario._mat(Color(0.95, 0.96, 0.97), 0.5)
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.13, 0.19, 0.26)
	vidrio.metallic = 0.55
	vidrio.metallic_specular = 0.7
	vidrio.roughness = 0.12
	var granito := TunelVestuario._mat(Color(0.32, 0.33, 0.35), 0.6)
	var cornisa := TunelVestuario._mat(c1.lerp(Color(0.1, 0.1, 0.12), 0.35), 0.5)
	var alto := EdificioClub.ALTO_PLANTA * 2.0 + EdificioClub.ALTO_LIBRE + 0.5
	var xs := TunelVestuario.VEST_MEDIO + 0.3
	var z0 := z_out - 0.3
	var z1 := z_fin + 0.3
	var largo := z1 - z0
	var zc := (z0 + z1) / 2.0
	## LOS DOS LADOS (miran a ±X).
	for lado: float in [-1.0, 1.0]:
		var xf := x0 + lado * xs
		var giro := lado * PI / 2.0
		## Aplacado y zócalo.
		lote.caja(placa, _en(Vector3(xf + lado * 0.02, alto / 2.0, zc)), Vector3(0.04, alto, largo))
		lote.caja(granito, _en(Vector3(xf + lado * 0.05, 0.3, zc)), Vector3(0.06, 0.6, largo))
		for p: int in PLANTAS_ARRIBA:
			var y0 := float(p) * EdificioClub.ALTO_PLANTA
			## Vidrio: franja alta en el vestuario; banda grande en las oficinas.
			var ya := y0 + (2.2 if p == 0 else 0.9)
			var yb := y0 + 3.1
			lote.caja(vidrio, _en(Vector3(xf + lado * 0.05, (ya + yb) / 2.0, zc)), Vector3(0.04, yb - ya, largo - 0.8))
			var z := z0 + 0.4
			while z <= z1 - 0.4 + 0.01:
				lote.caja(blanco, _en(Vector3(xf + lado * 0.09, (ya + yb) / 2.0, z)), Vector3(0.08, yb - ya + 0.1, 0.08))
				z += MONTANTE
			## El canto del forjado de encima (banda blanca saliente).
			if p < 2:
				lote.caja(blanco, _en(Vector3(xf + lado * 0.1, y0 + EdificioClub.ALTO_PLANTA - 0.35, zc)), Vector3(0.16, 0.5, largo + 0.1))
		## La cornisa del club con el nombre.
		lote.caja(cornisa, _en(Vector3(xf + lado * 0.1, alto - 0.55, zc)), Vector3(0.16, 1.1, largo + 0.1))
		_letrero(nodo, nombre_club, Vector3(xf + lado * 0.2, alto - 0.55, zc), giro, largo - 1.0)
	## LA FACHADA DE ATRÁS (mira a +Z): de la planta 1 para arriba, por encima
	## del pórtico de la entrada.
	var ancho := xs * 2.0
	var zf := z1
	var y_ini := EdificioClub.ALTO_PLANTA - 0.6
	lote.caja(placa, _en(Vector3(x0, (y_ini + alto) / 2.0, zf + 0.02)), Vector3(ancho, alto - y_ini, 0.04))
	lote.caja(blanco, _en(Vector3(x0, EdificioClub.ALTO_PLANTA - 0.35, zf + 0.1)), Vector3(ancho + 0.1, 0.5, 0.16))
	for p: int in [1, 2]:
		var y0 := float(p) * EdificioClub.ALTO_PLANTA
		lote.caja(vidrio, _en(Vector3(x0, y0 + 2.0, zf + 0.05)), Vector3(ancho - 0.8, 2.2, 0.04))
		var x := x0 - xs + 0.4
		while x <= x0 + xs - 0.4 + 0.01:
			lote.caja(blanco, _en(Vector3(x, y0 + 2.0, zf + 0.09)), Vector3(0.08, 2.3, 0.08))
			x += MONTANTE
		if p < 2:
			lote.caja(blanco, _en(Vector3(x0, y0 + EdificioClub.ALTO_PLANTA - 0.35, zf + 0.1)), Vector3(ancho + 0.1, 0.5, 0.16))
	lote.caja(cornisa, _en(Vector3(x0, alto - 0.55, zf + 0.1)), Vector3(ancho + 0.3, 1.1, 0.16))
	_letrero(nodo, nombre_club, Vector3(x0, alto - 0.55, zf + 0.2), 0.0, ancho - 1.0)
	lote.montar(nodo, "Fachada")
	return lote

static func _en(p: Vector3) -> Transform3D:
	return Transform3D(Basis.IDENTITY, p)

## El nombre del club en letras blancas sobre la cornisa, ajustado al ancho.
static func _letrero(nodo: Node3D, texto: String, p: Vector3, giro: float, ancho: float) -> void:
	var l := Label3D.new()
	l.text = texto.to_upper()
	l.pixel_size = 0.01
	l.font_size = clampi(int(ancho / (float(maxi(1, texto.length())) * 0.62 * l.pixel_size)), 24, 80)
	l.modulate = Color(1, 1, 1)
	l.outline_size = 0
	l.position = p
	l.rotation.y = giro
	l.double_sided = false
	l.shaded = false
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.name = "LetreroClub"
	nodo.add_child(l)
