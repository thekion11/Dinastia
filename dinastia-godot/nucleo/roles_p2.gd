extends "res://nucleo/roles_p1.gd"
## (Parte 2 de 5 de `roles.gd`.)

func jefe_confianza() -> int:
	return int(dt_empleado.get("confianza", JEFE_CONFIANZA_INICIAL))

# ---------------------------------------------------------------------------
# EL ENTRENADOR EMPLEADO (y el jefe, que es el mismo con otro sombrero)
# ---------------------------------------------------------------------------

func dt_nombre() -> String:
	return String(dt_empleado.get("nombre", "—"))

func jefe_nombre() -> String:
	return dt_nombre()

## Meterse en su trabajo desgasta la relación: mandar tiene un precio. Lo llama
## quien aplique una directriz.
func desgastar_relacion() -> void:
	if dt_empleado.is_empty():
		return
	if es_ayudante():
		dt_empleado["confianza"] = clampi(jefe_confianza() - 1, 0, 100)
		if jefe_confianza() < 20 and Azar.suerte(0.3):
			aviso.emit("Tu jefe te corta",
				"%s te recuerda delante del grupo quién arma el equipo. Conviene bajar el perfil una temporada." % jefe_nombre())
	else:
		dt_empleado["sintonia"] = clampi(int(dt_empleado.get("sintonia", 60)) - 2, 0, 100)
		if int(dt_empleado["sintonia"]) < 25 and Azar.suerte(0.35):
			aviso.emit("Tu entrenador está incómodo",
				"%s dejó caer en rueda de prensa que «cada uno debería ocuparse de lo suyo». La relación se está deteriorando." % dt_nombre())

## Cambiar una directriz.
##
## `dt_obedece()` y `desgastar_relacion()` ya estaban portadas más abajo en este
## mismo archivo -sistema escrito antes y todavía sin pantalla-, así que aquí
## solo se guarda la decisión y se llama a la que ya existía. El texto de queja
## sale por la señal `aviso`, que la pantalla ya escucha.
func fijar_directriz(clave: String, valor: Variant) -> void:
	directrices[clave] = valor
	desgastar_relacion()

## Cuánto caso te hace el que dirige.
##
## Con poca sintonía hace lo que le da la gana, y ese es el precio de no estar en
## el banco. Como ayudante te hace bastante menos caso todavía: tú propones, no
## ordenas, y la escala depende de lo que tu jefe confíe en ti.
func dt_obedece() -> bool:
	if dt_empleado.is_empty():
		return false
	if es_ayudante():
		return Azar.f() * 100.0 < 10.0 + float(jefe_confianza()) * 0.55
	return Azar.f() * 100.0 < 30.0 + float(dt_empleado.get("sintonia", 60)) * 0.7

func _meter_canterano(c: Club) -> void:
	var once := c.once()
	if once.size() < 11:
		return
	var joven: Jugador = null
	for j in c.disponibles():
		if j.edad <= 20 and not once.has(j) and (joven == null or j.ovr > joven.ovr):
			joven = j
	if joven == null:
		return
	## Sale el más flojo, pero nunca el portero: cambiar de arquero por dar
	## minutos a un chico es otra decisión, y bastante más gorda.
	var fuera: Jugador = null
	for j in once:
		if not j.es_portero() and (fuera == null or j.ovr < fuera.ovr):
			fuera = j
	if fuera == null:
		return
	var nuevo := once.duplicate()
	nuevo[nuevo.find(fuera)] = joven
	c.fijar_once(nuevo)

func _rotar_cansado(c: Club) -> void:
	var once := c.once()
	if once.size() < 11:
		return
	var cansado: Jugador = null
	for j in once:
		if not j.es_portero() and j.fisico < 70:
			cansado = j
			break
	if cansado == null:
		return
	var fresco: Jugador = null
	for j in c.disponibles():
		if not once.has(j) and j.fisico > 85 and (fresco == null or j.ovr > fresco.ovr):
			fresco = j
	if fresco == null:
		return
	var nuevo := once.duplicate()
	nuevo[nuevo.find(cansado)] = fresco
	c.fijar_once(nuevo)

