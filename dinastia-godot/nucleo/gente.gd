class_name Gente
extends RefCounted
## LA GENTE DEL CLUB: las diez personas que llevan aquí más años que tú.
##
## `vGente()` del HTML. El utilero, el jardinero, la cocinera, el conserje, la
## secretaria, el chófer, el médico veterano, el viejo de la puerta 7, el
## encargado de prensa y el ojeador jubilado.
##
## POR QUÉ EXISTE ESTO. No mueve ninguna estadística del partido y no es un
## sistema de gestión: es lo que hace que un club sea un SITIO y no una hoja de
## cálculo con escudo. Tratarlos bien no sale en ninguna tabla, y esa es justo
## la gracia —el HTML lo dice con esas palabras en la propia pantalla—.
##
## Lo único que hacen de verdad es CONTARTE COSAS. Cada uno mira el club desde
## su rincón: el jardinero habla del césped, el médico de los lesionados, la
## secretaria de la caja. Son diez termómetros distintos del mismo club, y por
## eso la frase de cada uno depende del contexto y no de un sorteo.

## clave, nombre del puesto, icono, y qué clase de persona es.
const ROLES := [
	["utilero", "Utilero", "🧺", "Lleva treinta años lavando camisetas y ha visto pasar a todos."],
	["jardinero", "Jefe de cancha", "🌱", "El césped es suyo; los partidos son un mal necesario."],
	["cocinera", "Cocinera del plantel", "🍲", "Sabe quién come bien y quién llega con olor a asado."],
	["conserje", "Conserje del estadio", "🔑", "Abre y cierra. Se entera de todo porque nadie lo mira."],
	["secretaria", "Secretaría del club", "📋", "Contratos, permisos y llamadas del presidente."],
	["chofer", "Chófer del bus", "🚌", "Conduce en silencio y escucha absolutamente todo."],
	["medico", "Médico veterano", "🩺", "Lleva más tiempo que el edificio y no se muerde la lengua."],
	["hincha", "El de la puerta 7", "📣", "No trabaja aquí, pero está aquí desde antes que tú."],
	["prensa", "Encargado de prensa", "🎙️", "Le toca apagar los incendios que enciendes en rueda."],
	["ojeador", "Ojeador jubilado", "👓", "Ya no cobra, pero sigue yendo a ver a los chicos."],
]

const PERFILES := ["gruñón", "cariñoso", "irónico", "supersticioso", "trabajador", "chismoso"]

## Cuántas charlas caben por semana. Tres y no diez: si se pudiera hablar con
## todos cada semana dejaría de ser una elección y sería una ronda de clics.
const CHARLAS_POR_SEMANA := 3

var _ref: WeakRef
## clave -> {nombre, edad, anios, confianza, perfil, ultima_semana}
var fichas: Dictionary = {}
var charlas_esta_semana: int = 0

func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo

## Crea a las diez personas si no existen. Se llama al empezar y al cargar.
func armar() -> void:
	if not fichas.is_empty():
		return
	for fila: Array in ROLES:
		var k := String(fila[0])
		var edad := Azar.ent(31, 64)
		if k == "hincha":
			edad = Azar.ent(58, 79)
		elif k == "ojeador":
			edad = Azar.ent(62, 76)
		fichas[k] = {
			"nombre": _nombre_al_azar(),
			"edad": edad,
			"anios": Azar.ent(2, 34),
			"confianza": Azar.ent(45, 65),
			"perfil": String(Azar.uno(PERFILES)),
			"ultima_semana": 0,
		}

func ficha(clave: String) -> Dictionary:
	return fichas.get(clave, {})

func confianza_media() -> int:
	if fichas.is_empty():
		return 0
	var s := 0
	for k: String in fichas:
		s += int((fichas[k] as Dictionary).get("confianza", 50))
	return int(round(float(s) / float(fichas.size())))

## Con quién ya hablaste esta semana.
func hablado_esta_semana(clave: String) -> bool:
	var m := _mundo()
	if m == null:
		return false
	return int(ficha(clave).get("ultima_semana", 0)) == m.semana

