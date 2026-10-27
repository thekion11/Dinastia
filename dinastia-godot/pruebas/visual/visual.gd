extends Node
## PRUEBAS VISUALES AUTOMÁTICAS (s3, 26-10-2026; plan §10 «Pruebas visuales automáticas»).
## Recorre 20 pantallas clave de la Principal con un mundo de semilla fija, las fotografía con el
## renderizador del juego (Forward+) y las compara con las referencias de `referencias/`: JPG de
## 640×360 (~40 KB, archivos normales: NO van a LFS). Cada pantalla se compara reducida a 320×180
## y por bloques (ver `diferencia`): CAMBIÓ si al menos `MIN_BLOQUES` bloques pasan de
## `UMBRAL_BLOQUE` (calibrado con el ruido del JPG y de los fondos animados: ver sesion_3.md).
## De las que cambian deja la foto actual y un mapa de diferencias.
##   herramientas/visual.sh              → compara (código 0 = «FIN. 0 fallos»)
##   herramientas/visual.sh referencias  → vuelve a hacer las referencias (tras un cambio querido)
## Salida de las que cambiaron: /tmp/visual/<pantalla>_actual.jpg y <pantalla>_dif.png.
## Sin GPU tarda ~2 min (lavapipe). Una pantalla nueva: añadirla a `PANTALLAS` y regenerar.
const SEMILLA := 20261026
const ANCHO_REF := 640
## Calidad del JPG de referencia: con 0,72 el ruido del JPG llegaba al 3,9 % en el peor bloque.
const CALIDAD_REF := 0.85
const COMPARA := Vector2i(320, 180)
const LADO_BLOQUE := 10
## Un bloque cambia si la diferencia media de sus píxeles pasa de esto (0..1).
const UMBRAL_BLOQUE := 0.04
## Y la pantalla CAMBIÓ si cambian al menos estos bloques (uno solo puede ser ruido).
const MIN_BLOQUES := 2
## Desplazamiento del color medio de un bloque (0..1) y bloques necesarios para un cambio de tono.
const UMBRAL_TONO := 0.012
const MIN_TONO := 6
const SALTO_PIXEL := 0.25
const REFS := "res://pruebas/visual/referencias/"
const SALIDA := "/tmp/visual/"
## [nombre, pestaña, sección (o "")]
const PANTALLAS := [
	["inicio", "Inicio", ""], ["plantel", "Mi plantel", ""], ["tactica", "Táctica", ""],
	["entrenar", "Entrenar", ""], ["enfermeria", "Enfermería", ""], ["cantera", "Cantera", ""],
	["contratos", "Contratos", ""], ["calendario", "Calendario", ""], ["finanzas", "Finanzas", ""],
	["mercado", "Mercado", ""], ["clubes", "Clubes", ""], ["copa", "Copa", ""],
	["correo", "Correo", ""], ["estadio", "Estadio", ""], ["identidad", "Gente", "identidad"],
	["personal", "Club", "staff"], ["records", "Récords", "records"], ["redes", "Redes", "redes"],
	["ajustes", "Ajustes", "aspecto"], ["glosario", "Glosario", ""],
]
const ESPERA := 12
const MAX_ESPERA := 150
var _previa: Image
var _quietos := 0

var _p: Principal
var _n := 0
var _i := -1
var _hacer_refs := OS.get_environment("VISUAL") == "referencias"
## VISUAL=capturas: solo guarda las 20 a tamaño real en /tmp/visual/capturas/ (para revisar a ojo
## otro idioma o resolución), sin comparar. VISUAL_IDIOMA=de|tr|… cambia el idioma.
var _solo_capturas := OS.get_environment("VISUAL") == "capturas"
var _idioma_antes := ""
var _cambiadas: Array[String] = []
var _nuevas: Array[String] = []

func _ready() -> void:
	AjustesCiudad.guardar("tutorial_visto", true)
	## Sin fundidos a medias en la foto: animaciones reducidas (solo en memoria, no se
	## guarda en los ajustes del jugador) y el reloj a ×10 para los fundidos que no
	## pasan por `Animar` (filas que entran escalonadas).
	Animar._reducidas = 1
	Engine.time_scale = 10.0
	var m := Mundo.new()
	m.generar([], SEMILLA)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	PedidoPartida.mundo_pregenerado = m
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	DirAccess.make_dir_recursive_absolute(SALIDA)

