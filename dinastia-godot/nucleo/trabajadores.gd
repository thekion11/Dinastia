class_name Trabajadores
extends RefCounted
## LOS TRABAJADORES DE CADA INSTALACIÓN Y LO QUE PASA EN ELLAS (26-9-2026, plan
## maestro C10). Pedido: *"trabajadores de esos lugares con sus personalidades y
## eventos de los lugares"*. Cada instalación construida tiene una persona al
## frente -el chef del comedor, la psicóloga, el jardinero del estadio...- con su
## carácter, y cada tanto pasa algo: la caldera de la piscina se rompe, el chef
## estrena menú, un campo se inunda. El carácter cambia cuánto pasa:
##   - PERFECCIONISTA: casi nunca falla nada;
##   - TRABAJADOR: lo normal;
##   - DESPISTADO: el doble de averías;
##   - CARISMÁTICO: además, de vez en cuando levanta el ánimo del plantel;
##   - CONFLICTIVO: además, de vez en cuando pide un aumento.
## Nombres, caracteres y sorteos salen de hashes: sin `Azar`.

signal noticia(titulo: String, cuerpo: String)
signal movimiento(concepto: String, monto: int)

const PUESTO := {
	"trib": "Jefe de seguridad", "cal": "Jardinero del estadio", "med": "Jefa de enfermería",
	"ct": "Preparador jefe", "acad": "Coordinador de la academia", "com": "Encargada de la tienda",
	"gim": "Encargado del gimnasio", "resid": "Tutora de la residencia", "video": "Analista de vídeo",
	"rehab": "Fisioterapeuta jefe", "museo": "Conservador del museo", "park": "Jefe de accesos",
	"pren": "Jefa de prensa", "cocina": "Chef del club", "piscina": "Encargado de la piscina",
	"guarderia": "Educadora", "bienestar": "Psicóloga del club", "esports": "Coordinador de eSports",
	"huerto": "Hortelano",
}
const CARACTERES := {
	"perfeccionista": ["Perfeccionista", 0.5], "trabajador": ["Trabajador", 1.0],
	"despistado": ["Despistado", 2.0], "carismatico": ["Carismático", 1.0], "conflictivo": ["Conflictivo", 1.2],
}
## Probabilidad semanal base de que pase algo en UNA instalación.
const PROB_BASE := 0.012

## instalación -> [[texto, efecto, valor]]. Efectos: coste (dinero), moral
## (plantel), socios, animo (hinchada), forma (plantel).
const EVENTOS := {
	"piscina": [["La caldera de la piscina se rompe: dos semanas sin agua caliente", "coste", 60000]],
	"cocina": [["Intoxicación leve tras un marisco en mal estado", "forma", -4], ["El chef estrena menú y el plantel lo celebra", "moral", 2]],
	"gim": [["Un patrocinador dona maquinaria nueva al gimnasio", "moral", 1], ["Se rompe la cinta de correr de alto rendimiento", "coste", 25000]],
	"ct": [["Se inunda un campo de entrenamiento tras un temporal", "coste", 45000]],
	"med": [["Una inspección sanitaria felicita al centro médico", "animo", 1]],
	"resid": [["Un canterano se escapa de madrugada de la residencia", "moral", -1]],
	"museo": [["Una visita escolar llena el museo del club", "socios", 120]],
	"com": [["Se agota la camiseta nueva en la tienda oficial", "coste", -40000]],
	"video": [["Se cae el servidor de vídeo justo antes del partido", "coste", 15000]],
	"pren": [["Falla el micrófono en plena rueda de prensa y se hace viral", "animo", 1]],
	"cal": [["Una plaga de hongos obliga a resembrar parte del césped", "coste", 70000]],
	"trib": [["Se detecta una grieta en un vomitorio: obra urgente", "coste", 90000]],
	"acad": [["Un ojeador extranjero ronda los entrenamientos de la academia", "moral", 0]],
	"bienestar": [["La psicóloga organiza una charla sobre presión y el vestuario lo agradece", "moral", 2]],
	"guarderia": [["Fiesta familiar en la guardería del club", "moral", 1]],
	"esports": [["El equipo de eSports gana un torneo online", "socios", 80]],
	"huerto": [["La cosecha del huerto llega a la cocina del club", "forma", 2]],
	"park": [["Atasco monumental en los accesos del estadio", "animo", -1]],
	"rehab": [["El fisio jefe prueba una terapia nueva con buenos resultados", "forma", 2]],
}
const _NOMBRES := ["Amanda", "Bruno", "Camila", "Danilo", "Elena", "Fernando", "Gabriela", "Héctor",
	"Irene", "Jaime", "Karen", "Luis", "Marta", "Nicolás", "Olga", "Pedro", "Rocío", "Sergio", "Tamara", "Víctor"]
