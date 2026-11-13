class_name CarreraMomentos
extends RefCounted
## «LOS MOMENTOS» (13-11-2026): el partido en cuatro jugadas tuyas. Entre jugarlo
## entero en el césped y simularlo, la tercera vía: las ocasiones que te tocan
## según tu puesto, cada una decidida en la barra de toque (`RutaBarra`). Tus
## atributos ensanchan la zona; lo que hagas da el resultado del partido.

## tipo -> [título, situación, atributo, clase de desenlace]
const TIPOS := {
	"remate": ["Remate en el área", "El centro llega al punto de penal. Es tuya.", "tir", "gol"],
	"mano": ["Mano a mano", "Te escapas solo y el portero sale a achicar.", "reg", "gol"],
	"pase": ["Pase filtrado", "Ves el desmarque entre los centrales.", "pas", "asist"],
	"robo": ["Robo en el medio", "El rival se duerme con el balón en los pies.", "def", "robo"],
	"entrada": ["Última entrada", "El delantero encara y eres el último hombre.", "def", "muro"],
	"despeje": ["Despeje sobre la línea", "El balón va camino de la red. Llegas tú.", "fis", "muro"],
	"parada": ["Mano a mano del rival", "Se planta solo delante de ti.", "ref", "guante"],
	"vuelo": ["Tiro a la escuadra", "Le pega seco desde la frontal.", "div", "guante"],
	"salida": ["Centro al área", "El balón cuelga en el área chica.", "pos", "guante"],
	"falta": ["Falta al borde del área", "Veintidós metros, barrera de cinco. La pides tú.", "tir", "gol"],
	"cabezazo": ["Cabezazo en el córner", "El córner viene cerrado al primer palo.", "fis", "gol"],
	"centro": ["Centro desde la banda", "Llegas a línea de fondo con el nueve entrando.", "pas", "asist"],
	"cobertura": ["Cobertura al compañero", "A tu lateral lo han superado. Te toca cerrar.", "def", "robo"],
	"penal": ["Penal en contra", "Once metros. Solo estáis él y tú.", "ref", "guante"],
	"pies": ["Salida con los pies", "Te presionan dos y hay un compañero libre en la banda.", "saq", "robo"],
}
## Las jugadas que le pueden tocar a cada línea: la primera sale siempre (es la
## del puesto) y de las demás se sortean tres, distintas, cada partido.
const GUIONES := {
	"DEL": ["remate", "pase", "mano", "cabezazo", "falta"],
	"MED": ["pase", "remate", "robo", "falta", "centro", "cobertura"],
	"DEF": ["entrada", "despeje", "pase", "cabezazo", "centro", "cobertura"],
	"POR": ["parada", "salida", "vuelo", "penal", "pies"],
}
const POR_PARTIDO := 4
## clase -> [perfecto, bien, fallo]
const DESENLACES := {
	"gol": ["¡GOL!", "Al palo. Casi.", "Se va fuera."],
	"asist": ["¡ASISTENCIA!", "Buen pase, pero no acaba en gol.", "Te cortan el pase."],
	"robo": ["¡Robo limpio y contra!", "Lo frenas a medias.", "Te dejan atrás."],
	"muro": ["¡Corte perfecto!", "Lo mandas a córner.", "Te supera: gol del rival."],
	"guante": ["¡PARADÓN!", "Paras en dos tiempos.", "Gol del rival."],
}

## Las jugadas de este partido: [{tipo, minuto}], en orden. Suplente: las dos
## últimas, desde el minuto en que entra.
static func guion(c: CarreraJugador, m: Mundo, entra_al := -1) -> Array:
	var j := c.jugador(m)
	var tipos: Array = (GUIONES.get(j.pos if j != null else "MED", GUIONES["MED"]) as Array).duplicate()
	## La jugada favorita de tu estilo sale siempre, la primera.
	var fav := CarreraEstilo.favorita(c, m)
	if fav != "" and TIPOS.has(fav):
		tipos.erase(fav)
		tipos.push_front(fav)
	var g := CarreraRuta._azar(c, m, 7)
	## Se barajan (menos la primera, que presenta el puesto) y se juegan cuatro.
	for i in range(tipos.size() - 1, 1, -1):
		var k := g.randi_range(1, i)
		var tmp: String = tipos[i]
		tipos[i] = tipos[k]
		tipos[k] = tmp
	tipos = tipos.slice(0, POR_PARTIDO)
	if entra_al >= 0:
		tipos = tipos.slice(tipos.size() - 2)
	var desde := maxi(4, entra_al + 3)
	var paso := float(88 - desde) / float(tipos.size())
	var out: Array = []
	for i2 in tipos.size():
		out.append({"tipo": String(tipos[i2]), "minuto": desde + int(paso * float(i2)) + g.randi_range(0, maxi(1, int(paso) - 2))})
	return out

