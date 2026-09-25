class_name Entrenamiento
extends RefCounted
## La semana de trabajo: el plan de entrenamiento, el árbol de habilidades de
## los jugadores y el del entrenador.
##
## En el HTML esto vivía en tres sitios que no se hablaban entre sí: el bloque
## de entrenamiento dentro de `procesoSemanal` (foco e intensidad), el plan por
## días de `procesoEntreno` (v2.0), y las funciones sueltas del árbol de
## habilidades. Los tres tocaban al mismo jugador la misma semana, así que aquí
## viajan juntos y en el MISMO ORDEN: primero la sesión general, después el plan
## por días, después el trabajo individual. Cambiar ese orden cambia los
## números, porque el físico que reparte uno es el que el siguiente descuenta.
##
## POR QUÉ LAS HABILIDADES VIVEN AQUÍ Y NO EN `Jugador`
## `jugador.gd` no se toca en esta migración, y aun pudiendo tocarlo tampoco
## convendría: las habilidades no son un dato del futbolista, son el resultado
## de un sistema —los puntos que reparte la temporada, los prerrequisitos, los
## planes individuales—. Se guardan indexadas por id, exactamente como
## `medico.gd` guarda sus fichas, y por la misma razón: que nadie pueda
## corromperlas sin pasar por esta puerta.
##
## LO QUE NO SE DUPLICA
## El riesgo de lesión por sobrecarga ya está portado en `Medico`
## (`riesgo_por_fatiga` / `chequeo_de_fatiga`), con la fórmula del HTML y su
## constante `CARGA_POR_DEFECTO = 6.0`, que es justo lo que suma el plan de seis
## días por defecto. Aquí se calcula la carga real del plan que haya elegido el
## entrenador (`carga_riesgo()`) y se le pasa al médico; rodar el dado por
## nuestra cuenta lesionaría al plantel dos veces por semana. Lo mismo con el
## ritmo del centro de entrenamiento (`Instalaciones.ritmo_de_progreso`) y con
## el aguante del preparador físico (`Staff.aguante`).

## Noticias de cara al jugador. Se emiten en vez de escribirlas en pantalla para
## que esta clase no conozca a la interfaz.
signal noticia(titulo: String, cuerpo: String)
## Un gasto que hay que anotar en la caja (concentración, pretemporada).
signal gasto(concepto: String, monto: int)
signal habilidad_aprendida(j: Jugador, clave: String, nombre: String)
signal progreso(j: Jugador, antes: int, ahora: int)
signal dt_habilidad(clave: String, nombre: String)
signal punto_dt_ganado(total: int)

# ---------------------------------------------------------------------------
#  LO QUE SE PUEDE ELEGIR
# ---------------------------------------------------------------------------

## Foco de la sesión general. Son los tres que el HTML consultaba de verdad:
## `recup` reparte más físico, `tecnico` multiplica el progreso de los jóvenes y
## `tactico` es el punto neutro. Un cuarto foco decorativo sería un botón que no
## mueve nada, que es el error que este proyecto ya pagó varias veces.
const FOCOS := {
	"tactico": ["Táctico", "Bloque y movimientos: el trabajo de siempre"],
	"tecnico": ["Técnico", "Los menores de 24 progresan un 50% más rápido"],
	"recup":   ["Recuperación", "Se recupera mucho más físico y se llega entero al fin de semana"],
}

## Intensidad: multiplica el progreso y, con `alta`, abre la puerta a lesionar a
## alguien machacándolo. Los tres multiplicadores son los del HTML.
const INTENSIDADES := {
	"baja":  ["Suave", 0.6],
	"media": ["Normal", 1.0],
	"alta":  ["Al límite", 1.5],
}

## El plan por defecto del HTML. Su riesgo suma exactamente 6,0, que es la
## `Medico.CARGA_POR_DEFECTO`: no es casualidad, es de donde salió esa constante.
const PLAN_POR_DEFECTO := ["tactico", "fisico", "tecnico", "balon", "tactico", "pelota"]

## Cuatro planes individuales a la vez y tres jugadores en desarrollo
## prioritario. Los dos topes son del HTML y son los que obligan a ELEGIR: sin
## ellos se le pone plan especial al plantel entero y el sistema desaparece.
const MAX_INDIVIDUALES := 4
const MAX_PRIORITARIOS := 3

## Semanas que tarda en cuajar un plan individual (se sortea al terminar).
const IND_MIN := 5
const IND_MAX := 9

## El entrenador empieza con tres puntos y gana uno cada diez semanas de
## trabajo. Es la única fuente que no depende de comprar nada.
const DT_PUNTOS_INICIALES := 3
const SEMANAS_POR_PUNTO_DT := 10

## Lo que cuesta una semana de concentración, antes de escalar por el tamaño del
## club.
const COSTE_CONCENTRACION := 3500.0

# ---------------------------------------------------------------------------
#  ESTADO
# ---------------------------------------------------------------------------

var foco: String = "tactico"
var intensidad: String = "media"
## Los seis días de la semana, cada uno con la clave de un bloque de `BLOQUES`.
var dias: Array[String] = []
## id de jugador -> {"clave": String, "semanas": int}
var individual: Dictionary = {}
## Ids de los jugadores en desarrollo prioritario.
var prioritarios: Array[String] = []
var concentracion: bool = false
## Clave de la pretemporada de este año, vacía si todavía no se ha hecho.
var pretemporada: String = ""
var semanas_trabajadas: int = 0

var dt_puntos: int = DT_PUNTOS_INICIALES
## clave -> true. Solo se guardan los nodos abiertos.
var dt_nodos: Dictionary = {}

## Las tres cosas que se guardan POR JUGADOR, indexadas por id.
var _habs: Dictionary = {}      ## id -> Array[String]
var _puntos: Dictionary = {}    ## id -> int (puntos de habilidad sin gastar)
var _subidas: Dictionary = {}   ## id -> int (puntos de media ganados esta temporada)

## Sistemas de los que se lee, nunca se duplican. Pueden ser nulos: el banco de
## pruebas monta un entrenamiento pelado para medir solo el árbol.
var staff: Staff = null
var obras: Instalaciones = null
var medico: Medico = null

