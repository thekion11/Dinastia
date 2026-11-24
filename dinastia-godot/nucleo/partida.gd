class_name Partida
extends "res://nucleo/partida_p2.gd"
## [Capa 2/2 de `partida.gd`] _dic_a_club, _dic_a_liga, _dic_a_copa, _restaurar_lo_tuyo, desde_instantanea, cargar … (+2)

static func _dic_a_club(d: Dictionary) -> Club:
	var c := Club.new(String(d["id"]), String(d["nombre"]))
	c.pais = String(d["pais"])
	c.fichajes_cupo = d.get("fcupo", {})
	c.ley_politica = String(d.get("lpol", "cumplir"))
	c.rep = int(d["rep"])
	c.saldo = int(d["saldo"])
	c.estadio_aforo = int(d["aforo"])
	c.estadio_nombre = String(d.get("est_nombre", ""))
	c.color1 = String(d.get("c1", c.color1))
	c.color2 = String(d.get("c2", c.color2))
	c.identidad_desde_dic(d.get("ident", {}))
	c.division = int(d.get("division", 1))
	c.precio_entrada = float(d.get("precio", 6.0))
	c.confianza = int(d.get("confianza", 50))
	c.socios = int(d.get("socios", 0))
	c.tactica.propias = (d.get("fprop", {}) as Dictionary).duplicate(true)   ## formaciones propias (10-11)
	FormacionPropia.registrar_todas(c.tactica)
	c.tactica.formacion = String(d.get("formacion", "4-3-3"))
	c.tactica.mentalidad = int(d.get("ment", Tactica.Mentalidad.EQUILIBRADA))
	c.tactica.presion = int(d.get("pres", Tactica.Nivel.MEDIO))
	c.tactica.ritmo = int(d.get("ritmo", Tactica.Nivel.MEDIO))
	c.tactica.linea = int(d.get("linea", Tactica.Nivel.MEDIO))
	c.tactica.amplitud = int(d.get("ampl", Tactica.Nivel.MEDIO))
	c.tactica.salida_corta = bool(d.get("corta", false))
	c.tactica.corner = String(d.get("corner", "area"))
	c.tactica.libre = String(d.get("libre", "directo"))
	c.tactica.plan_perdiendo = String(d.get("plan_p", "nada"))
	c.tactica.plan_ganando = String(d.get("plan_g", "nada"))
	## Guardados de antes del 25-10: sin racha, empieza de cero.
	c.tactica.racha_plan_clave = String(d.get("plan_rc", ""))
	c.tactica.racha_plan_n = int(d.get("plan_rn", 0))
	## Guardados de antes del 26-10: con y sin balón en lo normal, sin roles.
	c.tactica.verticalidad = int(d.get("vert", Tactica.Nivel.MEDIO))
	c.tactica.tras_perdida = int(d.get("trasp", Tactica.Nivel.MEDIO))
	c.tactica.roles = (d.get("roles_t", {}) as Dictionary).duplicate()
	c.tactica.plan_fijo = String(d.get("plan_fijo", ""))
	c.tactica.marca_al_hombre = bool(d.get("hombre", false))
	c.tactica.fuera_de_juego = bool(d.get("fjuego", false))
	c.tactica.tiro_lejano = bool(d.get("lejano", false))
	if d.has("estilo"):
		c.set_meta("estilo", String(d["estilo"]))
	else:   ## (10-11) partida de antes de los estilos: los clubes que seguían con la táctica de fábrica recuperan la suya (la que tocaste, se respeta)
		EstiloClub.aplicar_si_de_fabrica(c)
	c.mascota = String(d.get("masc", ""))
	c.once_elegido.clear()
	for id_j in d.get("once", []):
		c.once_elegido.append(String(id_j))
	for dj: Dictionary in d["jugadores"]:
		c.plantilla.append(_dic_a_jugador(dj))
	return c

