class_name Ojeadores
extends RefCounted
## "RED DE OJEADORES CON NOMBRE Y SESGO" del HTML (v2.9, ideas 446-475), que
## en Godot no tenía ningún equivalente: `Staff.ojo()` da una probabilidad
## plana de que llegue un informe, pero el HTML tiene un sistema mucho más
## grande detrás, y no es solo una pantalla -es la lógica que decide qué tan
## bien conoces a CUALQUIER jugador que no sea tuyo-.
##
## Cada país que cubres tiene un ojeador de carne y hueso: nombre, sesgo (el
## entusiasta infla el informe, el desconfiado lo recorta), especialidad y un
## humor que baja si le ignoras los hallazgos -y si llega a cero, renuncia y
## pierdes la cobertura de ese país hasta contratar a otro-. Cuántos países
## puedes cubrir a la vez depende del nivel de `Staff.nivel("ojeador")`, igual
## que en el HTML depende de `G.staff.ojo`.
##
## Sin cobertura, la media de un jugador ajeno no se ve exacta: se ve
## aproximada, con un margen de error que se cierra cuanto mejor lo conozcas
## -tu propia liga, tu red de ojeadores, o pagar el informe individual de
## ese jugador en concreto (`ojear()`, que lo deja en 3/3 para siempre-.
##
## OJO: referencia DEBIL al mundo, mismo motivo que Mercado/Cesiones/Roles -
## Ojeadores no puede sujetar al Mundo o el ciclo de RefCounted no se recoge.
var _ref: WeakRef

signal noticia(titulo: String, cuerpo: String)

const SESGOS := {
	"opt": {"nombre": "Entusiasta", "desc": "Se enamora de los jugadores: sus informes tiran alto", "valor": 3},
	"pes": {"nombre": "Desconfiado", "desc": "No se fía de nadie: siempre pone medio punto menos", "valor": -2},
	"fiel": {"nombre": "Ecuánime", "desc": "Dice lo que ve, sin adornos", "valor": 0},
	"vende": {"nombre": "Vendedor", "desc": "Exagera sus hallazgos para justificar lo que le pagas", "valor": 5},
}
const ESPECIALIDADES := ["juveniles", "delanteros", "defensas", "arqueros", "veteranos", "mediocampo"]
## "MERCADO A CIEGAS" del HTML (v2.0, `G.ajustes.ciego`): con este ajuste
## activado, ni siquiera el rango numérico de un rival se enseña -solo una
## palabra cualitativa, como la vería un ojeador de verdad-. Apaga el número,
## no el sistema: por debajo sigue siendo el mismo `nivel_de()`/`ovr_aproximado()`
## de siempre, con el mismo ruido determinista por jugador.
var modo_ciego: bool = false
## El tercer elemento (descripción) solo lo usa `fichaCiega()` -la ficha
## ciega completa de un rival-, `ovr_palabra()` sigue leyendo solo el [1].
const ESCALA_CIEGA := [
	[90, "Generacional", "Un jugador para una década"],
	[84, "De élite", "Titular en cualquier grande"],
	[78, "Muy bueno", "Marca diferencias en esta liga"],
	[72, "Bueno", "Titular fiable"],
	[66, "Correcto", "Cumple sin destacar"],
	[60, "Justo", "Rotación"],
	[0, "Flojo", "Le queda grande"],
]
## `[0,2,4,6][G.staff.ojo]` del HTML: sin jefe de ojeadores no se cubre ni un
## país.
const MAX_PAISES_POR_NIVEL := [0, 2, 4, 6]
const PRESUPUESTO_INICIAL := 120000
## `[40000,25000,15000,8000][G.staff.ojo]`: cuesta menos pedir un informe
## individual cuanto mejor es tu departamento de ojeo.
const COSTO_INFORME_POR_NIVEL := [40000, 25000, 15000, 8000]

var red: Dictionary = {}         ## pais -> nivel de Staff.ojo al contratarlo
var ojeadores: Dictionary = {}   ## pais -> {nombre, pais, sesgo, precision, espec, informes, ignorados, aciertos, desde, humor}
var presupuesto: int = PRESUPUESTO_INICIAL

