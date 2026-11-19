class_name ProbarNativoAsfalto
extends RefCounted
## (19-11-2026) LA IMAGEN DEL ASFALTO EN C++ = GDScript (`nativo/src/asfalto_nativo.cpp`; gemela `Texturas._pixeles_asfalto_gd`). Los tres ruidos reales a 64, 200 y 512 px con
## varios tintes y semillas; se comparan los bytes RGB8. Además, un ruido que no es L8 debe devolver null. Devuelve {fallos, textos}.
static func probar(nat: Object) -> Dictionary:
	var fallos: Array[String] = []
	var textos: Array[String] = []
	var comparados := 0
	var t_gd := 0
	var t_c := 0
	for caso in [[64, 23, Color(0.17, 0.175, 0.185)], [200, 5, Color(0.9, 0.3, 0.1)], [512, 23, Color(0.17, 0.175, 0.185)], [512, 777, Color(1, 1, 1)]]:
		var n: int = caso[0]
		var semilla: int = caso[1]
		var tinte: Color = caso[2]
		var grande := Texturas._ruido(FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.004, semilla, 3)
		var medio := Texturas._ruido(FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.03, semilla + 1, 3)
		var grieta := Texturas._ruido(FastNoiseLite.TYPE_CELLULAR, 0.012, semilla + 2, 1)
		grieta.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
		var ig := grande.get_seamless_image(n, n)
		var im := medio.get_seamless_image(n, n)
		var ic := grieta.get_seamless_image(n, n)
		var t0 := Time.get_ticks_usec()
		var a: Image = Texturas._pixeles_asfalto_gd(ig, im, ic, tinte, semilla, n)
		var t1 := Time.get_ticks_usec()
		var b: Image = nat.asfalto_imagen(ig, im, ic, tinte, semilla, n)
		var t2 := Time.get_ticks_usec()
		t_gd += t1 - t0
		t_c += t2 - t1
		comparados += 1
		if b == null or a.get_data() != b.get_data() or a.get_format() != b.get_format() or a.get_width() != b.get_width():
			var cuantos := 0
			if b != null and a.get_data().size() == b.get_data().size():
				var da := a.get_data()
				var db := b.get_data()
				for i in da.size():
					if da[i] != db[i]:
						cuantos += 1
			fallos.append("asfalto %d px (semilla %d) distinto (%d bytes)" % [n, semilla, cuantos])
	comparados += 1
	var rgb := Image.create(64, 64, false, Image.FORMAT_RGB8)
	if nat.asfalto_imagen(rgb, rgb, rgb, Color.WHITE, 1, 64) != null:
		fallos.append("un ruido que no es L8 debía dar null")
	## La enredadera (`Texturas._imagen_enredadera_gd`): varias semillas y tamaños.
	for caso2 in [[71, 256], [29, 256], [1, 128], [4242, 256], [0, 64]]:
		var e_gd: Image = Texturas._imagen_enredadera_gd(caso2[0], caso2[1])
		var e_c: Image = nat.enredadera_imagen(caso2[0], caso2[1])
		comparados += 1
		if e_c == null or e_gd.get_data() != e_c.get_data():
			var malos := 0
			if e_c != null and e_gd.get_data().size() == e_c.get_data().size():
				var da2 := e_gd.get_data()
				var db2 := e_c.get_data()
				for i in da2.size():
					if da2[i] != db2[i]:
						malos += 1
			fallos.append("enredadera (semilla %d, %d px) distinta (%d bytes)" % [caso2[0], caso2[1], malos])
	textos.append("asfalto y enredadera: %d imágenes comparadas; GDScript %d ms, C++ %d ms" % [comparados, t_gd / 1000, t_c / 1000])
	return {"fallos": fallos, "textos": textos}
