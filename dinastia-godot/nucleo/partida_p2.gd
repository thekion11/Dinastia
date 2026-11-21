extends "res://nucleo/partida_p1.gd"
## [Capa intermedia de `partida.gd`, entre `partida_p1.gd` y `partida.gd`] _seq_de y su gemela _seq_de_gd (20-11, orden 63: C++).
## Y la restauración de la partida (`_restaurar_lo_tuyo` y sus auxiliares, 20-11, orden 63: partido en funciones por tramos).

## El número de un id «j123» / «c45»; `defecto` si no tiene esa forma.
static func _seq_de(id: String, prefijo: String, defecto: int) -> int:
	var nat := Nativo.de("nuc_seq_de")
	if nat != null:
		return nat.nuc_seq_de(id, prefijo, defecto)
	return _seq_de_gd(id, prefijo, defecto)

## Gemela GDScript de `nuc_seq_de` (extensión C++, orden 63): respaldo sin binario y comparación en `pruebas/probar_nativo_puras.gd`.
static func _seq_de_gd(id: String, prefijo: String, defecto: int) -> int:
	var n := id.trim_prefix(prefijo)
	return int(n) if id.begins_with(prefijo) and n.is_valid_int() else defecto

static func _restaurar_lo_tuyo(datos: Dictionary, m: Mundo) -> void:
	var mio := m.mi_club()
	if mio == null:
		_restaurar_sin_club(datos, m)
		return
	## `tomar_el_mando` crea los sistemas "solo tuyos" de cero y vuelve a sortear los continentales. Se llama primero y DESPUES
	## se pisan sus valores con los del guardado: un sistema nuevo se estrena en limpio en una partida vieja, en vez de null.
	m.tomar_el_mando(m.mi_club_id)
	m.anios_en_club = int(datos.get("anios_en_club", 0))   ## (`tomar_el_mando` lo pone a 0: se restaura DESPUÉS)
	_restaurar_directiva(datos, m)
	_restaurar_plantilla_y_obras(datos, m, mio)
	_restaurar_servicios_club(datos, m)
	_restaurar_competicion(datos, m)
	_restaurar_gestion_club(datos, m)
	_restaurar_ajustes_club(datos, m)
	_restaurar_prensa_y_resto(datos, m)

## Partida sin club (La Ruta): lo que se restaura aunque no tengas club (revisión de G-03/G-04).
static func _restaurar_sin_club(datos: Dictionary, m: Mundo) -> void:
	_restaurar_continentales(datos, m)   ## (16-11, informe G-03) en La Ruta no hay club tuyo, pero los continentales siguen
	_restaurar_competicion(datos, m)
	var em: Variant = (datos.get("entrenamiento", {}) as Dictionary).get("mundo") if datos.get("entrenamiento") is Dictionary else null
	if em is Dictionary:   ## (16-11, revisión de G-04) el tope de subidas del entrenamiento del mundo
		m._entreno_mundo = Entrenamiento.new()
		m._entreno_mundo.desde_dic(em)

## La directiva del club: confianza, objetivos, proyecto, bases y trofeos.
static func _restaurar_directiva(datos: Dictionary, m: Mundo) -> void:
	var dd: Dictionary = datos.get("directiva", {})
	if not dd.is_empty() and m.directiva != null:
		m.directiva.confianza = int(dd.get("confianza", Directiva.INICIAL))
		m.directiva.meta_puesto = int(dd.get("meta", 8))
		m.directiva.objetivo = String(dd.get("objetivo", m.directiva.objetivo))
		m.directiva.temporadas = int(dd.get("temporadas", 0))
		m.directiva.despedido_ya = bool(dd.get("despedido", false))
		m.directiva.desde_dic(dd.get("consejeros", {}))
		## (10-11) Objetivos por club: una partida vieja no los trae y se queda con los que generó `tomar_el_mando` para su club.
		m.directiva._objetivo_generado = m.directiva.objetivo   ## (guardado viejo o nuevo: el de liga que cargó es el «generado», así se renueva al cerrar la temporada)
		if dd.has("objetivos"):
			m.directiva.objetivos.clear()
			for o: Variant in dd["objetivos"]:
				if o is Dictionary:
					m.directiva.objetivos.append((o as Dictionary).duplicate())
			m.directiva.proyecto = (dd.get("proyecto", {}) as Dictionary).duplicate(true)
			m.directiva.bases = (dd.get("bases", {}) as Dictionary).duplicate(true)
		DesafiosDificultad.aplicar(m)
		m.directiva.trofeos.clear()
		for t: String in dd.get("trofeos", []):
			m.directiva.trofeos.append(t)