## Los nombres de arriba alternan mujer/hombre en ese orden (índice par = mujer),
## salvo algunos; estos son los femeninos, para el texto ("la"/"el").
const _FEMENINOS := ["Amanda", "Camila", "Elena", "Gabriela", "Irene", "Karen", "Marta", "Olga", "Rocío", "Tamara"]
const _APELLIDOS := ["Aguilera", "Bravo", "Cáceres", "Durán", "Espinoza", "Farías", "Godoy", "Henríquez",
	"Ibáñez", "Jiménez", "Leiva", "Mardones", "Navarro", "Orellana", "Palma", "Riquelme", "Saavedra", "Toro"]

## De quién es cada instalación. Se calcula siempre del hash del club: no hace
## falta guardarlo.
static func de(c: Club, clave: String) -> Dictionary:
	if c == null:
		return {}
	var h := absi(("trab|%s|%s" % [c.id, clave]).hash())
	var car := CARACTERES.keys()
	return {
		"nombre": "%s %s" % [_NOMBRES[h % _NOMBRES.size()], _APELLIDOS[absi(("ap%d" % h).hash()) % _APELLIDOS.size()]],
		"puesto": String(PUESTO.get(clave, "Encargado")),
		"caracter": String(car[(h / 13) % car.size()]),
	}

static func texto_de(c: Club, clave: String) -> String:
	var t := de(c, clave)
	if t.is_empty():
		return ""
	return "%s · %s (%s)" % [String(t["puesto"]), String(t["nombre"]), String(CARACTERES[String(t["caracter"])][0]).to_lower()]

## ============================================================================
##  EL EQUIPO DE CADA INSTALACIÓN (26-9-2026, segunda pasada)
## ============================================================================
## Pedido: *"que las instalaciones tengan trabajadores reales y eventos mejor"*.
## Antes había UNA persona por instalación que solo existía como texto y cuyos
## eventos se aplicaban solos. Ahora:
##   - cada instalación tiene su EQUIPO: el encargado de siempre y, con nivel 3
##     y 6, uno o dos más (su puesto propio: la fisio del centro médico, el
##     ayudante de cocina, el socorrista...);
##   - cada persona tiene habilidad, ánimo, sueldo y antigüedad que cambian con
##     las semanas: el perfeccionista mejora, el despistado no; nadie aguanta
##     sin quejarse un sueldo congelado años;
##   - el equipo MUEVE la instalación: `Instalaciones.factor_personal` sube
##     hasta +15 % con gente buena y contenta y baja hasta -20 % con gente floja,
##     quemada o con una avería sin arreglar;
##   - y hay ASUNTOS CON DECISIÓN en el despacho (dos salidas, las dos cuestan
##     algo): piden aumento, un rival quiere llevárselos, proponen una mejora,
##     cometen un error, piden formación, se rompe algo...
## Todo se guarda con la partida (`a_dic`/`desde_dic`).

