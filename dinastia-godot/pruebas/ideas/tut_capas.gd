extends BaseIdea
## TUTORIAL POR CAPAS (27-10-2026, fila 1040): la ayuda de cada pantalla sale la primera vez que se abre, se descarta, se apaga y se reinicia.

func _ready() -> void:
	await get_tree().process_frame
	var copia := FileAccess.get_file_as_string(CapasTutorial.ARCHIVO) if FileAccess.file_exists(CapasTutorial.ARCHIVO) else ""
	await _probar_capas()
	## Se deja el archivo de ajustes como estaba.
	if copia == "":
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CapasTutorial.ARCHIVO))
	else:
		FileAccess.open(CapasTutorial.ARCHIVO, FileAccess.WRITE).store_string(copia)
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _probar_capas() -> void:
	_titulo("TUTORIAL · POR CAPAS, LA PRIMERA VEZ QUE SE USA CADA SISTEMA")
	CapasTutorial.forzar = true
	CapasTutorial.reiniciar()
	_comprobar(CapasTutorial.debe_mostrar("Táctica"), "la primera vez, la capa de Táctica toca")
	_comprobar(not CapasTutorial.debe_mostrar("Inventada"), "una pantalla sin ayuda no sale")
	_comprobar(not CapasTutorial.debe_mostrar("Táctica", true), "con el modo experto no sale")
	for t in ["Mi plantel", "Táctica", "Entrenar", "Enfermería", "Camarín", "Contratos", "Cantera", "Finanzas", "Mercado"]:
		_comprobar(AyudaPestana.lineas(t).size() == 3, "«%s» tiene sus tres líneas de ayuda" % t)
	CapasTutorial.marcar_vista("Táctica")
	_comprobar(not CapasTutorial.debe_mostrar("Táctica") and CapasTutorial.debe_mostrar("Entrenar"), "una capa vista no vuelve; las demás siguen")
	CapasTutorial.poner_activas(false)
	_comprobar(not CapasTutorial.debe_mostrar("Entrenar"), "apagadas las ayudas, ninguna sale")
	CapasTutorial.reiniciar()
	_comprobar(CapasTutorial.activas() and CapasTutorial.debe_mostrar("Táctica"), "reiniciar las enciende y vuelve a empezar")
	CapasTutorial.forzar = false
	_comprobar(not CapasTutorial.debe_mostrar("Táctica"), "sin pantalla (headless) y sin forzar no sale nunca")
	CapasTutorial.forzar = true
	## La tarjeta suelta.
	var padre := Control.new()
	add_child(padre)
	var tarjeta := CapaTutorialUI.mostrar(padre, "Entrenar")
	_comprobar(tarjeta.name == "CapaTutorial" and tarjeta.find_children("*", "Label", true, false).size() == 4, "la tarjeta lleva el título y las tres líneas")
	(tarjeta.find_child("Entendido", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_comprobar(not is_instance_valid(tarjeta) and not CapasTutorial.debe_mostrar("Entrenar") and CapasTutorial.activas(), "«Entendido» la cierra y no vuelve esa capa, las demás sí")
	var t2 := CapaTutorialUI.mostrar(padre, "Camarín")
	(t2.find_child("NoMostrar", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_comprobar(not CapasTutorial.activas() and not CapasTutorial.debe_mostrar("Contratos"), "«No mostrar más ayudas» las apaga todas")
	## En la pantalla de verdad: abrir una pestaña la primera vez saca la tarjeta; la segunda, no.
	CapasTutorial.reiniciar()
	var p: Node = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	for i in 8:
		await get_tree().process_frame
	p.call("_ir_a_pestana", "Táctica")
	p.call("_ir_a_pestana", "Entrenar")
	await get_tree().process_frame
	var tar := p.get_node_or_null("CapaTutorial")
	_comprobar(tar != null and (tar.find_child("Entendido", true, false) != null), "al abrir una pestaña por primera vez sale su tarjeta en la pantalla")
	(tar.find_child("Entendido", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	p.call("_ir_a_pestana", "Camarín")
	p.call("_ir_a_pestana", "Entrenar")   ## ya vista: no saca otra; sigue la de Camarín (la nueva)
	await get_tree().process_frame
	var otra := p.get_node_or_null("CapaTutorial")
	_comprobar(otra != null and (otra.find_children("*", "Label", true, false)[0] as Label).text.contains("Camarín"), "y al volver a una que ya viste, no sale otra vez")
	if otra != null:
		otra.free()
	p.set("_modo_experto", true)
	CapasTutorial.reiniciar()
	p.call("_ir_a_pestana", "Cantera")
	await get_tree().process_frame
	_comprobar(p.get_node_or_null("CapaTutorial") == null, "con el modo experto no sale nada")
	CapasTutorial.forzar = false
