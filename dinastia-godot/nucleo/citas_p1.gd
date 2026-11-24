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
## "ciudad" = punto de `CargaCiudad.de("CityBuilder").puntos_clic` (clave `ciudad_<uso>`).
const TIPOS := {
	"junta": {"icono": "🏛️", "dia": 1, "hora": 11, "donde": "estadio", "lugar": "Despacho del presidente", "planta": 1, "nombre_lugar": "el despacho del presidente"},
	"patrocinio": {"icono": "🤝", "dia": 2, "hora": 16, "donde": "ciudad", "lugar": "ciudad_centro_comercial", "planta": 0, "nombre_lugar": "el centro comercial"},
	"agente": {"icono": "🕴️", "dia": 3, "hora": 19, "donde": "ciudad", "lugar": "ciudad_plaza_mayor", "planta": 0, "nombre_lugar": "la terraza de la Plaza Mayor"},
	"politica": {"icono": "🏢", "dia": 4, "hora": 12, "donde": "ciudad", "lugar": "ciudad_ayuntamiento", "planta": 0, "nombre_lugar": "el ayuntamiento"},
	## Bloque 4: la entrevista de contratación, al día siguiente del fichaje, en tu oficina.
	"entrevista": {"icono": "🤝", "dia": -1, "hora": 10, "donde": "estadio", "lugar": "Oficina del DT", "planta": 1, "nombre_lugar": "tu oficina"},
	## Bloque 6: la asamblea de socios (cada 4 temporadas, o con la confianza por los suelos), el sábado en el salón de actos.
	"asamblea": {"icono": "🗳️", "dia": 5, "hora": 11, "donde": "estadio", "lugar": "Sala de prensa", "planta": 2, "nombre_lugar": "el salón de actos"},
	## Fase 5: las ramas de otros deportes piden presupuesto (semana 5) y el presidente presenta cada trofeo nuevo en el museo.
	"rama": {"icono": "🏅", "dia": 2, "hora": 17, "donde": "estadio", "lugar": "Museo del club", "planta": 2, "nombre_lugar": "el museo del club"},
	"celebracion": {"icono": "🏆", "dia": 0, "hora": 10, "donde": "estadio", "lugar": "Museo del club", "planta": 2, "nombre_lugar": "el museo del club"},
}
const RAMA_SEMANA := 5
const RAMA_EXTRA := 0.10   ## del coste anual de la rama
const ASAMBLEA_SEMANA := 3
const CONFIANZA_ASAMBLEA := 25
## Lo que mueve la moral del recién llegado cada tono de la entrevista (seguro, evasivo, humilde).
const MORAL_ENTREVISTA := [2, -1, 1]
## (§2.5, 30-10) La entrevista son TRES preguntas: el tono (arriba), con qué grupo del vestuario se
## cambia y con quién del cuerpo técnico trabaja su primera semana. Staff: [forma, adaptación, moral].
const ENTREVISTA_PREGUNTAS := ["%s quiere conocer a su nuevo entrenador.", "¿Con quién se cambia %s en el vestuario?",
	"¿Con quién del cuerpo técnico trabaja %s esta semana?"]
const STAFF_ENTREVISTA := [[3, 0, 0], [0, 15, 0], [0, 0, 1]]
const _NOMBRES := ["Valeria", "Ignacio", "Camila", "Rodrigo", "Antonia", "Matías", "Josefa", "Sebastián", "Constanza", "Nicolás"]
const _APELLIDOS := ["Soto", "Reyes", "Vargas", "Fuentes", "Araya", "Espinoza", "Tapia", "Carrasco", "Sepúlveda", "Figueroa"]

## {id, tipo, quien, cargo, dia, hora, asunto, clave, estado (pendiente/hecha/caducada), anio, semana}
var lista: Array[Dictionary] = []
## La cita marcada con «Ir» en la Agenda (id) o "".
var objetivo := ""
## La semana (abs) en que el agente te dejó algo a deber (bloque 3: −5 % en su próxima mesa).
var favor_agente := -1
## La semana (abs) en que convocaste una rueda de prensa extra desde el móvil (máximo una).
var rueda_semana := -1
## El año en que ya hubo asamblea (una por temporada como mucho).
var asamblea_anio := -1
## Cuántos trofeos del DT se habían celebrado ya (−1 = aún sin mirar).
var _trofeos_vistos := -1
var _ramas_vistas := -1   ## títulos de las ramas ya celebrados (`CitasRamas`)
var _n := 0

static func _h(t: String) -> int:
	var nat := Nativo.de("nuc_hash_abs")
	if nat != null:
		return nat.nuc_hash_abs(t)
	return _h_gd(t)

## Gemela GDScript de `nuc_hash_abs` (extensión C++, orden 63): respaldo sin binario y comparación en `pruebas/probar_nativo_puras.gd`.
static func _h_gd(t: String) -> int:
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
	nuevas = _semana_junta(m, c, prox, nuevas)
	nuevas = _semana_patrocinio(m, prox, nuevas)
	nuevas = _semana_agente(m, prox, nuevas)
	nuevas = _semana_asamblea(m, c, prox, nuevas)
	nuevas = _semana_ramas(m, c, prox, nuevas)
	nuevas = _semana_trofeo(m, c, prox, nuevas)
	nuevas = CitasRamas.celebraciones(self, m, c, prox, nuevas)
	_semana_politica(m, c, prox, nuevas)

