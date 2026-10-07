class_name KitTextureFactory
extends RefCounted

## Viste al modelo de Kenney con la equipacion del club.
##
## El atlas del personaje es un unico PNG de 1024x1024 y cada prenda vive en un
## rectangulo suyo. Que rectangulo es cada cosa se averiguo pintando cuadrantes
## de colores y mirando el render (scripts/debug_atlas.gd), no adivinando:
##
##   TORSO   Rect(165,500,315,515)  ->  V = ESPALDA arriba / PECHO abajo,
##                                      U = de un costado al otro del cuerpo.
##   PIERNAS Rect(612,768,412,256)  ->  V = de la cadera al tobillo,
##                                      U = cara delantera / trasera.
##   BOTINES Rect(640,130,182,390)
##
## Con eso se puede pegar la camiseta REAL del club (los PNG de 420x420 de
## recursos\equipaciones\) en el pecho y en la espalda, y pintar pantalon,
## medias y botines aparte, que es lo que separa a un futbolista de un muneco
## con una camiseta de color liso.

const TORSO_RECT := Rect2i(165, 500, 315, 515)
const TORSO_ESPALDA := Rect2i(165, 500, 315, 257)
const TORSO_PECHO := Rect2i(165, 757, 315, 258)
const SHORT_RECT := Rect2i(612, 768, 412, 102)
const RODILLA_RECT := Rect2i(612, 870, 412, 30)
const MEDIAS_RECT := Rect2i(612, 900, 412, 124)
const BOTINES_RECT := Rect2i(640, 130, 182, 390)
const MANGA_IZQ_RECT := Rect2i(0, 490, 165, 534)
const MANGA_DER_RECT := Rect2i(478, 490, 157, 534)

const BASE_SKINS := [
	"res://assets/characters/Skins/skaterMaleA.png",
	"res://assets/characters/Skins/skaterFemaleA.png",
	"res://assets/characters/Skins/criminalMaleA.png",
	"res://assets/characters/Skins/cyborgFemaleA.png",
]

const SEG_BY_DIGIT := {
	0: [1, 1, 1, 1, 1, 1, 0], 1: [0, 1, 1, 0, 0, 0, 0], 2: [1, 1, 0, 1, 1, 0, 1],
	3: [1, 1, 1, 1, 0, 0, 1], 4: [0, 1, 1, 0, 0, 1, 1], 5: [1, 0, 1, 1, 0, 1, 1],
	6: [1, 0, 1, 1, 1, 1, 1], 7: [1, 1, 1, 0, 0, 0, 0], 8: [1, 1, 1, 1, 1, 1, 1],
	9: [1, 1, 1, 1, 0, 1, 1],
}

var _base_images: Array = []
var _material_cache: Dictionary = {}
static var _jersey_cache: Dictionary = {}
static var _dir_kits := ""
static var _dir_buscado := false

# --------------------------------------------------- equipaciones reales en disco

## La carpeta recursos\equipaciones\ NO esta dentro del proyecto de Godot: vive
## junto al HTML del juego, y son 167 MB que no tiene sentido duplicar dentro
## del .pck. Se busca en las rutas donde puede quedar segun donde se haya dejado
## el visor, igual que MatchDataLoader hace con el JSON del partido.
static func dir_equipaciones() -> String:
	if _dir_buscado:
		return _dir_kits
	_dir_buscado = true
	var cands: Array = []
	var exe := OS.get_executable_path().get_base_dir()
	var res := ProjectSettings.globalize_path("res://")
	for base in [exe, exe.path_join(".."), exe.path_join("../.."), res, res.path_join("..")]:
		cands.append(str(base).path_join("recursos/equipaciones").simplify_path())
	for c in cands:
		if DirAccess.dir_exists_absolute(c):
			_dir_kits = c
			print("KitTextureFactory: equipaciones reales en ", c)
			return c
	print("KitTextureFactory: no encontre recursos/equipaciones, camisetas por color")
	return ""