func _init(mundo: Mundo) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo

func max_paises() -> int:
	var m := _mundo()
	if m == null or m.staff == null:
		return 0
	return MAX_PAISES_POR_NIVEL[clampi(m.staff.nivel("ojeador"), 0, 3)]

func costo_informe() -> int:
	var m := _mundo()
	var nivel := clampi(m.staff.nivel("ojeador"), 0, 3) if m != null and m.staff != null else 0
	return COSTO_INFORME_POR_NIVEL[nivel]

func cubre(pais: String) -> bool:
	return red.has(pais)

func sesgo_de(pais: String) -> int:
	if not ojeadores.has(pais):
		return 0
	return int(SESGOS.get(String(ojeadores[pais]["sesgo"]), SESGOS["fiel"])["valor"])

func _nombre_al_azar() -> String:
	var n: Array = Datos.tabla("NOMBRES")
	var a: Array = Datos.tabla("APELLIDOS")
	if n == null or a == null or n.is_empty() or a.is_empty():
		return "Ojeador"
	return "%s %s" % [Azar.uno(n), Azar.uno(a)]

func _nuevo_ojeador(pais: String) -> Dictionary:
	var m := _mundo()
	var claves_sin_fiel: Array = SESGOS.keys().filter(func(k): return k != "fiel")
	var sesgo: String = String(Azar.uno(claves_sin_fiel)) if Azar.suerte(0.42) else "fiel"
	return {
		"nombre": _nombre_al_azar(), "pais": pais, "sesgo": sesgo,
		"precision": Azar.ent(1, 3), "espec": String(Azar.uno(ESPECIALIDADES)),
		"informes": 0, "ignorados": 0, "aciertos": 0,
		"desde": m.anio if m != null else 0, "humor": 70,
	}

## Contrata o retira la cobertura de un país -toggleRed() del HTML-. Devuelve
## "" si se hizo, o el motivo por el que no.
func alternar_pais(pais: String) -> String:
	if red.has(pais):
		var o: Dictionary = ojeadores.get(pais, {})
		red.erase(pais)
		ojeadores.erase(pais)
		return ""
	var m := _mundo()
	if m == null or m.staff == null:
		return "Primero contrata un jefe de ojeadores"
	if m.staff.nivel("ojeador") <= 0:
		return "Primero contrata un jefe de ojeadores"
	if red.size() >= max_paises():
		return "Red completa: libera un país para sumar otro"
	red[pais] = m.staff.nivel("ojeador")
	var o := _nuevo_ojeador(pais)
	ojeadores[pais] = o
	var s: Dictionary = SESGOS.get(o["sesgo"], SESGOS["fiel"])
	var nombre_pais := String((Datos.tabla("PAIS_SELECCION") as Dictionary).get(pais, pais))
	noticia.emit("🔎 Nuevo ojeador en %s" % nombre_pais,
		"%s se hace cargo de la zona. Precisión %d/3, especialista en %s. %s: %s. Sus informes van a llegar cada semana; si nunca le haces caso, se acabará yendo." % [
			String(o["nombre"]), int(o["precision"]), String(o["espec"]), String(s["nombre"]), String(s["desc"]).to_lower()])
	return ""

## El humor de cada ojeador baja si se ignoran más informes de los que se usan;
## a cero, renuncia y el país queda sin cubrir hasta que mandes a otro -
## procesoOjeadores() del HTML-.
func procesar_semana() -> void:
	var paises: Array = ojeadores.keys()
	for pais: String in paises:
		var o: Dictionary = ojeadores[pais]
		var ignorados := int(o["ignorados"])
		var informes := int(o["informes"])
		var golpe := -4 if float(ignorados) > float(informes) * 0.7 else 1
		o["humor"] = clampi(int(o["humor"]) + golpe, 0, 100)
		if int(o["humor"]) <= 0:
			ojeadores.erase(pais)
			red.erase(pais)
			noticia.emit("🚪 Renuncia un ojeador",
				"%s, tu hombre en %s, presentó la renuncia. «Llevo %d informes y no fichaste a ninguno», escribió. «Prefiero trabajar donde me lean.» Pierdes la cobertura de ese país hasta que mandes a otro." % [
					String(o["nombre"]), pais, informes])

