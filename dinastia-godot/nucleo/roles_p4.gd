extends "res://nucleo/roles_p3.gd"
## [Capa 4/5 de `roles.gd`] tras_temporada, ayudante_ascendido, subir_al_primer_equipo, ascender, chequeo_filosofia, homenajear … (+12)

## Al cerrar la temporada. `resumen` es lo que devuelve `Directiva.tras_temporada()`.
##
## El prestigio se mueve AQUÍ y no en cuarenta sitios. El HTML lo tocaba en 26
## funciones distintas y por eso nadie sabía nunca por qué había subido; aquí se
## concentra lo que de verdad marca una carrera —cumplir, ganar, fracasar— y el
## resto entra por `sumar_prestigio()` desde donde corresponda.
func tras_temporada(resumen: Dictionary = {}) -> Dictionary:
	temporadas += 1
	if bool(resumen.get("cumplido", false)):
		sumar_prestigio(3)
		_rep("ganador", 3, "Cumpliste el objetivo de la temporada")
	elif not resumen.is_empty():
		sumar_prestigio(-2)
		_rep("ganador", -3, "No cumpliste el objetivo de la temporada")
	_reputacion_de_temporada()
	if int(resumen.get("puesto", 0)) == 1:
		sumar_trofeo("Liga")
	if es_cantera():
		_chequeo_cantera()
	var siguiente := puede_ascender()
	return {
		"rol": rol, "prestigio": prestigio, "trofeos": trofeos.size(),
		"temporadas": temporadas, "puede_ascender_a": siguiente,
	}

func ayudante_ascendido() -> bool:
	return bool(ayudante.get("ascendido", false))

# ---------------------------------------------------------------------------
# CANTERA: subir chicos al primer equipo
# ---------------------------------------------------------------------------

## Sube un juvenil al primer equipo. Devuelve "" si se pudo, o el motivo.
##
## Subirlo antes de tiempo tiene precio: le queda grande y se le nota. Es lo que
## convierte la decisión en una decisión — si subir siempre fuera gratis, el modo
## sería pulsar un botón cuatro veces cada temporada.
func subir_al_primer_equipo(j: Jugador) -> String:
	var m := _mundo()
	if m == null or not es_cantera():
		return "no eres director de cantera"
	if j == null or j.club_id != m.mi_club_id:
		return "ese chico no es del club"
	if j.edad > 21:
		return "ya no cuenta como canterano"
	var subidos: Array = cantera.get("subidos", [])
	if subidos.has(j.id):
		return "ya lo promoviste"
	subidos.append(j.id)
	cantera["subidos"] = subidos
	cantera["total"] = int(cantera.get("total", 0)) + 1
	var listo := j.ovr >= m.mi_club().rep - 14
	if listo:
		j.moral = 99
		sumar_prestigio(2)
		aviso.emit("Debuta un canterano: %s" % j.nombre,
			"%s (%d años, %s, media %d con proyección %d) sube al primer equipo. Es el %dº debutante de tu gestión. La grada canta su nombre antes de que toque la pelota." % [
				j.nombre, j.edad, j.pos_e, j.ovr, j.pot, subidos.size()])
	else:
		## El HTML le disparaba la ansiedad, que es un sistema que aquí no está
		## portado. La moral es lo más parecido que existe hoy: un chico quemado
		## rinde por debajo de su media, que es justo el castigo que tocaba.
		j.cambiar_moral(-(Azar.ent(14, 26)), "Directiva")
		aviso.emit("Debut prematuro: %s" % j.nombre,
			"Lo subiste antes de tiempo. Le queda grande y se le nota. A veces un año más abajo vale oro.")
	return ""

## Sube de rol. Devuelve "" si se hizo, o el motivo por el que no.
func ascender() -> String:
	var nuevo := puede_ascender()
	if nuevo == "":
		return "todavía no tienes el prestigio para dar ese salto"
	var antes := rol
	rol = nuevo
	if dt_empleado.is_empty():
		_contratar_dt_empleado()
	rol_cambiado.emit(antes, rol)
	ascenso.emit(rol)
	if nuevo == DIR:
		aviso.emit("Asciendes a Director Deportivo",
			"El directorio te sube al despacho: dejas el banquillo a %s y pasas a mandar en mercado, cuerpo técnico y finanzas." % dt_nombre())
	else:
		aviso.emit("Asciendes a Dueño del club",
			"Compras el paquete de control. Ya nadie te puede echar: el club es tuyo, con todo lo que eso implica.")
	return ""