## Charlar con alguien. Sube su confianza y, si es alta, da un efecto pequeño y
## concreto según de quién sea: el jardinero cuida el césped, el médico avisa,
## la cocinera cuida el físico. Devuelve lo que pasó.
##
## Los efectos son deliberadamente PEQUEÑOS. Si hablar con el utilero diera dos
## puntos de media, esto dejaría de ser el alma del club y sería otra pestaña
## que hay que farmear cada semana.
func charlar(clave: String) -> String:
	var m := _mundo()
	if m == null or not fichas.has(clave):
		return ""
	if charlas_esta_semana >= CHARLAS_POR_SEMANA:
		return "Ya has dedicado bastante tiempo a la gente esta semana. Vuelve el lunes."
	if hablado_esta_semana(clave):
		return "Ya hablaste con esta persona esta semana."
	var f: Dictionary = fichas[clave]
	f["ultima_semana"] = m.semana
	f["confianza"] = clampi(int(f["confianza"]) + Azar.ent(2, 6), 0, 100)
	charlas_esta_semana += 1
	var c := m.mi_club()
	var conf := int(f["confianza"])
	## Por debajo de 60 te escuchan pero no te dan nada: la confianza hay que
	## ganársela antes de que sirva para algo.
	if conf < 60 or c == null:
		return "Charla corta. Te escucha, asiente y sigue con lo suyo."
	match clave:
		"cocinera":
			for j in c.plantilla:
				j.fisico = clampi(j.fisico + 1, 10, 100)
			return "Te cuenta que ha cambiado el menú de la semana. El plantel llega un punto más entero."
		"jardinero":
			return "Te enseña el césped como quien enseña un hijo. Lo va a dejar impecable para el domingo."
		"medico":
			var tocados := 0
			for j2 in c.plantilla:
				if j2.fisico < 62:
					tocados += 1
			return "Te avisa sin rodeos: hay %d que llegan justos. Él no los sacaría." % tocados
		"prensa":
			if m.prensa != null:
				m.prensa.funa = maxi(0, m.prensa.funa - 2)
			return "Te sugiere cómo plantear la rueda. El ruido de la semana baja un poco."
		"hincha":
			return "Te habla de un partido de hace treinta años como si fuera ayer. Sales con ganas de ganar el domingo."
		"ojeador":
			return "Te da un nombre apuntado en una libreta que ya no usa nadie. Dice que lo mires."
		"utilero":
			for j3 in c.plantilla:
				j3.moral = clampi(j3.moral + 1, 10, 99)
			return "Se le nota que quiere al plantel. Algo de eso se contagia al vestuario."
		"secretaria":
			return "Te pone al día de los papeles que nadie mira hasta que estallan."
		"conserje":
			return "Te cuenta, sin darle importancia, tres cosas que pasaron esta semana y que nadie te contó."
		"chofer":
			return "Escucha más de lo que habla. Hoy te ha hablado, y eso ya dice algo."
	return "Una charla tranquila, de las que no se notan hasta que faltan."

## El pulso semanal: se reinicia el cupo de charlas y la confianza se enfría un
## poco si no apareces. La gente no se ofende, pero se acostumbra a tu ausencia.
func semana() -> void:
	charlas_esta_semana = 0
	var m := _mundo()
	if m == null:
		return
	for k: String in fichas:
		var f: Dictionary = fichas[k]
		if m.semana - int(f.get("ultima_semana", 0)) > 8:
			f["confianza"] = maxi(20, int(f["confianza"]) - 1)

func a_dic() -> Dictionary:
	return {"fichas": fichas.duplicate(true), "charlas": charlas_esta_semana}

func desde_dic(d: Dictionary) -> void:
	fichas = (d.get("fichas", {}) as Dictionary).duplicate(true)
	charlas_esta_semana = int(d.get("charlas", 0))

## Un nombre de persona corriente. Mismo criterio que la cantera: nombre de pila
## de la tabla NOMBRES y apellido de APELLIDOS, que son las que exportó el HTML.
func _nombre_al_azar() -> String:
	var n: Variant = Datos.tabla("NOMBRES")
	var a: Variant = Datos.tabla("APELLIDOS")
	var pila := "Juan"
	if n is Array and not (n as Array).is_empty():
		pila = String(Azar.uno(n))
	if a is Array and not (a as Array).is_empty():
		return Nombres.limpiar("%s %s" % [pila, String(Azar.uno(a))])
	return Nombres.limpiar(pila)