func _init(staff_propio: Staff = null, obras_propias: Instalaciones = null,
		medico_propio: Medico = null) -> void:
	staff = staff_propio
	obras = obras_propias
	medico = medico_propio
	dias.assign(PLAN_POR_DEFECTO)

# ---------------------------------------------------------------------------
#  LAS TABLAS
# ---------------------------------------------------------------------------

func bloques() -> Array:
	var t: Variant = Datos.tabla("BLOQUES")
	return t if t is Array else []

## Un bloque por clave: [clave, nombre, icono, descripción, {fis, ovr, riesgo, moral}].
func bloque(clave: String) -> Array:
	for fila: Array in bloques():
		if String(fila[0]) == clave:
			return fila
	## El táctico es el neutro del HTML: si alguien pide una clave que no existe
	## se entrena, no se queda el día en blanco.
	var b := bloques()
	return b[2] if b.size() > 2 else []

func nombres_de_dias() -> Array:
	var t: Variant = Datos.tabla("DIAS")
	return t if t is Array else ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]

func especiales() -> Array:
	var t: Variant = Datos.tabla("ESPECIALES")
	return t if t is Array else []

func especial(clave: String) -> Array:
	for fila: Array in especiales():
		if String(fila[0]) == clave:
			return fila
	return []

func pretemporadas() -> Array:
	var t: Variant = Datos.tabla("PRETEMP")
	return t if t is Array else []

func _habs_tabla() -> Dictionary:
	var t: Variant = Datos.tabla("HABS")
	return t if t is Dictionary else {}

func _skill_tabla() -> Dictionary:
	var t: Variant = Datos.tabla("SKILL_JUG")
	return t if t is Dictionary else {}

func _dt_tabla() -> Dictionary:
	var t: Variant = Datos.tabla("DT_SKILLS")
	return t if t is Dictionary else {}

# ---------------------------------------------------------------------------
#  EL PLAN DE LA SEMANA
# ---------------------------------------------------------------------------

## Cambia el trabajo de un día. Devuelve "" si se pudo, o el motivo por el que no.
func fijar_dia(indice: int, clave: String) -> String:
	if indice < 0 or indice >= dias.size():
		return "ese día no existe"
	var existe := false
	for fila: Array in bloques():
		if String(fila[0]) == clave:
			existe = true
			break
	if not existe:
		return "ese tipo de sesión no existe"
	dias[indice] = clave
	return ""

func fijar_foco(clave: String) -> String:
	if not FOCOS.has(clave):
		return "ese foco no existe"
	foco = clave
	return ""

func fijar_intensidad(clave: String) -> String:
	if not INTENSIDADES.has(clave):
		return "esa intensidad no existe"
	intensidad = clave
	return ""

## Lo que suma el plan entero: físico, progreso, riesgo y moral. Es el número
## que hay que enseñar en el menú, porque es el único resumen honesto de lo que
## le estás haciendo al plantel esta semana.
func carga() -> Dictionary:
	var c := {"fis": 0.0, "ovr": 0.0, "riesgo": 0.0, "moral": 0.0}
	for d in dias:
		var b := bloque(d)
		if b.is_empty():
			continue
		var e: Dictionary = b[4]
		c["fis"] = float(c["fis"]) + float(e.get("fis", 0))
		c["ovr"] = float(c["ovr"]) + float(e.get("ovr", 0))
		c["riesgo"] = float(c["riesgo"]) + float(e.get("riesgo", 0))
		c["moral"] = float(c["moral"]) + float(e.get("moral", 0))
	## LA INTENSIDAD TAMBIÉN SUBE EL RIESGO, no solo la ganancia.
	##
	## `procesar_semana` ya multiplicaba las mejoras por la intensidad, pero el
	## riesgo se quedaba fuera: entrenar "al límite" daba más progreso con
	## exactamente el mismo peligro de romper a alguien. Eso no es una decisión,
	## es una ganancia gratis, y el sentido de la perilla es justo el contrario.
	##
	## Con intensidad normal el multiplicador es 1,0, así que el plan por defecto
	## sigue sumando exactamente 6,0 —el `CARGA_POR_DEFECTO` del médico— y nada
	## cambia hasta que el entrenador toca la perilla.
	c["riesgo"] = float(c["riesgo"]) * multiplicador_intensidad()
	return c

## La carga que hay que pasarle a `Medico.revisar_semana` en vez de su valor por
## defecto. Con la semana entera de descanso da 0 y nadie se rompe entrenando;
## machacando a diario roza 13.
func carga_riesgo() -> float:
	return float(carga()["riesgo"])

func multiplicador_intensidad() -> float:
	return float(INTENSIDADES.get(intensidad, ["", 1.0])[1])

# ---------------------------------------------------------------------------
#  TRABAJO INDIVIDUAL Y DESARROLLO PRIORITARIO
# ---------------------------------------------------------------------------

## Pone (o quita) un plan individual. Volver a pedir el mismo lo cancela, que es
## como funcionaba en el HTML y evita tener dos botones para lo mismo.
func asignar_individual(j: Jugador, clave: String) -> String:
	if j == null:
		return "no hay jugador"
	if individual.has(j.id) and String(individual[j.id]["clave"]) == clave:
		individual.erase(j.id)
		return ""
	if especial(clave).is_empty():
		return "ese plan no existe"
	if individual.size() >= MAX_INDIVIDUALES and not individual.has(j.id):
		return "máximo %d planes individuales a la vez" % MAX_INDIVIDUALES
	individual[j.id] = {"clave": clave, "semanas": 0}
	return ""

func plan_de(j: Jugador) -> Dictionary:
	return individual.get(j.id, {})

## Desarrollo prioritario: progresa un 50% más rápido y paga un punto de físico
## por semana. Tres como mucho.
func alternar_prioritario(j: Jugador) -> String:
	if j == null:
		return "no hay jugador"
	var i := prioritarios.find(j.id)
	if i >= 0:
		prioritarios.remove_at(i)
		return ""
	if prioritarios.size() >= MAX_PRIORITARIOS:
		return "plan lleno: máximo %d en desarrollo prioritario" % MAX_PRIORITARIOS
	prioritarios.append(j.id)
	return ""

func es_prioritario(j: Jugador) -> bool:
	return prioritarios.has(j.id)

# ---------------------------------------------------------------------------
#  LA SEMANA
# ---------------------------------------------------------------------------

