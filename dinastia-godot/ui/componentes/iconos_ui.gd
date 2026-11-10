class_name IconosUI
extends RefCounted
## LOS ICONOS DIBUJADOS DEL MENÚ (10-11-2026, prototipo para que el dueño elija; estética de los menús, referencia eFootball). El riel y las cabeceras
## usaban emojis, y cada sistema los pinta con un estilo distinto (Android, Windows, la fuente del juego). Aquí, un juego propio de 16 iconos del
## MISMO estilo: trazo de 1,8 sobre una rejilla de 24, puntas redondeadas, sin relleno; dibujados para Dinastía (sin licencias de terceros).
## Detrás del interruptor de Ajustes → Pantalla «Iconos dibujados» (`dibujados`, ENCENDIDO por defecto desde la orden 36; apagado = emoji). El SVG va en el código (no en archivos
## sueltos: no hay que acordarse de exportarlos) y se rasteriza al tamaño pedido (`Image.load_svg_from_string`), con caché.
static var dibujados := true   ## (10-11, orden 36 del dueño) dibujados POR DEFECTO; los emojis quedan como opción en Ajustes → Pantalla
const COLOR := "#e8eef0"
const GRUPO := "icono_ui"
static var _cache := {}

## emoji del menú → nombre del icono
const DE_EMOJI := {"☰": "menu", "🏟️": "estadio", "🚶": "caminar", "👔": "plantel", "⚽": "partido", "💰": "dinero", "🏆": "trofeo",
	"📜": "historia", "👥": "gente", "🎓": "carrera", "📊": "operaciones", "🌅": "vida", "✏️": "editar", "📖": "reglas", "⚙️": "ajustes",
	"🏙️": "ciudad"}

const TRAZOS := {
	"menu": "M4 7h16M4 12h16M4 17h16",
	"estadio": "M3 10c0-2.8 4-5 9-5s9 2.2 9 5-4 5-9 5-9-2.2-9-5zM3 10v4c0 2.8 4 5 9 5s9-2.2 9-5v-4M7 10c0-1.4 2.2-2.5 5-2.5s5 1.1 5 2.5-2.2 2.5-5 2.5-5-1.1-5-2.5z",
	"caminar": "M13 3.5a1.5 1.5 0 1 0 0.01 0M11 21l2-6 2 3v3M13 15l-1.2-5 3.2 2 3 1M11.8 10l-3 2-1 3",
	"plantel": "M8.5 3.5L3.5 6.5l2 4 2.5-1V20h8V9.5l2.5 1 2-4-5-3c-.4 1.8-1.8 3-3.5 3s-3.1-1.2-3.5-3z",
	"partido": "M12 3a9 9 0 1 0 0.01 0M12 8l3 2.2-1.1 3.6h-3.8L9 10.2zM12 8V3.2M15 10.2l4.3-1.4M13.9 13.8l2.7 3.8M10.1 13.8l-2.7 3.8M9 10.2L4.7 8.8",
	"dinero": "M12 3a9 9 0 1 0 0.01 0M14.6 9.4c-.5-.9-1.5-1.4-2.6-1.4-1.4 0-2.5.8-2.5 2s1.1 1.6 2.5 2 2.5.8 2.5 2-1.1 2-2.5 2c-1.1 0-2.1-.5-2.6-1.4M12 6.5v1.5M12 16v1.5",
	"trofeo": "M8 4h8v5a4 4 0 0 1-8 0zM8 6H5.5v1a3 3 0 0 0 2.7 3M16 6h2.5v1a3 3 0 0 1-2.7 3M12 13v3.5M9 20h6M9.5 16.5h5V20h-5z",
	"historia": "M7 4h11a2 2 0 0 1 0 4h-2M7 4a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h9a2 2 0 0 0 2-2V8M8.5 11h6M8.5 14h6M8.5 17h4",
	"gente": "M9 5a3 3 0 1 0 0.01 0M3 20c0-3.3 2.7-6 6-6s6 2.7 6 6M17 6.5a2.5 2.5 0 1 0 0.01 0M16.5 14c2.6.3 4.5 2.6 4.5 5.5",
	"carrera": "M2 9l10-5 10 5-10 5zM6 11v5c0 1.7 2.7 3 6 3s6-1.3 6-3v-5M22 9v6",
	"operaciones": "M4 20h16M7 16v-5M12 16V6.5M17 16V9",
	"vida": "M3 18h18M6 18a6 6 0 0 1 12 0M12 4v3M4.9 9.9L7 12M19.1 9.9L17 12M7.5 21h9",
	"editar": "M4 20l4.2-1L19 8.2 15.8 5 5 15.8zM13.8 7l3.2 3.2",
	"reglas": "M12 6.2C10 4.7 7 4.2 4 4.7V19c3-.5 6 0 8 1.5 2-1.5 5-2 8-1.5V4.7c-3-.5-6 0-8 1.5zM12 6.2v14.3",
	"ajustes": "M12 9a3 3 0 1 0 0.01 0M12 2.5l1.6 2.3 2.7-.6.8 2.6 2.6.8-.6 2.7 2.4 1.7-2.4 1.6.6 2.7-2.6.8-.8 2.6-2.7-.6L12 21.5l-1.6-2.4-2.7.6-.8-2.6-2.6-.8.6-2.7L2.5 12l2.4-1.6-.6-2.7 2.6-.8.8-2.6 2.7.6z",
	"ciudad": "M3 21h18M5 21V9.5l5-3V21M10 21V4h6v17M16 21v-9h3.5v9M12.3 7.5h1.4M12.3 10.5h1.4M12.3 13.5h1.4",
}

