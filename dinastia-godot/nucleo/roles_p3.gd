extends "res://nucleo/roles_p2.gd"
## [Capa 3/5 de `roles.gd`] emergencia_activa, puede_fichar, puede_alinear, puede_contratar_staff, puede_construir, puede_vender_jugadores … (+26)

func emergencia_activa() -> bool:
	var m := _mundo()
	if m == null or emergencia.is_empty():
		return false
	return int(emergencia.get("anio", -1)) == m.anio \
		and not bool(emergencia.get("usada", false)) \
		and m.semana <= int(emergencia.get("hasta", 0))

## ¿Puedo fichar AHORA MISMO? Tres cosas a la vez, y las tres tienen que darse:
## que el rol te lo permita, que el mercado esté abierto (o tengas el permiso de
## emergencia) y que el modo no lo tenga cerrado por decreto.
func puede_fichar() -> bool:
	if not _permiso("fichar"):
		return false
	if mercado_bloqueado() != "":
		return false
	return ventana_abierta() or emergencia_activa()

## Poner el once y tocar el pizarrón. Falso para todo el que no dirige: es la
## incoherencia que el HTML arrastró durante versiones (el director de cantera
## armaba la alineación del primer equipo).
func puede_alinear() -> bool:
	return _permiso("alinear")

func puede_contratar_staff() -> bool:
	return _permiso("staff")

func puede_construir() -> bool:
	return _permiso("construir")

func puede_vender_jugadores() -> bool:
	return _permiso("vender_jugadores") and mercado_bloqueado() == ""

func puede_rescindir() -> bool:
	return _permiso("rescindir")

## Contratar y echar al entrenador empleado. El director deportivo manda en el
## despacho, y mandar en el despacho es, sobre todo, elegir quién se sienta en el
## banco.
func puede_contratar_dt() -> bool:
	return _permiso("contratar_dt")

func puede_inyectar_capital() -> bool:
	return _permiso("capital")

func puede_vender_club() -> bool:
	return _permiso("vender_club")

## ¿Te puede echar el directorio? Al dueño no hay quien lo eche —el club es
## suyo—, al ayudante lo juzga su jefe y no el directorio, y al interino no,
## porque su contrato ya trae fecha de término escrita.
##
## Quien conecte `Directiva.despedido` tiene que preguntar esto ANTES de actuar:
## la directiva sigue contando la confianza para todos, es este permiso el que
## decide si esa cuenta tiene consecuencias.
func le_pueden_echar() -> bool:
	if en_interinato():
		return false
	return _permiso("lo_echan")

## La frase que explica por qué el botón está apagado. Un botón gris sin motivo
## se lee como un fallo del juego.
func motivo_bloqueo(accion: String) -> String:
	match accion:
		"fichar":
			if en_interinato():
				return "Interinato: la ventana de pases está cerrada. Con estos te toca."
			if es_ayudante():
				return "Los fichajes no son cosa del ayudante de campo."
			if not _permiso("fichar"):
				return "Tu cargo no firma jugadores."
			if not ventana_abierta() and not emergencia_activa():
				return "Mercado cerrado: las ventanas son las semanas 1-6 y 18-24."
		"alinear":
			if es_ayudante():
				return "El once lo pone %s. Tú propones." % jefe_nombre()
			if manda():
				return "El once lo pone %s, que para eso es el entrenador." % dt_nombre()
		"vender_jugadores":
			if es_ayudante():
				return "Vender no es cosa del ayudante de campo."
			if mercado_bloqueado() != "":
				return "Con el mercado cerrado no se puede vender a nadie."
		"rescindir":
			if es_ayudante():
				return "Rescindir contratos no es cosa del ayudante de campo."
		"staff", "construir":
			if es_ayudante():
				return "El despacho no es tuyo: eso lo decide el club."
		"capital":
			return "Solo el dueño mete dinero de su bolsillo."
		"vender_club":
			return "No se vende lo que no es tuyo."
	return ""

