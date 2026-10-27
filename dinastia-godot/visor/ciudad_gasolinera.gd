class_name CiudadGasolinera
extends RefCounted
## LA GASOLINERA POR ARRIBA (27-10-2026, relleno de la ciudad). Era una losa blanca sobre cuatro palos, un cubo rojo y una caja.
## Ahora: marquesina con faldón de color y luz propia, islas de hormigón bajo los surtidores, tienda de conveniencia con la
## fachada modular (`FachadaModular`) y un poste de precios en la esquina. LOS SURTIDORES NO SE TOCAN: los pone
## `RedesCiudad` (visor/redes_ciudad_vista.gd) en c ± (0,09 y 0,2)·ancho, con su punto «Repostar» y su lógica; esto solo los cubre.
const ALTO_MARQUESINA := 5.6

static func montar(ex: CiudadExpansion, c: Vector3, w: float, f: float) -> void:
	var b := ex.b
	var blanco := b._mat_simple(Color(0.93, 0.93, 0.94), 0.5)
	var rojo := b._mat_simple(Color(0.82, 0.14, 0.12), 0.5)
	var hormigon := b._mat_simple(Color(0.62, 0.62, 0.6), 0.9)
	var ancho_m := minf(w * 0.5, 40.0)
	var fondo_m := minf(f * 0.4, 20.0)
	## Marquesina: losa fina, faldón rojo y banda inferior luminosa, sobre cuatro pilares.
	b._caja_en(c + Vector3(0, ALTO_MARQUESINA, 0), Vector3(ancho_m, 0.5, fondo_m), blanco)
	b._caja_en(c + Vector3(0, ALTO_MARQUESINA - 0.1, fondo_m * 0.5), Vector3(ancho_m + 0.4, 1.1, 0.3), rojo)
	b._caja_en(c + Vector3(0, ALTO_MARQUESINA - 0.1, -fondo_m * 0.5), Vector3(ancho_m + 0.4, 1.1, 0.3), rojo)
	b._caja_en(c + Vector3(0, ALTO_MARQUESINA - 0.32, 0), Vector3(ancho_m - 2.0, 0.06, fondo_m - 2.0), b._mat_simple(Color(1, 0.97, 0.85), 0.4, 1.6))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			b._cil_en(c + Vector3(sx * ancho_m * 0.4, ALTO_MARQUESINA * 0.5, sz * fondo_m * 0.36), 0.3, ALTO_MARQUESINA, blanco)
	## Islas de hormigón bajo los dos grupos de surtidores (en c.x ± 0,145·w, a lo largo de x) con bordillo rojo.
	for sx: float in [-1.0, 1.0]:
		b._caja_en(c + Vector3(sx * w * 0.145, 0.45, 0.0), Vector3(w * 0.13, 0.3, 1.6), hormigon)
		b._caja_en(c + Vector3(sx * w * 0.145, 0.62, 0.0), Vector3(w * 0.13 + 0.2, 0.06, 1.8), rojo)
	## Tienda al fondo (norte), de cara a las islas: volumen, cubierta y fachada modular de una planta.
	var zt := c.z - f * 0.36
	var ancho_t := 19.2
	b._caja_en(Vector3(c.x, c.y + 2.3, zt - 3.0), Vector3(ancho_t, 4.0, 6.0), blanco)
	b._caja_en(Vector3(c.x, c.y + 4.4, zt - 3.0), Vector3(ancho_t + 0.6, 0.4, 7.0), rojo)
	FachadaModular.montar(ex, c.x, zt, c.y + 0.3, ancho_t, 1)
	## Un cajero automático junto a la puerta de la tienda.
	CajeroCiudad.montar(ex, Vector3(c.x - ancho_t * 0.5 - 1.6, c.y + 0.3, zt + 1.2), 0.0)
	## El mostrador de la tienda (E): punto de la ciudad, uno por gasolinera.
	b.puntos_clic.append({"k": "tienda_%d" % (absi(hash(Vector2(c.x, c.z))) % 100000), "n": Idiomas.t("Tienda de la gasolinera"), "pos": Vector3(c.x, 0, zt + 3.6),
		"estado": "ciudad", "radio": 10.0, "alcance": 6.0})
	## Poste de precios en la esquina de la calle (sureste), con el cartel a dos caras.
	var pos := c + Vector3(w * 0.4, 0, f * 0.4)
	b._cil_en(pos + Vector3(0, 4.0, 0), 0.25, 8.0, hormigon)
	b._caja_en(pos + Vector3(0, 8.6, 0), Vector3(3.2, 2.6, 0.4), blanco)
	b._caja_en(pos + Vector3(0, 9.55, 0), Vector3(3.2, 0.7, 0.45), rojo)
	b._rotulo(pos + Vector3(0, 8.4, 0.25), Idiomas.t("Gasolina"), Color(0.8, 0.1, 0.1), 40)