## El icono dibujado de `emoji` a `px` píxeles, o null si no hay (o con los dibujados apagados, si `solo_activos`).
static func textura(emoji: String, px: int, solo_activos := true) -> Texture2D:
	if solo_activos and not dibujados:
		return null
	var nombre := String(DE_EMOJI.get(emoji, IconosUITrazos.DE_EMOJI.get(emoji, "")))   ## los del riel y los de los submenús
	var trazo := String(TRAZOS.get(nombre, IconosUITrazos.TRAZOS.get(nombre, "")))
	if nombre == "" or trazo == "":
		return null
	var clave := "%s@%d" % [nombre, px]
	if _cache.has(clave):
		return _cache[clave]
	var svg := "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' width='24' height='24'><path d='%s' fill='none' stroke='%s' stroke-width='1.8' stroke-linecap='round' stroke-linejoin='round'/></svg>" % [trazo, COLOR]
	var img := Image.new()
	if img.load_svg_from_string(svg, float(px) / 24.0) != OK:
		return null
	var tex := ImageTexture.create_from_image(img)
	_cache[clave] = tex
	return tex

## Pone en `b` el icono dibujado (sin texto) o el emoji, según el interruptor; queda apuntado para `aplicar_todos`.
static func en_boton(b: Button, emoji: String, px := 26) -> void:
	b.set_meta("icono_emoji", emoji)
	b.set_meta("icono_px", px)
	if not b.is_in_group(GRUPO):
		b.add_to_group(GRUPO)
	var t := textura(emoji, px)
	b.icon = t
	b.text = "" if t != null else emoji
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

## Un icono suelto (la cabecera de los menús): un `TextureRect` con el dibujado o una etiqueta con el emoji.
static func control(emoji: String, px: int) -> Control:
	var t := textura(emoji, px)
	if t == null:
		var l := Label.new()
		l.text = emoji
		l.add_theme_font_size_override("font_size", px)
		return l
	var r := TextureRect.new()
	r.texture = t
	r.custom_minimum_size = Vector2(px, px)
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_meta("icono_ui", true)
	return r

## Al cambiar el interruptor: todos los botones apuntados cambian a la vez.
static func aplicar_todos(arbol: SceneTree) -> void:
	for n: Node in arbol.get_nodes_in_group(GRUPO):
		if n is Button:
			en_boton(n as Button, String(n.get_meta("icono_emoji")), int(n.get_meta("icono_px", 26)))