## Aplica al club lo que el entrenador decide, con tus indicaciones si te hace
## caso. Se llama antes de jugar cuando el banco no es tuyo.
func aplicar_directrices(c: Club) -> void:
	if dt_empleado.is_empty() or c == null:
		return
	var estilo := String(directrices.get("estilo", "equilibrio"))
	if estilo != "equilibrio" and dt_obedece():
		if estilo == "ofensivo":
			c.tactica.mentalidad = Tactica.Mentalidad.OFENSIVA
			c.tactica.formacion = "3-4-3"
		elif estilo == "defensivo":
			c.tactica.mentalidad = Tactica.Mentalidad.DEFENSIVA
			c.tactica.formacion = "5-3-2"
	## Las tres que tocan la LISTA, no el dibujo. Se arma el once desde cero y
	## se sustituye a mano: es lo que hace el HTML, y así el cambio se nota.
	if bool(directrices.get("cantera", false)) and dt_obedece():
		_meter_canterano(c)
	if bool(directrices.get("rotacion", false)) and dt_obedece():
		_rotar_cansado(c)

func _al_cambiar_reputacion(t: String, x: String) -> void:
	aviso.emit(t, x)

func _init(mundo: Mundo) -> void:
	## Método y no función anónima: la lambda guardaba a `self` dentro de la
	## señal de `reputacion` (que es nuestra) y el ciclo Roles ↔ Reputacion no
	## se liberaba nunca (fuga al cerrar, etapa 1, 8-10-2026).
	reputacion.cambio.connect(_al_cambiar_reputacion)
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo

# ---------------------------------------------------------------------------
# EL MENÚ: de tarjeta a rol
# ---------------------------------------------------------------------------

## Las tarjetas del menú que llevan a una carrera de verdad, con su rol.
## Sale de MODOS_JUEGO, la tabla que ya trae el HTML: escribir la lista otra vez
## aquí garantizaría que un día el menú ofrezca un modo que el rol no conoce.
static func modos_con_rol() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var t: Variant = Datos.tabla("MODOS_JUEGO")
	if t == null:
		return salida
	for m: Dictionary in t:
		if String(m.get("rol", "")) != "":
			salida.append(m)
	return salida

## El rol al que lleva una tarjeta del menú, o "" si esa tarjeta no es una
## carrera (los retos y el tutorial no lo son).
static func rol_de_modo(modo_id: String) -> String:
	var t: Variant = Datos.tabla("MODOS_JUEGO")
	if t == null:
		return ""
	for m: Dictionary in t:
		if String(m.get("id", "")) == modo_id:
			return String(m.get("rol", ""))
	return ""

## Escribe una fila coherente en la tabla: los partidos ganados, empatados y
## perdidos tienen que sumar los jugados y dar los puntos que se le ponen, o la
## pantalla de clasificación enseña una fila imposible.
func _anotar_fila(l: Liga, c: Club, pj: int, pts: int, gf: int, gc: int) -> void:
	var g := mini(pj, pts / 3)
	var e := mini(pj - g, pts - g * 3)
	var p := maxi(0, pj - g - e)
	l.tabla_puntos[c.id] = {
		"pts": g * 3 + e, "pj": pj, "gf": gf, "gc": gc, "g": g, "e": e, "p": p,
	}

## Rellena la tabla como si la temporada estuviera a cinco fechas del final y tú
## fueras el que se va a Segunda.
##
## Primero la liga y DESPUÉS tú, en ese orden: hay que mirar cuántos puntos tiene
## el antepenúltimo para ponerte por debajo. Al revés te quedabas en descenso solo
## de casualidad, y el modo prometía una cosa y planteaba otra.
func _montar_liga_hundida(l: Liga, mio: Club) -> void:
	l.jornada_actual = maxi(0, l.jornadas() - FECHAS_INTERINATO)
	var pj := l.jornada_actual
	var rivales: Array[int] = []
	for c: Club in l.clubes:
		if c == mio:
			continue
		var base := int(round(22.0 + float(c.rep - 60) * 1.4))
		var pts := mini(clampi(base + Azar.ent(-4, 6), 18, 58), pj * 3)
		_anotar_fila(l, c, pj, pts, Azar.ent(20, 44), Azar.ent(20, 40))
		rivales.append(pts)
	rivales.sort()
	## Los puntos del antepenúltimo: el listón que hay que superar para salvarse.
	var corte: int = rivales[mini(2, rivales.size() - 1)] if not rivales.is_empty() else 20
	_anotar_fila(l, mio, pj, maxi(6, corte - Azar.ent(3, 6)), 19, 44)