# ---------------------------------------------------------------------------
# LA VENTANA DE EMERGENCIA
# ---------------------------------------------------------------------------

## La asociación te habilita a firmar UN libre con el mercado cerrado porque has
## perdido a un titular por una lesión larga. Una por temporada y una sola bala:
## quien lleve las lesiones llama aquí, y `puede_fichar()` se entera solo.
func abrir_emergencia(jugador_id: String) -> bool:
	var m := _mundo()
	if m == null or ventana_abierta():
		return false
	if int(emergencia.get("anio", -1)) == m.anio:
		return false
	emergencia = {"anio": m.anio, "hasta": m.semana + 3, "jugador_id": jugador_id, "usada": false}
	aviso.emit("Te abren una ventana de emergencia",
		"La asociación acepta el parte médico y te habilita a firmar UN jugador libre durante las próximas tres semanas, con el mercado cerrado para todos los demás. Es una sola bala: elige bien.")
	return true

## Se gasta al cerrar el traspaso, no al abrir la pantalla: la bala se consume
## cuando se dispara.
func usar_emergencia() -> void:
	if not ventana_abierta() and emergencia_activa():
		emergencia["usada"] = true
		aviso.emit("Ventana de emergencia consumida",
			"Usaste el permiso especial de la asociación. Hasta que se abra el mercado de verdad, no puedes fichar a nadie más.")

func estilo_dt() -> String:
	var e := String(dt_empleado.get("estilo", "motivador"))
	var t: Variant = Datos.tabla("DT_ESTILOS")
	if t == null:
		return e
	return String(t.get(e, e))

## Cambia de entrenador empleado. Devuelve "" si se hizo, o el motivo si no.
## Los métodos que gastan dinero devuelven el motivo en vez de un bool: así la
## pantalla puede decir cuánto falta en vez de un "no se puede" a secas.
func cambiar_dt() -> String:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return "no hay club"
	if not puede_contratar_dt():
		return "el banco no lo eliges tú"
	var c := m.mi_club()
	var coste := Eco.escalar(COSTE_CAMBIAR_DT, float(c.rep))
	if c.saldo < coste:
		return "finiquito y contrato: hacen falta %d y tienes %d" % [coste, c.saldo]
	c.mover_saldo(-coste)
	var viejo := dt_nombre()
	_contratar_dt_empleado()
	aviso.emit("Cambio en el banco",
		"Sale %s, asume %s (%s). La cancha dirá si fue buena idea." % [viejo, dt_nombre(), estilo_dt()])
	return ""

func sumar_prestigio(delta: int) -> void:
	prestigio = clampi(prestigio + delta, PRESTIGIO_MIN, PRESTIGIO_MAX)


# ---------------------------------------------------------------------------
# REPUTACIÓN POR FACETAS (26-9-2026)
# ---------------------------------------------------------------------------

## Anota un movimiento de reputación con la fecha de la partida.
func _rep(faceta: String, delta: int, motivo: String) -> void:
	var m := _mundo()
	reputacion.registrar(faceta, delta, motivo, m.anio if m != null else 0, m.semana if m != null else 0)

func _restaurar_objetivo() -> void:
	var m := _mundo()
	if m == null or m.directiva == null or _objetivo_club.is_empty():
		return
	m.directiva.objetivo = _objetivo_club
	_objetivo_club = ""

