class_name LeagueAcciones
extends RefCounted
## MÁS VIDA EN EL PARTIDO (11-11-2026, fase 4d; tabla de la sesión 10 en `docs/04_auditorias/anim_acciones_por_momento.md`). Solo la usa
## `MotorLeague` (y C4, que lo hereda): cambia QUÉ clip se ve en un momento, nunca posiciones, velocidades, reglas ni el azar del motor.
##  · FALTA LEVE: el que pierde un choque de hombros no siempre trastabilla igual: una de cada tres veces recibe el golpe en el pecho
##    (`Hit_Chest`, 0,33 s) o en la cabeza (`Hit_Head`, 0,43 s) de la UAL (CC0). El reparto sale del id del jugador y de cuántos
##    golpes lleva (determinista: el mismo partido repite lo mismo).
##  · CELEBRACIÓN DEL GOL (orden del líder, 11-11; acrobacias el 12-11): 2 de cada 5 veces el «celebrar» del motor se sustituye por un
##    baile o una alegría, y 1 de cada 5 por una acrobacia (rueda lateral, voltereta, mortal) de la base CMU (CC, `anims_cmu/cmu_uso.res`; elegidos en
##    `capturas_animaciones_2026-11-11/` y `capturas_partido_visual_2026-11-12/`), recortados a 6 s. Mismo reparto determinista por id.
##  · ENTRADA DE PIE (12-11): la del motor era siempre la misma estocada; ahora, por jugador, también la lateral y la anticipación.
##  · LAMENTO (12-11): 1 de cada 3 lamentos del que encaja es el llanto o la tristeza de CMU.
##  · DISPUTA AÉREA y REACCIÓN AL FALLO (12-11): ver `paso`.
static var activa := OS.get_environment("LS_ACCIONES") != "0"

const BIBLIOTECA_CMU := "res://assets/characters/quaternius/anims_cmu/cmu_uso.res"
const CELEBRACIONES_CMU := ["cmu_60_01", "cmu_60_02", "cmu_60_03", "cmu_60_04", "cmu_79_69", "cmu_79_70", "cmu_80_43", "cmu_93_03", "cmu_93_06"]
## (12-11) Acrobacias: rueda lateral, voltereta y mortal; salen 1 de cada 5 veces en lugar del «celebrar» del motor (con su duración).
const ACROBACIAS_CMU := ["cmu_90_04", "cmu_90_01", "cmu_85_01"]
const LAMENTOS := ["lamento", "manos_cabeza", "cuclillas_lamento", "brazos_jarra"]
const LAMENTOS_CMU := ["cmu_79_72", "cmu_79_71"]
const ENTRADAS_DE_PIE := ["entrada_de_pie", "entrada_lateral_pie", "anticipacion", "entrada_de_pie"]
const MAX_CELEBRACION := 6.0

## El nombre de clip que se reproduce en lugar de `nombre` para el jugador `p` (o el mismo).
static func variante(p: Dictionary, nombre: String) -> String:
	if not activa:
		return nombre
	if nombre == "celebrar":
		return _celebracion(p, nombre)
	if nombre == "entrada_de_pie":
		return _neutra(p, nombre, _de_lista(p, "ls_entradas", ENTRADAS_DE_PIE, nombre))
	if nombre in LAMENTOS:
		var n := int(p.get("ls_lamentos", 0))
		p["ls_lamentos"] = n + 1
		var h := absi(String(p.get("id", "")).hash()) + n
		if h % 3 == 0:
			var clave := _cmu(p, String(LAMENTOS_CMU[(h / 3) % LAMENTOS_CMU.size()]))
			if clave != "":
				return _neutra(p, nombre, clave)
		return nombre
	if not nombre.begins_with("duelo_empujado"):
		return nombre
	var n := int(p.get("ls_golpes", 0))
	p["ls_golpes"] = n + 1
	var turno := (String(p.get("id", "")).hash() + n) % 3
	if turno == 2:
		return nombre
	var clave := "golpe_pecho" if turno == 0 else "golpe_cabeza"
	var ap: AnimationPlayer = p.get("anim")
	var nodo: Node = p.get("node")
	if is_instance_valid(ap) and is_instance_valid(nodo) and AnimExtra.asegurar(ap, FutbolistaQ.esqueleto_de(nodo), clave):
		return clave
	return nombre

## LAS VARIANTES NUEVAS (12-11) NO CAMBIAN EL PARTIDO: el motor lee cuánto dura el gesto (`gesto_hasta`: quién puede moverse,
## entrar o levantarse), así que otro clip de otra duración cambiaba la simulación. Estas dejan anotado el clip que pidió el motor
## y `igualar` (desde `MotorLeague._anim`) escribe la duración de ese, no la del que se ve. (Las de antes, celebración y golpe,
## siguen como estaban.)
static func _neutra(p: Dictionary, pedido: String, visible: String) -> String:
	if visible != pedido:
		p["ls_tiempo_de"] = pedido
	return visible

