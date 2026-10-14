class_name MotorJugable
extends Node
## EL PARTIDO JUGABLE (29-9-2026, mapa de metas 18: Carrera de Jugador). Hasta
## hoy el 3D solo DRAMATIZABA lo que `nucleo/partido.gd` ya había decidido: el
## resultado salía de una simulación y los 22 seguían jugadas prehechas. Aquí
## el partido se JUEGA: el balón tiene física de verdad, los 21 que no manejas
## piensan solos y el resultado sale de lo que pase en el césped.
##
##   BALÓN: vuela con gravedad, arrastre y efecto; rueda frenando; bota; pega
##   en el poste y en el larguero; es gol cuando cruza la línea entre los palos.
##
##   REGLAS: saque de centro, de banda, de esquina y de puerta; faltas, tiros
##   libres y penales (con amarillas); descanso y final.
##
##   LOS NPC: cada equipo mantiene su dibujo y lo mueve con el balón (bloque que
##   bascula y se adelanta con la posesión). Sin balón, el más cercano presiona,
##   el segundo tapa, los demás marcan en su zona. Con balón, el portador valora
##   tirar, pasar (progresión, desmarque, riesgo de la línea) o conducir, y los
##   compañeros se desmarcan SIGUIENDO LAS JUGADAS PREHECHAS del catálogo
##   (`CatalogoJugadas`, ATQ-01..15) como patrón: cada fase dice a qué zona corre
##   cada puesto y a quién conviene pasarla. El portero se coloca entre el balón
##   y el arco, sale a por los balones sueltos del área y se estira si llega.
##
##   TÚ: controlas a UN jugador (tu futbolista) con el mando o el teclado
##   (`Mando`). Con balón: pase, tiro con potencia, centro, pase largo, pase al
##   hueco y regate. Sin balón: presionar, entrada, barrida y pedir el balón. Si
##   te toca lanzar un córner, una falta o un penal, apuntas y cargas la fuerza.
##
## Coordenadas del visor: X = ancho (±34 m), Z = largo (±52,5 m). El local ataca
## hacia +Z (su portero sale en -47, ver `PlayerSpawner.slot_to_position`).

signal gol(es_local: bool, autor: String, asistente: String)
signal aviso(texto: String)
signal cambio_estado(estado: String)
signal terminado
## Un cambio: quién sale, quién entra, de qué equipo (MEGAPLAN fase 3).
signal sustitucion(sale: String, entra: String, es_local: bool)

const LARGO := 52.5
const ANCHO := 34.0
const PALO := 3.66
const LARGUERO := 2.44
const AREA_X := 20.16
const AREA_Z := 16.5
const PUNTO_PENAL := 11.0
const R := 0.11
const G := 9.81
## EL CÉSPED (13-10-2026): con 0,55/s + 1,1 m/s² el balón rodaba como en el
## barro -un pase de 20 m tardaba ~3 s y llegaba muerto- y la sonda medía el
## balón SIN dueño el 88 % del tiempo. Ahora frena como un césped cortado: un
## pase raso de 20 m tarda ~1,5 s y llega a ~11 m/s.
const ROCE_SUELO := 0.18      ## frenado proporcional al rodar (1/s)
const ROCE_FIJO := 0.7        ## frenado constante al rodar (m/s²)
const ARRASTRE := 0.06
const BOTE := 0.55

var jugadores: Array = []
## El trío arbitral (los de `PlayerSpawner.spawn_arbitros`): no juegan, pero se
## mueven con la jugada para que la cancha no tenga tres estatuas.
var arbitros: Array = []
var balon: Node3D
var vel_balon := Vector3.ZERO
var giro_balon := Vector3.ZERO
var usuario: Dictionary = {}
## Sin usuario (o en las pruebas), también tu jugador lo maneja la IA.
var autopiloto := false
var duracion_mitad := 240.0   ## segundos reales por tiempo
var t := 0.0
var mitad := 1
var goles := [0, 0]            ## [local, visita]
var estado := "saque"          ## juego | saque | gol | descanso | fin
var poseedor: Dictionary = {}
var ultimo_toque: Dictionary = {}
var penultimo_toque: Dictionary = {}
var pase_a: Dictionary = {}    ## a quién va el último pase (para correr a recibirlo)
var saque := {}
var apuntando := false         ## el usuario está lanzando una jugada a balón parado
var apunte := {"ang": 0.0, "loft": 0.3, "fuerza": 0.0, "fase": 0.0, "x": 0.0, "y": 0.8}
var cargando := false
var carga := 0.0
var pedido_hasta := 0.0        ## hasta cuándo vale que pediste el balón
var _pase_usuario_vivo := false ## el balón en camino es un pase tuyo
var stats := {"fueras_de_juego": 0, "goles": 0, "asist": 0, "pases": 0, "pases_ok": 0, "tiros": 0, "a_puerta": 0,
	"entradas": 0, "entradas_ok": 0, "toques": 0, "faltas": 0}
var posesion := [0.0, 0.0]
var tiros := [0, 0]
var _rng := RandomNumberGenerator.new()
## FUERA DE JUEGO (MEGAPLAN fase 3): la foto del momento del pase. Quién del
## equipo que patea estaba adelantado; si uno de ellos recibe, se pita.
## {"local": bool, "ids": {id: true}}
var _offside := {}
## CAMBIOS (MEGAPLAN fase 3). `extra` es el jugador que espera en la banda: tú
## si empiezas en el banco (`entra_usuario_min` >= 0) o el suplente de tu
## puesto si empiezas jugando (te pueden sacar). El cambio se hace en el
## primer balón parado desde su minuto, como en el fútbol.
var extra: Dictionary = {}
var entra_usuario_min := -1
var usuario_sustituido := false
var minutos_usuario := 0.0
var _cambio_hecho := false
## El nivel de exigencia del DT para sacarte: con buena relación aguanta más.
var exigencia_dt := 0.5
var prob_cambio_extra := 0.0   ## (para las pruebas: 1 = seguro que te cambia)
var _cambio_decidido := false

var fueras_de_juego := [0, 0]
var _offside_previo := {}
var _ultima_anim := ""
var _jugada := {}             ## la jugada prehecha que guía el ataque del poseedor
var _decision_en := 0.0
var _t_estado := 0.0
var depurar := false

# ---------------------------------------------------------------- modo DT
## EL PARTIDO DEL ENTRENADOR CON ESTE MOTOR (13-10-2026, pedido: «que ya no
## sean solo jugadas predeterminadas, que los cambios de jugadores o tácticas
## puedan cambiar el resultado, y controlar a los jugadores de mi equipo como
## en el vídeo»). Todo esto viene APAGADO: la Carrera de Jugador juega igual que
## antes. `VistaEstadio` lo enciende para el partido del DT.
##
## Un remate terminado (gol aparte): "atajada", "poste" o "fallo".
signal remate(es_local: bool, autor_id: String, tipo: String)
## Una tarjeta de verdad (con `tarjetas_reales`): la segunda amarilla expulsa.
signal tarjeta(jugador_id: String, roja: bool, es_local: bool)
## La pizarra de cada equipo: [local, visita], con "mentalidad" (0-3), "presion",
## "linea", "amplitud" y "ritmo" (0-2). 1 es el término medio y, con todo a 1,
## el motor juega EXACTAMENTE como antes.
var tacticas: Array = [{}, {}]
## El cansancio baja los atributos (un suplente fresco se nota).
var cansancio_real := false
## Las amarillas cuentan y la segunda expulsa (y el equipo juega con uno menos).
var tarjetas_reales := false
## -1: nadie; 0: manejas al local; 1: a la visita. Manejas al que tiene el balón
## o al más cercano, y cambias con `jugar_cambiar` (Q / LB), como en FC.
var control_equipo := -1
## Si se da, el stick se lee respecto a ESTA cámara (la de televisión, de lado):
## arriba en la pantalla es hacia el fondo de la imagen.
var camara: Camera3D = null
var expulsados: Array = []
var corners := [0, 0]
var faltas := [0, 0]
## Pases de cada equipo y cuántos llegaron a un compañero (la precisión que
## enseña la transmisión), y despejes.
var pases := [0, 0]
var pases_ok := [0, 0]
var despejes := [0, 0]
var _pase_eq := -1
var _manual_hasta := 0.0
var _tiro_vivo: Dictionary = {}
var _t_attr := 0.0
var _eligiendo := false
## Cuántas veces se ha pateado el balón: el portero decide UNA vez por disparo.
var _n_patada := 0
## Qué clase de golpeo es el próximo `_patear` (lo fija quien patea).
var _ctx_golpeo := ""
## Lo que dura la celebración antes del saque (el partido del DT la alarga para
## su secuencia de cámaras) y quién marcó.
var duracion_gol := 3.2
var _goleador: Dictionary = {}
var _celebra_anim := "celebrar"

# ---------------------------------------------------------------- montaje

func preparar(lista: Array, ball: Node3D, jugador_usuario_id: String, semilla: int = 1) -> void:
	_rng.seed = semilla
	jugadores = []
	arbitros = []
	for p: Dictionary in lista:
		if bool(p.get("arbitro", false)):
			arbitros.append(p)
			continue
		_preparar_uno(p)
		jugadores.append(p)
		if String(p.get("id", "")) == jugador_usuario_id:
			usuario = p
	balon = ball
	_orientar_formaciones()
	Mando.registrar()
	_saque_de_centro(true)

## CADA EQUIPO EN SU MITAD (13-10-2026). Este motor juega con el local
## defendiendo -Z (`dir_ataque`), pero `PlayerSpawner` coloca las formaciones
## con la convención del visor (`MatchPlayback`): el local defiende +Z. Los dos
## onces salían invertidos -el portero local en +46, su delantero en -34- y en
## cada saque de centro cruzaban el campo entero; la sonda medía además más
## tiros para el que atacaba hacia +Z con el mismo once a los dos lados. Aquí
## se gira 180° la formación del equipo que esté al revés.
func _orientar_formaciones() -> void:
	for local: bool in [true, false]:
		var por_z := 0.0
		var hay := false
		for p: Dictionary in jugadores:
			if bool(p["es_local"]) == local and bool(p["por"]):
				por_z = (p["base_pos"] as Vector3).z
				hay = true
		if not hay or por_z * dir_ataque(local) < 0.0:
			continue
		for p: Dictionary in jugadores:
			if bool(p["es_local"]) != local:
				continue
			var bp: Vector3 = p["base_pos"]
			p["base_pos"] = Vector3(-bp.x, bp.y, -bp.z)
			var n: Node3D = p["node"]
			n.position = Vector3(-n.position.x, n.position.y, -n.position.z)
			n.rotation.y += PI

## EL DESGASTE DEL PARTIDO (MEGAPLAN fase 3): la forma física que queda, de
## 1 a ~0,6 en 90' según el físico, más lo que pese el sprint. NO toca la
## velocidad (eso lo lleva `aguante`, como siempre: cuando el desgaste frenaba
## a todos, los ataques no llegaban y los tiros bajaban de 7-8 a 1-4 por
## partido). Es la barra que ves y lo que mira el DT para cambiarte.
func forma_fisica(p: Dictionary) -> float:
	if p.is_empty():
		return 1.0
	var jugado := clampf((float(mitad - 1) * duracion_mitad + t) / (2.0 * duracion_mitad), 0.0, 1.0)
	var fis := float(p["attr"]["fis"]) if p.has("attr") else 0.6
	var por_tiempo := jugado * 0.42 * (1.3 - fis)
	## Quien entró desde el banco llega fresco: solo cuenta lo que jugó.
	por_tiempo *= clampf(1.0 - float(p.get("entro_en", 0.0)), 0.0, 1.0) if jugado > 0.0 else 1.0
	return clampf(1.0 - por_tiempo - (1.0 - float(p.get("aguante", 1.0))) * 0.5, 0.2, 1.0)

func _preparar_uno(p: Dictionary) -> void:
	var jd: Dictionary = p.get("jugador", {})
	var at: Dictionary = jd.get("atributos", {}) if jd.get("atributos") is Dictionary else {}
	p["attr"] = _atributos(at, int(jd.get("ovr", 60)))
	## La forma y la moral del día (con lo que traiga el jugador): de -4 % a +2 %.
	if jd.has("forma"):
		var dia := 0.94 + 0.0006 * float(jd.get("forma", 60)) + 0.0002 * float(jd.get("moral", 70))
		for k: String in p["attr"]:
			p["attr"][k] = float(p["attr"][k]) * dia
	p["attr_base"] = (p["attr"] as Dictionary).duplicate()
	p["vel"] = Vector3.ZERO
	p["aguante"] = 1.0
	p["enfriar"] = 0.0
	p["regate_hasta"] = 0.0
	p["anim_actual"] = ""
	p["por"] = String(p.get("slot_code", "")) == "POR"

## El que espera en la banda. Si es el usuario, entra en `minuto_entrada`.
func poner_extra(p: Dictionary, es_usuario: bool, minuto_entrada: int = -1) -> void:
	_preparar_uno(p)
	p["por"] = false
	extra = p
	(p["node"] as Node3D).position = Vector3(ANCHO + 2.5, 0, 6.0 if bool(p["es_local"]) else -6.0)
	if es_usuario:
		usuario = {}
		entra_usuario_min = maxi(1, minuto_entrada)

