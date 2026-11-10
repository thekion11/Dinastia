extends Node
## CUÁNTO CUESTA EL MUNDO ENTERO FRENTE A UN MUNDO PARCIAL (10-11-2026, encargo del dueño para la pantalla «Ligas activas»): un proceso por configuración (la memoria sale limpia). Mide generar,
## una semana, una temporada, el tamaño de la partida guardada y el tiempo de guardarla y cargarla, y la RAM (estática del motor y RSS del proceso, de /proc). Herramienta, no prueba del banco.
##   CONFIG=1|5|15|TODOS  godot --headless --path . res://pruebas/zz_coste_mundo.tscn      (SEMANAS=5: semanas sueltas que se promedian)
## Los países: «1» = CHI, «5»/«15» = los N países con más clubes (CHI siempre incluido).

func _rss_mb() -> float:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)   ## procfs declara longitud 0: se lee línea a línea, no de golpe
	if f == null:
		return -1.0
	while not f.eof_reached():
		var l := f.get_line()
		if l.begins_with("VmRSS:"):
			return float(l.split(" ", false)[1]) / 1024.0
	return -1.0

func _est_mb() -> float:
	return Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0

func _top(n: int) -> Array[String]:
	var pl: Dictionary = Datos.tabla("PAISES_LIGAS")
	var cuenta: Array = []
	for p: String in pl:
		var d: Dictionary = pl[p]
		cuenta.append([p, (d.get("clubes", []) as Array).size()])
	cuenta.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]) > int(b[1]))
	var r: Array[String] = ["CHI"]
	for c: Array in cuenta:
		if r.size() >= n:
			break
		if not r.has(String(c[0])):
			r.append(String(c[0]))
	return r

func _ready() -> void:
	var cfg := OS.get_environment("CONFIG") if OS.get_environment("CONFIG") != "" else "1"
	var paises: Array[String] = []
	match cfg:
		"1": paises = ["CHI"]
		"TODOS": paises = []
		_: paises = _top(int(cfg))
	var semanas := int(OS.get_environment("SEMANAS")) if OS.get_environment("SEMANAS") != "" else 5
	var r0 := _rss_mb()
	var m := Mundo.new()
	var t := Time.get_ticks_usec()
	m.generar(paises, 4711)
	var t_gen := (Time.get_ticks_usec() - t) / 1000.0
	var n_jug := 0
	for c: Club in m.clubes.values():
		n_jug += c.plantilla.size()
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var r_gen := _rss_mb(); var e_gen := _est_mb()
	var suma := 0.0
	for i in semanas:
		t = Time.get_ticks_usec()
		m.avanzar_semana()
		suma += (Time.get_ticks_usec() - t) / 1000.0
	t = Time.get_ticks_usec()
	m.jugar_temporada()   ## (lo que queda de la temporada, como en el banco)
	var t_temp := (Time.get_ticks_usec() - t) / 1000.0
	t = Time.get_ticks_usec()
	m.nueva_temporada()   ## el cierre: ascensos, premios, envejecer, selecciones
	var t_cierre := (Time.get_ticks_usec() - t) / 1000.0
	var r_temp := _rss_mb(); var e_temp := _est_mb()
	var datos := Partida.instantanea(m)
	var crudo := JSON.stringify(datos, "", false, true).to_utf8_buffer()
	Partida.guardar(m, "zz_coste")
	var ms_g := PartidaArchivo.ms_guardado
	var tam := 0
	var f := FileAccess.open(Partida.ruta_de("zz_coste"), FileAccess.READ)
	if f != null:
		tam = f.get_length()
	var m2 := Partida.cargar("zz_coste")
	var ms_c := PartidaArchivo.ms_carga
	var r_car := _rss_mb()
	Partida.borrar("zz_coste")
	print("COSTE_MUNDO config=%s paises=%d clubes=%d jugadores=%d | generar=%.0f ms | semana=%.0f ms (media de %d) | resto_de_temporada=%.0f ms + cierre=%.0f ms | guardar=%d ms cargar=%d ms | archivo=%.2f MB (JSON %.1f MB) | RSS: inicio=%.0f generado=%.0f tras_temporada=%.0f tras_cargar=%.0f MB | estática: generado=%.0f tras_temporada=%.0f MB" % [
		cfg, paises.size() if not paises.is_empty() else (Datos.tabla("PAISES_LIGAS") as Dictionary).size() + 0, m.clubes.size(), n_jug, t_gen, suma / semanas, semanas, t_temp, t_cierre,
		ms_g, ms_c, float(tam) / 1048576.0, float(crudo.size()) / 1048576.0, r0, r_gen, r_temp, r_car, e_gen, e_temp])
	m2 = null
	get_tree().quit()
