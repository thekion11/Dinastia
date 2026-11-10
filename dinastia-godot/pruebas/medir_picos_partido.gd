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

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ALTO)
	var mundo := Mundo.new()
	var pais := OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	mundo.generar([pais], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[int(OS.get_environment("CLUB")) % mundo.ligas[0].clubes.size()].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_t_ant = Time.get_ticks_usec()
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _process(_d: float) -> void:
	if _fin:
		return
	var ahora := Time.get_ticks_usec()
	_t.append(float(ahora - _t_ant) / 1000.0)
	_fase.append(_fase_act)
	_t_ant = ahora
	_n += 1
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
	if _n >= 220:
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
