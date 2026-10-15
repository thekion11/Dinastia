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

## EL SVG DE LA CAMISETA (rehecho el 14-10-2026, «las camisetas deben parecerse
## más a las reales»). Antes era una silueta de cinco trazos con el estampado
## recortado a mano y mangas lisas. Ahora: el estampado se RECORTA a la silueta
## (cubre cuerpo y mangas, como una camiseta de verdad), con cuello en el color
## secundario, puños, costuras laterales, sombra de tela (más oscura en los
## costados y el bajo) y la marca del fabricante y el escudo del club en el pecho.
## `num` y `sp` no se dibujan aquí: van encima como etiquetas de Godot.
const _CUERPO := "M33 5 L11 16 L2 43 L18 50 L24 41 L24 91 Q50 96 76 91 L76 41 L82 50 L98 43 L89 16 L67 5 Q50 21 33 5 Z"

static func _estampado(estilo: String, c2: String) -> String:
	match estilo:
		"franjas":
			return '<path d="M12.5 0h12.5v100H12.5zM37.5 0H50v100H37.5zM62.5 0H75v100H62.5zM87.5 0H100v100H87.5z" fill="%s"/>' % c2
		"banda": return '<path d="M0 36H100V52H0z" fill="%s"/>' % c2
		"mitad": return '<path d="M50 0H100V100H50z" fill="%s"/>' % c2
		"hombros": return '<path d="M0 0H100V22L76 26V100H100V0zM0 0V100H24V26L0 22z" fill="%s"/><path d="M0 0H100V20Q50 34 0 20z" fill="%s"/>' % [c2, c2]
		"aros": return '<path d="M0 14H100V24H0zM0 34H100V44H0zM0 54H100V64H0zM0 74H100V84H0z" fill="%s"/>' % c2
		"diagonal": return '<path d="M14 100 64 0H82L32 100z" fill="%s"/>' % c2
		"cuadros":
			var d := ""
			for r in 8:
				for c in 5:
					if (r + c) % 2 == 0:
						d += "M%.1f %.1fh10v11.5h-10z" % [25.0 + c * 10.0, 6.0 + r * 11.5]
			return '<path d="%s" fill="%s"/>' % [d, c2]
		"vertical3": return '<path d="M32 0h9v100h-9zM45.5 0h9v100h-9zM59 0h9v100h-9z" fill="%s"/>' % c2
		"degrade": return '<defs><linearGradient id="dg" x1="0" y1="0" x2="0" y2="1"><stop offset=".25" stop-color="%s" stop-opacity="0"/><stop offset="1" stop-color="%s" stop-opacity=".95"/></linearGradient></defs><path d="M0 0H100V100H0z" fill="url(#dg)"/>' % [c2, c2]
		"sash": return '<path d="M16 8 54 8 84 100 56 100z" fill="%s" transform="skewX(0)"/>' % c2
		"arlequin": return '<path d="M50 6 76 30 50 54 24 30zM50 54 76 78 50 102 24 78zM24 30 0 54 24 78 48 54zM76 30 100 54 76 78 52 54z" fill="%s" opacity=".95"/>' % c2
	return ""

static func svg_de(c1: String, c2: String, estilo: String, num: int = 0, sp: String = "") -> String:
	var tx := _lum_tx(c1)
	var cuello := c2 if estilo != "hombros" else c1
	var p := (
		'<svg width="64" height="62" viewBox="0 0 100 97" xmlns="http://www.w3.org/2000/svg">' +
		'<defs><clipPath id="cp"><path d="%s"/></clipPath>' +
		'<linearGradient id="sh" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000" stop-opacity=".30"/><stop offset=".22" stop-color="#000" stop-opacity=".04"/><stop offset=".5" stop-color="#fff" stop-opacity=".07"/><stop offset=".78" stop-color="#000" stop-opacity=".04"/><stop offset="1" stop-color="#000" stop-opacity=".30"/></linearGradient>' +
		'<linearGradient id="sv" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".10"/><stop offset=".7" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".22"/></linearGradient></defs>' +
		'<path d="%s" fill="%s"/>' +
		'<g clip-path="url(#cp)">%s<path d="M0 0H100V100H0z" fill="url(#sh)"/><path d="M0 0H100V100H0z" fill="url(#sv)"/>' +
		'<path d="M24 41V91M76 41V91" stroke="#000" stroke-opacity=".18" stroke-width="1"/>' +
		'<path d="M2 43 18 50M98 43 82 50" stroke="%s" stroke-width="5"/></g>' +
		'<path d="%s" fill="none" stroke="#000" stroke-opacity=".55" stroke-width="1.6" stroke-linejoin="round"/>' +
		'<path d="M33 5Q50 24 67 5L62.5 4Q50 15 37.5 4Z" fill="%s" stroke="#000" stroke-opacity=".35" stroke-width=".8"/>' +
		'<circle cx="39" cy="30" r="4.2" fill="%s" fill-opacity=".85" stroke="%s" stroke-opacity=".6" stroke-width=".8"/>' +
		'<path d="M60 27l4 4M60 31l4 4" stroke="%s" stroke-opacity=".8" stroke-width="1.6" stroke-linecap="round"/>' +
		'</svg>') % [_CUERPO, _CUERPO, c1, _estampado(estilo, c2), c2, _CUERPO, cuello, tx, tx, tx]
	return p

static var _cache_svg: Dictionary = {}

## La camiseta procedural, rasterizada y cacheada por clave -mismo criterio
## que `Portada.textura()`: se pide el doble de resolución real y se deja que
## el control la encoja.
static func textura_procedural(c1: String, c2: String, estilo: String, ancho_px: int = 128) -> Texture2D:
	## Los diseños nuevos del diseñador (26-9-2026) los dibuja `DisenosKit`.
	if not KITS.has(estilo) and DisenosKit.claves().has(estilo):
		var cols: Array[Color] = [Color(c1), Color(c2), Color(c2).darkened(0.35), Color.WHITE, Color("111111")]
		return DisenosKit.textura_camiseta(estilo, cols, 1, ancho_px)
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
	## Con la equipación del diseñador, sus cinco colores y su ribete.
	if cual == 0 and custom_kit == "" and not club.kit_x.is_empty():
		var kx := DisenosKit.kit_de_club(club)
		return DisenosKit.textura_camiseta(String(kx["dis"]), DisenosKit.colores(kx), int(kx.get("trim", 1)), ancho_px)
	return textura_procedural(club.color_kit1(), club.color_kit2(),
		kit_de(club, estilo), ancho_px)
