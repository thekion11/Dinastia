class_name Academia
extends RefCounted
## LA ACADEMIA: LOS CHICOS DE 10 A 16 AÑOS (25-9-2026).
##
## El pedido está en `instruciones profundas/instrucciones_extras.txt`: "captas
## talentos de 10 a 16 años, diseñas sus planes de alimentación, controlas sus
## estudios escolares y moldeas su personalidad antes de entregárselos al DT
## principal". Llevaba en el ROADMAP desde el 12-9 como "el más grande de la
## fase, requiere motor nuevo real": la cantera de `Cantera` empieza a los 16.
##
## Esto es ese motor, y vive ANTES de `Cantera`: aquí los chicos todavía no son
## `Jugador` -no ocupan ficha, no cobran, no juegan-; son niños en la
## residencia del club. A los 16 (o desde los 15, si decides adelantarlo) se
## ENTREGAN: se convierten en un `Jugador` de verdad en la plantilla, y cómo
## llegan depende de cómo los formaste:
##
##  * EL PLAN DE TRABAJO (técnico, físico, táctico, descanso) y las HORAS de
##    fútbol que deja el colegio deciden cuánto crecen cada semana.
##  * LA ALIMENTACIÓN cuesta dinero y decide el desarrollo físico: un chico mal
##    alimentado se lesiona más y llega con menos techo; uno bien alimentado,
##    con más.
##  * LOS ESTUDIOS: priorizar el fútbol acelera el crecimiento pero hunde las
##    notas, y con malas notas la familia acaba sacándolo de la academia.
##  * LA PERSONALIDAD se moldea semana a semana (disciplina, liderazgo, temple,
##    ambición). La disciplina multiplica lo que crece; la que domine a los 16
##    se convierte en su rasgo (Motor, Líder, Cerebro, Killer).
##
## El techo real de cada chico está OCULTO: se ve una horquilla que se va
## estrechando cuanto más tiempo lleva en la casa. La regla de siempre de la
## cantera se respeta: el chico llega con media baja y techo alto.
##
## Solo existe para TU club, igual que la capa visible de `Cantera`.

signal noticia(titulo: String, cuerpo: String)
signal movimiento(concepto: String, monto: int)

const EDAD_MIN := 10
const EDAD_CAPTACION_MAX := 12
const EDAD_ENTREGA := 16
## Desde esta edad se puede entregar antes de tiempo.
const EDAD_ENTREGA_ANTICIPADA := 15
const CUPO := 12
const CANDIDATOS_POR_TEMPORADA := 4
const SEMANAS_TEMPORADA := 38

## Coste semanal por chico, en puntos internos antes de escalar por el tamaño
## del club (`Eco.escalar`): residencia y colegio. La comida va aparte.
const COSTE_RESIDENCIA := 45.0
const COSTE_CAPTACION := 1200.0

## Crecimiento: cada semana se come esta fracción de lo que le falta para su
## techo, multiplicada por los factores de abajo. Con 0,004 y factores medios,
## un chico captado a los 10 llega a los 16 con unos 18 puntos de margen entre
## media y techo -el mismo "media baja, techo alto" de `Cantera._camada_de()`-.
## Bien formado llega con 12; mal formado, con 26.
const RITMO := 0.004

