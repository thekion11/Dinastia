class_name MercadoAvanzado
extends RefCounted
## EL MERCADO AVANZADO Y SUS ZONAS GRISES (28-9-2026, bloques 37-38 del plan
## maestro). Los derechos de formación ya existían (`Cesiones`); aquí va lo que
## faltaba:
##
##   GUERRA DE OFERTAS. Cuando llega una oferta por uno de tus buenos
##   jugadores, otros clubes pueden entrar a pujar: cada semana alguno mejora
##   la mejor oferta en la mesa (hasta tres pujas por jugador). Tú eliges cuál
##   aceptar en el mercado, como siempre.
##
##   Y cuatro asuntos de despacho, con dos salidas cada uno:
##   - EL SUPERAGENTE, que representa a varios de tus jugadores y pide
##     aumentos o comisiones con amenaza de llevárselos;
##   - EL FICHAJE IMPUESTO: la directiva (o el presidente) quiere un nombre, y
##     decirle que no cuesta confianza (si eres el dueño, no aplica);
##   - LAS APUESTAS: un jugador tuyo aparece apostando en partidos; tapar el
##     asunto o sancionarlo;
##   - LA TRANSPARENCIA: publicar las cuentas y las comisiones del club.
##
## Todos los nombres son inventados. Usa su propio generador de números, no
## `Azar`, para no mover ninguna otra tirada de la simulación.

signal noticia(titulo: String, cuerpo: String)
signal movimiento(concepto: String, monto: int)

const AGENTES := ["Rodrigo Benavente", "Iván Castellanos", "Mauro Lissandri", "Teo Varela"]
const MAX_PUJAS := 3

var pendiente: Dictionary = {}          ## el asunto a decidir: {id, texto, a, b, ...}
var superagente := ""                   ## el nombre del agente, cuando aparece
var clientes: Array[String] = []        ## ids de tus jugadores que representa
var pujas: Dictionary = {}              ## id de jugador -> pujas hechas
var ultima_semana_asunto := -99
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.seed = 3701

# --- la guerra de ofertas ------------------------------------------------------

## Una vez por semana: si hay ofertas por un jugador bueno, otro club puede
## mejorarlas. Devuelve cuántas pujas nuevas hubo.
func guerra_de_ofertas(m: Mundo) -> int:
	if m.mercado == null or m.mercado.ofertas_recibidas.is_empty():
		return 0
	var mejores := {}   ## jugador id -> la oferta más alta
	for o: Dictionary in m.mercado.ofertas_recibidas:
		var j: Jugador = o["jugador"]
		if bool(o.get("clausula", false)):
			continue
		if not mejores.has(j.id) or int(o["monto"]) > int(mejores[j.id]["monto"]):
			mejores[j.id] = o
	var nuevas := 0
	for jid: String in mejores:
		var o: Dictionary = mejores[jid]
		var j: Jugador = o["jugador"]
		if j.ovr < 70 or int(pujas.get(jid, 0)) >= MAX_PUJAS or _rng.randf() > 0.45:
			continue
		var ya := {}
		for o2: Dictionary in m.mercado.ofertas_recibidas:
			if (o2["jugador"] as Jugador) == j:
				ya[(o2["club"] as Club).id] = true
		var monto := int(round(float(o["monto"]) * _rng.randf_range(1.08, 1.2)))
		var candidatos: Array[Club] = []
		for c: Club in m.clubes.values():
			if c.id != m.mi_club_id and not ya.has(c.id) and c.rep >= j.ovr - 10 and c.saldo >= monto:
				candidatos.append(c)
		if candidatos.is_empty():
			continue
		var rival: Club = candidatos[_rng.randi() % candidatos.size()]
		m.mercado.ofertas_recibidas.append({"jugador": j, "club": rival, "monto": monto,
			"semana": m.semana, "clausula": false, "puja": true})
		pujas[jid] = int(pujas.get(jid, 0)) + 1
		nuevas += 1
		noticia.emit("🔥 Guerra por %s" % j.nombre, "%s entra en la pelea y ofrece %s, más que %s. La decisión es tuya en el mercado." % [
			rival.nombre, Cesiones.dinero(monto), (o["club"] as Club).nombre])
	return nuevas

# --- los asuntos de despacho ---------------------------------------------------

## Una vez por semana: a lo sumo un asunto nuevo cada cuatro semanas.
func semana(m: Mundo) -> void:
	guerra_de_ofertas(m)
	var c := m.mi_club()
	if c == null or not pendiente.is_empty():
		return
	var abs_sem := m.anio * 60 + m.semana
	if abs_sem - ultima_semana_asunto < 4 or _rng.randf() > 0.3:
		return
	var tipos: Array[String] = ["superagente", "apuestas", "transparencia", "corrupcion"]
	if m.roles == null or m.roles.rol != Roles.DUENO:
		tipos.append("impuesto")
	var tipo := tipos[_rng.randi() % tipos.size()]
	if _montar(m, tipo):
		ultima_semana_asunto = abs_sem

