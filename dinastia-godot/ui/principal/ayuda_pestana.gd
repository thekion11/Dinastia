class_name AyudaPestana
extends RefCounted
## LA AYUDA «?» DE LAS PANTALLAS DENSAS (onboarding, 26-10-2026).
##
## Un jugador nuevo abre Mi plantel, Táctica, Finanzas, Mercado o Cantera y se
## encuentra una pared de cifras (MEDIA, POT, perillas, taquilla, mesa de
## negociación, camada…) sin saber qué mirar primero. El tutorial guiado solo
## pasa por encima de los bloques; esto es la chuleta de cada pantalla: 2-3
## líneas, siempre a mano, al final del carril de chips.
##
## Interfaz: `anadir(fila, titulo)` pone el botón si la pestaña tiene ayuda y lo
## devuelve (o null); `abrir(boton)` despliega la nota. Todo pasa por
## `Idiomas.t` (las frases están traducidas en `datos/idiomas_extra.json`).

## Pestaña → líneas de ayuda (castellano: es la clave de traducción).
const TEXTOS := {
	"Mi plantel": [
		"MEDIA es lo que rinde hoy; POT, hasta dónde puede llegar. Pulsa una cabecera para ordenar.",
		"Pulsa un jugador para ver su ficha a la derecha: forma, moral, contrato y lesiones.",
		"Busca equilibrio: un buen once titular y recambio en cada línea.",
	],
	"Táctica": [
		"Arriba, el once en el pizarrón; debajo, la formación (cambiarla vacía el once elegido).",
		"Las perillas (mentalidad, presión, ritmo, línea…) tienen tres niveles: si dudas, deja el del medio.",
		"El partido en vivo usa esto mismo; se puede retocar en el descanso.",
	],
	"Finanzas": [
		"La caja es el dinero de hoy: si baja de cero, la directiva pierde confianza.",
		"El precio de la entrada sube lo que deja cada espectador, pero baja la asistencia: mira la taquilla estimada.",
		"La tienda se paga una vez y vende cada mes según los socios y el ánimo de la hinchada.",
	],
	"Mercado": [
		"Filtra por línea o por lo que puedes pagar y pulsa un jugador para abrir la mesa de negociación.",
		"«Piden» es lo que quiere el otro club; «Perciben» es cuánto vale tu oferta para ellos.",
		"Fijo, cuotas y bonos reparten el pago: las cuotas alivian la caja de hoy pero pesan después.",
	],
	"Entrenar": [
		"Elige el foco del entrenamiento de la semana: sube lo que trabajas, pero cansa más a la plantilla.",
		"Los jóvenes mejoran más rápido; los veteranos aguantan menos carga. Reparte según la edad.",
		"Si ves muchos fundidos o lesiones, baja la intensidad antes del partido importante.",
	],
	"Enfermería": [
		"Aquí están los lesionados y cuántas semanas les quedan; un jugador cansado se lesiona más.",
		"El informe médico te dice el riesgo de recaída antes de poner a alguien tocado.",
		"Un buen preparador físico y la rotación reducen las lesiones: no lo dejes para cuando ya duelen.",
	],
	"Camarín": [
		"El clima del vestuario sube o baja con los resultados, los minutos y los grupos de amigos o rivales.",
		"Los capitanes y los veteranos sostienen el ambiente: cuida de quién sale del once.",
		"Un jugador descontento rinde menos y acaba pidiendo salir: hablar a tiempo cuesta menos que fichar.",
	],
	"Contratos": [
		"Aquí ves quién termina contrato este año: sin renovar, se va gratis al acabar la temporada.",
		"Renovar cuesta una prima y una ficha nueva; negociar con tiempo sale más barato.",
		"En el mercado puedes pactar un precontrato con un jugador en su último año de contrato.",
	],
	"Cantera": [
		"La academia (10-16 años) prepara a los que llegarán: invertir en ella mejora las camadas.",
		"Cada año sale una camada nueva; los que están listos pueden debutar con el primer equipo.",
		"El potencial importa más que la media: dales minutos para que crezcan.",
	],
}

## Pone el botón «?» al final de `fila` si `titulo` tiene ayuda.
static func anadir(fila: Container, titulo: String) -> Button:
	if fila == null or not TEXTOS.has(titulo):
		return null
	var b := Button.new()
	b.text = "?"
	b.name = "AyudaPestana"
	b.custom_minimum_size = Vector2(30, 30)
	b.tooltip_text = Idiomas.t("¿Qué es esta pantalla?")
	b.add_theme_color_override("font_color", Tema.ORO)
	b.set_meta("titulo_ayuda", titulo)
	b.pressed.connect(func() -> void: abrir(b))
	fila.add_child(b)
	return b

## Las líneas traducidas de la pestaña (vacío si no tiene).
static func lineas(titulo: String) -> Array[String]:
	var r: Array[String] = []
	for l: String in (TEXTOS.get(titulo, []) as Array):
		r.append(Idiomas.t(l))
	return r

## Despliega la nota bajo el botón. Un `PopupPanel` se cierra solo al pulsar
## fuera o con Esc, que es lo que se espera de una chuleta.
static func abrir(b: Button) -> PopupPanel:
	var titulo := String(b.get_meta("titulo_ayuda", ""))
	var pop := PopupPanel.new()
	pop.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.ORO))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	pop.add_child(v)
	v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.ORO, Idiomas.t("¿Qué es esta pantalla?")))
	for l: String in lineas(titulo):
		var e := Tema.etiqueta(Tema.TAM_CUERPO, Tema.TEXTO, "• " + l)
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		e.custom_minimum_size = Vector2(380, 0)
		v.add_child(e)
	b.add_child(pop)
	pop.popup_hide.connect(pop.queue_free)
	var pos := Vector2i(b.get_screen_position() + Vector2(0, b.size.y + 4))
	pop.popup(Rect2i(pos, Vector2i(400, 0)))
	return pop