## ¿Toca hacer el cambio en este balón parado?
## `forzar`: sin balón parado desde hace rato, el árbitro para el juego para
## el cambio (con mitades cortas podía pasar media parte sin una interrupción y
## el suplente no entraba nunca).
func _revisar_cambio(forzar := false) -> void:
	if extra.is_empty() or _cambio_hecho:
		return
	var minu := minuto()
	if forzar:
		minu = maxi(minu, 0)
	if entra_usuario_min >= 0:
		if minu >= entra_usuario_min:
			_cambiar(_quien_sale_por(extra), extra, true)
		return
	## Tú en el campo: el DT lo decide UNA vez, en el primer balón parado
	## pasada la hora. Pesa su exigencia, tu nota y tu cansancio.
	if usuario.is_empty() or minu < 60 or _cambio_decidido:
		return
	_cambio_decidido = true
	var prob := 0.05 + exigencia_dt * 0.35 + maxf(0.0, 6.6 - nota_usuario()) * 0.3 \
		+ maxf(0.0, 0.75 - forma_fisica(usuario)) * 1.2 + prob_cambio_extra
	if _rng.randf() < clampf(prob, 0.0, 0.95 + prob_cambio_extra):
		_cambiar(usuario, extra, false)

## El compañero que deja su sitio al que entra: el de su línea más cansado.
func _quien_sale_por(entra: Dictionary) -> Dictionary:
	var grupo := String((entra.get("jugador", {}) as Dictionary).get("pos", "MED"))
	var peor: Dictionary = {}
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != bool(entra["es_local"]) or bool(q["por"]):
			continue
		var g := String((q.get("jugador", {}) as Dictionary).get("pos", ""))
		var nota := forma_fisica(q) + (0.0 if g == grupo else 0.5)
		if peor.is_empty() or nota < float(peor["_nota_cambio"]):
			q["_nota_cambio"] = nota
			peor = q
	return peor

func _cambiar(sale: Dictionary, entra: Dictionary, entra_es_usuario: bool) -> void:
	var i := jugadores.find(sale)
	if i < 0 or entra.is_empty():
		return
	_cambio_hecho = true
	## El que entra hereda el sitio táctico del que sale.
	entra["slot_code"] = sale["slot_code"]
	entra["entro_en"] = clampf((float(mitad - 1) * duracion_mitad + t) / (2.0 * duracion_mitad), 0.0, 1.0)
	entra["base_pos"] = sale["base_pos"]
	(entra["node"] as Node3D).position = Vector3(ANCHO - 0.5, 0, 0)
	(entra["node"] as Node3D).visible = true
	jugadores[i] = entra
	var ns: Node3D = sale["node"]
	ns.position = Vector3(ANCHO + 2.5, 0, 4.0)
	ns.visible = false
	if poseedor == sale:
		poseedor = {}
	if entra_es_usuario:
		usuario = entra
	elif sale == usuario:
		usuario = {}
		usuario_sustituido = true
	extra = {}
	var nom_s := String((sale.get("jugador", {}) as Dictionary).get("nombre", ""))
	var nom_e := String((entra.get("jugador", {}) as Dictionary).get("nombre", ""))
	aviso.emit("🔁 Cambio: entra %s, sale %s" % [nom_e, nom_s])
	sustitucion.emit(nom_s, nom_e, bool(entra["es_local"]))

## Los atributos de 0 a 1, con el CONTRASTE estirado alrededor de 62: con la
## escala tal cual, un once de 72 y uno de 62 rendían casi igual en el césped
## (la sonda: el mejor de la liga ganaba 1 de 5 en casa). Ahora 72 → 0,78 y
## 52 → 0,46, y la calidad se nota en el resultado.
func _atributos(at: Dictionary, ovr: int) -> Dictionary:
	var a := {}
	for k: String in ["rit", "tir", "pas", "reg", "def", "fis", "div", "par", "ref", "pos"]:
		var crudo := float(at.get(k, ovr)) / 100.0
		a[k] = clampf(0.62 + (crudo - 0.62) * 1.6, 0.15, 1.0)
	return a

## La perilla `k` del equipo (1 = término medio).
func _tac(local: bool, k: String) -> int:
	var tc: Dictionary = tacticas[0 if local else 1]
	return int(tc.get(k, 1))

## La pizarra del club traducida al motor. «Ir a por todo» (`riesgo`) sube un
## punto la mentalidad y «cerrar el partido» (`tiempo`) la baja.
static func tactica_desde(tc: Tactica, riesgo := false, tiempo := false) -> Dictionary:
	if tc == null:
		return {}
	var m := tc.mentalidad + (1 if riesgo else 0) - (1 if tiempo else 0)
	return {"mentalidad": clampi(m, 0, 3), "presion": tc.presion, "linea": tc.linea,
		"amplitud": tc.amplitud, "ritmo": tc.ritmo}

## Un cambio en pleno partido: `entra` (un diccionario de `PlayerSpawner`) ocupa
## el sitio táctico de `sale_id` y aparece en la banda, a la altura del medio.
func reemplazar(sale_id: String, entra: Dictionary) -> bool:
	var i := -1
	for k in jugadores.size():
		if String(jugadores[k].get("id", "")) == sale_id:
			i = k
			break
	if i < 0 or entra.is_empty():
		return false
	var sale: Dictionary = jugadores[i]
	_preparar_uno(entra)
	entra["slot_code"] = sale["slot_code"]
	entra["base_pos"] = sale["base_pos"]
	entra["es_local"] = sale["es_local"]
	entra["por"] = sale["por"]
	entra["entro_en"] = clampf((float(mitad - 1) * duracion_mitad + t) / (2.0 * duracion_mitad), 0.0, 1.0)
	var n: Node3D = entra["node"]
	n.position = Vector3(signf(pos(sale).x + 0.01) * (ANCHO - 0.5), 0, clampf(pos(sale).z, -8.0, 8.0))
	n.visible = true
	jugadores[i] = entra
	if poseedor == sale:
		poseedor = {}
	if pase_a == sale:
		pase_a = {}
	if usuario == sale:
		usuario = {}
	return true

## La roja: sale del campo y el equipo sigue con uno menos.
func _expulsar(p: Dictionary) -> void:
	jugadores.erase(p)
	expulsados.append(p)
	var n: Node3D = p["node"]
	n.position = Vector3(ANCHO + 3.0, 0, 0)
	n.visible = false
	if poseedor == p:
		poseedor = {}
	if pase_a == p:
		pase_a = {}
	if usuario == p:
		usuario = {}

## Para reabrir el partido a mitad (tras el descanso): el marcador y el reloj
## del `Partido`, y saque de centro.
func empezar_en(minuto_: int, gl: int, gv: int) -> void:
	goles = [gl, gv]
	if minuto_ >= 45:
		mitad = 2
		t = clampf(float(minuto_ - 45) / 45.0 * duracion_mitad, 0.0, duracion_mitad - 1.0)
		_saque_de_centro(false)
	else:
		t = clampf(float(minuto_) / 45.0 * duracion_mitad, 0.0, duracion_mitad - 1.0)

## El remate en curso termina: atajada, palo o fuera.
func _cerrar_tiro(tipo: String) -> void:
	if _tiro_vivo.is_empty():
		return
	var p: Dictionary = _tiro_vivo["p"]
	_tiro_vivo = {}
	remate.emit(bool(p["es_local"]), String(p.get("id", "")), tipo)

## CONTROL DEL EQUIPO, COMO EN FC: manejas al que lleva el balón; sin balón, al
## que va a recibir el pase o al más cercano a la pelota; `jugar_cambiar` salta
## al siguiente más cercano y durante un momento manda tu elección.
func _control_de_equipo() -> void:
	var mio := control_equipo == 0
	if not poseedor.is_empty() and bool(poseedor["es_local"]) == mio:
		if poseedor != usuario:
			_poner_usuario(poseedor)
		return
	var pedir := Input.is_action_just_pressed("jugar_cambiar")
	if pedir:
		_manual_hasta = t + 1.5
	var cand := _mio_mas_cercano(mio, usuario if pedir else {})
	if cand.is_empty():
		return
	if usuario.is_empty() or pedir:
		_poner_usuario(cand)
		return
	if t < _manual_hasta:
		return
	if not pase_a.is_empty() and bool(pase_a["es_local"]) == mio and pase_a != usuario:
		_poner_usuario(pase_a)
		return
	var b := balon.position
	if cand != usuario and pos(usuario).distance_to(b) - pos(cand).distance_to(b) > 5.0:
		_poner_usuario(cand)

func _poner_usuario(q: Dictionary) -> void:
	usuario = q
	q["manual"] = Vector3.ZERO

func _mio_mas_cercano(local: bool, menos: Dictionary) -> Dictionary:
	var b := balon.position + Vector3(vel_balon.x, 0, vel_balon.z) * 0.3
	var mejor: Dictionary = {}
	var md := 999.0
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != local or q == menos:
			continue
		if bool(q["por"]) and not _en_su_area(q, balon.position):
			continue
		var d := pos(q).distance_to(Vector3(b.x, 0, b.z))
		if d < md:
			md = d
			mejor = q
	return mejor

## El cansancio en los atributos: cada segundo, de 100 % fresco a ~84 % fundido.
func _aplicar_cansancio() -> void:
	for p: Dictionary in jugadores:
		var base: Dictionary = p.get("attr_base", {})
		if base.is_empty():
			continue
		var f := 0.74 + 0.26 * forma_fisica(p)
		for k: String in base:
			if k != "fis":
				p["attr"][k] = float(base[k]) * f

static func dir_ataque(es_local: bool) -> float:
	return 1.0 if es_local else -1.0

func _arco_rival(p: Dictionary) -> Vector3:
	return Vector3(0, 0, LARGO * dir_ataque(bool(p["es_local"])))

func _arco_propio(p: Dictionary) -> Vector3:
	return Vector3(0, 0, -LARGO * dir_ataque(bool(p["es_local"])))

func pos(p: Dictionary) -> Vector3:
	return (p["node"] as Node3D).position

func minuto() -> int:
	return int(t / duracion_mitad * 45.0) + (45 if mitad == 2 else 0)

# ---------------------------------------------------------------- bucle

func _physics_process(delta: float) -> void:
	paso(delta)

## Un paso de simulación. Público para poder correrlo en las pruebas sin
## esperar al reloj.
func paso(delta: float) -> void:
	if estado == "fin":
		return
	_t_estado += delta
	_mover_arbitros(delta)
	match estado:
		"juego":
			t += delta
			if not usuario.is_empty():
				minutos_usuario += delta / duracion_mitad * 45.0
			if not extra.is_empty() and not _cambio_hecho:
				var due := entra_usuario_min if entra_usuario_min >= 0 else 60
				if minuto() >= due + 3:
					_revisar_cambio(true)
			if t >= duracion_mitad:
				_fin_de_mitad()
				return
			if not poseedor.is_empty():
				posesion[0 if bool(poseedor["es_local"]) else 1] += delta
			_mover_balon(delta)
			_disputas(delta)
			if control_equipo >= 0 and not autopiloto:
				_control_de_equipo()
			_ia_equipos(delta)
			_control_usuario(delta)
			if cansancio_real:
				_t_attr -= delta
				if _t_attr <= 0.0:
					_t_attr = 1.0
					_aplicar_cansancio()
			if not _tiro_vivo.is_empty() and t - float(_tiro_vivo["t"]) > 3.5:
				_cerrar_tiro("fallo")
		"saque":
			if _t_estado <= delta * 1.5:
				_revisar_cambio()
			_colocar_saque(delta)
		"gol", "descanso":
			_mover_balon(delta)
			_ia_celebracion(delta)
			if _t_estado > (duracion_gol if estado == "gol" else 3.2):
				if estado == "descanso":
					mitad = 2
					t = 0.0
					_saque_de_centro(false)
				else:
					var saca_local: bool = not bool(saque.get("gol_local", true))
					_saque_de_centro(saca_local)
	_mover_jugadores(delta)
	_actualizar_balon_visual(delta)

func _fin_de_mitad() -> void:
	if mitad == 1:
		estado = "descanso"
		_t_estado = 0.0
		aviso.emit("⏸ Descanso: %d-%d" % goles)
		cambio_estado.emit(estado)
	else:
		estado = "fin"
		aviso.emit("🏁 Final: %d-%d" % goles)
		cambio_estado.emit(estado)
		terminado.emit()

# ---------------------------------------------------------------- balón

func _mover_balon(delta: float) -> void:
	if not poseedor.is_empty():
		## Conducción: el balón va unos palmos por delante, con toques.
		var n: Node3D = poseedor["node"]
		var fwd := Vector3(sin(n.rotation.y), 0, cos(n.rotation.y))
		var sp := (poseedor["vel"] as Vector3).length()
		var toque := 0.45 + minf(sp, 7.0) * 0.07 + 0.08 * sin(t * 9.0)
		var destino := n.position + fwd * toque
		destino.y = R
		var previa := balon.position
		vel_balon = (destino - balon.position) / maxf(delta, 0.001)
		balon.position = destino
		## Conduciendo también se puede meter gol o sacar el balón del campo.
		if estado == "juego":
			_palos_y_lineas(previa)
		return
	var p := balon.position
	var en_aire := p.y > R + 0.02 or vel_balon.y > 0.2
	if en_aire:
		var magnus := giro_balon.cross(vel_balon) * 0.012
		vel_balon += (Vector3(0, -G, 0) + magnus - vel_balon * ARRASTRE) * delta
	else:
		var h := Vector3(vel_balon.x, 0, vel_balon.z)
		var v := h.length()
		if v > 0.0:
			var nv := maxf(0.0, v - (v * ROCE_SUELO + ROCE_FIJO) * delta)
			h = h / v * nv
		vel_balon = Vector3(h.x, 0.0, h.z)
		giro_balon *= 0.97
	var antes := p
	p += vel_balon * delta
	if p.y < R:
		p.y = R
		if vel_balon.y < -1.2:
			vel_balon.y = -vel_balon.y * BOTE
			## El césped se come parte del avance en cada bote.
			vel_balon.x *= 0.72
			vel_balon.z *= 0.72
		else:
			vel_balon.y = 0.0
	## Dentro de la red, el balón se muere.
	if absf(p.z) > LARGO and absf(p.x) < PALO and p.y < LARGUERO:
		vel_balon *= 0.85
		p.z = clampf(p.z, -LARGO - 1.8, LARGO + 1.8)
	balon.position = p
	if estado == "juego":
		_palos_y_lineas(antes)