## Entrena a TU club una semana entera y devuelve lo que ha pasado.
##
## El orden es el del HTML y no se toca: sesión general (foco e intensidad),
## plan por días, trabajo individual, concentración. Aquí NO se descuenta la
## semana de baja de los lesionados ni se mueve la forma: de eso ya se encarga
## `Mundo.avanzar_semana` para el mundo entero, y repetirlo curaría a tu plantel
## al doble de velocidad que al de los rivales.
## MENTORÍAS (`crearMentoria`/`procesoMentoria` del HTML). Un veterano apadrina
## a un chico: el pupilo progresa más rápido cuanto mejor es el maestro, y con
## el tiempo se le pega hasta el carácter. Es la única forma de que un veterano
## que ya no juega siga sirviendo para algo.
const MENTOR_EDAD := 29
const MENTOR_MEDIA := 62
const PUPILO_EDAD := 21
const MAX_MENTORIAS := 4

var mentorias: Array[Dictionary] = []   ## {maestro, pupilo, semanas, subidas}

func puede_ser_mentor(j: Jugador) -> bool:
	if j.edad < MENTOR_EDAD or j.ovr < MENTOR_MEDIA:
		return false
	for m: Dictionary in mentorias:
		if String(m["maestro"]) == j.id:
			return false
	return true

func puede_ser_pupilo(j: Jugador) -> bool:
	if j.edad > PUPILO_EDAD:
		return false
	for m: Dictionary in mentorias:
		if String(m["pupilo"]) == j.id:
			return false
	return true

func crear_mentoria(maestro: Jugador, pupilo: Jugador) -> String:
	if mentorias.size() >= MAX_MENTORIAS:
		return "solo puedes tener %d parejas de mentoría a la vez" % MAX_MENTORIAS
	if not puede_ser_mentor(maestro) or not puede_ser_pupilo(pupilo):
		return "esa pareja no vale"
	mentorias.append({"maestro": maestro.id, "pupilo": pupilo.id, "semanas": 0, "subidas": 0})
	maestro.moral = clampi(maestro.moral + 5, 10, 99)
	pupilo.moral = clampi(pupilo.moral + 8, 10, 99)
	noticia.emit("Mentoría en la cantera",
		"%s apadrina a %s. Entrenarán juntos y el chico va a aprender de alguien que ya lo vivió todo." % [
			Nombres.limpiar(maestro.nombre), Nombres.limpiar(pupilo.nombre)])
	return ""

func romper_mentoria(indice: int) -> void:
	if indice >= 0 and indice < mentorias.size():
		mentorias.remove_at(indice)

## Cada semana. Las parejas se deshacen solas si alguno deja el club: una
## mentoría con un jugador vendido sería un puntero a nadie.
func _procesar_mentorias(c: Club) -> void:
	for i in range(mentorias.size() - 1, -1, -1):
		var m: Dictionary = mentorias[i]
		var maestro: Jugador = null
		var pupilo: Jugador = null
		for j in c.plantilla:
			if j.id == String(m["maestro"]):
				maestro = j
			elif j.id == String(m["pupilo"]):
				pupilo = j
		if maestro == null or pupilo == null:
			mentorias.remove_at(i)
			continue
		m["semanas"] = int(m["semanas"]) + 1
		## El pupilo crece más rápido cuanto mejor es el maestro.
		if pupilo.ovr < pupilo.pot and Azar.suerte(0.10 + float(maestro.ovr - 60) * 0.002):
			pupilo.ajustar_media(1)
			m["subidas"] = int(m["subidas"]) + 1
			if not pupilo.atributos.is_empty():
				var k: String = Azar.uno(pupilo.atributos.keys())
				pupilo.atributos[k] = clampi(int(pupilo.atributos[k]) + 1, 22, 99)
			pupilo.tasar()
		## Y cada dos meses puede pegársele el carácter.
		if int(m["semanas"]) % 8 == 0 and maestro.rasgo != "" and pupilo.rasgo == "" and Azar.suerte(0.35):
			pupilo.rasgo = maestro.rasgo
			noticia.emit("El alumno sale al maestro",
				"%s ha copiado el carácter de %s." % [
					Nombres.limpiar(pupilo.nombre), Nombres.limpiar(maestro.nombre)])
		pupilo.moral = clampi(pupilo.moral + 1, 10, 99)

func procesar_semana(c: Club, anio: int = 0, semana: int = 0) -> Dictionary:
	var res := {"subieron": [], "bajaron": [], "aprendieron": [], "lesionados": [], "punto_dt": false}
	if c == null:
		return res
	_procesar_mentorias(c)

	var mult := multiplicador_intensidad()
	var ritmo := obras.ritmo_de_progreso() if obras != null else 1.0
	var joven := factor_progreso_joven()

	for j in c.plantilla:
		_sesion_general(j, mult, ritmo, joven, res)
	_dado_de_la_intensidad(c, anio, semana, res)

	var carg := carga()
	_plan_por_dias(c, carg, ritmo, res)
	_trabajo_individual(c, res)

	if concentracion:
		var costo := Eco.escalar(COSTE_CONCENTRACION, float(c.rep))
		c.mover_saldo(-costo)
		gasto.emit("Concentración de la semana", costo)
		for j in c.plantilla:
			j.fisico = clampi(j.fisico + 3, 10, 100)

	## El punto de habilidad del entrenador: uno cada diez semanas de trabajo.
	semanas_trabajadas += 1
	if semanas_trabajadas % SEMANAS_POR_PUNTO_DT == 0:
		dt_puntos += 1
		res["punto_dt"] = true
		punto_dt_ganado.emit(dt_puntos)
		noticia.emit("Punto de habilidad de entrenador",
			"Diez semanas más de trabajo en el banquillo. Tienes %d punto(s) por gastar en tu árbol de carrera."
			% dt_puntos)
	return res

