extends Node
## ¿CUÁNTO TARDA ABRIR EL ESTADIO CON Y SIN EL PRECALENTADO DEL MENÚ? (7-11, meta de RAM: el precalentado de caras y animaciones cuesta ~83 MB en el menú.)
## Imita el menú (tomar el mando → `PrecalentarCaras`, `PrecalentarAnim`), espera a que acaben y abre el estadio midiendo `abrir` y los fotogramas siguientes.
##   [SIN_PRECALENTAR=1] bash herramientas/hw_modesto.sh res://pruebas/medir_apertura.tscn -- minimo
var _n := 0
var _v: Node
var _mundo: Mundo
var _t_abrir := 0
var _dts: Array[float] = []
var _t_prev := 0

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ULTRA_BAJA)
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	if OS.get_environment("SIN_PRECALENTAR") == "" and PrecalentarAnim.permitido():
		_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)   ## (lo que hace el menú: pone en cola los onces)
		PrecalentarAnim.lanzar()
	else:
		_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id

func _process(_d: float) -> void:
	Engine.max_fps = 0
	_n += 1
	if _n < 700:
		return   ## el menú ya terminó de precalentar
	if _n == 700:
		print("APERTURA estatica_antes=", int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
		var par := _mundo.proximo_partido()
		var t0 := Time.get_ticks_usec()
		_v = load("res://ui/estadio.gd").new()
		add_child(_v)
		_v.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
		_t_abrir = Time.get_ticks_usec() - t0
		_t_prev = Time.get_ticks_usec()
		return
	var ahora := Time.get_ticks_usec()
	_dts.append((ahora - _t_prev) / 1000.0)
	_t_prev = ahora
	var intro: Variant = _v.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
	if _dts.size() >= 60:
		var suma := 0.0
		var mx := 0.0
		for x in _dts:
			suma += x
			mx = maxf(mx, x)
		print("APERTURA abrir_ms=%.0f suma_60_fotogramas_ms=%.0f peor_fotograma_ms=%.0f estatica_despues=%d" % [_t_abrir / 1000.0, suma, mx, int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)])
		get_tree().quit()
