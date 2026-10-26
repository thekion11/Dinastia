class_name Citas
extends RefCounted
## CITAS EN PERSONA (fase 4 del plan del lunes, bloque 1, 26-10-2026). Plan §2.2d:
## *«una cita = {quién, dónde, día y hora, asunto, tipo}; nacen de lo que ya pasa cada
## semana (junta, oferta de zona, agente, votación); llegan por Mensajes del móvil y
## salen en la Agenda; máximo 3 por semana y 1 por persona; si no vas, caduca el
## domingo sin castigo»*.
##
## Solo datos y reglas: ningún nodo. No inventa simulación nueva: resolver una cita
## llama a lo de siempre (`Junta.resolver`, `Comercial.firmar_zona`…) con el pequeño
## bono de hacerlo en persona. No consume `Azar`: todo sale de hashes y del estado.

signal noticia(titulo: String, cuerpo: String)

const MAX_SEMANA := 3
## Horas que la persona espera en el sitio desde la hora de la cita.
const DURACION := 2
## Bonos de hacerlo en persona (§2.2d, bloques 3 y 5).
const BONO_PATROCINIO := 0.05     ## +5 % de renta la zona firmada en persona
const BONO_JUNTA := 1             ## +1 de confianza por dar la cara en el despacho
const DIAS := ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
## tipo → dónde y cuándo. `donde` "estadio" = zona del edificio del club (con planta);
## "ciudad" = punto de `CityBuilder.puntos_clic` (clave `ciudad_<uso>`).
const TIPOS := {
	"junta": {"icono": "🏛️", "dia": 1, "hora": 11, "donde": "estadio", "lugar": "Despacho del presidente", "planta": 1, "nombre_lugar": "el despacho del presidente"},
	"patrocinio": {"icono": "🤝", "dia": 2, "hora": 16, "donde": "ciudad", "lugar": "ciudad_centro_comercial", "planta": 0, "nombre_lugar": "el centro comercial"},
	"agente": {"icono": "🕴️", "dia": 3, "hora": 19, "donde": "ciudad", "lugar": "ciudad_plaza_mayor", "planta": 0, "nombre_lugar": "la terraza de la Plaza Mayor"},
	"politica": {"icono": "🏢", "dia": 4, "hora": 12, "donde": "ciudad", "lugar": "ciudad_ayuntamiento", "planta": 0, "nombre_lugar": "el ayuntamiento"},
}
const _NOMBRES := ["Valeria", "Ignacio", "Camila", "Rodrigo", "Antonia", "Matías", "Josefa", "Sebastián", "Constanza", "Nicolás"]
const _APELLIDOS := ["Soto", "Reyes", "Vargas", "Fuentes", "Araya", "Espinoza", "Tapia", "Carrasco", "Sepúlveda", "Figueroa"]

## {id, tipo, quien, cargo, dia, hora, asunto, clave, estado (pendiente/hecha/caducada), anio, semana}
var lista: Array[Dictionary] = []
## La cita marcada con «Ir» en la Agenda (id) o "".
var objetivo := ""
## La semana (abs) en que el agente te dejó algo a deber (bloque 3: −5 % en su próxima mesa).
var favor_agente := -1
var _n := 0

static func _h(t: String) -> int:
	return absi(t.hash())

static func nombre_ficticio(semilla: String) -> String:
	var h := _h(semilla)
	return "%s %s" % [_NOMBRES[h % _NOMBRES.size()], _APELLIDOS[(h / 7) % _APELLIDOS.size()]]

# ========================================================================== SEMANA

