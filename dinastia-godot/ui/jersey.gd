class_name Jersey
extends RefCounted
## La camiseta de un club: la foto real si existe (`recursos\equipaciones\`,
## las 1.102 que trajo el usuario), y si no, el dibujo de siempre -el
## `jerseySVG()` del HTML, doce estampados, portado tal cual como generador de
## cadenas, igual que `Escudo`/`Cara`/`Portada`-. Nadie había portado el
## generador procedural todavía: solo lo real llegó a Godot, y solo al visor
## 3D (`visor/kit_texture_factory.gd`). Aquí es para la interfaz 2D -la ficha,
## el plantel, "Club → Equipación"-, que hasta hoy no mostraba ninguna
## camiseta en ningún lado.

const KITS := ["liso", "franjas", "banda", "mitad", "hombros", "aros", "diagonal",
	"cuadros", "vertical3", "degrade", "sash", "arlequin"]

## El mismo `kitDe()` del HTML: estable por club -el hash del id no cambia
## entre repintados-, salvo que sea el tuyo y hayas elegido uno en Identidad
## (`custom`, si se pasa, gana siempre).
static func kit_de(c: Club, custom: String = "") -> String:
	if custom != "":
		return custom
	var h := 0
	for i in c.id.length():
		h += c.id.unicode_at(i)
	return KITS[h % KITS.size()]

static func _lum_tx(c1: String) -> String:
	var col := Color(c1)
	var lum := 0.299 * col.r + 0.587 * col.g + 0.114 * col.b
	return "#0c130e" if lum > 0.6 else "#ffffff"

## El SVG de la camiseta procedural. `num` es el dorsal (0 = sin dorsal),
## `sp` el nombre del sponsor a pecho (vacío = sin banda).
static func svg_de(c1: String, c2: String, estilo: String, num: int = 0, sp: String = "") -> String:
	var deco := ""
	match estilo:
		"franjas": deco = '<path d="M22 8h8v38h-8zM38 8h8v38h-8z" fill="%s"/>' % c2
		"banda": deco = '<path d="M12 12 52 34v9L12 21z" fill="%s"/>' % c2
		"mitad": deco = '<path d="M32 4h12l6 4-4 12v26H32z" fill="%s"/>' % c2
		"hombros": deco = '<path d="M20 4 8 10l4 10 6-3v3h4V6zM44 4l12 6-4 10-6-3v3h-4V6z" fill="%s"/>' % c2
		"aros": deco = '<path d="M18 14h28v6H18zM18 26h28v6H18zM18 38h28v6H18z" fill="%s"/>' % c2
		"diagonal": deco = '<path d="M18 46 46 8h8L26 46z" fill="%s"/>' % c2
		"cuadros": deco = '<path d="M18 8h7v9h-7zM32 8h7v9h-7zM25 17h7v9h-7zM39 17h7v9h-7zM18 26h7v9h-7zM32 26h7v9h-7zM25 35h7v9h-7zM39 35h7v9h-7z" fill="%s" opacity=".85"/>' % c2
		"vertical3": deco = '<path d="M20 8h5v38h-5zM29.5 8h5v38h-5zM39 8h5v38h-5z" fill="%s"/>' % c2
		"degrade": deco = '<defs><linearGradient id="dg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="%s" stop-opacity="0"/><stop offset="1" stop-color="%s" stop-opacity=".95"/></linearGradient></defs><path d="M18 8h28v38H18z" fill="url(#dg)"/>' % [c2, c2]
		"sash": deco = '<path d="M16 10 48 40v6h-4L14 18z" fill="%s"/>' % c2
		"arlequin": deco = '<path d="M32 8h14v19H32zM18 27h14v19H18z" fill="%s"/>' % c2
	var tx := _lum_tx(c1)
	## El texto del sponsor y el numero no se dibujan aqui -el rasterizador de
	## Godot no pinta <text>, la misma limitacion de siempre-: van encima como
	## etiquetas de Godot, y por eso svg_de() no los recibe.
	return ('<svg width="64" height="52" viewBox="0 0 64 52" xmlns="http://www.w3.org/2000/svg">' +
		'<path d="M20 4 8 10l4 10 6-3v29h28V17l6 3 4-10L44 4l-6 3h-12z" fill="%s" stroke="#000a" stroke-width="2.5" stroke-linejoin="round"/>' +
		'%s<path d="M26 4h12l-6 6z" fill="%s" stroke="#0006"/></svg>') % [c1, deco, c2]