# ---------------------------------------------------------------------------

## Pisa el objetivo que la directiva acaba de fijar por reputación, guardando el
## que había.
##
## Guardarlo importa: cuando el modo especial termina —el ayudante hereda el
## banco, el interino cumple sus cinco fechas— hay que devolver el objetivo del
## club. Sin esto, un entrenador principal con quince años de carrera seguía
## teniendo escrito en pantalla "AYUDANTE: ganarte el banco", que ya se ganó.
func _fijar_objetivo(texto: String) -> void:
	var m := _mundo()
	if m == null or m.directiva == null or texto.is_empty():
		return
	if _objetivo_club.is_empty():
		_objetivo_club = m.directiva.objetivo
	m.directiva.objetivo = texto

## Llegas como bombero: te contratan para las últimas cinco fechas con un solo
## objetivo. Ni fichajes ni proyecto, solo motivación y urgencia táctica.
##
## Elige el club él mismo —"el club te lo elige el juego"— entre los cinco peores
## de la primera división del país, y le monta una temporada hundida: sin eso el
## modo se jugaba como una carrera normal empezada tarde, que es exactamente lo
## que le pasaba al HTML antes de cerrarle el mercado.
func arrancar_interinato(pais: String = "CHI") -> void:
	var m := _mundo()
	if m == null:
		return
	var candidatos: Array[Club] = []
	for c: Club in m.clubes.values():
		if c.pais == pais and c.division == 1:
			candidatos.append(c)
	if candidatos.is_empty():
		return
	candidatos.sort_custom(func(a: Club, b: Club) -> bool: return a.rep < b.rep)
	var club: Club = candidatos[Azar.ent(0, mini(4, candidatos.size() - 1))]

	m.tomar_el_mando(club.id)
	rol = DT   ## el interino DIRIGE: lo suyo es el banquillo, no el despacho
	interino = {"cumplido": false, "salvado": false, "desde_jornada": 0}
	sandbox = false
	club.saldo = int(round(Eco.ref_caja(float(club.rep)) * 0.18))

	var l := m.liga_de(club)
	if l != null:
		_montar_liga_hundida(l, club)
		interino["desde_jornada"] = l.jornada_actual
		## La semana del almanaque se pone a la par de la jornada: si no, el
		## calendario y la tabla contarían dos historias distintas, y el mercado
		## —que abre por número de semana— creería que estamos en pretemporada.
		m.semana = l.jornada_actual + 1

	## El vestuario llega hundido. Es la mitad del modo: un plantel con la moral
	## por los suelos rinde por debajo de su media, así que salvarlo no es
	## cuestión de dibujar otro 4-4-2.
	for j in club.plantilla:
		j.moral = Azar.ent(14, 32)
		j.forma = clampi(j.forma - Azar.ent(6, 14), 20, 99)

	_fijar_objetivo("INTERINATO: salvar al club del descenso en %d fechas" % FECHAS_INTERINATO)
	if m.directiva != null:
		## Salvarse es no acabar en los dos últimos, que son los dos que bajan.
		m.directiva.meta_puesto = maxi(1, l.clubes.size() - 2) if l != null else 14
		m.directiva.mover_confianza(28 - m.directiva.confianza, "llegas con el incendio declarado")
	rol_cambiado.emit("", rol)
	aviso.emit("Te llaman para apagar el incendio",
		"%s está en zona de descenso a cinco fechas del final. Echaron al técnico y te firman solo hasta el último partido. %s" % [
			club.nombre,
			"No hay mercado, no hay proyecto y el vestuario está hundido: tienes cinco partidos para salvarlos. Si lo consigues, te lloverán las ofertas."])