const OTROS_PUESTOS := {
	"trib": ["Jefe de acomodadores", "Técnico de mantenimiento"], "cal": ["Técnico de riego", "Electricista del estadio"],
	"med": ["Fisioterapeuta", "Médica deportiva"], "ct": ["Utilero", "Analista de rendimiento"],
	"acad": ["Tutor escolar", "Entrenador de porteros juvenil"], "com": ["Dependiente", "Encargado de almacén"],
	"gim": ["Readaptador", "Monitor de fuerza"], "resid": ["Cocinera de la residencia", "Monitor nocturno"],
	"video": ["Técnico de cámaras", "Editora de vídeo"], "rehab": ["Masajista", "Hidroterapeuta"],
	"museo": ["Guía del museo", "Restauradora"], "park": ["Aparcacoches", "Vigilante"],
	"pren": ["Community manager", "Fotógrafo oficial"], "cocina": ["Ayudante de cocina", "Nutricionista"],
	"piscina": ["Socorrista", "Técnico de la depuradora"], "guarderia": ["Auxiliar", "Monitora de juegos"],
	"bienestar": ["Capellán", "Terapeuta"], "esports": ["Jugador profesional", "Streamer del club"],
	"huerto": ["Ayudante de huerto", "Apicultora"],
}

## El de la partida en curso (lo fija `Mundo`), para las fichas del mapa 3D.
static var actual: Trabajadores = null

var equipos: Dictionary = {}     ## instalación -> Array[Dictionary] (personas)
var averias: Dictionary = {}     ## instalación -> semanas que le quedan
var pendiente: Dictionary = {}   ## el asunto a decidir: {id, inst, idx, texto, a, b, ...}
var _sig := 0

## Una persona nueva, del hash (el encargado sale igual que `de()`).
static func _persona(c: Club, clave: String, i: int, semilla: String) -> Dictionary:
	var h := absi(("trab|%s|%s|%d|%s" % [c.id, clave, i, semilla]).hash())
	var car := CARACTERES.keys()
	var nombre := "%s %s" % [_NOMBRES[h % _NOMBRES.size()], _APELLIDOS[absi(("ap%d" % h).hash()) % _APELLIDOS.size()]]
	var puesto := String(PUESTO.get(clave, "Encargado"))
	var caracter := String(car[(h / 13) % car.size()])
	if i == 0 and semilla == "":
		var jefe := de(c, clave)
		nombre = String(jefe["nombre"])
		caracter = String(jefe["caracter"])
	elif i > 0:
		var otros: Array = OTROS_PUESTOS.get(clave, ["Ayudante", "Auxiliar"])
		puesto = String(otros[(i - 1) % otros.size()])
	return {
		"nombre": nombre, "puesto": puesto, "caracter": caracter,
		"hab": 45 + (h / 7) % 41, "moral": 70, "edad": 24 + (h / 11) % 34,
		"semanas": 0, "sueldo_sube": 0,
	}

static func es_mujer(t: Dictionary) -> bool:
	return String(t.get("nombre", "")).get_slice(" ", 0) in _FEMENINOS

## El equipo de una instalación (lo arma si hace falta).
func equipo(c: Club, obras: Instalaciones, clave: String) -> Array:
	if c == null or obras == null or obras.nivel(clave) <= 0:
		return []
	var n := 1 + (1 if obras.nivel(clave) >= 3 else 0) + (1 if obras.nivel(clave) >= 6 else 0)
	var e: Array = equipos.get(clave, [])
	while e.size() < n:
		e.append(_persona(c, clave, e.size(), ""))
	equipos[clave] = e
	return e

## Cuánto rinde la instalación por su gente: 0,75-1,15.
func factor(clave: String) -> float:
	var e: Array = equipos.get(clave, [])
	if e.is_empty():
		return 1.0
	var suma := 0.0
	for t: Dictionary in e:
		suma += float(t["hab"]) / 100.0 * (0.6 + 0.4 * float(t["moral"]) / 100.0)
	var f := 0.8 + 0.45 * (suma / float(e.size()))
	if int(averias.get(clave, 0)) > 0:
		f -= 0.2
	return clampf(f, 0.75, 1.15)

