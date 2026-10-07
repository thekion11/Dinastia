class_name Junta
extends RefCounted
## EL PRESIDENTE DEL CLUB, LOS ACCIONISTAS Y LA JUNTA (26-9-2026, plan maestro C5).
## Pedido: *"presidentes del club, accionistas del club, reuniones con altas
## autoridades del club"*. La directiva ya medía una "confianza"; aquí hay
## PERSONAS detrás: un presidente con su estilo y tres accionistas, cada uno con
## su porcentaje y lo que exige. Cada trece semanas (una vez por trimestre) hay
## junta: uno de ellos pone un tema sobre la mesa y tú decides. Lo que decides
## sube o baja su humor, y si alguno se harta del todo, pide tu cabeza (moción de
## censura: la confianza de la directiva cae de golpe).
##
## Nombres y exigencias salen de un hash del club: el mismo club, la misma
## junta. Las decisiones no tiran `Azar`.

signal noticia(titulo: String, cuerpo: String)
signal movimiento(concepto: String, monto: int)

const CADA := 13
const HUMOR_CENSURA := 18

const ESTILOS := {
	"ambicioso": "Quiere títulos ya y no mira el gasto.",
	"prudente": "Cuida la caja por encima de todo.",
	"populista": "Gobierna para la grada y las encuestas.",
}
const EXIGENCIAS := {
	"dividendos": "cobrar dividendos",
	"titulos": "ganar títulos",
	"cantera": "que jueguen los de casa",
	"estadio": "agrandar el estadio",
}
const _NOMBRES := ["Aurelio", "Benjamín", "Cristina", "Domingo", "Eugenia", "Fabián", "Gloria",
	"Hernán", "Inés", "Julián", "Leonor", "Maximiliano", "Nora", "Orlando", "Pilar", "Ricardo"]
const _APELLIDOS := ["Altamirano", "Bascuñán", "Cruchaga", "Del Solar", "Errázuriz", "Fontaine",
	"Grove", "Huidobro", "Izquierdo", "Larraín", "Matte", "Noguera", "Ovalle", "Prieto"]

var presidente: Dictionary = {}     ## {nombre, estilo}
var accionistas: Array = []         ## [{nombre, pct, exige, humor}]
var pendiente: Dictionary = {}      ## la junta abierta: {quien, exige, tema, a, b}
var historial: Array = []           ## [{semana, anio, tema, eleccion}]

func formar(c: Club) -> void:
	if c == null or not presidente.is_empty():
		return
	var h := absi(("junta|" + c.id).hash())
	var estilos := ESTILOS.keys()
	presidente = {"nombre": _nombre(h), "estilo": String(estilos[h % estilos.size()])}
	var exig := EXIGENCIAS.keys()
	var pcts := [34, 21, 12]
	accionistas = []
	for i in 3:
		var hi := absi(("acc|%s|%d" % [c.id, i]).hash())
		accionistas.append({"nombre": _nombre(hi), "pct": pcts[i] + hi % 6,
			"exige": String(exig[(h / (i + 3) + i) % exig.size()]), "humor": 60})

func _nombre(h: int) -> String:
	## El apellido con su propio hash: con `h / 17` los tres accionistas salían
	## con el mismo apellido.
	return "%s %s" % [_NOMBRES[h % _NOMBRES.size()], _APELLIDOS[absi(("ap%d" % h).hash()) % _APELLIDOS.size()]]

## Una vez por semana. Convoca la junta del trimestre.
func semana(c: Club, anio: int, sem: int) -> void:
	formar(c)
	if not pendiente.is_empty() or sem % CADA != 0 or accionistas.is_empty():
		return
	## Habla el más molesto (o el de más peso si todos están contentos).
	var quien: Dictionary = accionistas[0]
	for a: Dictionary in accionistas:
		if int(a["humor"]) < int(quien["humor"]):
			quien = a
	pendiente = _tema(c, quien)
	noticia.emit("🏛️ Junta de accionistas",
		"%s (%d %% del club) pide la palabra: %s" % [String(quien["nombre"]), int(quien["pct"]), String(pendiente["tema"])])