func _process(_d: float) -> void:
	_n += 1
	if _n < 10:
		return
	if _i < 0:
		## El idioma lo decide la prueba, no las preferencias de la máquina (se
		## restaura al terminar, para no dejárselo cambiado al jugador).
		_idioma_antes = Idiomas.idioma
		Idiomas.idioma = OS.get_environment("VISUAL_IDIOMA") if OS.get_environment("VISUAL_IDIOMA") != "" else "es"
		_p._refrescar()
		## Una partida nueva abre el tutorial de bienvenida encima de todo: se salta.
		for t in get_tree().root.find_children("*", "", true, false):
			if t is Tutorial:
				(t as Tutorial)._terminar(false)
		_siguiente()
		return
	## Cada pantalla, tras pintarse y con los retratos 3D ya hechos.
	if _n < ESPERA or not Retrato3D._cola.is_empty():
		return
	_sabotaje()
	## Quieta: lo que se pinta poco a poco (miniaturas, muestras, fundidos) ya terminó
	## cuando dos fotogramas seguidos no se distinguen. Si nunca se queda quieta, a los
	## `MAX_ESPERA` se fotografía igual (y la comparación dirá si eso es un problema).
	var ahora := get_viewport().get_texture().get_image()
	var quieta := _previa != null and int(diferencia(ahora, _previa).z) == 0
	_quietos = _quietos + 1 if quieta else 0
	_previa = ahora
	if _quietos < 2 and _n < MAX_ESPERA:
		return
	_previa = null
	_quietos = 0
	_foto(String(PANTALLAS[_i][0]))
	_siguiente()

func _siguiente() -> void:
	_i += 1
	_n = 0
	if _i >= PANTALLAS.size():
		_terminar()
		return
	var pt: Array = PANTALLAS[_i]
	if String(pt[2]) != "":
		_p._ir_a_chip({"tab": pt[1], "secc": pt[2], "label": pt[0]})
	else:
		_p._ir_a_pestana(String(pt[1]))

func _foto(nombre: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	var ref := img.duplicate() as Image
	ref.resize(ANCHO_REF, ANCHO_REF * img.get_height() / maxi(1, img.get_width()), Image.INTERPOLATE_LANCZOS)
	if _solo_capturas:
		var dir := SALIDA + "capturas/"
		DirAccess.make_dir_recursive_absolute(dir)
		img.save_jpg(dir + "%s_%dx%d_%s.jpg" % [Idiomas.idioma, img.get_width(), img.get_height(), nombre], 0.85)
		print("CAPTURA %s" % nombre)
		return
	var ruta := REFS + nombre + ".jpg"
	if _hacer_refs or not FileAccess.file_exists(ruta):
		ref.save_jpg(ruta, CALIDAD_REF)
		_nuevas.append(nombre)
		print("REFERENCIA %s" % nombre)
		return
	var vieja := Image.load_from_file(ProjectSettings.globalize_path(ruta))
	var d := diferencia(ref, vieja)
	var cambia := int(d.z) >= MIN_BLOQUES or tono_bloques >= MIN_TONO
	print("%s %-11s media %.2f %%  peor bloque %.1f %% %s  bloques %d  tono %d" % ["CAMBIÓ" if cambia else "igual ", nombre, d.x * 100.0, d.y * 100.0, str(peor_bloque), int(d.z), tono_bloques])
	if cambia:
		_cambiadas.append(nombre)
		ref.save_jpg(SALIDA + nombre + "_actual.jpg", 0.85)
		mapa(ref, vieja).save_png(SALIDA + nombre + "_dif.png")

## AUTOPRUEBA DE LA PROPIA PRUEBA: `SABOTAJE=1` alarga el nombre del club de la
## cabecera, `SABOTAJE=2` esconde el panel de objetivos, `SABOTAJE=3` cambia el color
## de la tabla. Sirve para medir qué tamaño de cambio detecta (ver sesion_3.md).
func _sabotaje() -> void:
	match OS.get_environment("SABOTAJE"):
		"1":
			(_p.get("_cabecera") as Label).text = "Lautaro FC Unido de la Costa"
		"2":
			var po: Control = _p.get("_panel_obj")
			if po != null:
				po.visible = false
		"3":
			(_p.get("_lista_tabla") as Control).modulate = Color(1.0, 0.75, 0.75)

## [diferencia media 0..1, peor bloque 0..1, bloques que cambian] entre dos imágenes a 320×180.
## Por BLOQUES de 10×10 (32×18 en pantalla, ~40×40 px reales): un cambio local -un texto, un panel
## que falta- se ve entero en su bloque y no se diluye en la media de toda la pantalla.
static var peor_bloque := Vector2i.ZERO
## Bloques que cambiaron de TONO en la última comparación (ver `diferencia`).
static var tono_bloques := 0
static func diferencia(a: Image, b: Image) -> Vector3:
	var x := _reducir(a)
	var y := _reducir(b)
	var bloques := {}
	var tonos := {}
	var suma := 0.0
	for j in COMPARA.y:
		for i in COMPARA.x:
			var p := x.get_pixel(i, j)
			var q := y.get_pixel(i, j)
			var s := (absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b)) / 3.0
			suma += s
			var k := Vector2i(i / LADO_BLOQUE, j / LADO_BLOQUE)
			bloques[k] = float(bloques.get(k, 0.0)) + s
			tonos[k] = (tonos.get(k, Vector3.ZERO) as Vector3) + Vector3(p.r - q.r, p.g - q.g, p.b - q.b)
	var peor := 0.0
	var cambian := 0
	for k: Vector2i in bloques:
		var m := float(bloques[k]) / float(LADO_BLOQUE * LADO_BLOQUE)
		if m > peor:
			peor_bloque = k
		peor = maxf(peor, m)
		if m > UMBRAL_BLOQUE:
			cambian += 1
	## EL TONO (s3, 26-10-2026): un tinte suave (la tabla ×0,75 en verde y azul) mueve
	## cada píxel muy poco y no llega a `UMBRAL_BLOQUE`, pero lo mueve SIEMPRE en el
	## mismo sentido; el ruido del JPG va en los dos y se anula. Un bloque cambia de
	## tono si su color medio se desplaza más de `UMBRAL_TONO` en algún canal; y la
	## pantalla cuenta si son al menos `MIN_TONO` bloques (una región, no un píxel).
	tono_bloques = 0
	for k: Vector2i in tonos:
		var t := (tonos[k] as Vector3) / float(LADO_BLOQUE * LADO_BLOQUE)
		if maxf(absf(t.x), maxf(absf(t.y), absf(t.z))) > UMBRAL_TONO:
			tono_bloques += 1
	return Vector3(suma / float(COMPARA.x * COMPARA.y), peor, cambian)

