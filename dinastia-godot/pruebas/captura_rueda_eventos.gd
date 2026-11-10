extends Node
## (10-11) Fotos de la rueda de prensa en CRUZ y de los eventos con diálogo (directiva, clásico, mitad de liga). OUT = carpeta (por defecto
## /tmp/fotos_rueda). Comprueba además que la cruz tiene un botón por opción y que elegir cierra la escena. Sale con «FIN. N fallos».
var _fallos := 0

func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout
	await get_tree().process_frame

func _ok(c: bool, que: String) -> void:
	print(("  ok  " if c else "  FALLO  ") + que)
	if not c:
		_fallos += 1

func _foto(dir: String, nombre: String) -> void:
	get_viewport().get_texture().get_image().save_jpg(dir + "/" + nombre + ".jpg", 0.88)
	print("foto: ", nombre)

func _ready() -> void:
	var dir := OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "/tmp/fotos_rueda"
	DirAccess.make_dir_recursive_absolute(dir)
	var p: Principal = load("res://escenas/principal.tscn").instantiate()
	add_child(p)
	await _esperar(3.0)
	CapasTutorial.poner_activas(false)
	for k: String in ["directiva:%d" % p.mundo.anio]:   ## que el evento de la semana 1 no tape la rueda en la foto
		p.mundo.prensa.eventos_vistos.append(k)
	for h in p.get_children():
		if h is EventoDialogo:
			h.queue_free()
	## 1) La rueda de prensa con las respuestas en cruz.
	p.mundo.prensa.abrir_rueda(true, false)
	p._abrir_rueda_pantalla_completa(p.mundo.prensa.entrevista)
	await _esperar(4.0)
	var r: Node = p._rueda_pop
	var nops := (p.mundo.prensa.entrevista.get("opciones", []) as Array).size()
	_ok(r != null and r._opciones is SelectorDireccional and r._opciones.get_child_count() == nops, "la rueda pinta la cruz con un botón por opción (%d)" % nops)
	_foto(dir, "rueda_cruz")
	if r != null:
		(r._opciones as SelectorDireccional).apuntar(1)
		await _esperar(0.4)
		_foto(dir, "rueda_cruz_derecha")
		(r._opciones as SelectorDireccional).elegir(1)
		await _esperar(1.5)
	## 2) Los tres eventos con diálogo.
	for id: String in ["directiva", "clasico", "mitad"]:
		var ev: Dictionary = EventosClub._directiva(p.mundo) if id == "directiva" else (EventosClub._clasico(p.mundo) if id == "clasico" else EventosClub._mitad(p.mundo))
		if ev.is_empty():   ## sin clásico ni mitad de liga hoy: se fuerza el texto para la foto
			ev = EventosClub._directiva(p.mundo)
			ev["id"] = id
			if id == "clasico":
				var cap := EventosClub.capitan(p.mundo.mi_club())
				ev.merge({"lugar": "Vestuario", "quien": cap.nombre, "cargo": "Capitán", "jugador": cap,
					"texto": Idiomas.t("Míster, esta semana es el clásico contra %s. El vestuario está encendido y la ciudad no habla de otra cosa. ¿Qué les decimos a los muchachos?") % "Rival"}, true)
			ev["clave"] = id + ":foto"
		var esc := EventoDialogo.mostrar(p, ev)
		await _esperar(3.0)
		_ok(esc.selector.get_child_count() == (ev["opciones"] as Array).size(), "evento %s: cruz con sus respuestas" % id)
		_foto(dir, "evento_" + id)
		var elegida := [""]
		esc.elegido.connect(func(o: String) -> void: elegida[0] = o)
		esc.selector.elegir(0)
		await _esperar(0.8)
		_ok(elegida[0] == "0", "evento %s: elegir emite la respuesta tras la animación" % id)
		esc.queue_free()
		await _esperar(0.3)
	print("FIN. %d fallos" % _fallos)
	get_tree().quit()
