extends RefCounted
## (Parte 1 de 3 de `entrenamiento.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `entrenamiento.gd`, conserva la clase.)

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

func multiplicador_intensidad() -> float:
	return float(INTENSIDADES.get(intensidad, ["", 1.0])[1])

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
	maestro.cambiar_moral(5, "Entrenamiento")
	pupilo.cambiar_moral(8, "Entrenamiento")
	noticia.emit("Mentoría en la cantera",
		"%s apadrina a %s. Entrenarán juntos y el chico va a aprender de alguien que ya lo vivió todo." % [
			Nombres.visible(maestro.nombre), Nombres.visible(pupilo.nombre)])
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
					Nombres.visible(pupilo.nombre), Nombres.visible(maestro.nombre)])
		pupilo.cambiar_moral(1, "Entrenamiento")

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

## Los menores de 23 de TU club progresan un 40% más rápido con el formador.
func factor_progreso_joven() -> float:
	return 1.4 if dt_tiene("formador") else 1.0

func _lista(id: String) -> Array:
	if not _habs.has(id):
		_habs[id] = []
	return _habs[id]

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