## Postes, larguero, gol, y fuera del campo.
func _palos_y_lineas(antes: Vector3) -> void:
	var p := balon.position
	for signo: float in [-1.0, 1.0]:
		var linea := LARGO * signo
		## ¿Cruzó la línea de gol en este paso?
		if (antes.z - linea) * (p.z - linea) <= 0.0 and absf(p.z) >= LARGO - 0.001 and signf(p.z) == signo:
			## Poste: el balón pega en el palo si pasa a un radio de él.
			if p.y < LARGUERO + R and absf(absf(p.x) - PALO) < 0.12 + R:
				vel_balon.z = -vel_balon.z * 0.6
				vel_balon.x += signf(p.x) * 1.5
				balon.position.z = linea - signo * 0.2
				aviso.emit("¡AL PALO!")
				_cerrar_tiro("poste")
				return
			if absf(p.x) < PALO and absf(p.y - LARGUERO) < 0.12 + R:
				vel_balon.y = -absf(vel_balon.y) * 0.5
				vel_balon.z = -vel_balon.z * 0.5
				balon.position.z = linea - signo * 0.2
				aviso.emit("¡AL LARGUERO!")
				_cerrar_tiro("poste")
				return
			if absf(p.x) < PALO and p.y < LARGUERO:
				_gol(signo > 0.0)
				return
			## Fuera por la línea de fondo: córner o saque de puerta.
			_cerrar_tiro("fallo")
			var defiende_local := signo < 0.0   ## el local defiende -Z
			var toco_defensor := not ultimo_toque.is_empty() and bool(ultimo_toque["es_local"]) == defiende_local
			if toco_defensor:
				_empezar_saque("corner", not defiende_local, Vector3(signf(p.x) * (ANCHO - 0.3), R, linea - signo * 0.3))
			else:
				_empezar_saque("puerta", defiende_local, Vector3(signf(p.x) * 5.0, R, linea - signo * 5.5))
			return
	if absf(p.x) > ANCHO:
		var local_saca := ultimo_toque.is_empty() or not bool(ultimo_toque["es_local"])
		_empezar_saque("banda", local_saca, Vector3(signf(p.x) * (ANCHO - 0.2), R, clampf(p.z, -LARGO + 1.0, LARGO - 1.0)))

func _gol(en_arco_visita: bool) -> void:
	## El arco de +Z es el de la visita: gol del local.
	var de_local := en_arco_visita
	_tiro_vivo = {}
	goles[0 if de_local else 1] += 1
	var autor := ultimo_toque
	var autor_id := String(autor.get("id", ""))
	var asist_id := ""
	## Gol en contra: el último toque fue de un defensor.
	if not autor.is_empty() and bool(autor["es_local"]) != de_local:
		autor_id = ""
	elif not penultimo_toque.is_empty() and bool(penultimo_toque["es_local"]) == de_local and penultimo_toque != autor:
		asist_id = String(penultimo_toque.get("id", ""))
	if not usuario.is_empty():
		if autor_id == String(usuario["id"]):
			stats["goles"] += 1
		if asist_id == String(usuario["id"]):
			stats["asist"] += 1
	vel_balon *= 0.15
	poseedor = {}
	estado = "gol"
	_t_estado = 0.0
	saque = {"gol_local": de_local}
	gol.emit(de_local, autor_id, asist_id)
	cambio_estado.emit(estado)
	## El goleador celebra según su carácter: primero corre al córner (o a la
	## banda) y allí hace lo suyo; los compañeros llegan a abrazarlo.
	for q: Dictionary in jugadores:
		q["gesto_hasta"] = 0.0
	_goleador = autor if autor_id != "" else {}
	if not autor.is_empty() and autor_id != "":
		var ap: AnimationPlayer = autor.get("anim")
		var jd: Dictionary = autor.get("jugador", {})
		if is_instance_valid(ap):
			_celebra_anim = AnimExtra.celebracion(ap, String(jd.get("rasgo", "")), autor_id, not de_local, _rng)

## Cuánto rueda un balón raso que sale a `v0`: con frenado dv/dt = -(k·v + c),
## x = v0/k - c/k²·ln(1 + k·v0/c).
static func distancia_rodando(v0: float) -> float:
	var k := ROCE_SUELO
	var c := ROCE_FIJO
	return v0 / k - c / (k * k) * log(1.0 + k * v0 / c)

## La velocidad para que un pase raso muera `sobra` metros después del
## destino: el compañero lo recibe en carrera sin que se le pase de largo.
static func velocidad_para(dist: float, sobra := 2.5) -> float:
	var lo := 1.0
	var hi := 40.0
	for _i in 24:
		var mid := (lo + hi) * 0.5
		if distancia_rodando(mid) < dist + sobra:
			lo = mid
		else:
			hi = mid
	return hi

## Patea el balón hacia `destino` con una velocidad horizontal `vh` y la
## parábola que haga falta para llegar ahí (más `loft` de altura extra).
func _patear(p: Dictionary, destino: Vector3, vh: float, loft := 0.0, efecto := 0.0, anim := "pase") -> void:
	_ultima_anim = anim
	_n_patada += 1
	var b := balon.position
	var d := Vector3(destino.x - b.x, 0, destino.z - b.z)
	var dist := maxf(d.length(), 0.1)
	var tv := dist / maxf(vh, 1.0)
	var vy := 0.0
	if loft > 0.0:
		## Envío por arriba: `loft` fija la ALTURA de la parábola y de ahí sale
		## el tiempo de vuelo, para que el balón CAIGA donde se apuntó (antes se
		## sumaba encima de la parábola y los despejes cruzaban el campo).
		var cumbre := maxf(1.5 + loft * 1.8, destino.y - b.y + 1.0)
		vy = sqrt(2.0 * G * cumbre)
		var caida := vy * vy - 2.0 * G * (destino.y - b.y)
		tv = (vy + sqrt(maxf(caida, 0.0))) / G
		vh = dist / maxf(tv, 0.2)
	elif destino.y > R + 0.05:
		vy = ((destino.y - b.y) + 0.5 * G * tv * tv) / tv
	## El arrastre frena: se compensa un poco para que llegue.
	var h := d / dist * vh * (1.0 + ARRASTRE * tv * 0.6)
	if vy <= 0.0:
		h = d / dist * vh
	vel_balon = Vector3(h.x, vy, h.z)
	giro_balon = Vector3(0, efecto, 0)
	if depurar:
		print("PATADA %s(%s) desde %s a %s vh %.1f loft %.1f vel %s" % [String(p.get("slot_code", "")), "L" if bool(p["es_local"]) else "V", str(b), str(destino), vh, loft, str(vel_balon)])
	_foto_offside(p)
	penultimo_toque = ultimo_toque
	ultimo_toque = p
	poseedor = {}
	p["enfriar"] = 0.35
	balon.position.y = maxf(balon.position.y, R + 0.01)
	(p["node"] as Node3D).rotation.y = atan2(d.x, d.z)
	var ap: AnimationPlayer = p.get("anim")
	if is_instance_valid(ap):
		_anim(p, _golpeo_anim(p, ap, anim, destino, b, vh, loft, efecto), true)
	_ctx_golpeo = ""
	if p == usuario:
		stats["toques"] += 1

## EL GESTO QUE TOCA (13-10-2026). Hay 333 animaciones de futbolista y el motor
## usaba un puñado, y los golpeos se sorteaban a ciegas (un pase corto podía
## salir con gesto de rabona). Aquí se elige por la jugada: tiro colocado,
## cañonazo, rosca, de primera, volea o en carrera; pase interior, al pie,
## bombeado, largo, filtrado, atrás o de primera; centro, despeje, saque de
## banda, cabezazo de pase o de remate. Y el zurdo, con la zurda (espejo).
func _golpeo_anim(p: Dictionary, ap: AnimationPlayer, anim: String, destino: Vector3, desde: Vector3, vh: float, loft: float, efecto: float) -> String:
	var d := dir_ataque(bool(p["es_local"]))
	var dist := Vector2(destino.x - desde.x, destino.z - desde.z).length()
	var de_primera := t - float(p.get("tomo_en", -9.0)) < 0.35
	var en_aire := desde.y > 0.45
	var sp := (p["vel"] as Vector3).length()
	var ops: Array = []
	match _ctx_golpeo:
		"tiro":
			if en_aire:
				ops = ["volea", "media_volea"] if desde.y < 1.2 else ["tijera", "chilena"]
			elif de_primera:
				ops = ["tiro_de_primera"]
			elif absf(efecto) > 2.2:
				ops = ["tiro_rosca", "trivela"]
			elif vh > 30.0:
				ops = ["tiro_canonazo", "tiro_empeine", "tiro_seco"]
			elif sp > 5.0:
				ops = ["tiro_carrera"]
			else:
				ops = ["tiro_colocado", "tiro_rastron", "tiro_puntera"]
		"filtrado":
			ops = ["pase_filtrado"]
		"centro":
			ops = ["centro_raso"] if destino.y < 0.6 else (["centro_rosca", "centro"] if absf(efecto) > 3.0 else ["centro"])
		"despeje":
			ops = ["patear", "pase_largo"]
		"banda":
			ops = ["saque_banda"]
		_:
			if anim == "cabezazo":
				ops = ["cabezazo_potente", "cabezazo_picado"] if vh > 15.0 else ["pase_cabeza", "cabezazo"]
			elif en_aire and anim == "pase":
				ops = ["pase_pecho"] if desde.y > 1.0 else ["media_volea"]
			elif anim == "pase":
				var atras := (destino.z - desde.z) * d < -3.0
				if loft > 0.0:
					ops = ["pase_largo", "pase_bombeado"] if dist > 28.0 else ["pase_bombeado"]
				elif de_primera:
					ops = ["pase_primera"]
				elif atras:
					ops = ["pase_atras"]
				elif dist < 13.0:
					ops = ["pase_interior", "pase"]
				elif absf(destino.x - desde.x) > absf(destino.z - desde.z) * 1.6:
					ops = ["pase_lateral", "pase_cruzado"]
				else:
					ops = ["pase_empeine", "pase", "pase_exterior"]
			else:
				ops = [anim]
	var vivos: Array = ops.filter(func(n: String) -> bool: return ap.has_animation(n))
	var nombre := String(vivos[_rng.randi() % vivos.size()]) if not vivos.is_empty() else anim
	if AnimExtra.es_zurdo(String(p.get("id", ""))) and ap.has_animation(nombre + "_espejo"):
		nombre += "_espejo"
	return nombre

## La foto del fuera de juego al patear `p`. En saque de banda, córner y saque
## de puerta no hay fuera de juego (regla 11).
func _foto_offside(p: Dictionary) -> void:
	_offside = {}
	if estado == "saque" and String(saque.get("tipo", "")) in ["banda", "corner", "puerta"]:
		return
	var local := bool(p["es_local"])
	var d := dir_ataque(local)
	## El penúltimo rival (el portero cuenta): la línea del fuera de juego.
	var prof: Array = []
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != local:
			prof.append(pos(q).z * d)
	if prof.size() < 2:
		return
	prof.sort()
	var penultimo: float = prof[prof.size() - 2]
	var balon_prof := balon.position.z * d
	var ids := {}
	for q: Dictionary in jugadores:
		if q == p or bool(q["es_local"]) != local:
			continue
		var z := pos(q).z * d
		## En campo rival, por delante del balón y del penúltimo (con 30 cm de
		## tolerancia: la línea la marca el cuerpo, no los pies).
		if z > 0.0 and z > balon_prof + 0.3 and z > penultimo + 0.3:
			ids[String(q.get("id", ""))] = true
	if not ids.is_empty():
		_offside = {"local": local, "ids": ids, "de": String(p.get("slot_code", "")), "anim": _ultima_anim, "t": t,
			"por": bool(p["por"]), "z": pos(p).z * d}

## ¿`q` está ahora en posición adelantada respecto de un pase de `p`?
func _adelantado(q: Dictionary, p: Dictionary) -> bool:
	var local := bool(q["es_local"])
	var d := dir_ataque(local)
	var z := pos(q).z * d
	if z <= 0.0 or z <= pos(p).z * d + 0.3:
		return false
	var prof: Array = []
	for r: Dictionary in jugadores:
		if bool(r["es_local"]) != local:
			prof.append(pos(r).z * d)
	if prof.size() < 2:
		return false
	prof.sort()
	return z > float(prof[prof.size() - 2]) + 0.3

## ¿El que recibe estaba adelantado en el pase? Pita y saca el rival.
func _pitar_offside(p: Dictionary) -> bool:
	if _offside.is_empty():
		return false
	var mismo := bool(p["es_local"]) == bool(_offside["local"])
	var adelantado := mismo and (_offside["ids"] as Dictionary).has(String(p.get("id", "")))
	_offside_previo = _offside
	_offside = {}
	if not adelantado:
		return false
	if OS.get_environment("DEPURAR_OFF") != "":
		print("OFFSIDE de %s(%s) tras %s de %s (por=%s z=%.1f) hace %.1fs, recibe en z=%.1f" % [String(p.get("slot_code","")), _rol(p),
			String(_offside_previo.get("anim", "")), String(_offside_previo.get("de", "")), str(_offside_previo.get("por", false)),
			float(_offside_previo.get("z", 0.0)), t - float(_offside_previo.get("t", 0.0)), pos(p).z * dir_ataque(bool(p["es_local"]))])
	fueras_de_juego[0 if bool(p["es_local"]) else 1] += 1
	if p == usuario:
		stats["fueras_de_juego"] += 1
	var nombre := String((p.get("jugador", {}) as Dictionary).get("nombre", "un atacante"))
	aviso.emit("🚩 Fuera de juego de %s" % nombre)
	var lugar := pos(p)
	_empezar_saque("falta", not bool(p["es_local"]), Vector3(clampf(lugar.x, -ANCHO + 1.0, ANCHO - 1.0), R,
		clampf(lugar.z, -LARGO + 1.0, LARGO - 1.0)))
	return true

