class_name Fuentes
extends RefCounted
## LAS FUENTES PROPIAS (26-10-2026, investigación s4, fila 3). Hasta hoy cada
## tipografía de Ajustes se pedía al sistema por nombre (Impact, Arial Narrow,
## Segoe UI Emoji...): en Windows salía bien, pero en Linux, Android y Web esas
## fuentes no existen y los 1.100 iconos-emoji de la interfaz dependían de que
## el sistema tuviera alguna. Ahora el juego lleva las suyas (OFL, en
## `assets/fuentes/`, ver `OFL.txt` allí) y el sistema queda como repuesto.
##
## LA CADENA DE RESPALDO (la misma para todas las tipografías):
##   1. la fuente pedida (propia si la hay; si no, la del sistema por nombre);
##   2. los emojis EN COLOR del sistema, si los tiene (así Windows y Linux se
##      ven igual que antes: no se cambia un emoji de color por uno gris);
##   3. Noto Emoji (monocromo, se tiñe con `font_color`), Noto Sans Symbols 2 y
##      los subconjuntos de Symbols, Math, Mono y JP (ver `assets/fuentes/OFL.txt`):
##      cubren el resto de símbolos que usa el juego aunque el sistema no tenga nada;
##   4. Inter, para cualquier letra que le falte a la fuente elegida (Bebas Neue,
##      por ejemplo, no tiene minúsculas propias ni algunas letras del turco).
##
## «Del juego» sigue siendo la fuente de fábrica de Godot, con el mismo tamaño
## y el mismo MSDF de `project.godot`: solo se le cuelga la cadena de respaldo.

## Familias que el juego trae dentro: nombre (el que se escribe en
## `Principal.TIPOGRAFIAS`) → archivo.
const PROPIAS := {
	"Inter": "res://assets/fuentes/Inter-Variable.ttf",
	"Barlow Condensed": "res://assets/fuentes/BarlowCondensed-Regular.ttf",
	"Bebas Neue": "res://assets/fuentes/BebasNeue-Regular.ttf",
	"Noto Emoji": "res://assets/fuentes/NotoEmoji-Variable.ttf",
	"Noto Sans Symbols 2": "res://assets/fuentes/NotoSansSymbols2-Regular.ttf",
	## Los cuatro de abajo cubren los últimos símbolos que solo ponía el sistema
	## (flechas, ⓒ, ⛶, trazos y barras del teléfono, «＋»). Tres son subconjuntos.
	"Noto Sans Symbols": "res://assets/fuentes/NotoSansSymbols-Variable.ttf",
	"Noto Sans Math": "res://assets/fuentes/NotoSansMath-Flechas.ttf",
	"Noto Sans Mono": "res://assets/fuentes/NotoSansMono-Cajas.ttf",
	"Noto Sans JP": "res://assets/fuentes/NotoSansJP-AnchoCompleto.ttf",
	## Serifs de respaldo para la intro, el logo y el selector de idioma.
	"Cinzel": "res://assets/fuentes/Cinzel-Variable.ttf",
	"Gelasio": "res://assets/fuentes/Gelasio-Variable.ttf",
}

## El orden de la cadena de respaldo propia (paso 3 de la cabecera; Inter, el 4).
const CADENA := ["Noto Emoji", "Noto Sans Symbols 2", "Noto Sans Symbols", "Noto Sans Math",
	"Noto Sans Mono", "Noto Sans JP", "Inter"]

## Emojis en color que se piden al sistema antes que los propios (monocromos).
const EMOJI_SISTEMA := ["Noto Color Emoji", "Segoe UI Emoji", "Apple Color Emoji", "Segoe UI Symbol"]

## Tamaños de letra (px) a los que se recorta el alto de las fuentes de respaldo.
const TAM_MIN := 6
const TAM_MAX := 160

static var _repuesto: Array[Font] = []

## Carga una familia propia. Devuelve una copia para poder colgarle respaldos
## sin tocar el recurso compartido de la caché.
static func propia(nombre: String) -> FontFile:
	if not PROPIAS.has(nombre) or not ResourceLoader.exists(PROPIAS[nombre]):
		return null
	var f := load(PROPIAS[nombre]) as FontFile
	return f.duplicate() as FontFile if f != null else null

## La cadena de respaldo común (pasos 2-4 de la cabecera).
static func repuesto() -> Array[Font]:
	if not _repuesto.is_empty():
		return _repuesto
	var color := SystemFont.new()
	color.font_names = PackedStringArray(EMOJI_SISTEMA)
	_repuesto.append(color)
	var base := ThemeDB.fallback_font
	for n: String in CADENA:
		var f := propia(n)
		if f != null:
			_recortar_alto(f, base)
			_repuesto.append(f)
	return _repuesto

