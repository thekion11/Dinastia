extends "res://nucleo/logros_p1.gd"
## (Parte 2 de 3 de `logros.gd`.)

# ---------------------------------------------------------------------------
#  LOS VEINTE LOGROS
# ---------------------------------------------------------------------------

## Las condiciones que el JSON no pudo traer.
##
## Van en un `match` y no en un diccionario de `Callable`, que sería la
## traducción literal del array de funciones del HTML, por dos razones: un
## `Callable` que llama a un método propio se queda con una referencia a este
## objeto, y este objeto se queda con el diccionario, así que el contador de
## referencias nunca llega a cero y la memoria del club no se libera nunca. Y
## además un `match` sale en la traza cuando algo falla, y una lambda anónima no.
func _cumple(clave: String) -> bool:
	if mundo == null:
		return false
	var c := mundo.mi_club()
	if c == null:
		return false
	var trofeos: Array = []
	if mundo.directiva != null:
		trofeos = mundo.directiva.trofeos

	match clave:
		"primer": return trofeos.size() >= 1
		"diez": return trofeos.size() >= 10
		"veinte": return trofeos.size() >= 20
		"conti": return _algun_trofeo(trofeos, ["Libertador", "Sudamer", "Champ", "Europ"])
		"mundoclub": return _algun_trofeo(trofeos, ["Mundial de Clubes"])
		"salvador": return _algun_trofeo(trofeos, ["Permanencia"])
		"invicto": return int(rachas["invicto_max"]) >= 20
		"goleada": return rec.has("mayor_goleada") and int(rec["mayor_goleada"]["dif"]) >= 6
		"cantera": return canteranos_debutados.size() >= 15
		"estadio": return c.estadio_aforo >= 60000
		"querido": return c.confianza >= 95
		"millon": return float(c.saldo) * Eco.ECO >= 100000000.0
		## "Manos limpias" pide diez temporadas sin un solo pago turbio. Los
		## sobornos todavía no están portados, así que no hay forma de
		## ensuciarse: aguantar diez años basta. El día que entren, la condición
		## solo tiene que sumar el "y sin pagos turbios" que le falta.
		"limpio": return mundo.anio - anio_inicio >= 10
	return false

func _cumple_oculto(clave: String) -> bool:
	var c := mundo.mi_club()
	if c == null:
		return false
	match clave:
		"centenario":
			return mundo.roles != null and mundo.roles.trofeos.size() >= 100
		"mecenas":
			## Diez inyecciones de capital. `Roles` cuenta las de la temporada;
			## el total acumulado lo lleva `_inyecciones_totales`, que se añadió
			## para esto: sin él el logro solo podría caer dentro de un mismo año.
			return mundo.roles != null and mundo.roles.inyecciones_totales >= 10
		"imperio":
			return mundo.obras != null and mundo.obras.todo_al_maximo()
		"sabio":
			return mundo.entrenamiento != null and mundo.entrenamiento.mentorias.size() >= 4
		"cantera11":
			## Once canteranos a la vez. Se mira el once REAL, no la plantilla:
			## tener once de la casa en la lista no es alinearlos.
			var once := c.once()
			if once.size() < 11 or mundo.cantera == null:
				return false
			for j: Jugador in once:
				if not mundo.cantera.es_canterano(j):
					return false
			return true
		"idolos":
			var n := 0
			for j in c.plantilla:
				if j.partidos >= 60 and j.moral >= 80:
					n += 1
			return n >= 5
		"invicto":
			## Temporada invicta: se lee de las rachas, que ya cuentan el invicto
			## máximo del año.
			var l := mundo.liga_de(c)
			return l != null and not l.quedan_jornadas() and int(rachas.get("invicto", 0)) >= l.jornadas()
		"remontada":
			return bool(marcas.get("remontada", false))
	return false

func revisar_ocultos() -> Array[String]:
	var nuevos: Array[String] = []
	var tabla: Variant = Datos.tabla("LOGROS_OCULTOS")
	if not (tabla is Array) or mundo == null:
		return nuevos
	for fila: Array in tabla:
		var clave := String(fila[0])
		if ocultos.has(clave) or not _cumple_oculto(clave):
			continue
		ocultos[clave] = mundo.anio
		nuevos.append(clave)
		logro_desbloqueado.emit(clave, "🎖️", String(fila[1]), String(fila[2]))
	return nuevos