# ---------------------------------------------------------------------------
# LA ESCUELA TÁCTICA, EL HOMENAJE Y LA RETIRADA: `vLegado()` del HTML
# ---------------------------------------------------------------------------

## `chequeoFilosofia()`: se llama UNA VEZ POR SEMANA con la táctica que sacaste.
## No hay nada que pulsar; la escuela nace sola si eres fiel a un modelo. Por
## eso cuenta semanas y no partidos: cambiar de dibujo para un rival puntual
## también rompe la racha, que es exactamente lo que se quiere premiar.
func chequeo_filosofia(t: Tactica) -> void:
	if t == null or not filosofia.is_empty():
		return
	var clave := "%s|%d" % [t.formacion, t.mentalidad]
	_estilos_contados[clave] = int(_estilos_contados.get(clave, 0)) + 1
	if int(_estilos_contados[clave]) < SEMANAS_PARA_ESCUELA:
		return
	## El apellido del entrenador con el sufijo que le pega a su mentalidad. Un
	## "Durantismo" ofensivo y una "Durantística" de equilibrio no suenan igual,
	## y esa es la gracia: el nombre delata cómo juegas.
	var partes := nombre.strip_edges().split(" ", false)
	var apellido := partes[partes.size() - 1] if partes.size() > 0 else "DT"
	var sufijo := "ística"
	if t.mentalidad == Tactica.Mentalidad.OFENSIVA:
		sufijo = "ismo"
	elif t.mentalidad == Tactica.Mentalidad.DEFENSIVA:
		sufijo = "anismo"
	filosofia = {"nombre": "El %s%s" % [apellido, sufijo], "formacion": t.formacion, "mentalidad": t.mentalidad}
	prestigio = clampi(prestigio + 6, PRESTIGIO_MIN, PRESTIGIO_MAX)
	escuela_nacida.emit(String(filosofia["nombre"]), t.formacion)
	aviso.emit("Nace una escuela: %s" % String(filosofia["nombre"]),
		"Llevas casi dos temporadas fiel a un mismo modelo (%s). La prensa bautizó tu estilo como «%s». Los entrenadores de tu cantera ya lo replican y otros clubes buscan fichar a tus ayudantes." % [t.formacion, String(filosofia["nombre"])])

## `homenajear()`: placa, camiseta enmarcada y vuelta al campo. Devuelve "" si
## se hizo, o el motivo por el que no.
func homenajear(nombre_leyenda: String) -> String:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return "no hay club"
	var c := m.mi_club()
	var coste := Eco.escalar(COSTE_HOMENAJE, c.rep)
	if c.saldo < coste:
		return "el club no tiene los %s que cuesta" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	if m.prensa != null:
		m.prensa.animo = clampi(m.prensa.animo + Azar.ent(5, 11), 0, 100)
	c.socios += Azar.ent(150, 600)
	for j in c.plantel():
		j.cambiar_moral(3, "Directiva")
	homenaje_hecho.emit(nombre_leyenda)
	aviso.emit("Homenaje a %s" % nombre_leyenda,
		"Placa en el acceso principal, camiseta enmarcada y vuelta al campo antes del partido. La grada cantó su nombre durante diez minutos. El club recuerda de dónde viene.")
	return ""

## `retirarse()`: el punto final voluntario. No se puede deshacer -por eso la
## pantalla pide confirmar dos veces-, pero tampoco borra la partida: deja el
## balance a la vista y el juego sigue si quieres mirarlo.
func retirarse() -> String:
	if not retirado.is_empty():
		return "ya anunciaste tu retirada"
	var m := _mundo()
	if m == null:
		return "no hay partida"
	var p: Dictionary = m.puntaje_carrera()
	retirado = {"anio": m.anio, "puntaje": int(p["total"])}
	carrera_cerrada.emit(m.anio, int(p["total"]))
	aviso.emit("Se acaba una carrera",
		"Anuncias tu retirada tras %d temporadas, con %d título(s) y %d puntos de carrera." % [
			m.anio - 2026 + 1, trofeos.size(), int(p["total"])])
	return ""