func _tomar(p: Dictionary) -> void:
	if poseedor == p:
		return
	if not _tiro_vivo.is_empty() and _tiro_vivo["p"] != p:
		## Un tiro fuerte que se topa con un defensor no se controla: se
		## desvía (muchas veces a córner), como un bloqueo de verdad.
		var tirador: Dictionary = _tiro_vivo["p"]
		_cerrar_tiro("fallo")
		if bool(tirador["es_local"]) != bool(p["es_local"]) and not bool(p["por"]) and vel_balon.length() > 14.0:
			vel_balon = Vector3(-vel_balon.x * 0.3 + _rng.randf_range(-6, 6), _rng.randf_range(0.5, 3.0), vel_balon.z * _rng.randf_range(0.2, 0.5))
			penultimo_toque = ultimo_toque
			ultimo_toque = p
			p["enfriar"] = 0.5
			return
	if _pase_eq >= 0:
		if (0 if bool(p["es_local"]) else 1) == _pase_eq:
			pases_ok[_pase_eq] += 1
		elif OS.get_environment("DEPURAR_PASES") != "" and not pase_a.is_empty():
			print("PASE PERDIDO: recibía %s a %.1f m del balón; lo cortó %s a %.1f m; balón a %.1f m/s, alto %.1f" % [
				String(pase_a.get("slot_code", "")), pos(pase_a).distance_to(balon.position), String(p.get("slot_code", "")),
				pos(p).distance_to(balon.position), vel_balon.length(), balon.position.y])
		_pase_eq = -1
	if _pitar_offside(p):
		return
	## Tu pase llegó si lo controla uno de los tuyos.
	if _pase_usuario_vivo and not usuario.is_empty() and p != usuario and bool(p["es_local"]) == bool(usuario["es_local"]):
		stats["pases_ok"] += 1
	_pase_usuario_vivo = false
	if poseedor.is_empty() or bool(poseedor["es_local"]) != bool(p["es_local"]):
		_jugada = {}
	penultimo_toque = ultimo_toque if ultimo_toque != p else penultimo_toque
	ultimo_toque = p
	## El control: con el pecho si viene alto, orientado con el pie si viene
	## fuerte y él casi parado; el portero blocando.
	var alto := balon.position.y
	var fuerte := vel_balon.length()
	p["tomo_en"] = t
	if bool(p["por"]):
		_anim(p, "blocaje_alto" if alto > 1.4 else ("blocaje_rasante" if fuerte > 6.0 else "recoger_balon"), true, 0.8)
	elif alto > 0.9:
		_anim(p, "golpe_pecho", true, 0.6)
	elif fuerte > 7.0 and (p["vel"] as Vector3).length() < 2.0:
		_anim(p, "parada_pie", true, 0.6)
	poseedor = p
	pase_a = {}
	vel_balon = Vector3.ZERO
	_decision_en = t + 0.35 + _rng.randf() * 0.4
	if p == usuario:
		stats["toques"] += 1

# ---------------------------------------------------------------- disputas

func _disputas(delta: float) -> void:
	for p: Dictionary in jugadores:
		p["enfriar"] = maxf(0.0, float(p["enfriar"]) - delta)
	var b := balon.position
	if poseedor.is_empty():
		## Balón suelto: lo controla el más cercano que llegue.
		var mejor: Dictionary = {}
		var md := 99.0
		for p: Dictionary in jugadores:
			if float(p["enfriar"]) > 0.0:
				continue
			var d := Vector2(pos(p).x - b.x, pos(p).z - b.z).length()
			var alcance := 1.6 if bool(p["por"]) and _en_su_area(p, b) else 0.9
			## El que espera el pase va al encuentro del balón y se perfila:
			## llega antes que su marca (sin esto la sonda medía 4 de cada 10
			## pases cortados por el defensor que marcaba a 1,6 m).
			var ventaja := 0.0
			if p == pase_a:
				alcance = 1.25
				ventaja = 0.55
			if d < alcance and b.y < (2.4 if bool(p["por"]) and _en_su_area(p, b) else 1.5) and d - ventaja < md:
				md = d - ventaja
				mejor = p
		if not mejor.is_empty():
			var rapido := vel_balon.length()
			## Un balón muy fuerte se escapa si el control es malo.
			var control: float = float(mejor["attr"]["reg"]) * 0.5 + 0.5
			if bool(mejor["por"]):
				control = float(mejor["attr"]["par"]) * 0.6 + 0.35
			if rapido < 14.0 or _rng.randf() < control:
				_tomar(mejor)
			else:
				## Rechace.
				vel_balon = Vector3(-vel_balon.x * 0.3 + _rng.randf_range(-3, 3), 1.5, -vel_balon.z * 0.35)
				penultimo_toque = ultimo_toque
				ultimo_toque = mejor
				mejor["enfriar"] = 0.4
				## Un rechace del rival rompe el fuera de juego (no el de un compañero).
				if not _offside.is_empty() and bool(mejor["es_local"]) != bool(_offside["local"]):
					_offside = {}
		## Cabezazos: balón alto a la altura de la cabeza.
		elif b.y > 1.5 and b.y < 2.4:
			for p: Dictionary in jugadores:
				if float(p["enfriar"]) > 0.0 or bool(p["por"]):
					continue
				if Vector2(pos(p).x - b.x, pos(p).z - b.z).length() < 0.8:
					_cabezazo(p)
					break
		return
	## Con dueño: entradas de los rivales cercanos (la del usuario va aparte).
	## Al portero con el balón en las manos no se le entra.
	if bool(poseedor["por"]):
		return
	for p: Dictionary in jugadores:
		if bool(p["es_local"]) == bool(poseedor["es_local"]) or p == usuario and not autopiloto:
			continue
		if float(p["enfriar"]) > 0.0 or bool(p["por"]):
			continue
		if pos(p).distance_to(pos(poseedor)) < 1.25 + 0.12 * float(_tac(bool(p["es_local"]), "presion") - 1):
			_entrada(p, false)
			break

func _en_su_area(p: Dictionary, b: Vector3) -> bool:
	var arco := _arco_propio(p)
	return absf(b.x) < AREA_X and absf(b.z - arco.z) < AREA_Z

func _cabezazo(p: Dictionary) -> void:
	var arco := _arco_rival(p)
	var cerca := absf(pos(p).z - arco.z) < 18.0
	if cerca:
		var destino := Vector3(_rng.randf_range(-PALO + 0.4, PALO - 0.4), _rng.randf_range(0.3, 2.0), arco.z)
		_patear(p, destino, 14.0 + float(p["attr"]["tir"]) * 6.0, 0.0, 0.0, "cabezazo")
		tiros[0 if bool(p["es_local"]) else 1] += 1
		_tiro_vivo = {"p": p, "t": t}
	else:
		## Despeje o pase de cabeza: a un compañero de delante si lo hay, bajo.
		var fwd := Vector3(_rng.randf_range(-8, 8), 0, dir_ataque(bool(p["es_local"])) * 14.0)
		var q := _companero_cerca(p, pos(p) + fwd)
		var destino := pos(q) if not q.is_empty() and pos(q).distance_to(pos(p)) < 22.0 else pos(p) + fwd
		_patear(p, destino, 10.0, 0.6, 0.0, "cabezazo")
		if not q.is_empty():
			pase_a = q

## Una entrada: quita el balón, o hace falta.
func _entrada(p: Dictionary, barrida: bool) -> void:
	if poseedor.is_empty():
		return
	var victima := poseedor
	p["enfriar"] = 1.0 if not barrida else 1.6
	var def_ := float(p["attr"]["def"])
	var reg := float(victima["attr"]["reg"])
	if t < float(victima["regate_hasta"]):
		reg += 0.35
	## Defensa contra regate al cuadrado: el buen defensor roba bastante más
	## que el malo (antes la proporción lineal igualaba a todos).
	var exito := def_ * def_ / (def_ * def_ + reg * reg) * (0.55 if barrida else 0.32)
	if p == usuario:
		stats["entradas"] += 1
	var de_lado := absf((pos(victima) - pos(p)).normalized().dot(Vector3(sin((p["node"] as Node3D).rotation.y), 0, cos((p["node"] as Node3D).rotation.y)))) < 0.5
	var gesto_e := "entrada_de_pie"
	if barrida:
		gesto_e = ["barrida_lateral", "barrida_corta", "barrida_rapida", "barrida_larga", "falta_barrida"][_rng.randi() % 5]
	elif de_lado:
		gesto_e = "carga_hombro" if _rng.randf() < 0.5 else "entrada_lateral_pie"
	_anim(p, gesto_e, true)
	var r := _rng.randf()
	if r < exito:
		if p == usuario:
			stats["entradas_ok"] += 1
		poseedor = {}
		ultimo_toque = p
		_offside = {}
		vel_balon = (pos(p) - pos(victima)).normalized() * 3.0 + Vector3(_rng.randf_range(-2, 2), 0, 0)
		victima["enfriar"] = 0.6
	elif r < exito + (0.18 if barrida else 0.07):
		_falta(p, victima)

func _falta(infractor: Dictionary, victima: Dictionary) -> void:
	if infractor == usuario:
		stats["faltas"] += 1
	var lugar := pos(victima)
	var atacante_local := bool(victima["es_local"])
	var arco := _arco_rival(victima)
	var en_area := absf(lugar.x) < AREA_X and absf(lugar.z - arco.z) < AREA_Z
	var nombre := String((infractor.get("jugador", {}) as Dictionary).get("nombre", "Un defensor"))
	faltas[0 if bool(infractor["es_local"]) else 1] += 1
	if _rng.randf() < 0.25:
		if tarjetas_reales:
			infractor["amarillas"] = int(infractor.get("amarillas", 0)) + 1
			var roja := int(infractor["amarillas"]) >= 2
			aviso.emit(("🟥 ¡Roja! Segunda amarilla para %s" if roja else "🟨 Amarilla para %s") % nombre)
			tarjeta.emit(String(infractor.get("id", "")), roja, bool(infractor["es_local"]))
			if roja:
				_expulsar(infractor)
		else:
			aviso.emit("🟨 Amarilla para %s" % nombre)
	if en_area:
		aviso.emit("¡PENAL!")
		_empezar_saque("penal", atacante_local, Vector3(0, R, arco.z - signf(arco.z) * PUNTO_PENAL))
	else:
		aviso.emit("Falta de %s" % nombre)
		_empezar_saque("falta", atacante_local, Vector3(lugar.x, R, lugar.z))

# ---------------------------------------------------------------- IA

func _ia_equipos(delta: float) -> void:
	var b := balon.position
	var equipo_con_balon := -1
	if not poseedor.is_empty():
		equipo_con_balon = 0 if bool(poseedor["es_local"]) else 1
	elif not ultimo_toque.is_empty():
		equipo_con_balon = 0 if bool(ultimo_toque["es_local"]) else 1
	## Quién va a por el balón suelto: el más rápido de cada equipo en llegar.
	var persigue := [{}, {}]
	if poseedor.is_empty():
		var destino := b + Vector3(vel_balon.x, 0, vel_balon.z) * 0.35
		## Con un pase en camino, el rival solo sale a cortarlo si llega antes
		## que el receptor al punto donde se recibe (sin esto cortaba cuatro de
		## cada diez pases: el que persigue siempre iba a la línea del balón).
		var recep := _punto_de_recepcion() if not pase_a.is_empty() else Vector3.ZERO
		var d_recep := pos(pase_a).distance_to(recep) if not pase_a.is_empty() else 0.0
		for eq in 2:
			var md := 999.0
			for p: Dictionary in jugadores:
				if (0 if bool(p["es_local"]) else 1) != eq or bool(p["por"]):
					continue
				var d := pos(p).distance_to(Vector3(destino.x, 0, destino.z))
				if not pase_a.is_empty() and bool(pase_a["es_local"]) != bool(p["es_local"]) \
						and pos(p).distance_to(recep) > d_recep * 0.8:
					continue
				if d < md:
					md = d
					persigue[eq] = p
	## La jugada prehecha del equipo que ataca.
	if not poseedor.is_empty():
		_guiar_jugada(delta)
	for p: Dictionary in jugadores:
		if p == usuario and not autopiloto:
			continue
		var eq := 0 if bool(p["es_local"]) else 1
		if bool(p["por"]):
			p["objetivo"] = _ia_portero(p)
			continue
		if p == poseedor:
			_ia_portador(p)
			continue
		if not pase_a.is_empty() and p == pase_a:
			p["objetivo"] = _punto_de_recepcion()
			p["correr"] = true
			continue
		if poseedor.is_empty() and p == persigue[eq]:
			p["objetivo"] = b + Vector3(vel_balon.x, 0, vel_balon.z) * 0.35
			p["correr"] = true
			continue
		if equipo_con_balon == eq:
			p["objetivo"] = _ia_ataque_sin_balon(p)
		else:
			p["objetivo"] = _ia_defensa(p)

## La forma del equipo: la posición de la formación, movida con el balón.
func _forma(p: Dictionary, en_posesion: bool) -> Vector3:
	var base: Vector3 = p["base_pos"]
	var b := balon.position
	var d := dir_ataque(bool(p["es_local"]))
	## La pizarra (con todo a 1, lo de siempre): la línea adelanta o retrasa el
	## bloque, la mentalidad lo empuja y la amplitud abre a los de banda.
	var loc := bool(p["es_local"])
	var lin := float(_tac(loc, "linea") - 1)
	var men := float(_tac(loc, "mentalidad") - 1)
	var amp := float(_tac(loc, "amplitud") - 1)
	var z := base.z * 0.55 + b.z * 0.45 + (d * (9.0 + men * 3.0) if en_posesion else -d * 3.0)
	z += d * (lin * 3.5 + men * 2.0)
	var x := base.x * (0.8 + (amp * 0.12 if en_posesion else 0.0)) + b.x * 0.22
	## Nadie se mete detrás de su propio arco ni más allá del rival.
	z = clampf(z, -LARGO + 4.0, LARGO - 4.0)
	return Vector3(clampf(x, -ANCHO + 2.0, ANCHO - 2.0), 0, z)

