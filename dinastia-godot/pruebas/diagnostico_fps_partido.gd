extends Node
## Mide FPS real (con ventana, no headless) del partido 3D en vivo, con las
## mismas condiciones con las que lo ve un jugador: VistaEstadio + partido en
## marcha, cámara por defecto, 22 jugadores + árbitros. Calidad.elegida decide
## el nivel grafico -se puede forzar desde la linea de ordenes con -- alto /
## -- medio / -- ultra igual que hace el resto del juego-.
##
## Ejecutar con ventana real (--headless no sirve para medir fotogramas de
## verdad, el renderer dummy no hace el trabajo de la GPU):
##   godot --path dinastia-godot --rendering-driver opengl3 res://pruebas/diagnostico_fps_partido.tscn

const SEGUNDOS := 8

var _vista: VistaEstadio
var _t_inicio := 0
var _ultima_muestra := 0
var _muestras: Array = []

func _ready() -> void:
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ALTO)
	print("=== DIAGNOSTICO FPS: PARTIDO 3D EN VIVO (calidad=%d, 0=MEDIO 1=ALTO 2=ULTRA) ===" % Calidad.elegida)
	var mundo := Mundo.new()
	mundo.generar(["CHI"], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[0].id
	var par := mundo.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)
	_t_inicio = Time.get_ticks_msec()
	_ultima_muestra = _t_inicio

func _process(_delta: float) -> void:
	var ahora := Time.get_ticks_msec()
	if ahora - _ultima_muestra >= 1000:
		_ultima_muestra = ahora
		var fps := Engine.get_frames_per_second()
		_muestras.append(fps)
		print("  segundo %d: %.1f fps" % [_muestras.size(), fps])
	if ahora - _t_inicio >= SEGUNDOS * 1000:
		var suma := 0.0
		var minimo := 9999.0
		for f in _muestras:
			suma += f
			minimo = minf(minimo, float(f))
		var prom := suma / maxf(1.0, float(_muestras.size()))
		print("=== PROMEDIO: %.1f fps   MINIMO: %.1f fps   (calidad=%d) ===" % [prom, minimo, Calidad.elegida])
		get_tree().quit()
