extends Node
## RAM POR ESCENARIO (7-11-2026, meta del dueño: -40 % de RAM con código puro, también en ALTA).
## ESCENARIO=menu|ciudad|partido  y la calidad por argumento de usuario (`-- minimo` o `-- alto`...).
##   ESCENARIO=ciudad HW_RAM_MB=12000 bash herramientas/hw_modesto.sh res://pruebas/medir_ram.tscn -- alto
## Imprime `RAM esc calidad rss_mb pico_mb estatica_mb textura_mb video_mb objetos recursos nodos` tras asentarse. Comparable entre versiones (misma máquina).
var _n := 0
var _p: Node
var _v: Node
var _esc := "menu"

static func _kb(campo: String) -> int:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)   ## (los archivos de /proc dicen tamaño 0: se lee por líneas)
	while f != null and not f.eof_reached():
		var l := f.get_line()
		if l.begins_with(campo):
			return int(l.split(":")[1].strip_edges().split(" ")[0])
	return 0

func _ready() -> void:
	_esc = OS.get_environment("ESCENARIO") if OS.get_environment("ESCENARIO") != "" else "menu"
	Calidad.elegida = Calidad.nivel_de_argumentos(Calidad.ULTRA_BAJA)
	if _esc == "partido":
		var mundo := Mundo.new()
		mundo.generar(["CHI"], 4711)
		mundo.mi_club_id = mundo.ligas[0].clubes[0].id
		var par := mundo.proximo_partido()
		_v = load("res://ui/estadio.gd").new()   ## (dinámico: nombrar la clase compilaría el estadio en TODOS los escenarios y falsearía la RAM del menú)
		add_child(_v)
		_v.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
	else:
		_p = load("res://escenas/principal.tscn").instantiate()
		add_child(_p)

func _process(_d: float) -> void:
	Engine.max_fps = 0
	_n += 1
	if _esc == "partido":
		var intro: Variant = _v.get("_intro")
		if intro != null and is_instance_valid(intro) and intro.activa:
			intro.terminar()
			return
		var cer: Variant = _v.get("_ceremonia")
		if cer != null and is_instance_valid(cer) and cer.activa:
			cer.terminar()
			return
	if _n == 5 and _esc == "ciudad":
		_p.call("_ver_ciudad_propia")
	var meta := 260 if _esc == "ciudad" else 160
	if _n == meta:
		print("RAM ", _esc, " ", Calidad.elegida, " rss=", _kb("VmRSS:") / 1024, " anon=", _kb("RssAnon:") / 1024, " archivos=", _kb("RssFile:") / 1024, " pico=", _kb("VmHWM:") / 1024,
			" estatica=", int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0),
			" textura=", int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0),
			" video=", int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0),
			" objetos=", int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			" recursos=", int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
			" nodos=", int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		var cargados: Array = []
		for r in ["res://ui/estadio.gd", "res://visor/stadium_builder.gd", "res://visor/motor_jugable.gd", "res://visor/player_spawner.gd", "res://visor/city_builder.gd", "res://ui/partido_jugable.gd", "res://visor/personaje_dt.gd"]:
			if ResourceLoader.has_cached(r):
				cargados.append(r.get_file())
		print("RAM_CARGADOS ", cargados)
		get_tree().quit()
