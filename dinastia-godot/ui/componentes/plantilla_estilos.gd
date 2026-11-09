class_name PlantillaEstilos
extends RefCounted
## EL ESTILO DE JUEGO EN LA PLANTILLA (9-11; idea de la «Opción de entrenamiento» y la «Información del jugador» del PES: estilo de juego y habilidades con
## ESTRELLAS). Para el jugador elegido, los roles de su línea con las estrellas de lo bien que le van (`Vestuario.aptitud_rol`) y el actual marcado; un clic lo
## cambia (como en Táctica: `Vestuario.fijar_rol_tactico` + `Tactica.poner_rol`).
const UMBRALES := [0.95, 1.02, 1.10]   ## aptitud mínima para 1, 2 y 3 estrellas

## 0-3 estrellas según la aptitud del jugador para el rol.
static func estrellas(aptitud: float) -> int:
	var n := 0
	for u: float in UMBRALES:
		if aptitud >= u:
			n += 1
	return n

static func texto_estrellas(n: int) -> String:
	return "★".repeat(n) + "☆".repeat(3 - n)

## Pinta la sección en `caja`. `al_cambiar` se llama tras cambiar de rol (para repintar la pantalla).
static func pintar(m: Mundo, club: Club, j: Jugador, caja: Container, al_cambiar: Callable) -> void:
	var v := m.vestuario if m != null else null
	if v == null or j == null:
		return
	var tabla: Dictionary = v.tabla_roles_tacticos()
	var actual: String = v.rol_tactico(j)
	var t := Label.new()
	t.text = Idiomas.t("ESTILO DE JUEGO")
	t.add_theme_font_size_override("font_size", 12)
	t.add_theme_color_override("font_color", Tema.ORO)
	caja.add_child(t)
	var claves: Array = v.roles_de_grupo(Datos.grupo(j.pos_e))
	claves.sort()
	for clave: String in claves:
		var b := Button.new()
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var es_actual := clave == actual
		var n := estrellas(v.aptitud_rol(j, clave))
		b.text = "%s  %s%s" % [texto_estrellas(n), Idiomas.t(String((tabla[clave] as Array)[0])), "  ✔" if es_actual else ""]
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", Tema.ORO if es_actual else Tema.TEXTO)
		b.tooltip_text = "%s: %.2f" % [Idiomas.t("Aptitud"), v.aptitud_rol(j, clave)]
		b.pressed.connect(func() -> void:
			v.fijar_rol_tactico(j, clave)
			club.tactica.poner_rol(j, String(RolTactico.DE_VESTUARIO.get(clave, "")))
			if al_cambiar.is_valid():
				al_cambiar.call())
		caja.add_child(b)
