extends BaseIdea
## RETRATO 3D CON RENDERIZADO DE VERDAD (ppru, 26-10-2026; plan M-406: «Retrato3D no se ejercita
## en headless; sin prueba con xvfb»). `f0m_visor_piezas` solo mira el encargo (marcador, caché, cola),
## porque sin pantalla no se pinta nada. Esta prueba monta el busto con el renderizador del juego
## (Forward+ con lavapipe bajo xvfb) y mira la IMAGEN que llega a la textura:
##   · tamaño (256 grande, 128 de cabeza), que no sea un color liso (varianza) ni el marcador;
##   · que el centro tenga algo distinto del fondo (la cara/el busto) y la esquina de arriba sea fondo;
##   · que dos jugadores distintos den retratos distintos.
## Se lanza con `herramientas/ppru_retrato.sh` (xvfb + Vulkan). Con `ideas.sh` (headless) no hay nada
## que pintar: avisa y no cuenta como fallo, salvo si `PPRU_EXIGIR_PANTALLA=1` (lo pone el .sh).

const SEMILLA := 4062026
const K1 := "#1f4fa8"
const K2 := "#ffffff"
## Fotogramas máximos esperando a que la cola de retratos se vacíe (uno por fotograma + 3 de espera).
const MAX_FOTOGRAMAS := 900

func _ready() -> void:
	await get_tree().process_frame
	await _probar_async()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _probar_async() -> void:
	_titulo("M-406: Retrato3D con renderizado real (xvfb)")
	if not Retrato3D.disponible():
		var exigir := OS.get_environment("PPRU_EXIGIR_PANTALLA") == "1"
		_linea("  (sin pantalla: esta prueba se lanza con herramientas/ppru_retrato.sh)")
		_comprobar(not exigir, "hay pantalla para renderizar (PPRU_EXIGIR_PANTALLA=1)")
		return
	var m := _mundo(SEMILLA)
	var par := _dos_distintos(m.mi_club().plantilla)
	var ja: Jugador = par[0]
	var jb: Jugador = par[1]
	_linea("  jugadores: %s y %s" % [ja.id, jb.id])
	Retrato3D.limpiar_cache()
	var ta := Retrato3D.textura(ja, K1, K2, 150)
	var tb := Retrato3D.textura(jb, K1, K2, 150)
	var tc := Retrato3D.textura(ja, K1, K2, 30)
	var marcador := ta.get_image().duplicate() as Image
	marcador.convert(Image.FORMAT_RGBA8)
	var marcador_c := tc.get_image().duplicate() as Image
	marcador_c.convert(Image.FORMAT_RGBA8)
	var n := 0
	while n < MAX_FOTOGRAMAS and (not Retrato3D._cola.is_empty() or _ocupado()):
		await get_tree().process_frame
		n += 1
	await get_tree().process_frame
	_comprobar(Retrato3D._cola.is_empty() and not _ocupado(), "la cola de retratos se vació en %d fotogramas (máx. %d)" % [n, MAX_FOTOGRAMAS])
	var ia := _img(ta)
	var ib := _img(tb)
	var ic := _img(tc)
	_comprobar(ia != null and ib != null and ic != null, "las tres texturas tienen imagen")
	if ia == null or ib == null or ic == null:
		return
	_comprobar(ia.get_size() == Vector2i(Retrato3D.TAM_GRANDE, Retrato3D.TAM_GRANDE) and ic.get_size() == Vector2i(Retrato3D.TAM_CHICO, Retrato3D.TAM_CHICO),
		"tamaños: grande %s (esperado %d), cabeza %s (esperado %d)" % [ia.get_size(), Retrato3D.TAM_GRANDE, ic.get_size(), Retrato3D.TAM_CHICO])
	for par_img in [["grande A", ia, marcador], ["grande B", ib, marcador], ["cabeza A", ic, marcador_c]]:
		_revisar(String(par_img[0]), par_img[1], par_img[2])
	## Contraprueba: las medidas distinguen. El marcador (lo que se vería si el busto no llegara)
	## y un cuadro liso NO pasarían las comprobaciones de arriba.
	var liso := Image.create(Retrato3D.TAM_GRANDE, Retrato3D.TAM_GRANDE, false, Image.FORMAT_RGBA8)
	liso.fill(Color(K1))
	_comprobar(_figura_centro(marcador) < 0.5 and _fraccion_distinta(marcador, marcador, 0.06) == 0.0 and _varianza_luz(liso) < 0.002,
		"contraprueba: el marcador (centro %.0f %%) y un cuadro liso suspenderían" % (_figura_centro(marcador) * 100.0))
	var dab := _fraccion_distinta(ia, ib, 0.08)
	_comprobar(dab > 0.03, "dos jugadores distintos dan retratos distintos (%.1f %% de píxeles cambian, mín. 3 %%)" % (dab * 100.0))
	var dac := _fraccion_distinta(ia, _escalada(ic, ia.get_size()), 0.08)
	_comprobar(dac > 0.05, "el encuadre de cabeza no es el de pecho reescalado (%.1f %% distinto)" % (dac * 100.0))
	if OS.get_environment("PPRU_GUARDAR") != "":
		DirAccess.make_dir_recursive_absolute(OS.get_environment("PPRU_GUARDAR"))
		ia.save_jpg(OS.get_environment("PPRU_GUARDAR") + "/retrato_a.jpg")
		ib.save_jpg(OS.get_environment("PPRU_GUARDAR") + "/retrato_b.jpg")
		ic.save_jpg(OS.get_environment("PPRU_GUARDAR") + "/retrato_cabeza.jpg")
	Retrato3D.limpiar_cache()