static func _reducir(img: Image) -> Image:
	var r := img.duplicate() as Image
	r.convert(Image.FORMAT_RGB8)
	r.resize(COMPARA.x, COMPARA.y, Image.INTERPOLATE_BILINEAR)
	return r

## La actual en gris, con en rojo lo que cambió (para verlo de un vistazo).
static func mapa(a: Image, b: Image) -> Image:
	var x := _reducir(a)
	var y := _reducir(b)
	var out := Image.create(COMPARA.x, COMPARA.y, false, Image.FORMAT_RGB8)
	for j in COMPARA.y:
		for i in COMPARA.x:
			var p := x.get_pixel(i, j)
			var q := y.get_pixel(i, j)
			var s := absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b)
			var g := p.get_luminance() * 0.6
			out.set_pixel(i, j, Color(1, 0.15, 0.1) if s > SALTO_PIXEL else Color(g, g, g))
	out.resize(COMPARA.x * 4, COMPARA.y * 4, Image.INTERPOLATE_NEAREST)
	return out

func _terminar() -> void:
	if _idioma_antes != "" and _idioma_antes != Idiomas.idioma:
		Idiomas.idioma = _idioma_antes
		_p._guardar_preferencias()
	if get_viewport().get_visible_rect().size != Vector2(1280, 720):
		print("AVISO: las referencias se hicieron a 1280×720; esta ventana es %s" % str(get_viewport().get_visible_rect().size))
	print("")
	if _hacer_refs:
		print("Referencias hechas: %d en %s" % [_nuevas.size(), REFS])
		print("===== FIN. 0 fallos =====")
		get_tree().quit(0)
		return
	if not _cambiadas.is_empty():
		print("Cambiaron %d de %d: %s (fotos y mapas en %s)" % [_cambiadas.size(), PANTALLAS.size(), ", ".join(_cambiadas), SALIDA])
		for c in _cambiadas:
			print("  FALLO la pantalla «%s» no se parece a su referencia" % c)
	print("===== FIN. %d fallos =====" % _cambiadas.size())
	get_tree().quit(0 if _cambiadas.is_empty() else 1)