static func igualar(p: Dictionary, t: float, gesto: bool, dur_max: float) -> void:
	if not p.has("ls_tiempo_de"):
		return
	var pedido := String(p["ls_tiempo_de"])
	p.erase("ls_tiempo_de")
	var ap: AnimationPlayer = p.get("anim")
	if gesto and is_instance_valid(ap) and ap.has_animation(pedido):
		p["gesto_hasta"] = t + minf(ap.get_animation(pedido).length, dur_max)

## Uno de `lista` por jugador y vez (contador `clave_n` en `p`); el que no tenga el AnimationPlayer, el pedido.
static func _de_lista(p: Dictionary, clave_n: String, lista: Array, nombre: String) -> String:
	var n := int(p.get(clave_n, 0))
	p[clave_n] = n + 1
	var elegido := String(lista[(absi(String(p.get("id", "")).hash()) + n) % lista.size()])
	var ap: AnimationPlayer = p.get("anim")
	return elegido if is_instance_valid(ap) and ap.has_animation(elegido) else nombre

## Un baile, una alegría o una acrobacia de CMU para el que celebra (o el mismo «celebrar»).
static func _celebracion(p: Dictionary, nombre: String) -> String:
	var n := int(p.get("ls_celebra", 0))
	p["ls_celebra"] = n + 1
	var h := String(p.get("id", "")).hash() + n
	if h % 5 == 2:
		var acro := _cmu(p, String(ACROBACIAS_CMU[(h / 5) % ACROBACIAS_CMU.size()]))
		return _neutra(p, nombre, acro) if acro != "" else nombre
	if h % 5 >= 2:
		return nombre
	var base := String(CELEBRACIONES_CMU[(h / 5) % CELEBRACIONES_CMU.size()])
	var clave := _cmu(p, base)
	return clave if clave != "" else nombre

## ── CLIP PROPIO: lo que el motor no pone y aquí se ve (salto a disputar, reacción a un fallo) ──────────────────────────────────────
## DISPUTA AÉREA. Los clips de cabezazo ya saltan (la cadera sube 0,3-0,4 m hacia los 0,3 s), pero el motor los arranca en el
## CONTACTO: la cabeza llegaba arriba 0,3 s después de que el balón se fuera y «nadie despegaba». Cuando un balón alto baja hacia la
## altura de un cabezazo en salto y llegará en `PICO` s, el jugador de cada equipo más cercano al punto de caída arranca ya su clip:
## los dos saltan a disputarlo y el que remata lo hace con la cabeza arriba (cuando el motor pide el cabezazo, sigue el que va).
## REACCIÓN AL FALLO. Tras un remate fuera o al palo, el que tiró se lleva las manos a la cabeza o se encoge de hombros (solo si no
## está corriendo: si arranca, la reacción se corta, para que no patine).
## Nada de esto escribe lo que lee la IA (ni posiciones, ni `gesto_hasta` salvo lo que el motor habría escrito, ni su azar).
## `LS_AEREO=0` y `LS_REACCION=0` los apagan.
static var aereo := OS.get_environment("LS_AEREO") != "0"
static var reaccion := OS.get_environment("LS_REACCION") != "0"
const CLIPS_CABEZA := ["cabezazo", "cabezazo_potente", "cabezazo_picado", "pase_cabeza"]
const CLIPS_SALTO := ["cabezazo_potente", "cabezazo", "cabezazo_picado"]
const REACCIONES_FALLO := ["manos_cabeza", "cmu_111_25", "manos_cabeza", "lamento"]
## (12-11, sesión 16) Falta pitada SIN tarjeta: el infractor pide perdón, se pone en jarras o protesta (con tarjeta ya protesta el motor).
const REACCIONES_FALTA := ["pedir_perdon", "brazos_jarra", "protestar", "pedir_perdon"]
## Segundos del clip en que la cabeza está arriba, altura (m) del balón a la que se cabecea en salto y radio de llegada.
const PICO := 0.3
const ALTURA_SALTO := 2.05
const RADIO := 1.4
const ENFRIAR := 1.5
## Reacción: espera tras el remate (s), tope de espera y velocidad (m/s) por encima de la cual no se reacciona (o se corta).
const REAC_RETRASO := 0.45
const REAC_ESPERA := 2.5
const REAC_VEL := 2.6

## Contadores (pruebas y medidas): saltos a disputar, cabezazos con el saltador ya en el aire, reacciones vistas.
static var saltos := 0
static var remates_en_salto := 0
static var reacciones := 0
static var reacciones_falta := 0