## La sesión general del HTML: reparte físico, sube la moral si hay con qué,
## hace progresar a los jóvenes y desgasta a los veteranos.
func _sesion_general(j: Jugador, mult: float, ritmo: float, joven: float, res: Dictionary) -> void:
	## Físico. El `recup` reparte 26 en vez de 16, y el preparador físico suma
	## de tres en tres: es el número que hace que contratarlo se note el lunes.
	##
	## EL NUTRICIONISTA Y EL UTILERO ya existen -llegaron con las ideas 91-105-,
	## asi que la recuperacion semanal ya no sale solo del comedor y la piscina.
	## Suman poco cada uno; el punto es que son baratos y se contratan pronto.
	var base := 26 if foco == "recup" else 16
	var extra := (staff.aguante() * 3) if staff != null else 0
	extra += (staff.recuperacion_fisica() * 2) if staff != null else 0
	extra += obras.aguante() if obras != null else 0
	j.fisico = clampi(j.fisico + base + extra, 10, 100)

	## El jugador en desarrollo prioritario paga la carga extra en físico.
	if es_prioritario(j):
		j.fisico = clampi(j.fisico - 1, 10, 100)

	## En el HTML esto lo hacía el psicólogo del staff, que no está portado. La
	## puerta equivalente que sí existe es el espacio de bienestar y la
	## guardería: si el club los tiene, el vestuario va levantando el ánimo solo.
	var calma := obras.calma_del_vestuario() if obras != null else 0
	if calma > 0 and j.moral < 40 + 5 * calma:
		j.moral = clampi(j.moral + 1, 10, 99)

	## Progreso de los menores de 24. La probabilidad base es 0,10 y encima se
	## multiplican intensidad, formador del DT, rasgo motor, plan prioritario,
	## centro de entrenamiento y foco técnico. Todos son del HTML.
	if j.edad < 24 and j.ovr < j.pot:
		var p := 0.10 * mult * ritmo
		if j.edad < 23:
			p *= joven
		if j.rasgo == "motor":
			p *= 1.5
		if es_prioritario(j):
			p *= 1.5
		if foco == "tecnico":
			p *= 1.5
		if Azar.suerte(p):
			_subir_media(j, Azar.ent(1, 2), res)

	## Y la otra cara: a partir de los 31 se empieza a perder, un 5% de las
	## semanas. El suelo son 45 de media, no 0: un veterano se apaga, no
	## desaparece.
	if j.edad >= 31 and Azar.suerte(0.05) and j.ovr > 45:
		var antes := j.ovr
		j.ajustar_media(-1)
		## Lo que se va primero son las piernas: ritmo y físico en un jugador de
		## campo, velocidad en un portero.
		var decae: Array = ["rit", "fis"] if j.atributos.has("rit") else ["vel"]
		var k := String(Azar.uno(decae))
		if j.atributos.has(k):
			j.atributos[k] = clampi(int(j.atributos[k]) - Azar.ent(1, 2), 22, 99)
		_tasar(j)
		res["bajaron"].append(j)
		progreso.emit(j, antes, j.ovr)

## Entrenar al límite tiene un precio: una de cada cuatro semanas alguien se
## queda en el camino, y si hay un frágil en el plantel suele ser él.
func _dado_de_la_intensidad(c: Club, anio: int, semana: int, res: Dictionary) -> void:
	if intensidad != "alta":
		return
	var nivel_med := staff.nivel("medico") if staff != null else 0
	if not Azar.suerte(0.25 * (1.0 - 0.12 * float(nivel_med))):
		return
	var libres := c.disponibles()
	if libres.is_empty():
		return
	var j: Jugador = Azar.uno(libres)
	## La mitad de las veces el dado se corrige hacia el frágil. No es un capricho
	## del HTML: es lo que hace que el rasgo se note y que machacar al plantel sea
	## una decisión y no una estadística invisible.
	if j.rasgo != "fragil" and Azar.suerte(0.5):
		for x in libres:
			if x.rasgo == "fragil":
				j = x
				break
	var sem := 0
	if medico != null:
		var sev: int = Medico.MEDIA if Azar.suerte(0.20) else Medico.LEVE
		sem = medico.lesionar(j, sev, "entrenando al límite", anio, semana)
	else:
		sem = Azar.ent(1, 3)
		j.lesionar(sem)
	res["lesionados"].append({"jugador": j, "semanas": sem})
	noticia.emit("Lesión en entrenamiento",
		"%s se queda en el camino entrenando al límite: %d semana(s) de baja. El cuerpo médico sugiere bajar la intensidad."
		% [j.nombre, sem])

## El plan por días: la carga del lunes al sábado se reparte sobre el plantel.
func _plan_por_dias(c: Club, carg: Dictionary, ritmo: float, res: Dictionary) -> void:
	## El gimnasio multiplica lo que se recupera; el 0,55 es el freno del HTML,
	## sin él una semana de descanso completo llenaba el depósito de golpe.
	var gim := (1.0 + 0.08 * float(obras.nivel("gim"))) if obras != null else 1.0
	for j in c.plantilla:
		j.fisico = clampi(j.fisico + int(round(float(carg["fis"]) * gim * 0.55)), 10, 100)
		j.moral = clampi(j.moral + int(round(float(carg["moral"]) * 0.4)), 10, 99)
		## El riesgo de romperse por acumulación NO se tira aquí: lo tira
		## `Medico.chequeo_de_fatiga` con la carga que devuelve `carga_riesgo()`.
		if j.edad < 24 and j.ovr < j.pot:
			var p := float(carg["ovr"]) * 0.014 * ritmo
			if j.rasgo == "motor":
				p *= 1.5
			if Azar.suerte(p):
				_subir_media(j, 1, res)