## La junta: el accionista que pidió la palabra.
func _semana_junta(m: Mundo, c: Club, prox: int, nuevas: int) -> int:
	## La junta: el accionista que pidió la palabra, en el despacho del presidente.
	if m.junta != null and not m.junta.pendiente.is_empty() and not _hay("junta", prox):
		var pres := String(m.junta.presidente.get("nombre", "Presidente"))
		_nueva(m, prox, "junta", pres, Idiomas.t("Presidente de %s") % c.nombre,
			"%s %s" % [String(m.junta.pendiente.get("quien", "")), String(m.junta.pendiente.get("tema", ""))], "")
		nuevas += 1
	return nuevas

## Una zona de patrocinio con ofertas: la marca que más paga quiere cerrar en persona.
func _semana_patrocinio(m: Mundo, prox: int, nuevas: int) -> int:
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
	return nuevas

## El superagente te cita en una terraza.
func _semana_agente(m: Mundo, prox: int, nuevas: int) -> int:
	## El superagente, cuando aparece, te cita en una terraza.
	if nuevas < MAX_SEMANA and m.mercado_av != null and m.mercado_av.superagente != "" and not _hay("agente", prox):
		_nueva(m, prox, "agente", m.mercado_av.superagente, Idiomas.t("Agente de jugadores"),
			Idiomas.t("quiere hablar de sus representados (%d en tu plantilla)") % m.mercado_av.clientes.size(), "")
		nuevas += 1
	return nuevas

## La asamblea de socios: cada 4 temporadas, o con la confianza por los suelos.
func _semana_asamblea(m: Mundo, c: Club, prox: int, nuevas: int) -> int:
	## La asamblea de socios: cada 4 temporadas, o cualquier temporada con la confianza por los suelos.
	if nuevas < MAX_SEMANA and asamblea_anio != m.anio and prox == ASAMBLEA_SEMANA and not _hay("asamblea", prox) \
			and (m.anio % 4 == 0 or (m.directiva != null and m.directiva.confianza < CONFIANZA_ASAMBLEA)):
		if m.junta != null:
			m.junta.formar(c)
		var pres := String(m.junta.presidente.get("nombre", "Presidente")) if m.junta != null else "Presidente"
		_nueva(m, prox, "asamblea", pres, Idiomas.t("Asamblea de socios"), Idiomas.t("convoca la asamblea: los socios votan la presidencia y tú hablas"), "")
		nuevas += 1
	return nuevas

## Las ramas de otros deportes piden presupuesto extra en la semana 5.
func _semana_ramas(m: Mundo, c: Club, prox: int, nuevas: int) -> int:
	## Las ramas de otros deportes (fase 5): su coordinadora pide presupuesto extra en la semana 5.
	if m.hinchada != null and prox == RAMA_SEMANA:
		for f: Array in Hinchada.RAMAS:
			var clave := String(f[0])
			if nuevas >= MAX_SEMANA or not m.hinchada.tiene_rama(clave) or _hay_clave("rama", prox, clave):
				continue
			_nueva(m, prox, "rama", nombre_ficticio("rama|" + clave + c.id), Idiomas.t("Coordinadora de %s") % Idiomas.t(String(f[2])),
				Idiomas.t("pide un presupuesto extra para la rama (%s)") % Eco.dinero(int(float(f[3]) * RAMA_EXTRA)), clave)
			nuevas += 1
	return nuevas

## Un trofeo nuevo del primer equipo: el presidente lo presenta en el museo.
func _semana_trofeo(m: Mundo, c: Club, prox: int, nuevas: int) -> int:
	## Un trofeo nuevo del primer equipo: el presidente lo presenta en el museo el lunes.
	if m.roles != null:
		var tro := m.roles.trofeos.size()
		if _trofeos_vistos >= 0 and tro > _trofeos_vistos and nuevas < MAX_SEMANA and not _hay("celebracion", prox):
			var pres := String(m.junta.presidente.get("nombre", "Presidente")) if m.junta != null else "Presidente"
			_nueva(m, prox, "celebracion", pres, Idiomas.t("Presidente de %s") % c.nombre, Idiomas.t("te espera para presentar el trofeo nuevo en el museo"), "")
			nuevas += 1
		_trofeos_vistos = tro
	return nuevas

## La semana antes de la votación, el gabinete del alcalde pide apoyo.
func _semana_politica(m: Mundo, c: Club, prox: int, nuevas: int) -> int:
	## La semana antes de la votación, el gabinete del alcalde pide apoyo.
	if nuevas < MAX_SEMANA and m.politica != null and prox == Politica.semana_votacion(c.pais) - 1 and not _hay("politica", prox):
		_nueva(m, prox, "politica", Politica.nombre_ficticio(c.pais, "gabinete%d" % m.anio), Idiomas.t("Jefe de gabinete del alcalde"),
			Idiomas.t("pide el apoyo público del club antes de la votación"), c.pais)
		nuevas += 1
	return nuevas

