extends Node
## Captura de los eventos de la selección (oferta del cargo y partido de un torneo) a pantalla completa (necesita pantalla: xvfb-run).
## xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/captura_cargo_seleccion.tscn  → /tmp/sel_oferta.jpg y /tmp/sel_partido.jpg y /tmp/sel_convocatoria.jpg
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n != 12:
		return
	var m: Mundo = _p.mundo
	var sel_n := OS.get_environment("SEL") if OS.get_environment("SEL") != "" else "Marruecos"
	var c := SeleccionEquipo.club_de(m, sel_n, m.selecciones.fuerza(sel_n), m.anio)
	var ev := EventoSeleccion.oferta(_p, c, m.selecciones.fuerza(sel_n), 2400)
	await get_tree().create_timer(1.2).timeout
	get_viewport().get_texture().get_image().save_jpg("/tmp/sel_oferta.jpg", 0.9)
	ev.queue_free()
	m.selecciones.cargo.ofrecer(sel_n, m.selecciones.fuerza(sel_n), 2400)
	m.selecciones.cargo.responder(m, true)
	var t := SeleccionesTorneos.mundial(m.selecciones, m, 2026)
	var mia := SeleccionesTorneos.equipo_en(t, sel_n)
	if mia == null:
		print("FIN. 1 fallos (no está en el Mundial)")
		get_tree().quit()
		return
	t.jugar_fecha()
	var par := t.partido_de(mia)
	var ev2 := EventoSeleccion.partido(_p, t, mia, par[1] if par[0] == mia else par[0])
	await get_tree().create_timer(1.2).timeout
	get_viewport().get_texture().get_image().save_jpg("/tmp/sel_partido.jpg", 0.9)
	ev2.queue_free()
	JornadaSeleccion.abrir_convocatoria(_p)
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_jpg("/tmp/sel_convocatoria.jpg", 0.9)
	print("CAPTURA OK")
	get_tree().quit()
