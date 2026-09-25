class_name Vestidor
extends RefCounted

## Viste al modelo humano realista: le pone la equipacion del club, le quita los
## tatuajes y le da la piel y el pelo del jugador que toque.
##
## EL GOLPE DE SUERTE
## La textura de la camiseta que trae el modelo (`al-nassr.png`, 758x775) es una
## FOTO FRONTAL DE UNA CAMISETA SOBRE FONDO BLANCO — exactamente el mismo formato
## que las 1.102 equipaciones reales de `recursos\equipaciones\`. O sea que no
## hay que repintar nada ni averiguar el despliegue UV: se cambia una foto por
## otra y el modelo queda con la camiseta del club, con su escudo, su
## patrocinador y sus mangas. Es la diferencia entre un dia de trabajo y diez
## lineas.
##
## QUE MALLA ES QUE (sacado con scripts/debug_materiales.gd, no adivinado)
##   Object_7_001  sup0 y sup3 -> camiseta   (textura 758x775)
##   Object_7_001  sup1        -> detalle trasero de la camiseta (180x180)
##   Object_8_001  sup0        -> piel del cuerpo y brazos, CON LOS TATUAJES (2048x1024)
##   Object_10_001 sup0        -> cara y pelo (1024x1024)
##   Object_12_001 sup0        -> ojos (512x512)

const MALLA_CAMISETA := "Object_7_001"
const SUPS_CAMISETA := [0, 3]
const MALLA_PIEL := "Object_8_001"
const MALLA_CARA := "Object_10_001"

## Los dos paneles de brazo dentro de arm.png. El izquierdo esta cubierto de
## tatuajes y el derecho esta limpio: para quitarlos se espeja el limpio encima
## del otro. Medido sobre la textura de 2048x1024.
const BRAZO_TATUADO := Rect2i(102, 0, 871, 672)
const BRAZO_LIMPIO := Rect2i(1075, 0, 871, 672)

static var _cache_camiseta := {}
static var _cache_piel := {}
static var _cache_cara := {}
static var _cache_color := {}

# ------------------------------------------------------------------ camiseta

## Sustituye la foto de la camiseta por la equipacion real del club.
## `fichero` es el nombre del PNG dentro de recursos\equipaciones\.
static func _tex_camiseta(fichero: String, ancho: int, alto: int) -> Texture2D:
	var clave := "%s|%dx%d" % [fichero, ancho, alto]
	if _cache_camiseta.has(clave):
		return _cache_camiseta[clave]
	var dir := KitTextureFactory.dir_equipaciones()
	if dir == "" or fichero == "":
		_cache_camiseta[clave] = null
		return null
	var ruta := dir.path_join(fichero)
	if not FileAccess.file_exists(ruta):
		_cache_camiseta[clave] = null
		return null
	var img: Image = Image.load_from_file(ruta)
	if img == null:
		_cache_camiseta[clave] = null
		return null
	img.convert(Image.FORMAT_RGBA8)
	# La del modelo y las del pack estan encuadradas casi igual, pero no exacto.
	# Se recorta a la caja del dibujo y se reencuadra con el mismo margen que
	# tiene la original, o la camiseta sale desplazada sobre el cuerpo.
	var caja := KitTextureFactory._caja_util(img)
	if caja.size.x > 20 and caja.size.y > 20:
		img = img.get_region(caja)
	var lienzo := Image.create(ancho, alto, false, Image.FORMAT_RGBA8)
	lienzo.fill(Color(1, 1, 1, 1))
	var margen := 0.055
	var w := int(ancho * (1.0 - margen * 2.0))
	var h := int(alto * (1.0 - margen * 2.0))
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)
	lienzo.blit_rect(img, Rect2i(0, 0, w, h), Vector2i(int(ancho * margen), int(alto * margen)))
	var tex := ImageTexture.create_from_image(lienzo)
	_cache_camiseta[clave] = tex
	return tex