func _ia_ataque_sin_balon(p: Dictionary) -> Vector3:
	p["correr"] = false
	## Si la jugada prehecha le da un destino a su puesto, va ahí.
	if not _jugada.is_empty() and bool(_jugada["local"]) == bool(p["es_local"]):
		var dest: Dictionary = _jugada.get("destinos", {})
		var rol := _rol(p)
		if dest.has(rol):
			p["correr"] = true
			## El desmarque de la jugada respeta la línea del fuera de juego
			## mientras el balón no sale (sin esto, 10-13 por partido).
			var dz := dir_ataque(bool(p["es_local"]))
			var linea := _ultima_linea(not bool(p["es_local"]))
			var dd: Vector3 = dest[rol]
			if (dd.z - linea) * dz > -0.5 and (dd.z - balon.position.z) * dz > 0.0:
				dd.z = linea - dz * 0.6
			return dd
	var obj := _forma(p, true)
	## Apoyo: los dos más cercanos al portador se ofrecen en ángulo.
	if not poseedor.is_empty():
		var d := pos(p).distance_to(pos(poseedor))
		if d < 14.0:
			var lado := signf(pos(p).x - pos(poseedor).x)
			if lado == 0.0:
				lado = 1.0
			obj = pos(poseedor) + Vector3(lado * 9.0, 0, dir_ataque(bool(p["es_local"])) * 5.0)
	## Los delanteros atacan el espacio a la espalda de la defensa.
	var linea := _ultima_linea(not bool(p["es_local"]))
	var dz := dir_ataque(bool(p["es_local"]))
	if _rol(p) in ["DC", "ED", "EI", "SD"]:
		obj.z = clampf(linea - dz * 0.6, -LARGO + 6.0, LARGO - 6.0) if (linea - pos(p).z) * dz > -8.0 else obj.z
	## Y NADIE se queda en fuera de juego esperando (MEGAPLAN fase 3): el
	## central que subió al córner o el lateral que se proyectó vuelven a
	## estar habilitados mientras el balón no pase la línea.
	var tope := maxf(linea * dz, balon.position.z * dz) - 0.6
	if obj.z * dz > tope:
		obj.z = tope * dz
	return obj

## La línea del último defensor (sin el portero) del equipo `local`.
func _ultima_linea(local: bool) -> float:
	var d := dir_ataque(local)
	var linea := d * 40.0
	var hay := false
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != local or bool(q["por"]):
			continue
		var z := pos(q).z
		if not hay or (z - linea) * d < 0.0:
			linea = z
			hay = true
	return linea

func _ia_defensa(p: Dictionary) -> Vector3:
	p["correr"] = false
	var b := balon.position
	var arco := _arco_propio(p)
	var cercanos: Array = []
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]) and not (q == usuario and not autopiloto):
			cercanos.append([pos(q).distance_to(b), q])
	cercanos.sort_custom(func(a: Array, c: Array) -> bool: return float(a[0]) < float(c[0]))
	## El más cercano presiona; el segundo cubre entre el balón y el arco.
	## Presión baja: lejos de su área se temporiza; presión alta: van dos.
	var pres := _tac(bool(p["es_local"]), "presion")
	if not cercanos.is_empty() and cercanos[0][1] == p:
		if pres == 0 and b.distance_to(arco) > 42.0 and pos(p).distance_to(b) > 9.0:
			return b + (arco - b).normalized() * 5.0
		p["correr"] = true
		return b + (arco - b).normalized() * 0.8
	if cercanos.size() > 1 and cercanos[1][1] == p:
		if pres == 2:
			p["correr"] = true
			return b + (arco - b).normalized() * 2.5
		return b + (arco - b).normalized() * 7.0
	## Los demás: zona, marcando al rival más cercano.
	var obj := _forma(p, false)
	var rival: Dictionary = {}
	var md := 11.0
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != bool(p["es_local"]) and not bool(q["por"]):
			var d := pos(q).distance_to(obj)
			if d < md:
				md = d
				rival = q
	if not rival.is_empty():
		## Marca a distancia de zona: entre el rival y el arco, a 2,4 m.
		obj = pos(rival) + (arco - pos(rival)).normalized() * 2.4
	return obj

func _ia_portero(p: Dictionary) -> Vector3:
	var b := balon.position
	var arco := _arco_propio(p)
	p["correr"] = false
	if poseedor == p:
		## Sale con el balón: lo pasa a un defensa libre o despeja largo.
		if t > _decision_en + 0.8:
			var mejor := _mejor_pase(p)
			## Salida jugada casi siempre; el pelotazo, menos alto.
			if not mejor.is_empty() and _rng.randf() < 0.8:
				_pasar_a(p, mejor)
			else:
				var lejos := Vector3(_rng.randf_range(-15, 15), 0, dir_ataque(bool(p["es_local"])) * 2.0)
				_patear(p, lejos, 18.0, 3.0, 0.0, "patear")
		return pos(p)
	## Tiro que viene: ¿llega a tapar?
	var hacia := signf(arco.z)
	if poseedor.is_empty() and vel_balon.z * hacia > 6.0:
		var tz := (arco.z - hacia * 0.6 - b.z) / vel_balon.z
		if tz > 0.0 and tz < 1.6:
			var cruce := b + vel_balon * tz
			cruce.y = b.y + vel_balon.y * tz - 0.5 * G * tz * tz
			## UNA decisión por disparo (13-10-2026): antes se tiraba el dado en
			## cada fotograma del vuelo -20 o 30 oportunidades- y el portero lo
			## paraba casi todo (8 de cada 10 en la sonda).
			if absf(cruce.x) < PALO + 0.8 and cruce.y < LARGUERO + 0.4 and int(p.get("_patada_vista", -1)) != _n_patada:
				p["_patada_vista"] = _n_patada
				## Alcance de la estirada: hasta ~3 m con un gran portero, y menos
				## cuanto menos tiempo tiene para reaccionar (antes llegaba a 4 m
				## en cualquier tiro). Arriba, a la escuadra, cuesta más.
				var alcance: float = (1.1 + float(p["attr"]["div"]) * 2.0 + float(p["attr"]["ref"]) * 0.8) * clampf((tz - 0.1) * 2.4, 0.3, 1.0)
				if cruce.y > 1.8:
					alcance *= 0.85
				var lat := absf(cruce.x - pos(p).x)
				if lat < alcance and _rng.randf() < 0.4 + float(p["attr"]["ref"]) * 0.42:
					_parada(p, cruce, lat > 1.2)
					return pos(p)
	## Balón suelto en su área y él llega antes: sale a por él.
	if poseedor.is_empty() and _en_su_area(p, b) and b.y < 2.0:
		var suyo := true
		for q: Dictionary in jugadores:
			if bool(q["es_local"]) != bool(p["es_local"]) and pos(q).distance_to(b) < pos(p).distance_to(b) * 0.8:
				suyo = false
		if suyo:
			p["correr"] = true
			return b
	## Colocación: en la línea balón-arco, más adelantado cuanto más lejos.
	var dist := b.distance_to(arco)
	var sale := clampf(dist * 0.12, 0.8, 5.5)
	var obj := arco + (Vector3(b.x, 0, b.z) - arco).normalized() * sale
	obj.x = clampf(obj.x, -PALO - 1.0, PALO + 1.0)
	return obj

## El portero se estira: atrapa si puede, si no la desvía.
func _parada(p: Dictionary, cruce: Vector3, estirada: bool) -> void:
	_cerrar_tiro("atajada")
	var lado := "izq" if (cruce.x - pos(p).x) * dir_ataque(bool(p["es_local"])) > 0.0 else "der"
	var altura := "baja" if cruce.y < 0.7 else ("media" if cruce.y < 1.6 else "alta")
	var anim := ("estirada_%s_%s" % [altura, lado]) if estirada else ("atajar_bajo" if cruce.y < 0.6 else ("blocaje_alto" if cruce.y > 1.6 else "atajar"))
	_anim(p, anim, true)
	(p["node"] as Node3D).position.x = move_toward(pos(p).x, cruce.x, 1.6 if estirada else 0.8)
	var fuerza := vel_balon.length()
	if not estirada and fuerza < 22.0 and _rng.randf() < float(p["attr"]["par"]) * 0.9:
		_tomar(p)
		balon.position = pos(p) + Vector3(0, 1.0, 0)
		aviso.emit("¡Atajada!")
	else:
		## Rechace: hacia un lado y, la mitad de las veces, por detrás de la
		## línea (córner), como las manos abiertas de un portero de verdad.
		var lado_r := signf(cruce.x - pos(p).x + 0.01)
		if _rng.randf() < 0.5:
			vel_balon = Vector3(lado_r * _rng.randf_range(6, 11), _rng.randf_range(1, 4), vel_balon.z * 0.3)
		else:
			vel_balon = Vector3(lado_r * _rng.randf_range(4, 9), _rng.randf_range(1, 4), -vel_balon.z * 0.25)
		penultimo_toque = ultimo_toque
		ultimo_toque = p
		p["enfriar"] = 0.6
		aviso.emit("¡Qué parada!")

## El que lleva el balón decide: tirar, pasar o conducir.
func _ia_portador(p: Dictionary) -> void:
	var arco := _arco_rival(p)
	var d := dir_ataque(bool(p["es_local"]))
	var yo := pos(p)
	var dist_arco := Vector2(yo.x - arco.x, yo.z - arco.z).length()
	var presion := _presion(p)
	## Conduce hacia el arco, esquivando al rival más cercano.
	var hacia := (arco - yo).normalized()
	if dist_arco > 30.0:
		hacia = Vector3(0, 0, d)
	var rival := _rival_mas_cercano(p)
	if not rival.is_empty() and pos(rival).distance_to(yo) < 4.0:
		var esquiva := (yo - pos(rival)).normalized()
		hacia = (hacia + esquiva * 0.8).normalized()
	p["objetivo"] = yo + hacia * 6.0
	p["correr"] = dist_arco < 35.0 or presion < 4.0
	if t < _decision_en:
		return
	## Conduce algo más antes de decidir (antes se la quitaba de encima en
	## medio segundo: el balón en los pies solo el 24 % del tiempo).
	_decision_en = t + (0.45 + _rng.randf() * 0.45) * (1.0 - 0.15 * float(_tac(bool(p["es_local"]), "ritmo") - 1))
	if OS.get_environment("DEPURAR_PORTADOR") != "" and dist_arco < 40.0:
		print("PORTADOR %s(%s) a %.0f m del arco, x %.0f, presión %.1f" % [String(p.get("slot_code", "")), "L" if bool(p["es_local"]) else "V", dist_arco, yo.x, presion])
	## En su propio campo y apretado: despeje, lejos y hacia fuera si hace falta.
	var en_su_tercio := (arco.z - yo.z) * d > 70.0
	if en_su_tercio and presion < 2.2 and _rng.randf() < 0.55:
		var lado := signf(yo.x) if yo.x != 0.0 else 1.0
		var despeje := Vector3(lado * _rng.randf_range(18, 36), 0, yo.z + d * _rng.randf_range(20, 40))
		_ctx_golpeo = "despeje"
		_patear(p, despeje, 18.0, 4.0, 0.0, "patear")
		despejes[0 if bool(p["es_local"]) else 1] += 1
		return
	## Tirar: cerca y con ángulo.
	var angulo := absf(yo.x) / maxf(absf(arco.z - yo.z), 1.0)
	## Se tira también desde la frontal (hasta ~27 m), como en un partido de
	## verdad; con más pegada, desde más lejos.
	var ganas_tiro := (1.0 - dist_arco / 34.0) * (0.7 + float(p["attr"]["tir"]) * 0.6) - angulo * 0.25
	if dist_arco < 30.0 and ganas_tiro > 0.13 - 0.05 * float(_tac(bool(p["es_local"]), "mentalidad") - 1) + _rng.randf() * 0.24:
		## A un palo, abajo o arriba (antes se apuntaba al azar por el centro
		## y el portero lo paraba casi todo: 27 de 29 en la sonda).
		var palo := (1.0 if _rng.randf() < 0.5 else -1.0) * _rng.randf_range(0.55, 0.95)
		var alto := -0.45 if _rng.randf() < 0.6 else 0.55
		_tirar(p, Vector2(palo, alto), clampf(0.55 + _rng.randf() * 0.4, 0.0, 1.0))
		return
	## Centro desde la banda, cerca del fondo.
	if absf(yo.x) > 17.0 and absf(arco.z - yo.z) < 20.0 and _rng.randf() < 0.55:
		var err_c := (1.0 - float(p["attr"]["pas"])) * 7.0
		var destino := Vector3(_rng.randf_range(-4, 4) + _rng.randf_range(-err_c, err_c), 1.6, arco.z - d * _rng.randf_range(4, 10))
		_ctx_golpeo = "centro"
		_patear(p, destino, 17.0, 0.0, -signf(yo.x) * 6.0, "pase")
		pase_a = _companero_cerca(p, destino)
		return
	## EL REGATE DE LA IA (13-10-2026): con el defensor encima, el que tiene
	## regate intenta irse con una finta (antes solo el jugador humano podía).
	if presion < 1.8 and t > float(p["regate_hasta"]) and _rng.randf() < float(p["attr"]["reg"]) * 0.45:
		p["regate_hasta"] = t + 0.7
		var lado := Vector3(d, 0, 0) * (1.0 if _rng.randf() < 0.5 else -1.0)
		(p["node"] as Node3D).position += lado * 0.8
		## El repertorio crece con el regate: los buenos sacan bicicletas,
		## elásticas, ruletas y caños.
		var reg_a := float(p["attr"]["reg"])
		var fintas := ["regate_finta", "recorte_interior", "recorte_exterior", "amague_cuerpo", "finta_hombro"]
		if reg_a > 0.7:
			fintas.append_array(["bicicleta", "cola_de_vaca", "giro_cruyff", "pisada_lateral"])
		if reg_a > 0.82:
			fintas.append_array(["elastica", "ruleta", "cano", "croqueta", "sombrero"])
		var nom: String = fintas[_rng.randi() % fintas.size()]
		var ap_r: AnimationPlayer = p["anim"]
		if is_instance_valid(ap_r) and lado.x * d < 0.0 and ap_r.has_animation(nom + "_espejo"):
			nom += "_espejo"
		_anim(p, nom, true)
		return
	## EL PASE AL HUECO (13-10-2026). La IA nunca filtraba: los ataques
	## morían a 30 m de la portería tocando atrás (la sonda: 5 tiros en 8
	## minutos). Si un delantero o un extremo habilitado ataca la espalda de la
	## defensa y la línea de pase está limpia, se la mete al espacio; con más
	## pase, más a menudo.
	if dist_arco < 48.0:
		var hueco := _companero_al_hueco(p)
		if not hueco.is_empty() and _rng.randf() < 0.6 + float(p["attr"]["pas"]) * 0.3:
			_pasar_a(p, hueco, false, true)
			return
	## Pasar si hay presión o un compañero mejor situado.
	var mejor := _mejor_pase(p)
	if not mejor.is_empty():
		var hay_prisa := presion < 3.0
		## Cerca del área y con espacio, sigue conduciendo hacia la portería.
		var conduce := dist_arco < 34.0 and presion > 3.0
		if hay_prisa or float(mejor.get("_nota", 0.0)) > 1.5 or (not conduce and _rng.randf() < 0.15):
			_pasar_a(p, mejor)

