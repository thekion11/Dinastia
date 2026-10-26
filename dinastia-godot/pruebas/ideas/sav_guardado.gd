extends BaseIdea
## GUARDADO ROBUSTO (paquete sav, 25-10-2026): copias rotativas, huella, escritura
## atómica, versiones viejas, ida y vuelta idéntica, mascota del club y tiempos.

const N := "__sav_prueba__"

func _probar() -> void:
	_titulo("GUARDADO ROBUSTO (sav)")
	var m := _mundo(4040)
	var ruta := Partida.ruta_de(N)
	Partida.borrar(N)
	_rotacion(m, ruta)
	_huella(m, ruta)
	_cortes(m, ruta)
	_versiones(m, ruta)
	_ida_y_vuelta(m)
	Partida.borrar(N)
	var queda := false
	for suf: String in PartidaArchivo.sufijos():
		queda = queda or FileAccess.file_exists(ruta + suf)
	_comprobar(not queda, "borrar quita principal, temporal y las tres copias")

func _semana_en(ruta: String) -> int:
	return int(Partida._leer_todo(ruta).get("semana", -1))

func _rotacion(m: Mundo, ruta: String) -> void:
	var s0 := m.semana
	var todos := true
	for i in 5:
		m.semana = s0 + i
		todos = Partida.guardar(m, N) and todos
	_comprobar(todos, "cinco guardados seguidos")
	_comprobar(_semana_en(ruta) == s0 + 4, "el principal es el último guardado")
	_comprobar(_semana_en(ruta + ".bak") == s0 + 3 and _semana_en(ruta + ".bak2") == s0 + 2
		and _semana_en(ruta + ".bak3") == s0 + 1, "tres copias rotativas, de la más nueva a la más vieja")
	_comprobar(not FileAccess.file_exists(ruta + ".bak4") and not FileAccess.file_exists(ruta + PartidaArchivo.TEMPORAL),
		"no hay cuarta copia ni temporal sobrante")
	## Principal y dos copias rotas: sale la tercera.
	for suf in ["", ".bak", ".bak2"]:
		_escribir(ruta + suf, "basura".to_utf8_buffer())
	var m2 := Partida.cargar(N)
	_comprobar(m2 != null and m2.semana == s0 + 1 and Partida.cargada_de_respaldo,
		"principal y dos copias rotas: se recupera la tercera (semana %d)" % (m2.semana if m2 != null else -1))
	m.semana = s0
	Partida.cargada_de_respaldo = false

## Un solo carácter cambiado DENTRO del JSON, recomprimido bien: deflate y JSON
## lo aceptarían; la huella no.
func _huella(m: Mundo, ruta: String) -> void:
	Partida.borrar(N)
	Partida.guardar(m, N)
	m.semana += 1
	Partida.guardar(m, N)
	m.semana -= 1
	var b := FileAccess.get_file_as_bytes(ruta)
	var crudo := PartidaArchivo.desempaquetar(b)
	_comprobar(not crudo.is_empty() and b.slice(0, 4).get_string_from_ascii() == "DIN2", "el archivo lleva firma DIN2 y se abre")
	var texto := crudo.get_string_from_utf8()
	var malo := texto.replace("\"semana\":%d" % (m.semana + 1), "\"semana\":%d" % (m.semana + 7)).to_utf8_buffer()
	_comprobar(malo != crudo and malo.size() == crudo.size(), "se cambió un número dentro del JSON")
	var falso := b.slice(0, 24)
	falso.append_array(malo.compress(FileAccess.COMPRESSION_DEFLATE))
	_escribir(ruta, falso)
	var m2 := Partida.cargar(N)
	_comprobar(m2 != null and m2.semana == m.semana and Partida.cargada_de_respaldo,
		"un JSON alterado pero válido se detecta por la huella y carga la copia")
	Partida.cargada_de_respaldo = false