## EL ALTO DE LÍNEA. Godot mide la altura de una fuente como la mayor de toda
## su cadena de respaldo, y algunas de estas traen ascensos o descensos enormes
## (Noto Sans Symbols 2: 11 px de descenso a 16 px): colgadas sin más, TODA
## línea de texto crecía de 22 a 29 px y las tablas perdían filas. A cada una
## se le limitan el ascenso y el descenso a los de la fuente de fábrica, en
## cada tamaño que usa la interfaz. Medido en `pruebas/ideas/fnt_recursos.gd`.
static func _recortar_alto(f: FontFile, base: Font) -> void:
	var ra := base.get_ascent(16) / 16.0
	var rd := base.get_descent(16) / 16.0
	var fa := f.get_ascent(16) / 16.0
	var fd := f.get_descent(16) / 16.0
	if fa <= ra and fd <= rd:
		return
	for t in range(TAM_MIN, TAM_MAX + 1):
		f.set_cache_ascent(0, t, t * minf(fa, ra))
		f.set_cache_descent(0, t, t * minf(fd, rd))

## Fuente para una lista de nombres (la de `Principal.TIPOGRAFIAS`): si el
## primero es propio se usa el archivo y el resto de nombres va al sistema como
## repuesto; si no, todo se pide al sistema. Siempre con la cadena de respaldo.
static func para(nombres: Array) -> Font:
	var resto := nombres.duplicate()
	var base: Font = null
	if not resto.is_empty() and PROPIAS.has(String(resto[0])):
		base = propia(String(resto.pop_front()))
	var cadena: Array[Font] = []
	if base == null:
		var s := SystemFont.new()
		s.font_names = PackedStringArray(resto)
		base = s
	elif not resto.is_empty():
		var s2 := SystemFont.new()
		s2.font_names = PackedStringArray(resto)
		cadena.append(s2)
	cadena.append_array(repuesto())
	base.fallbacks = cadena
	return base

## «Del juego»: la fuente de fábrica (`ThemeDB.fallback_font`) con la cadena de
## respaldo. Es una `FontVariation` para no tocar la fuente global.
static func del_juego() -> Font:
	var v := FontVariation.new()
	v.base_font = ThemeDB.fallback_font
	v.fallbacks = repuesto()
	return v

## UNA SERIF DEL SISTEMA CON RESPALDO PROPIO (26-10-2026). La intro, el logo y
## el selector de idioma piden una serif por nombre (Palatino, Georgia...). En
## Windows y macOS la encuentran y se ve igual que siempre. Si NINGUNA de la
## lista existe, `SystemFont` no falla: carga otra (la de fábrica, o la que el
## sistema le sustituya), y en Android y Web salía una letra sin remates. Por
## eso se mira qué familia resolvió de verdad y, si no es de la lista, se usa la
## propia (`propio`, con su peso por el eje `wght` y la cursiva inclinada a
## mano). Detrás, la de fábrica y la cadena de símbolos, para la «ğ» o la «ł».
## La serif de rótulo de la intro y el logo (`intro_dibujo.gd`, `menu_modos_logo.gd`).
const SERIF_ROTULO := ["Cinzel", "Trajan Pro", "Palatino Linotype", "Book Antiqua",
	"Palatino", "Georgia", "Times New Roman"]

static func serif(nombres: Array, propio: String, peso: int, cursiva := false, mipmaps := false) -> Font:
	var cadena: Array[Font] = [ThemeDB.fallback_font]
	cadena.append_array(repuesto())
	var s := SystemFont.new()
	s.font_names = PackedStringArray(nombres)
	s.font_weight = peso
	s.font_italic = cursiva
	s.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	s.generate_mipmaps = mipmaps
	if _resuelve(s, nombres):
		s.fallbacks = cadena
		return s
	var f := propia(propio)
	if f == null:
		s.fallbacks = cadena
		return s
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.generate_mipmaps = mipmaps
	f.fallbacks = cadena
	var v := FontVariation.new()
	v.base_font = f
	v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): peso}
	if cursiva:
		v.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
	return v

## ¿La `SystemFont` encontró de verdad una de las familias pedidas?
static func _resuelve(s: SystemFont, nombres: Array) -> bool:
	var hallada := s.get_font_name().to_lower()
	for n: String in nombres:
		if hallada == n.to_lower():
			return true
	return false