## Repasa los veinte y devuelve las claves que acaban de caer.
##
## Cada logro da UN PUNTO del árbol de habilidades del entrenador, igual que en
## el HTML. Esa línea llevaba desde el porte esperando a que el árbol existiera
## -el comentario de aquí decía literalmente "cuando lo esté, el sitio donde
## sumarlo es justo aquí"-; ya existe, así que ya suma. Es lo que convierte los
## logros en progreso y no en una lista de cromos.
func revisar() -> Array[String]:
	var nuevos: Array[String] = []
	var tabla: Variant = Datos.tabla("LOGROS")
	if tabla == null:
		return nuevos
	for fila: Array in tabla:
		var clave := String(fila[0])
		if desbloqueados.has(clave):
			continue
		if not _cumple(clave):
			continue
		desbloqueados[clave] = {"anio": mundo.anio, "semana": mundo.semana}
		nuevos.append(clave)
		if mundo != null and mundo.entrenamiento != null:
			mundo.entrenamiento.dt_sumar_puntos(1)
		logro_desbloqueado.emit(clave, String(fila[1]), String(fila[2]), String(fila[3]))
	nuevos.append_array(revisar_ocultos())
	return nuevos

## Se llama al terminar cada partido de tu club. Alimenta cara a cara, rachas,
## récords, goleadores históricos y debuts de cantera, y de paso revisa si algo
## de eso acaba de desbloquear un logro.
##
## `publico` lo pone quien lo sepa (`Finanzas.asistencia()`); a cero no se anota
## récord de asistencia, que es mejor que anotar uno inventado.
func tras_partido(p: Partido, competicion: String = "Liga", publico: int = 0, por_penales: bool = false) -> void:
	if mundo == null or p == null:
		return
	var mio := mundo.mi_club()
	if mio == null:
		return
	var soy_local := p.local == mio
	if not soy_local and p.visita != mio:
		return   ## no es mi partido: la memoria es la del club que diriges

	_anotar_plantilla_inicial()
	var rival: Club = p.visita if soy_local else p.local
	var mis_goles := p.goles_local if soy_local else p.goles_visita
	var sus_goles := p.goles_visita if soy_local else p.goles_local
	var gane := mis_goles > sus_goles
	var empate := mis_goles == sus_goles
	if gane and p.hubo_remontada_de(mio):
		marcar("remontada")

	_anotar_cara_a_cara(rival, mis_goles, sus_goles, gane, empate)
	_anotar_rachas(gane, empate)
	_anotar_records(rival, mis_goles, sus_goles, competicion, publico)
	_anotar_participaciones(p, soy_local)

	var dif := mis_goles - sus_goles
	if absi(dif) >= DIF_EFEMERIDE or (por_penales and not empate):
		var texto := ""
		if dif > 0:
			texto = "Goleada %d-%d a %s" % [mis_goles, sus_goles, rival.nombre]
		else:
			texto = "Paliza %d-%d de %s" % [sus_goles, mis_goles, rival.nombre]
		_apuntar_efemeride(texto)

	revisar()

## Levantar un título. Es lo más caro del perfil de gestor y lo único que llena
## la vitrina, y además se NOTA en el club: la hinchada se vuelca, llegan socios
## nuevos y el vestuario se pone a tope de moral.
##
## Esos tres efectos no son adorno. En el HTML son lo que hace que el año
## siguiente a un título se juegue distinto: más gente en el estadio, más cuotas
## y una plantilla que rinde. Un título que solo añade una línea a una lista es
## una pantalla, no un premio.
func celebrar_titulo(nombre: String) -> void:
	if mundo == null:
		return
	var c := mundo.mi_club()
	if c == null:
		return
	sumar_xp(XP_TITULO)
	titulo_celebrado.emit(nombre)

	var once := c.plantilla.duplicate()
	once.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	var nombres: Array[String] = []
	for j in once.slice(0, 11):
		nombres.append(Nombres.visible(j.nombre))
	muro.append({"anio": mundo.anio, "titulo": nombre, "once": nombres})

	c.confianza = clampi(c.confianza + Azar.ent(8, 16), 0, 100)
	c.socios += Azar.ent(600, 2200)
	for j in c.plantilla:
		j.moral = 99

	var total := mundo.directiva.trofeos.size() if mundo.directiva != null else muro.size()
	if total > 0 and total % 10 == 0:
		_apuntar_efemeride("El club coloca una placa en el acceso principal por los %d títulos de tu era" % total)
	var anios := mundo.anio - anio_inicio
	if anios > 0 and anios % 5 == 0:
		_apuntar_efemeride("Se cumplen %d años de tu llegada: gala con las leyendas de la casa y lleno absoluto" % anios)

	revisar()