const PLANES := {
	"tecnico": {"nombre": "Técnico", "desc": "Balón, control y pase. El que más hace crecer.", "crece": 1.12, "fisico": 0.0, "lesion": 1.0, "animo": 0.0},
	"fisico": {"nombre": "Físico", "desc": "Fuerza y resistencia. Desarrolla el cuerpo, pero lesiona más.", "crece": 0.95, "fisico": 0.16, "lesion": 1.9, "animo": -0.1},
	"tactico": {"nombre": "Táctico", "desc": "Leer el juego. Crece algo menos y forja el temple.", "crece": 1.0, "fisico": 0.0, "lesion": 0.9, "animo": 0.0},
	"descanso": {"nombre": "Descanso", "desc": "Semana suave: recupera el ánimo y las lesiones, casi no crece.", "crece": 0.35, "fisico": 0.0, "lesion": 0.3, "animo": 1.6},
}
const DIETAS := {
	"libre": {"nombre": "Comedor libre", "desc": "Gratis. Crece peor, se lesiona más y el cuerpo no termina de hacerse.", "coste": 0.0, "crece": 0.86, "fisico": 0.04, "lesion": 1.6, "animo": 0.25},
	"equilibrada": {"nombre": "Equilibrada", "desc": "Menú de residencia. Lo normal.", "coste": 14.0, "crece": 1.0, "fisico": 0.14, "lesion": 1.0, "animo": 0.0},
	"deportiva": {"nombre": "Nutricionista", "desc": "Plan de nutricionista. Cara; el mejor desarrollo físico y menos lesiones.", "coste": 34.0, "crece": 1.08, "fisico": 0.26, "lesion": 0.65, "animo": -0.15},
}
const ESTUDIOS := {
	"futbol": {"nombre": "Prioriza el fútbol", "desc": "Más horas de campo, menos de colegio. Las notas bajan.", "horas": 1.22, "nota": -0.025, "animo": 0.0},
	"equilibrio": {"nombre": "Equilibrio", "desc": "Colegio completo y entrenamiento de tarde.", "horas": 1.0, "nota": 0.006, "animo": 0.0},
	"estudios": {"nombre": "Prioriza los estudios", "desc": "Menos campo, notas altas y la familia tranquila.", "horas": 0.8, "nota": 0.04, "animo": 0.2},
}
## Los cuatro rasgos que se pueden moldear, y el rasgo de `RASGOS` al que
## conducen si dominan a los 16.
const PERSONALIDAD := {
	"disciplina": {"nombre": "Disciplina", "rasgo": "motor", "desc": "Entrena como nadie: multiplica lo que crece."},
	"liderazgo": {"nombre": "Liderazgo", "rasgo": "lider", "desc": "Tira del grupo. Llega con madera de capitán."},
	"temple": {"nombre": "Temple", "rasgo": "cerebro", "desc": "No se pone nervioso: lee el partido."},
	"ambicion": {"nombre": "Ambición", "rasgo": "killer", "desc": "Quiere ser el mejor. Hambre de gol."},
}

var _ref: WeakRef
var chicos: Array[Dictionary] = []
var candidatos: Array[Dictionary] = []
var _seq := 0
## Los que ya se entregaron, para la memoria del club.
var entregados: Array[Dictionary] = []

func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo

func _club() -> Club:
	var m := _mundo()
	return m.mi_club() if m != null else null

# ===========================================================================
#  ALTAS: LA PRIMERA CAMADA Y LA CAPTACIÓN
# ===========================================================================

## La academia no arranca vacía: al tomar el mando ya hay seis chicos de todas
## las edades, para que haya alguien que entregar pronto y alguien a quien
## formar entero.
func sembrar() -> void:
	chicos.clear()
	candidatos.clear()
	for edad in [10, 11, 12, 13, 14, 15]:
		chicos.append(_nuevo_chico(edad))
	_renovar_candidatos()

func _nuevo_chico(edad: int) -> Dictionary:
	var c := _club()
	var rep := c.rep if c != null else 70
	var pais := c.pais if c != null else "CHI"
	var m := _mundo()
	_seq += 1
	var grupo := String(Azar.uno(["POR", "DEF", "DEF", "MED", "MED", "DEL", "DEL"]))
	## El techo depende del club -un grande capta mejor- pero con mucha
	## dispersión: el crack puede aparecer en cualquier parte.
	var techo := clampi(rep - 8 + Azar.ent(-12, 16), 55, 95)
	## Lo que ya sabe según la edad: un chico de 10 es casi solo potencial.
	var nivel := float(clampi(22 + (edad - EDAD_MIN) * 6 + Azar.ent(-4, 4), 15, techo - 8))
	var error := Azar.ent(6, 10)
	var desvio := Azar.ent(-error + 2, error - 2)
	return {
		"id": "a%d" % _seq,
		"nombre": m._nombre_al_azar(pais, Regiones.region_para(pais, "a%d" % _seq, c)) if m != null else "Chico %d" % _seq,
		"pais": pais,
		"region": Regiones.region_para(pais, "a%d" % _seq, c),
		"edad": edad,
		"pos": grupo,
		"pos_e": m.cantera.demarcacion_de(grupo) if m != null and m.cantera != null else grupo,
		"nivel": nivel,
		"techo": techo,
		## La horquilla que ve el jugador: centrada en el techo real más un
		## desvío que el ojeador no sabe, y que se estrecha con el tiempo.
		"estimado": techo + desvio,
		"error": error,
		"fisico": float(Azar.ent(30, 60)),
		"nota": snappedf(lerpf(4.4, 6.2, Azar.f()), 0.1),
		"animo": float(Azar.ent(60, 85)),
		"personalidad": {
			"disciplina": float(Azar.ent(25, 65)), "liderazgo": float(Azar.ent(20, 60)),
			"temple": float(Azar.ent(25, 60)), "ambicion": float(Azar.ent(30, 70)),
		},
		"plan": "tecnico", "dieta": "equilibrada", "estudios": "equilibrio", "molde": "disciplina",
		"lesion": 0, "semanas": 0, "aviso_notas": false,
	}