## Una vez por semana. Devuelve lo que pasó (para las pruebas).
func semana(c: Club, obras: Instalaciones, anio: int, sem: int, prensa: Prensa) -> Array:
	var pasado: Array = []
	if c == null or obras == null:
		return pasado
	for clave: String in Instalaciones.CATALOGO:
		if obras.nivel(clave) <= 0:
			continue
		## El equipo envejece en el puesto: habilidad y ánimo se mueven.
		var eq := equipo(c, obras, clave)
		for t: Dictionary in eq:
			t["semanas"] = int(t["semanas"]) + 1
			var car_t := String(t["caracter"])
			if sem % 4 == 0:
				var sube := 1 if car_t in ["perfeccionista", "trabajador"] else 0
				t["hab"] = clampi(int(t["hab"]) + sube, 20, 99)
			## El ánimo vuelve despacio a su punto, que baja con los años sin
			## aumento (a partir del segundo año).
			var punto := 72 - clampi((int(t["semanas"]) - int(t["sueldo_sube"])) / 52 * 6, 0, 24)
			t["moral"] = int(t["moral"]) + signi(punto - int(t["moral"]))
		if int(averias.get(clave, 0)) > 0:
			averias[clave] = int(averias[clave]) - 1
		obras.factor_personal[clave] = factor(clave)
		var t0 := de(c, clave)
		var car := String(t0["caracter"])
		var rng := RandomNumberGenerator.new()
		rng.seed = absi(("evinst|%s|%s|%d|%d" % [c.id, clave, anio, sem]).hash())
		var r := rng.randf()
		## Los dos caracteres con evento propio.
		if car == "carismatico" and r < 0.012:
			for j: Jugador in c.plantilla:
				j.moral = clampi(j.moral + 2, 10, 99)
			noticia.emit("🍖 Asado del club", "%s (%s) organiza un asado con el plantel. Buen ambiente." % [String(t0["nombre"]), String(t0["puesto"]).to_lower()])
			pasado.append({"clave": clave, "tipo": "carisma"})
			continue
		if car == "conflictivo" and r < 0.008:
			var aumento := Eco.escalar(30000.0, float(c.rep))
			c.mover_saldo(-aumento)
			movimiento.emit("Aumento para %s" % String(t0["nombre"]), -aumento)
			noticia.emit("💼 Pide aumento", "%s (%s) amenazó con irse y consiguió un aumento." % [String(t0["nombre"]), String(t0["puesto"]).to_lower()])
			if not eq.is_empty():
				eq[0]["sueldo_sube"] = int(eq[0]["semanas"])
			pasado.append({"clave": clave, "tipo": "aumento"})
			continue
		var lista: Array = EVENTOS.get(clave, [])
		if lista.is_empty() or r >= PROB_BASE * float(CARACTERES[car][1]):
			continue
		var ev: Array = lista[rng.randi() % lista.size()]
		_aplicar(c, String(ev[1]), int(ev[2]), prensa, String(ev[0]))
		noticia.emit("🏢 %s" % String(Instalaciones.CATALOGO[clave][0]), "%s. (Al frente: %s.)" % [String(ev[0]), String(t0["nombre"])])
		pasado.append({"clave": clave, "tipo": String(ev[1])})
	## Un asunto con decisión, de vez en cuando (y nunca dos a la vez).
	if pendiente.is_empty():
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = absi(("asunto_inst|%s|%d|%d" % [c.id, anio, sem]).hash())
		if rng2.randf() < 0.05:
			_sortear_asunto(c, obras, rng2)
	return pasado

## ------------------------------------------------------------ ASUNTOS

