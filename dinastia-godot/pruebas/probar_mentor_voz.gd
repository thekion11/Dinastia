extends Node
## (19-11-2026) El MENTOR (`MentorVoz`) con pantallas que se cierran: (1) si la pantalla se cierra con el consejo a la vista, el siguiente consejo
## SÍ sale (antes `_mostrando` quedaba en true para siempre y el mentor callaba toda la sesión); (2) un consejo en cola para una pantalla ya
## liberada se salta sin «SCRIPT ERROR: previously freed instance».

var fallos := 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO ", msg)

func _mentores(n: Node) -> int:
	var hay := 0
	for h in n.get_children():
		if h is MentorVoz:
			hay += 1
	return hay

func _ready() -> void:
	MentorVoz._cola.clear()
	MentorVoz._mostrando = false
	var a := Control.new()
	add_child(a)
	MentorVoz.decir(a, null, "Uno", "uno")
	_ok(_mentores(a) == 1, "el consejo asoma en la pantalla")
	await get_tree().process_frame
	a.queue_free()   ## se cambia de pantalla con el consejo a la vista
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(not MentorVoz._mostrando, "al cerrarse la pantalla el mentor queda libre")
	var b := Control.new()
	add_child(b)
	MentorVoz.decir(b, null, "Dos", "dos")
	_ok(_mentores(b) == 1, "el consejo siguiente sale en la pantalla nueva")
	var c := Control.new()
	add_child(c)
	MentorVoz._cola.append({"padre": c, "mundo": null, "titulo": "x", "texto": "y"})
	c.free()
	b.free()   ## cierra el consejo «Dos»: el siguiente de la cola es de una pantalla liberada y se salta
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(MentorVoz._cola.is_empty() and not MentorVoz._mostrando, "la cola con una pantalla liberada se vacía y el mentor queda libre")
	print("FIN. %d fallos" % fallos)
	get_tree().quit()