## Los planes individuales. Tardan entre cinco y nueve semanas y terminan
## enseñando una habilidad de verdad, no un +1 invisible.
func _trabajo_individual(c: Club, res: Dictionary) -> void:
	for j in c.plantilla:
		if not individual.has(j.id):
			continue
		var plan: Dictionary = individual[j.id]
		plan["semanas"] = int(plan["semanas"]) + 1
		## El trabajo extra se paga en piernas. El HTML descontaba 1,5 sobre un
		## físico decimal; aquí `Jugador.fisico` es entero y se redondea a 2, que
		## es la diferencia de medio punto cada varias semanas y no mueve nada.
		j.fisico = clampi(j.fisico - 2, 10, 100)
		if int(plan["semanas"]) < Azar.ent(IND_MIN, IND_MAX):
			continue
		var e := especial(String(plan["clave"]))
		individual.erase(j.id)
		if e.is_empty():
			continue
		var hab: Variant = e[3]
		if hab == null:
			## El plan de liderazgo no da habilidad: da peso en el vestuario y la
			## cinta si no hay capitán.
			j.moral = clampi(j.moral + 12, 10, 99)
			if not _hay_capitan(c):
				j.capitan = true
			noticia.emit("%s crece como líder" % j.nombre,
				"Termina su plan de liderazgo: más peso en el vestuario y candidato natural a la cinta.")
			continue
		var k := String(hab)
		if not tiene_habilidad(j, k):
			_lista(j.id).append(k)
			res["aprendieron"].append({"jugador": j, "habilidad": k})
			habilidad_aprendida.emit(j, k, nombre_habilidad(k))
			noticia.emit("%s domina una habilidad nueva" % j.nombre,
				"%s termina su plan de %s y suma la habilidad «%s». Se nota en el campo desde ya."
				% [j.nombre, String(e[1]).to_lower(), nombre_habilidad(k)])
		else:
			## Ya la tenía: el trabajo se traduce en atributos, que es lo que
			## impide que repetir el mismo plan sea tiempo tirado.
			var ks: Array = j.atributos.keys()
			if not ks.is_empty():
				var kk := String(ks[0])
				j.atributos[kk] = clampi(int(j.atributos[kk]) + 2, 22, 99)
				_tasar(j)
			noticia.emit("%s afina lo que ya sabía" % j.nombre,
				"Ya tenía la habilidad, así que el trabajo se tradujo en atributos.")

func _hay_capitan(c: Club) -> bool:
	for j in c.plantilla:
		if j.capitan:
			return true
	return false

## Progresión de un jugador que NO es tuyo. El HTML entrenaba al mundo entero en
## la misma pasada, sin foco ni intensidad ni instalaciones: solo el 0,10 base y
## el desgaste de los veteranos. Sin esto, los rivales se quedan congelados y en
## tres temporadas tu cantera domina el continente sola.
func procesar_ajeno(j: Jugador) -> void:
	j.fisico = clampi(j.fisico + 16, 10, 100)
	if j.edad < 24 and j.ovr < j.pot:
		var p := 0.10
		if j.rasgo == "motor":
			p *= 1.5
		if Azar.suerte(p):
			var antes := j.ovr
			j.ajustar_media(1)
			if not j.atributos.is_empty():
				var k := String(Azar.uno(j.atributos.keys()))
				j.atributos[k] = clampi(int(j.atributos[k]) + Azar.ent(1, 2), 22, 99)
			j.tasar()
			progreso.emit(j, antes, j.ovr)
	if j.edad >= 31 and Azar.suerte(0.05) and j.ovr > 45:
		var antes2 := j.ovr
		j.ajustar_media(-1)
		var decae: Array = ["rit", "fis"] if j.atributos.has("rit") else ["vel"]
		var k2 := String(Azar.uno(decae))
		if j.atributos.has(k2):
			j.atributos[k2] = clampi(int(j.atributos[k2]) - Azar.ent(1, 2), 22, 99)
		j.tasar()
		progreso.emit(j, antes2, j.ovr)

func _subir_media(j: Jugador, delta_atributo: int, res: Dictionary) -> void:
	var antes := j.ovr
	j.ajustar_media(1)
	if j.ovr == antes:
		return
	_subidas[j.id] = int(_subidas.get(j.id, 0)) + 1
	if not j.atributos.is_empty():
		var k := String(Azar.uno(j.atributos.keys()))
		j.atributos[k] = clampi(int(j.atributos[k]) + delta_atributo, 22, 99)
	_tasar(j)
	res["subieron"].append(j)
	progreso.emit(j, antes, j.ovr)

func reiniciar_subidas() -> void:
	_subidas.clear()

func _tasar(j: Jugador) -> void:
	## Si hay parte médico se tasa por ahí, que es quien sabe del historial de
	## lesiones; si no, el jugador se tasa solo.
	if medico != null:
		medico.tasar(j)
	else:
		j.tasar()
	## EL BONO DE HABILIDADES: "if(j.habs.length>=3)v*=1.05" del HTML. No puede
	## vivir dentro de `Jugador.tasar()` -las habilidades no viven en el
	## jugador, viven aquí- así que se aplica encima, mismo criterio que
	## `Medico.tasar()` con el historial de lesiones: se tasa normal y se
	## recalcula el sueldo desde el valor ya con el bono.
	if habilidades(j).size() >= 3:
		j.valor = int(max(300.0, round(float(j.valor) * 1.05 / 100.0) * 100.0))
		j.sueldo = int(max(30.0, round(1.361 * pow(float(j.valor), 0.66) / 10.0) * 10.0))

# ---------------------------------------------------------------------------
#  PRETEMPORADA
# ---------------------------------------------------------------------------

## Se elige una vez al año y marca la temporada entera. Devuelve "" si se hizo,
## o el motivo por el que no.
func elegir_pretemporada(clave: String, c: Club, anio: int = 0, semana: int = 0) -> String:
	if pretemporada != "":
		return "la pretemporada de este año ya está hecha"
	var d: Array = []
	for fila: Array in pretemporadas():
		if String(fila[0]) == clave:
			d = fila
			break
	if d.is_empty():
		return "esa pretemporada no existe"
	var costo := Eco.escalar(float(d[2]), float(c.rep)) if float(d[2]) > 0.0 else 0
	if costo > c.saldo:
		return "no hay caja: cuesta %d y tienes %d" % [costo, c.saldo]
	if costo > 0:
		c.mover_saldo(-costo)
		gasto.emit("Pretemporada: " + String(d[1]), costo)
	pretemporada = clave
	var ef: Dictionary = d[4]
	var rotos := 0
	for j in c.plantilla:
		j.fisico = clampi(j.fisico + int(ef.get("fis", 0)), 10, 100)
		## La forma sube seis décimas de lo que sube el físico: llegar fuerte a
		## agosto no es lo mismo que llegar enchufado.
		j.forma = clampi(j.forma + int(round(float(ef.get("fis", 0)) * 0.6)), 20, 99)
		var base := int(ef.get("base", 0))
		if base > 0 and j.ovr < j.pot and Azar.suerte(0.25 * float(base)):
			var antes := j.ovr
			j.ajustar_media(1)
			_subidas[j.id] = int(_subidas.get(j.id, 0)) + 1
			_tasar(j)
			progreso.emit(j, antes, j.ovr)
		if Azar.suerte(float(ef.get("riesgo", 0)) / 100.0):
			if medico != null:
				medico.lesionar(j, Medico.LEVE, "en la pretemporada", anio, semana)
			else:
				j.lesionar(Azar.ent(1, 3))
			rotos += 1
	var cola := " %d jugador(es) se resintieron durante el trabajo." % rotos if rotos > 0 else ""
	noticia.emit(String(d[1]), String(d[3]) + "." + cola)
	return ""