## Recorta el TORSO de la camiseta real (sin mangas) y lo deja del tamano del
## panel del atlas. El PNG del pack es una camiseta de frente sobre fondo claro:
## se detecta la caja del dibujo en vez de dar por hecho unos margenes fijos,
## porque no todos los packs recortan igual.
static func _torso_de_camiseta(fichero: String) -> Image:
	if _jersey_cache.has(fichero):
		return _jersey_cache[fichero]
	var dir := dir_equipaciones()
	if dir == "" or fichero == "":
		_jersey_cache[fichero] = null
		return null
	var ruta := dir.path_join(fichero)
	if not FileAccess.file_exists(ruta):
		print("KitTextureFactory: falta la equipación ", fichero)
		_jersey_cache[fichero] = null
		return null
	var src := Image.load_from_file(ruta)
	if src == null:
		_jersey_cache[fichero] = null
		return null
	src.convert(Image.FORMAT_RGBA8)
	var caja := _caja_util(src)
	if caja.size.x < 20 or caja.size.y < 20:
		_jersey_cache[fichero] = null
		return null
	# Las mangas sobresalen a los lados: quedandose con la franja central se coge
	# el cuerpo de la camiseta, que es lo que envuelve el torso del modelo.
	var recorte := Rect2i(
		caja.position.x + int(caja.size.x * 0.255),
		caja.position.y + int(caja.size.y * 0.06),
		int(caja.size.x * 0.49),
		int(caja.size.y * 0.92)).intersection(Rect2i(0, 0, src.get_width(), src.get_height()))
	var torso := src.get_region(recorte)
	torso.resize(TORSO_PECHO.size.x, TORSO_PECHO.size.y, Image.INTERPOLATE_LANCZOS)
	_jersey_cache[fichero] = torso
	return torso

## Caja del dibujo: se descarta el fondo tomando como fondo el color de la
## esquina (los packs usan blanco o transparente, segun de donde venga cada uno).
static func _caja_util(img: Image) -> Rect2i:
	var w := img.get_width()
	var h := img.get_height()
	var fondo := img.get_pixel(1, 1)
	var x0 := w
	var y0 := h
	var x1 := 0
	var y1 := 0
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			var p := img.get_pixel(x, y)
			if p.a < 0.35:
				continue
			if absf(p.r - fondo.r) + absf(p.g - fondo.g) + absf(p.b - fondo.b) < 0.16:
				continue
			x0 = mini(x0, x)
			y0 = mini(y0, y)
			x1 = maxi(x1, x)
			y1 = maxi(y1, y)
	if x1 <= x0 or y1 <= y0:
		return Rect2i(0, 0, w, h)
	return Rect2i(x0, y0, x1 - x0, y1 - y0)

# ------------------------------------------------------------------ pintado

func _ensure_base_loaded() -> void:
	if not _base_images.is_empty():
		return
	for p in BASE_SKINS:
		var img: Image = load(p).get_image()
		img.convert(Image.FORMAT_RGBA8)
		_base_images.append(img)

func _paint_shirt(img: Image, c1: Color, c2: Color, estilo: String) -> void:
	match estilo:
		"franjas", "vertical3":
			var stripes := 5
			var sw := TORSO_RECT.size.x / float(stripes)
			for i in range(stripes):
				var col := c1 if i % 2 == 0 else c2
				var rx := TORSO_RECT.position.x + int(i * sw)
				var r := Rect2i(rx, TORSO_RECT.position.y, int(ceil(sw)), TORSO_RECT.size.y)
				img.fill_rect(r.intersection(TORSO_RECT), col)
		"banda", "sash":
			img.fill_rect(TORSO_RECT, c1)
			for p in [TORSO_ESPALDA, TORSO_PECHO]:
				var panel: Rect2i = p
				var band_h: int = int(panel.size.y * 0.28)
				var band_y: int = panel.position.y + int(panel.size.y * 0.36)
				img.fill_rect(Rect2i(panel.position.x, band_y, panel.size.x, band_h), c2)
		"mitad":
			img.fill_rect(TORSO_RECT, c1)
			img.fill_rect(Rect2i(TORSO_RECT.position.x + TORSO_RECT.size.x / 2,
				TORSO_RECT.position.y, TORSO_RECT.size.x / 2, TORSO_RECT.size.y), c2)
		"hombros":
			img.fill_rect(TORSO_RECT, c1)
			for p in [TORSO_ESPALDA, TORSO_PECHO]:
				var panel: Rect2i = p
				img.fill_rect(Rect2i(panel.position.x, panel.position.y, panel.size.x,
					int(panel.size.y * 0.22)), c2)
		_:
			img.fill_rect(TORSO_RECT, c1)

## Pecho y espalda con la camiseta real. La espalda va espejada para que el
## dibujo siga el cuerpo y no se corte el escudo en la costura del costado.
func _pegar_camiseta_real(img: Image, torso: Image) -> bool:
	if torso == null:
		return false
	img.blit_rect(torso, Rect2i(Vector2i.ZERO, torso.get_size()), TORSO_PECHO.position)
	# La espalda NO se espeja. Comprobado volcando el atlas ya compuesto
	# (debug_torso_atlas.png) y comparandolo con el render: lo que se pinta en el
	# panel es lo que se ve, sin inversion de por medio. Espejarlo -aqui o al
	# final- era lo que dejaba el patrocinador y el dorsal escritos del reves.
	var atras: Image = torso.duplicate()
	atras.resize(TORSO_ESPALDA.size.x, TORSO_ESPALDA.size.y, Image.INTERPOLATE_LANCZOS)
	img.blit_rect(atras, Rect2i(Vector2i.ZERO, atras.get_size()), TORSO_ESPALDA.position)
	return true