## [id, texto, opción a, opción b]. {n} nombre, {p} puesto, {i} instalación.
const ASUNTOS := [
	["aumento", "{n} ({p}, {i}) pide un aumento: dice que en otro club le pagan un 30 % más.", "Subirle el sueldo", "No hay presupuesto"],
	["rival", "Un club rival quiere llevarse a {n} ({p}, {i}) y le ofrece el doble.", "Igualar la oferta", "Dejarle ir"],
	["curso", "{n} ({p}, {i}) quiere hacer un curso de especialización en el extranjero.", "Pagarle el curso", "Ahora no es el momento"],
	["error", "{n} ({p}, {i}) cometió un error grave y la prensa ya lo sabe.", "Despedirle", "Darle otra oportunidad"],
	["idea", "{n} ({p}, {i}) propone una mejora: {idea}.", "Invertir en la idea", "Guardarla para más adelante"],
	["averia", "Se rompe algo importante en {i}: {averia}. {n} pide arreglarlo ya.", "Arreglarlo bien", "Parchearlo por ahora"],
	["homenaje", "{n} ({p}) cumple años en el club y el plantel quiere hacerle un homenaje.", "Homenaje en el estadio", "Algo íntimo en el vestuario"],
]
const IDEAS := {
	"cocina": "un menú con productos del huerto del club", "gim": "sensores de carga en cada máquina",
	"med": "un protocolo de prevención de lesiones musculares", "ct": "chalecos GPS para cada entrenamiento",
	"acad": "una escuela del club en otra ciudad", "com": "una línea de camisetas retro",
	"museo": "una sala interactiva con realidad virtual", "pren": "un canal propio de vídeo",
	"video": "análisis con inteligencia artificial del rival", "piscina": "sesiones de recuperación en agua fría",
	"resid": "clases de idiomas para los canteranos", "rehab": "una cámara hiperbárica",
	"guarderia": "un día de familias en el estadio", "bienestar": "un programa de salud mental para el plantel",
	"esports": "un torneo abierto a los hinchas", "huerto": "vender la cosecha en la tienda",
	"cal": "un césped híbrido", "trib": "asientos calefactados en la tribuna", "park": "carga para coches eléctricos",
}
const AVERIAS := {
	"piscina": "la caldera", "cocina": "la cámara frigorífica", "gim": "el sistema de ventilación",
	"med": "el ecógrafo", "ct": "el riego de los campos", "video": "el servidor de vídeo",
	"pren": "la sala de conferencias (goteras)", "cal": "las torres de iluminación", "trib": "un vomitorio",
	"com": "la caja registradora", "museo": "la climatización de las vitrinas", "rehab": "la piscina de hidroterapia",
	"resid": "la calefacción", "esports": "los equipos de juego", "guarderia": "el techo del patio",
	"bienestar": "la sala de meditación", "huerto": "el riego por goteo", "park": "la barrera de entrada",
	"acad": "los vestuarios juveniles",
}

func _sortear_asunto(c: Club, obras: Instalaciones, rng: RandomNumberGenerator) -> void:
	var hechas: Array = []
	for k: String in Instalaciones.CATALOGO:
		if obras.nivel(k) > 0:
			hechas.append(k)
	if hechas.is_empty():
		return
	var clave: String = hechas[rng.randi() % hechas.size()]
	var eq := equipo(c, obras, clave)
	var idx := rng.randi() % eq.size()
	var t: Dictionary = eq[idx]
	## El carácter pesa en qué pasa: el despistado se equivoca, el conflictivo
	## pide más, el perfeccionista propone.
	var pesos := {"aumento": 2.0, "rival": 1.0, "curso": 1.0, "error": 1.0, "idea": 1.0, "averia": 1.2, "homenaje": 0.4}
	match String(t["caracter"]):
		"conflictivo": pesos["aumento"] = 5.0
		"despistado": pesos["error"] = 4.0
		"perfeccionista":
			pesos["idea"] = 4.0
			pesos["error"] = 0.1
		"carismatico": pesos["homenaje"] = 2.0
	if int(t["semanas"]) < 52:
		pesos["homenaje"] = 0.0
	var total := 0.0
	for k2: String in pesos:
		total += float(pesos[k2])
	var tiro := rng.randf() * total
	var elegido := "aumento"
	for k3: String in pesos:
		tiro -= float(pesos[k3])
		if tiro <= 0.0:
			elegido = k3
			break
	for a: Array in ASUNTOS:
		if String(a[0]) == elegido:
			var txt := String(a[1]).format({"n": String(t["nombre"]), "p": String(t["puesto"]).to_lower(),
				"i": String(Instalaciones.CATALOGO[clave][0]).to_lower(),
				"idea": String(IDEAS.get(clave, "una forma nueva de trabajar")),
				"averia": String(AVERIAS.get(clave, "una instalación clave"))})
			pendiente = {"id": elegido, "inst": clave, "idx": idx, "texto": txt, "a": String(a[2]), "b": String(a[3]),
				"nombre": String(t["nombre"]), "puesto": String(t["puesto"])}
			noticia.emit("🏢 Asunto en %s" % String(Instalaciones.CATALOGO[clave][0]), "Hay algo que decidir en el despacho.")
			return