func _montar(m: Mundo, tipo: String) -> bool:
	var c := m.mi_club()
	match tipo:
		"superagente":
			if superagente == "":
				superagente = AGENTES[_rng.randi() % AGENTES.size()]
			clientes.clear()
			var buenos := c.plantilla.duplicate()
			buenos.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
			for j: Jugador in buenos.slice(0, 3):
				clientes.append(j.id)
			if clientes.is_empty():
				return false
			var j0 := m.jugador_por_id(clientes[0])
			pendiente = {"id": "superagente", "jugador": j0.id,
				"texto": "%s, el superagente que lleva a %s y a otros dos de tu plantel, exige un 15 %% más de sueldo para su cliente. «O se lo dan acá, o se lo dan en otro lado.»" % [superagente, j0.nombre],
				"a": "Pagar el aumento", "b": "Plantarse ante el agente"}
		"impuesto":
			var objetivo: Jugador = null
			for l: Jugador in m.libres:
				if l.edad >= 30 and (objetivo == null or l.ovr > objetivo.ovr):
					objetivo = l
			if objetivo == null:
				return false
			pendiente = {"id": "impuesto", "jugador": objetivo.id,
				"texto": "La directiva quiere fichar a %s (%d años, media %d): «vende camisetas y la gente lo pide». No lo pediste tú, pero el dinero sale del club." % [objetivo.nombre, objetivo.edad, objetivo.ovr],
				"a": "Aceptar el fichaje", "b": "Negarse: el plantel lo armo yo"}
		"apuestas":
			var j2: Jugador = c.plantilla[_rng.randi() % c.plantilla.size()]
			pendiente = {"id": "apuestas", "jugador": j2.id,
				"texto": "Un periodista tiene capturas de %s apostando en partidos de otra liga. No hay amaño, pero el reglamento lo prohíbe." % j2.nombre,
				"a": "Sancionarlo y comunicarlo", "b": "Taparlo dentro del club"}
		"corrupcion":
			var pres := String(m.federacion.presidente.get("nombre", "el presidente")) if m.federacion != null else "el presidente"
			pendiente = {"id": "corrupcion", "coste": int(round(Eco.ref_caja(float(c.rep)) * 0.04)),
				"texto": "Un intermediario que dice hablar por %s ofrece «arbitrajes amables» el resto de la temporada a cambio de %s en efectivo. Nadie firma nada." % [pres, Cesiones.dinero(int(round(Eco.ref_caja(float(c.rep)) * 0.04)))],
				"a": "Pagar", "b": "Denunciarlo a la justicia deportiva"}
		"transparencia":
			pendiente = {"id": "transparencia",
				"texto": "Un grupo de socios pide publicar las cuentas del club: sueldos, comisiones de agentes y deudas. La competencia vería tus números.",
				"a": "Publicar todo", "b": "No publicar"}
		_:
			return false
	return true