## Cortes: temporal a medias junto a un principal sano; guardado que no puede escribirse.
func _cortes(m: Mundo, ruta: String) -> void:
	Partida.borrar(N)
	Partida.guardar(m, N)
	var b := FileAccess.get_file_as_bytes(ruta)
	_escribir(ruta + PartidaArchivo.TEMPORAL, b.slice(0, b.size() / 2))
	var m2 := Partida.cargar(N)
	_comprobar(m2 != null and not Partida.cargada_de_respaldo, "corte a mitad del temporal: el principal sano manda")
	_comprobar(Partida.guardar(m, N) and not FileAccess.file_exists(ruta + PartidaArchivo.TEMPORAL),
		"el siguiente guardado pisa el temporal roto y lo retira")
	## Cortado a mitad sin ninguna copia: no revienta, devuelve null.
	Partida.borrar(N)
	Partida.guardar(m, N)
	_escribir(ruta, b.slice(0, b.size() / 2))
	_comprobar(Partida.cargar(N) == null, "cortado a medias y sin copias: null, sin reventar")
	Partida.cargada_de_respaldo = false

func _versiones(m: Mundo, ruta: String) -> void:
	## Formato de la versión 1: tamaño + deflate, sin firma ni huella, «version»: 1.
	var d := Partida.instantanea(m)
	d["version"] = 1
	var crudo := JSON.stringify(d).to_utf8_buffer()
	var viejo := PackedByteArray()
	viejo.resize(4)
	viejo.encode_u32(0, crudo.size())
	viejo.append_array(crudo.compress(FileAccess.COMPRESSION_DEFLATE))
	Partida.borrar(N)
	_escribir(ruta, viejo)
	var m2 := Partida.cargar(N)
	_comprobar(m2 != null and m2.semana == m.semana and m2.mi_club_id == m.mi_club_id, "un guardado de la versión 1 (formato viejo) carga")
	_comprobar(int(PartidaArchivo.migrar({"version": 1}, Partida.VERSION).get("version", 0)) == Partida.VERSION
		and PartidaArchivo.migrar({}, Partida.VERSION).has("guardado"), "la migración lleva v0 y v1 a la versión actual")
	_comprobar(int(d["version"]) == 1, "migrar no toca el diccionario original")
	d["version"] = Partida.VERSION + 1
	_comprobar(Partida.desde_instantanea(d) == null, "un guardado de una versión más nueva se rechaza")
	## Tiempos y tamaño a la vista.
	Partida.guardar(m, N)
	Partida.cargar(N)
	_linea("  · guardado %d ms (%d KB) · carga %d ms" % [PartidaArchivo.ms_guardado, PartidaArchivo.bytes_guardado / 1024, PartidaArchivo.ms_carga])
	_comprobar(PartidaArchivo.ms_guardado > 0 and PartidaArchivo.ms_carga > 0 and PartidaArchivo.bytes_guardado > 1000,
		"se miden los tiempos de guardado y carga")

## Ida y vuelta: retrato → mundo → retrato da lo mismo (salvo la hora del guardado).
func _ida_y_vuelta(m: Mundo) -> void:
	m.mi_club().mascota = "aguila"
	## Primera vuelta: un sistema puede rellenar campos por defecto al cargar
	## (Cantera añade «propio»: false a cada leyenda), así que se compara la
	## SEGUNDA vuelta con la primera: a partir de ahí no puede cambiar nada.
	var a := Partida.instantanea(Partida.desde_instantanea(Partida.instantanea(m)))
	var b := Partida.instantanea(Partida.desde_instantanea(a))
	a.erase("guardado")
	b.erase("guardado")
	var distintas: Array[String] = []
	for k: String in a:
		if JSON.stringify(a[k]) != JSON.stringify(b.get(k)):
			distintas.append(k)
	_comprobar(distintas.is_empty() and a.size() == b.size(), "ida y vuelta estable (claves distintas: %s)" % ", ".join(distintas))
	var rec := Partida.desde_instantanea(Partida.instantanea(m))
	_comprobar(rec.mi_club().mascota == "aguila" and EstadioExtras.animal_de(rec.mi_club()) == "aguila",
		"la mascota elegida se guarda y la usa el estadio")
	var otro: Club = m.ligas[0].clubes[1]
	_comprobar(otro.mascota == "" and MascotaQ.ANIMALES.has(EstadioExtras.animal_de(otro)), "sin elegir, sigue la mascota de siempre")

func _escribir(ruta: String, b: PackedByteArray) -> void:
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_buffer(b)
	f.close()