## El calendario NO se guarda: se vuelve a armar con `preparar()`, que es
## determinista a partir del orden de los clubes. Guardarlo serían 480 pares por
## liga para nada, y encima habría que resolver las referencias a mano.
static func _dic_a_liga(d: Dictionary, m: Mundo) -> Liga:
	var l := Liga.new(String(d["nombre"]), String(d["pais"]), int(d.get("div", 1)))
	for id: String in d["clubes"]:
		var c: Club = m.clubes.get(id)
		if c != null:
			l.clubes.append(c)
	l.preparar()
	l.jornada_actual = int(d["jornada"])
	## La tabla se pisa DESPUÉS de preparar(), porque preparar() la deja a cero.
	for id: String in d["tabla"]:
		if l.tabla_puntos.has(id):
			var fila: Dictionary = d["tabla"][id]
			for k: String in fila:
				l.tabla_puntos[id][k] = int(fila[k])
	for k2: String in d.get("h2h", {}):
		l.h2h[k2] = int(d["h2h"][k2])
	if l.formato != null and not (d.get("ff", {}) as Dictionary).is_empty():
		l.formato.cargar(l, d["ff"])
	l.plazas_descenso = int(d.get("desc", 2))
	l.puntos_victoria = int(d.get("pv", 3))
	return l

static func _dic_a_copa(d: Dictionary, m: Mundo) -> Copa:
	if d.is_empty():
		return null
	var c := Copa.new(String(d.get("nombre", "Copa")))
	for id: String in d.get("inscritos", []):
		var k: Club = m.clubes.get(id)
		if k != null:
			c.participantes.append(k)
	for id: String in d.get("vivos", []):
		var k: Club = m.clubes.get(id)
		if k != null:
			c.vivos.append(k)
	c.ronda = int(d.get("ronda", 0))
	c.campeon = m.clubes.get(String(d.get("campeon", "")))
	c.peso_premio = float(d.get("peso_premio", 1.0))   ## (16-11, informe G-05) la copa secundaria cobraba el premio entero tras cargar
	c.historial_desde_ids(d.get("historial", []), m.clubes)
	return c

## Reconstruye un Mundo desde el retrato. Lo usan la carga de disco y el
## deshacer, que son la misma operacion con distinto origen.
## Sin estas claves no se puede reconstruir un mundo (ver `desde_instantanea`). «azar» NO está: es opcional (los guardados viejos, como `pruebas/partidas_viejas/v2_2026-10-27`, no lo traen).
const CLAVES_IMPRESCINDIBLES := ["semilla", "anio", "semana", "clubes", "ligas", "mi_club"]

## Las comprobaciones baratas de `desde_instantanea` (versión, claves y forma) sin construir nada: ¿vale la pena soltar el mundo de antes?
static func _instantanea_buena(datos: Dictionary) -> bool:
	if datos.is_empty() or int(datos.get("version", 0)) > VERSION:
		return false
	var d := PartidaArchivo.migrar(datos.duplicate(), VERSION)
	for clave: String in CLAVES_IMPRESCINDIBLES:
		if not d.has(clave):
			return false
	return d["clubes"] is Array and d["ligas"] is Array and d["mi_club"] is String

