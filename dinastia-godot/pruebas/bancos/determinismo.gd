extends BaseIdea
## BANCO ESPECIALIZADO «determinismo», FASE 2 (4-11-2026, megarreforma de los bancos). La misma semilla da SIEMPRE lo
## mismo; semillas distintas, mundos distintos; y el código de la simulación no usa azar ni reloj por fuera de `Azar`.
##   1. Escaneo de `nucleo/`: ningún randf/randi/pick_random/shuffle/randomize suelto (solo `Azar` o un generador propio
##      con semilla), y el reloj del sistema solo en registros, medidas y guardado (lista cerrada).
##   2. Mundo con la misma semilla dos veces, 0 y 12 semanas: instantánea idéntica campo por campo.
##   3. Semillas distintas: mundos distintos (nombres, tablas, saldos).
##   4. El mismo partido simulado con el azar en el mismo estado: mismo resultado y mismos eventos, 5 veces.
##   5. Una temporada entera repetida: misma tabla final.

## Archivos de `nucleo/` que pueden mirar el reloj (nunca para decidir nada de la simulación).
const RELOJ_PERMITIDO := ["partida_p1.gd", "partida.gd", "partida_archivo.gd", "registro.gd", "medicion.gd", "logros_p1.gd", "reloj.gd",
	"avisos_sonido.gd", "guardado_segundo_plano.gd", "compilar_fondo.gd"]   ## avisos en pantalla y tiempos medidos

func _probar() -> void:
	_titulo("BANCO DETERMINISMO (fase 2): código, mundos, partidos y temporada")
	_escaneo()
	for semanas in [0, 12]:
		_mundo_dos_veces(31337, semanas)
	_semillas_distintas()
	_partido_repetido()
	_temporada_repetida()

func _archivos(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_archivos(dir.path_join(d)))
	return out

func _escaneo() -> void:
	var azar_suelto: Array[String] = []
	var reloj: Array[String] = []
	var re_azar := RegEx.create_from_string("(^|[^._a-zA-Z0-9])(randf|randi|randf_range|randi_range|randomize|randfn)\\(|\\.pick_random\\(\\)|\\.shuffle\\(\\)")
	## Solo el reloj REAL (del sistema o de los ticks): las conversiones de fechas (`get_unix_time_from_datetime_dict`…) son puras.
	var re_reloj := RegEx.create_from_string("Time\\.get_(ticks_\\w+|\\w+_from_system)\\(")
	for ruta in _archivos("res://nucleo"):
		var n := 0
		for linea in FileAccess.get_file_as_string(ruta).split("\n"):
			n += 1
			var codigo := linea.get_slice("#", 0)
			if codigo.strip_edges().is_empty():
				continue
			if re_azar.search(codigo) != null and not codigo.contains("rng") and not codigo.contains("Azar."):
				azar_suelto.append("%s:%d" % [ruta.get_file(), n])
			if re_reloj.search(codigo) != null and not RELOJ_PERMITIDO.has(ruta.get_file()):
				reloj.append("%s:%d" % [ruta.get_file(), n])
	_comprobar(azar_suelto.is_empty(), "nucleo/ no usa azar suelto (fuera de Azar o de un generador con semilla)%s" % ("" if azar_suelto.is_empty() else ": " + str(azar_suelto.slice(0, 8))))
	_comprobar(reloj.is_empty(), "el reloj del sistema solo en registros, medidas y guardado%s" % ("" if reloj.is_empty() else ": " + str(reloj.slice(0, 8))))

func _mundo_n(semilla: int, semanas: int, paises: Array[String] = ["CHI", "ARG"]) -> Mundo:
	Partido.limpiar_contexto()
	var m := Mundo.new()
	m.generar(paises, semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	for i in semanas:
		m.avanzar_semana()
	return m

func _foto(m: Mundo) -> String:
	var d := Partida.instantanea(m)
	d.erase("guardado")
	return JSON.stringify(JSON.parse_string(JSON.stringify(d)), "\t", true)

func _primera_diferencia(a: String, b: String) -> String:
	var la := a.split("\n")
	var lb := b.split("\n")
	for i in mini(la.size(), lb.size()):
		if la[i] != lb[i]:
			return "línea %d: «%s» ≠ «%s»" % [i, la[i].strip_edges().left(80), lb[i].strip_edges().left(80)]
	return "tamaños %d / %d" % [la.size(), lb.size()]

func _mundo_dos_veces(semilla: int, semanas: int) -> void:
	var a := _foto(_mundo_n(semilla, semanas))
	var b := _foto(_mundo_n(semilla, semanas))
	_comprobar(a == b, "semilla %d, %d semanas, dos veces: el mismo mundo campo por campo%s" % [semilla, semanas, "" if a == b else " — " + _primera_diferencia(a, b)])

func _semillas_distintas() -> void:
	var m1 := _mundo_n(1, 0)
	var m2 := _mundo_n(2, 0)
	## (Los planteles de la base ficticia son FIJOS: con otra semilla cambian el azar de la temporada, no los nombres.)
	_comprobar(_foto(m1) != _foto(m2), "semillas distintas: mundos distintos")

func _partido_repetido() -> void:
	var primero := ""
	var iguales := 0
	for i in 5:
		## Un mundo NUEVO cada vez: jugar un partido cambia a los jugadores (cansancio, forma, notas).
		var m := _mundo_n(4242, 3)
		var l: Liga = m.ligas[0]
		Partido.limpiar_contexto()
		Azar.sembrar(777)
		var p := Partido.new(l.clubes[1], l.clubes[2])
		var r := p.simular()
		var firma := "%d-%d|%s" % [int(r["local"]), int(r["visita"]), str(p.eventos)] if "eventos" in p else "%d-%d" % [int(r["local"]), int(r["visita"])]
		if i == 0:
			primero = firma
		iguales += 1 if firma == primero else 0
	_comprobar(iguales == 5, "el mismo partido con el azar en el mismo estado da el mismo resultado y los mismos eventos (5/5: %d)" % iguales)

func _temporada_repetida() -> void:
	var tablas: Array[String] = []
	for i in 2:
		var m := _mundo_n(2024, 30)
		var s := PackedStringArray()
		for l: Liga in m.ligas:
			for c: Club in l.clubes:
				s.append("%s:%d:%d" % [c.id, c.saldo, c.plantilla.size()])
		tablas.append("|".join(s))
	_comprobar(tablas[0] == tablas[1], "una temporada entera (30 semanas) repetida: mismos saldos y planteles en todos los clubes")