## Los ocultos con su estado, para la pantalla. Los que no han caído salen sin
## título ni descripción: enseñarlos delataría lo que hay que hacer.
func catalogo_oculto() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var tabla: Variant = Datos.tabla("LOGROS_OCULTOS")
	if not (tabla is Array):
		return salida
	for fila: Array in tabla:
		var clave := String(fila[0])
		var caido := ocultos.has(clave)
		salida.append({
			"clave": clave,
			"titulo": String(fila[1]) if caido else "???",
			"descripcion": String(fila[2]) if caido else "Sigue jugando.",
			"conseguido": caido,
			"anio": int(ocultos.get(clave, 0)),
		})
	return salida

func conseguido(clave: String) -> bool:
	return desbloqueados.has(clave)

func cuantos() -> int:
	return desbloqueados.size()

## Los veinte con su estado, listos para pintar una pantalla de logros sin que
## la interfaz tenga que saber nada de tablas ni de condiciones.
func catalogo() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var tabla: Variant = Datos.tabla("LOGROS")
	if tabla == null:
		return salida
	for fila: Array in tabla:
		var clave := String(fila[0])
		salida.append({
			"clave": clave,
			"icono": String(fila[1]),
			"titulo": String(fila[2]),
			"descripcion": String(fila[3]),
			"conseguido": desbloqueados.has(clave),
			"cuando": desbloqueados.get(clave, {}),
			"pendiente": SIN_SISTEMA.has(clave),
		})
	return salida

## LA NOTA DE LA TEMPORADA, Y LO QUE HAY QUE CAMBIAR CUANDO SE PORTEN LAS NOTAS.
##
## En el HTML cada jugador acumula un `ratingTemp`: un array con la nota que sacó
## en cada partido, y la gala ordena por su promedio. Ese sistema todavía no está
## portado a Godot, así que aquí se ordena con lo único que sí existe hoy —los
## partidos jugados, los goles y la media—, y eso tiene un sesgo que conviene
## tener presente: premia al delantero y deja al central y al portero ordenados
## solo por su media, que es la nota que traían de casa y no lo que hicieron
## este año.
##
## Cuando se porten las notas por partido, este método es el ÚNICO sitio que hay
## que tocar: se sustituye el cuerpo por el promedio del array de notas (con el
## mismo mínimo de ocho) y toda la gala pasa a ordenarse bien sola, porque nadie
## más mira los goles. No hay que inventar mientras tanto un sistema de notas
## paralelo: serían dos criterios distintos conviviendo y el día de la mudanza
## habría que decidir cuál gana.
func _nota_de_temporada(j: Jugador) -> float:
	if j.partidos < PARTIDOS_MINIMOS:
		return 0.0
	return float(j.ovr) + 1.5 * float(j.goles)

func _nombre_club(id: String) -> String:
	var c: Club = mundo.clubes.get(id)
	return c.nombre if c != null else "—"

func _mayor_aforo(grandes: Array[Club], mio: Club) -> String:
	var mejor: Club = null
	for c in grandes:
		if c == mio:
			continue
		if mejor == null or c.estadio_aforo > mejor.estadio_aforo:
			mejor = c
	return mejor.nombre if mejor != null else "—"

## La foto de la plantilla del año, con el puesto y el mejor de los tuyos. Es lo
## que hace que dentro de quince temporadas se pueda mirar atrás y reconocer al
## equipo del primer ascenso.
func _archivar_plantel(puesto: int) -> void:
	var mio := mundo.mi_club()
	if mio == null:
		return
	var mvp: Jugador = null
	var mvp_nota := -1.0
	var lista: Array = []
	for j in mio.plantilla:
		var n := _nota_de_temporada(j)
		if n > mvp_nota:
			mvp_nota = n
			mvp = j
		## LA FOTO COMPLETA, no solo el nombre. Antes se guardaba la cadena
		## "Fulano (78)" y con eso no se podia enseñar el plantel de aquel año:
		## ni el dorsal, ni el puesto, ni lo que jugó, ni lo que hizo. Era una
		## memoria que no se podia consultar.
		lista.append({
			"n": Nombres.visible(j.nombre), "ovr": j.ovr, "pos": j.pos_e,
			"d": j.dorsal, "pj": j.partidos, "g": j.goles, "edad": j.edad,
		})
	planteles.append({
		"anio": mundo.anio, "puesto": puesto,
		"mvp": Nombres.visible(mvp.nombre) if mvp != null else "",
		"jugadores": lista,
	})
	while planteles.size() > MAX_PLANTELES:
		planteles.pop_front()