## Un compañero de ataque, habilitado, cerca de la última línea rival y por
## delante del balón, con el pasillo hacia el espacio a su espalda limpio.
func _companero_al_hueco(p: Dictionary) -> Dictionary:
	var local := bool(p["es_local"])
	var d := dir_ataque(local)
	var linea := _ultima_linea(not local)
	var yo := pos(p)
	var mejor: Dictionary = {}
	var mejor_nota := 0.0
	for q: Dictionary in jugadores:
		if q == p or bool(q["es_local"]) != local or bool(q["por"]):
			continue
		if not _rol(q) in ["DC", "ED", "EI", "MC"]:
			continue
		var qp := pos(q)
		var adelante := (qp.z - yo.z) * d
		if adelante < 4.0 or absf(qp.z - linea) > 7.0 or _adelantado(q, p):
			continue
		var espacio := qp + Vector3(0, 0, d * 7.0)
		espacio.z = clampf(espacio.z, -LARGO + 4.0, LARGO - 4.0)
		if _linea_tapada(yo, espacio, local):
			continue
		var nota := adelante - absf(qp.x) * 0.15
		if nota > mejor_nota:
			mejor_nota = nota
			mejor = q
	return mejor

func _presion(p: Dictionary) -> float:
	var r := _rival_mas_cercano(p)
	return pos(r).distance_to(pos(p)) if not r.is_empty() else 99.0

func _rival_mas_cercano(p: Dictionary) -> Dictionary:
	var mejor: Dictionary = {}
	var md := 999.0
	for q: Dictionary in jugadores:
		if bool(q["es_local"]) != bool(p["es_local"]):
			var d := pos(q).distance_to(pos(p))
			if d < md:
				md = d
				mejor = q
	return mejor

func _companero_cerca(p: Dictionary, punto: Vector3) -> Dictionary:
	var mejor: Dictionary = {}
	var md := 999.0
	for q: Dictionary in jugadores:
		if q != p and bool(q["es_local"]) == bool(p["es_local"]) and not bool(q["por"]):
			var d := pos(q).distance_to(punto)
			if d < md:
				md = d
				mejor = q
	return mejor

## El mejor pase: progresión hacia el arco, compañero libre y línea limpia.
## Bonificaciones: el destinatario que marca la jugada prehecha, y tú si
## pediste el balón.
func _mejor_pase(p: Dictionary) -> Dictionary:
	var yo := pos(p)
	var d := dir_ataque(bool(p["es_local"]))
	var mejor: Dictionary = {}
	var mejor_nota := -99.0
	for q: Dictionary in jugadores:
		if q == p or bool(q["es_local"]) != bool(p["es_local"]) or bool(q["por"]):
			continue
		var qp := pos(q)
		var dist := qp.distance_to(yo)
		if dist < 4.0 or dist > 42.0:
			continue
		var progreso := (qp.z - yo.z) * d
		var libre := 99.0
		var riesgo := 0.0
		for r: Dictionary in jugadores:
			if bool(r["es_local"]) == bool(p["es_local"]):
				continue
			libre = minf(libre, pos(r).distance_to(qp))
			var cerca := Geometry3D.get_closest_point_to_segment(pos(r), yo, qp)
			var dl := cerca.distance_to(pos(r))
			if dl < 2.2:
				riesgo += (2.2 - dl) * 1.4
		var nota := progreso * (0.08 + 0.025 * float(_tac(bool(p["es_local"]), "mentalidad") - 1) + 0.015 * float(_tac(bool(p["es_local"]), "ritmo") - 1)) \
			+ minf(libre, 10.0) * 0.18 - riesgo - dist * 0.02
		## Un buen pasador ve el fuera de juego: con más visión (pase) casi
		## nunca se la da a un compañero adelantado.
		if _adelantado(q, p) and _rng.randf() < 0.55 + float(p["attr"]["pas"]) * 0.4:
			nota -= 6.0
		if not _jugada.is_empty() and String(_jugada.get("pase_a", "")) == _rol(q):
			nota += 1.2
		if q == usuario and t < pedido_hasta:
			nota += 2.5
		## Visión de juego: con poco pase se elige peor (ruido en la nota).
		nota += _rng.randf_range(-1.0, 1.0) * (1.0 - float(p["attr"]["pas"])) * 3.0
		if nota > mejor_nota:
			mejor_nota = nota
			mejor = q
	if not mejor.is_empty():
		mejor["_nota"] = mejor_nota
	return mejor

func _pasar_a(p: Dictionary, q: Dictionary, largo := false, al_hueco := false) -> void:
	var destino := pos(q)
	var dist := destino.distance_to(pos(p))
	## Se le pasa adelantado, a donde va a estar.
	var guia := (q["vel"] as Vector3) * clampf(dist / 18.0, 0.2, 1.0)
	if al_hueco:
		guia += Vector3(0, 0, dir_ataque(bool(q["es_local"])) * 7.0)
	destino += guia
	## Nadie pasa perfecto: el error crece con la distancia, con la presión y
	## cuanto peor es el pase del que la toca.
	var error := (1.0 - float(p["attr"]["pas"])) * dist * 0.22 + (1.2 if _presion(p) < 2.0 else 0.0) * (1.4 - float(p["attr"]["pas"]))
	destino += Vector3(_rng.randf_range(-error, error), 0, _rng.randf_range(-error, error))
	## POR ABAJO SIEMPRE QUE SE PUEDA (13-10-2026): con «cualquier rival cerca
	## de la línea = por arriba» la sonda medía el balón en el aire el 64 % del
	## tiempo (pelotazo y cabezazo). Ahora por arriba solo el envío largo o el
	## que está tapado y lejos, y a media altura.
	_ctx_golpeo = "filtrado" if al_hueco else ""
	var elevado := largo or dist > 32.0 or (dist > 15.0 and _linea_tapada(pos(p), destino, bool(p["es_local"])))
	if elevado:
		## Envío por arriba: vuela despacio y cae cerca del compañero.
		_patear(p, destino, clampf(dist * 0.45 + 6.0, 10.0, 19.0), 0.9 if dist < 25.0 else 2.0, 0.0, "pase")
	else:
		## Con pace: el balón llega al compañero con fuerza, no muriéndose.
		_patear(p, destino, clampf(velocidad_para(dist, 2.5 + dist * 1.2), 6.0, 26.0), 0.0, 0.0, "pase")
	pase_a = q
	_pase_eq = 0 if bool(p["es_local"]) else 1
	pases[_pase_eq] += 1
	if p == usuario:
		stats["pases"] += 1
		_pase_usuario_vivo = true

func _linea_tapada(a: Vector3, c: Vector3, local: bool) -> bool:
	for r: Dictionary in jugadores:
		if bool(r["es_local"]) == local:
			continue
		var cerca := Geometry3D.get_closest_point_to_segment(pos(r), a, c)
		if cerca.distance_to(pos(r)) < 1.3:
			return true
	return false

## Dónde conviene recibir el pase que va en camino.
func _punto_de_recepcion() -> Vector3:
	var b := balon.position
	var v := Vector3(vel_balon.x, 0, vel_balon.z)
	var sp := v.length()
	if sp < 1.0:
		return b
	## Dónde para (o por dónde pasa en un segundo).
	var t_para := minf(sp / (ROCE_SUELO * sp + ROCE_FIJO + 0.01), 1.2)
	return Vector3(b.x, 0, b.z) + v * t_para * 0.6

## Un tiro al arco rival. `apunte.x` ∈ [-1, 1] mueve el objetivo de palo a
## palo; `fuerza` ∈ [0, 1] es la carga. Mucha fuerza sin técnica se va alta.
func _tirar(p: Dictionary, apunte_: Vector2, fuerza: float) -> void:
	var arco := _arco_rival(p)
	var tec := float(p["attr"]["tir"])
	## El error crece con la distancia: desde 25 m se falla mucho más que
	## dentro del área (la sonda medía 8 de cada 10 tiros entre los palos).
	var lejos := Vector2(pos(p).x - arco.x, pos(p).z - arco.z).length()
	var error := ((1.0 - tec) * 2.6 + maxf(0.0, fuerza - 0.8) * 2.5) * (0.55 + lejos / 26.0)
	var x := clampf(apunte_.x, -1.0, 1.0) * (PALO - 0.35) + _rng.randf_range(-error, error)
	var y := clampf(0.35 + fuerza * 1.2 + apunte_.y * 0.6 + _rng.randf_range(-error, error) * 0.6, 0.15, 3.4)
	var destino := Vector3(x, y, arco.z + signf(arco.z) * 0.3)
	var vh := 16.0 + fuerza * 14.0 + tec * 4.0
	_ctx_golpeo = "tiro"
	_patear(p, destino, vh, 0.0, _rng.randf_range(-3, 3), "patear")
	tiros[0 if bool(p["es_local"]) else 1] += 1
	_tiro_vivo = {"p": p, "t": t}
	if OS.get_environment("DEPURAR_TIROS") != "":
		print("TIRO de %s a %.0f m, destino x %.1f y %.1f, vh %.0f, error %.2f" % [String(p.get("slot_code", "")),
			pos(p).distance_to(arco), x, y, vh, error])
	if p == usuario:
		stats["tiros"] += 1
		if absf(x) < PALO and y < LARGUERO:
			stats["a_puerta"] += 1

func _rol(p: Dictionary) -> String:
	var s := String(p.get("slot_code", ""))
	match s:
		"DC", "SD", "DEL": return "DC"
		"ED", "MD": return "ED"
		"EI", "MI": return "EI"
		"MC", "MCO", "MCD": return "MC"
		"LD", "CAD": return "LD"
		"LI", "CAI": return "LI"
		"DFC": return "DFC"
	return s

## LAS JUGADAS PREHECHAS COMO GUÍA. Cuando un equipo tiene el balón en campo
## rival, elige una del catálogo y sus fases le dicen a cada puesto adónde
## desmarcarse y a quién conviene pasarla. El catálogo está escrito para un
## ataque hacia -Z; para el que ataca hacia +Z se da la vuelta.
func _guiar_jugada(delta: float) -> void:
	var local := bool(poseedor["es_local"])
	var d := dir_ataque(local)
	var en_campo_rival := balon.position.z * d > -5.0
	if _jugada.is_empty():
		if not en_campo_rival:
			return
		var id: String = CatalogoJugadas.IDS_ATQ[_rng.randi() % CatalogoJugadas.IDS_ATQ.size()]
		var def := CatalogoJugadas.obtener_definicion(id)
		var fases: Array = def.get("fases", [])
		if fases.is_empty():
			return
		_jugada = {"id": id, "local": local, "fases": fases, "i": 0, "t": 0.0}
		_aplicar_fase()
		return
	_jugada["t"] = float(_jugada["t"]) + delta
	var fase: Dictionary = (_jugada["fases"] as Array)[int(_jugada["i"])]
	if float(_jugada["t"]) > float(fase.get("duracion", 1.0)) * 1.8:
		_jugada["i"] = int(_jugada["i"]) + 1
		_jugada["t"] = 0.0
		if int(_jugada["i"]) >= (_jugada["fases"] as Array).size():
			_jugada = {}
			return
		_aplicar_fase()

func _aplicar_fase() -> void:
	var fase: Dictionary = (_jugada["fases"] as Array)[int(_jugada["i"])]
	var d := dir_ataque(bool(_jugada["local"]))
	var dest := {}
	var fd: Dictionary = fase.get("destinos", {})
	for rol: String in fd:
		var v: Vector3 = fd[rol]
		## Catálogo: ataque hacia -Z. Para atacar hacia +Z, espejo completo.
		dest[rol] = Vector3(-v.x * d, 0, -v.z * d) if d > 0.0 else v
	_jugada["destinos"] = dest
	_jugada["pase_a"] = String(fase.get("pase_a", ""))

