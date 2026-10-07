class_name Maestria
extends RefCounted
## LAS MAESTRÍAS DEL ENTRENADOR (26-9-2026). Pedido: *"que las habilidades tengan
## unas 15 categorías más, y unos 30 niveles por cada categoría"*.
##
## El árbol de siempre (`Entrenamiento.dt_*`, cinco ramas con nodos que se
## desbloquean) sigue igual. Esto es la otra mitad: 15 categorías de oficio, cada
## una con 30 niveles, que se suben con PUNTOS DE MAESTRÍA:
##   - se gana uno cada semana trabajada y otro por cada victoria;
##   - subir al nivel n cuesta 1 + n/10 puntos (los primeros niveles son
##     baratos; del 21 al 30, tres cada uno);
##   - en los niveles 10, 20 y 30 de cada categoría hay un HITO: un punto de
##     habilidad para el árbol y el efecto de la categoría se nota el doble.
## Todo tiene efecto de verdad en el juego (ver `EFECTO` y `semana()`), pequeño
## por nivel y grande al final: el nivel 30 de Ataque son +6 % de ataque.

signal noticia(titulo: String, cuerpo: String)
signal movimiento(concepto: String, monto: int)

const NIVEL_MAX := 30

## clave -> [nombre, icono, color, qué hace (por nivel), rama visual]
const CATEGORIAS := {
	"ataque": ["Ataque", "⚔️", "e05555", "+0,2 % de ataque por nivel"],
	"defensa": ["Defensa", "🛡️", "2f7fd0", "+0,2 % de defensa por nivel"],
	"porteros": ["Porteros", "🧤", "d9a400", "+0,1 % de defensa por nivel (trabajo con arqueros)"],
	"balon_parado": ["Balón parado", "🎯", "e07b2a", "+0,1 % de ataque por nivel (córners y tiros libres)"],
	"analisis": ["Análisis de rivales", "📹", "5c7cfa", "+0,1 % de ataque y de defensa por nivel"],
	"fisica": ["Preparación física", "🏃", "3fa06a", "El plantel recupera físico más rápido cada semana"],
	"cargas": ["Gestión de cargas", "🔋", "20c997", "Los cansados recuperan forma cada semana"],
	"liderazgo": ["Liderazgo", "👑", "c9a227", "Moral del plantel cada cuatro semanas"],
	"psicologia": ["Psicología", "🧠", "b05cd6", "Nadie cae por debajo de un suelo de moral que sube con el nivel"],
	"idiomas": ["Idiomas", "🗣️", "15aabf", "Los extranjeros se adaptan antes"],
	"formacion": ["Formación juvenil", "🌱", "40c057", "Los chicos de la academia progresan más"],
	"prensa": ["Relación con la prensa", "🎤", "868e96", "La hinchada te quiere más, más a menudo"],
	"aficion": ["Relación con la hinchada", "📣", "f76707", "+0,3 % de público por nivel"],
	"finanzas": ["Finanzas", "💹", "82c91e", "Ingreso semanal extra para el club"],
	"negociacion": ["Negociación de sueldos", "🤝", "fab005", "Recuperas un 0,3 % de la masa salarial por nivel"],
}
const ORDEN := ["ataque", "defensa", "porteros", "balon_parado", "analisis", "fisica", "cargas",
	"liderazgo", "psicologia", "idiomas", "formacion", "prensa", "aficion", "finanzas", "negociacion"]
const HITOS := [10, 20, 30]

var niveles: Dictionary = {}     ## clave -> nivel (0..30)
var puntos: int = 0
var ganados: int = 0             ## total ganados, para las pruebas y la ficha

func nivel(clave: String) -> int:
	return int(niveles.get(clave, 0))

## Lo que cuesta subir al siguiente nivel.
func coste(clave: String) -> int:
	return 1 + int(float(nivel(clave)) / 10.0)

func total_niveles() -> int:
	var t := 0
	for k: String in ORDEN:
		t += nivel(k)
	return t

## Nivel "efectivo": cada hito alcanzado suma 5 niveles de efecto (el nivel 30
## rinde como 45). Es lo que hace que los hitos se noten.
func efectivo(clave: String) -> float:
	var n := nivel(clave)
	var extra := 0
	for h: int in HITOS:
		if n >= h:
			extra += 5
	return float(n + extra)

## Sube un nivel. Devuelve "" si se pudo, o el motivo.
func subir(clave: String, entrenamiento: Entrenamiento = null) -> String:
	if not CATEGORIAS.has(clave):
		return "esa categoría no existe"
	if nivel(clave) >= NIVEL_MAX:
		return "ya está al máximo"
	var c := coste(clave)
	if puntos < c:
		return "te faltan %d punto(s) de maestría" % (c - puntos)
	puntos -= c
	niveles[clave] = nivel(clave) + 1
	var n := nivel(clave)
	if HITOS.has(n):
		if entrenamiento != null:
			entrenamiento.dt_puntos += 1
		noticia.emit("🏅 Hito de maestría", "%s llega al nivel %d: su efecto se refuerza y ganas un punto de habilidad para el árbol." % [String(CATEGORIAS[clave][0]), n])
	return ""