func _tema(c: Club, a: Dictionary) -> Dictionary:
	var monto := Eco.escalar(400000.0, float(c.rep))
	match String(a["exige"]):
		"dividendos":
			return {"quien": a["nombre"], "exige": "dividendos", "monto": monto,
				"tema": "quiere repartir dividendos este trimestre (%s)." % Cesiones.dinero(monto),
				"a": "Repartir dividendos", "b": "Reinvertir todo en el club"}
		"titulos":
			return {"quien": a["nombre"], "exige": "titulos", "monto": 0,
				"tema": "exige que el club pelee el título: quiere oír un compromiso.",
				"a": "Prometer pelear el campeonato", "b": "Pedir paciencia: es un proyecto"}
		"cantera":
			return {"quien": a["nombre"], "exige": "cantera", "monto": 0,
				"tema": "quiere más minutos para los canteranos.",
				"a": "Comprometerse a dar minutos a la cantera", "b": "Juega el que está mejor"}
	return {"quien": a["nombre"], "exige": "estadio", "monto": 0,
		"tema": "propone agrandar el estadio aunque haya que endeudarse.",
		"a": "Aprobar la ampliación", "b": "No es el momento"}

## Resuelve la junta abierta. Devuelve {titulo, cuerpo, confianza, censura}.
func resolver(op: String, c: Club, directiva: Directiva, prensa: Prensa) -> Dictionary:
	if pendiente.is_empty():
		return {}
	var p := pendiente
	pendiente = {}
	var sube := op == "a"
	var d_humor := 18 if sube else -14
	var d_conf := 0
	var cuerpo := ""
	match String(p["exige"]):
		"dividendos":
			if sube:
				c.mover_saldo(-int(p["monto"]))
				movimiento.emit("Dividendos a los accionistas", -int(p["monto"]))
				d_conf = 2
				cuerpo = "Los accionistas cobran. La caja lo nota."
			else:
				cuerpo = "Todo se reinvierte. Algunos accionistas se van de la sala sin saludar."
		"titulos":
			if sube:
				d_conf = 3
				if prensa != null:
					prensa.presion_prometida = true
				cuerpo = "La frase sale de la sala y llega a la prensa: ahora hay que cumplirla."
			else:
				d_conf = -2
				cuerpo = "«Paciencia» no es una palabra que guste en una junta."
		"cantera":
			if sube:
				for j: Jugador in c.plantilla:
					if j.edad <= 21:
						j.moral = clampi(j.moral + 5, 10, 99)
				cuerpo = "Los chicos de casa se enteran y entrenan con otra cara."
			else:
				cuerpo = "Los de la academia leen la noticia y no les gusta."
		_:
			if sube:
				d_conf = 2
				cuerpo = "Aprobada la ampliación: se abre el proyecto de nuevas tribunas (Club → Obras)."
			else:
				cuerpo = "La ampliación queda en un cajón."
	for a: Dictionary in accionistas:
		if a["nombre"] == p["quien"]:
			a["humor"] = clampi(int(a["humor"]) + d_humor, 0, 100)
	if directiva != null and d_conf != 0:
		directiva.mover_confianza(d_conf, "junta de accionistas")
	historial.push_front({"tema": String(p["tema"]), "eleccion": String(p["a"] if sube else p["b"])})
	while historial.size() > 12:
		historial.pop_back()
	## LA MOCIÓN DE CENSURA: un accionista harto pide tu cabeza.
	var censura := false
	for a: Dictionary in accionistas:
		if int(a["humor"]) <= HUMOR_CENSURA:
			censura = true
			a["humor"] = 40
			if directiva != null:
				directiva.mover_confianza(-10, "moción de censura de %s" % String(a["nombre"]))
			noticia.emit("⚠️ Moción de censura", "%s (%d %% del club) pide tu destitución ante la junta. No prospera, pero la directiva toma nota." % [
				String(a["nombre"]), int(a["pct"])])
	var titulo := "Junta: %s" % String(p["a"] if sube else p["b"])
	noticia.emit("🏛️ " + titulo, cuerpo)
	return {"titulo": titulo, "cuerpo": cuerpo, "confianza": d_conf, "censura": censura}

func a_dic() -> Dictionary:
	return {"presidente": presidente, "accionistas": accionistas, "pendiente": pendiente, "historial": historial}

func desde_dic(d: Dictionary) -> void:
	presidente = (d.get("presidente", {}) as Dictionary).duplicate()
	accionistas = (d.get("accionistas", []) as Array).duplicate(true)
	pendiente = (d.get("pendiente", {}) as Dictionary).duplicate()
	historial = (d.get("historial", []) as Array).duplicate(true)