# --------------------------------------------------------------- piel y cara

## Quita los tatuajes espejando el brazo limpio sobre el tatuado, y de paso
## lleva toda la piel al tono del jugador.
static func _tex_piel(base: Image, piel: Color) -> Texture2D:
	var clave := piel.to_html(false)
	if _cache_piel.has(clave):
		return _cache_piel[clave]
	var img: Image = base.duplicate()
	img.convert(Image.FORMAT_RGBA8)
	var limpio: Image = img.get_region(BRAZO_LIMPIO)
	limpio.flip_x()
	img.blit_rect(limpio, Rect2i(Vector2i.ZERO, limpio.get_size()), BRAZO_TATUADO.position)
	_retenir(img, piel)
	var tex := ImageTexture.create_from_image(img)
	_cache_piel[clave] = tex
	return tex

## Cara: se le lleva la piel a su tono y el pelo a su color, igual que se hace
## con el muneco de Kenney. Los ojos y las cejas se quedan como estan.
static func _tex_cara(base: Image, piel: Color, pelo: Color) -> Texture2D:
	var clave := "%s|%s" % [piel.to_html(false), pelo.to_html(false)]
	if _cache_cara.has(clave):
		return _cache_cara[clave]
	var img: Image = base.duplicate()
	img.convert(Image.FORMAT_RGBA8)
	_retenir(img, piel, pelo)
	var tex := ImageTexture.create_from_image(img)
	_cache_cara[clave] = tex
	return tex

## Re-tine una textura fotografica conservando su sombreado. Se trabaja sobre el
## buffer de bytes: son dos millones de pixeles por textura y pixel a pixel el
## visor tardaba segundos en abrir cada jugador.
static func _retenir(img: Image, piel: Color, pelo: Color = Color(0, 0, 0, 0)) -> void:
	# Las texturas del .glb vienen CON MIPMAPS: el buffer mide un tercio mas que
	# ancho x alto x 4 y create_from_data lo rechaza. Se quitan antes de tocar
	# nada; Godot los regenera solo al subir la textura.
	img.clear_mipmaps()
	var w := img.get_width()
	var h := img.get_height()
	var datos := img.get_data()
	# tono medio de la piel de la foto, para saber cuanto hay que desplazarla
	var ref := _tono_medio(img)
	if ref.get_luminance() < 0.02:
		return
	var kr: float = piel.r / maxf(ref.r, 0.02)
	var kg: float = piel.g / maxf(ref.g, 0.02)
	var kb: float = piel.b / maxf(ref.b, 0.02)
	var tine_pelo: bool = pelo.a > 0.0
	for i in range(0, datos.size(), 4):
		if datos[i + 3] < 40:
			continue
		var cr := datos[i] / 255.0
		var cg := datos[i + 1] / 255.0
		var cb := datos[i + 2] / 255.0
		var l: float = 0.2126 * cr + 0.7152 * cg + 0.0722 * cb
		if tine_pelo and l < 0.22:
			# zona oscura de la cabeza: pelo, cejas y barba
			var f: float = clampf(l / 0.16, 0.35, 1.4)
			datos[i] = int(clampf(pelo.r * f, 0.0, 1.0) * 255.0)
			datos[i + 1] = int(clampf(pelo.g * f, 0.0, 1.0) * 255.0)
			datos[i + 2] = int(clampf(pelo.b * f, 0.0, 1.0) * 255.0)
			continue
		datos[i] = int(clampf(cr * kr, 0.0, 1.0) * 255.0)
		datos[i + 1] = int(clampf(cg * kg, 0.0, 1.0) * 255.0)
		datos[i + 2] = int(clampf(cb * kb, 0.0, 1.0) * 255.0)
	img.set_data(w, h, false, Image.FORMAT_RGBA8, datos)

