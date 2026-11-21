extends RefCounted
## [Capa 1/3 de `recorrido_club.gd`] aviso_de, y_de, menu_ascensor, respuesta_oficio, dialogo, dialogo_portero … (+6)

## Cómo te recibe cada uno (lo primero que dice al acercarte).
const SALUDOS := {
	"conserje": "Buenas, míster. Hoy entra usted temprano, ¿eh? Yo abro a las siete.",
	"jardinero": "Cuidado con pisar el área chica, que la acabo de resembrar.",
	"hincha": "¡Míster! Treinta años en esta puerta. Ganemos el domingo, por favor.",
	"utilero": "Las camisetas ya están lavadas y colgadas. Cada uno en su sitio.",
	"medico": "Pase, pase. Le cuento cómo están los tocados.",
	"chofer": "El bus está listo cuando usted diga. Yo no escucho nada… casi nada.",
	"secretaria": "Tiene tres llamadas del presidente y un contrato para firmar.",
	"ojeador": "Estoy viendo a un chico del barrio. Tiene algo, se lo digo yo.",
	"presidente": "Siéntese. Hablemos de cómo va esto.",
	"prensa": "La sala está lista. Intente no encender ningún fuego hoy.",
	"cocinera": "Hoy hay legumbres. Y nadie se levanta sin terminar el plato.",
	"portero": "Aquí estoy, míster. Nadie entra sin que yo lo vea.",
}

const PREGUNTA_OFICIO := {
	"medico": "¿Cómo está la enfermería?",
	"cocinera": "¿Cómo ves al grupo?",
	"jardinero": "¿Cómo está el césped?",
	"secretaria": "¿Cómo va la caja?",
	"utilero": "¿Quién está más fino esta semana?",
	"ojeador": "¿Algún chico de la cantera que valga?",
}

const _RUTA_PERSONAL_ESTADIO := "res://visor/personal_estadio.gd"
const _RUTA_STADIUM_BUILDER := "res://visor/stadium_builder.gd"


## ¿La última respuesta fue mala noticia? (para la cara de quien la dice)
static var _ultima_mala := false

## Lo que cuenta el portero si le preguntas (gente ficticia del club).
const NOVEDADES_PORTERO := [
	"Esta mañana vino un periodista preguntando por usted. Le dije que no estaba.",
	"El jefe de cancha lleva dos horas regando la misma esquina. Algo le pasa con esa esquina.",
	"Han llegado las camisetas nuevas; el utilero no deja ni mirarlas.",
	"Anoche se quedó encendida la luz de la sala de vídeo. Ya la apagué yo.",
	"Un chico del barrio dejó una carta para el capitán. La tengo guardada aquí.",
	"El de la puerta 7 ya está ahí fuera. Dice que hoy no se mueve hasta el domingo.",
	"El bus salió a lavar y volvió más sucio. No pregunte.",
]
## Lo común a recorrer el estadio a pie, desde la ciudad (`ExploradorCiudad`)
## o desde la vista del estadio (`ExploradorEstadio`): el texto de cada zona y
## el panel del ascensor del edificio del club (estadio interactivo 2.0).

## El aviso de abajo al entrar en una zona.
static func aviso_de(nombre: String, _club: String = "") -> String:
	match nombre:
		"Vestuario":
			return Idiomas.t("El vestuario. Por el túnel se sale al campo.")
		"Túnel":
			return Idiomas.t("El túnel. Al fondo se oye la grada.")
		"Banda":
			return Idiomas.t("¡A la cancha!")
		"Acceso":
			return Idiomas.t("E: salir a la calle")
		"Ascensor":
			return Idiomas.t("E: llamar al ascensor")
		"Pasillo", "Campo", "":
			return ""
	return Idiomas.t(nombre)

## La altura del suelo de una planta.
static func y_de(planta: int) -> float:
	return float(planta) * EdificioClub.ALTO_PLANTA + 0.02

## El panel del ascensor: un botón por planta. `al_elegir(planta)`.
static func menu_ascensor(capa: CanvasLayer, actual: int, al_elegir: Callable) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -190
	panel.offset_right = 190
	panel.offset_top = -170
	panel.offset_bottom = 170
	panel.add_theme_stylebox_override("panel", CuadroDialogo.estilo_panel())
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	panel.add_child(caja)
	var t := Label.new()
	t.text = "🛗 " + Idiomas.t("Ascensor")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 20)
	caja.add_child(t)
	var plantas := EdificioClub.plantas()
	plantas.reverse()
	for p: int in plantas:
		var b := Button.new()
		b.text = "%s %d · %s" % ["▶" if p == actual else "  ", p, Idiomas.t(EdificioClub.nombre_planta(p))]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = p == actual
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(func() -> void:
			panel.queue_free()
			al_elegir.call(p))
		caja.add_child(b)
	var cerrar := Button.new()
	cerrar.text = Idiomas.t("Cerrar")
	cerrar.pressed.connect(func() -> void: panel.queue_free())
	caja.add_child(cerrar)
	capa.add_child(panel)
	return panel
