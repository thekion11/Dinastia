extends Control
## LLAMADAS DE DIBUJO DEL HUD DE TV, PIEZA A PIEZA (17-11). Sin estadio (solo el lienzo 2D, se mide en segundos): el marcador, el
## radar con 22 jugadores, 3 árbitros y el balón, los nombres y aros de dos jugadores y el aviso de repetición, cada uno solo y
## todos juntos. Con GPU por software sirve igual: las llamadas no dependen de la máquina.
##   xvfb-run -a godot --path . --rendering-driver vulkan --resolution 1366x768 res://pruebas/medir_hud_tv.tscn
var _n := 0
var _piezas: Array[Control] = []
var _nombres := ["marcador", "radar", "nombres", "repetición"]
var _fase := -1
var _suma := 0.0
var _cuenta := 0

func _ready() -> void:
	size = Vector2(1366, 768)
	var a := Club.new("m_a", "Atlético Brisas")
	a.color1 = "#1d4fa3"
	a.color2 = "#ffffff"
	var b := Club.new("m_b", "Deportivo Ceibo")
	b.color1 = "#c41e2a"
	b.color2 = "#111111"
	var m := MarcadorTV.poner(self, a, b)
	m.fijar(2, 1, "67'")
	var r := RadarPartido.new()
	add_child(r)
	r.size = Vector2(210, 136)
	r.position = Vector2(578, 520)
	var lista: Array = []
	for i in 25:
		var n := Node3D.new()
		add_child(n)
		n.position = Vector3(randf_range(-30, 30), 0, randf_range(-50, 50))
		n.rotation.y = randf() * TAU
		lista.append({"node": n, "es_local": i % 2 == 0, "arbitro": i >= 22})
	r.jugadores = lista
	var bal := Node3D.new()
	add_child(bal)
	r.balon = bal
	r.jugador_activo = lista[0]["node"]
	var nt := NombresTV.new()
	add_child(nt)
	nt.set_process(false)
	nt.size = size
	var marcas: Array = []
	for k in 2:
		var c := Vector2(500 + k * 260, 400)
		var aro := PackedVector2Array()
		var atras: Array[bool] = []
		for j in NombresTV.LADOS_ARO + 1:
			aro.append(c + Vector2(cos(TAU * j / NombresTV.LADOS_ARO) * 40, sin(TAU * j / NombresTV.LADOS_ARO) * 14))
			atras.append(j < NombresTV.LADOS_ARO / 2)
		marcas.append({"aro": aro, "atras": atras, "col": Color.RED if k == 0 else Color.WHITE, "nombre": "APELLIDO%d" % k, "pie": c,
			"grande": k == 0, "sin_aro": false, "receptor": k == 1, "cabeza": c - Vector2(0, 90)})
	nt.set("_marcas", marcas)
	nt.queue_redraw()
	var rr := RotuloRepeticion.entrar(self, null)
	_piezas = [m, r, nt, rr]
	for c in _piezas:
		c.visible = false

func _process(_d: float) -> void:
	_n += 1
	## Fases de 20 fotogramas: −1 = nada, 0..3 = una pieza, 4 = todas. Se descartan los 4 primeros de cada fase.
	var fase := _n / 20 - 1
	if fase != _fase:
		if _fase >= -1 and _cuenta > 0:
			print("HUD_TV %s: %.1f llamadas 2D" % ["sin HUD" if _fase == -1 else ("todo junto" if _fase == 4 else _nombres[_fase]), _suma / _cuenta])
		_fase = fase
		_suma = 0.0
		_cuenta = 0
		if fase > 4:
			get_tree().quit()
			return
		for i in _piezas.size():
			_piezas[i].visible = fase == 4 or fase == i
			_piezas[i].queue_redraw()
	if _n % 20 >= 4:
		_suma += get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_CANVAS, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
		_cuenta += 1
