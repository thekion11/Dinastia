class_name Tema
extends RefCounted
## EL SISTEMA DE DISEÑO (25-9-2026, plan maestro B13). Hasta hoy once archivos
## copiaban su propia paleta -`COL_TEXTO`, `COL_SUAVE`, `COL_ORO`...- con los
## mismos valores escritos a mano, y algunos ya se habían desviado (tres verdes
## y tres rojos distintos para "bien" y "mal"). Aquí viven UNA vez los colores,
## los tamaños de letra, los radios y los espaciados; las pantallas apuntan
## aquí (`const COL_TEXTO := Tema.TEXTO`) en lugar de repetirlos.
##
## Lo que NO pasa por aquí, a propósito: la pantalla gigante del estadio (su
## paleta azul de transmisión es parte del 3D), la paleta para daltonismo (se
## aplica encima, en `Principal._color_de_paleta()`) y las paletas que el
## jugador elige en Ajustes (`Principal._pal_panel()`).

# --- color ---------------------------------------------------------------------
const FONDO := Color("0c1510")        ## detrás de todo
const PANEL := Color("141c16")        ## tarjetas y columnas
const TARJETA := Color("16211a")      ## tarjeta dentro de un panel
const BORDE := Color("ffffff12")      ## borde tenue de tarjeta
const TEXTO := Color("e9eeea")        ## texto principal
const SUAVE := Color("8ea595")        ## texto secundario, rótulos
const ORO := Color("c9a227")          ## lo importante: títulos de sección, trofeos
const ACENTO := Color("3fa06a")       ## verde del club DINASTÍA: botones, enlaces
const BIEN := Color("4caf6d")         ## victoria, subida, dinero que entra
const MAL := Color("e05555")          ## derrota, bajada, alerta
const NEUTRO := Color("8ea595")       ## empate, sin cambios
## Colores por línea del campo (pizarra, fichas, etiquetas de posición).
const POS := {"POR": Color("d9a400"), "DEF": Color("2f7fd0"), "MED": Color("2f9a5e"), "DEL": Color("e07b2a")}

# --- letra ---------------------------------------------------------------------
const TAM_ROTULO := 11     ## "PRÓXIMO PARTIDO", encabezados de tabla
const TAM_CUERPO := 13     ## texto corriente
const TAM_DESTACADO := 16  ## nombres en tarjetas
const TAM_TITULO := 22     ## títulos de pantalla
const TAM_MARCADOR := 36   ## marcadores y cifras héroe

# --- forma ---------------------------------------------------------------------
const RADIO := 8           ## tarjetas
const RADIO_CHICO := 4     ## chips, etiquetas
const RADIO_GRANDE := 12   ## paneles flotantes (cajón, avisos)
const ESPACIO := 8         ## separación estándar entre elementos
const MARGEN := 12         ## relleno interior de una tarjeta

## Una tarjeta con el estilo del juego.
static func caja(fondo: Color = PANEL, radio: int = RADIO, borde: Color = BORDE) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = fondo
	e.border_color = borde
	e.set_border_width_all(1)
	e.set_corner_radius_all(radio)
	e.content_margin_left = MARGEN
	e.content_margin_right = MARGEN
	e.content_margin_top = MARGEN - 2
	e.content_margin_bottom = MARGEN - 2
	return e

## Una etiqueta con la letra y el color del juego.
static func etiqueta(tam: int = TAM_CUERPO, color: Color = TEXTO, texto: String = "") -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l

## Rótulo de sección: pequeño, en mayúsculas y en el color suave.
static func rotulo(texto: String) -> Label:
	return etiqueta(TAM_ROTULO, SUAVE, texto.to_upper())

## Color de un resultado desde mi lado: ganar, perder o empatar.
static func de_resultado(mios: int, suyos: int) -> Color:
	return BIEN if mios > suyos else (MAL if mios < suyos else NEUTRO)
