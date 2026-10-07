extends Node
## Camisetas 2D con sus patrocinadores (frente y espalda) de varios clubes.
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	m.auspicio.contrato = {"marca": "Cerveza Andin4", "color": "#e8b13a", "monto": 1, "exig_pos": 5, "anio": 2026}
	m.comercial.zonas_firmadas["manga"] = {"marca": "AeroC0ndor", "color": "#4ab3d5"}
	m.comercial.zonas_firmadas["espalda"] = {"marca": "Banc0 Austral", "color": "#3a7bd5"}
	var lienzo := Image.create(1400, 640, false, Image.FORMAT_RGBA8)
	lienzo.fill(Color("1b2027"))
	var disenos := ["v_ancha", "panal_3", "llamas", "mosaico_3", "vichy", "estela_3", "rombo_central", "cebra_3"]
	for i in 8:
		var c: Club = m.ligas[0].clubes[i]
		var k := DisenosKit.kit_de_club(c)
		k["dis"] = disenos[i]
		print(c.nombre, " sp=", k["sp"])
		for lado in 2:
			var t := DisenosKit.textura_completa(k, lado == 1, 160)
			var img := t.get_image()
			lienzo.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i(10 + i * 172, 10 + lado * 310))
	lienzo.save_png("res://pruebas/capturas/sponsors_2d.png")
	get_tree().quit()
