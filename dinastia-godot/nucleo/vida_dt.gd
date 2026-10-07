class_name VidaDT
extends RefCounted
## MI VIDA: LA VIDA DEL ENTRENADOR FUERA DEL CLUB (26-9-2026). Pedido del
## usuario: *"crea un menú que vaya a otro apartado: lo de la vida del
## jugador"* (el jugador eres tú, el DT).
##
## Lo que hay:
##   - CASA y TRANSPORTE: se pagan cada semana de tu patrimonio (el sueldo de DT
##     entra en `Roles.patrimonio`). Una casa mejor te deja descansar más.
##   - FAMILIA: pareja e hijos inventados (por hash, sin `Azar`), y lo contentos
##     que están contigo.
##   - EL EQUILIBRIO VIDA/TRABAJO: cuanto más trabajas, mejor preparas los
##     partidos (hasta un +3% en ataque y defensa), pero sube el estrés y la
##     familia te ve menos.
##   - ESTRÉS: sube con las derrotas y las semanas de trabajo sin respiro; baja
##     con el ocio, las vacaciones y una casa donde descansar. Con estrés alto el
##     vestuario te nota tenso; si se dispara, el médico te para una semana.
##   - OCIO: una actividad por semana (gimnasio, asado, escapada...).
##   - ASUNTOS DE LA VIDA: cada tanto pasa algo en casa y decides.
##
## Todo lo que se sortea sale de hashes: no se consume `Azar`.

signal noticia(titulo: String, cuerpo: String)
signal mentor(titulo: String, texto: String)

## clave -> [nombre, coste semanal, descanso (estrés que resta por semana), icono]
const VIVIENDAS := {
	"pension": ["Pieza en una pensión", 150, 0, "🛏️"],
	"depto": ["Departamento arrendado", 600, 1, "🏢"],
	"casa": ["Casa en un barrio tranquilo", 1200, 2, "🏠"],
	"jardin": ["Casa con jardín y quincho", 2200, 3, "🏡"],
	"mansion": ["Mansión con piscina", 5000, 4, "🏰"],
}
const ORDEN_VIVIENDA := ["pension", "depto", "casa", "jardin", "mansion"]
## clave -> [nombre, coste semanal, estrés que resta, icono]
const TRANSPORTES := {
	"micro": ["Transporte público", 0, 0, "🚌"],
	"usado": ["Auto usado", 120, 0, "🚗"],
	"familiar": ["Auto familiar nuevo", 300, 1, "🚙"],
	"deportivo": ["Deportivo", 900, 1, "🏎️"],
	"chofer": ["Auto con chofer", 1500, 2, "🚘"],
}
const ORDEN_TRANSPORTE := ["micro", "usado", "familiar", "deportivo", "chofer"]
## clave -> [nombre, coste, estrés, familia, icono]
const OCIO := {
	"gimnasio": ["Ir al gimnasio", 50, -4, 0, "🏋️"],
	"cena": ["Cena con la familia", 120, -3, 8, "🍽️"],
	"asado": ["Asado con los amigos", 150, -6, 2, "🔥"],
	"padel": ["Partido de pádel", 80, -5, 0, "🎾"],
	"pesca": ["Salir a pescar", 40, -5, 0, "🎣"],
	"concierto": ["Ir a un concierto", 200, -7, 4, "🎸"],
	"escapada": ["Escapada de fin de semana", 900, -12, 10, "🧳"],
	"lectura": ["Tarde de lectura", 0, -3, 0, "📚"],
}

const _PAREJAS := ["Carolina", "Daniela", "Francisca", "Valentina", "Javiera", "Andrea", "Paula",
	"Tomás", "Andrés", "Felipe", "Sebastián", "Marcela", "Lorena", "Ignacio"]
const _HIJOS := ["Martina", "Agustín", "Florencia", "Benjamín", "Sofía", "Vicente", "Emilia", "Lucas", "Isidora", "Mateo"]
const _MASCOTAS := ["Canela", "Toby", "Luna", "Pelusa", "Rocky", "Mora"]

