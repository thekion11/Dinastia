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
	## Regla del dueño (orden 34): nunca un solo club. Tres clubes de ligas (y países) distintas, con colores claros y oscuros.
	var clubes: Array[Club] = []
	for k in p.mundo.ligas.size():
		var l: Liga = p.mundo.ligas[k]
		if clubes.size() < 3 and l.clubes.size() > 0:
			clubes.append(l.clubes[(k * 5 + 2) % l.clubes.size()])
	while clubes.size() < 3:
		clubes.append(p.mundo.ligas[0].clubes[clubes.size() * 4 % p.mundo.ligas[0].clubes.size()])
	var ids := ["directiva", "clasico", "mitad"]
	for n in clubes.size():
		var club := clubes[n]
		p.mundo.tomar_el_mando(club.id)
		p.mundo.prensa.eventos_vistos.append("directiva:%d" % p.mundo.anio)
		p._refrescar()
		await _esperar(1.0)
		for h in p.get_children():
			if h is EventoDialogo:
				h.queue_free()
		var tag := "%d_%s" % [n, club.pais]
		print("club: ", club.nombre, " (", club.pais, ") acento ", p.COL_ACENTO.to_html(false))
		## 1) La rueda de prensa con las respuestas en cruz.
		p.mundo.prensa.abrir_rueda(true, false)
		p._abrir_rueda_pantalla_completa(p.mundo.prensa.entrevista)
		await _esperar(4.0)
		var r: Node = p._rueda_pop
		var nops := (p.mundo.prensa.entrevista.get("opciones", []) as Array).size()
		_ok(r != null and r._opciones is SelectorDireccional and r._opciones.get_child_count() == nops, "%s: la rueda pinta la cruz con un botón por opción (%d)" % [club.nombre, nops])
		if r != null:
			(r._opciones as SelectorDireccional).apuntar(1)
			await _esperar(0.4)
			_foto(dir, "rueda_" + tag)
			(r._opciones as SelectorDireccional).elegir(1)
			await _esperar(1.5)
		while p._rueda_pop != null:
			p._responder(0)
			await _esperar(0.5)
		## 2) Un evento con diálogo por club (los tres rotan).
		var id: String = ids[n]
		var ev: Dictionary = EventosClub._directiva(p.mundo) if id == "directiva" else (EventosClub._clasico(p.mundo) if id == "clasico" else EventosClub._mitad(p.mundo))
		if ev.is_empty():   ## fuera de fecha: se fuerza el texto para la foto
			ev = EventosClub._directiva(p.mundo)
			ev["id"] = id
			if id == "clasico":
				var cap := EventosClub.capitan(club)
				ev.merge({"lugar": "Vestuario", "quien": cap.nombre, "cargo": "Capitán", "jugador": cap,
					"texto": Idiomas.t("Míster, esta semana es el clásico contra %s. El vestuario está encendido y la ciudad no habla de otra cosa. ¿Qué les decimos a los muchachos?") % clubes[(n + 1) % 3].nombre}, true)
		var esc := EventoDialogo.mostrar(p, ev)
		await _esperar(3.0)
		_ok(esc.selector.get_child_count() == (ev["opciones"] as Array).size(), "%s · evento %s: cruz con sus respuestas" % [club.nombre, id])
		_foto(dir, "evento_%s_%s" % [id, tag])
		var elegida := [""]
		esc.elegido.connect(func(o: String) -> void: elegida[0] = o)
		esc.selector.elegir(0)
		await _esperar(0.8)
		_ok(elegida[0] == "0", "evento %s: elegir emite la respuesta tras la animación" % id)
		esc.queue_free()
		await _esperar(0.3)
	print("FIN. %d fallos" % _fallos)
	get_tree().quit()