## La decisión. Devuelve {titulo, cuerpo}.
func resolver(m: Mundo, op: String) -> Dictionary:
	if pendiente.is_empty():
		return {}
	var p := pendiente
	pendiente = {}
	var c := m.mi_club()
	var r := m.roles
	var j := m.jugador_por_id(String(p.get("jugador", "")))
	match String(p["id"]):
		"superagente":
			if j == null:
				return {}
			if op == "a":
				j.sueldo = int(round(float(j.sueldo) * 1.15))
				j.moral = clampi(j.moral + 8, 0, 100)
				if r != null:
					r.anotar_reputacion("negociador", -2, "Cediste ante el superagente %s" % superagente)
				return {"titulo": "💰 Aumento para %s" % j.nombre, "cuerpo": "El agente se va contento. Los otros dos clientes ya saben que contigo funciona apretar."}
			j.moral = clampi(j.moral - 10, 0, 100)
			if _rng.randf() < 0.45:
				j.pide_salir = true
			if r != null:
				r.anotar_reputacion("negociador", 2, "Te plantaste ante el superagente %s" % superagente)
			return {"titulo": "🧱 Te plantas ante %s" % superagente, "cuerpo": "%s no está contento%s." % [j.nombre, " y ya pide salir" if j.pide_salir else ""]}
		"impuesto":
			var idx := m.libres.find(j) if j != null else -1
			if op == "a" and idx >= 0:
				var res := m.fichar_libre(idx, c)
				if res.has("ok"):
					if m.directiva != null:
						m.directiva.mover_confianza(4, "aceptaste el fichaje que pedía")
					return {"titulo": "✍️ Llega %s" % j.nombre, "cuerpo": "La directiva está feliz. Tú, con un veterano más en el plantel que no pediste."}
				return {"titulo": "El fichaje no se cerró", "cuerpo": "Al final no firmó: %s." % String(res.get("error", "rechazó la oferta"))}
			if m.directiva != null:
				m.directiva.mover_confianza(-6, "te negaste al fichaje que pedía")
			if r != null:
				r.anotar_reputacion("leal", -1, "Le dijiste que no a la directiva")
			return {"titulo": "🚫 No al fichaje", "cuerpo": "La directiva toma nota. El plantel lo armas tú, pero la paciencia de arriba baja."}
		"apuestas":
			if j == null:
				return {}
			if op == "a":
				j.suspension = maxi(j.suspension, 3)
				j.moral = clampi(j.moral - 12, 0, 100)
				if r != null:
					r.anotar_reputacion("honesto", 3, "Sancionaste a %s por apostar" % j.nombre)
				return {"titulo": "⚖️ %s, sancionado" % j.nombre, "cuerpo": "Tres partidos fuera. La prensa aplaude la decisión."}
			if _rng.randf() < 0.4:
				if r != null:
					r.anotar_reputacion("honesto", -5, "El club tapó las apuestas de %s" % j.nombre)
				if m.prensa != null:
					m.prensa.animo = clampi(m.prensa.animo - 6, 0, 100)
				j.suspension = maxi(j.suspension, 5)
				noticia.emit("📰 Salió a la luz", "Las apuestas de %s y que el club lo tapó. La federación lo suspende cinco partidos." % j.nombre)
				return {"titulo": "📰 Se supo todo", "cuerpo": "Lo taparon y salió igual: peor para todos."}
			return {"titulo": "🤫 Queda en casa", "cuerpo": "Por ahora nadie más lo sabe."}
		"corrupcion":
			var coste := int(p.get("coste", 0))
			if op == "a":
				c.mover_saldo(-coste)
				movimiento.emit("Pago en negro a un intermediario", -coste)
				if m.federacion != null:
					m.federacion.enojo_arbitral = 0
				if r != null:
					r.anotar_reputacion("honesto", -6, "Pagaste por arbitrajes amables")
				if _rng.randf() < 0.35:
					for l in m.ligas:
						if l.clubes.has(c) and l.tabla_puntos.has(c.id):
							l.tabla_puntos[c.id]["pts"] = int(l.tabla_puntos[c.id]["pts"]) - 9
					if m.prensa != null:
						m.prensa.animo = clampi(m.prensa.animo - 10, 0, 100)
					noticia.emit("💣 Escándalo de corrupción", "Se filtró el pago de %s a un intermediario de la federación: 9 puntos menos y la hinchada furiosa." % c.nombre)
					return {"titulo": "💣 Se destapó", "cuerpo": "Pagaste y salió a la luz: 9 puntos menos."}
				return {"titulo": "🤐 Pagado", "cuerpo": "Nadie habla. Los árbitros, de momento, te miran con otros ojos."}
			if r != null:
				r.anotar_reputacion("honesto", 4, "Denunciaste la corrupción federativa")
			if m.federacion != null:
				m.federacion.aliados = clampi(m.federacion.aliados - 3, -10, 10)
			noticia.emit("⚖️ Denuncia de corrupción", "%s denuncia a un intermediario de la federación. La prensa aplaude; en la asamblea te miran mal." % c.nombre)
			return {"titulo": "⚖️ Denunciado", "cuerpo": "Ganas en juego limpio y pierdes aliados en la asamblea."}
		"transparencia":
			if op == "a":
				if r != null:
					r.anotar_reputacion("honesto", 3, "Publicaste las cuentas del club")
					r.anotar_reputacion("social", 2, "Los socios valoran la transparencia")
				if m.prensa != null:
					m.prensa.animo = clampi(m.prensa.animo + 4, 0, 100)
				return {"titulo": "📊 Cuentas públicas", "cuerpo": "Los socios lo valoran. Los rivales ahora saben cuánto puedes gastar."}
			if r != null:
				r.anotar_reputacion("social", -1, "No publicaste las cuentas")
			return {"titulo": "🔒 Cuentas cerradas", "cuerpo": "Los socios que las pedían se quedan con la duda."}
	return {}

func a_dic() -> Dictionary:
	return {"pend": pendiente.duplicate(true), "agente": superagente, "clientes": clientes.duplicate(),
		"pujas": pujas.duplicate(), "ult": ultima_semana_asunto}

func desde_dic(d: Dictionary) -> void:
	if d.is_empty():
		return
	pendiente = (d.get("pend", {}) as Dictionary).duplicate(true)
	superagente = String(d.get("agente", ""))
	clientes.clear()
	for x: Variant in d.get("clientes", []):
		clientes.append(String(x))
	pujas = (d.get("pujas", {}) as Dictionary).duplicate()
	ultima_semana_asunto = int(d.get("ult", -99))
