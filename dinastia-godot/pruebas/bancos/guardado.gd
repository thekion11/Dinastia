extends BaseIdea
## BANCO ESPECIALIZADO «guardado», FASE 2 (4-11-2026, megarreforma de los bancos): ultra detalle de guardar y cargar.
## Lo corre `herramientas/bancos_especiales.py guardado` (además de las secciones del banco y las especiales del área).
##   1. Ida y vuelta EXACTA (3 semillas × 0, 6 y 20 semanas): la instantánea tras cargar es igual campo por campo.
##   2. Cargar y seguir = seguir sin cargar (el estado del azar se guarda): 4 semanas más dan el mismo mundo.
##   3. Archivo CORRUPTO o CORTADO: no se cuelga; vuelve a la copia anterior o devuelve null.
##   4. Exportar e importar (pasar la partida a otro aparato) da el mismo mundo.
##   5. Nombres con tildes, eñes y espacios; listar() la ve con su club y semana; borrar() no deja restos.
##   6. Tamaño del archivo y tiempo de guardar dentro de su tope.

const PREFIJO := "zz_banco_gua_"
const TOPE_MB := 2.0      ## 2 países comprimidos
const TOPE_MS := 3000     ## guardar en primer plano, 2 países, sin GPU

func _probar() -> void:
	_titulo("BANCO GUARDADO (fase 2): ida y vuelta, azar, corrupción, exportar, nombres, tamaño")
	_limpiar()   ## restos de una corrida cortada
	for semilla in [101, 4242, 90001]:
		for semanas in [0, 6, 20]:
			_ida_y_vuelta(semilla, semanas)
	_cargar_y_seguir()
	_corrupcion()
	_exportar_importar()
	_nombres_y_lista()
	_limpiar()

