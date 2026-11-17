class_name EstiloAvanzar
extends RefCounted
## EL ESTILO DE LA MAQUETA («Avanzar en el tiempo», aprobada por el dueño) EN EL JUEGO (17-11-2026): colores por tipo de evento, la tipografía condensada (Barlow
## Condensed, ya incluida en el juego, licencia OFL), el arte por evento (`assets/ui/avanzar/arte_*.webp`, dibujado en la maqueta y pre-renderizado), los iconos
## de trazo (los mismos de la maqueta) y el jugador con la camiseta del club (`figura_plantilla.svg`, con los colores del club). Todo lo que se dibuja en las pantallas
## de avance, de eventos, del menú del partido y del resultado sale de aquí, para que se vean como la maqueta.

const FONDO := Color("0b1220")
const TINTA := Color("e8eeff")
const SUAVE := Color("9aa6c4")
const ROJO := Color("c8102e")
const AZUL := Color("2d4a8a")
## Colores de cada TIPO de evento (las variables --t-* de la maqueta).
const COLOR := {"partido": Color("c8102e"), "premio": Color("e2b84a"), "fichaje": Color("27a9b8"), "noticia": Color("4f8ff7"), "decision": Color("f08a3c"),
	"lesion": Color("e5484d"), "dinero": Color("3fb27f"), "cantera": Color("9acd32"), "mercado": Color("8b95a8"), "hito": Color("9b7bf0"), "memoria": Color("5a6275")}

## Cómo se llama cada evento del juego en la maqueta: {arte, color, kicker}. El arte es uno de `arte_*.webp`; "" = sin arte (partido).
const DE_TIPO := {"liga": ["", "partido", "Partido"], "copa": ["", "partido", "Copa"], "conti": ["", "partido", "Continental"],
	"mercado_abre": ["mercado", "mercado", "Mercado"], "mercado_cierra": ["mercado", "mercado", "Mercado"], "fin": ["hito", "hito", "Fin de temporada"]}
const DE_CAUSA := {"despido": ["decision", "decision", "Directiva"], "ultimatum": ["decision", "decision", "Directiva"], "golpe_caja": ["dinero", "dinero", "Finanzas"],
	"imprevisto": ["decision", "decision", "Imprevisto"], "jugador_del_mes": ["premio", "premio", "Premio individual"], "guerra_agentes": ["nego", "fichaje", "Agentes"],
	"evento_cantera": ["cantera", "cantera", "Cantera"], "hallazgo": ["sorteo", "noticia", "Ojeadores"], "retos_semana": ["sorteo", "noticia", "Vestuario"],
	"cambio_dt": ["noticia", "noticia", "Prensa"], "oferta_seleccion": ["noticia", "noticia", "Selección"], "sancion_dt": ["tarjeta", "decision", "Federación"],
	"contratos_vencen": ["oferta", "fichaje", "Contratos"], "precontrato": ["oferta", "fichaje", "Mercado"], "jugador_sancionado": ["tarjeta", "decision", "Disciplina"],
	"caja_negativa": ["dinero", "dinero", "Finanzas"]}

## {arte, color (clave de COLOR), kicker} del evento.
static func ficha(ev: Dictionary) -> Array:
	var t := String(ev.get("tipo", ""))
	if t == "fecha_pais":
		var sub := String(ev.get("subtipo", ""))
		if sub == "memoria":
			return ["memoria", "memoria", "Día de memoria"]
		return ["fiesta", "premio", "Fecha especial" if sub != "independencia" else "Independencia"]
	if DE_TIPO.has(t):
		return DE_TIPO[t]
	var c := String((ev.get("causa", {}) as Dictionary).get("id", ""))
	if DE_CAUSA.has(c):
		return DE_CAUSA[c]
	return ["noticia", "noticia", "Novedad"]

static func color_de(clave: String) -> Color:
	return COLOR.get(clave, COLOR["noticia"])

static var _cache := {}

## El arte pre-renderizado de la maqueta (640x480, transparente), o null si no existe.
static func arte(tipo: String) -> Texture2D:
	if tipo == "":
		return null
	var ruta := "res://assets/ui/avanzar/arte_%s.webp" % tipo
	if not _cache.has(ruta):
		_cache[ruta] = load(ruta) if ResourceLoader.exists(ruta) else null
	return _cache[ruta]

## Títulos y números: la condensada de la maqueta (Barlow Condensed) engrosada, como los titulares en negrita de la maqueta.
static var _titulo: FontVariation
static func fuente_titulo() -> Font:
	if _titulo == null:
		_titulo = FontVariation.new()
		_titulo.base_font = load("res://assets/fuentes/BarlowCondensed-Regular.ttf")
		_titulo.variation_embolden = 0.8
	return _titulo

## El sonido de cada tipo de arte (sonidos que el juego ya tiene; la memoria va SIN sonido, como pidió el dueño).
const SONIDO_DE := {"premio": "trofeo", "oferta": "oferta", "nego": "contrato", "pres": "flashes", "decision": "aviso", "lesion": "lesion", "dinero": "dinero_sale",
	"hito": "fin_temporada", "mercado": "cronometro", "cantera": "aplauso", "noticia": "correo", "fiesta": "fichaje", "tarjeta": "aviso", "sorteo": "sorteo", "memoria": ""}
static func sonido_de(arte_tipo: String) -> String:
	return String(SONIDO_DE.get(arte_tipo, "aviso"))