## Al empezar temporada vuelve a haber pretemporada que elegir.
func reiniciar_pretemporada() -> void:
	pretemporada = ""

# ---------------------------------------------------------------------------
#  ÁRBOL DE HABILIDADES DEL JUGADOR
# ---------------------------------------------------------------------------
#
# Hasta la v2.0 del HTML las habilidades se sorteaban al nacer y ahí quedaban:
# un chico no podía APRENDER nada por mucho que jugara. Este árbol las convierte
# en progresión, y no son adornos: el motor de partido ya las consulta (la
# jugada de gol, el goleador, los remates de córner y de tiro libre).

## Las habilidades que tiene un jugador. Devuelve una copia: quien quiera añadir
## una pasa por `aprender()` o por `dar_habilidad()`, que es donde están las
## reglas.
func habilidades(j: Jugador) -> Array:
	return _lista(j.id).duplicate()

func tiene_habilidad(j: Jugador, clave: String) -> bool:
	return _lista(j.id).has(clave)

func _lista(id: String) -> Array:
	if not _habs.has(id):
		_habs[id] = []
	return _habs[id]

## Mete una habilidad sin pasar por el árbol. Es lo que usa el sorteo de
## nacimiento y lo que necesita el que cargue una partida vieja.
func dar_habilidad(j: Jugador, clave: String) -> bool:
	if not _habs_tabla().has(clave):
		return false
	var l := _lista(j.id)
	if l.has(clave):
		return false
	l.append(clave)
	return true

func puntos(j: Jugador) -> int:
	return int(_puntos.get(j.id, 0))

## Qué se le puede ofrecer a este jugador. Al portero SOLO sus tres: parar
## penales, jugar con los pies y mandar en la línea. Ofrecerle una ruleta sería
## un menú lleno de botones muertos.
func disponibles(j: Jugador) -> Array[String]:
	var salida: Array[String] = []
	var por := j.es_portero()
	for k: String in _skill_tabla():
		var de_portero := k == "atajaPen" or k == "juegoPies"
		if por:
			if de_portero or k == "liderazgo":
				salida.append(k)
		elif not de_portero:
			salida.append(k)
	return salida

## Por qué NO puede aprenderla. Cadena vacía significa que sí puede. Devolver el
## motivo y no un booleano es a propósito: el menú tiene que decir "necesita REG
## 72", no apagar el botón y callarse.
func motivo(j: Jugador, clave: String) -> String:
	var t := _skill_tabla()
	if not t.has(clave):
		return "no disponible"
	var s: Array = t[clave]
	if tiene_habilidad(j, clave):
		return "ya la tiene"
	var req: Variant = s[3]
	if req != null and not tiene_habilidad(j, String(req)):
		return "antes: " + nombre_habilidad(String(req))
	var at := atributo_de(j, clave)
	var v := int(j.atributos.get(at, 0))
	var minimo := int(s[2])
	if v < minimo:
		return "necesita %s %d (tiene %d)" % [at.to_upper(), minimo, v]
	if puntos(j) < 1:
		return "sin puntos"
	return ""

func puede(j: Jugador, clave: String) -> bool:
	return motivo(j, clave) == ""

## Qué atributo gobierna esta habilidad EN ESTE jugador.
##
## TRAMPA HEREDADA DEL HTML: la tabla dice que «Voz de mando» la gobierna `def`,
## y un portero no tiene `def` -sus atributos son div/par/saq/ref/vel/pos-. El
## resultado era que al arquero se le ofrecía liderazgo en el menú y nunca podía
## aprenderlo, porque su `def` valía siempre 0. Aquí se le pide lo mismo (66)
## pero sobre `pos`, que es el atributo del portero que de verdad significa leer
## el juego y ordenar la línea. El número no cambia; lo que cambia es que el
## botón deja de estar muerto.
func atributo_de(j: Jugador, clave: String) -> String:
	var t := _skill_tabla()
	if not t.has(clave):
		return ""
	var at := String((t[clave] as Array)[1])
	if j.es_portero() and not j.atributos.has(at) and j.atributos.has("pos"):
		return "pos"
	return at

## Gasta un punto y aprende. Devuelve "" si se aprendió, o el motivo por el que no.
func aprender(j: Jugador, clave: String) -> String:
	var m := motivo(j, clave)
	if m != "":
		return m
	_lista(j.id).append(clave)
	_puntos[j.id] = puntos(j) - 1
	## Aprender algo deja huella en el atributo que lo gobierna. Es un punto, no
	## es mucho, pero es lo que hace que el árbol se vea también en la ficha.
	var at := atributo_de(j, clave)
	if j.atributos.has(at):
		j.atributos[at] = clampi(int(j.atributos[at]) + 1, 1, 99)
	j.moral = clampi(j.moral + 4, 10, 99)
	_tasar(j)
	habilidad_aprendida.emit(j, clave, nombre_habilidad(clave))
	noticia.emit("Nueva habilidad: " + j.nombre,
		"%s termina de pulir «%s» en los entrenamientos. %s. Le quedan %d punto(s) por gastar."
		% [j.nombre, nombre_habilidad(clave), descripcion_habilidad(clave), puntos(j)])
	return ""