# ---------------------------------------------------------------------------
#  CUÁNTO SABES DE UN JUGADOR QUE NO ES TUYO
# ---------------------------------------------------------------------------
# `nivelScout()`/`_errScout()`/`ovrNum()`/`ovrTxt()` del HTML: la media de
# cualquiera que no sea tuyo no se ve exacta salvo que lo conozcas bien -tu
# propia liga, tu red de ojeadores, o el informe individual de `ojear()`-.

## 3.0 = conocimiento perfecto (tuyo, o ya ojeado a fondo). Si no, la mezcla de
## "es de tu país" y "tu red lo cubre" -el máximo de los dos, no la suma-.
## Falta el bono de "consejero, director deportivo" del HTML: ese sistema
## (`G.consejeros`) no está portado todavía, así que no hay +0.4 que sumar.
func nivel_de(j: Jugador) -> float:
	var m := _mundo()
	if m == null:
		return 3.0
	## `Mundo.ojeados` -no un campo en Jugador- es el mismo diccionario que ya
	## lee la ficha y el comparador para enseñar o esconder la Proyección: un
	## jugador ojeado se conoce del todo, sea por el sorteo automático de
	## `_informes_de_ojeo()` o por haber pagado `ojear()` aquí.
	if j.club_id == m.mi_club_id or m.ojeados.has(j.id):
		return 3.0
	var suyo: Club = m.clubes.get(j.club_id)
	var mio: Club = m.mi_club()
	var base := 1.5 if (suyo != null and mio != null and suyo.pais == mio.pais) else 0.0
	var cobertura := float(red.get(suyo.pais, 0)) * 0.9 if suyo != null else 0.0
	## El consejero deportivo (`dep`) es "un ojo extra" que afina la niebla en
	## TODO el mundo, no solo en los países cubiertos -por eso se suma al final
	## y no entra en el maxf() de arriba-.
	var bono_consejero := 0.4 if (m.directiva != null and m.directiva.tiene_consejero("dep")) else 0.0
	return maxf(base, cobertura) + bono_consejero

## EL CAZADOR DEL ARBOL AFINA LOS INFORMES. `ojeo_preciso()` estaba escrita y
## no la llamaba nadie: el nodo «Cazador» costaba un punto y los informes salian
## con la misma horquilla de siempre. Con el, el error se parte por la mitad.
func _error_de(nivel: float) -> int:
	var base := _error_bruto(nivel)
	var m := _mundo()
	if base > 0 and m != null and m.entrenamiento != null and m.entrenamiento.ojeo_preciso():
		return maxi(1, int(round(float(base) / 2.0)))
	return base

func _error_bruto(nivel: float) -> int:
	if nivel >= 3.0:
		return 0
	if nivel >= 2.0:
		return 2
	if nivel >= 1.4:
		return 4
	if nivel >= 0.8:
		return 6
	return 9

## La media que se le enseña al jugador: la real si lo conoces bien, si no una
## que se desvía un poco -siempre igual para el mismo jugador, el ruido sale
## de su id, no de un dado nuevo en cada repintado- y con el sesgo del ojeador
## de su país sumado encima.
func ovr_aproximado(j: Jugador) -> int:
	var nivel := nivel_de(j)
	if nivel >= 3.0:
		return j.ovr
	var err := _error_de(nivel)
	var h := 0
	for i in j.id.length():
		h += j.id.unicode_at(i)
	var suyo: Club = _mundo().clubes.get(j.club_id)
	var sesgo := sesgo_de(suyo.pais) if suyo != null else 0
	return clampi(j.ovr + ((h % (err * 2 + 1)) - err) + sesgo, 40, 96)

## "78" si lo conoces bien, o un rango "72-84" si no -o una palabra ("Muy
## bueno") en modo ciego- `ovrTxt()` del HTML.
func ovr_texto(j: Jugador) -> String:
	var nivel := nivel_de(j)
	if nivel >= 3.0:
		return str(j.ovr)
	if modo_ciego:
		return ovr_palabra(j)
	var err := _error_de(nivel)
	var c := ovr_aproximado(j)
	return "%d-%d" % [maxi(40, c - err), mini(96, c + err)]

