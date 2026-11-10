extends Node
## PICOS DE LOS PRIMEROS FOTOGRAMAS DEL PARTIDO 3D (10-11-2026, sesión 5): tiempo real de cada fotograma desde que se abre la vista, SIN saltar la intro, y qué pasa al saltarla, al empezar a jugar y
## con el festejo (confeti/bengalas), que es lo primero que enciende materiales nuevos. Sirve para ver si hay tirones por compilar shaders al primer dibujado (en llvmpipe la compilación de GLSL es real).
##   PAIS=ESP CLUB=5 HW_DRIVER=opengl3 herramientas/hw_modesto.sh res://pruebas/medir_picos_partido.tscn -- baja
## Imprime los 12 fotogramas más largos con su número y la fase en que ocurrieron, y la mediana.
var _vista: VistaEstadio
var _n := 0
var _t_ant := 0
var _t: Array[float] = []
var _fase: Array[String] = []
var _fase_act := "montaje"
var _fin := false
var _par: Array = []
var _pausa := false
var _vuelta := 0   ## DOBLE=1: se abre, se cierra a los 60 fotogramas y se abre otra vez en el mismo proceso (shaders ya compilados): si los picos siguen, no eran shaders.

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ALTO)
	var mundo := Mundo.new()
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	mundo.generar([pais], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[int(OS.get_environment("CLUB")) % mundo.ligas[0].clubes.size()].id
	var par := mundo.proximo_partido()
	_par = par
	_abrir()

func _abrir() -> void:
	_vista = VistaEstadio.new()
	add_child(_vista)
	_t_ant = Time.get_ticks_usec()
	_pausa = true
	await _vista.abrir(_par[0], 0.85, _par[1], Partido.new(_par[0], _par[1]))
	if OS.get_environment("ESTAB") != "":
		await PantallaCarga.estabilizar(get_tree())   ## como el juego de verdad: 10 fotogramas dibujados debajo de la carga antes de enseñar el partido
	_t_ant = Time.get_ticks_usec()
	_pausa = false

func _process(_d: float) -> void:
	if _fin or _pausa:
		return
	var ahora := Time.get_ticks_usec()
	_t.append(float(ahora - _t_ant) / 1000.0)
	_fase.append(_fase_act)
	_t_ant = ahora
	_n += 1
	if OS.get_environment("DOBLE") != "" and _vuelta == 0 and _n == 60:
		_vuelta = 1
		_pausa = true
		print("PRIMERA APERTURA: %d fotogramas, suma %.0f ms, los 6 mayores %s" % [_t.size(), _suma(), str(_mayores(6))])
		_vista.queue_free()
		_t.clear(); _fase.clear(); _n = 0; _fase_act = "montaje"
		for k in 6:
			await get_tree().process_frame
		_pausa = false
		_abrir()
		return
	var intro: Variant = _vista.get("_intro")
	var cer: Variant = _vista.get("_ceremonia")
	if intro != null and is_instance_valid(intro) and intro.activa:
		_fase_act = "intro"
		if _n == 40:
			_fase_act = "salto_intro"
			intro.terminar()
		return
	if cer != null and is_instance_valid(cer) and cer.activa:
		_fase_act = "ceremonia"
		if _n == 80:
			_fase_act = "salto_ceremonia"
			cer.terminar()
		return
	if _fase_act == "salto_ceremonia" or _fase_act == "salto_intro" or _fase_act == "montaje":
		_fase_act = "juego"
	if _n == 30:
		(_vista.get("_rig") as CameraRig).switch_to(0)
	if _n == 150:
		_fase_act = "festejo"
		FestejoGrada.lanzar(_vista.get("_raiz3d"), Color(0.8, 0.1, 0.1), Color(1, 1, 1), "salida", 600.0)
	if _n >= (130 if OS.get_environment("DOBLE") != "" else 220):
		_fin = true
		var orden: Array[int] = []
		for i in _t.size():
			orden.append(i)
		orden.sort_custom(func(a: int, b: int) -> bool: return _t[a] > _t[b])
		var s := _t.duplicate()
		s.sort()
		print("PICOS nivel=%d fotogramas=%d mediana=%.1f ms" % [Calidad.elegida, _t.size(), s[s.size() / 2]])
		for k in 12:
			print("PICO #%d fotograma %d (%s): %.1f ms" % [k + 1, orden[k], _fase[orden[k]], _t[orden[k]]])
		get_tree().quit()

func _suma() -> float:
	var x := 0.0
	for v in _t:
		x += v
	return x

func _mayores(k: int) -> Array:
	var s := _t.duplicate()
	s.sort()
	s.reverse()
	return s.slice(0, k).map(func(v: float) -> String: return "%.0f" % v)