func _ia_celebracion(_delta: float) -> void:
	var g := _goleador
	var hay := estado == "gol" and not g.is_empty() and jugadores.has(g)
	var esquina := Vector3.ZERO
	if hay:
		var gp := pos(g)
		esquina = Vector3(signf(gp.x + 0.01) * (ANCHO - 2.5), 0, clampf(gp.z, -LARGO + 3.0, LARGO - 3.0) * 0.85)
	for p: Dictionary in jugadores:
		if p == usuario and not autopiloto:
			continue
		if hay and p == g:
			var lejos := pos(p).distance_to(esquina)
			p["objetivo"] = esquina
			p["correr"] = lejos > 1.5
			if lejos <= 1.5 and float(p.get("gesto_hasta", 0.0)) <= t:
				## Llegó: su celebración (y se queda en ella).
				_anim(p, _celebra_anim, true, 99.0)
			continue
		if hay and bool(p["es_local"]) == bool(g["es_local"]) and not bool(p["por"]) and _t_estado > 0.8 \
				and pos(p).distance_to(pos(g)) < 34.0:
			## A abrazarlo: alrededor de él, sin meterse encima.
			var lado := Vector3(sin(float(absi(String(p.get("id", "")).hash()) % 628) / 100.0), 0,
				cos(float(absi(String(p.get("id", "")).hash()) % 628) / 100.0))
			p["objetivo"] = pos(g) + lado * 1.0
			p["correr"] = true
			if pos(p).distance_to(pos(g)) < 1.7 and float(p.get("gesto_hasta", 0.0)) <= t:
				_anim(p, "celebrar" if _rng.randf() < 0.5 else "aplauso_arriba", true, 99.0)
			continue
		p["objetivo"] = _forma(p, false)
		p["correr"] = false
		## El que encajó: lamento.
		if hay and bool(p["es_local"]) != bool(g["es_local"]) and _t_estado < 0.1:
			if _rng.randf() < 0.4:
				_anim(p, ["lamento", "manos_cabeza", "cuclillas_lamento", "brazos_jarra"][_rng.randi() % 4], true, 99.0)

# ---------------------------------------------------------------- balón parado

func _empezar_saque(tipo: String, saca_local: bool, lugar: Vector3) -> void:
	estado = "saque"
	_t_estado = 0.0
	poseedor = {}
	pase_a = {}
	_jugada = {}
	vel_balon = Vector3.ZERO
	balon.position = lugar
	var lanzador := _elegir_lanzador(tipo, saca_local, lugar)
	saque = {"tipo": tipo, "local": saca_local, "lugar": lugar, "lanzador": lanzador}
	if tipo == "corner":
		corners[0 if saca_local else 1] += 1
	apuntando = false
	cargando = false
	if tipo != "centro":
		aviso.emit({"banda": "Saque de banda", "corner": "Córner", "puerta": "Saque de puerta",
			"falta": "Tiro libre", "penal": "Penal"}.get(tipo, tipo))
	cambio_estado.emit("saque_" + tipo)

func _saque_de_centro(saca_local: bool) -> void:
	_goleador = {}
	for p: Dictionary in jugadores:
		(p["node"] as Node3D).position = p["base_pos"]
		p["vel"] = Vector3.ZERO
		p["gesto_hasta"] = 0.0
	_empezar_saque("centro", saca_local, Vector3(0, R, 0))

## Quién lo lanza. El usuario, si es de su equipo y le toca: los córners y las
## faltas si es lanzador (o el más cercano en las bandas), y los penales si se
## hizo cargo de ellos.
var lanza_usuario := {"corner": true, "falta": true, "penal": true, "banda": false}

func _elegir_lanzador(tipo: String, saca_local: bool, lugar: Vector3) -> Dictionary:
	## Con el equipo en tus manos, el lanzador lo elige la IA y lo manejas tú.
	if control_equipo >= 0 and not autopiloto and not _eligiendo and (control_equipo == 0) == saca_local \
			and bool(lanza_usuario.get(tipo, false)):
		var guardado := usuario
		usuario = {}
		_eligiendo = true
		var m := _elegir_lanzador(tipo, saca_local, lugar)
		_eligiendo = false
		usuario = guardado
		if not m.is_empty():
			_poner_usuario(m)
			return m
	if not usuario.is_empty() and not autopiloto and bool(usuario["es_local"]) == saca_local \
			and bool(lanza_usuario.get(tipo, false)):
		return usuario
	var mejor: Dictionary = {}
	var md := 999.0
	for p: Dictionary in jugadores:
		if bool(p["es_local"]) != saca_local:
			continue
		if tipo == "puerta":
			if bool(p["por"]):
				return p
			continue
		if bool(p["por"]):
			continue
		var d := pos(p).distance_to(lugar)
		if tipo in ["penal", "falta"]:
			d -= float(p["attr"]["tir"]) * 40.0
		if d < md:
			md = d
			mejor = p
	return mejor

## Coloca a todos para el saque y, cuando están, lo ejecuta (o espera al
## usuario si lanza él).
func _colocar_saque(delta: float) -> void:
	var tipo := String(saque.get("tipo", "centro"))
	var lugar: Vector3 = saque["lugar"]
	var lanzador: Dictionary = saque.get("lanzador", {})
	var saca_local := bool(saque["local"])
	for p: Dictionary in jugadores:
		var obj: Vector3
		if p == lanzador:
			var atras := (lugar - _arco_rival(p)).normalized() if tipo != "banda" else Vector3(signf(lugar.x), 0, 0)
			obj = lugar + atras * 0.6
		elif tipo == "centro":
			obj = p["base_pos"]
		elif tipo == "penal":
			obj = _fuera_del_area(p)
			if bool(p["por"]) and bool(p["es_local"]) != saca_local:
				obj = _arco_propio(p) + Vector3(0, 0, dir_ataque(bool(p["es_local"])) * 0.3)
		elif tipo in ["corner", "falta"]:
			obj = _pos_balon_parado(p, lugar, saca_local)
		else:
			obj = _forma(p, bool(p["es_local"]) == saca_local)
		if bool(p["por"]) and tipo != "puerta" and not (tipo == "penal"):
			obj = _ia_portero_saque(p)
		p["objetivo"] = obj
		p["correr"] = true
		## Se colocan rápido (en los saques el juego está parado).
		var n: Node3D = p["node"]
		if _t_estado < 0.1:
			pass
		n.position = n.position.move_toward(obj, 14.0 * delta)
	if lanzador.is_empty():
		_reanudar()
		return
	if lanzador == usuario and not autopiloto:
		if not apuntando and _t_estado > 0.8:
			apuntando = true
			apunte = {"ang": 0.0, "loft": 0.35 if tipo == "corner" else 0.15, "fuerza": 0.0, "fase": 0.0, "x": 0.0, "y": 0.8}
			cambio_estado.emit("apuntar_" + tipo)
		if apuntando:
			_apuntar_usuario(delta)
		return
	if _t_estado > (1.4 if tipo != "centro" else 1.0):
		_ejecutar_saque_ia(lanzador, tipo, lugar)

func _ia_portero_saque(p: Dictionary) -> Vector3:
	var arco := _arco_propio(p)
	return arco + Vector3(0, 0, dir_ataque(bool(p["es_local"])) * 0.8)

func _fuera_del_area(p: Dictionary) -> Vector3:
	var o := _forma(p, false)
	var lugar: Vector3 = saque["lugar"]
	var arco_z := signf(lugar.z) * LARGO
	if absf(o.z - arco_z) < AREA_Z + 1.0:
		o.z = arco_z - signf(arco_z) * (AREA_Z + 2.0)
	return o

## Córner y falta: los que atacan entran al área (primer palo, segundo palo,
## punto de penal, frontal) y los que defienden los marcan; en las faltas
## cercanas, cuatro hacen barrera a 9,15 m.
func _pos_balon_parado(p: Dictionary, lugar: Vector3, saca_local: bool) -> Vector3:
	var ataca := bool(p["es_local"]) == saca_local
	var arco_z := LARGO * dir_ataque(saca_local)
	var zonas := [Vector3(-2.5, 0, arco_z - signf(arco_z) * 5.0), Vector3(3.0, 0, arco_z - signf(arco_z) * 6.5),
		Vector3(0, 0, arco_z - signf(arco_z) * 11.0), Vector3(-6.0, 0, arco_z - signf(arco_z) * 9.0),
		Vector3(6.5, 0, arco_z - signf(arco_z) * 10.0), Vector3(0, 0, arco_z - signf(arco_z) * 18.0)]
	var i := absi(String(p.get("id", "")).hash()) % zonas.size()
	if ataca:
		if _rol(p) in ["DFC", "DC", "ED", "EI", "MC"]:
			return zonas[i]
		return _forma(p, true)
	## Defensores: barrera en las faltas cercanas.
	var dist_arco := Vector2(lugar.x, lugar.z - arco_z).length()
	if String(saque["tipo"]) == "falta" and dist_arco < 32.0 and _rol(p) in ["DC", "ED", "EI", "MC"]:
		var hacia := (Vector3(0, 0, arco_z) - lugar).normalized()
		var lado := Vector3(hacia.z, 0, -hacia.x)
		var k := float(i % 4) - 1.5
		return lugar + hacia * 9.15 + lado * k * 0.7
	return zonas[i] + Vector3(0.8, 0, 0)

func _ejecutar_saque_ia(p: Dictionary, tipo: String, lugar: Vector3) -> void:
	var arco := _arco_rival(p)
	match tipo:
		"corner":
			var destino := Vector3(_rng.randf_range(-3, 4), 1.7, arco.z - signf(arco.z) * _rng.randf_range(5, 9))
			_ctx_golpeo = "centro"
			_patear(p, destino, 18.0, 0.0, -signf(lugar.x) * 8.0, "pase")
			pase_a = _companero_cerca(p, destino)
		"penal":
			_tirar(p, Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-0.3, 0.4)), 0.7)
		"falta":
			var dist := Vector2(lugar.x - arco.x, lugar.z - arco.z).length()
			if dist < 30.0:
				_tirar(p, Vector2(_rng.randf_range(-0.9, 0.9), 0.5), 0.75)
			else:
				var mejor := _mejor_pase(p)
				if not mejor.is_empty():
					_pasar_a(p, mejor, dist > 35.0)
				else:
					_patear(p, arco * 0.7, 20.0, 4.0)
		"puerta":
			## Saque de puerta: en corto a un central si está libre; si no, a
			## media cancha, para que lo peleen.
			var corto := _mejor_pase(p)
			if not corto.is_empty() and pos(corto).distance_to(pos(p)) < 30.0 and _rng.randf() < 0.6:
				_pasar_a(p, corto)
			else:
				var lejos := Vector3(_rng.randf_range(-16, 16), 0, dir_ataque(bool(p["es_local"])) * 3.0)
				_patear(p, lejos, 19.0, 3.5, 0.0, "patear")
		_:
			var m := _mejor_pase(p)
			if not m.is_empty():
				_pasar_a(p, m)
				if tipo == "banda":
					_anim(p, AnimExtra.variante(p["anim"], "saque_banda", String(p.get("id", "")), _rng), true)
			else:
				_patear(p, pos(p) + Vector3(0, 0, dir_ataque(bool(p["es_local"])) * 8.0), 10.0)
	_reanudar()

func _reanudar() -> void:
	estado = "juego"
	_t_estado = 0.0
	apuntando = false
	cambio_estado.emit("juego")

# ---------------------------------------------------------------- tú

## Lanzar tú: el stick mueve la dirección (córner/falta) o el punto del arco
## (penal); arriba/abajo la altura; mantener TIRO carga la fuerza y soltar
## patea. PASE lanza a ras, sin cargar.
func _apuntar_usuario(delta: float) -> void:
	var tipo := String(saque["tipo"])
	var mv := Mando.movimiento()
	if tipo == "penal":
		apunte["x"] = clampf(float(apunte["x"]) + mv.x * delta * 1.4, -1.0, 1.0)
		apunte["y"] = clampf(float(apunte["y"]) - mv.y * delta * 1.2, 0.0, 1.0)
	else:
		apunte["ang"] = clampf(float(apunte["ang"]) + mv.x * delta * 1.2, -1.2, 1.2)
		apunte["loft"] = clampf(float(apunte["loft"]) - mv.y * delta * 0.8, 0.0, 1.0)
	if Input.is_action_pressed("jugar_tiro"):
		apunte["fuerza"] = minf(1.0, float(apunte["fuerza"]) + delta * 0.9)
		cargando = true
	elif cargando:
		cargando = false
		_lanzar_usuario(float(apunte["fuerza"]))
	elif Input.is_action_just_pressed("jugar_pase"):
		_lanzar_usuario(0.45)

## La dirección de apunte en el campo (para la flecha de la interfaz).
func direccion_apunte() -> Vector3:
	var lugar: Vector3 = saque.get("lugar", Vector3.ZERO)
	var arco := _arco_rival(usuario) if not usuario.is_empty() else Vector3.ZERO
	var base := (arco - lugar).normalized()
	return base.rotated(Vector3.UP, -float(apunte["ang"]))

func _lanzar_usuario(fuerza: float) -> void:
	var p := usuario
	var tipo := String(saque["tipo"])
	var lugar: Vector3 = saque["lugar"]
	if tipo == "penal":
		_tirar(p, Vector2(float(apunte["x"]) * dir_ataque(bool(p["es_local"])) * -1.0, float(apunte["y"]) - 0.4), fuerza)
	else:
		var dir := direccion_apunte()
		var dist := 12.0 + fuerza * 38.0
		var destino := lugar + dir * dist
		destino.y = float(apunte["loft"]) * 2.0
		var loft := float(apunte["loft"]) * 7.0
		_patear(p, destino, 12.0 + fuerza * 18.0, loft, (float(apunte["ang"]) * -10.0), "patear" if fuerza > 0.6 else "pase")
		if tipo == "falta" and Vector2(lugar.x, lugar.z - _arco_rival(p).z).length() < 32.0:
			tiros[0 if bool(p["es_local"]) else 1] += 1
			stats["tiros"] += 1
		pase_a = _companero_cerca(p, destino)
	_reanudar()