## La palabra que se ve en modo ciego -`ovrPalabra()` del HTML-: mismo ruido
## determinista que `ovr_aproximado()`, leído en una escala cualitativa en vez
## de un número.
func ovr_palabra(j: Jugador) -> String:
	var c := ovr_aproximado(j)
	for fila: Array in ESCALA_CIEGA:
		if c >= int(fila[0]):
			return String(fila[1])
	return String(ESCALA_CIEGA[-1][1])

## La fila completa (umbral, nombre, descripción) de `ESCALA_CIEGA` para un
## valor de media. `fichaCiega()` del HTML la busca sobre `j.ovr` REAL -no el
## aproximado con ruido-: el ojeador de carne y hueso sabe la verdad, solo la
## cuenta con adjetivos en vez de un número.
func escala_de(valor_ovr: int) -> Array:
	for fila: Array in ESCALA_CIEGA:
		if valor_ovr >= int(fila[0]):
			return fila
	return ESCALA_CIEGA[-1]

## La fiabilidad del informe en palabras -"conf" de `fichaCiega()` del HTML-.
func fiabilidad_de(j: Jugador) -> String:
	var n := clampi(int(nivel_de(j)), 0, 3)
	return ["muy poco fiable", "poco fiable", "razonable", "sólido"][n]

## El informe individual -ojearJug() del HTML-: paga, y a partir de ahí ese
## jugador se ve exacto para siempre. Sale del presupuesto de ojeo, aparte del
## de fichajes; si no alcanza, tira de la caja del club. Devuelve "" si se
## hizo, o el motivo por el que no.
func ojear(j: Jugador) -> String:
	var m := _mundo()
	if m.ojeados.has(j.id):
		return "ya está ojeado"
	var costo := costo_informe()
	var mio := m.mi_club()
	if presupuesto >= costo:
		presupuesto -= costo
	elif mio != null and mio.saldo >= costo:
		mio.mover_saldo(-costo)
	else:
		return "caja insuficiente: hacen falta %d" % costo
	m.ojeados[j.id] = true
	var suyo: Club = m.clubes.get(j.club_id)
	if suyo != null and ojeadores.has(suyo.pais):
		var o: Dictionary = ojeadores[suyo.pais]
		o["informes"] = int(o["informes"]) + 1
	return ""

## LA LISTA DE SEGUIMIENTO (`toggleSeguimiento` del HTML). Marcar a alguien y
## tenerlo todos a la vista. Sin esto, seguir la pista a cuatro objetivos era
## acordarse de sus nombres y buscarlos uno a uno en una tabla de sesenta.
##
## Guarda solo el ID, no el jugador: si se guardara el objeto, un fichaje o un
## retiro dejarían la lista apuntando a alguien que ya no existe.
var seguidos: Dictionary = {}

func sigue(j: Jugador) -> bool:
	return j != null and seguidos.has(j.id)

## Marca o desmarca. Devuelve si queda seguido.
func alternar_seguimiento(j: Jugador) -> bool:
	if j == null:
		return false
	if seguidos.has(j.id):
		seguidos.erase(j.id)
		return false
	seguidos[j.id] = true
	return true

## Los seguidos que SIGUEN existiendo, resueltos a jugador. Los que ya no están
## -se retiraron, o el mundo se regeneró- se limpian aquí: es el único sitio por
## el que pasan todos, así que es donde toca sacar la basura.
func lista_seguimiento() -> Array[Jugador]:
	var m := _mundo()
	var salida: Array[Jugador] = []
	if m == null:
		return salida
	var vivos := {}
	for c: Club in m.clubes.values():
		for j in c.plantilla:
			if seguidos.has(j.id):
				salida.append(j)
				vivos[j.id] = true
	for id: String in seguidos.keys():
		if not vivos.has(id):
			seguidos.erase(id)
	return salida

