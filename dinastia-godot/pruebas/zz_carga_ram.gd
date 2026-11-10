extends Node
## EL PICO DE RAM AL CARGAR UNA PARTIDA (10-11-2026): genera un mundo, lo guarda, lo SUELTA o no (como hace la interfaz al cargar otra partida) y mide el pico (memoria estática y VmHWM) de `Partida.cargar`.
## Después guarda lo cargado en otra ranura y compara las dos (el mismo mundo).
##   CONFIG=TODOS|5  SOLTAR=0 (el mundo de antes sigue vivo durante la carga) | 1 (`soltar_antes`, lo nuevo)  godot --headless --path . res://pruebas/zz_carga_ram.tscn
func _estado(etapa: String) -> void:
	var rss := 0.0
	var hwm := 0.0
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	while f != null and not f.eof_reached():
		var l := f.get_line()
		if l.begins_with("VmRSS:"):
			rss = float(l.split(" ", false)[1]) / 1024.0
		elif l.begins_with("VmHWM:"):
			hwm = float(l.split(" ", false)[1]) / 1024.0
	print("CARGA_RAM %-28s RSS=%5.0f MB  estática=%5.0f MB  pico_estática=%5.0f MB  VmHWM=%5.0f MB" % [etapa, rss, float(OS.get_static_memory_usage()) / 1048576.0, float(OS.get_static_memory_peak_usage()) / 1048576.0, hwm])

func _md5_de(nombre: String) -> String:
	var crudo := PartidaArchivo.desempaquetar(FileAccess.get_file_as_bytes(Partida.ruta_de(nombre)))
	return crudo.get_string_from_utf8().md5_text()

func _ready() -> void:
	var cfg := OS.get_environment("CONFIG") if OS.get_environment("CONFIG") != "" else "TODOS"
	var soltar := OS.get_environment("SOLTAR") == "1"
	var paises: Array[String] = []
	if cfg != "TODOS":
		paises = ["CHI", "ARG", "USA", "EGY", "BRA"]
	var m := Mundo.new()
	m.generar(paises, 4711)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	for i in 3:
		m.avanzar_semana()
	Partida.guardar(m, "zz_carga")
	var tenedor: Array = [m]   ## (una lambda captura por valor: se suelta vaciando un Array compartido)
	m = null
	_estado("antes de cargar")
	var m2 := Partida.cargar("zz_carga", func() -> void: tenedor.clear()) if soltar else Partida.cargar("zz_carga")
	_estado("DESPUÉS DE CARGAR (soltar=%s)" % str(soltar))
	tenedor.clear()
	Partida.guardar(m2, "zz_carga2")
	var igual := _md5_de("zz_carga") == _md5_de("zz_carga2")
	print("CARGA_RAM el mundo cargado es el mismo que el guardado: %s (clubes=%d)" % [str(igual), m2.clubes.size()])
	Partida.borrar("zz_carga")
	Partida.borrar("zz_carga2")
	get_tree().quit()