## Plantilla del club: staff, obras, roles, federación, estadio y entrenamiento.
static func _restaurar_plantilla_y_obras(datos: Dictionary, m: Mundo, mio: Club) -> void:
	m.staff.desde_dic(datos.get("staff", {}))
	## Y hay que volver a aplicarlo: los niveles solos no mueven nada, el motor de
	## partido lee `Club.bonus_ataque` y `bonus_defensa`. Sin este `aplicar`, un
	## staff de nivel 5 cargado de disco no hacia absolutamente nada.
	m.staff.aplicar(mio)
	## Las obras van DESPUES de fijar el aforo base, y hay que volver a aplicarlas:
	## el aforo del club que viene del guardado ya trae las tribunas construidas,
	## asi que si se aplicara sobre el, cada carga lo multiplicaria otra vez.
	var obras_dic: Dictionary = datos.get("obras", {})
	if not obras_dic.is_empty():
		m.obras.desde_dic(obras_dic)
		if int(obras_dic.get("aforo_base", 0)) <= 0:
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

## Servicios del club (vestuario, hinchada, cantera de sus clubes…): cada uno con su «desde_dic».
static func _restaurar_servicios_club(datos: Dictionary, m: Mundo) -> void:
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

## Gestión: calendario, política, contratos, vida, maestría, junta, banco, auspicio y eras.
static func _restaurar_gestion_club(datos: Dictionary, m: Mundo) -> void:
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

## Ajustes tácticos, comercial, ciudad, selecciones, cantera, ojeadores y cesiones; al final, los bonificadores.
static func _restaurar_ajustes_club(datos: Dictionary, m: Mundo) -> void:
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
	var bm: Array = datos.get("bonus_mio", [])
	if bm.size() == 2 and m.mi_club() != null: m.mi_club().bonus_ataque = float(bm[0]); m.mi_club().bonus_defensa = float(bm[1])

## Prensa, médico, logros, retos, mentor, mercado DT, ojeados, libro y continentales.
static func _restaurar_prensa_y_resto(datos: Dictionary, m: Mundo) -> void:
	var dp: Dictionary = datos.get("prensa", {})
	if not dp.is_empty() and m.prensa != null:
		for k: String in _CAMPOS_PRENSA:
			if dp.has(k):
				m.prensa.set(k, dp[k])
	if m.medico != null:
		m.medico.desde_dic(datos.get("medico", {}))
	if m.logros != null:
		m.logros.desde_dic(datos.get("logros", {}))
	m.retos_semana.desde_dic(datos.get("retos_semana", {}))
	m.mentor_mes.desde_dic(datos.get("mentor_mes", {}))
	MercadoDT.de(m).desde_dic(m, datos.get("mercado_dt", {}))
	m.ojeados = datos.get("ojeados", {})
	m.libro_financiero.clear()
	for x: Dictionary in datos.get("libro_financiero", []):
		m.libro_financiero.append(x)
	_restaurar_continentales(datos, m)

## Los ajustes de competición y la sede de la final de copa (también en La Ruta, revisión de G-03).
static func _restaurar_competicion(datos: Dictionary, m: Mundo) -> void:
	m.ajustes_competicion = (datos.get("ajustes_competicion", {}) as Dictionary).duplicate()
	if m.copa != null:
		m.copa.sede_final_id = String(m.ajustes_competicion.get("copa_sede", ""))

static func _restaurar_continentales(datos: Dictionary, m: Mundo) -> void:
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
		t.grupos_desde_dic(fila, m.clubes)
		m.continentales[k] = t