## EL INFORME DE PERSONALIDAD -informePersonal()/costoInfPers() del HTML-: a
## diferencia del informe de ojeo (media/potencial exactos), este paga por
## saber cómo es un jugador ajeno FUERA de la cancha -profesionalidad, cómo
## encaja en un vestuario, qué tan fácil es convencerlo de mudarse-. Precio
## fijo (7000, escalado a tu reputación) porque el HTML tampoco lo escala al
## valor del jugador como sí hace el informe médico.
var _informes_personalidad: Dictionary = {}   ## id de jugador -> {prof, vestuario, mudanza, anio}

func costo_informe_personalidad(rep_club: int) -> int:
	return Eco.escalar(7000.0, float(rep_club))

func informe_personalidad_de(j: Jugador) -> Dictionary:
	return _informes_personalidad.get(j.id, {}) if j != null else {}

## Encarga el informe. "" si se hizo, o el motivo por el que no. `prof` usa un
## "hambre" fijo de 50 -el HTML lo saca de `j.mente.hambre`, que solo suben los
## orígenes de "garra" (`sortearOrigen()`), un sistema que Godot no tiene
## portado todavía-, así que aquí depende solo de la moral, no de un campo que
## no existe.
func informe_personalidad(j: Jugador, c: Club) -> String:
	if j == null or c == null:
		return "no hay jugador"
	if not informe_personalidad_de(j).is_empty():
		return "ya tienes su informe de personalidad"
	var costo := costo_informe_personalidad(c.rep)
	if c.saldo < costo:
		return "caja insuficiente: cuesta %d" % costo
	c.mover_saldo(-costo)
	var suyo: Club = _mundo().clubes.get(j.club_id)
	var mismo_pais := suyo != null and j.pais == suyo.pais
	_informes_personalidad[j.id] = {
		"prof": clampi(int(round(50.0 * 0.6 + float(j.moral) * 0.4)), 0, 100),
		"vestuario": ("suma en el grupo" if j.rasgo == "lider" else
			("puede incendiar la semana" if j.rasgo == "polemico" else "discreto")),
		"mudanza": ("sin problema, es de casa" if mismo_pais else
			("joven y con ganas de salir" if j.edad <= 23 else "tiene familia asentada: costará convencerlo")),
		"anio": _mundo().anio,
	}
	return ""

func a_dic() -> Dictionary:
	return {"red": red, "ojeadores": ojeadores, "presupuesto": presupuesto, "modo_ciego": modo_ciego,
		"seguidos": seguidos.duplicate(),
		"analitica": analitica_nivel, "tension": analitica_tension, "avisado": analitica_avisado,
		"hallazgos": hallazgos.duplicate(true), "academias": academias.duplicate(),
		"informes_personalidad": _informes_personalidad.duplicate(true)}

func desde_dic(d: Dictionary) -> void:
	red = d.get("red", {})
	ojeadores = d.get("ojeadores", {})
	presupuesto = int(d.get("presupuesto", PRESUPUESTO_INICIAL))
	modo_ciego = bool(d.get("modo_ciego", false))
	seguidos = (d.get("seguidos", {}) as Dictionary).duplicate()
	analitica_nivel = int(d.get("analitica", 0))
	analitica_tension = int(d.get("tension", 0))
	analitica_avisado = bool(d.get("avisado", false))
	hallazgos = (d.get("hallazgos", []) as Array).duplicate(true)
	academias = (d.get("academias", []) as Array).duplicate()
	_informes_personalidad = (d.get("informes_personalidad", {}) as Dictionary).duplicate(true)

# ===========================================================================
#  EL DEPARTAMENTO DE DATOS Y LAS ACADEMIAS (`vOjeo()`)
# ===========================================================================

signal noticia_ojeo(titulo: String, cuerpo: String)
signal movimiento_ojeo(concepto: String, monto: int)

# ---------------------------------------------------------------------------
#  ANÁLISIS DE DATOS: la otra forma de encontrar futbolistas
# ---------------------------------------------------------------------------
#
# El ojeo tradicional te dice lo BUENO que es alguien; el modelo te dice lo
# INFRAVALORADO que está, que no es lo mismo. Cruza minutos, duelos y kilómetros
# y señala chicos que no salen en ningún informe.
#
# Y trae guerra dentro de casa. A partir del nivel dos, con un jefe de ojeadores
# de la vieja escuela, la tensión sube sola hasta que hay que decidir quién manda
# en la sala de fichajes. Eso es lo que lo hace una decisión y no una mejora: no
# es solo dinero, es a quién le das la razón.

