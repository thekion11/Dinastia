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

## Una vez por semana. Devuelve lo que pasó (para las pruebas).
func semana(c: Club, obras: Instalaciones, anio: int, sem: int, prensa: Prensa) -> Array:
	var pasado: Array = []
	if c == null or obras == null:
		return pasado
	for clave: String in Instalaciones.CATALOGO:
		if obras.nivel(clave) <= 0:
			continue
		var t := de(c, clave)
		var car := String(t["caracter"])
		var rng := RandomNumberGenerator.new()
		rng.seed = absi(("evinst|%s|%s|%d|%d" % [c.id, clave, anio, sem]).hash())
		var r := rng.randf()
		## Los dos caracteres con evento propio.
		if car == "carismatico" and r < 0.012:
			for j: Jugador in c.plantilla:
				j.moral = clampi(j.moral + 2, 10, 99)
			noticia.emit("🍖 Asado del club", "%s (%s) organiza un asado con el plantel. Buen ambiente." % [String(t["nombre"]), String(t["puesto"]).to_lower()])
			pasado.append({"clave": clave, "tipo": "carisma"})
			continue
		if car == "conflictivo" and r < 0.008:
			var aumento := Eco.escalar(30000.0, float(c.rep))
			c.mover_saldo(-aumento)
			movimiento.emit("Aumento para %s" % String(t["nombre"]), -aumento)
			noticia.emit("💼 Pide aumento", "%s (%s) amenazó con irse y consiguió un aumento." % [String(t["nombre"]), String(t["puesto"]).to_lower()])
			pasado.append({"clave": clave, "tipo": "aumento"})
			continue
		var lista: Array = EVENTOS.get(clave, [])
		if lista.is_empty() or r >= PROB_BASE * float(CARACTERES[car][1]):
			continue
		var ev: Array = lista[rng.randi() % lista.size()]
		_aplicar(c, String(ev[1]), int(ev[2]), prensa, String(ev[0]))
		noticia.emit("🏢 %s" % String(Instalaciones.CATALOGO[clave][0]), "%s. (Al frente: %s.)" % [String(ev[0]), String(t["nombre"])])
		pasado.append({"clave": clave, "tipo": String(ev[1])})
	return pasado

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