static func desde_instantanea(datos: Dictionary) -> Mundo:
	if datos.is_empty():
		return null
	if int(datos.get("version", 0)) > VERSION:
		push_error("Partida: el guardado es de una versión más nueva (%d) que el juego (%d)" % [
			int(datos["version"]), VERSION])
		return null
	## Un guardado viejo se pone al día paso a paso antes de leerlo (M-399).
	## Se migra una copia: el diccionario de entrada (p. ej. el de deshacer) no se toca.
	datos = PartidaArchivo.migrar(datos.duplicate(), VERSION)
	## (5-11, banco de errores) Un guardado sin lo imprescindible (mal importado, hecho a mano o de otra herramienta) no es una partida:
	## antes reventaba el intérprete a medias y dejaba un mundo sin construir. Ahora se rechaza entero, como uno de versión nueva.
	for clave: String in CLAVES_IMPRESCINDIBLES:
		if not datos.has(clave):
			push_error("Partida: al guardado le falta «%s»; no se carga" % clave)
			return null
	if not (datos["clubes"] is Array and datos["ligas"] is Array and datos["mi_club"] is String):
		push_error("Partida: «clubes», «ligas» o «mi_club» del guardado no tienen la forma esperada; no se carga")
		return null

	## Un guardado anterior a la base ficticia (sin la clave) se jugó siempre
	## con los datos reales. Si esta instalación no tiene el pack, se queda en
	## la ficticia: los nombres del propio guardado se ven igual, solo se
	## pierden las equipaciones reales.
	Datos.usar_base_real(bool(datos.get("base_real", true)))

	var m := Mundo.new()
	## Se siembra con la semilla guardada para que lo que pase a partir de aquí
	## siga la misma línea que seguía la partida. Sin esto, cargar y seguir
	## jugando daba un futuro distinto cada vez que se cargaba.
	m.semilla = Azar.sembrar(int(datos["semilla"]))
	m.mercado = Mercado.new(m)
	m.roles = Roles.new(m)
	## `Cesiones` es del MUNDO, no solo de tu club -un préstamo puede ser entre
	## dos clubes de la IA-, así que se crea aquí como mercado y roles, y no
	## dentro de `_restaurar_lo_tuyo()`. Sin esto ni siquiera existía: cada carga
	## empezaba con las cesiones y las cláusulas en blanco, calladamente, porque
	## todo lo que lo usa ya comprueba `!= null` antes de tocarlo.
	m.cesiones = Cesiones.new(m)
	## Las epocas doradas son del mundo y `desde_instantanea()` no pasa por
	## `generar()`: sin esto se quedaban con la referencia al mundo en null y
	## dejaban de sortearse en cuanto se cargaba una partida.
	m.eras = Eras.new(m)
	m.anio = int(datos["anio"])
	m.semana = int(datos["semana"])
	Jugador.semana_global = m.anio * 100 + m.semana
	## Fase 0: el día/hora y las necesidades del DT (silencioso: cargar no pasa el tiempo).
	m.reloj.desde_dic(datos.get("reloj", {}))
	m.necesidades.desde_dic(datos.get("necesidades", {}))
	m.citas.desde_dic(datos.get("citas", {}))
	if not (datos.get("redes_ciudad", {}) as Dictionary).is_empty():
		m.redes_ciudad = CargaCiudad.de("RedesCiudad").new(int(datos["redes_ciudad"].get("semilla", 1)))
		m.redes_ciudad.desde_dic(datos["redes_ciudad"])
	m.afinidad.desde_dic(datos.get("afinidad", {}))
	m.imprevistos.desde_dic(datos.get("imprevistos", {}))
	m.horario = String(datos.get("horario", "tarde"))
	m.campana = (datos.get("campana", {}) as Dictionary).duplicate()
	m.mi_club_id = String(datos["mi_club"])
	m.desafios.clear()
	m.reto = (datos.get("reto", {}) as Dictionary).duplicate()
	m.rotacion_activa = bool(datos.get("rotacion_activa", false))
	m.bono_analisis = float(datos.get("bono_analisis", 1.0))
	m.fin_partida = (datos.get("fin_partida", {}) as Dictionary).duplicate()
	var df: Dictionary = datos.get("fondo", {})
	if not df.is_empty():
		m.fondo = FondoInversion.new()
		m.fondo.desde_dic(df)
	for k in datos.get("desafios", []):
		m.desafios.append(String(k))
	m.dificultad = String(datos.get("dificultad", "normal"))   ## guardados viejos: normal
	m.prologo_visto = bool(datos.get("prologo_visto", true))   ## guardados viejos: ya jugaban, sin prólogo
	m.prologo_pendiente = bool(datos.get("prologo_pendiente", false))
	m.valor_ia_ref = float(datos.get("vref", 0.0))

	for d: Dictionary in datos["clubes"]:
		var c := _dic_a_club(d)
		m.clubes[c.id] = c
	for d: Dictionary in datos["ligas"]:
		m.ligas.append(_dic_a_liga(d, m))
	if datos.get("paises_activos") is Array:   ## (10-11) partidas viejas no la traen: se deduce de las ligas
		LigasActivas.fijar(m, datos["paises_activos"] as Array)
	else:
		LigasActivas.registrar(m)
	if datos.get("paises_pendientes") is Array:   ## (12-11) ligas elegidas en Ajustes con la temporada en marcha
		LigasActivas.programar(m, datos["paises_pendientes"] as Array)
	m.copa = _dic_a_copa(datos.get("copa", {}), m)
	CopasMundo.desde_dic(m, datos.get("copas_mundo", {}))
	m.mercado.desde_dic(datos.get("mercado", {}))
	for d: Dictionary in datos.get("libres", []):
		m.libres.append(_dic_a_jugador(d))
	m.tienda = datos.get("tienda", {})
	var n_guardadas: Dictionary = datos.get("normas", {})
	for k in m.normas:
		if n_guardadas.has(k):
			m.normas[k] = bool(n_guardadas[k])
	_restaurar_lo_tuyo(datos, m)
	## (4-11, banco de guardado) `tomar_el_mando` (dentro de `_restaurar_lo_tuyo`) vuelve a sembrar las citas de la semana:
	## sin esto, cada carga añadía citas repetidas y movía su contador. Las guardadas mandan.
	m.citas.desde_dic(datos.get("citas", {}))
	## La Carrera de Jugador va aparte: no tiene club de entrenador, y
	## `_restaurar_lo_tuyo()` sale en seco sin él.
	var cj: Dictionary = datos.get("carrera_jugador", {})
	if not cj.is_empty():
		m.carrera_jugador = CarreraJugador.desde_dic(cj)
	## 28-10 (auditoría): los contadores de ids no se guardan; sin esto, el primer canterano o libre nacía como «j1» y
	## chocaba con un jugador existente (y «c1» con un club). Se recalculan de lo cargado.
	var seq_j := 0
	for c: Club in m.clubes.values():
		seq_j = maxi(seq_j, _seq_de(c.id, "c", 0))
		for j: Jugador in c.plantilla:
			seq_j = maxi(seq_j, _seq_de(j.id, "j", 0))
	for j: Jugador in m.libres:
		seq_j = maxi(seq_j, _seq_de(j.id, "j", 0))
	m._seq_jugador = maxi(m._seq_jugador, seq_j)
	var seq_c := 0
	for cid: String in m.clubes:
		seq_c = maxi(seq_c, _seq_de(cid, "c", 0))
	m._seq_club = maxi(m._seq_club, seq_c)
	## Los «ex de mi club» son del mundo cargado, no de la partida anterior de la misma sesión.
	Partido.ex_de_mi_club = (datos.get("ex_mio", {}) as Dictionary).duplicate()
	## El estado del azar guardado manda sobre todo lo que la carga haya consumido (`tomar_el_mando`, etc.).
	if datos.has("azar"):
		Azar._rng.state = int(String(datos["azar"]))
	LeyesPais.clubes_mundo = m.clubes
	LeyesPais.anio_actual = m.anio
	return m

