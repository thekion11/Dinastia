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
	pintar_en(p, p._lista_inicio, false)

## (17-11) Lo que enseña la tarjeta «Informe de la semana» del escaparate: el titular (el aviso grave más urgente o, si no hay, el primero), cuántos avisos graves y cuántos hay.
static func resumen(p: Principal) -> Dictionary:
	var lineas := p.mundo.informe_de_gestion()
	var graves := 0
	var titular := ""
	for f: Dictionary in lineas:
		if bool(f["grave"]):
			graves += 1
			if titular == "":
				titular = String(f["txt"])
	if titular == "" and not lineas.is_empty():
		titular = String(lineas[0]["txt"])
	return {"titular": Idiomas.t(titular) if titular != "" else Idiomas.t("Todo en orden esta semana."), "graves": graves, "total": lineas.size()}

## Las líneas del informe en `destino`. Con `grande` (pantalla completa del escaparate) cada aviso con destino lleva un botón grande (focos de mando y teclado); `al_ir` se llama antes de ir a la pantalla del aviso (para cerrar la capa).
static func pintar_en(p: Principal, destino: Control, grande: bool, al_ir := Callable()) -> void:
	var lineas := p.mundo.informe_de_gestion()
	if not grande:
		var t := p._texto(11, Principal.COL_SUAVE)
		t.text = Idiomas.t("📋 INFORME DE LA SEMANA")
		destino.add_child(t)
	for f: Dictionary in lineas:
		var grave := bool(f["grave"])
		var tab := String(f.get("tab", ""))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		destino.add_child(fila)
		var n := p._texto(18 if grande else 12, Principal.COL_ROJO if grave else Principal.COL_TEXTO)
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
		b.add_theme_font_size_override("font_size", 16 if grande else 10)
		b.clip_text = true
		b.custom_minimum_size = Vector2(190, 44) if grande else Vector2(92, 24)
		## (12-11) Si el aviso dice a qué pantalla de la pestaña va (`secc`), se abre esa y no la última que se miró.
		var secc := String(f.get("secc", ""))
		b.pressed.connect(func() -> void:
			if al_ir.is_valid():
				al_ir.call()
			if secc != "":
				p._ir_a_chip({"tab": tab, "secc": secc})
			else:
				p._ir_a_pestana(tab))
		fila.add_child(b)
	if not grande:
		destino.add_child(HSeparator.new())