static func _tono_medio(img: Image) -> Color:
	var acc := Vector3.ZERO
	var n := 0
	var w := img.get_width()
	var h := img.get_height()
	for y in range(int(h * 0.55), h, 11):
		for x in range(0, w, 11):
			var p := img.get_pixel(x, y)
			if p.a < 0.4 or p.get_luminance() < 0.18:
				continue
			acc += Vector3(p.r, p.g, p.b)
			n += 1
	if n == 0:
		return Color(0.75, 0.6, 0.5)
	acc /= float(n)
	return Color(acc.x, acc.y, acc.z)

# ------------------------------------------------------------------- vestir

## Deja al jugador con la equipacion del club, sin tatuajes y con su cara.
## `kit_img` es el PNG de la equipacion; "" deja la que trae el modelo.
## `color_liso`: si se le pasa un color con alfa, la camiseta se pinta de ese
## color entero en vez de con una foto. Es lo que viste al arbitro y a los jueces
## de linea, que no llevan equipacion de club.
static func vestir(modelo: Node3D, kit_img: String, piel: Color, pelo: Color,
		color_liso: Color = Color(0, 0, 0, 0)) -> void:
	# Pantalon y medias son materiales SIN textura, de un blanco roto (e7e7e7).
	# Se les pone el color dominante de la camiseta del club: asi el conjunto
	# case siempre, en vez de dejarles el azul del Al-Nassr con cualquier equipo.
	var color_kit := _color_de_kit(kit_img)
	if color_liso.a > 0.0:
		color_kit = color_liso
	for malla in _mallas(modelo):
		var mi: MeshInstance3D = malla
		for s in range(mi.mesh.get_surface_count()):
			var m: Material = mi.get_active_material(s)
			if not (m is StandardMaterial3D):
				continue
			var sm: StandardMaterial3D = (m as StandardMaterial3D).duplicate()
			var t: Texture2D = sm.albedo_texture
			if mi.name.begins_with(MALLA_CAMISETA) and color_liso.a > 0.0:
				sm.albedo_texture = null
				sm.albedo_color = color_liso
			elif mi.name.begins_with(MALLA_CAMISETA) and s in SUPS_CAMISETA and kit_img != "":
				var nueva := _tex_camiseta(kit_img, t.get_width() if t else 758, t.get_height() if t else 775)
				if nueva:
					sm.albedo_texture = nueva
			elif mi.name.begins_with(MALLA_PIEL) and t:
				sm.albedo_texture = _tex_piel(t.get_image(), piel)
			elif mi.name.begins_with(MALLA_CARA) and t:
				sm.albedo_texture = _tex_cara(t.get_image(), piel, pelo)
			elif t == null and sm.albedo_color.get_luminance() > 0.7 and color_kit.a > 0.0:
				sm.albedo_color = color_kit
			else:
				continue
			mi.set_surface_override_material(s, sm)

## Color dominante de la equipacion, para el pantalon y las medias.
static func _color_de_kit(fichero: String) -> Color:
	if fichero == "":
		return Color(0, 0, 0, 0)
	if _cache_color.has(fichero):
		return _cache_color[fichero]
	var dir := KitTextureFactory.dir_equipaciones()
	var ruta := dir.path_join(fichero) if dir != "" else ""
	var col := Color(0, 0, 0, 0)
	if ruta != "" and FileAccess.file_exists(ruta):
		var img: Image = Image.load_from_file(ruta)
		if img != null:
			img.convert(Image.FORMAT_RGBA8)
			var caja := KitTextureFactory._caja_util(img)
			# el centro del torso, que es donde esta el color de verdad del club
			var centro := Rect2i(caja.position.x + caja.size.x / 3, caja.position.y + caja.size.y / 2,
				maxi(caja.size.x / 3, 8), maxi(caja.size.y / 3, 8))
			col = KitTextureFactory._color_dominante(img, centro)
			col.a = 1.0
	_cache_color[fichero] = col
	return col

static func _mallas(n: Node, out: Array = []) -> Array:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out.append(n)
	for c in n.get_children():
		_mallas(c, out)
	return out