## Nombre de persona con el mismo reparto que el HTML: tres de cada diez son
## extranjeros. Se limpia el leetspeak porque las tablas lo llevan.
func _nombre_de_persona() -> String:
	var extranjero := Azar.suerte(0.3)
	var n: Variant = Datos.tabla("NOMBRES_EXT" if extranjero else "NOMBRES")
	var a: Variant = Datos.tabla("APELLIDOS_EXT" if extranjero else "APELLIDOS")
	if n == null or a == null or (n as Array).is_empty() or (a as Array).is_empty():
		return "Míster"
	return Nombres.limpiar("%s %s" % [Azar.uno(n), Azar.uno(a)])

func _contratar_dt_empleado() -> void:
	var estilos: Array = ["ofensivo", "defensivo", "motivador", "pizarron"]
	var t: Variant = Datos.tabla("DT_ESTILOS")
	if t != null and not (t as Dictionary).is_empty():
		estilos = (t as Dictionary).keys()
	dt_empleado = {
		"nombre": _nombre_de_persona(),
		"estilo": String(Azar.uno(estilos)),
		## La sintonía arranca a 60: te hace caso más veces que no, pero no
		## siempre. Un empleado que obedece siempre no es un personaje, es un
		## mando a distancia.
		"sintonia": 60,
	}

## Empiezas abajo, de ayudante de un entrenador jefe. No fichas, no vendes y no
## pones el once: lo tuyo son los entrenamientos, el camarín y la cantera, y tu
## carrera consiste en ganarte el banco que ocupa otro.
func arrancar_ayudante() -> void:
	var m := _mundo()
	rol = AYUDANTE
	_contratar_dt_empleado()
	## El jefe ES el entrenador empleado: el mismo diccionario, no una copia. Así
	## el motor de partido sigue leyendo `dt_empleado` sin enterarse de que quien
	## está en el banco además te puede echar.
	dt_empleado["confianza"] = JEFE_CONFIANZA_INICIAL
	dt_empleado["malos"] = 0
	ayudante = {"desde": m.anio if m != null else 0, "ascendido": false}
	_fijar_objetivo("AYUDANTE: ganarte el banco")
	var club := m.mi_club().nombre if m != null and m.mi_club() != null else "el club"
	aviso.emit("Ayudante de campo",
		"Entras al cuerpo técnico de %s como ayudante de %s. No fichas, no vendes y no pones el once: eso es cosa suya. %s" % [
			club, jefe_nombre(),
			"Lo tuyo son los entrenamientos, el camarín y la cantera. Si te ganas su confianza y el equipo responde, el banco acabará siendo tuyo."])

## Solo la cantera: captas chicos, los formas y decides cuándo están listos. El
## primer equipo no es tuyo, y por eso el club te recorta la caja: tu presupuesto
## es el de una academia, no el de un plantel profesional.
func arrancar_cantera() -> void:
	var m := _mundo()
	rol = CANTERA
	_contratar_dt_empleado()
	var meta := Azar.ent(3, 5)
	cantera = {"meta": meta, "subidos": [], "anio_inicio": m.anio if m != null else 0, "total": 0}
	if m != null and m.mi_club() != null:
		m.mi_club().saldo = int(round(float(m.mi_club().saldo) * 0.35))
	_fijar_objetivo("CANTERA: subir %d juveniles al primer equipo esta temporada" % meta)
	aviso.emit("Director de cantera",
		"No diriges al primer equipo: eso es cosa de %s. Tu trabajo es captar chicos, elegir su plan de trabajo, cuidarles la cabeza y decidir cuándo están listos. El club te pide %d debutantes esta temporada." % [
			dt_nombre(), meta])

static func _modo(modo_id: String) -> Dictionary:
	var t: Variant = Datos.tabla("MODOS_JUEGO")
	if t == null:
		return {}
	for m: Dictionary in t:
		if String(m.get("id", "")) == modo_id:
			return m
	return {}

func _arrancar_sandbox() -> void:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return
	sandbox = true
	var caja: Variant = Datos.tabla("CAJA_JEQUE")
	var tope := int(caja) if caja != null else 999999999
	m.mi_club().saldo = tope
	aviso.emit("Modo jeque",
		"Un fondo soberano compra el club y te pone al frente sin límite de gasto. " +
		"No hay excusas: con esta caja, lo que salga mal es cosa tuya.")