## Los controles durante el juego.
func _control_usuario(delta: float) -> void:
	if usuario.is_empty() or autopiloto:
		return
	var p := usuario
	var n: Node3D = p["node"]
	var d := dir_ataque(bool(p["es_local"]))
	var mv := Mando.movimiento()
	## Con la cámara detrás del jugador mirando al arco rival: arriba en la
	## pantalla es hacia el arco, la derecha de la pantalla es -X al atacar +Z.
	var mundo := Vector3(-mv.x * d, 0, -mv.y * d)
	if camara != null and is_instance_valid(camara):
		var f := -camara.global_basis.z
		f.y = 0.0
		var r := camara.global_basis.x
		r.y = 0.0
		if f.length() > 0.01 and r.length() > 0.01:
			mundo = r.normalized() * mv.x + f.normalized() * (-mv.y)
	var sprint := Input.is_action_pressed("jugar_sprint")
	p["correr"] = sprint
	if mundo.length() > 0.1:
		p["objetivo"] = pos(p) + mundo.normalized() * 3.0
		p["manual"] = mundo.normalized()
	else:
		p["objetivo"] = pos(p)
		p["manual"] = Vector3.ZERO
	var con_balon := poseedor == p
	if con_balon:
		if Input.is_action_just_pressed("jugar_pase"):
			var q := _companero_en_direccion(p, mundo if mundo.length() > 0.1 else Vector3(sin(n.rotation.y), 0, cos(n.rotation.y)))
			if not q.is_empty():
				_pasar_a(p, q)
		elif Input.is_action_just_pressed("jugar_filtrado"):
			var q2 := _companero_en_direccion(p, mundo if mundo.length() > 0.1 else Vector3(0, 0, d))
			if not q2.is_empty():
				_pasar_a(p, q2, false, true)
		elif Input.is_action_just_pressed("jugar_pase_largo"):
			var q3 := _companero_en_direccion(p, mundo if mundo.length() > 0.1 else Vector3(0, 0, d))
			if not q3.is_empty():
				_pasar_a(p, q3, true)
		elif Input.is_action_just_pressed("jugar_centro"):
			var arco := _arco_rival(p)
			var destino := Vector3(_rng.randf_range(-3, 3), 1.6, arco.z - d * 7.0)
			_ctx_golpeo = "centro"
			_patear(p, destino, 17.0, 0.0, -signf(pos(p).x) * 6.0, "pase")
			pase_a = _companero_cerca(p, destino)
			stats["pases"] += 1
			_pase_usuario_vivo = true
		elif Input.is_action_just_pressed("jugar_regate"):
			p["regate_hasta"] = t + 0.7
			var lado := Vector3(d, 0, 0) * (1.0 if _rng.randf() < 0.5 else -1.0)
			n.position += lado * 0.9
			_anim(p, AnimExtra.variante(p["anim"], "regate_finta", String(p["id"]), _rng), true)
		if Input.is_action_pressed("jugar_tiro"):
			carga = minf(1.0, carga + delta * 1.1)
			cargando = true
		elif cargando:
			cargando = false
			_tirar(p, Vector2(-mv.x * d, -mv.y * 0.5), carga)
			carga = 0.0
	else:
		cargando = false
		carga = 0.0
		if Input.is_action_pressed("jugar_pase") and not poseedor.is_empty() and bool(poseedor["es_local"]) != bool(p["es_local"]):
			## Presionar: ir a por el portador.
			p["objetivo"] = pos(poseedor)
			p["correr"] = true
		if Input.is_action_just_pressed("jugar_tiro") and float(p["enfriar"]) <= 0.0:
			if not poseedor.is_empty() and bool(poseedor["es_local"]) != bool(p["es_local"]) and pos(poseedor).distance_to(pos(p)) < 1.8:
				_entrada(p, false)
			elif poseedor.is_empty() and balon.position.distance_to(pos(p)) < 1.6:
				## Despeje / remate de primera.
				var arco2 := _arco_rival(p)
				if absf(arco2.z - pos(p).z) < 25.0:
					_tirar(p, Vector2(0, 0), 0.8)
				else:
					_patear(p, pos(p) + Vector3(0, 0, d * 25.0), 22.0, 4.0, 0.0, "patear")
		if Input.is_action_just_pressed("jugar_centro") and float(p["enfriar"]) <= 0.0:
			## Barrida: más alcance, más riesgo.
			if not poseedor.is_empty() and bool(poseedor["es_local"]) != bool(p["es_local"]) and pos(poseedor).distance_to(pos(p)) < 3.0:
				n.position = n.position.move_toward(pos(poseedor), 1.6)
				_entrada(p, true)
			else:
				_anim(p, "falta_barrida", true)
				p["enfriar"] = 1.2
		if Input.is_action_just_pressed("jugar_pedir"):
			pedido_hasta = t + 2.5
			aviso.emit("🙋 ¡Pide el balón!")
			_anim(p, "pedir_balon", true)

func _companero_en_direccion(p: Dictionary, dir: Vector3) -> Dictionary:
	var mejor: Dictionary = {}
	var mejor_nota := -99.0
	var yo := pos(p)
	for q: Dictionary in jugadores:
		if q == p or bool(q["es_local"]) != bool(p["es_local"]) or bool(q["por"]):
			continue
		var v := pos(q) - yo
		var dist := v.length()
		if dist < 3.0 or dist > 45.0:
			continue
		var alineado := v.normalized().dot(dir.normalized())
		var nota := alineado * 3.0 - dist * 0.03
		if nota > mejor_nota:
			mejor_nota = nota
			mejor = q
	return mejor

# ---------------------------------------------------------------- movimiento

func _mover_jugadores(delta: float) -> void:
	for p: Dictionary in jugadores:
		var n: Node3D = p["node"]
		if not is_instance_valid(n) or not p.has("objetivo"):
			continue
		var obj: Vector3 = p["objetivo"]
		obj.y = 0.0
		var dif := obj - Vector3(n.position.x, 0, n.position.z)
		var dist := dif.length()
		var rit := float(p["attr"]["rit"])
		## La velocidad pesa más (13-10-2026): de ~6,7 m/s a ~8,3 m/s según el ritmo.
		var tope := (4.4 + rit * 4.2) * (1.0 if bool(p.get("correr", false)) else 0.62) * (0.7 + 0.3 * float(p["aguante"]))
		if poseedor == p:
			tope *= 0.88
		var deseada := Vector3.ZERO
		if dist > 0.25:
			deseada = dif / dist * minf(tope, dist * 2.5)
		var vel: Vector3 = p["vel"]
		vel = vel.move_toward(deseada, 9.0 * delta)
		p["vel"] = vel
		n.position += vel * delta
		n.position.x = clampf(n.position.x, -ANCHO - 2.0, ANCHO + 2.0)
		n.position.z = clampf(n.position.z, -LARGO - 2.0, LARGO + 2.0)
		var sp := vel.length()
		## RECORRER HACIA ATRÁS (13-10-2026): el defensa que se repliega cerca
		## de la jugada no da la espalda al balón; retrocede mirándolo.
		var hacia_b := balon.position - n.position
		hacia_b.y = 0.0
		var atras := false
		if sp > 0.5 and sp < 4.2 and poseedor != p and not bool(p["por"]) and hacia_b.length() < 18.0 \
				and not poseedor.is_empty() and bool(poseedor["es_local"]) != bool(p["es_local"]) \
				and vel.normalized().dot(hacia_b.normalized()) < -0.35:
			atras = true
			n.rotation.y = rotate_toward(n.rotation.y, atan2(hacia_b.x, hacia_b.z), 7.0 * delta)
		elif sp > 0.4:
			n.rotation.y = rotate_toward(n.rotation.y, atan2(vel.x, vel.z), 9.0 * delta)
		elif poseedor != p:
			var hacia := balon.position - n.position
			n.rotation.y = rotate_toward(n.rotation.y, atan2(hacia.x, hacia.z), 4.0 * delta)
		## Aguante: el sprint cansa, andar recupera.
		if bool(p.get("correr", false)) and sp > 5.0:
			## Presionar arriba cansa: el equipo de presión alta se funde antes
			## (el precio de la pizarra ofensiva, que se nota con el cansancio real).
			var coste := 1.0 + 0.35 * float(_tac(bool(p["es_local"]), "presion") - 1) + 0.15 * float(_tac(bool(p["es_local"]), "ritmo") - 1)
			p["aguante"] = maxf(0.2, float(p["aguante"]) - delta * 0.012 * (1.4 - float(p["attr"]["fis"])) * coste)
		else:
			p["aguante"] = minf(1.0, float(p["aguante"]) + delta * 0.006)

		## La animación según la velocidad (salvo que haya un gesto en curso).
		if float(p.get("gesto_hasta", 0.0)) > t:
			continue
		var anim := "parado" if sp < 0.5 else ("trotar" if sp < 5.2 else "correr")
		## Con el balón en los pies se conduce (no se trota); el portero espera
		## en guardia; el que está fundido se nota parado.
		if poseedor == p and sp >= 0.5 and sp < 6.5:
			anim = "conducir"
		elif atras:
			anim = "trotar_atras"
		elif sp < 0.5 and bool(p["por"]) and hacia_b.length() < 32.0:
			anim = "portero_listo"
		elif sp < 0.5 and cansancio_real and forma_fisica(p) < 0.6:
			anim = "cansado"
		_anim(p, anim, false)
		var ap: AnimationPlayer = p.get("anim")
		if is_instance_valid(ap):
			var ciclo := {"trotar": 3.4, "correr": 7.0, "conducir": 3.6, "trotar_atras": 2.6}
			ap.speed_scale = clampf(sp / float(ciclo[anim]), 0.7, 1.4) if ciclo.has(anim) else 1.0

## EL ÁRBITRO SIGUE LA JUGADA (29-9-2026). El principal va en diagonal, unos
## metros por detrás y a un lado del balón, sin meterse en la línea de pase;
## los asistentes corren su banda a la altura del balón, cada uno en su mitad.
func _mover_arbitros(delta: float) -> void:
	if balon == null:
		return
	var b := balon.position
	for a: Dictionary in arbitros:
		var n: Node3D = a.get("node")
		if not is_instance_valid(n):
			continue
		var obj: Vector3
		match String(a.get("id", "")):
			"arbitro":
				obj = Vector3(clampf(b.x - 9.0 * signf(b.x + 0.01), -26.0, 26.0), 0, clampf(b.z - 6.0, -40.0, 40.0))
			"linea_a":
				obj = Vector3(-36.5, 0, clampf(b.z, -50.0, 0.0))
			_:
				obj = Vector3(36.5, 0, clampf(b.z, 0.0, 50.0))
		var hacia := obj - n.position
		hacia.y = 0.0
		var v := minf(hacia.length() * 1.6, 6.5)
		var sp := 0.0
		if hacia.length() > 0.4:
			n.position += hacia.normalized() * v * delta
			sp = v
		## Siempre de cara al juego.
		var mira := b - n.position
		mira.y = 0.0
		if mira.length() > 0.5:
			n.rotation.y = lerp_angle(n.rotation.y, atan2(mira.x, mira.z), clampf(delta * 5.0, 0.0, 1.0))
		_anim(a, "parado" if sp < 0.5 else ("trotar" if sp < 4.5 else "correr"), false)

func _anim(p: Dictionary, nombre: String, gesto: bool, dur_max := 1.4) -> void:
	var ap: AnimationPlayer = p.get("anim")
	if not is_instance_valid(ap) or not ap.has_animation(nombre):
		return
	if gesto:
		ap.play(nombre, 0.1)
		ap.speed_scale = 1.0
		p["gesto_hasta"] = t + minf(ap.get_animation(nombre).length, dur_max)
		p["anim_actual"] = nombre
	elif String(p.get("anim_actual", "")) != nombre:
		ap.play(nombre, 0.2)
		p["anim_actual"] = nombre

## Gira el balón según lo que rueda (como `Balon3D`).
var _ultima_pos_balon := Vector3.ZERO
func _actualizar_balon_visual(_delta: float) -> void:
	if balon == null:
		return
	var p := balon.position
	var despl := Vector2(p.x - _ultima_pos_balon.x, p.z - _ultima_pos_balon.z)
	if despl.length_squared() > 0.000001 and despl.length() < 3.0:
		var eje := Vector3(despl.y, 0.0, -despl.x).normalized()
		balon.global_rotate(eje, despl.length() / R)
	_ultima_pos_balon = p

# ---------------------------------------------------------------- resumen

## La nota de tu partido, como la de los diarios: 6 de base.
func nota_usuario() -> float:
	var s := stats
	var n := 6.0 + float(s["goles"]) * 1.0 + float(s["asist"]) * 0.6 + float(s["pases_ok"]) * 0.03 \
		- float(maxi(0, int(s["pases"]) - int(s["pases_ok"]))) * 0.05 + float(s["a_puerta"]) * 0.12 \
		+ float(s["entradas_ok"]) * 0.12 - float(s["faltas"]) * 0.1
	if not usuario.is_empty():
		var mio := 0 if bool(usuario["es_local"]) else 1
		n += 0.3 if goles[mio] > goles[1 - mio] else (-0.3 if goles[mio] < goles[1 - mio] else 0.0)
	return clampf(snappedf(n, 0.1), 3.0, 10.0)

func posesion_local() -> int:
	var tot: float = float(posesion[0]) + float(posesion[1])
	return int(round(posesion[0] / tot * 100.0)) if tot > 0.0 else 50
