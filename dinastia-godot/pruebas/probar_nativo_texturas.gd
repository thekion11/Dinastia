class_name ProbarNativoTexturas
extends RefCounted
## (19-11-2026) LAS TEXTURAS PROCEDIMENTALES EN C++ = GDScript (`nativo/src/texturas_nativo.cpp`): los trapos pintados (`TelonesPintados._imagen_gd`, 5 patrones × giro × pares de
## colores, también casi iguales y claros), el azulejo (`VestuarioRealista._azulejo_gd`) y el corte del césped (`CespedTextura.nueva_gd`, los 11 patrones y uno desconocido).
## Se comparan los bytes de cada imagen. Devuelve {fallos, textos}.
static func _igual(a: Image, b: Image) -> bool:
	return b != null and a.get_width() == b.get_width() and a.get_height() == b.get_height() and a.get_format() == b.get_format() and a.get_data() == b.get_data()

static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var comparadas := 0
	var pares := [[Color(0.8, 0.1, 0.1), Color(0.95, 0.95, 0.95)], [Color(0.1, 0.2, 0.6), Color(0.12, 0.2, 0.55)], [Color(0.95, 0.95, 0.9), Color(0.9, 0.92, 0.9)],
		[Color("2e7d32"), Color("fdd835")], [Color(0.3, 0.3, 0.3), Color(0.1, 0.1, 0.1)]]
	for par: Array in pares:
		for p in range(5):
			for girado in [false, true]:
				var a: Image = TelonesPintados._imagen_gd(par[0], par[1], p, girado)
				var b: Image = nat.telon_imagen(par[0], par[1], p, girado)
				b.generate_mipmaps()
				comparadas += 1
				if not _igual(a, b):
					fallos.append("trapo patrón %d giro %s colores %s distinto" % [p, girado, par])
	var az: Array = VestuarioRealista._azulejo_gd(256)
	var azc: Array = nat.azulejo_imagenes(256)
	for i in 2:
		comparadas += 1
		if not _igual(az[i], azc[i]):
			fallos.append("azulejo, imagen %d distinta" % i)
	for patron: String in ["rayas", "rayasH", "damero", "damGrande", "circular", "circulos", "diagonal", "espiga", "cruz", "abanico", "rombos", "mitades", "liso", "desconocido"]:
		for cols in [[Color(0.3, 0.6, 0.2), Color(0.2, 0.5, 0.15)], [Color(0.9, 0.95, 0.4), Color(0.1, 0.3, 0.05)]]:
			comparadas += 1
			if not _igual(CespedTextura.nueva_gd(patron, cols[0], cols[1]), nat.cesped_imagen(patron, cols[0], cols[1])):
				fallos.append("césped «%s» distinto" % patron)
	return {"fallos": fallos, "textos": ["texturas: %d imágenes comparadas (trapos, azulejo, césped)" % comparadas]}