var vivienda: String = "depto"
var transporte: String = "usado"
var balance: int = 60            ## 0 = todo familia, 100 = todo trabajo
var estres: int = 35
var familia: int = 65            ## lo contenta que está tu familia
var semanas_estres_alto: int = 0
var ocio_semana: int = -1        ## la última semana (abs) en que hiciste ocio
var baja_hasta: int = -1         ## semana abs hasta la que el médico te para
var pendiente: Dictionary = {}   ## asunto de la vida abierto
var perfil: Dictionary = {}      ## {pareja, hijos:[...], mascota}
var historial: Array = []        ## [{anio, semana, texto}], lo más nuevo primero
var bienvenida: bool = false
## LOS PRECIOS SIGUEN AL SUELDO (recorrido D4): con precios fijos, casa y auto
## costaban el 4% de lo que cobra un DT de club grande y no había decisión.
## `escala` = sueldo semanal / 2.800 (un departamento y un auto usado son
## entonces ~una cuarta parte del sueldo, en cualquier club).
var escala: float = 1.0

func actualizar_escala(roles: Roles) -> void:
	if roles != null:
		escala = clampf(float(roles.sueldo_semanal()) / 2800.0, 0.5, 40.0)

func precio(base: int) -> int:
	return int(round(float(base) * escala))

static func _h(t: String) -> int:
	return absi(t.hash())

static func _abs(anio: int, sem: int) -> int:
	return anio * 60 + sem

## Tu familia, inventada una vez por partida (por hash del club inicial).
func crear_perfil(semilla: String) -> void:
	if not perfil.is_empty():
		return
	var h := _h("vida|" + semilla)
	var hijos: Array = []
	for i in (h / 3) % 4:
		hijos.append({"nombre": _HIJOS[(h / (7 + i)) % _HIJOS.size()], "edad": 3 + (h / (11 + i * 5)) % 14})
	perfil = {
		"pareja": _PAREJAS[h % _PAREJAS.size()] if h % 5 != 0 else "",
		"hijos": hijos,
		"mascota": _MASCOTAS[(h / 13) % _MASCOTAS.size()] if (h / 17) % 2 == 0 else "",
	}

func coste_semanal() -> int:
	return precio(int(VIVIENDAS[vivienda][1]) + int(TRANSPORTES[transporte][1]))

## El plus de preparación de los partidos por trabajar más (lo aplica `Mundo`
## en `aplicar_bonificadores`). Con el médico parándote, nada.
func factor_trabajo(anio: int, sem: int) -> float:
	if baja_hasta >= _abs(anio, sem):
		return 0.98
	return 1.0 + float(clampi(balance - 50, 0, 50)) * 0.0006

func de_baja(anio: int, sem: int) -> bool:
	return baja_hasta >= _abs(anio, sem)

func cambiar_vivienda(clave: String, roles: Roles) -> String:
	if not VIVIENDAS.has(clave):
		return "esa casa no existe"
	if clave == vivienda:
		return "ya vives ahí"
	## La mudanza cuesta cuatro semanas de la casa nueva de golpe.
	var mudanza := precio(int(VIVIENDAS[clave][1]) * 4)
	if roles.patrimonio < mudanza:
		return "la mudanza cuesta %s y no te alcanza" % Cesiones.dinero(mudanza)
	roles.patrimonio -= mudanza
	var sube := ORDEN_VIVIENDA.find(clave) > ORDEN_VIVIENDA.find(vivienda)
	vivienda = clave
	familia = clampi(familia + (6 if sube else -4), 0, 100)
	_anotar("Te mudas a: %s." % String(VIVIENDAS[clave][0]))
	noticia.emit("%s Mudanza" % String(VIVIENDAS[clave][3]), "Te mudas a: %s. La mudanza costó %s." % [String(VIVIENDAS[clave][0]), Cesiones.dinero(mudanza)])
	return ""

func cambiar_transporte(clave: String, roles: Roles) -> String:
	if not TRANSPORTES.has(clave):
		return "eso no existe"
	if clave == transporte:
		return "ya lo tienes"
	var entrada := precio(int(TRANSPORTES[clave][1]) * 6)
	if roles.patrimonio < entrada:
		return "el pie cuesta %s y no te alcanza" % Cesiones.dinero(entrada)
	roles.patrimonio -= entrada
	transporte = clave
	_anotar("Ahora te mueves en: %s." % String(TRANSPORTES[clave][0]))
	return ""

func hacer_ocio(clave: String, roles: Roles, anio: int, sem: int) -> String:
	if not OCIO.has(clave):
		return "eso no existe"
	if ocio_semana == _abs(anio, sem):
		return "esta semana ya te diste un respiro"
	var o: Array = OCIO[clave]
	if roles.patrimonio < precio(int(o[1])):
		return "no te alcanza"
	roles.patrimonio -= precio(int(o[1]))
	ocio_semana = _abs(anio, sem)
	estres = clampi(estres + int(o[2]), 0, 100)
	familia = clampi(familia + int(o[3]), 0, 100)
	_anotar("%s %s." % [String(o[4]), String(o[0])])
	return ""