func _renovar_candidatos() -> void:
	candidatos.clear()
	for i in CANDIDATOS_POR_TEMPORADA:
		candidatos.append(_nuevo_chico(Azar.ent(EDAD_MIN, EDAD_CAPTACION_MAX)))

func coste_captacion(ch: Dictionary) -> int:
	var c := _club()
	var rep := float(c.rep) if c != null else 70.0
	## Se paga por lo que PARECE -la estimación-, no por el techo real, que
	## nadie conoce: así un chico infravalorado es una ganga de verdad.
	var prima := pow(1.06, float(int(ch["estimado"]) - 70))
	return int(round(float(Eco.escalar(COSTE_CAPTACION, rep)) * prima))

## Capta al candidato `i`. Devuelve "" si se pudo, o el motivo.
func captar(i: int) -> String:
	var c := _club()
	if c == null or i < 0 or i >= candidatos.size():
		return "no hay candidato"
	if chicos.size() >= CUPO:
		return "la residencia está llena (%d plazas)" % CUPO
	var ch: Dictionary = candidatos[i]
	var coste := coste_captacion(ch)
	if coste > c.saldo:
		return "no hay caja"
	c.mover_saldo(-coste)
	movimiento.emit("Academia: captación de %s" % ch["nombre"], -coste)
	candidatos.remove_at(i)
	chicos.append(ch)
	noticia.emit("Nuevo chico en la academia",
		"%s (%d años, %s) deja su club de barrio y se muda a la residencia." % [ch["nombre"], int(ch["edad"]), ch["pos_e"]])
	return ""

# ===========================================================================
#  EL DÍA A DÍA: LAS DECISIONES DE CADA CHICO
# ===========================================================================

func chico(id: String) -> Dictionary:
	for ch in chicos:
		if String(ch["id"]) == id:
			return ch
	return {}

## Cambia el plan, la dieta, los estudios o el molde de un chico.
func cambiar(id: String, campo: String, valor: String) -> String:
	var ch := chico(id)
	if ch.is_empty():
		return "ese chico no está en la academia"
	var catalogo: Dictionary = {"plan": PLANES, "dieta": DIETAS, "estudios": ESTUDIOS, "molde": PERSONALIDAD}.get(campo, {})
	if not catalogo.has(valor):
		return "opción desconocida"
	ch[campo] = valor
	return ""

func coste_semanal_de(ch: Dictionary) -> int:
	var c := _club()
	var rep := float(c.rep) if c != null else 70.0
	var base := COSTE_RESIDENCIA + float(DIETAS[String(ch["dieta"])]["coste"])
	return Eco.escalar(base, rep)

func coste_semanal() -> int:
	var t := 0
	for ch in chicos:
		t += coste_semanal_de(ch)
	return t

## Lo que el jugador ve del techo: una horquilla que se estrecha con cada
## temporada que el chico pasa en la casa.
func proyeccion(ch: Dictionary) -> Vector2i:
	var err := maxi(2, int(ch["error"]) - int(ch["semanas"]) / 19)
	## El desvío también se va corrigiendo: el ojeador acaba conociéndolo.
	var centro := int(round(lerpf(float(ch["estimado"]), float(ch["techo"]), clampf(float(ch["semanas"]) / 150.0, 0.0, 1.0))))
	return Vector2i(clampi(centro - err, 40, 99), clampi(centro + err, 40, 99))

## El rasgo que domina ahora mismo, o "" si ninguno pasa de 70.
func rasgo_dominante(ch: Dictionary) -> String:
	var mejor := ""
	var valor := 70.0
	var p: Dictionary = ch["personalidad"]
	for k: String in p:
		if float(p[k]) >= valor:
			valor = float(p[k])
			mejor = k
	return mejor

# ===========================================================================
#  LA SEMANA
# ===========================================================================

## Una semana de academia: coste, crecimiento, colegio, ánimo, lesiones,
## personalidad y la familia que se lleva al chico si las notas se hunden.
## Devuelve los sucesos de la semana (para el banco de pruebas y el diario).
func procesar_semana() -> Array[Dictionary]:
	var c := _club()
	var sucesos: Array[Dictionary] = []
	if c == null or chicos.is_empty():
		return sucesos
	var coste := coste_semanal()
	if coste > 0:
		c.mover_saldo(-coste)
		movimiento.emit("Academia: residencia, colegio y comida", -coste)
	var se_van: Array[Dictionary] = []
	for ch in chicos:
		var s := _semana_de(ch)
		if not s.is_empty():
			sucesos.append(s)
			if String(s.get("tipo", "")) == "abandono":
				se_van.append(ch)
	for ch in se_van:
		chicos.erase(ch)
	return sucesos