## Una vez por semana (desde `Mundo._semana_modulos_del_club`, antes de `semana += 1`):
## caducan las citas viejas y nacen las de la semana que empieza (`prox`).
func semana(m: Mundo, prox: int = -1) -> void:
	var c := m.mi_club()
	if c == null:
		return
	if prox < 0:
		prox = m.semana + 1
	for ct: Dictionary in lista:
		if String(ct["estado"]) == "pendiente" and (int(ct["anio"]) != m.anio or int(ct["semana"]) != prox):
			ct["estado"] = "caducada"
	while lista.size() > 12:
		lista.pop_front()
	if objetivo != "" and por_id(objetivo).get("estado", "") != "pendiente":
		objetivo = ""
	var nuevas := 0
	## La junta: el accionista que pidió la palabra, en el despacho del presidente.
	if m.junta != null and not m.junta.pendiente.is_empty() and not _hay("junta", prox):
		var pres := String(m.junta.presidente.get("nombre", "Presidente"))
		_nueva(m, prox, "junta", pres, Idiomas.t("Presidente de %s") % c.nombre,
			"%s %s" % [String(m.junta.pendiente.get("quien", "")), String(m.junta.pendiente.get("tema", ""))], "")
		nuevas += 1
	## Una zona de patrocinio con ofertas: la marca que más paga quiere cerrar en persona.
	if nuevas < MAX_SEMANA and m.comercial != null and not m.comercial.ofertas_zona.is_empty() and not _hay("patrocinio", prox):
		var claves: Array = m.comercial.ofertas_zona.keys()
		claves.sort()
		var zona := String(claves[0])
		var ofertas: Array = m.comercial.ofertas_zona[zona]
		var mejor := 0
		for i in ofertas.size():
			if int((ofertas[i] as Dictionary)["monto"]) > int((ofertas[mejor] as Dictionary)["monto"]):
				mejor = i
		var o: Dictionary = ofertas[mejor]
		var marca := String(o["marca"])
		_nueva(m, prox, "patrocinio", nombre_ficticio("pat|" + marca), Idiomas.t("Directora de marketing de %s") % marca,
			Idiomas.t("quiere cerrar %s por %s al año") % [Comercial._nombre_zona(zona), Eco.dinero(int(o["monto"]))],
			"%s|%d" % [zona, mejor])
		nuevas += 1
	## El superagente, cuando aparece, te cita en una terraza.
	if nuevas < MAX_SEMANA and m.mercado_av != null and m.mercado_av.superagente != "" and not _hay("agente", prox):
		_nueva(m, prox, "agente", m.mercado_av.superagente, Idiomas.t("Agente de jugadores"),
			Idiomas.t("quiere hablar de sus representados (%d en tu plantilla)") % m.mercado_av.clientes.size(), "")
		nuevas += 1
	## La semana antes de la votación, el gabinete del alcalde pide apoyo.
	if nuevas < MAX_SEMANA and m.politica != null and prox == Politica.semana_votacion(c.pais) - 1 and not _hay("politica", prox):
		_nueva(m, prox, "politica", Politica.nombre_ficticio(c.pais, "gabinete%d" % m.anio), Idiomas.t("Jefe de gabinete del alcalde"),
			Idiomas.t("pide el apoyo público del club antes de la votación"), c.pais)
		nuevas += 1

func _hay(tipo: String, sem: int) -> bool:
	for ct: Dictionary in lista:
		if String(ct["tipo"]) == tipo and int(ct["semana"]) == sem and String(ct["estado"]) == "pendiente":
			return true
	return false

func _nueva(m: Mundo, sem: int, tipo: String, quien: String, cargo: String, asunto: String, clave: String) -> void:
	var t: Dictionary = TIPOS[tipo]
	_n += 1
	var ct := {"id": "c%d_%d_%d" % [m.anio, sem, _n], "tipo": tipo, "quien": quien, "cargo": cargo, "dia": int(t["dia"]),
		"hora": int(t["hora"]), "asunto": asunto, "clave": clave, "estado": "pendiente", "anio": m.anio, "semana": sem}
	lista.append(ct)
	if m.movil != null:
		## Plantilla + argumentos: el móvil la traduce al idioma de cada momento.
		m.movil.recibir(quien, String(t["icono"]), "%s. %s a las %s en %s. Te espero. (Agenda del móvil → Ir)", m.anio, sem,
			[asunto, DIAS[int(t["dia"])], "%02d:00" % int(t["hora"]), String(t["nombre_lugar"])], true)
	noticia.emit("%s %s" % [String(t["icono"]), Idiomas.t("Cita nueva")], "%s (%s): %s" % [quien, cargo, asunto])

# ======================================================================== LECTURAS

func pendientes() -> Array[Dictionary]:
	var sal: Array[Dictionary] = []
	for ct: Dictionary in lista:
		if String(ct["estado"]) == "pendiente":
			sal.append(ct)
	return sal

func por_id(id: String) -> Dictionary:
	for ct: Dictionary in lista:
		if String(ct["id"]) == id:
			return ct
	return {}

## ¿La persona está ahora mismo en su sitio? (su día, de la hora de la cita a +2 h).
func en_hora(ct: Dictionary, reloj: Reloj) -> bool:
	if ct.is_empty() or String(ct["estado"]) != "pendiente" or reloj == null:
		return false
	if reloj.anio != int(ct["anio"]) or reloj.semana != int(ct["semana"]) or reloj.dia != int(ct["dia"]):
		return false
	return reloj.hora() >= int(ct["hora"]) and reloj.hora() < int(ct["hora"]) + DURACION

## «Martes 16:00 · el centro comercial», para la Agenda y el HUD.
func cuando(ct: Dictionary) -> String:
	var t: Dictionary = TIPOS[String(ct["tipo"])]
	return "%s %02d:00 · %s" % [Idiomas.t(DIAS[int(ct["dia"])]), int(ct["hora"]), Idiomas.t(String(t["nombre_lugar"]))]

func lugar(ct: Dictionary) -> Dictionary:
	return TIPOS[String(ct["tipo"])]