## ---------------------------------------------------------------- EFECTOS ---

func factor_ataque() -> float:
	return 1.0 + efectivo("ataque") * 0.002 * _norma() + efectivo("balon_parado") * 0.001 * _norma() + efectivo("analisis") * 0.001 * _norma()

func factor_defensa() -> float:
	return 1.0 + efectivo("defensa") * 0.002 * _norma() + efectivo("porteros") * 0.001 * _norma() + efectivo("analisis") * 0.001 * _norma()

func factor_publico() -> float:
	return 1.0 + efectivo("aficion") * 0.003 * _norma()

## El nivel efectivo máximo es 45 (30 + tres hitos): se reescala para que el
## tope anunciado sea el del nivel 30 (+6 % de ataque, etc.).
func _norma() -> float:
	return 30.0 / 45.0

## Una vez por semana. `resultado`: 1 ganó, 0 empató, -1 perdió, 2 sin partido.
func semana(c: Club, prensa: Prensa, academia: Academia, sem: int, resultado: int) -> void:
	if c == null:
		return
	puntos += 1
	ganados += 1
	if resultado == 1:
		puntos += 1
		ganados += 1
	var fis := int(efectivo("fisica") / 9.0)
	var car := int(efectivo("cargas") / 9.0)
	var suelo := 20 + int(efectivo("psicologia"))
	var ada := int(efectivo("idiomas") / 5.0)
	for j: Jugador in c.plantilla:
		if fis > 0:
			j.fisico = mini(100, j.fisico + fis)
		if car > 0 and j.forma < 55:
			j.forma = mini(99, j.forma + car)
		if nivel("psicologia") > 0 and j.moral < suelo:
			j.moral = mini(99, j.moral + 1)
		if ada > 0 and j.pais != c.pais:
			j.adapt = mini(100, j.adapt + ada)
	if sem % 4 == 0 and nivel("liderazgo") > 0:
		var sube := 1 + int(efectivo("liderazgo") / 20.0)
		for j: Jugador in c.plantilla:
			j.moral = clampi(j.moral + sube, 10, 99)
	if academia != null and nivel("formacion") > 0:
		for ch: Dictionary in academia.chicos:
			ch["nivel"] = float(ch["nivel"]) + efectivo("formacion") * 0.02
	if prensa != null and nivel("prensa") > 0:
		var cada := maxi(2, 12 - int(efectivo("prensa") / 4.0))
		if sem % cada == 0:
			prensa.mover_animo(1)
	if nivel("finanzas") > 0:
		var extra := Eco.escalar(250.0 * efectivo("finanzas") * _norma(), float(c.rep))
		c.mover_saldo(extra)
		movimiento.emit("Gestión financiera del DT", extra)
	if nivel("negociacion") > 0:
		var ahorro := int(float(c.masa_salarial()) * efectivo("negociacion") * _norma() * 0.003)
		if ahorro > 0:
			c.mover_saldo(ahorro)
			movimiento.emit("Ahorro en sueldos por negociación", ahorro)

## El efecto actual de una categoría, en palabras, para la ficha.
func efecto_actual(clave: String) -> String:
	var e := efectivo(clave) * _norma()
	match clave:
		"ataque": return "+%.1f %% de ataque" % (e * 0.2)
		"defensa": return "+%.1f %% de defensa" % (e * 0.2)
		"porteros": return "+%.1f %% de defensa" % (e * 0.1)
		"balon_parado": return "+%.1f %% de ataque" % (e * 0.1)
		"analisis": return "+%.1f %% de ataque y defensa" % (e * 0.1)
		"fisica": return "+%d de físico por semana" % int(efectivo(clave) / 9.0)
		"cargas": return "+%d de forma por semana a los cansados" % int(efectivo(clave) / 9.0)
		"liderazgo": return "+%d de moral cada cuatro semanas" % (1 + int(efectivo(clave) / 20.0)) if nivel(clave) > 0 else "sin efecto aún"
		"psicologia": return "suelo de moral en %d" % (20 + int(efectivo(clave))) if nivel(clave) > 0 else "sin efecto aún"
		"idiomas": return "+%d de adaptación por semana" % int(efectivo(clave) / 5.0)
		"formacion": return "+%.2f de nivel semanal a cada chico" % (efectivo(clave) * 0.02)
		"prensa": return "+1 de ánimo cada %d semanas" % maxi(2, 12 - int(efectivo(clave) / 4.0)) if nivel(clave) > 0 else "sin efecto aún"
		"aficion": return "+%.1f %% de público" % (e * 0.3)
		"finanzas": return "ingreso semanal extra (%d)" % int(250.0 * e) if nivel(clave) > 0 else "sin efecto aún"
		"negociacion": return "recuperas %.1f %% de los sueldos" % (e * 0.3)
	return ""

func a_dic() -> Dictionary:
	return {"niv": niveles, "pts": puntos, "gan": ganados}

func desde_dic(d: Dictionary) -> void:
	niveles = (d.get("niv", {}) as Dictionary).duplicate()
	puntos = int(d.get("pts", 0))
	ganados = int(d.get("gan", 0))