## Firma el asunto. Devuelve {titulo, cuerpo}.
func resolver(op: String, c: Club, obras: Instalaciones, prensa: Prensa) -> Dictionary:
	if pendiente.is_empty() or c == null:
		return {}
	var p := pendiente
	pendiente = {}
	var si := op == "a"
	var clave := String(p["inst"])
	var eq: Array = equipos.get(clave, [])
	var idx := int(p["idx"])
	if idx >= eq.size():
		return {}
	var t: Dictionary = eq[idx]
	var nombre := String(t["nombre"])
	var rep := float(c.rep)
	var out := {"titulo": "", "cuerpo": ""}
	match String(p["id"]):
		"aumento":
			if si:
				_gastar(c, Eco.escalar(40000.0, rep), "Aumento para %s" % nombre)
				t["moral"] = mini(99, int(t["moral"]) + 25)
				t["sueldo_sube"] = int(t["semanas"])
				out = {"titulo": "Aumento concedido", "cuerpo": "%s sigue con más ganas que nunca." % nombre}
			else:
				t["moral"] = maxi(10, int(t["moral"]) - 20)
				if String(t["caracter"]) == "conflictivo":
					eq[idx] = _reemplazo(c, clave, idx, t)
					out = {"titulo": "%s se va" % nombre, "cuerpo": "Se despidió dando un portazo. Llega %s, con menos experiencia." % String(eq[idx]["nombre"])}
				else:
					out = {"titulo": "Sin aumento", "cuerpo": "%s lo acepta, pero se nota el malestar." % nombre}
		"rival":
			if si:
				_gastar(c, Eco.escalar(60000.0, rep), "Retener a %s" % nombre)
				t["moral"] = mini(99, int(t["moral"]) + 15)
				t["sueldo_sube"] = int(t["semanas"])
				out = {"titulo": "%s se queda" % nombre, "cuerpo": "El club igualó la oferta. Mensaje claro al resto del personal."}
			else:
				eq[idx] = _reemplazo(c, clave, idx, t)
				out = {"titulo": "%s se marcha" % nombre, "cuerpo": "Se va al rival. %s ocupa su puesto." % String(eq[idx]["nombre"])}
		"curso":
			if si:
				_gastar(c, Eco.escalar(25000.0, rep), "Formación de %s" % nombre)
				t["hab"] = mini(99, int(t["hab"]) + 8)
				t["moral"] = mini(99, int(t["moral"]) + 10)
				out = {"titulo": "Vuelve con ideas nuevas", "cuerpo": "%s aprendió mucho: la instalación lo nota." % nombre}
			else:
				t["moral"] = maxi(10, int(t["moral"]) - 8)
				out = {"titulo": "Curso aplazado", "cuerpo": "%s lo entiende, aunque le hacía ilusión." % nombre}
		"error":
			if si:
				eq[idx] = _reemplazo(c, clave, idx, t)
				for o: Dictionary in eq:
					o["moral"] = maxi(10, int(o["moral"]) - 5)
				if prensa != null:
					prensa.mover_animo(1)
				out = {"titulo": "Despedido", "cuerpo": "%s deja el club. El resto del personal toma nota. Entra %s." % [nombre, String(eq[idx]["nombre"])]}
			else:
				t["moral"] = mini(99, int(t["moral"]) + 12)
				t["hab"] = mini(99, int(t["hab"]) + 2)
				if prensa != null:
					prensa.mover_animo(-1)
				out = {"titulo": "Segunda oportunidad", "cuerpo": "%s promete que no volverá a pasar. La prensa lo critica un poco." % nombre}
		"idea":
			if si:
				_gastar(c, Eco.escalar(50000.0, rep), "Idea de %s" % nombre)
				t["hab"] = mini(99, int(t["hab"]) + 4)
				t["moral"] = mini(99, int(t["moral"]) + 15)
				for j: Jugador in c.plantilla:
					j.forma = clampi(j.forma + 2, 10, 99)
				c.socios += 150
				out = {"titulo": "La idea funciona", "cuerpo": "La propuesta de %s ya está en marcha: el plantel y los socios lo notan." % nombre}
			else:
				t["moral"] = maxi(10, int(t["moral"]) - 6)
				out = {"titulo": "Idea en el cajón", "cuerpo": "%s guarda su propuesta para más adelante." % nombre}
		"averia":
			if si:
				_gastar(c, Eco.escalar(45000.0, rep), "Reparación en %s" % String(Instalaciones.CATALOGO[clave][0]))
				out = {"titulo": "Arreglado", "cuerpo": "Técnicos toda la semana: %s funciona como nuevo." % String(AVERIAS.get(clave, "todo"))}
			else:
				_gastar(c, Eco.escalar(8000.0, rep), "Parche en %s" % String(Instalaciones.CATALOGO[clave][0]))
				averias[clave] = 6
				out = {"titulo": "Parche provisional", "cuerpo": "Funciona a medias: la instalación rinde menos durante seis semanas."}
		"homenaje":
			if si:
				_gastar(c, Eco.escalar(15000.0, rep), "Homenaje a %s" % nombre)
				if prensa != null:
					prensa.mover_animo(2)
				t["moral"] = 99
				out = {"titulo": "Homenaje en el estadio", "cuerpo": "El estadio entero aplaudió a %s. Muchos no sabían quién era; ahora sí." % nombre}
			else:
				t["moral"] = mini(99, int(t["moral"]) + 15)
				for j: Jugador in c.plantilla:
					j.moral = clampi(j.moral + 1, 10, 99)
				out = {"titulo": "Homenaje en el vestuario", "cuerpo": "Tarta, camiseta firmada y abrazos para %s." % nombre}
	if obras != null:
		obras.factor_personal[clave] = factor(clave)
	return out