## Las dos respuestas posibles en la cita.
func opciones(m: Mundo, ct: Dictionary) -> Array[String]:
	match String(ct["tipo"]):
		"junta":
			if m.junta != null and not m.junta.pendiente.is_empty():
				return [String(m.junta.pendiente["a"]), String(m.junta.pendiente["b"])]
			return [Idiomas.t("Ya está resuelto; gracias por recibirme"), Idiomas.t("Me voy")]
		"patrocinio":
			return [Idiomas.t("Firmar aquí mismo (+5 % de renta)"), Idiomas.t("Lo pienso; sigue en el PC")]
		"agente":
			return [Idiomas.t("Escuchar lo que ofrece"), Idiomas.t("No hago tratos en la calle")]
	return [Idiomas.t("Apoyar al gobierno en la rueda de prensa"), Idiomas.t("El club no se mete en política")]

# ======================================================================== RESOLVER

## Cumple la cita con la opción elegida (0 o 1). Devuelve {titulo, texto} ya traducido.
## Lo que pasa es lo de siempre (PC) más el bono de estar en persona.
func resolver(m: Mundo, id: String, opcion: int) -> Dictionary:
	var ct := por_id(id)
	if ct.is_empty() or String(ct["estado"]) != "pendiente":
		return {}
	ct["estado"] = "hecha"
	if objetivo == id:
		objetivo = ""
	var c := m.mi_club()
	match String(ct["tipo"]):
		"junta":
			if m.junta == null or m.junta.pendiente.is_empty():
				return {"titulo": String(ct["quien"]), "texto": Idiomas.t("«Ya lo hablamos por escrito. Gracias por venir igual.»")}
			var r := m.junta.resolver("a" if opcion == 0 else "b", c, m.directiva, m.prensa)
			if m.directiva != null:
				m.directiva.confianza = clampi(m.directiva.confianza + BONO_JUNTA, 0, 100)
			return {"titulo": String(r.get("titulo", ct["quien"])), "texto": "%s %s" % [String(r.get("cuerpo", "")), Idiomas.t("(Dar la cara en el despacho: +1 de confianza.)")]}
		"patrocinio":
			var partes := String(ct["clave"]).split("|")
			if opcion != 0 or partes.size() < 2 or m.comercial == null:
				return {"titulo": String(ct["quien"]), "texto": Idiomas.t("«Piénsalo; la oferta sigue en pie unos días.»")}
			var error := m.comercial.firmar_zona(partes[0], int(partes[1]))
			if error != "":
				return {"titulo": String(ct["quien"]), "texto": Idiomas.t("No se pudo firmar: %s.") % Idiomas.t(error)}
			var z: Dictionary = m.comercial.zonas_firmadas[partes[0]]
			z["monto"] = int(round(float(z["monto"]) * (1.0 + BONO_PATROCINIO) / 10000.0)) * 10000
			return {"titulo": Idiomas.t("Firmado en persona"), "texto": Idiomas.t("%s cierra %s por %s al año (+5 % por cerrarlo en persona).") % [
				String(z["marca"]), Comercial._nombre_zona(partes[0]), Eco.dinero(int(z["monto"]))]}
		"agente":
			if opcion != 0:
				return {"titulo": String(ct["quien"]), "texto": Idiomas.t("«Como quieras. Ya sabes dónde encontrarme.»")}
			favor_agente = m.anio * 60 + m.semana
			return {"titulo": String(ct["quien"]), "texto": Idiomas.t("«Represento a %d de los tuyos. Tratemos bien a mi gente y la próxima mesa será más barata.» (−5 % en su próxima negociación.)") % m.mercado_av.clientes.size()}
	## política
	if opcion != 0 or m.politica == null:
		return {"titulo": String(ct["quien"]), "texto": Idiomas.t("«Lo entiendo. El fútbol es de todos.»")}
	var gob := m.politica.gobierno(c.pais, m.anio)
	gob["apoyo_club"] = m.anio
	if m.prensa != null:
		for f: Array in Prensa.PERIODISTAS:
			if String(f[3]) == "crítico":
				m.prensa._mover_relacion(String(f[0]), -2)
	return {"titulo": String(ct["quien"]), "texto": Idiomas.t("«El alcalde lo recordará.» El club apoya al gobierno en la próxima rueda; la prensa crítica toma nota (−2 de relación).")}

# ======================================================================== GUARDADO

func a_dic() -> Dictionary:
	return {"lista": lista.duplicate(true), "objetivo": objetivo, "favor_agente": favor_agente, "n": _n}

func desde_dic(d: Dictionary) -> void:
	lista.clear()
	for ct: Variant in d.get("lista", []):
		if ct is Dictionary:
			lista.append(ct as Dictionary)
	objetivo = String(d.get("objetivo", ""))
	favor_agente = int(d.get("favor_agente", -1))
	_n = int(d.get("n", 0))
