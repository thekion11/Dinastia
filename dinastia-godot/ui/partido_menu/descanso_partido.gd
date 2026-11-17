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

static func mostrar(v: Node) -> DescansoPartido:
	var p: Partido = v.get("partido")
	var club: Club = v.get("mi_club")
	if p == null or club == null or DisplayServer.get_name() == "headless":
		return null
	var d := DescansoPartido.new()
	d.vivo = v
	var pr := v.get_parent()
	while pr != null and not (pr is Principal):
		pr = pr.get_parent()
	d.montar(pr if pr != null else v, FondoCine.Modo.NOCHE, Color.BLACK)
	ResumenPartidoCine.montar(d._raiz, p, club, true)
	var lista: Array = [["Continuar", d._continuar, true], ["Cambios", d.cerrar_resumen, false]]
	if pr is Principal and (pr as Principal)._menu_lateral != null:
		lista.append(["Táctica", d._tactica.bind(pr), false])
	ResumenPartidoCine.botones(d._raiz, lista)
	return d

func _continuar() -> void:
	cerrar_resumen()
	if is_instance_valid(vivo) and vivo.has_method("_salir_segunda"):
		vivo.call("_salir_segunda")

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