## OJO con la espalda: NO hay que espejarla. Se probaron las dos cosas (espejar
## la camiseta al pegarla, y espejar el panel entero al final) y las dos dejaban
## el patrocinador escrito del reves y el dorsal ilegible ("10" se leia "OI").
## El modelo ya invierte el eje U al mirarlo por detras: cualquier flip extra lo
## invierte una segunda vez y se vuelve al punto de partida.

## Pantalon, medias y botines. Sin esto el jugador lleva los vaqueros y las
## zapatillas del skater de Kenney, y por buena que sea la camiseta se sigue
## viendo un muneco disfrazado en vez de un futbolista.
func _paint_abajo(img: Image, short: Color, medias: Color, piel: Color, botin: Color) -> void:
	img.fill_rect(SHORT_RECT, short)
	img.fill_rect(RODILLA_RECT, piel)
	img.fill_rect(MEDIAS_RECT, medias)
	# vuelta de la media, justo debajo de la rodilla
	var vuelta := medias.lightened(0.55) if medias.get_luminance() < 0.6 else medias.darkened(0.4)
	img.fill_rect(Rect2i(MEDIAS_RECT.position.x, MEDIAS_RECT.position.y, MEDIAS_RECT.size.x, 12), vuelta)
	img.fill_rect(BOTINES_RECT, botin)

## ------------------------------------------------------------------- la cara
##
## El pack de Kenney trae cuatro caras y punto: con veintidos jugadores en el
## campo se repetian cinco veces cada una. El juego, en cambio, ya sabe que pinta
## tiene cada futbolista (lookDe() en el HTML: piel, color de pelo, barba), y esa
## cara es la que se ve en su ficha. Aqui se re-tine la cabeza del atlas con esos
## dos colores conservando el sombreado del dibujo original, de modo que el
## jugador que en la ficha es moreno y con barba tambien lo es en el campo.
##
## Se trabaja sobre el buffer de bytes y no con get_pixel/set_pixel: son 309.000
## pixeles por cabeza y por jugador, y pixel a pixel el visor tardaba segundos en
## abrir.
const CABEZA_RECT := Rect2i(0, 0, 636, 486)
const MANOS_RECT := Rect2i(636, 522, 388, 242)
const CACHETE_RECT := Rect2i(280, 180, 110, 70)
const PELAMBRE_RECT := Rect2i(60, 40, 120, 80)
const BARBA_RECT := Rect2i(232, 232, 190, 78)

func _retenir(img: Image, piel: Color, pelo: Color) -> void:
	var w := img.get_width()
	var datos := img.get_data()
	var lum_piel: float = maxf(_color_dominante(img, CACHETE_RECT).get_luminance(), 0.12)
	var lum_pelo: float = maxf(_color_dominante(img, PELAMBRE_RECT).get_luminance(), 0.05)
	for zona in [CABEZA_RECT, MANOS_RECT]:
		var r: Rect2i = zona
		# El skater de Kenney lleva mitones negros. Esos pixeles no pasan ni por
		# piel ni por pelo, asi que las manos se quedaban negras y de lejos
		# parecia que el futbolista jugaba con guantes. En la zona de las manos
		# se re-tine TODO a piel, que ahi no hay nada mas que pintar.
		var todo_piel: bool = zona == MANOS_RECT
		for y in range(r.position.y, mini(r.end.y, img.get_height())):
			var fila := y * w
			for x in range(r.position.x, mini(r.end.x, w)):
				var i := (fila + x) * 4
				if datos[i + 3] < 40:
					continue
				var cr := datos[i] / 255.0
				var cg := datos[i + 1] / 255.0
				var cb := datos[i + 2] / 255.0
				var l: float = 0.2126 * cr + 0.7152 * cg + 0.0722 * cb
				var mx: float = maxf(cr, maxf(cg, cb))
				var mn: float = minf(cr, minf(cg, cb))
				var sat: float = 0.0 if mx <= 0.0 else (mx - mn) / mx
				var destino: Color
				var ref: float
				if todo_piel:
					destino = piel
					ref = lum_piel
				elif l > 0.40 and sat < 0.62:
					destino = piel
					ref = lum_piel
				elif l < 0.36 and sat > 0.30:
					# pelo y cejas. Las pupilas son casi neutras (saturacion baja)
					# y se quedan fuera a proposito: tenidas de rubio daban miedo.
					destino = pelo
					ref = lum_pelo
				else:
					continue
				var k: float = clampf(l / ref, 0.42, 1.55)
				datos[i] = int(clampf(destino.r * k, 0.0, 1.0) * 255.0)
				datos[i + 1] = int(clampf(destino.g * k, 0.0, 1.0) * 255.0)
				datos[i + 2] = int(clampf(destino.b * k, 0.0, 1.0) * 255.0)
	var nueva := Image.create_from_data(w, img.get_height(), false, Image.FORMAT_RGBA8, datos)
	img.blit_rect(nueva, Rect2i(0, 0, w, img.get_height()), Vector2i.ZERO)