func _ascender_de_ayudante() -> void:
	var m := _mundo()
	var jefe := jefe_nombre()
	## Se conserva `ayudante` con la marca puesta en vez de borrarlo: el HTML lo
	## dejaba a null y entonces no había forma de distinguir "ascendió" de "nunca
	## fue ayudante". Se pregunta con `ayudante_ascendido()`.
	ayudante["ascendido"] = true
	var antes := rol
	rol = DT
	dt_empleado = {}
	sumar_prestigio(8)
	_restaurar_objetivo()   ## vuelve el objetivo que el club te pedía
	if m != null and m.directiva != null:
		m.directiva.mover_confianza(62 - m.directiva.confianza, "asciendes a entrenador principal")
	## El XP del perfil de gestor: "el día que dejas de ser el ayudante de
	## alguien". Lleva hito propio porque es un ÚNICO hito en la vida del
	## perfil, no algo que farmear ascendiendo en carrera tras carrera.
	if m != null and m.logros != null:
		m.logros.sumar_xp(Logros.XP_ASCENSO_AYUDANTE, "ascenso_ayudante")
	rol_cambiado.emit(antes, rol)
	ascenso.emit(rol)
	var club := m.mi_club().nombre if m != null and m.mi_club() != null else "el club"
	aviso.emit("El banco es tuyo",
		"%s deja el club y te recomienda como sucesor. El directorio acepta: pasas de ayudante a entrenador principal de %s. Ahora el once, la charla y los fichajes son cosa tuya." % [jefe, club])

func _echar_del_cuerpo_tecnico() -> void:
	var jefe := jefe_nombre()
	var antes := rol
	rol = DT
	ayudante = {}
	dt_empleado = {}
	sumar_prestigio(-3)
	sin_club = true
	rol_cambiado.emit(antes, rol)
	fuera_del_cuerpo_tecnico.emit(jefe)
	aviso.emit("Fuera del cuerpo técnico",
		"%s rehace su equipo de trabajo y tú no entras. Se acabó la etapa de ayudante: te toca buscar banco." % jefe)

# ---------------------------------------------------------------------------
# AYUDANTE: ganarte el banco de tu jefe
# ---------------------------------------------------------------------------

## El jefe te evalúa partido a partido: confía más si el equipo gana, menos si
## pierde. Con mucha confianza y prestigio propio, te acaba dejando el banco; con
## muy poca, te saca del cuerpo técnico.
##
## Las dos condiciones del ascenso son a propósito: solo con la confianza del
## jefe, un ayudante recién llegado heredaría el banco de un club grande sin
## haber hecho nada; solo con prestigio, lo heredaría alguien a quien su jefe no
## quiere ni ver.
func _chequeo_ayudante(gane: bool, empate: bool) -> void:
	if ayudante.is_empty() or dt_empleado.is_empty():
		return
	dt_empleado["confianza"] = clampi(jefe_confianza() + (3 if gane else (1 if empate else -2)), 0, 100)
	dt_empleado["malos"] = 0 if gane else (int(dt_empleado.get("malos", 0)) + (0 if empate else 1))
	if jefe_confianza() >= JEFE_ASCIENDE and prestigio >= PRESTIGIO_PARA_EL_BANCO \
			and not bool(ayudante.get("ascendido", false)):
		_ascender_de_ayudante()
		return
	if jefe_confianza() <= JEFE_ECHA:
		_echar_del_cuerpo_tecnico()

# ---------------------------------------------------------------------------
# EL PULSO DE LA CARRERA: partido, jornada y temporada
# ---------------------------------------------------------------------------

## Después de TU partido. Mueve el prestigio (±1, que es lo que lo mueve de
## verdad a lo largo de una carrera) y, si eres ayudante, pasa la cuenta a tu
## jefe, que es quien te juzga.
func tras_partido(goles_propios: int, goles_rival: int) -> void:
	var gane := goles_propios > goles_rival
	var empate := goles_propios == goles_rival
	sumar_prestigio(1 if gane else (0 if empate else -1))
	## Ganar de a muchos (o perder por goleada) también hace fama.
	var dif := goles_propios - goles_rival
	if absi(dif) >= 3:
		_rep("ganador", 2 if dif > 0 else -2, "Goleada %s %d-%d" % ["a favor" if dif > 0 else "en contra", goles_propios, goles_rival])
	var m0 := _mundo()
	if m0 != null:
		reputacion.revisar_nivel(m0.mi_club())
	if es_ayudante():
		_chequeo_ayudante(gane, empate)