## El reparto de fin de temporada. Los puntos se ganan JUGANDO, no comprando:
## doce partidos dan uno, y los menores de 21 con ocho partidos ganan otro más.
## Devuelve la lista de [{jugador, puntos}] para que la interfaz lo cuente.
func repartir_puntos(c: Club) -> Array:
	var ganaron: Array = []
	if c == null:
		return ganaron
	for j in c.plantilla:
		var p := 0
		if j.partidos >= 12:
			p += 1
		if j.edad <= 21 and j.partidos >= 8:
			p += 1
		if p > 0:
			_puntos[j.id] = puntos(j) + p
			ganaron.append({"jugador": j, "puntos": p})
	if ganaron.is_empty():
		return ganaron
	ganaron.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["puntos"]) != int(b["puntos"]):
			return int(a["puntos"]) > int(b["puntos"])
		return (a["jugador"] as Jugador).pot > (b["jugador"] as Jugador).pot)
	var dobles: Array[String] = []
	for x: Dictionary in ganaron:
		if int(x["puntos"]) == 2 and dobles.size() < 6:
			var j: Jugador = x["jugador"]
			dobles.append("%s (%d)" % [j.nombre, j.edad])
	var cuerpo := "%d futbolistas ganaron puntos por los minutos que jugaron. " % ganaron.size()
	if not dobles.is_empty():
		cuerpo += "Con dos puntos, por ser jóvenes con rodaje: " + ", ".join(dobles) + ". "
	cuerpo += "Gástalos en la ficha de cada jugador, en el árbol de habilidades: lo que aprendan se nota en el campo."
	noticia.emit("Puntos de habilidad de la temporada", cuerpo)
	return ganaron

## El sorteo de nacimiento: con qué habilidades llega un jugador al mundo. Se
## queda aquí y no en `Jugador` porque las habilidades no viven en el jugador.
func sortear_habilidades(j: Jugador) -> Array[String]:
	var t: Variant = Datos.tabla("HAB_POR" if j.es_portero() else "HAB_CAMPO")
	var pool: Array = t if t is Array else []
	if pool.is_empty():
		return []
	var n := 0
	if j.ovr >= 85:
		n = Azar.ent(2, 4)
	elif j.ovr >= 76:
		n = Azar.ent(1, 3)
	elif j.ovr >= 66:
		n = Azar.ent(0, 2)
	else:
		n = Azar.ent(0, 1)
	var salida: Array[String] = []
	for i in n:
		var h := String(Azar.uno(pool))
		if not salida.has(h):
			salida.append(h)
	var l := _lista(j.id)
	for h in salida:
		if not l.has(h):
			l.append(h)
	return salida

func nombre_habilidad(clave: String) -> String:
	var t := _habs_tabla()
	if not t.has(clave):
		return clave
	return Nombres.limpiar(String((t[clave] as Array)[0]))

func descripcion_habilidad(clave: String) -> String:
	var t := _habs_tabla()
	if not t.has(clave):
		return ""
	return String((t[clave] as Array)[1])

# ---------------------------------------------------------------------------
#  ÁRBOL DE CARRERA DEL ENTRENADOR
# ---------------------------------------------------------------------------
#
# Es un árbol aparte del de los jugadores: cuesta puntos propios, tiene cinco
# ramas (Gestión, Camarín, Táctica, Cantera, Medios) y cada nodo cuesta de uno a
# tres puntos con un requisito encadenado. Lo consulta medio juego a través de
# `dt_tiene()`; los efectos con número concreto tienen método propio abajo para
# que nadie tenga que recordar si «genio» era un 6% o un 5%.

func dt_tiene(clave: String) -> bool:
	return dt_nodos.get(clave, false)

func dt_coste(clave: String) -> int:
	var t := _dt_tabla()
	return int((t[clave] as Array)[4]) if t.has(clave) else 0

func dt_requisito(clave: String) -> String:
	var t := _dt_tabla()
	if not t.has(clave):
		return ""
	var r: Variant = (t[clave] as Array)[5]
	return "" if r == null else String(r)

func dt_nombre(clave: String) -> String:
	var t := _dt_tabla()
	return Nombres.limpiar(String((t[clave] as Array)[1])) if t.has(clave) else clave

func dt_icono(clave: String) -> String:
	var t := _dt_tabla()
	return String((t[clave] as Array)[2]) if t.has(clave) else ""

func dt_descripcion(clave: String) -> String:
	var t := _dt_tabla()
	return String((t[clave] as Array)[3]) if t.has(clave) else ""


## Igual que con los jugadores: el menú tiene que poder decir qué falta.
func dt_motivo(clave: String) -> String:
	var t := _dt_tabla()
	if not t.has(clave):
		return "no disponible"
	if dt_tiene(clave):
		return "ya la tienes"
	var req := dt_requisito(clave)
	if req != "" and not dt_tiene(req):
		return "antes: " + dt_nombre(req)
	var c := dt_coste(clave)
	if dt_puntos < c:
		return "te faltan %d punto(s)" % (c - dt_puntos)
	return ""

## Abre un nodo. Devuelve "" si se abrió, o el motivo por el que no.
func dt_aprender(clave: String) -> String:
	var m := dt_motivo(clave)
	if m != "":
		return m
	dt_puntos -= dt_coste(clave)
	dt_nodos[clave] = true
	dt_habilidad.emit(clave, dt_nombre(clave))
	noticia.emit("Nueva habilidad: " + dt_nombre(clave),
		dt_descripcion(clave) + ". Tu ficha de entrenador suma un punto más de prestigio.")
	return ""

func dt_sumar_puntos(n: int) -> void:
	dt_puntos = maxi(0, dt_puntos + n)
	if n > 0:
		punto_dt_ganado.emit(dt_puntos)

## Los nodos agrupados por rama, en el orden de la tabla.
func dt_ramas() -> Dictionary:
	var salida := {}
	var t := _dt_tabla()
	for k: String in t:
		var rama := String((t[k] as Array)[0])
		if not salida.has(rama):
			salida[rama] = []
		(salida[rama] as Array).append(k)
	return salida

# --- lo que el árbol del entrenador le hace al juego ------------------------
#
# Todas las puertas por las que la carrera del DT toca el motor, juntas y a la
# vista, como en `Instalaciones.efecto()`. Si mañana se abre un nodo nuevo, este
# es el sitio donde tiene que aparecer o no servirá para nada.

## Bonificación de ataque y defensa del banquillo. «Genio» REEMPLAZA a «Pizarra
## fina», no se suman: el 6% ya incluye el 3%.
##
## OJO: esto NO se escribe en `Club.bonus_ataque`/`bonus_defensa`. Esos dos
## números los vuelca `Staff.aplicar()` enteros cada vez que se contrata a
## alguien, así que escribir aquí se perdería al siguiente fichaje de staff.
## Quien monte el club combina este factor con el del cuerpo técnico.
func bonus_dt() -> float:
	if dt_tiene("genio"):
		return 1.06
	if dt_tiene("pizarra"):
		return 1.03
	return 1.0

