class_name DescansoPartido
extends PantallaMaqueta
## EL DESCANSO (17-11-2026, Auditoría: «al nivel de la referencia»). Al llegar al 45 en la pantalla del partido en vivo (`PartidoVivo`, también cuando
## el 3D se para en el descanso y vuelve a ella), sale a pantalla completa el resumen de la primera parte (`ResumenPartidoCine`: marcador con escudos,
## goleadores con su minuto, barras con las cifras reales y la figura de la primera parte) con tres botones:
##   CONTINUAR → sale a la segunda parte (lo mismo que «Salir a la segunda parte» del camarín, sin charla);
##   CAMBIOS   → cierra el resumen y deja a la vista el camarín y el banquillo (charla, cambios e instrucciones, como siempre);
##   TÁCTICA   → abre la pantalla de Táctica del juego (`PlanPartidoUI`), y al cerrarla vuelve aquí.
## Lo abre `PartidoVivo` con `load()`; no cambia nada del partido por sí mismo.

var vivo: Node
static var en_pruebas := false   ## el banco lo abre sin pantalla (para probar el mando)

static func mostrar(v: Node) -> DescansoPartido:
	var p: Partido = v.get("partido")
	var club: Club = v.get("mi_club")
	if p == null or club == null or (DisplayServer.get_name() == "headless" and not en_pruebas):
		return null
	var d := DescansoPartido.new()
	d.vivo = v
	var pr := v.get_parent()
	while pr != null and not (pr is Principal):
		pr = pr.get_parent()
	d.montar(pr if pr != null else v, FondoCine.Modo.NOCHE, Color.BLACK)
	ResumenPartidoCine.montar(d._raiz, p, club, true)
	var lista: Array = [["Continuar", d._continuar, true], ["Cambios", d.cerrar_resumen, false]]
	if p.has_meta("simulando_resto") and bool(p.get_meta("simulando_resto")):
		## (17-11, Auditoría) Se llegó aquí con «Simular el resto» en la 1.ª parte: seguir simulando (la 2.ª parte la juega el simulador del juego), volver
		## a jugar la 2.ª parte en 3D o hacer cambios en el camarín.
		p.remove_meta("simulando_resto")
		lista = [["Continuar simulando", d._seguir_simulando, true], ["Volver a jugar", d._continuar, false], ["Cambios", d.cerrar_resumen, false]]
	elif pr is Principal and (pr as Principal)._menu_lateral != null:
		lista.append(["Táctica", d._tactica.bind(pr), false])
	ResumenPartidoCine.botones(d._raiz, lista)
	MandoMenuPartido.escuchar(d, d.cerrar_resumen)
	d.visible = false   ## (17-11) entra bajo el barrido de color: del partido al descanso sin corte seco
	BarridoPartido.pasar(v, BarridoPartido.colores_de(p), func() -> void:
		if is_instance_valid(d):
			d.visible = true
			ResumenPartidoCine.enfocar(d._raiz))
	return d

func _continuar() -> void:
	var v := vivo
	BarridoPartido.pasar(_raiz, BarridoPartido.colores_de(v.get("partido") if is_instance_valid(v) else null), func() -> void:
		cerrar_resumen()
		if is_instance_valid(v) and v.has_method("_salir_segunda"):
			v.call("_salir_segunda"))

## La 2.ª parte simulada con el `Partido` (el simulador calibrado del juego), del marcador y el minuto de ahora; al acabar sale el resultado final.
func _seguir_simulando() -> void:
	var v := vivo
	BarridoPartido.pasar(_raiz, BarridoPartido.colores_de(v.get("partido") if is_instance_valid(v) else null), func() -> void:
		cerrar_resumen()
		if is_instance_valid(v) and v.has_method("_hasta_el_final"):
			v.set("_entretiempo", false)
			v.call("_hasta_el_final"))

func cerrar_resumen() -> void:
	Sonido.toca("clic")
	elegido.emit("cerrar")
	queue_free()

func _tactica(pr: Principal) -> void:
	visible = false
	var pm := PlanPartidoUI.abrir(pr)
	if pm == null:
		visible = true
		return
	pm.cerrada.connect(func() -> void:
		if is_instance_valid(self):
			visible = true)

func _unhandled_input(e: InputEvent) -> void:
	if visible and e.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar_resumen()
