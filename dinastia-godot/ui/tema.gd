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
## paleta azul de transmisión es parte del 3D) y las paletas que el jugador
## elige en Ajustes (`Principal._pal_panel()`).
##
## ACCESIBILIDAD (25-10-2026, paquete uitm): el modo daltónico y el tamaño de
## letra de Ajustes solo llegaban a `Principal._texto()` y al registro; lo que
## se pinta con `Tema.*` (álbum, teléfono, paneles, avisos...) no cambiaba.
## Ahora hay dos interruptores estáticos aquí, `daltonico` y `escala_texto`, que
## Principal vuelca al cargar las preferencias y al tocarlos en Ajustes.
## Por defecto (false / 1.0) TODO se pinta exactamente igual que antes.

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
## Los mismos tres con la paleta Okabe-Ito (azul cielo, bermellón, ámbar): se
## separan en cualquier tipo de daltonismo. Son los de `Principal`.
const BIEN_DALT := Color("56b4e9")
const MAL_DALT := Color("d55e00")
const ORO_DALT := Color("e69f00")
const POS := {"POR": Color("d9a400"), "DEF": Color("2f7fd0"), "MED": Color("2f9a5e"), "DEL": Color("e07b2a")}

# --- letra ---------------------------------------------------------------------
const TAM_ROTULO := 11     ## "PRÓXIMO PARTIDO", encabezados de tabla
const TAM_CUERPO := 13     ## texto corriente
const TAM_DESTACADO := 16  ## nombres en tarjetas
const TAM_TITULO := 22     ## títulos de pantalla
const TAM_MARCADOR := 36   ## marcadores y cifras héroe

## Interruptores de accesibilidad (ver la cabecera). `escala_texto` se acota
## al mismo rango que Ajustes (0,7-1,6).
static var daltonico := false
static var escala_texto := 1.0

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

## Una etiqueta con la letra y el color del juego. Pasa por la escala de
## texto y por la paleta para daltonismo.
static func etiqueta(tam: int = TAM_CUERPO, color: Color = TEXTO, texto: String = "") -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", letra(tam))
	l.add_theme_color_override("font_color", accesible(color))
	return l

## El tamaño de letra con la escala de Ajustes aplicada (misma cuenta que
## `Principal._texto()`: redondeo y nunca por debajo de 8 px). Con la escala a
## 1,0 devuelve `tam` tal cual, sea cual sea.
static func letra(tam: int) -> int:
	if is_equal_approx(escala_texto, 1.0):
		return tam
	return maxi(8, int(round(float(tam) * clampf(escala_texto, 0.7, 1.6))))

## Los colores con significado -bien, mal, oro- cambiados por el par que un
## daltónico distingue. Cualquier otro color, o con el modo apagado, pasa igual.
## Se compara RGB y se conserva el alfa: `Color(Tema.BIEN, 0.5)` también cambia.
static func accesible(c: Color) -> Color:
	if not daltonico:
		return c
	var opaco := Color(c, 1.0)
	if opaco == BIEN:
		return Color(BIEN_DALT, c.a)
	if opaco == MAL:
		return Color(MAL_DALT, c.a)
	if opaco == ORO:
		return Color(ORO_DALT, c.a)
	return c

## Los tres semánticos ya pasados por `accesible()`. Las constantes BIEN/MAL/ORO
## se quedan como constantes a propósito: una docena de archivos hacen
## `const COL_X := Tema.BIEN`, y una variable ahí no compilaría. Quien pinte en
## tiempo de ejecución y quiera respetar el modo daltónico usa estas.
static func bien() -> Color:
	return accesible(BIEN)

static func mal() -> Color:
	return accesible(MAL)

static func oro() -> Color:
	return accesible(ORO)

## Rótulo de sección: pequeño, en mayúsculas y en el color suave.
static func rotulo(texto: String) -> Label:
	return etiqueta(TAM_ROTULO, SUAVE, texto.to_upper())

## Color de un resultado desde mi lado: ganar, perder o empatar.
static func de_resultado(mios: int, suyos: int) -> Color:
	return bien() if mios > suyos else (mal() if mios < suyos else NEUTRO)