func _semana_de(ch: Dictionary) -> Dictionary:
	var plan: Dictionary = PLANES[String(ch["plan"])]
	var dieta: Dictionary = DIETAS[String(ch["dieta"])]
	var est: Dictionary = ESTUDIOS[String(ch["estudios"])]
	var p: Dictionary = ch["personalidad"]
	ch["semanas"] = int(ch["semanas"]) + 1

	## Lesionado: no crece, y la semana de descanso acorta la baja.
	if int(ch["lesion"]) > 0:
		ch["lesion"] = maxi(0, int(ch["lesion"]) - (2 if String(ch["plan"]) == "descanso" else 1))
	else:
		var disciplina := 0.7 + float(p["disciplina"]) / 100.0 * 0.6
		var animo := 0.8 if float(ch["animo"]) < 30.0 else 1.0
		var f := float(plan["crece"]) * float(dieta["crece"]) * float(est["horas"]) * disciplina * animo
		var falta := float(ch["techo"]) - float(ch["nivel"])
		ch["nivel"] = float(ch["nivel"]) + falta * RITMO * f

	ch["fisico"] = clampf(float(ch["fisico"]) + float(dieta["fisico"]) + float(plan["fisico"]), 0.0, 100.0)
	ch["nota"] = clampf(float(ch["nota"]) + float(est["nota"]) + (float(p["disciplina"]) - 50.0) / 5000.0
		+ lerpf(-0.02, 0.02, Azar.f()), 1.0, 7.0)
	var d_animo := float(plan["animo"]) + float(dieta["animo"]) + float(est["animo"])
	if float(ch["nota"]) < 4.0 and String(ch["estudios"]) == "futbol":
		d_animo -= 0.4   ## en casa hay bronca por las notas
	ch["animo"] = clampf(float(ch["animo"]) + d_animo + lerpf(-0.3, 0.3, Azar.f()), 0.0, 100.0)

	## La personalidad: el molde elegido crece, el plan táctico forja temple y
	## priorizar el colegio, disciplina.
	var molde := String(ch["molde"])
	p[molde] = clampf(float(p[molde]) + 0.45, 0.0, 100.0)
	if String(ch["plan"]) == "tactico":
		p["temple"] = clampf(float(p["temple"]) + 0.12, 0.0, 100.0)
	if String(ch["estudios"]) == "estudios":
		p["disciplina"] = clampf(float(p["disciplina"]) + 0.08, 0.0, 100.0)

	## Lesiones: el plan físico y comer mal, sobre un cuerpo sin hacer.
	if int(ch["lesion"]) == 0:
		var riesgo := 0.004 * float(plan["lesion"]) * float(dieta["lesion"]) * (1.4 if float(ch["fisico"]) < 40.0 else 1.0)
		if Azar.suerte(riesgo):
			ch["lesion"] = Azar.ent(2, 6)
			noticia.emit("Lesión en la academia",
				"%s se lesiona entrenando: %d semanas de baja." % [ch["nombre"], int(ch["lesion"])])
			return {"tipo": "lesion", "id": ch["id"]}

	## El colegio: primero avisa, y si las notas no remontan la familia lo saca.
	if float(ch["nota"]) < 4.2 and not bool(ch["aviso_notas"]):
		ch["aviso_notas"] = true
		noticia.emit("Llaman del colegio",
			"Las notas de %s van en %.1f. Si siguen bajando, su familia lo sacará de la academia." % [ch["nombre"], float(ch["nota"])])
		return {"tipo": "aviso", "id": ch["id"]}
	if float(ch["nota"]) >= 4.6:
		ch["aviso_notas"] = false
	if float(ch["nota"]) < 3.6 and Azar.suerte(0.05):
		noticia.emit("Un chico deja la academia",
			"La familia de %s lo saca de la residencia: con esas notas, primero el colegio." % ch["nombre"])
		return {"tipo": "abandono", "id": ch["id"]}
	return {}

# ===========================================================================
#  LA TEMPORADA: CUMPLEAÑOS, ENTREGAS Y CAPTACIÓN NUEVA
# ===========================================================================