func _anotar(texto: String, anio: int = 0, sem: int = 0) -> void:
	historial.push_front({"anio": anio, "semana": sem, "texto": texto})
	if historial.size() > 30:
		historial.resize(30)

## Una vez por semana. `resultado`: 1 ganó, 0 empató, -1 perdió, 2 sin partido.
func semana(c: Club, roles: Roles, anio: int, sem: int, resultado: int) -> void:
	if c == null or roles == null:
		return
	crear_perfil(c.id)
	actualizar_escala(roles)
	if not bienvenida:
		bienvenida = true
		mentor.emit("Tu vida fuera del club", "Entrenar no es solo el club: tienes casa, familia y cabeza. Si trabajas sin parar prepararás mejor los partidos, pero el estrés se paga. Lo tienes todo en MI VIDA.")
	## Gastos de la casa y el transporte.
	var gasto := coste_semanal()
	roles.patrimonio -= gasto
	if roles.patrimonio < 0:
		## Sin plata, a lo más barato.
		vivienda = "depto" if vivienda != "pension" else "pension"
		transporte = "micro"
		roles.patrimonio = 0
		estres = clampi(estres + 8, 0, 100)
		noticia.emit("💸 Te ajustas el cinturón", "No te alcanza para la casa y el auto: vuelves a un departamento y al transporte público.")
	## El estrés de la semana.
	var d := int(float(balance - 50) / 8.0)
	match resultado:
		-1: d += 4
		1: d -= 2
	d -= int(VIVIENDAS[vivienda][2]) + int(TRANSPORTES[transporte][2])
	estres = clampi(estres + d, 0, 100)
	familia = clampi(familia - int(float(balance - 55) / 6.0), 0, 100)
	## Estrés alto sostenido: el médico te para una semana.
	semanas_estres_alto = semanas_estres_alto + 1 if estres >= 85 else 0
	if semanas_estres_alto >= 3 and baja_hasta < _abs(anio, sem):
		baja_hasta = _abs(anio, sem) + 1
		semanas_estres_alto = 0
		estres = clampi(estres - 25, 0, 100)
		noticia.emit("🩺 El médico te para", "Tres semanas al límite pasan factura: una semana de reposo. Tu ayudante dirige los entrenamientos y el equipo lo nota un poco.")
		_anotar("Una semana de reposo por estrés.", anio, sem)
	## Cada cuatro semanas el vestuario nota cómo estás.
	if sem % 4 == 0:
		if estres >= 70:
			for j: Jugador in c.plantilla:
				j.moral = clampi(j.moral - 1, 10, 99)
			noticia.emit("😬 Te notan tenso", "El plantel nota tu estrés en los entrenamientos (moral −1).")
		elif estres <= 30:
			for j: Jugador in c.plantilla:
				j.moral = clampi(j.moral + 1, 10, 99)
	## Asuntos de la vida.
	if pendiente.is_empty():
		_sortear_asunto(anio, sem)

const _ASUNTOS := [
	["cumple", "Es el cumpleaños de %s y cae el día del entrenamiento táctico.", "Ir al cumpleaños", "Quedarse en el entrenamiento"],
	["colegio", "Te llaman del colegio de %s: quieren hablar contigo esta semana.", "Ir a la reunión", "Mandar un mensaje y seguir trabajando"],
	["aniversario", "Es tu aniversario con %s.", "Cena romántica", "Lo celebran otro día"],
	["tele", "Un programa de televisión te invita a hablar de fútbol el domingo por la noche.", "Ir al programa (+patrimonio)", "Rechazarlo y descansar"],
	["vecino", "Tu vecino es hincha del rival de siempre y pone su bandera frente a tu casa.", "Tomárselo con humor", "Ir a reclamarle"],
	["mascota", "%s se escapó de casa justo antes del partido.", "Salir a buscarla", "Que la busque la familia"],
	["publicidad", "Una marca te ofrece protagonizar un anuncio.", "Aceptar (+patrimonio)", "No mezclar"],
]