## La zona de la barra para una jugada: [medio ancho perfecto, medio ancho bien].
## Con 50 en el atributo es estrecha; con 90, generosa.
## `forma` (−3 a +3) suma dos puntos de atributo por punto; `favorita`: la jugada de tu estilo, un 25 % más ancha.
static func zona(j: Jugador, tipo: String, forma := 0, favorita := false) -> Array:
	var attr := String(TIPOS[tipo][2])
	var v := (float(j.atributos.get(attr, j.ovr)) if j != null else 60.0) + float(forma) * 2.0
	var k := clampf((v - 40.0) / 55.0, 0.0, 1.0)
	var ancho := CarreraEstilo.ZONA_FAVORITA if favorita else 1.0
	return [(0.03 + 0.05 * k) * ancho, (0.09 + 0.09 * k) * ancho]

## Lo que deja una jugada con calidad `q` (1 perfecto, 0,6 bien, 0,1 fallo).
static func desenlace(tipo: String, q: float) -> Dictionary:
	var clase := String(TIPOS[tipo][3])
	var nivel := 0 if q >= 1.0 else (1 if q >= 0.6 else 2)
	var d := {"texto": String(DESENLACES[clase][nivel]), "gol": 0, "asist": 0, "parada": 0, "encajado": 0,
		"nota": [0.7, 0.3, -0.3][nivel]}
	match clase:
		"gol": d["gol"] = 1 if nivel == 0 else 0
		"asist": d["asist"] = 1 if nivel == 0 else 0
		"muro": d["encajado"] = 1 if nivel == 2 else 0
		"guante":
			d["parada"] = 1 if nivel < 2 else 0
			d["encajado"] = 1 if nivel == 2 else 0
	if d["gol"] == 1:
		d["nota"] = 1.0
	return d

## El resumen del partido (el mismo que da el partido jugado en el césped) a
## partir de las jugadas resueltas. El resto del marcador lo ponen los otros 21.
## `mi_equipo`: con la selección, el equipo de paso con el que juegas (si no, tu club).
static func resultado(c: CarreraJugador, m: Mundo, par: Array, hechas: Array, entra_al := -1, eliminatoria := false, mi_equipo: Club = null) -> Dictionary:
	var club := mi_equipo if mi_equipo != null else c.club(m)
	var soy_local: bool = par.size() == 2 and par[0] == club
	var g := CarreraRuta._azar(c, m, 9)
	var goles := 0
	var asist := 0
	var paradas := 0
	var encajados := 0
	var nota := 6.0
	for h: Dictionary in hechas:
		goles += int(h.get("gol", 0))
		asist += int(h.get("asist", 0))
		paradas += int(h.get("parada", 0))
		encajados += int(h.get("encajado", 0))
		nota += float(h.get("nota", 0.0))
	## Los goles de los demás: los tuyos pesan, pero no juegas solo.
	var rival: Club = (par[1] if soy_local else par[0]) if par.size() == 2 else null
	var ventaja := float(club.rep - rival.rep) / 40.0 if club != null and rival != null else 0.0
	var mios := goles + asist + (1 if g.randf() < 0.35 + ventaja else 0)
	var suyos := encajados + (1 if g.randf() < 0.40 - ventaja else 0)
	if eliminatoria and mios == suyos:
		if nota >= 6.6:
			mios += 1
		else:
			suyos += 1
	return {"goles_local": mios if soy_local else suyos, "goles_visita": suyos if soy_local else mios, "goles": goles, "asist": asist,
		"nota": snappedf(clampf(nota, 4.0, 10.0), 0.1), "minutos": 90 if entra_al < 0 else 90 - entra_al, "titular": entra_al < 0,
		"sustituido": false, "paradas": paradas, "encajados": suyos, "momentos": true}
