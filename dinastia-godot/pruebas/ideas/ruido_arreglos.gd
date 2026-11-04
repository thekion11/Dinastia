extends BaseIdea
## RUIDO DE REGISTROS (3-11, «detectar fallos»): errores reales que salían aunque la prueba pasara. Aquí, uno por uno: el ancla del suelo con el reproductor tirado, un meta que falta,
## una señal conectada dos veces, y el «+5 %» sin escapar de la cita de patrocinio en todos los idiomas.
func _ready() -> void:
	await get_tree().process_frame
	_titulo("RUIDO DE REGISTROS · arreglos")
	## 1. AnclaSuelo sin reproductor: se apaga solo, sin «assigned_animation on Nil» cada fotograma.
	var nodo := Node3D.new()
	add_child(nodo)
	var a := AnclaSuelo.new()
	a._nodo = nodo
	a._modelo = Node3D.new()
	a._esq = Skeleton3D.new()
	a._anim = AnimationPlayer.new()
	nodo.add_child(a)
	a._anim.free()
	a._process(0.016)
	_comprobar(not a.is_processing(), "AnclaSuelo con el reproductor tirado se apaga solo")
	a._modelo.free()
	a._esq.free()
	## 2. MandoTactil.leer sin el meta: devuelve el respaldo (y no escribe ERROR).
	var e := Node.new()
	_comprobar(MandoTactil.leer(e, Vector2(0.3, 0.4)) == Vector2(0.3, 0.4), "sin mando táctil se usa el respaldo")
	e.free()
	## 3. Conexion.una_vez: dos veces, una conexión.
	var emisor := Node.new()
	emisor.add_user_signal("hola")
	var cb := func() -> void: pass
	Conexion.una_vez(Signal(emisor, "hola"), cb)
	Conexion.una_vez(Signal(emisor, "hola"), cb)
	_comprobar(emisor.get_signal_connection_list("hola").size() == 1, "Conexion.una_vez no duplica la conexión")
	emisor.free()
	## 4. La cita de patrocinio firmada en persona se formatea bien en los nueve idiomas.
	var antes := Idiomas.idioma
	for l: String in ["es", "en", "pt", "fr", "it", "de", "ca", "pl", "tr"]:
		Idiomas.idioma = l
		var t := Idiomas.t("%s cierra %s por %s al año (+5 %% por cerrarlo en persona).") % ["Marca", "la camiseta", "100.000 €"]
		_comprobar(t != "" and not t.contains("%s") and t.contains("5"), "la cita «firmado en persona» sale bien en %s: %s" % [l, t])
		var t2 := Idiomas.t("«Represento a %d de los tuyos. Tratemos bien a mi gente y la próxima mesa será más barata.» (−5 %% en su próxima negociación.)") % 3
		_comprobar(t2 != "" and t2.contains("3") and t2.contains("5"), "y la del agente (−5 %%) en %s" % l)
	Idiomas.idioma = antes
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