## El veredicto de `epilogoHTML()`: la frase con la que el juego te resume. Va
## aparte de la pantalla porque el banco tiene que poder comprobar que un
## historial de quince títulos no devuelve la frase del que no ganó nada.
func veredicto_carrera() -> Dictionary:
	var t := trofeos.size()
	if t >= 15:
		return {"texto": "Uno de los grandes nombres que ha dado este fútbol. Tu nombre ya está en la puerta del estadio.", "tono": "oro"}
	if t >= 6:
		return {"texto": "Una carrera sólida y con vitrina. Cuando te retires, la hinchada va a recordar estos años.", "tono": "verde"}
	if t >= 1:
		return {"texto": "Un camino con altibajos y alguna alegría grande. Todavía tienes tiempo de escribir el capítulo bueno.", "tono": "ambar"}
	return {"texto": "Todavía sin títulos. Hay entrenadores que tardaron quince años en levantar el primero.", "tono": "suave"}

## El palmarés agrupado por competición: "Liga ×3, Copa ×1". El año se le quita
## al título porque si no cada temporada es una fila distinta y no se ve nada.
func palmares_por_tipo() -> Array[Dictionary]:
	var cuenta := {}
	for t: Dictionary in trofeos:
		var k := String(t.get("titulo", "")).strip_edges()
		if k == "":
			continue
		cuenta[k] = int(cuenta.get(k, 0)) + 1
	var salida: Array[Dictionary] = []
	for k2: String in cuenta:
		salida.append({"titulo": k2, "veces": int(cuenta[k2])})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["veces"]) > int(b["veces"]))
	return salida

## Cuántos aportes de capital te quedan esta temporada -para que el botón se
## pueda apagar antes de intentarlo, en vez de fallar y explicarse-.
func inyecciones_restantes() -> int:
	var m := _mundo()
	if m != null and _anio_inyecciones != m.anio:
		return INYECCIONES_POR_TEMPORADA
	return maxi(0, INYECCIONES_POR_TEMPORADA - _inyecciones)

func inyectar_capital() -> String:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return "no hay club"
	if not puede_inyectar_capital():
		return "solo el dueño mete dinero de su bolsillo"
	if _anio_inyecciones != m.anio:
		_anio_inyecciones = m.anio
		_inyecciones = 0
	if _inyecciones >= INYECCIONES_POR_TEMPORADA:
		return "máximo dos aportes de capital por temporada"
	_inyecciones += 1
	inyecciones_totales += 1
	var monto := Eco.escalar(INYECCION, float(m.mi_club().rep))
	m.mi_club().mover_saldo(monto)
	aviso.emit("El dueño mete la mano al bolsillo",
		"Inyección desde tu patrimonio personal (%d/%d esta temporada). Los acreedores respiran." % [
			_inyecciones, INYECCIONES_POR_TEMPORADA])
	return ""

## Vender el club es el final de una carrera, no una operación más: te vas por la
## puerta ancha y vuelves al mercado como entrenador libre.
func vender_club() -> String:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return "no hay club"
	if not puede_vender_club():
		return "no se vende lo que no es tuyo"
	var c := m.mi_club()
	var precio := int(round(Eco.ref_caja(float(c.rep)) * 5.5 + float(c.saldo) * 0.5))
	historial.append({"club": "%s (vendido)" % c.nombre, "hasta": m.anio})
	sumar_prestigio(6)
	var antes := rol
	rol = DT
	sin_club = true
	rol_cambiado.emit(antes, rol)
	aviso.emit("Operación histórica",
		"Vendiste %s por %d. Te vas por la puerta ancha, con la vitrina llena y el bolsillo también. Tu prestigio te abre todas las puertas del continente." % [c.nombre, precio])
	sin_banco.emit(c.nombre)
	return ""

# ---------------------------------------------------------------------------
# SIN CLUB: las ofertas y el club nuevo
# ---------------------------------------------------------------------------

## Te quedas sin banco. Lo llama quien atienda `Directiva.despedido`, DESPUÉS de
## comprobar `le_pueden_echar()`.
func quedar_sin_banco() -> void:
	var m := _mundo()
	var c := m.mi_club() if m != null else null
	if c != null:
		historial.append({"club": c.nombre, "hasta": m.anio})
	sin_club = true
	sin_banco.emit(c.nombre if c != null else "")