func _hay_clave(tipo: String, sem: int, clave: String) -> bool:
	for ct: Dictionary in lista:
		if String(ct["tipo"]) == tipo and int(ct["semana"]) == sem and String(ct["clave"]) == clave and String(ct["estado"]) == "pendiente":
			return true
	return false

func _hay(tipo: String, sem: int) -> bool:
	for ct: Dictionary in lista:
		if String(ct["tipo"]) == tipo and int(ct["semana"]) == sem and String(ct["estado"]) == "pendiente":
			return true
	return false

## Al cerrar un fichaje (`Negociacion._cerrar_fichaje`): el nuevo te espera mañana a las
## 10:00 en tu oficina. Si no vas, caduca y el fichaje queda como siempre (sin bono ni castigo).
func entrevista(m: Mundo, j: Jugador) -> void:
	if j == null or m.reloj == null:
		return
	m.reloj._al_dia()
	var dia := mini(m.reloj.dia + 1, 5)
	_nueva(m, m.reloj.semana if m.reloj.semana >= 0 else m.semana, "entrevista", j.nombre, Idiomas.t("Fichaje nuevo"),
		Idiomas.t("quiere conocer a su nuevo entrenador"), j.id, dia)

func _nueva(m: Mundo, sem: int, tipo: String, quien: String, cargo: String, asunto: String, clave: String, dia := -1) -> void:
	var t: Dictionary = TIPOS[tipo]
	if dia < 0:
		dia = int(t["dia"])
	_n += 1
	var ct := {"id": "c%d_%d_%d" % [m.anio, sem, _n], "tipo": tipo, "quien": quien, "cargo": cargo, "dia": dia,
		"hora": int(t["hora"]), "asunto": asunto, "clave": clave, "estado": "pendiente", "anio": m.anio, "semana": sem}
	lista.append(ct)
	if m.movil != null:
		## Plantilla + argumentos: el móvil la traduce al idioma de cada momento.
		m.movil.recibir(quien, String(t["icono"]), "%s. %s a las %s en %s. Te espero. (Agenda del móvil → Ir)", m.anio, sem,
			[asunto, DIAS[dia], "%02d:00" % int(t["hora"]), String(t["nombre_lugar"])], true)
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
		"rama":
			return [Idiomas.t("Aprobar el presupuesto extra"), Idiomas.t("Este año no"), Idiomas.t("Darles visibilidad: un partido en el estadio")]
		"celebracion":
			return [Idiomas.t("Levantar la copa y foto para Tribuna"), Idiomas.t("Celebrarlo en privado")]
		"asamblea":
			return [Idiomas.t("Seguro · Este proyecto va a ganar: pido vuestro voto para seguir igual."),
				Idiomas.t("Evasivo · No es momento de cambios; ya veremos cómo acaba la temporada."),
				Idiomas.t("Humilde · Los socios mandan; yo seguiré trabajando con quien elijan.")]
		"entrevista":
			return [Idiomas.t("Seguro · Vienes a ser importante: demuéstralo desde mañana."),
				Idiomas.t("Evasivo · Ya veremos dónde encajas; el tiempo dirá."),
				Idiomas.t("Humilde · Bienvenido: aprende del grupo y el grupo de ti.")]
	return [Idiomas.t("Apoyar al gobierno en la rueda de prensa"), Idiomas.t("El club no se mete en política")]

# ======================================================================== RESOLVER

## Cumple la cita con la opción elegida (0 o 1). Devuelve {titulo, texto} ya traducido.
## Lo que pasa es lo de siempre (PC) más el bono de estar en persona.
## Las opciones de la pregunta `paso` (0-2) de la entrevista; la 0 son los tonos de `opciones()`.
func opciones_entrevista(m: Mundo, ct: Dictionary, paso: int) -> Array[String]:
	match paso:
		1:
			var o: Array[String] = []
			for cl: Dictionary in grupos_entrevista(m):
				o.append(Idiomas.t("Con «%s»") % Idiomas.t(String(cl["nombre"])))
			o.append(Idiomas.t("Con todos, sin bandos"))
			return o
		2:
			return [Idiomas.t("El preparador físico: un plan a su medida (+3 de forma)"),
				Idiomas.t("El analista: vídeos de tu sistema (+15 de adaptación)"),
				Idiomas.t("Nadie en especial: que se integre a su ritmo (+1 de moral)")]
	return opciones(m, ct)

## Hasta dos grupos del vestuario a los que presentarlo (los de más miembros).
func grupos_entrevista(m: Mundo) -> Array:
	if m.vestuario == null:
		return []
	var g := m.vestuario.camarillas.duplicate()
	g.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a["miembros"] as Array).size() > (b["miembros"] as Array).size())
	return g.slice(0, 2)
