class_name Partida
extends "res://nucleo/partida_p1.gd"
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
	c.tactica.marca_al_hombre = bool(d.get("hombre", false))
	c.tactica.fuera_de_juego = bool(d.get("fjuego", false))
	c.tactica.tiro_lejano = bool(d.get("lejano", false))
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
	return c

static func _restaurar_lo_tuyo(datos: Dictionary, m: Mundo) -> void:
	var mio := m.mi_club()
	if mio == null:
		return
	## `tomar_el_mando` crea los sistemas "solo tuyos" de cero y vuelve a sortear los
	## continentales. Se llama primero y DESPUES se pisan sus valores con los del
	## guardado: asi no hay que duplicar aqui la construccion de cada uno, y si
	## manana se anade un sistema nuevo, cargar una partida vieja lo estrena en
	## limpio en vez de dejarlo en null.
	m.tomar_el_mando(m.mi_club_id)

	var dd: Dictionary = datos.get("directiva", {})
	if not dd.is_empty() and m.directiva != null:
		m.directiva.confianza = int(dd.get("confianza", Directiva.INICIAL))
		m.directiva.meta_puesto = int(dd.get("meta", 8))
		m.directiva.objetivo = String(dd.get("objetivo", m.directiva.objetivo))
		m.directiva.temporadas = int(dd.get("temporadas", 0))
		m.directiva.despedido_ya = bool(dd.get("despedido", false))
		m.directiva.desde_dic(dd.get("consejeros", {}))
		m.directiva.trofeos.clear()
		for t: String in dd.get("trofeos", []):
			m.directiva.trofeos.append(t)

	m.staff.desde_dic(datos.get("staff", {}))
	## Y hay que volver a aplicarlo: los niveles solos no mueven nada, el motor de
	## partido lee `Club.bonus_ataque` y `bonus_defensa`. Sin este `aplicar`, un
	## staff de nivel 5 cargado de disco no hacia absolutamente nada.
	m.staff.aplicar(mio)
	## Las obras van DESPUES de fijar el aforo base, y hay que volver a aplicarlas:
	## el aforo del club que viene del guardado ya trae las tribunas construidas,
	## asi que si se aplicara sobre el, cada carga lo multiplicaria otra vez.
	var do_: Dictionary = datos.get("obras", {})
	if not do_.is_empty():
		m.obras.desde_dic(do_)
		if int(do_.get("aforo_base", 0)) <= 0:
			## Guardado viejo, sin aforo base: se deduce quitando las tribunas.
			m.obras.fijar_aforo_base(int(round(float(mio.estadio_aforo) / (1.0 + 0.15 * float(m.obras.nivel("trib"))))))
		m.obras.aplicar(mio)
	if m.roles != null:
		m.roles.desde_dic(datos.get("roles", {}))
		## `desde_dic()` no emite `rol_cambiado` -no es un cambio de rol, es
		## restaurar uno ya vivido-, así que `Directiva.puede_despedirte` no se
		## entera solo: `tomar_el_mando()`, arriba, lo calculó con el rol por
		## defecto de antes de cargar. Se recalcula aquí, ya con el rol real.
		if m.directiva != null:
			m.directiva.puede_despedirte = m.roles.le_pueden_echar()
	m.federacion.desde_dic(datos.get("federacion", {}))
	m.estadio.desde_dic(datos.get("estadio", {}))
	if m.entrenamiento != null:
		m.entrenamiento.desde_dic(datos.get("entrenamiento", {}))
	## El vestuario tenia a_dic()/desde_dic() escritos pero nadie los llamaba: la
	## ansiedad de cada jugador se sortea al crear su ficha mental (Azar.ent), asi
	## que sin restaurarla una partida cargada barajaba la cabeza de todo el
	## plantel de nuevo. Eso cambiaba factor_animo() y por tanto bonus_ataque -el
	## sintoma que cazaba el banco, aunque el rastro llevaba aqui y no a Staff.
	if m.vestuario != null:
		m.vestuario.desde_dic(datos.get("vestuario", {}))
	if m.hinchada != null:
		m.hinchada.desde_dic(datos.get("hinchada", {}))
	if m.gente != null:
		m.gente.desde_dic(datos.get("gente", {}))
	m.interiores.desde_dic(datos.get("interiores", {}))
	if m.club_dentro != null:
		m.club_dentro.desde_dic(datos.get("club_dentro", {}))
	if m.charlas != null:
		m.charlas.desde_dic(datos.get("charlas", {}))
	if m.licencia != null:
		m.licencia.desde_dic(datos.get("licencia", {}))
	if m.eventos_cantera != null:
		m.eventos_cantera.desde_dic(datos.get("eventos_cantera", {}))
	if m.trabajadores != null:
		m.trabajadores.desde_dic(datos.get("trabajadores", {}))
	if m.redes != null:
		m.redes.desde_dic(datos.get("redes", {}))
	if m.movil != null:
		m.movil.desde_dic(datos.get("movil", {}))
	if m.mercado_av != null:
		m.mercado_av.desde_dic(datos.get("mercado_av", {}))
	if m.insolvencia != null:
		m.insolvencia.desde_dic(datos.get("insolvencia", {}))
	m.ajustes_competicion = (datos.get("ajustes_competicion", {}) as Dictionary).duplicate()
	if m.copa != null:
		m.copa.sede_final_id = String(m.ajustes_competicion.get("copa_sede", ""))
	if m.calendario != null:
		m.calendario.desde_dic(datos.get("calendario", {}))
	if m.politica != null:
		m.politica.desde_dic(datos.get("politica", {}))
	if m.contratos != null:
		m.contratos.desde_dic(datos.get("contratos", {}))
	if m.vida != null:
		m.vida.desde_dic(datos.get("vida", {}))
	if m.maestria != null:
		m.maestria.desde_dic(datos.get("maestria", {}))
	if m.junta != null:
		m.junta.desde_dic(datos.get("junta", {}))
		m.junta.formar(m.mi_club())
	if m.banco != null:
		m.banco.desde_dic(datos.get("banco", {}))
	if m.auspicio != null:
		m.auspicio.desde_dic(datos.get("auspicio", {}))
	if m.eras != null:
		m.eras.desde_dic(datos.get("eras", {}))
	m.era_tactica = int(datos.get("era_tactica", 0))
	m.era_hasta = int(datos.get("era_hasta", 0))
	m.eficacia_tactica = (datos.get("eficacia_tactica", {}) as Dictionary).duplicate(true)
	m.amistoso_hecho = bool(datos.get("amistoso", false))
	if m.comercial != null:
		m.comercial.desde_dic(datos.get("comercial", {}))
	if m.ciudad != null:
		m.ciudad.desde_dic(datos.get("ciudad", {}))
		m.gente.armar()
	if m.selecciones != null:
		m.selecciones.desde_dic(datos.get("selecciones", {}))
	if m.cantera != null:
		m.cantera.desde_dic(datos.get("cantera", {}))
	if m.academia != null:
		m.academia.desde_dic(datos.get("academia", {}))
	if m.ojeadores != null:
		m.ojeadores.desde_dic(datos.get("ojeadores", {}))
	if m.cesiones != null:
		m.cesiones.desde_dic(datos.get("cesiones_datos", {}))
	## Y se recalculan los bonificadores del motor con el staff, el arbol del DT
	## y el vestuario ya cargados: los niveles solos no mueven nada.
	m.aplicar_bonificadores()

	var dp: Dictionary = datos.get("prensa", {})
	if not dp.is_empty() and m.prensa != null:
		for k: String in _CAMPOS_PRENSA:
			if dp.has(k):
				m.prensa.set(k, dp[k])
	if m.medico != null:
		m.medico.desde_dic(datos.get("medico", {}))
	if m.logros != null:
		m.logros.desde_dic(datos.get("logros", {}))
	m.ojeados = datos.get("ojeados", {})
	m.libro_financiero.clear()
	for x: Dictionary in datos.get("libro_financiero", []):
		m.libro_financiero.append(x)

	var dc: Dictionary = datos.get("continentales", {})
	if dc.is_empty():
		return
	m.continentales.clear()
	for k: String in dc:
		var t := Continental.crear(k)
		var fila: Dictionary = dc[k]
		for id: String in fila.get("inscritos", []):
			var c: Club = m.clubes.get(id)
			if c != null:
				t.participantes.append(c)
		for id: String in fila.get("vivos", []):
			var c2: Club = m.clubes.get(id)
			if c2 != null:
				t.vivos.append(c2)
		t.ronda = int(fila.get("ronda", 0))
		t.fecha = int(fila.get("fecha", 0))
		t.por_grupos = bool(fila.get("por_grupos", false))
		t.campeon = m.clubes.get(String(fila.get("campeon", "")))
		m.continentales[k] = t