const ANALITICA_MAX := 3
const COSTE_ANALITICA := 180000.0
const TENSION_CRITICA := 70

var analitica_nivel: int = 0
var analitica_tension: int = 0
var analitica_avisado: bool = false
var hallazgos: Array = []      ## {pid, nombre, anio, semana}, como mucho ocho

func coste_analitica(c: Club) -> int:
	return Eco.escalar(COSTE_ANALITICA, float(c.rep)) * (analitica_nivel + 1)

func mejorar_analitica(c: Club) -> String:
	if analitica_nivel >= ANALITICA_MAX:
		return "el departamento ya está al máximo"
	var coste := coste_analitica(c)
	if c.saldo < coste:
		return "ampliarlo cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento_ojeo.emit("Departamento de análisis nivel %d" % (analitica_nivel + 1), -coste)
	analitica_nivel += 1
	noticia_ojeo.emit("Crece el departamento de datos",
		"Contrataste más analistas. El modelo propio del club ya cruza minutos, duelos y kilómetros de %d futbolistas. %s" % [
			analitica_nivel * 4000,
			"Tus ojeadores de la vieja escuela miran las pantallas con desconfianza." if analitica_nivel >= 2 \
				else "De momento conviven bien con los ojeadores."])
	return ""

## El pulso semanal del modelo. Cuanto mejor el departamento, más veces encuentra
## a alguien; y cuanto más encuentra, peor se lleva con el ojeo de siempre.
func semana_analitica(nivel_jefe_ojeadores: int) -> void:
	if analitica_nivel <= 0:
		return
	var m := _mundo()
	if m == null or m.mi_club() == null:
		return
	if not Azar.suerte(0.10 * float(analitica_nivel)):
		return
	var mio := m.mi_club()
	var techo_valor := int(Eco.ref_caja(float(mio.rep)) * 0.25)
	var pool: Array[Jugador] = []
	for c: Club in m.clubes.values():
		if c == mio:
			continue
		for j: Jugador in c.plantilla:
			## Joven, con mucho recorrido por delante y barato: exactamente lo
			## que el ojo no ve y los números sí.
			if j.edad <= 24 and j.pot - j.ovr >= 10 and j.valor < techo_valor:
				pool.append(j)
	if pool.is_empty():
		return
	var j: Jugador = pool[Azar.ent(0, pool.size() - 1)]
	hallazgos.append({"pid": j.id, "nombre": j.nombre, "anio": m.anio, "semana": m.semana})
	while hallazgos.size() > 8:
		hallazgos.pop_front()
	var suyo: Club = m.clubes.get(j.club_id)
	noticia_ojeo.emit("El modelo señala un nombre",
		"El departamento de datos destaca a %s (%d años, %s). No aparece en ningún informe de ojeo, pero sus números por noventa minutos están muy por encima de lo que cuesta. El jefe de ojeadores ya dijo en la reunión que «los números no ven la cara del chico cuando va perdiendo»." % [
			j.nombre, j.edad, suyo.nombre if suyo != null else "?"])

	if nivel_jefe_ojeadores >= 2:
		analitica_tension = clampi(analitica_tension + Azar.ent(6, 14), 0, 100)
		if analitica_tension >= TENSION_CRITICA and not analitica_avisado:
			analitica_avisado = true
			noticia_ojeo.emit("Guerra en la sala de fichajes",
				"El jefe de ojeadores y el jefe de analistas se cruzaron a gritos en el pasillo. Uno dice que el modelo ficha planillas de Excel; el otro, que el ojeo es superstición cara. Antes o después hay que decidir quién manda.")

## Los hallazgos que todavía existen, con el jugador resuelto. Un chico fichado
## por otro club o retirado deja de ser un hallazgo aprovechable.
func hallazgos_vivos() -> Array[Dictionary]:
	var m := _mundo()
	var salida: Array[Dictionary] = []
	if m == null:
		return salida
	for h: Dictionary in hallazgos:
		var j := m.jugador_por_id(String(h.get("pid", "")))
		if j == null:
			continue
		salida.append({"jugador": j, "anio": int(h.get("anio", 0)), "semana": int(h.get("semana", 0))})
	salida.reverse()
	return salida