## Los menores de 23 de TU club progresan un 40% más rápido con el formador.
func factor_progreso_joven() -> float:
	return 1.4 if dt_tiene("formador") else 1.0

## Techo extra de las camadas de cantera. Se suma al de `Staff.techo_cantera()`
## y al de `Instalaciones.techo_cantera()`, que miden otras cosas.
func techo_cantera_dt() -> int:
	if dt_tiene("academia"):
		return 3
	if dt_tiene("formador"):
		return 2
	return 0

## Cuánto pegan las instrucciones dadas en vivo durante el partido.
func factor_instrucciones() -> float:
	return 1.5 if dt_tiene("bloque") else 1.0

## Se ve la táctica del rival en la previa.
func ve_tactica_rival() -> bool:
	return dt_tiene("lectura")

## Cuánto sube el sueldo del entrenador por su fama.
func factor_sueldo_dt() -> float:
	return 1.15 if dt_tiene("carisma") else 1.0

## Los sueldos del cuerpo técnico con el descuento del contable.
func factor_sueldo_staff() -> float:
	return 0.85 if dt_tiene("contable") else 1.0

## Cuánto más rápido se apaga una funa en la prensa.
func factor_apagar_funa() -> float:
	return 2.0 if dt_tiene("mediatico") else 1.0

## Cuánto más rápido baja la ansiedad del vestuario cada semana.
func factor_calma() -> float:
	return 2.0 if dt_tiene("psicologo") else 1.0

## Lo que se le suma a la probabilidad de mediar con éxito entre camarillas.
func bono_mediacion() -> float:
	return 0.18 if dt_tiene("mediador") else 0.0

## Multas y normas internas rinden el doble.
func multas_dobles() -> bool:
	return dt_tiene("duro")

## Inmune a las rebeliones de vestuario.
func vestuario_de_hierro() -> bool:
	return dt_tiene("lider")

## Puede comprar acciones de clubes filiales.
func puede_comprar_filiales() -> bool:
	return dt_tiene("magnate")

## Lo que se le suma a la probabilidad de que un jugador acepte venir. Son los
## dos bonos que el HTML sumaba en la puerta de fichajes.
func bono_fichajes() -> float:
	var b := 0.0
	if dt_tiene("icono"):
		b += 0.10
	if dt_tiene("negociador"):
		b += 0.06
	return b

## Y lo que se le suma a la negociación con agentes, que en el HTML pesaba
## distinto: aquí el negociador manda y el ícono acompaña.
func bono_agentes() -> float:
	var b := 0.0
	if dt_tiene("negociador"):
		b += 0.08
	if dt_tiene("icono"):
		b += 0.06
	return b

## Informes de ojeo mucho más precisos.
func ojeo_preciso() -> bool:
	return dt_tiene("cazador")

# ---------------------------------------------------------------------------
#  GUARDAR
# ---------------------------------------------------------------------------

## Solo se guardan los jugadores que tienen algo que guardar. En un mundo de
## once mil futbolistas la inmensa mayoría no ha aprendido nada ni tiene puntos,
## y escribir once mil diccionarios vacíos engorda la partida sin decir nada: el
## guardado de este juego ya costó una depuración entera por tamaño.
func a_dic() -> Dictionary:
	var jug := {}
	for id: String in _habs:
		var l: Array = _habs[id]
		if not l.is_empty():
			jug[id] = {"habs": l.duplicate()}
	for id: String in _puntos:
		if int(_puntos[id]) > 0:
			if not jug.has(id):
				jug[id] = {}
			jug[id]["pts"] = int(_puntos[id])
	for id: String in _subidas:
		if int(_subidas[id]) > 0:
			if not jug.has(id):
				jug[id] = {}
			jug[id]["sub"] = int(_subidas[id])
	return {
		"mentorias": mentorias.duplicate(true),
		"foco": foco,
		"intensidad": intensidad,
		"dias": dias.duplicate(),
		"individual": individual.duplicate(true),
		"prioritarios": prioritarios.duplicate(),
		"concentracion": concentracion,
		"pretemporada": pretemporada,
		"semanas": semanas_trabajadas,
		"dt_puntos": dt_puntos,
		"dt_nodos": dt_nodos.duplicate(),
		"jugadores": jug,
	}

func desde_dic(d: Dictionary) -> void:
	mentorias.clear()
	for m in d.get("mentorias", []):
		mentorias.append({
			"maestro": String(m.get("maestro", "")), "pupilo": String(m.get("pupilo", "")),
			"semanas": int(m.get("semanas", 0)), "subidas": int(m.get("subidas", 0)),
		})
	foco = String(d.get("foco", "tactico"))
	intensidad = String(d.get("intensidad", "media"))
	var ds: Array = d.get("dias", [])
	dias.clear()
	for x in ds:
		dias.append(String(x))
	if dias.size() != PLAN_POR_DEFECTO.size():
		dias.assign(PLAN_POR_DEFECTO)
	individual = (d.get("individual", {}) as Dictionary).duplicate(true)
	prioritarios.clear()
	for x in (d.get("prioritarios", []) as Array):
		prioritarios.append(String(x))
	concentracion = bool(d.get("concentracion", false))
	pretemporada = String(d.get("pretemporada", ""))
	semanas_trabajadas = int(d.get("semanas", 0))
	dt_puntos = int(d.get("dt_puntos", DT_PUNTOS_INICIALES))
	dt_nodos = (d.get("dt_nodos", {}) as Dictionary).duplicate()
	_habs.clear()
	_puntos.clear()
	_subidas.clear()
	var jug: Dictionary = d.get("jugadores", {})
	for id: String in jug:
		var f: Dictionary = jug[id]
		var l: Array = f.get("habs", [])
		if not l.is_empty():
			var limpia: Array = []
			for h in l:
				limpia.append(String(h))
			_habs[id] = limpia
		if int(f.get("pts", 0)) > 0:
			_puntos[id] = int(f["pts"])
		if int(f.get("sub", 0)) > 0:
			_subidas[id] = int(f["sub"])
