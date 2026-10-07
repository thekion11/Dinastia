class_name Charlas
extends RefCounted
## HABLAR CON UN JUGADOR, UNO A UNO (26-9-2026, plan maestro C7). Pedido: *"poder
## hablar con los jugadores"*. Hasta hoy solo se hablaba con el plantel entero
## (la charla del entretiempo) o cuando un jugador te buscaba a ti. Ahora, desde
## su ficha, eliges el tema y él responde según quién es:
##   - el LÍDER agradece que le exijas; el FRÁGIL, que lo animes; el POLÉMICO
##     explota si le aprietas;
##   - hay MEMORIA: hablarle de lo mismo dos veces en dos semanas vale la mitad
##     ("otra vez, míster...");
##   - las PROMESAS se cobran: si le prometes minutos y en cuatro semanas no
##     juega al menos dos partidos, se entera todo el vestuario.
## Nada de `Azar`: la respuesta sale de su rasgo, su moral y un hash del día.

signal noticia(titulo: String, cuerpo: String)

const TEMAS := {
	"animar": "💪 Animarlo",
	"exigir": "📣 Exigirle más",
	"minutos": "⏱ Prometerle minutos",
	"contrato": "📄 Hablar de su contrato",
	"vida": "🏠 Preguntar por su vida",
}
const SEMANAS_MEMORIA := 2
const PLAZO_PROMESA := 4
const PARTIDOS_PROMESA := 2

## id -> {tema: semana_abs de la última charla de ese tema}
var ultima: Dictionary = {}
## id -> {limite: semana_abs, pj0: partidos al prometer}
var promesas: Dictionary = {}

static func _abs(anio: int, semana: int) -> int:
	return anio * 60 + semana

## Habla con `j` sobre `tema`. Devuelve {respuesta, efecto, moral}.
func hablar(j: Jugador, tema: String, anio: int, semana: int) -> Dictionary:
	if j == null or not TEMAS.has(tema):
		return {}
	var hoy := _abs(anio, semana)
	var mem: Dictionary = ultima.get(j.id, {})
	var repetido: bool = mem.has(tema) and hoy - int(mem[tema]) < SEMANAS_MEMORIA
	mem[tema] = hoy
	ultima[j.id] = mem
	var h := absi(("%s|%s|%d" % [j.id, tema, hoy]).hash())
	var d := 0
	var resp := ""
	match tema:
		"animar":
			d = 6 if j.rasgo == "fragil" else (2 if j.rasgo == "lider" else 4)
			if j.moral >= 85:
				d = 1
				resp = "«Gracias, míster, pero estoy bien. Al que hay que levantar es a otro.»"
			else:
				resp = ["«Lo necesitaba. Esta semana se me va a ver.»", "«Gracias por confiar. No le voy a fallar.»",
					"«Me hacía falta oírlo, de verdad.»"][h % 3]
		"exigir":
			if j.rasgo == "lider" or j.rasgo == "motor":
				d = 4
				resp = "«Tiene razón. Puedo dar más y lo voy a dar.»"
			elif j.rasgo == "polemico" or j.rasgo == "fragil":
				d = -6
				resp = "«¿Ahora la culpa es mía? Mire a los demás también.»" if j.rasgo == "polemico" else "«…Vale, míster.» (Sale cabizbajo.)"
			else:
				d = 2 if j.moral >= 55 else -3
				resp = "«Entendido.»" if d > 0 else "«No es fácil rendir cuando nadie te da confianza.»"
		"minutos":
			d = 5
			promesas[j.id] = {"limite": hoy + PLAZO_PROMESA, "pj0": j.partidos}
			resp = "«¿En serio? Entonces me voy a matar en los entrenamientos.»"
		"contrato":
			if j.anios_contrato <= 1:
				d = 3
				resp = "«Me gustaría seguir. Si el club me ofrece algo, lo escucho.»"
			elif j.edad >= 31:
				d = 1
				resp = "«A mi edad, lo que quiero es terminar bien aquí.»"
			else:
				d = 0
				resp = "«Tengo contrato, míster. Ahora solo pienso en jugar.»"
		"vida":
			d = 2
			## Su vida es la que ya cuenta su ficha (inventada, nunca la de una
			## persona real): `FichaJugadorInfo.perfil_humano()`.
			var p: Dictionary = FichaJugadorInfo.perfil_humano(j)
			var cuenta := String(p.get("d", "")) if not p.is_empty() else ""
			resp = "«%s»" % (cuenta if cuenta != "" else "Todo tranquilo, míster. La familia bien, gracias por preguntar.")
	if repetido:
		d = int(float(d) / 2.0) if d > 0 else d
		resp = "«Otra vez con lo mismo, míster…» " + resp
	j.moral = clampi(j.moral + d, 10, 99)
	var efecto := ("moral %+d" % d) if d != 0 else "sin cambios"
	return {"respuesta": resp, "efecto": efecto, "moral": d, "repetido": repetido}

## Una vez por semana: las promesas vencidas se cobran.
func semana(c: Club, anio: int, sem: int) -> void:
	if c == null:
		return
	var hoy := _abs(anio, sem)
	for id: String in promesas.keys():
		var p: Dictionary = promesas[id]
		if hoy < int(p["limite"]):
			continue
		promesas.erase(id)
		for j: Jugador in c.plantilla:
			if j.id == id:
				if j.partidos - int(p["pj0"]) < PARTIDOS_PROMESA:
					j.moral = clampi(j.moral - 8, 10, 99)
					for otro: Jugador in c.plantilla:
						otro.moral = clampi(otro.moral - 1, 10, 99)
					noticia.emit("🗣️ Promesa incumplida",
						"%s cuenta en el vestuario que le prometiste minutos y no llegaron. El grupo toma nota." % j.nombre)
				else:
					j.moral = clampi(j.moral + 3, 10, 99)
					noticia.emit("🤝 Promesa cumplida", "%s tuvo sus minutos, como le dijiste." % j.nombre)

func a_dic() -> Dictionary:
	return {"ultima": ultima, "promesas": promesas}

func desde_dic(d: Dictionary) -> void:
	ultima = (d.get("ultima", {}) as Dictionary).duplicate(true)
	promesas = (d.get("promesas", {}) as Dictionary).duplicate(true)