func _mundo_n(semilla: int, semanas: int) -> Mundo:
	var m := Mundo.new()
	var paises: Array[String] = ["CHI", "ARG"]
	m.generar(paises, semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	for i in semanas:
		m.avanzar_semana()
	return m

## La instantánea sin lo que cambia legítimamente entre dos guardados (la hora del guardado).
func _foto(m: Mundo) -> String:
	var d := Partida.instantanea(m)
	d.erase("guardado")
	## Canónica: por JSON ida y vuelta (todos los números como en el archivo), así 10 y 10.0 cuentan igual.
	## Los TIPOS que cambian al cargar (entero → decimal) los vigila `_tipos_al_cargar`.
	return JSON.stringify(JSON.parse_string(JSON.stringify(d)), "\t", true)

## Primera diferencia entre dos textos JSON (para que el fallo diga DÓNDE, no solo que algo cambió).
func _diferencia(a: String, b: String) -> String:
	var la := a.split("\n")
	var lb := b.split("\n")
	for i in mini(la.size(), lb.size()):
		if la[i] != lb[i]:
			## Las claves que abren los bloques de encima (dónde está la diferencia dentro del guardado).
			var camino: Array[String] = []
			var nivel := la[i].length() - la[i].strip_edges(true, false).length()
			for k in range(i - 1, -1, -1):
				var sangria := la[k].length() - la[k].strip_edges(true, false).length()
				if sangria < nivel and la[k].contains("\":"):
					camino.push_front(la[k].strip_edges().get_slice("\"", 1))
					nivel = sangria
			return "%s · línea %d: «%s» ≠ «%s»" % ["/".join(camino), i, la[i].strip_edges().left(90), lb[i].strip_edges().left(90)]
	return "tamaños distintos (%d / %d líneas)" % [la.size(), lb.size()]

func _ida_y_vuelta(semilla: int, semanas: int) -> void:
	var m := _mundo_n(semilla, semanas)
	var antes := _foto(m)
	var nombre := PREFIJO + "%d_%d" % [semilla, semanas]
	var t0 := Time.get_ticks_msec()
	var ok := Partida.guardar(m, nombre)
	var ms := Time.get_ticks_msec() - t0
	_comprobar(ok, "semilla %d, %d semanas: se guarda" % [semilla, semanas])
	var bytes := FileAccess.get_file_as_bytes(Partida.ruta_de(nombre)).size()
	_comprobar(bytes > 1000 and bytes < TOPE_MB * 1048576.0, "  el archivo pesa %.2f MB (tope %.1f)" % [bytes / 1048576.0, TOPE_MB])
	_comprobar(ms < TOPE_MS, "  guardar tarda %d ms (tope %d, sin GPU)" % [ms, TOPE_MS])
	var c := Partida.cargar(nombre)
	_comprobar(c != null, "  se vuelve a cargar")
	if c == null:
		return
	var despues := _foto(c)
	_comprobar(antes == despues, "  la partida cargada es IDÉNTICA campo por campo%s" % ("" if antes == despues else " — " + _diferencia(antes, despues)))
	_comprobar(c.anio == m.anio and c.semana == m.semana and c.mi_club_id == m.mi_club_id, "  mismo año, semana y club (%d, %d)" % [c.anio, c.semana])
	_comprobar(c.mi_club().plantilla.size() == m.mi_club().plantilla.size(), "  mismo plantel (%d)" % c.mi_club().plantilla.size())

func _cargar_y_seguir() -> void:
	## Sin cargar NADA en medio: cargar toca estado global (azar, semana global, contadores) que el mundo original también
	## usa. Primero el original sigue 4 semanas; luego se carga la copia y sigue otras 4.
	var m := _mundo_n(777, 8)
	_comprobar(Partida.guardar(m, PREFIJO + "seguir"), "cargar y seguir: se guarda")
	for i in 4:
		m.avanzar_semana()
	var a := _foto(m)
	var c := Partida.cargar(PREFIJO + "seguir")
	_comprobar(c != null, "  se carga")
	if c == null:
		return
	for i in 4:
		c.avanzar_semana()
	var b := _foto(c)
	_comprobar(a == b, "cargar y seguir 4 semanas da EXACTAMENTE lo mismo que seguir sin cargar%s" % ("" if a == b else " — " + _diferencia(a, b)))

func _corrupcion() -> void:
	var m := _mundo_n(55, 2)
	var nombre := PREFIJO + "roto"
	Partida.guardar(m, nombre)
	m.avanzar_semana()
	Partida.guardar(m, nombre)   ## segunda vez: ya hay copia anterior rotada
	var ruta := Partida.ruta_de(nombre)
	var bueno := FileAccess.get_file_as_bytes(ruta)
	## Basura encima del archivo principal.
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string("esto no es una partida")
	f.close()
	var c := Partida.cargar(nombre)
	_comprobar(c != null, "archivo principal con basura: carga la copia anterior en vez de colgarse")
	if c != null:
		_comprobar(c.semana >= 1, "  y la copia es una partida válida (semana %d)" % c.semana)
	## Cortado a la mitad.
	f = FileAccess.open(ruta, FileAccess.WRITE)
	f.store_buffer(bueno.slice(0, bueno.size() / 2))
	f.close()
	c = Partida.cargar(nombre)
	_comprobar(c != null, "archivo cortado a la mitad: vuelve a la copia anterior")
	## Sin ninguna copia buena: null, sin colgarse.
	for suf in PartidaArchivo.sufijos():
		if FileAccess.file_exists(ruta + suf):
			var g := FileAccess.open(ruta + suf, FileAccess.WRITE)
			g.store_string("roto")
			g.close()
	c = Partida.cargar(nombre)
	_comprobar(c == null, "todas las copias rotas: cargar devuelve null (y el juego sigue)")

func _exportar_importar() -> void:
	var m := _mundo_n(2026, 5)
	var nombre := PREFIJO + "exportar"
	Partida.guardar(m, nombre)
	var antes := _foto(m)
	var destino := OS.get_user_data_dir().path_join(PREFIJO + "fuera")
	var error := PartidaExportar.exportar(nombre, destino)
	_comprobar(error == "", "exportar la partida a un archivo%s" % ("" if error == "" else ": " + error))
	var archivo := destino + String(PartidaExportar.EXTENSIONES[0])
	_comprobar(FileAccess.file_exists(archivo), "  queda el archivo exportado")
	if not FileAccess.file_exists(archivo):
		return
	var r := PartidaExportar.importar(archivo, PREFIJO + "importada")
	_comprobar(bool(r.get("ok", false)), "importar el archivo%s" % ("" if bool(r.get("ok", false)) else ": " + str(r)))
	var c := Partida.cargar(String(r.get("nombre", PREFIJO + "importada")))
	_comprobar(c != null and _foto(c) == antes, "la partida importada es idéntica a la exportada")
	DirAccess.remove_absolute(archivo)

func _nombres_y_lista() -> void:
	var m := _mundo_n(9, 3)
	var raro := PREFIJO + "Año Niño Ñandú é"
	_comprobar(Partida.guardar(m, raro), "un nombre con tildes, eñes y espacios se guarda")
	var c := Partida.cargar(raro)
	_comprobar(c != null and c.semana == m.semana, "  y se carga")
	var visto := {}
	for p: Dictionary in Partida.listar():
		if String(p.get("fichero", "")).begins_with(PREFIJO):
			visto[String(p["fichero"])] = p
	_comprobar(visto.has(raro), "listar() muestra la partida guardada%s" % ("" if visto.has(raro) else " (ve: %s)" % str(visto.keys())))
	Partida.borrar(raro)
	var restos := 0
	var ruta := Partida.ruta_de(raro)
	for suf in [""] + Array(PartidaArchivo.sufijos()):
		restos += 1 if FileAccess.file_exists(ruta + suf) else 0
	_comprobar(restos == 0, "borrar() no deja archivos ni copias (%d restos)" % restos)

func _limpiar() -> void:
	for p: Dictionary in Partida.listar():
		if String(p.get("fichero", "")).begins_with(PREFIJO):
			Partida.borrar(String(p["fichero"]))
