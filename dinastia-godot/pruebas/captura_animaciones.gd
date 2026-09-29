extends Node
## LAS MINI ANIMACIONES (25-9-2026, plan maestro B11), comprobadas en la pantalla
## real: la caja cuenta hasta su valor nuevo pasando por intermedios, y al
## cambiar de pestaña el contenido entra escalonado (a mitad de camino, unos
## elementos ya se ven y otros todavía no).
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_animaciones.tscn
const ESPERA := 12
var _n := 0
var _pantalla: Node
var _textos: Array[String] = []
var _fallos := 0

func _ok(c: bool, t: String) -> void:
	print(("  ok    " if c else "  FALLO ") + t)
	if not c:
		_fallos += 1

func _ready() -> void:
	Animar.fijar_reducidas(false)
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	var caja: Label = _pantalla.get("_lbl_caja")
	if _n == ESPERA:
		var c: Club = _pantalla.get("mundo").mi_club()
		c.saldo += 25_000_000
		_pantalla.call("_refrescar")
	if _n > ESPERA and _n <= ESPERA + 50:
		if _textos.is_empty() or _textos[-1] != caja.text:
			_textos.append(caja.text)
	if _n == ESPERA + 51:
		_ok(_textos.size() >= 4, "la caja pasa por %d valores intermedios al cobrar" % (_textos.size() - 1))
		_pantalla.call("_ir_a_pestana", "Calendario")
	if _n == ESPERA + 51 + 18:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/animacion_pestana.png")
		var lista: Node = _pantalla.get("_lista_calendario")
		var transparentes := 0
		var visibles := 0
		for h in lista.get_children():
			if h is Control and (h as Control).visible:
				var a := (h as Control).modulate.a
				if a < 0.5:
					transparentes += 1
				elif a > 0.85:
					visibles += 1
		_ok(transparentes > 0 and visibles > 0, "a mitad de la entrada unos ya se ven (%d) y otros siguen entrando (%d)" % [visibles, transparentes])
	if _n == ESPERA + 120:
		var lista2: Node = _pantalla.get("_lista_calendario")
		var quedan := 0
		for h in lista2.get_children():
			if h is Control and (h as Control).visible and (h as Control).modulate.a < 0.99:
				quedan += 1
		_ok(quedan == 0, "al terminar no queda nada a medio aparecer (%d)" % quedan)
		print("===== ANIMACIONES: %d fallos =====" % _fallos)
		get_tree().quit()