## Sombra de barba sobre la mandibula. No es una barba modelada — el modelo no da
## para eso — pero distingue de un vistazo al que la lleva del que no, que es lo
## que el juego ya cuenta en la ficha.
func _paint_barba(img: Image, pelo: Color, barba: int) -> void:
	if barba <= 0:
		return
	var fuerza: float = clampf(0.22 + barba * 0.09, 0.22, 0.72)
	var alto: int = BARBA_RECT.size.y if barba >= 4 else int(BARBA_RECT.size.y * 0.72)
	for y in range(BARBA_RECT.position.y, BARBA_RECT.position.y + alto):
		for x in range(BARBA_RECT.position.x, BARBA_RECT.end.x):
			var p := img.get_pixel(x, y)
			if p.a < 0.2:
				continue
			img.set_pixel(x, y, p.lerp(pelo, fuerza))

## Mangas. Los dos paneles blancos que flanquean el torso en el atlas son los
## brazos, y traen ademas los tirantes negros del skater: sin pintarlos, el
## futbolista salia con bandas negras a media manga como si llevara coderas.
func _paint_mangas(img: Image, col: Color, piel: Color) -> void:
	img.fill_rect(MANGA_IZQ_RECT, col)
	img.fill_rect(MANGA_DER_RECT, col)
	# Puno del antebrazo en tono piel: la manga se corta antes de la muneca y el
	# brazo deja de parecer un guante largo de un solo color.
	var alto := int(MANGA_IZQ_RECT.size.y * 0.20)
	var y0 := MANGA_IZQ_RECT.end.y - alto
	img.fill_rect(Rect2i(MANGA_IZQ_RECT.position.x, y0, MANGA_IZQ_RECT.size.x, alto), piel)
	img.fill_rect(Rect2i(MANGA_DER_RECT.position.x, y0, MANGA_DER_RECT.size.x, alto), piel)

func _draw_segment_digit(img: Image, x0: int, y0: int, w: int, h: int, digit: int, color: Color) -> void:
	if digit < 0 or digit > 9:
		return
	var seg: Array = SEG_BY_DIGIT[digit]
	var t: int = max(3, int(w * 0.18))
	if seg[0]:
		img.fill_rect(Rect2i(x0 + t, y0, w - 2 * t, t), color)
	if seg[3]:
		img.fill_rect(Rect2i(x0 + t, y0 + h - t, w - 2 * t, t), color)
	if seg[6]:
		img.fill_rect(Rect2i(x0 + t, y0 + h / 2 - t / 2, w - 2 * t, t), color)
	if seg[5]:
		img.fill_rect(Rect2i(x0, y0, t, h / 2 + t / 2), color)
	if seg[1]:
		img.fill_rect(Rect2i(x0 + w - t, y0, t, h / 2 + t / 2), color)
	if seg[4]:
		img.fill_rect(Rect2i(x0, y0 + h / 2 - t / 2, t, h / 2 + t / 2), color)
	if seg[2]:
		img.fill_rect(Rect2i(x0 + w - t, y0 + h / 2 - t / 2, t, h / 2 + t / 2), color)

## El dorsal va SOLO en la espalda (la mitad de arriba del panel), que es donde
## lo lleva una camiseta de verdad. En el pecho taparia el escudo del club.
func _paint_dorsal(img: Image, dorsal: int, on_color: Color) -> void:
	if dorsal <= 0:
		return
	var digits: Array = []
	var n := dorsal
	while n > 0:
		digits.push_front(n % 10)
		n = int(n / 10.0)
	if digits.is_empty():
		digits = [0]
	var dw := 62
	var dh := 96
	var gap := 12
	var total_w := digits.size() * dw + (digits.size() - 1) * gap
	var cx := TORSO_ESPALDA.position.x + TORSO_ESPALDA.size.x / 2
	var cy := TORSO_ESPALDA.position.y + int(TORSO_ESPALDA.size.y * 0.30)
	var start_x := cx - total_w / 2
	for i in range(digits.size()):
		_draw_segment_digit(img, start_x + i * (dw + gap), cy, dw, dh, digits[i], on_color)