static var _espaciada: FontVariation
## La condensada con las letras separadas, para los rótulos de categoría («PREMIO INDIVIDUAL»).
static func fuente_rotulo() -> Font:
	if _espaciada == null:
		_espaciada = FontVariation.new()
		_espaciada.base_font = load("res://assets/fuentes/BarlowCondensed-Regular.ttf")
		_espaciada.spacing_glyph = 4
	return _espaciada

static func etiqueta(texto: String, tam: int, color := TINTA, titulo := false, mayus := false) -> Label:
	var l := Label.new()
	l.text = texto.to_upper() if mayus else texto
	l.add_theme_font_size_override("font_size", Tema.letra(tam))
	l.add_theme_color_override("font_color", color)
	if titulo:
		l.add_theme_font_override("font", fuente_titulo())
	return l

## Un icono de trazo de la maqueta (24x24) del color y tamaño pedidos.
const ICONOS := {
	"ball": '<circle cx="12" cy="12" r="9"/><path d="M12 7l4 3-1.5 5h-5L8 10zM12 3v4M16 10l5-1M14.5 15l3 4M9.5 15l-3 4M8 10L3 9"/>',
	"copa": '<path d="M8 4h8v5a4 4 0 0 1-8 0z"/><path d="M8 6H5v2a3 3 0 0 0 3 3M16 6h3v2a3 3 0 0 1-3 3M12 13v4M9 20h6M10 17h4"/>',
	"doc": '<path d="M7 3h8l4 4v14H7z"/><path d="M15 3v4h4M10 12h6M10 16h6"/>',
	"charla": '<path d="M4 5h11v7H9l-3 3v-3H4z"/><path d="M15 9h5v7h-2v3l-3-3h-4v-2"/>',
	"camiseta": '<path d="M8 4L3 7l2 4 3-1v10h8V10l3 1 2-4-5-3c-1 2-5 2-6 0z"/>',
	"globo": '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"/>',
	"alerta": '<path d="M4 5h16v11H10l-4 4v-4H4z"/><path d="M12 8v4M12 14v.5"/>',
	"cruz": '<path d="M9 4h6v5h5v6h-5v5H9v-5H4V9h5z"/>',
	"euro": '<circle cx="12" cy="12" r="9"/><path d="M15 9a3.5 3.5 0 1 0 0 6M8 11h5M8 13.5h5"/>',
	"brote": '<path d="M12 21v-9"/><path d="M12 12c0-4-3-6-7-6 0 4 3 6 7 6zM12 14c0-3 2-5 6-5 0 3-2 5-6 5z"/>',
	"candado": '<rect x="5" y="11" width="14" height="9" rx="1"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
	"bandera": '<path d="M6 21V4M6 5h12l-2 4 2 4H6"/>',
	"campana": '<path d="M6 17V11a6 6 0 0 1 12 0v6l2 2H4z"/><path d="M10 21a2 2 0 0 0 4 0"/>',
	"repetir": '<path d="M4 12a8 8 0 0 1 14-5l2-2v6h-6l2-2a5 5 0 1 0 1 5"/>',
	"ojo": '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
	"rayo": '<path d="M13 2L5 14h6l-1 8 9-13h-6z"/>', "saltar": '<path d="M5 5l8 7-8 7zM14 5l8 7-8 7z"/>',
	"bolas": '<circle cx="8" cy="8" r="4"/><circle cx="16" cy="9" r="4"/><circle cx="11" cy="16" r="4"/>',
	"lazo": '<path d="M12 3c-3 0-4 2-3 4l3 4 3-4c1-2 0-4-3-4zM9 11l-3 9 4-2 2 3 2-3 4 2-3-9"/>'}
## Qué icono lleva cada tipo de evento (como SIMB de la maqueta).
const ICONO_DE := {"partido": "ball", "premio": "copa", "fichaje": "doc", "noticia": "globo", "decision": "alerta", "lesion": "cruz", "dinero": "euro",
	"cantera": "brote", "mercado": "candado", "hito": "bandera", "memoria": "lazo"}

static func icono(clave: String, color: Color, px := 48, grosor := 2.0) -> Texture2D:
	var k := "ic|%s|%s|%d|%.1f" % [clave, color.to_html(false), px, grosor]
	if _cache.has(k):
		return _cache[k]
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="%d" height="%d" fill="none" stroke="#%s" stroke-width="%.1f" stroke-linecap="round" stroke-linejoin="round">%s</svg>' % [
		px, px, color.to_html(false), grosor, String(ICONOS.get(clave, ICONOS["alerta"]))]
	var img := Image.new()
	img.load_svg_from_string(svg)
	var t := ImageTexture.create_from_image(img)
	_cache[k] = t
	return t

## El jugador de la previa y del resultado, con la camiseta del club (colores c1/c2) y su número; `alto` en píxeles.
static func figura(c1: Color, c2: Color, piel := Color("f0c8a0"), pelo := Color("2a1c14")) -> Texture2D:
	var k := "fig|%s|%s|%s|%s" % [c1.to_html(false), c2.to_html(false), piel.to_html(false), pelo.to_html(false)]
	if _cache.has(k):
		return _cache[k]
	var f := FileAccess.open("res://assets/ui/avanzar/figura_plantilla.svg", FileAccess.READ)
	var s := f.get_as_text() if f != null else ""
	s = s.replace("@C1@", "#" + c1.to_html(false)).replace("@C2@", "#" + c2.to_html(false)).replace("@SKIN@", "#" + piel.to_html(false)).replace("@HAIR@", "#" + pelo.to_html(false))
	var img := Image.new()
	img.load_svg_from_string(s, 2.0)
	var t := ImageTexture.create_from_image(img)
	_cache[k] = t
	return t