## Comprobaciones de UNA imagen: no lisa, no es el marcador, fondo arriba y figura en el centro.
func _revisar(nombre: String, img: Image, marcador: Image) -> void:
	var var_l := _varianza_luz(img)
	_comprobar(var_l > 0.002, "%s: no es de un solo color (varianza de luz %.4f, mín. 0,002)" % [nombre, var_l])
	var cambio := _fraccion_distinta(img, marcador, 0.06)
	_comprobar(cambio > 0.25, "%s: el busto sustituyó al marcador (%.0f %% de píxeles cambian, mín. 25 %%)" % [nombre, cambio * 100.0])
	var tam := img.get_width()
	## El fondo: lo que hay en las dos esquinas de ARRIBA (el busto no llega ahí).
	var fi := img.get_pixel(2, 2)
	var fd := img.get_pixel(tam - 3, 2)
	_comprobar(_dist(fi, fd) < 0.06, "%s: las esquinas de arriba son fondo liso (diferencia %.3f)" % [nombre, _dist(fi, fd)])
	## El centro (el 40 % del medio) es casi todo figura: distinto del fondo.
	var f_centro := _figura_centro(img)
	_comprobar(f_centro > 0.5, "%s: la figura ocupa el centro (%.0f %% del centro distinto del fondo, mín. 50 %%)" % [nombre, f_centro * 100.0])
	## Y una franja del borde de arriba es fondo (la cabeza no está cortada ni el encuadre desplazado).
	var arriba := 0
	for x in tam:
		if _dist(img.get_pixel(x, 1), fi) < 0.06:
			arriba += 1
	_comprobar(float(arriba) / float(tam) > 0.3, "%s: hay fondo en la fila de arriba (%d de %d píxeles)" % [nombre, arriba, tam])

## Fracción del 40 % central de la imagen que se aparta del fondo (la esquina de arriba a la izquierda).
func _figura_centro(img: Image) -> float:
	var tam := img.get_width()
	var fondo := img.get_pixel(2, 2)
	var fig := 0
	var tot := 0
	for y in range(int(tam * 0.3), int(tam * 0.7)):
		for x in range(int(tam * 0.3), int(tam * 0.7)):
			tot += 1
			if _dist(img.get_pixel(x, y), fondo) > 0.2:
				fig += 1
	return float(fig) / float(maxi(tot, 1))

func _ocupado() -> bool:
	return Retrato3D._inst != null and is_instance_valid(Retrato3D._inst) and Retrato3D._inst._ocupado

func _img(t: Texture2D) -> Image:
	if t == null:
		return null
	var i := t.get_image()
	if i == null or i.is_empty():
		return null
	i.convert(Image.FORMAT_RGBA8)
	return i

## Dos jugadores con la piel MÁS distinta de la plantilla (para que la diferencia no dependa del dorsal).
func _dos_distintos(pl: Array[Jugador]) -> Array:
	var mejor := [pl[0], pl[1]]
	var dmax := -1.0
	for i in pl.size():
		var li: Array = PlayerSpawner._look_de(Puente3D.jugador(pl[i]))
		for k in range(i + 1, pl.size()):
			var lk: Array = PlayerSpawner._look_de(Puente3D.jugador(pl[k]))
			var d := _dist(li[0], lk[0]) + _dist(li[1], lk[1])
			if d > dmax:
				dmax = d
				mejor = [pl[i], pl[k]]
	return mejor

func _dist(a: Color, b: Color) -> float:
	return (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) / 3.0

func _varianza_luz(img: Image) -> float:
	var s := 0.0
	var s2 := 0.0
	var n := 0
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			var l := img.get_pixel(x, y).get_luminance()
			s += l
			s2 += l * l
			n += 1
	var med := s / n
	return s2 / n - med * med

func _fraccion_distinta(a: Image, b: Image, umbral: float) -> float:
	if a.get_size() != b.get_size():
		return 1.0
	var d := 0
	var n := 0
	for y in range(0, a.get_height(), 2):
		for x in range(0, a.get_width(), 2):
			n += 1
			if _dist(a.get_pixel(x, y), b.get_pixel(x, y)) > umbral:
				d += 1
	return float(d) / float(maxi(n, 1))

func _escalada(img: Image, tam: Vector2i) -> Image:
	var c := img.duplicate() as Image
	c.resize(tam.x, tam.y, Image.INTERPOLATE_BILINEAR)
	return c
