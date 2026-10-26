extends BaseIdea
## s3 (26-10-2026): la métrica de las pruebas visuales (`pruebas/visual/visual.gd`), sin pantalla.
## Las capturas de verdad necesitan Vulkan (`herramientas/visual.sh`); esto comprueba que la
## comparación por bloques dice «igual» a lo igual y ve un cambio local pequeño.
const V := preload("res://pruebas/visual/visual.gd")

func _probar() -> void:
	_titulo("S3: MÉTRICA DE LAS PRUEBAS VISUALES (comparación por bloques)")
	var a := Image.create(1280, 720, false, Image.FORMAT_RGB8)
	a.fill(Color(0.08, 0.1, 0.09))
	var b := a.duplicate() as Image
	var d0: Vector3 = V.diferencia(a, b)
	_comprobar(int(d0.z) == 0 and d0.x == 0.0, "dos pantallas iguales: ningún bloque cambia")
	## Un rótulo claro de 90×40 px (lo que ocupa una palabra en la cabecera).
	b.fill_rect(Rect2i(600, 330, 90, 40), Color(0.9, 0.9, 0.9))
	var d1: Vector3 = V.diferencia(a, b)
	_comprobar(int(d1.z) >= V.MIN_BLOQUES, "un rótulo nuevo de 90×40 px se ve (%d bloques, media %.2f %%)" % [int(d1.z), d1.x * 100.0])
	## Ruido de JPG: la misma imagen guardada y leída al 85 % no cambia.
	var c := a.duplicate() as Image
	c.fill_rect(Rect2i(100, 100, 300, 200), Color(0.5, 0.3, 0.2))
	var jpg := Image.new()
	jpg.load_jpg_from_buffer(c.save_jpg_to_buffer(V.CALIDAD_REF))
	var d2: Vector3 = V.diferencia(c, jpg)
	_comprobar(int(d2.z) == 0, "el ruido del JPG de referencia no cuenta como cambio (peor bloque %.1f %%)" % (d2.y * 100.0))
	## Un tinte suave sobre una zona oscura (la tabla ×0,75 en verde y azul): no llega al umbral
	## por bloque, pero el color medio se desplaza siempre en el mismo sentido.
	var t := a.duplicate() as Image
	var u := a.duplicate() as Image
	for y in range(100, 600):
		for x in range(80, 420):
			u.set_pixel(x, y, Color(0.10, 0.12 * 0.75, 0.11 * 0.75))
			t.set_pixel(x, y, Color(0.10, 0.12, 0.11))
	var d3: Vector3 = V.diferencia(t, u)
	_comprobar(int(d3.z) < V.MIN_BLOQUES and V.tono_bloques >= V.MIN_TONO,
		"un tinte suave no pasa el umbral por bloque (%d) pero sí el de tono (%d bloques)" % [int(d3.z), V.tono_bloques])
	V.diferencia(c, jpg)
	_comprobar(V.tono_bloques == 0, "y el ruido del JPG no mueve el tono (%d bloques)" % V.tono_bloques)
	var m: Image = V.mapa(a, b)
	_comprobar(m.get_width() == V.COMPARA.x * 4, "el mapa de diferencias sale (%d px de ancho)" % m.get_width())