## c1/c2: colores del club. estilo: patron ('liso','franjas'...). dorsal: numero.
## variant: 0-3, cual de los 4 skins base usar (varia pelo y piel entre jugadores).
## img_kit: nombre del PNG de la equipacion real, o "" para pintarla por color.
## piel: tono de piel del jugador, para la rodilla que asoma entre short y media.
func get_material(c1: Color, c2: Color, estilo: String, dorsal: int, variant: int,
		img_kit: String = "", piel: Color = Color(0.85, 0.66, 0.52),
		pelo: Color = Color(0.19, 0.13, 0.09), barba: int = 0) -> StandardMaterial3D:
	_ensure_base_loaded()
	variant = clampi(variant, 0, _base_images.size() - 1)
	var key := "%d|%s|%s|%s|%d|%s|%s|%s|%d" % [variant, c1.to_html(false), c2.to_html(false),
		estilo, dorsal, img_kit, piel.to_html(false), pelo.to_html(false), barba]
	if _material_cache.has(key):
		return _material_cache[key]

	var img: Image = _base_images[variant].duplicate()
	_retenir(img, piel, pelo)
	_paint_barba(img, pelo, barba)
	var real := _pegar_camiseta_real(img, _torso_de_camiseta(img_kit))
	if not real:
		_paint_shirt(img, c1, c2, estilo)

	# Con equipacion real el color dominante de la camiseta manda sobre el c1 del
	# club, que es una aproximacion dibujada: asi short y medias casan de verdad.
	var base_col := c1
	if real:
		base_col = _color_dominante(img, TORSO_PECHO)
	# Short y medias van del color dominante de la camiseta: es lo que hace la
	# mayoria de los clubes y, sobre todo, nunca desentona con ella. El short se
	# oscurece un pelo para que se distinga de la camiseta a contraluz.
	var short_col := base_col.darkened(0.18)
	if base_col.get_luminance() > 0.72:
		short_col = base_col.darkened(0.06)
	if not real and c2.get_luminance() > 0.6 and estilo == "liso":
		short_col = c2
	var dorsal_color: Color = Color.WHITE if base_col.get_luminance() < 0.5 else Color(0.08, 0.08, 0.1)
	_paint_abajo(img, short_col, base_col, piel, Color(0.07, 0.07, 0.09))
	_paint_mangas(img, base_col, piel)
	_paint_dorsal(img, dorsal, dorsal_color)

	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.78
	_material_cache[key] = mat
	return mat

## Color DOMINANTE de una zona: el mas repetido, NO el promedio. Con el promedio
## la camiseta azul de Boca (banda amarilla + letras blancas) daba gris, y el
## jugador terminaba con medias grises que no son de ningun equipo. Los tonos se
## agrupan en cubos para que dos azules casi iguales cuenten como el mismo color.
static func _color_dominante(img: Image, r: Rect2i) -> Color:
	var cubos := {}
	var mejor := 0
	var mejor_k := -1
	for y in range(r.position.y + 16, r.end.y - 16, 5):
		for x in range(r.position.x + 10, r.end.x - 10, 5):
			var p := img.get_pixel(x, y)
			var k: int = (int(p.r * 7.99) << 6) | (int(p.g * 7.99) << 3) | int(p.b * 7.99)
			var n: int = int(cubos.get(k, 0)) + 1
			cubos[k] = n
			if n > mejor:
				mejor = n
				mejor_k = k
	if mejor_k < 0:
		return Color(0.2, 0.2, 0.2)
	# Del cubo se vuelve al color promediando SOLO sus propios pixeles: quedarse
	# con el centro del cubo daria un tono lavado que no es el del club.
	var acc := Vector3.ZERO
	var n2 := 0
	for y in range(r.position.y + 16, r.end.y - 16, 5):
		for x in range(r.position.x + 10, r.end.x - 10, 5):
			var p := img.get_pixel(x, y)
			var k: int = (int(p.r * 7.99) << 6) | (int(p.g * 7.99) << 3) | int(p.b * 7.99)
			if k == mejor_k:
				acc += Vector3(p.r, p.g, p.b)
				n2 += 1
	if n2 == 0:
		return Color(0.2, 0.2, 0.2)
	acc /= float(n2)
	return Color(acc.x, acc.y, acc.z)
