class_name InformeSemana
extends RefCounted
## (3-11) Sacado de `PantallaCantera` (capa 3/3): el Inicio del menú central lo pinta siempre al arrancar, y por él se
## compilaba la cantera entera aunque nadie la abriera (la cantera ahora es perezosa: `Principal.PANTALLAS_PEREZOSAS`).

## EL INFORME DE GESTIÓN. Lo primero de la pantalla de Inicio: las seis cosas
## que hay que mirar cada lunes, juntas y con el botón que lleva a arreglarlas.
##
## No añade ninguna mecánica: junta lo que ya está repartido por ocho pestañas.
## Este juego tiene dieciocho, y sin esto un jugador nuevo no sabe cuáles mirar
## y uno veterano se olvida siempre de la misma.
static func pintar(p: Principal) -> void:
	var lineas := p.mundo.informe_de_gestion()
	var t := p._texto(11, Principal.COL_SUAVE)
	t.text = Idiomas.t("📋 INFORME DE LA SEMANA")
	p._lista_inicio.add_child(t)
	for f: Dictionary in lineas:
		var grave := bool(f["grave"])
		var tab := String(f.get("tab", ""))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		p._lista_inicio.add_child(fila)
		var n := p._texto(12, Principal.COL_ROJO if grave else Principal.COL_TEXTO)
		## Traducido ANTES de ponerle la viñeta: los patrones con números
		## («5 contratos terminan…») empiezan en la frase, no en «●».
		n.text = "%s %s" % ["●" if grave else "○", Idiomas.t(String(f["txt"]))]
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.add_child(n)
		if tab == "":
			continue
		var b := Button.new()
		b.text = Idiomas.t(tab)
		b.add_theme_font_size_override("font_size", 10)
		b.clip_text = true
		b.custom_minimum_size = Vector2(92, 24)
		## (12-11) Si el aviso dice a qué pantalla de la pestaña va (`secc`), se abre esa y no la última que se miró.
		var secc := String(f.get("secc", ""))
		b.pressed.connect(func() -> void:
			if secc != "":
				p._ir_a_chip({"tab": tab, "secc": secc})
			else:
				p._ir_a_pestana(tab))
		fila.add_child(b)
	p._lista_inicio.add_child(HSeparator.new())