func _sortear_asunto(anio: int, sem: int) -> void:
	var h := _h("asuntovida|%d|%d|%s" % [anio, sem, str(perfil)])
	if h % 6 != 0:
		return
	var a: Array = _ASUNTOS[(h / 6) % _ASUNTOS.size()]
	var hijos: Array = perfil.get("hijos", [])
	var quien := ""
	match String(a[0]):
		"cumple", "colegio":
			if hijos.is_empty():
				return
			quien = String((hijos[(h / 7) % hijos.size()] as Dictionary)["nombre"])
		"aniversario":
			quien = String(perfil.get("pareja", ""))
			if quien == "":
				return
		"mascota":
			quien = String(perfil.get("mascota", ""))
			if quien == "":
				return
	var texto := String(a[1]) % quien if String(a[1]).contains("%s") else String(a[1])
	pendiente = {"tipo": String(a[0]), "texto": texto, "a": String(a[2]), "b": String(a[3])}

## Resuelve el asunto abierto. Devuelve el texto del resultado.
func resolver(op: String, roles: Roles, c: Club, prensa: Prensa, anio: int, sem: int) -> String:
	if pendiente.is_empty():
		return ""
	var p := pendiente
	pendiente = {}
	var a := op == "a"
	var r := ""
	match String(p["tipo"]):
		"cumple", "colegio":
			if a:
				familia = clampi(familia + 12, 0, 100)
				estres = clampi(estres - 3, 0, 100)
				r = "Tu familia lo agradece. Tu ayudante se encargó de la sesión."
			else:
				familia = clampi(familia - 10, 0, 100)
				r = "Te quedaste trabajando. En casa no cayó bien."
		"aniversario":
			if a and roles.patrimonio >= precio(400):
				roles.patrimonio -= precio(400)
				familia = clampi(familia + 14, 0, 100)
				estres = clampi(estres - 5, 0, 100)
				r = "Una noche para recordar."
			else:
				familia = clampi(familia - 8, 0, 100)
				r = "Lo dejaron para otro día. No es lo mismo."
		"tele":
			if a:
				var pago := Eco.escalar(3000.0, float(c.rep))
				roles.patrimonio += pago
				estres = clampi(estres + 4, 0, 100)
				if prensa != null:
					prensa.mover_animo(1)
				r = "Cobraste %s y la hinchada te vio cercano." % Cesiones.dinero(pago)
			else:
				estres = clampi(estres - 3, 0, 100)
				r = "Domingo en casa, sin cámaras."
		"vecino":
			if a:
				estres = clampi(estres - 2, 0, 100)
				r = "Le regalaste una camiseta de tu club. Ahora saluda."
			else:
				estres = clampi(estres + 5, 0, 100)
				r = "La discusión terminó en las redes. Mejor no."
		"mascota":
			if a:
				familia = clampi(familia + 8, 0, 100)
				estres = clampi(estres + 3, 0, 100)
				r = "La encontraste a dos cuadras. Llegaste justo a la charla técnica."
			else:
				familia = clampi(familia - 6, 0, 100)
				r = "Apareció sola por la noche. En casa te lo recordarán."
		"publicidad":
			if a:
				var pago2 := Eco.escalar(6000.0, float(c.rep))
				roles.patrimonio += pago2
				estres = clampi(estres + 3, 0, 100)
				r = "Cobraste %s. Tus amigos no paran de mandarte el anuncio." % Cesiones.dinero(pago2)
			else:
				r = "Prefieres que hablen tus equipos, no tus anuncios."
	_anotar("%s → %s" % [String(p["texto"]), r], anio, sem)
	noticia.emit("🏠 Mi vida", r)
	return r

func a_dic() -> Dictionary:
	return {"viv": vivienda, "tr": transporte, "bal": balance, "es": estres, "fam": familia,
		"sea": semanas_estres_alto, "oc": ocio_semana, "baja": baja_hasta, "pend": pendiente,
		"perfil": perfil, "hist": historial, "bienv": bienvenida}

func desde_dic(d: Dictionary) -> void:
	vivienda = String(d.get("viv", "depto"))
	transporte = String(d.get("tr", "usado"))
	balance = int(d.get("bal", 60))
	estres = int(d.get("es", 35))
	familia = int(d.get("fam", 65))
	semanas_estres_alto = int(d.get("sea", 0))
	ocio_semana = int(d.get("oc", -1))
	baja_hasta = int(d.get("baja", -1))
	pendiente = (d.get("pend", {}) as Dictionary).duplicate(true)
	perfil = (d.get("perfil", {}) as Dictionary).duplicate(true)
	historial = (d.get("hist", []) as Array).duplicate(true)
	bienvenida = bool(d.get("bienv", false))