## Al empezar la temporada: todos cumplen un año, los de 16 pasan al primer
## equipo y llega una tanda nueva de candidatos. Devuelve los `Jugador` que se
## entregaron.
func fin_de_temporada() -> Array[Jugador]:
	var salida: Array[Jugador] = []
	for ch in chicos:
		ch["edad"] = int(ch["edad"]) + 1
	var listos: Array[Dictionary] = []
	for ch in chicos:
		if int(ch["edad"]) >= EDAD_ENTREGA:
			listos.append(ch)
	for ch in listos:
		var j := _entregar(ch, int(ch["edad"]) >= EDAD_ENTREGA + 1)
		if j != null:
			salida.append(j)
	_renovar_candidatos()
	return salida

## Entrega anticipada, desde los 15, a petición del jugador.
func entregar(id: String) -> String:
	var ch := chico(id)
	if ch.is_empty():
		return "ese chico no está en la academia"
	if int(ch["edad"]) < EDAD_ENTREGA_ANTICIPADA:
		return "todavía es muy chico: se entrega desde los %d" % EDAD_ENTREGA_ANTICIPADA
	return "" if _entregar(ch, false) != null else "no hay ficha libre en el plantel"

## Lo convierte en `Jugador`. Sin ficha libre se queda un año más; a los 17 se
## entrega igual (`forzar`): la residencia no es para adultos.
func _entregar(ch: Dictionary, forzar: bool) -> Jugador:
	var m := _mundo()
	var c := _club()
	if m == null or c == null:
		return null
	if c.plantilla.size() >= Cantera.TOPE_PLANTEL and not forzar:
		noticia.emit("Sin ficha para %s" % ch["nombre"],
			"El plantel está lleno (%d fichas): se queda un año más en la academia." % c.plantilla.size())
		return null
	var ovr := clampi(int(round(float(ch["nivel"]))), 40, 74)
	var j := m.crear_jugador(c, String(ch["pos"]), String(ch["pos_e"]), int(ch["edad"]), ovr)
	j.nombre = String(ch["nombre"])
	j.pais = String(ch["pais"])
	j.region = String(ch.get("region", j.region))
	j.pot = clampi(techo_al_entregar(ch), j.ovr, 97)
	var dominante := rasgo_dominante(ch)
	if dominante != "":
		j.rasgo = String(PERSONALIDAD[dominante]["rasgo"])
	elif float(ch["fisico"]) < 30.0:
		j.rasgo = "fragil"
	else:
		j.rasgo = ""
	j.moral = clampi(int(round(float(ch["animo"]))), 20, 95)
	j.forma = 60
	j.anios_contrato = 3
	j.generar_atributos()
	j.tasar()
	if m.cantera != null:
		j.dorsal = m.cantera._dorsal_libre(c)
		m.cantera.registrar_de_academia(j, m.anio)
	c.plantilla.append(j)
	chicos.erase(ch)
	entregados.append({"nombre": j.nombre, "anio": m.anio, "ovr": j.ovr, "pot": j.pot, "id": j.id})
	noticia.emit("De la academia al primer equipo",
		"%s (%d años, %s) sube al plantel: media %d, proyección %d%s." % [j.nombre, j.edad, j.pos_e, j.ovr, j.pot,
			(", rasgo %s" % String((Datos.tabla("RASGOS") as Dictionary).get(j.rasgo, [j.rasgo])[0])) if j.rasgo != "" else ""])
	return j

## El techo con el que llega: el techo real, corregido por cómo se le formó.
## Buen cuerpo, disciplina y buenas notas lo suben; mal cuerpo lo baja.
func techo_al_entregar(ch: Dictionary) -> int:
	var t := float(ch["techo"])
	var fisico := float(ch["fisico"])
	t += clampf((fisico - 50.0) / 12.0, -3.0, 4.0)
	t += clampf((float(ch["personalidad"]["disciplina"]) - 50.0) / 16.0, -2.0, 3.0)
	if float(ch["nota"]) >= 6.0:
		t += 1.0
	return int(round(t))

# ===========================================================================
#  GUARDADO
# ===========================================================================

func a_dic() -> Dictionary:
	return {"chicos": chicos.duplicate(true), "candidatos": candidatos.duplicate(true),
		"seq": _seq, "entregados": entregados.duplicate(true)}

func desde_dic(d: Dictionary) -> void:
	if d.is_empty():
		## Un guardado de antes de la academia: se siembra como al tomar el mando.
		sembrar()
		return
	chicos.clear()
	for ch: Dictionary in d.get("chicos", []):
		chicos.append(ch.duplicate(true))
	candidatos.clear()
	for ch: Dictionary in d.get("candidatos", []):
		candidatos.append(ch.duplicate(true))
	_seq = int(d.get("seq", chicos.size() + candidatos.size()))
	entregados.clear()
	for e: Dictionary in d.get("entregados", []):
		entregados.append(e.duplicate(true))