## Los clubes que te quieren. Tres como mucho, y siempre al menos uno.
##
## Nunca puedes quedarte sin nada: si tu prestigio se hundió, siempre habrá algún
## club modesto dispuesto a darte una última oportunidad. Sin esa red, una racha
## mala terminaba la partida sin que el juego lo dijera en ninguna parte.
func ofertas_trabajo() -> Array[Club]:
	var salida: Array[Club] = []
	var m := _mundo()
	if m == null:
		return salida
	var todos: Array[Club] = []
	for c: Club in m.clubes.values():
		if c.division > 0 and c.id != m.mi_club_id:
			todos.append(c)
	if todos.is_empty():
		return salida
	var alcanzables: Array[Club] = []
	for c in todos:
		if c.rep <= prestigio + 18:
			alcanzables.append(c)
	Azar.barajar(alcanzables)
	for c in alcanzables:
		if salida.size() >= 3:
			break
		salida.append(c)
	if salida.size() < 2:
		var humildes := todos.duplicate()
		humildes.sort_custom(func(a: Club, b: Club) -> bool: return a.rep < b.rep)
		var seis: Array[Club] = []
		for c: Club in humildes:
			if seis.size() >= 6:
				break
			seis.append(c)
		Azar.barajar(seis)
		for c in seis:
			if salida.size() >= 3:
				break
			if not salida.has(c):
				salida.append(c)
	return salida

## Firmas por un club nuevo. Devuelve "" si se hizo, o el motivo.
##
## Guarda de la casa: si llega un id que no existe, en el HTML la línea siguiente
## dejaba el club apuntando a la nada y la partida quedaba irrecuperable —sin
## club, sin tabla y sin plantel—. Mejor no hacer nada que romper el guardado.
##
## Y OJO CON EL ORDEN: el cuerpo técnico y las obras se renuevan ANTES de tomar
## el mando. Lo que construiste en el club anterior se queda allí (es suyo, no
## tuyo), y `Mundo.tomar_el_mando()` crea el parte médico atado al `Staff` que
## encuentre: si se reemplazara después, el médico seguiría leyendo el cuerpo
## técnico del club que acabas de dejar.
func aceptar_trabajo(club_id: String) -> String:
	var m := _mundo()
	if m == null:
		return "no hay partida"
	if club_id.is_empty() or not m.clubes.has(club_id):
		return "ese club ya no está disponible"
	var anterior := m.mi_club()
	if anterior != null and anterior.id != club_id:
		historial.append({"club": anterior.nombre, "hasta": m.anio})
	m.staff = Staff.new()
	m.obras = Instalaciones.new()
	m.tomar_el_mando(club_id)
	sin_club = false
	## Ni el interinato ni el ayudantazgo se heredan: son contratos del club que
	## dejaste. Al nuevo llegas de entrenador, que es lo que firmaste.
	interino = {}
	ayudante = {}
	emergencia = {}
	## La directiva es OTRA y ya trae su propio objetivo: conservar el del club
	## anterior aquí lo resucitaría el día que termine un modo especial.
	_objetivo_club = ""
	if rol != DT and dt_empleado.is_empty():
		_contratar_dt_empleado()
	var c := m.mi_club()
	aviso.emit("Nuevo desafío",
		"Asumes en %s. Objetivo: %s." % [c.nombre, m.directiva.objetivo if m.directiva != null else "el que te pongan"])
	return ""

# ---------------------------------------------------------------------------
# GUARDADO
# ---------------------------------------------------------------------------

func a_dic() -> Dictionary:
	return {
		"reputacion": reputacion.a_dic(),
		"rol": rol, "nombre": nombre, "prestigio": prestigio,
		"trofeos": trofeos.duplicate(true),
		"historial": historial.duplicate(true),
		"temporadas": temporadas, "sin_club": sin_club, "sandbox": sandbox,
		"dt_empleado": dt_empleado.duplicate(),
		"directrices": directrices.duplicate(),
		"ayudante": ayudante.duplicate(),
		"interino": interino.duplicate(),
		"cantera": cantera.duplicate(true),
		"emergencia": emergencia.duplicate(),
		"inyecciones": _inyecciones, "anio_inyecciones": _anio_inyecciones,
		"inyecciones_totales": inyecciones_totales,
		"patrimonio": patrimonio, "licencia": licencia,
		"bienes": bienes.duplicate(), "sem_trabajadas": semanas_trabajadas,
		"filosofia": filosofia.duplicate(),
		"estilos": _estilos_contados.duplicate(),
		"retirado": retirado.duplicate(),
		"rival_dt": rival_dt.duplicate(),
		"leyenda_viva": leyenda_viva.duplicate(),
		"filiales": filiales.duplicate(),
		"sucesor": sucesor.duplicate(),
		"desgaste": desgaste, "curriculum": curriculum.duplicate(true),
		"oferta_club": oferta_de_club.duplicate(), "ult_oferta": _ultima_oferta,
		"look": look.duplicate(),
	}

