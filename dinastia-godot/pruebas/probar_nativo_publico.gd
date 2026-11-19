class_name ProbarNativoPublico
extends RefCounted
## (19-11-2026) EL PÚBLICO DE LA TEXTURA DE GRADA EN C++ = GDScript (`nativo/src/publico_nativo.cpp`; gemela `StadiumBuilder._pintar_publico_gd`). Texturas de varios tamaños y llenos
## sobre un fondo al azar y varios colores: se comparan los bytes y el estado del generador al terminar (la siguiente tirada tiene que ser la misma). Devuelve {fallos, textos}.
static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var comparados := 0
	for caso in [[64, 64, 0.0], [128, 256, 0.5], [256, 128, 1.0], [512, 256, 0.85], [100, 77, 0.33], [32, 600, 0.9], [8, 8, 0.7]]:
		var w: int = caso[0]
		var h: int = caso[1]
		var lleno: float = caso[2]
		var fondo := PackedByteArray()
		fondo.resize(w * h * 3)
		var azar := RandomNumberGenerator.new()
		azar.seed = 9 + w
		for i in fondo.size():
			fondo[i] = azar.randi() % 256
		var a := Image.create_from_data(w, h, false, Image.FORMAT_RGB8, fondo)
		var b := Image.create_from_data(w, h, false, Image.FORMAT_RGB8, fondo)
		var r_gd := RandomNumberGenerator.new()
		r_gd.seed = 4242
		var r_c := RandomNumberGenerator.new()
		r_c.seed = 4242
		StadiumBuilder._pintar_publico_gd(a, w, h, Color(0.8, 0.1, 0.1), Color(0.95, 0.95, 0.2), lleno, r_gd)
		var hecha: Image = nat.publico_pintar(b, w, h, Color(0.8, 0.1, 0.1), Color(0.95, 0.95, 0.2), lleno, r_c)
		comparados += 1
		if hecha == null or a.get_data() != hecha.get_data():
			fallos.append("público de %dx%d con lleno %s distinto" % [w, h, lleno])
		if r_gd.state != r_c.state or r_gd.randi() != r_c.randi():
			fallos.append("el generador quedó en otro estado (%dx%d)" % [w, h])
	## Las texturas de grada enteras (patrón + grano + público): la gemela con la extensión APAGADA para que sea GDScript puro.
	var a1 := Color(0.8, 0.1, 0.1)
	var a2 := Color(0.95, 0.95, 0.2)
	var a3 := Color(0.1, 0.2, 0.7)
	for patron: String in ["franjas", "vertical3", "aros", "damero", "degrade", "bicolor", "diagonal", "moteado", "sectores", "mosaico", "ola", "bandera", "liso"]:
		for lleno in [0.0, 0.6, 1.0]:
			Nativo._obj = null
			Nativo._mirado = true
			var g_gd: Image = StadiumBuilder._make_stand_texture_gd(patron, a1, a2, a3, 31, lleno)
			Nativo._mirado = false
			var g_c: Image = nat.grada_imagen(patron, a1, a2, a3, 31, lleno)
			g_gd.generate_mipmaps()
			g_c.generate_mipmaps()
			comparados += 1
			if g_c == null or g_gd.get_data() != g_c.get_data():
				fallos.append("grada «%s» con lleno %s distinta" % [patron, lleno])
	for caso in [[["franjas", "damero", "ola"], [[a1, a2, a3], [a2, a3, a1], [a3, a1, a2]]], [["moteado"], [[a1, a2]]], [["sectores", "aros", "bandera", "diagonal"], [[a1, a2, a3], [a3, a2]]], [["bicolor", "degrade", "mosaico"], [[a1, a2, a3], [a2, a1, a3], [Color.WHITE, Color.BLACK, Color.GRAY]]]]:
		Nativo._obj = null
		Nativo._mirado = true
		var t_gd: Image = StadiumBuilder._make_stand_texture_tramos_gd(caso[0], caso[1], 77, 0.75)
		Nativo._mirado = false
		var t_c: Image = nat.grada_tramos(caso[0], caso[1], 77, 0.75)
		t_gd.generate_mipmaps()
		t_c.generate_mipmaps()
		comparados += 1
		if t_c == null or t_gd.get_data() != t_c.get_data():
			fallos.append("grada de tramos %s distinta" % [caso[0]])
	comparados += 1
	var raro := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	if nat.publico_pintar(raro, 16, 16, Color.RED, Color.BLUE, 0.5, RandomNumberGenerator.new()) != null:
		fallos.append("una imagen que no es RGB8 debía dar null")
	return {"fallos": fallos, "textos": ["público de grada: %d texturas comparadas (bytes y estado del azar)" % comparados]}