## `soltar_antes`: lo que quien llama quiere soltar del mundo de ANTES (p. ej. `func(): p.mundo = null`). Se llama cuando el guardado ya se leyó y se sabe bueno (huella, versión y claves) y ANTES de construir el
## mundo nuevo (10-11, pico de RAM: con el mundo entero conviven el mundo viejo, el diccionario del JSON (~230 MB) y el mundo nuevo; así nunca coinciden los tres). Si el guardado no sirve, no se llama y el
## mundo de antes queda como estaba. Sin esto además `LeyesPais.clubes_mundo` (estático) mantenía vivo TODO el mundo anterior hasta el final de la carga.
static func cargar(nombre: String, soltar_antes := Callable()) -> Mundo:
	GuardadoSegundoPlano.esperar()   ## (3-11) no leer un archivo mientras el autoguardado lo está escribiendo
	var t0 := Time.get_ticks_msec()
	var datos := _leer_con_respaldo(ruta_de(nombre))
	if _instantanea_buena(datos):
		LeyesPais.clubes_mundo = {}
		if soltar_antes.is_valid():
			soltar_antes.call()
	var m := desde_instantanea(datos)
	PartidaArchivo.ms_carga = Time.get_ticks_msec() - t0
	return m

static func borrar(nombre: String) -> void:
	_cabeceras.erase(ruta_de(nombre))
	for suf: String in PartidaArchivo.sufijos():
		if FileAccess.file_exists(ruta_de(nombre) + suf):
			DirAccess.remove_absolute(ruta_de(nombre) + suf)