# ---------------------------------------------------------------------------
# ARRANQUE: el `rolSel` del HTML aplicado sobre una partida ya generada
# ---------------------------------------------------------------------------

## Monta el modo elegido en el menú. `modo_id` es el id de MODOS_JUEGO
## ("dt", "dir", "ayudante", "interino", "cantera", "imperio", "jeque"...).
##
## OJO CON EL ORDEN: esto va DESPUÉS de `Mundo.tomar_el_mando()`, porque varios
## modos pisan el objetivo, la confianza y la caja que la directiva acaba de
## fijar. Es exactamente el fallo que el HTML pagó con el modo jeque: ponía los
## 999.999.999 al crear la partida y la función que elegía club los sobrescribía
## acto seguido con el presupuesto real, así que el modo se anunciaba con un
## aviso y no hacía absolutamente nada. El interinato es la única excepción: elige
## club él mismo, así que se llama ANTES de tomar el mando (lo hace por dentro).
func arrancar(modo_id: String, dt_nombre: String = "Míster") -> void:
	nombre = dt_nombre
	var destino := rol_de_modo(modo_id)
	if destino == "":
		destino = DT
	if modo_id == MODO_INTERINO:
		arrancar_interinato()
		return
	rol = destino
	## Si no diriges tú, hay alguien que dirige. Es la línea del HTML que evita
	## el estado imposible "nadie pone el once".
	if rol != DT:
		_contratar_dt_empleado()
	if modo_id == AYUDANTE:
		arrancar_ayudante()
	elif modo_id == CANTERA:
		arrancar_cantera()
	elif bool(_modo(modo_id).get("sandbox", false)):
		_arrancar_sandbox()
	rol_cambiado.emit("", rol)

func en_interinato() -> bool:
	return not interino.is_empty() and not bool(interino.get("cumplido", false))

## El modo de menú que corresponde al rol de ahora -el camino inverso de
## `rol_de_modo()`-. Lo usa el tutorial al repetirse desde Ajustes, cuando el
## modo con el que se empezó la carrera ya no está en ninguna parte.
func modo_actual() -> String:
	if en_interinato():
		return MODO_INTERINO
	match rol:
		DIR: return "dir"
		AYUDANTE: return "ayudante"
		CANTERA: return "cantera"
		DUENO: return "jeque" if sandbox else "imperio"
	return "dt"

# ---------------------------------------------------------------------------
# PERMISOS: lo único que la interfaz necesita preguntar
# ---------------------------------------------------------------------------

func _permiso(clave: String) -> bool:
	var p: Dictionary = PERMISOS.get(rol, PERMISOS[DT])
	return bool(p.get(clave, false))

## El once no lo pones tú. Es el `mando()` del HTML, con su nombre y su rareza:
## agrupa al despacho con el ayudante porque comparten la consecuencia.
func manda() -> bool:
	return _permiso("manda")

func es_cantera() -> bool:
	return rol == CANTERA

## Cómo se llama tu puesto, para los textos de pantalla.
func nombre_del_cargo() -> String:
	var p: Dictionary = PERMISOS.get(rol, PERMISOS[DT])
	if en_interinato():
		return "entrenador interino"
	return String(p.get("cargo", "entrenador"))

## Por qué está cerrado el mercado, o "" si no lo está por culpa del rol.
## Devuelve la misma clave que el HTML ("interinato" / "ayudante") para que se
## pueda comprobar igual desde el banco de pruebas.
func mercado_bloqueado() -> String:
	if en_interinato():
		return "interinato"
	if es_ayudante():
		return "ayudante"
	return ""

## La ventana de pases: semanas 1 a 6 y 18 a 24. Es del calendario, no del rol,
## pero vive aquí porque es la otra mitad de la respuesta a "¿puedo fichar?".
func ventana_abierta() -> bool:
	var m := _mundo()
	if m == null:
		return false
	return m.semana <= 6 or (m.semana >= 18 and m.semana <= 24)