# ---------------------------------------------------------------------------
# INTERINATO: cinco fechas
# ---------------------------------------------------------------------------

## Fechas que te quedan de contrato. Sale del calendario de la liga, no de un
## contador propio: un contador propio se desincroniza en cuanto alguien aplace
## una jornada, y entonces el modo dura seis partidos o cuatro.
func fechas_interinato_restantes() -> int:
	if not en_interinato():
		return 0
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return 0
	var l := m.liga_de(m.mi_club())
	if l == null:
		return 0
	return maxi(0, l.jornadas() - l.jornada_actual)

func _resolver_interinato() -> void:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return
	var l := m.liga_de(m.mi_club())
	if l == null:
		return
	var t := l.tabla()
	var puesto := 0
	for i in t.size():
		if t[i]["club"] == m.mi_club():
			puesto = i + 1
			break
	## Salvarse es no acabar en los dos últimos, que son los dos que descienden.
	var salvado := puesto > 0 and puesto <= t.size() - 2
	interino["cumplido"] = true
	interino["salvado"] = salvado
	if salvado:
		sumar_prestigio(14)
		trofeos.append({"anio": m.anio, "titulo": "Permanencia (interinato)"})
		if m.directiva != null:
			m.directiva.mover_confianza(92 - m.directiva.confianza, "salvaste al club")
		aviso.emit("Misión cumplida",
			"Salvaste al club del descenso en cinco fechas. La hinchada te saca en andas y el teléfono no para de sonar: tu prestigio se dispara y varios clubes te quieren para un proyecto de verdad.")
	else:
		sumar_prestigio(-4)
		if m.directiva != null:
			m.directiva.mover_confianza(30 - m.directiva.confianza, "el club descendió")
		aviso.emit("No alcanzó",
			"El club se fue a Ascenso. Nadie te culpa del todo —llegaste con el incendio declarado— pero el descenso queda en tu ficha.")
	## Se acabó el contrato de bombero: el objetivo vuelve a ser el del club. El
	## puesto que exige la directiva se queda como está a propósito —salvarse es
	## lo que se le pide a un club que venía de zona de descenso— y lo recoloca
	## el cierre de temporada, que es de quien es esa cuenta.
	_restaurar_objetivo()
	interinato_resuelto.emit(salvado)

## Después de cada jornada. Solo mira una cosa: si al interino se le acabaron las
## cinco fechas.
func tras_jornada() -> void:
	if en_interinato() and fechas_interinato_restantes() <= 0:
		_resolver_interinato()

## Lo que te falta para el siguiente escalón, en una frase. La escalera solo
## motiva si se ve el peldaño.
func siguiente_escalon() -> String:
	if not ASCENSOS.has(rol):
		return ""
	var puerta: Dictionary = ASCENSOS[rol]
	var faltan_t: int = maxi(0, int(puerta["trofeos"]) - trofeos.size())
	var faltan_p: int = maxi(0, int(puerta["prestigio"]) - prestigio)
	if faltan_t == 0 and faltan_p == 0:
		return "Puedes dar el salto a %s" % PERMISOS[puerta["a"]]["cargo"]
	return "Para llegar a %s: %d trofeo(s) y %d punto(s) de prestigio" % [
		PERMISOS[puerta["a"]]["cargo"], faltan_t, faltan_p]