## Después de mover a los jugadores (cada paso del motor).
static func paso(m: MotorLeague) -> void:
	if not activa:
		return
	for p: Dictionary in m.jugadores:
		if p.has("ls_propio_hasta"):
			var ap: AnimationPlayer = p.get("anim")
			var corre := String(p.get("ls_propio_tipo", "")) == "reaccion" and (p["vel"] as Vector3).length() > REAC_VEL
			if m.t >= float(p["ls_propio_hasta"]) or not is_instance_valid(ap) or corre:
				_bajar(p)
			else:
				ap.speed_scale = 1.0   ## (el motor la ajusta en cada fotograma a la de su ciclo)
		elif p.has("ls_reac_en") and m.t >= float(p["ls_reac_en"]):
			_quizas_reaccionar(m, p)
	if aereo:
		_disputa_aerea(m)

static func _disputa_aerea(m: MotorLeague) -> void:
	if m.balon == null or not m.poseedor.is_empty() or m.estado != "juego":
		return
	var b := m.balon.position
	var v := m.vel_balon
	if b.y < 1.2 or b.y > 9.0:
		return
	var tc := tiempo_a_altura(b.y, v.y, ALTURA_SALTO, Balance.GRAVEDAD)
	if tc < PICO - 0.06 or tc > PICO + 0.05:
		return
	var donde := Vector2(b.x + v.x * tc, b.z + v.z * tc)
	for local: bool in [true, false]:
		var mejor: Dictionary = {}
		var d_mejor := RADIO
		for p: Dictionary in m.jugadores:
			if bool(p["es_local"]) != local or bool(p["por"]) or p.has("ls_propio_hasta") \
					or float(p.get("ls_aereo_desde", -9.0)) > m.t - ENFRIAR or float(p.get("gesto_hasta", 0.0)) > m.t:
				continue
			var n: Node3D = p.get("node")
			if not is_instance_valid(n):
				continue
			var d := Vector2(n.position.x, n.position.z).distance_to(donde)
			if d < d_mejor:
				d_mejor = d
				mejor = p
		if not mejor.is_empty():
			despegar(m.t, mejor)

## Tiempo (s) hasta que el balón, a `y0` m y subiendo a `vy` m/s, pase BAJANDO por `h` m (-1 si no llega).
static func tiempo_a_altura(y0: float, vy: float, h: float, g: float) -> float:
	var disc := vy * vy + 2.0 * g * (y0 - h)
	if disc < 0.0:
		return -1.0
	return (vy + sqrt(disc)) / g

## Arranca el salto de `p` (su clip de cabezazo, elegido por su id).
static func despegar(t: float, p: Dictionary) -> void:
	p["ls_aereo_desde"] = t
	saltos += 1
	_poner_propio(t, p, String(CLIPS_SALTO[absi(String(p.get("id", "")).hash()) % CLIPS_SALTO.size()]), "aereo")

## Pone `clip` como clip propio de `p` hasta que acabe. Sin cuerpo (pruebas sin gráficos) solo marca el tiempo (~1 s), para contar.
static func _poner_propio(t: float, p: Dictionary, clip: String, tipo: String) -> void:
	var ap: AnimationPlayer = p.get("anim")
	p["ls_propio_clip"] = clip
	p["ls_propio_tipo"] = tipo
	if not is_instance_valid(ap) or not ap.has_animation(clip):
		p["ls_propio_hasta"] = t + 0.95
		return
	ap.play(clip, 0.08 if tipo == "aereo" else 0.2)
	ap.speed_scale = 1.0
	p["ls_propio_hasta"] = t + ap.get_animation(clip).length - 0.05

## Acabó (o se cortó) el clip propio: vuelve el ciclo que el motor tenía puesto.
static func _bajar(p: Dictionary) -> void:
	p.erase("ls_propio_hasta")
	var ap: AnimationPlayer = p.get("anim")
	var ciclo := String(p.get("anim_actual", ""))
	if is_instance_valid(ap):
		ap.play(ciclo if ap.has_animation(ciclo) else "parado", 0.25)

## Para `MotorLeague._anim`: true si `p` lleva un clip propio y lo pedido no debe pisarlo. Un ciclo (correr, trotar…) espera; el
## cabezazo de verdad sigue con el salto que ya va (y el motor queda como si lo hubiera puesto él); otro gesto lo corta.
static func ocupado(p: Dictionary, t: float, nombre: String, gesto: bool, dur_max: float) -> bool:
	if not p.has("ls_propio_hasta"):
		return false
	if not gesto:
		return true
	var ap: AnimationPlayer = p.get("anim")
	var cabeza := nombre.trim_suffix("_espejo") in CLIPS_CABEZA and String(p.get("ls_propio_tipo", "")) == "aereo"
	if cabeza:
		remates_en_salto += 1
	p.erase("ls_propio_hasta")
	if cabeza and is_instance_valid(ap):
		## Lo mismo que habría escrito el motor con su clip (así su estado no cambia: solo qué se ve).
		var largo := ap.get_animation(nombre).length if ap.has_animation(nombre) else ap.current_animation_length
		p["anim_actual"] = String(p.get("ls_propio_clip", nombre))
		p["gesto_hasta"] = t + minf(largo, dur_max)
		return true
	return false