func _gastar(c: Club, monto: int, concepto: String) -> void:
	c.mover_saldo(-monto)
	movimiento.emit(concepto, -monto)

## Quien entra a cubrir un puesto: algo menos de habilidad al principio.
func _reemplazo(c: Club, clave: String, idx: int, antes: Dictionary) -> Dictionary:
	_sig += 1
	var n := _persona(c, clave, idx, "r%d" % _sig)
	n["puesto"] = String(antes["puesto"])
	n["hab"] = clampi(int(antes["hab"]) - 8 + (_sig * 7) % 13, 30, 90)
	return n

## Texto corto del equipo entero (fichas de instalación).
func texto_equipo(c: Club, obras: Instalaciones, clave: String) -> String:
	var partes: Array[String] = []
	for t: Dictionary in equipo(c, obras, clave):
		partes.append("%s · %s (%s, hab. %d, ánimo %d)" % [String(t["puesto"]), String(t["nombre"]),
			String(CARACTERES[String(t["caracter"])][0]).to_lower(), int(t["hab"]), int(t["moral"])])
	if int(averias.get(clave, 0)) > 0:
		partes.append("⚠ Avería: %d semanas" % int(averias[clave]))
	return "\n".join(partes)

func a_dic() -> Dictionary:
	return {"equipos": equipos.duplicate(true), "averias": averias.duplicate(), "pendiente": pendiente.duplicate(), "sig": _sig}

func desde_dic(d: Dictionary) -> void:
	equipos = (d.get("equipos", {}) as Dictionary).duplicate(true)
	averias = (d.get("averias", {}) as Dictionary).duplicate()
	pendiente = (d.get("pendiente", {}) as Dictionary).duplicate()
	_sig = int(d.get("sig", 0))

func _aplicar(c: Club, efecto: String, valor: int, prensa: Prensa, concepto: String) -> void:
	match efecto:
		"coste":
			var monto := Eco.escalar(float(absi(valor)), float(c.rep)) * (1 if valor < 0 else -1)
			c.mover_saldo(monto)
			movimiento.emit(concepto, monto)
		"moral":
			for j: Jugador in c.plantilla:
				j.moral = clampi(j.moral + valor, 10, 99)
		"forma":
			for j: Jugador in c.plantilla:
				j.forma = clampi(j.forma + valor, 10, 99)
		"socios":
			c.socios += valor
		"animo":
			if prensa != null:
				prensa.mover_animo(valor)
