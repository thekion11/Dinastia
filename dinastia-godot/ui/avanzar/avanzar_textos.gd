class_name AvanzarTextos
extends RefCounted
## LOS TEXTOS DE LOS EVENTOS DEL AVANCE POR DÍAS (paso 3, 17-11-2026). El evento trae su `causa` ({id, datos}); aquí se redacta (icono, título, texto y color
## según su clase) con `Idiomas.t`. Lo que ya viene con texto propio y traducido (calendario, `CrisisCaja`, imprevistos, fechas del país) se usa tal cual.

const COLOR_PARTIDO := Color("2f8f5b")
const COLOR_PANTALLA := Color("c9a227")
const COLOR_AVISO := Color("c0392b")
const ICONO_FECHA := {"memoria": "🕯️", "independencia": "🎆", "trabajo": "🛠️", "fiesta": "🎉", "festividad": "🎊"}
## id de la causa -> [icono, título]; el texto lo arma `texto`.
const CAUSAS := {
	"despido": ["🚪", "La directiva te despide"], "ultimatum": ["⚠️", "Tu puesto está en el aire"], "golpe_caja": ["💸", "Golpe de caja"],
	"imprevisto": ["❗", "Imprevisto"], "jugador_del_mes": ["🏅", "Jugador del mes"], "guerra_agentes": ["🕴️", "Guerra de agentes"],
	"evento_cantera": ["🌱", "Novedad en la cantera"], "hallazgo": ["🔭", "Hallazgo de los ojeadores"], "retos_semana": ["🎯", "Retos de la semana"],
	"cambio_dt": ["🔄", "Cambio de entrenador"], "oferta_seleccion": ["🌍", "Te llama una selección"], "sancion_dt": ["🟥", "Sanción al entrenador"]}

static func clase_color(clase: String) -> Color:
	match clase:
		EventosDia.PARTIDO: return COLOR_PARTIDO
		EventosDia.PANTALLA: return COLOR_PANTALLA
	return COLOR_AVISO

static func icono(ev: Dictionary) -> String:
	if ev.has("icono"):
		return String(ev["icono"])
	if String(ev.get("tipo", "")) == "fecha_pais":
		return String(ICONO_FECHA.get(String(ev.get("subtipo", "")), "📅"))
	var c: Array = CAUSAS.get(String((ev.get("causa", {}) as Dictionary).get("id", "")), ["📌", ""])
	return String(c[0])

static func titulo(ev: Dictionary) -> String:
	if ev.has("titulo"):
		return String(ev["titulo"])
	if String(ev.get("tipo", "")) == "fecha_pais":
		return Idiomas.t(String(ev.get("nombre", "")))
	if ev.has("etiqueta"):
		return String(ev["etiqueta"])
	var c: Array = CAUSAS.get(String((ev.get("causa", {}) as Dictionary).get("id", "")), ["", "Novedad"])
	return Idiomas.t(String(c[1]))

## El texto de la segunda línea: el propio del evento, o el armado con los datos de su causa.
static func texto(ev: Dictionary) -> String:
	if ev.has("texto") and String(ev["texto"]) != "":
		return Idiomas.t(String(ev["texto"])) if String(ev.get("tipo", "")) != "imprevisto" else String(ev["texto"])
	var d: Dictionary = (ev.get("causa", {}) as Dictionary).get("datos", {})
	match String((ev.get("causa", {}) as Dictionary).get("id", "")):
		"despido": return Idiomas.t("La confianza de la directiva llegó al límite.")
		"ultimatum": return Idiomas.t("La directiva te da un ultimátum: confianza %d.") % int(d.get("confianza", 0))
		"jugador_del_mes":
			if bool(ev.get("es_mio", false)):
				return Idiomas.t("%s, de tu club, es el jugador del mes.") % String(ev.get("nombre", ""))
			return Idiomas.t("%s (%s) es el jugador del mes de tu liga.") % [String(ev.get("nombre", "")), String(ev.get("club", ""))]
		"hallazgo": return Idiomas.t("Tus ojeadores encontraron a %s.") % String(ev.get("nombre", ""))
		"retos_semana": return Idiomas.t("%d retos nuevos para esta semana.") % int(d.get("n", 0))
		"cambio_dt": return Idiomas.t("%s deja el banquillo de %s. Llega %s.") % [String(d.get("sale", "")), String(d.get("club", "")), String(d.get("entra", ""))]
		"oferta_seleccion": return Idiomas.t("La selección de %s quiere que la dirijas.") % String(d.get("seleccion", ""))
		"sancion_dt": return Idiomas.t("El tribunal te sanciona con %d partido(s).") % int(d.get("fechas", 0))
	return ""