## Señal `remate` del motor: tras un remate fuera o al palo, el que tiró reaccionará en `REAC_RETRASO` s.
static func tras_remate(m: MotorLeague, autor_id: String, tipo: String) -> void:
	if not (activa and reaccion) or not (tipo in ["fallo", "poste"]):
		return
	for p: Dictionary in m.jugadores:
		if String(p.get("id", "")) == autor_id:
			p["ls_reac_en"] = m.t + REAC_RETRASO
			return

## Falta pitada sin tarjeta (`MotorLeague._falta`): el infractor reaccionará en `REAC_RETRASO` s, con las mismas reglas que el fallo
## (no si lleva el balón, si el motor le puso un gesto o si corre; si arranca, se corta). No escribe nada que lea la IA.
static func tras_falta(m: MotorLeague, infractor: Dictionary) -> void:
	if not (activa and reaccion) or infractor.is_empty():
		return
	infractor["ls_reac_en"] = m.t + REAC_RETRASO
	infractor["ls_reac_falta"] = true

static func _quizas_reaccionar(m: MotorLeague, p: Dictionary) -> void:
	if m.t > float(p["ls_reac_en"]) + REAC_ESPERA:
		p.erase("ls_reac_en")
		p.erase("ls_reac_falta")
		return
	if is_same(p, m.poseedor) or float(p.get("gesto_hasta", 0.0)) > m.t or (p["vel"] as Vector3).length() > REAC_VEL:
		return
	p.erase("ls_reac_en")
	var n := int(p.get("ls_reacciones", 0))
	p["ls_reacciones"] = n + 1
	if p.get("ls_reac_falta", false):
		p.erase("ls_reac_falta")
		reacciones_falta += 1
		var clip_f := String(REACCIONES_FALTA[(absi(String(p.get("id", "")).hash()) + n) % REACCIONES_FALTA.size()])
		var ap_f: AnimationPlayer = p.get("anim")
		if is_instance_valid(ap_f) and not ap_f.has_animation(clip_f):
			clip_f = "protestar"
		_poner_propio(m.t, p, clip_f, "reaccion")
		return
	var clip := String(REACCIONES_FALLO[(absi(String(p.get("id", "")).hash()) + n) % REACCIONES_FALLO.size()])
	var ap: AnimationPlayer = p.get("anim")
	if clip.begins_with("cmu_"):
		## Con el juego en marcha no se abre la biblioteca de CMU (3,7 MB: un tirón); si aún no se cargó (la carga la primera
		## celebración), las manos a la cabeza.
		clip = _cmu(p, clip) if ResourceLoader.has_cached(BIBLIOTECA_CMU) else "manos_cabeza"
	elif is_instance_valid(ap) and not ap.has_animation(clip) and is_instance_valid(p.get("node")):
		AnimExtra.asegurar(ap, FutbolistaQ.esqueleto_de(p["node"]), clip)
	reacciones += 1
	_poner_propio(m.t, p, clip if clip != "" else "manos_cabeza", "reaccion")

## Un clip de CMU (`cmu_<id>`) cargado en el AnimationPlayer de `p` como `ext_cmu_<id>` (recortado a `MAX_CELEBRACION`); "" si no hay.
static func _cmu(p: Dictionary, base: String) -> String:
	var clave := "ext_" + base
	var ap: AnimationPlayer = p.get("anim")
	if not is_instance_valid(ap) or not ap.has_animation("correr") or ap.get_animation("correr").get_track_count() == 0:
		return ""
	if ap.has_animation(clave):
		return clave
	var lib := load(BIBLIOTECA_CMU) as AnimationLibrary
	if lib == null or not lib.has_animation(base):
		return ""
	var a: Animation = lib.get_animation(base).duplicate(true)
	var prefijo := String(ap.get_animation("correr").track_get_path(0)).get_slice(":", 0)
	for i in a.get_track_count():
		a.track_set_path(i, NodePath("%s:%s" % [prefijo, str(a.track_get_path(i)).get_slice(":", 1)]))
	a.length = minf(a.length, MAX_CELEBRACION)
	a.loop_mode = Animation.LOOP_NONE
	ap.get_animation_library("").add_animation(clave, a)
	return clave