## Todo lo que una pantalla necesita saber del rol, de una vez. Evita que la
## interfaz llame a doce métodos y se olvide del decimotercero.
func resumen() -> Dictionary:
	return {
		"rol": rol, "cargo": nombre_del_cargo(), "manda": manda(),
		"prestigio": prestigio, "trofeos": trofeos.size(), "temporadas": temporadas,
		"sin_club": sin_club,
		"mercado_bloqueado": mercado_bloqueado(),
		"puede_fichar": puede_fichar(), "puede_alinear": puede_alinear(),
		"puede_contratar_staff": puede_contratar_staff(), "puede_construir": puede_construir(),
		"le_pueden_echar": le_pueden_echar(),
		"dt_empleado": dt_nombre() if not dt_empleado.is_empty() else "",
		"jefe_confianza": jefe_confianza() if es_ayudante() else -1,
		"interinato": fechas_interinato_restantes(),
		"siguiente": siguiente_escalon(),
	}

## Lo que se anota al cerrar la temporada: seguir en el club (lealtad), los
## canteranos que tienes en el plantel (formador) y lo que el club hace por su
## comunidad (social). Y los socios que eso trae.
func _reputacion_de_temporada() -> void:
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return
	var c := m.mi_club()
	_rep("leal", 3, "Otra temporada en %s" % c.nombre)
	var canteranos := 0
	if m.cantera != null:
		for j: Jugador in c.plantilla:
			if m.cantera.es_canterano(j):
				canteranos += 1
	_rep("formador", clampi(canteranos - 2, -3, 6), "%d canteranos en el plantel" % canteranos)
	var social := 0
	if m.obras != null:
		for k: String in ["huerto", "guarderia", "bienestar"]:
			if m.obras.nivel(k) > 0:
				social += 1
	_rep("social", social * 2 - 1, "Lo que el club hace por su gente")
	var socios := reputacion.socios_por_temporada(c)
	if socios != 0:
		c.socios = maxi(0, c.socios + socios)

## Un título a la vitrina de la CARRERA. `Directiva.trofeos` se queda en el club
## que dejas; esta lista te sigue de club en club y es la que abre los ascensos.
func sumar_trofeo(titulo: String) -> void:
	var m := _mundo()
	trofeos.append({"anio": m.anio if m != null else 0, "titulo": titulo})
	_rep("ganador", 8, "Título: %s" % titulo)
	sumar_prestigio(3)
	## Al museo de todas tus carreras, y un sobre de cromos.
	Meta.registrar_trofeo(m, titulo)

func _chequeo_cantera() -> void:
	var m := _mundo()
	var subidos: Array = cantera.get("subidos", [])
	var meta := int(cantera.get("meta", 4))
	if subidos.size() >= meta:
		sumar_prestigio(8)
		if m != null and m.directiva != null:
			m.directiva.mover_confianza(18, "objetivo de cantera cumplido")
		aviso.emit("Objetivo de cantera cumplido",
			"Subiste %d juveniles al primer equipo (pedían %d). El club renueva tu proyecto formativo." % [subidos.size(), meta])
	else:
		if m != null and m.directiva != null:
			m.directiva.mover_confianza(-14, "objetivo de cantera incumplido")
		aviso.emit("Objetivo de cantera incumplido",
			"Solo %d debutantes de los %d comprometidos. El directorio pregunta para qué paga la academia." % [subidos.size(), meta])
	var nueva := Azar.ent(3, 5)
	cantera["meta"] = nueva
	cantera["subidos"] = []
	_fijar_objetivo("CANTERA: subir %d juveniles al primer equipo esta temporada" % nueva)

# ---------------------------------------------------------------------------
# ASCENSO DE ROL: del banquillo al despacho, del despacho a la propiedad
# ---------------------------------------------------------------------------

## El rol al que puedes subir ahora mismo, o "". El dueño no asciende: por encima
## de ser dueño del club no hay nada.
func puede_ascender() -> String:
	if not ASCENSOS.has(rol):
		return ""
	if es_ayudante() or en_interinato():
		return ""   ## esos dos tienen su propia salida, no esta escalera
	var puerta: Dictionary = ASCENSOS[rol]
	if trofeos.size() >= int(puerta["trofeos"]) and prestigio >= int(puerta["prestigio"]):
		return String(puerta["a"])
	return ""
