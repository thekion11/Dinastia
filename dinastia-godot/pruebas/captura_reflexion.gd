extends Node
## (16-11) Fotos de la pantalla de reflexión de los días de memoria (`EventoReflexion`) en varios PAÍSES (regla del dueño: nunca uno solo).
## PAISES=NED,TUR,… e IDIOMA=de para otras pruebas. OUT = carpeta (por defecto /tmp/fotos_reflexion); MOVIL=1 = como en un teléfono. Comprueba que el botón cierra la escena. Sale con «FIN. N fallos».
var _fallos := 0

func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout
	await get_tree().process_frame

func _ok(c: bool, que: String) -> void:
	print(("  ok  " if c else "  FALLO  ") + que)
	if not c:
		_fallos += 1

func _ready() -> void:
	if OS.get_environment("MOVIL") == "1":
		EscalaMovil.forzar = true
		EscalaMovil.poner(get_tree(), EscalaMovil.ZOOM_MOVIL)
	var dir := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/fotos_reflexion"
	DirAccess.make_dir_recursive_absolute(dir)
	var p: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	await _esperar(3.0)
	CapasTutorial.poner_activas(false)
	if OS.get_environment("IDIOMA") != "":
		Idiomas.idioma = OS.get_environment("IDIOMA")
	var lista: PackedStringArray = (OS.get_environment("PAISES") if OS.get_environment("PAISES") != "" else "CHI,USA,GER,JPN,ENG").split(",")
	for pais: String in lista:
		var dia := {}
		for f: Dictionary in Calendario.del_anio(pais, 2026):
			if String(f["tipo"]) == "memoria":
				dia = {"nombre": f["nombre"], "pais": pais, "dia": f["dia"], "mes": f["mes"], "texto": f["texto"],
					"reflexion": DiasMemoria.reflexion_de(f), "cat": f.get("cat", "")}
				break
		_ok(not dia.is_empty(), "%s tiene un día de memoria" % pais)
		var e := EventoReflexion.mostrar(p, dia)
		var cerrado := [false]
		e.elegido.connect(func(_o: String) -> void: cerrado[0] = true)
		await _esperar(2.5)
		get_viewport().get_texture().get_image().save_jpg(dir + "/reflexion_" + pais + ".jpg", 0.88)
		e.barra.value = 1.0
		for b in e.find_children("*", "Button", true, false):
			(b as Button).pressed.emit()
		await _esperar(0.2)
		_ok(cerrado[0], "%s: «Continuar» cierra la escena" % pais)
		e.queue_free()
		await _esperar(0.2)
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