# ---------------------------------------------------------------------------
#  ACADEMIAS INTERNACIONALES
# ---------------------------------------------------------------------------
#
# Una sede en otro país. Cuesta mucho de construir, cuesta todas las semanas, y
# a cambio cada pretemporada llega UNA joya local con proyección de verdad. Es la
# apuesta más larga del juego: la sede que abres hoy da su primer futbolista el
# año que viene y su mejor futbolista dentro de cinco.

const ACADEMIAS_MAX := 3
const COSTE_ACADEMIA := 800000.0
const VENTA_ACADEMIA := 200000.0
const MANTENCION_ACADEMIA := 30000.0

var academias: Array = []    ## códigos de país

func tiene_academia(pais: String) -> bool:
	return academias.has(pais)

func alternar_academia(pais: String, c: Club) -> String:
	if tiene_academia(pais):
		academias.erase(pais)
		var vuelta := Eco.escalar(VENTA_ACADEMIA, float(c.rep))
		c.mover_saldo(vuelta)
		movimiento_ojeo.emit("Venta de sede: academia de %s" % pais, vuelta)
		noticia_ojeo.emit("Academia cerrada",
			"La sede de %s se vende. Los proyectos vuelven a casa." % pais)
		return ""
	if academias.size() >= ACADEMIAS_MAX:
		return "no se pueden tener más de %d academias internacionales" % ACADEMIAS_MAX
	var coste := Eco.escalar(COSTE_ACADEMIA, float(c.rep))
	if c.saldo < coste:
		return "construirla cuesta %s y no hay caja" % Cesiones.dinero(coste)
	c.mover_saldo(-coste)
	movimiento_ojeo.emit("Academia internacional en %s" % pais, -coste)
	academias.append(pais)
	noticia_ojeo.emit("Bandera plantada en %s" % pais,
		"Tu academia abre en %s: cada pretemporada llegará una joya local con proyección de verdad. Mantención: %s a la semana." % [
			pais, Cesiones.dinero(Eco.escalar(MANTENCION_ACADEMIA, float(c.rep)))])
	return ""

func mantencion_academias(c: Club) -> int:
	return Eco.escalar(MANTENCION_ACADEMIA, float(c.rep)) * academias.size()

## Las joyas de la pretemporada: una por sede. Nacen con la media de un juvenil
## normal y con MUCHO más techo -de 12 a 30 puntos-, que es a lo que se le paga.
func joyas_de_academia(c: Club) -> Array[Jugador]:
	var m := _mundo()
	var salida: Array[Jugador] = []
	if m == null or c == null:
		return salida
	for p: String in academias:
		if c.plantilla.size() >= Cantera.TOPE_PLANTEL:
			break
		var grupo := String(Azar.uno(["DEF", "MED", "MED", "DEL"]))
		var j := m.crear_jugador(c, grupo, m.cantera.demarcacion_de(grupo),
			Azar.ent(16, 17), c.rep - 20 + Azar.ent(0, 8))
		j.pot = clampi(j.ovr + Azar.ent(12, 30), j.ovr, 97)
		j.pais = p if Azar.suerte(0.85) else c.pais
		## Y con nombre del sitio: una joya que llega de tu sede en Brasil y se
		## llama como todos los demas no se siente venida de ninguna parte.
		if j.pais != c.pais:
			var ext: Variant = Datos.tabla("NOMBRES_EXT")
			var ape: Variant = Datos.tabla("APELLIDOS_EXT")
			if ext is Array and ape is Array and not (ext as Array).is_empty() and not (ape as Array).is_empty():
				j.nombre = "%s %s" % [String(Azar.uno(ext as Array)), String(Azar.uno(ape as Array))]
		j.generar_atributos()
		j.tasar()
		salida.append(j)
		noticia_ojeo.emit("Joya de la academia de %s" % p,
			"%s (%s, %d años) llega desde tu sede en %s con proyección %d." % [
				j.nombre, j.pos_e, j.edad, p, j.pot])
	return salida