## Reconstruye un Mundo desde el retrato. Lo usan la carga de disco y el
## deshacer, que son la misma operacion con distinto origen.
static func desde_instantanea(datos: Dictionary) -> Mundo:
	if datos.is_empty():
		return null
	if int(datos.get("version", 0)) > VERSION:
		push_error("Partida: el guardado es de una versión más nueva (%d) que el juego (%d)" % [
			int(datos["version"]), VERSION])
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
	m.horario = String(datos.get("horario", "tarde"))
	m.campana = (datos.get("campana", {}) as Dictionary).duplicate()
	m.mi_club_id = String(datos["mi_club"])
	m.desafios.clear()
	m.reto = (datos.get("reto", {}) as Dictionary).duplicate()
	var df: Dictionary = datos.get("fondo", {})
	if not df.is_empty():
		m.fondo = FondoInversion.new()
		m.fondo.desde_dic(df)
	for k in datos.get("desafios", []):
		m.desafios.append(String(k))

	for d: Dictionary in datos["clubes"]:
		var c := _dic_a_club(d)
		m.clubes[c.id] = c
	for d: Dictionary in datos["ligas"]:
		m.ligas.append(_dic_a_liga(d, m))
	m.copa = _dic_a_copa(datos.get("copa", {}), m)
	m.mercado.desde_dic(datos.get("mercado", {}))
	for d: Dictionary in datos.get("libres", []):
		m.libres.append(_dic_a_jugador(d))
	m.tienda = datos.get("tienda", {})
	var n_guardadas: Dictionary = datos.get("normas", {})
	for k in m.normas:
		if n_guardadas.has(k):
			m.normas[k] = bool(n_guardadas[k])
	_restaurar_lo_tuyo(datos, m)
	## La Carrera de Jugador va aparte: no tiene club de entrenador, y
	## `_restaurar_lo_tuyo()` sale en seco sin él.
	var cj: Dictionary = datos.get("carrera_jugador", {})
	if not cj.is_empty():
		m.carrera_jugador = CarreraJugador.desde_dic(cj)
	LeyesPais.clubes_mundo = m.clubes
	LeyesPais.anio_actual = m.anio
	return m

static func cargar(nombre: String) -> Mundo:
	return desde_instantanea(_leer_con_respaldo(ruta_de(nombre)))

static func borrar(nombre: String) -> void:
	for suf in ["", TEMPORAL, RESPALDO]:
		if FileAccess.file_exists(ruta_de(nombre) + suf):
			DirAccess.remove_absolute(ruta_de(nombre) + suf)

## Para el menú de carga solo hacen falta cuatro datos, pero el fichero está
## comprimido entero, así que hay que abrirlo igual. Se separa en su propia
## función para que quede claro qué se está pagando.
static func _leer_cabecera(ruta: String) -> Dictionary:
	return _cabecera_de(_leer_todo(ruta))