static var _cache_svg: Dictionary = {}

## La camiseta procedural, rasterizada y cacheada por clave -mismo criterio
## que `Portada.textura()`: se pide el doble de resolución real y se deja que
## el control la encoja.
static func textura_procedural(c1: String, c2: String, estilo: String, ancho_px: int = 128) -> Texture2D:
	var clave := "%s_%s_%s_%d" % [c1, c2, estilo, ancho_px]
	if _cache_svg.has(clave):
		return _cache_svg[clave]
	var img := Image.new()
	if img.load_svg_from_string(svg_de(c1, c2, estilo), float(ancho_px) / 64.0) != OK:
		return null
	var t := ImageTexture.create_from_image(img)
	_cache_svg[clave] = t
	return t

static var _cache_real: Dictionary = {}

## La foto real de la equipación, tal cual está en el disco -sin recortar al
## torso como hace el visor 3D, aquí se enseña entera-. Null si el club no
## tiene ninguna en `EQUIP_REAL` o si falta el archivo: quien llame decide el
## respaldo, igual que el `onerror` del HTML.
## Solo el nombre del fichero (sin cargar ninguna imagen) -lo que necesita el
## visor 3D (`Puente3D.kit()`) para pedirle a `KitTextureFactory` la misma
## equipación real que ya se ve en la ficha 2D, sin duplicar la búsqueda en
## `EQUIP_REAL`. "" si el club no tiene ninguna equipación real archivada.
static func fichero_real(club: Club, cual: int = 0) -> String:
	if club == null:
		return ""
	var tabla: Variant = Datos.tabla("EQUIP_REAL")
	if not (tabla is Dictionary):
		return ""
	var nombre := Nombres.limpiar(club.nombre)
	var lista: Variant = (tabla as Dictionary).get(nombre, null)
	if not (lista is Array) or (lista as Array).is_empty():
		return ""
	return String((lista as Array)[mini(maxi(cual, 0), (lista as Array).size() - 1)])

static func textura_real(club: Club, cual: int = 0) -> Texture2D:
	if club == null:
		return null
	var fichero := fichero_real(club, cual)
	if fichero == "":
		return null
	var nombre := Nombres.limpiar(club.nombre)
	var clave := "%s_%d" % [nombre, cual]
	if _cache_real.has(clave):
		return _cache_real[clave]
	var dir := KitTextureFactory.dir_equipaciones()
	if dir == "":
		return null
	var ruta := dir.path_join(fichero)
	if not FileAccess.file_exists(ruta):
		_cache_real[clave] = null
		return null
	var img := Image.load_from_file(ruta)
	if img == null:
		_cache_real[clave] = null
		return null
	var t := ImageTexture.create_from_image(img)
	_cache_real[clave] = t
	return t

## La puerta única: real si hay, procedural si no -exactamente el `jerseyDe()`
## del HTML, solo que aquí no hace falta un `onerror` de navegador porque se
## comprueba el archivo antes de devolver nada.
static func textura(club: Club, cual: int = 0, ancho_px: int = 128, custom_kit: String = "") -> Texture2D:
	var real := textura_real(club, cual)
	if real != null:
		return real
	## Los colores y el estampado del UNIFORME, que pueden ir por libre de los
	## del club: es toda la gracia de la pantalla de identidad -el uniforme no
	## arrastra el color del escudo ni el del menu-.
	var estilo := custom_kit if custom_kit != "" else club.kit_estilo
	return textura_procedural(club.color_kit1(), club.color_kit2(),
		kit_de(club, estilo), ancho_px)