func desde_dic(d: Dictionary) -> void:
	reputacion.desde_dic(d.get("reputacion", {}))
	rol = String(d.get("rol", DT))
	if not PERMISOS.has(rol):
		rol = DT   ## un guardado viejo con un rol que ya no existe no rompe nada
	nombre = String(d.get("nombre", "Míster"))
	look = (d.get("look", {}) as Dictionary).duplicate()
	var dg: Dictionary = d.get("directrices", {})
	for k in directrices:
		if dg.has(k):
			directrices[k] = dg[k]
	prestigio = clampi(int(d.get("prestigio", PRESTIGIO_INICIAL)), PRESTIGIO_MIN, PRESTIGIO_MAX)
	trofeos.clear()
	for t: Dictionary in d.get("trofeos", []):
		trofeos.append(t)
	historial.clear()
	for h: Dictionary in d.get("historial", []):
		historial.append(h)
	temporadas = int(d.get("temporadas", 0))
	sin_club = bool(d.get("sin_club", false))
	sandbox = bool(d.get("sandbox", false))
	dt_empleado = (d.get("dt_empleado", {}) as Dictionary).duplicate()
	ayudante = (d.get("ayudante", {}) as Dictionary).duplicate()
	interino = (d.get("interino", {}) as Dictionary).duplicate()
	cantera = (d.get("cantera", {}) as Dictionary).duplicate(true)
	emergencia = (d.get("emergencia", {}) as Dictionary).duplicate()
	_inyecciones = int(d.get("inyecciones", 0))
	_anio_inyecciones = int(d.get("anio_inyecciones", 0))
	inyecciones_totales = int(d.get("inyecciones_totales", 0))
	patrimonio = int(d.get("patrimonio", 0))
	licencia = int(d.get("licencia", 0))
	bienes = (d.get("bienes", {}) as Dictionary).duplicate()
	semanas_trabajadas = int(d.get("sem_trabajadas", 0))
	filosofia = (d.get("filosofia", {}) as Dictionary).duplicate()
	_estilos_contados = (d.get("estilos", {}) as Dictionary).duplicate()
	retirado = (d.get("retirado", {}) as Dictionary).duplicate()
	rival_dt = (d.get("rival_dt", {}) as Dictionary).duplicate()
	leyenda_viva = (d.get("leyenda_viva", {}) as Dictionary).duplicate()
	filiales = (d.get("filiales", []) as Array).duplicate()
	sucesor = (d.get("sucesor", {}) as Dictionary).duplicate()
	desgaste = int(d.get("desgaste", 0))
	curriculum = (d.get("curriculum", []) as Array).duplicate(true)
	oferta_de_club = (d.get("oferta_club", {}) as Dictionary).duplicate()
	_ultima_oferta = int(d.get("ult_oferta", 0))

## Lo que cobras a la semana. Sale de la reputación del club y del prestigio que
## tengas, más un 5% por cada licencia: la formación se paga sola.
func sueldo_semanal() -> int:
	var m := _mundo()
	var c := m.mi_club() if m != null else null
	if c == null:
		return 0
	## `sueldoDT()` DEL HTML, TAL CUAL (corregido el 10-9-2026). La versión
	## anterior era otra fórmula -multiplicativa, con el exponente 0,62 de
	## `Eco.escalar()`- que nadie había declarado rediseño y que daba unas TRES
	## VECES más: 9.900 por semana contra 3.509 con club y DT en el promedio.
	## No era un detalle: el sueldo del DT es lo que llena su patrimonio, y con
	## él se compran las licencias -la B cuesta 30.000-. Con la fórmula vieja
	## se pagaba en 3 semanas; en el HTML, en casi 9. Todo el ritmo de la
	## carrera del entrenador iba al triple sin que ninguna prueba lo notara.
	##
	## La del HTML es ADITIVA: una parte crece con el tamaño del club
	## (`ref_caja`, sin exponente) y otra con el prestigio del propio DT.
	var base := int(round(Eco.ref_caja(float(c.rep)) * 0.0022 + float(prestigio) * 40.0))
	## EL CARISMA DEL ARBOL SE COBRA AQUI. `Entrenamiento.factor_sueldo_dt()`
	## estaba escrita desde el porte y no la llamaba nadie: se podia gastar un
	## punto en «Carisma» y el sueldo no se movia un peso. Mismo orden de
	## redondeos que el HTML: primero el carisma, después la licencia.
	var fama := m.entrenamiento.factor_sueldo_dt() if m != null and m.entrenamiento != null else 1.0
	base = int(round(float(base) * fama))
	return int(round(float(base) * (1.0 + 0.05 * float(licencia))))
