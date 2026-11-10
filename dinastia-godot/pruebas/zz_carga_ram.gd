extends Node
## DÓNDE SE VA LA RAM AL CARGAR UNA PARTIDA (10-11-2026, pico de 1,83 GB con el mundo entero): RSS y memoria estática (pico incluido) tras cada etapa de `Partida.cargar`, con el mundo viejo vivo o ya liberado.
##   CONFIG=TODOS|5  VIEJO=1 (el mundo de antes sigue vivo mientras se carga) | 0 (se suelta antes)  godot --headless --path . res://pruebas/zz_carga_ram.tscn
func _rss() -> float:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	while f != null and not f.eof_reached():
		var l := f.get_line()
		if l.begins_with("VmRSS:"):
			return float(l.split(" ", false)[1]) / 1024.0
	return -1.0

func _hwm() -> float:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	while f != null and not f.eof_reached():
		var l := f.get_line()
		if l.begins_with("VmHWM:"):
			return float(l.split(" ", false)[1]) / 1024.0
	return -1.0

func _est() -> float:
	return float(OS.get_static_memory_usage()) / 1048576.0

func _pico() -> float:
	return float(OS.get_static_memory_peak_usage()) / 1048576.0

func _p(etapa: String) -> void:
	print("CARGA_RAM %-34s RSS=%5.0f MB  estática=%5.0f MB  pico_estática=%5.0f MB  VmHWM=%5.0f MB" % [etapa, _rss(), _est(), _pico(), _hwm()])

func _ready() -> void:
	var cfg := OS.get_environment("CONFIG") if OS.get_environment("CONFIG") != "" else "TODOS"
	var viejo := OS.get_environment("VIEJO") != "0"
	var paises: Array[String] = []
	if cfg != "TODOS":
		paises = ["CHI", "ARG", "USA", "EGY", "BRA"]
	var m := Mundo.new()
	m.generar(paises, 4711)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	Partida.guardar(m, "zz_carga")
	_p("mundo generado y guardado")
	if not viejo:
		m = null
		_p("mundo viejo soltado")
	var ruta := Partida.ruta_de("zz_carga")
	var b := FileAccess.get_file_as_bytes(ruta)
	_p("bytes del archivo (%.1f MB)" % (b.size() / 1048576.0))
	var crudo := PartidaArchivo.desempaquetar(b)
	_p("JSON descomprimido (%.1f MB)" % (crudo.size() / 1048576.0))
	var txt := crudo.get_string_from_utf8()
	_p("JSON como String")
	var j := JSON.new()
	j.parse(txt)
	_p("JSON parseado a Dictionary")
	txt = ""
	crudo = PackedByteArray()
	b = PackedByteArray()
	_p("texto y bytes soltados")
	var d: Dictionary = j.data
	var m2 := Partida.desde_instantanea(d)
	_p("mundo construido (desde_instantanea)")
	d = {}
	j = null
	_p("Dictionary soltado")
	print("CARGA_RAM jugadores=%d" % m2.clubes.size())
	Partida.borrar("zz_carga")
	get_tree().quit()
