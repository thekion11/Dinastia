class_name LeagueLocomocion
extends RefCounted
## LA LOCOMOCIÓN VISUAL DE LEAGUE-SOCCER EN EL PARTIDO (10-11-2026, fase 4c de `docs/04_auditorias/MOTOR_LEAGUE_SOCCER_PLAN.md`).
## Solo la usa `MotorLeague` (bandera MOTOR_LEAGUE=1); solo cambia lo que se VE, nunca posiciones, velocidades, el giro del nodo
## (del que dependen alcances y entradas) ni `gesto_hasta`:
##  · el portador conduce con los ciclos con balón del original (`LeagueAnim.CICLOS_CONDUCIR`);
##  · los demás, al arrancar, frenar, girar fuerte o cambiar hacia dónde miran, hacen el clip que elige el original
##    (`LeagueMovimiento.elegir`). Miran hacia el balón como en el original (`LeagueMovimiento.mirada`), así que a veces corren
##    con el CUERPO girado 45° o 135° respecto a la marcha (las «angled»), con el ciclo estable de las plantillas del original.
##    El giro del cuerpo que trae cada clip se compensa en el MODELO (hijo raíz del AnimationPlayer) para no sumarse al del nodo;
##    al acabar, la compensación deja el cuerpo donde lo dejó el clip y se apaga en ~0,1 s (sin saltos).
##    `LS_LOCO=0` apaga las transiciones; `LS_ANGLED=0`, solo el cuerpo girado.

static var transiciones_activas := OS.get_environment("LS_LOCO") != "0"
static var angled := OS.get_environment("LS_ANGLED") != "0"
const GIRO_MIN := 0.6          ## ~35°: por debajo, nuestro giro continuo basta (el original elige 0° o ±20°: paso estable)
const ESPERA := 0.2
## Cada cuánto se revisa a cada jugador (s). El original solo elige otro clip al acabar el que lleva (~0,24 s): revisar cada 0,1
## (escalonado entre los 22) basta y cuesta un tercio.
const CADENCIA := 0.1
const CICLOS := ["parado", "trotar", "correr"]
const CONDUCIR := ["conducir", "correr", "trotar", "conducir_ls", "conducir_ls_rapido"]
const CICLO_CUERPO := "ls_ciclo__"
const RECOLOCAR := 12.0   ## 1/s: la compensación que sobra al acabar un clip se apaga en ~0,25 s

static func paso(m: MotorLeague, delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	_paso(m, delta)
	us_total += Time.get_ticks_usec() - t0
	pasos += 1

## Cronómetro propio (barato: dos lecturas por paso), para medir la capa sin parches: µs acumulados y pasos.
static var us_total := 0
static var pasos := 0

## RECORTE FUERA DE CÁMARA (10-11, aprobado por la líder; `LS_FUERA_CAMARA=0` lo apaga): quien está fuera del encuadre de la cámara
## activa o a más de `LEJOS` m de ella no empieza clips nuevos (los que lleva acaban normal, sin salto). Solo cambia lo que se ve
## de quien no se ve; sin cámara (pruebas sin gráficos) no recorta nada.
static var fuera_camara := OS.get_environment("LS_FUERA_CAMARA") != "0"
const LEJOS := 70.0
static var _cam: Camera3D = null

static func a_la_vista(n: Node3D) -> bool:
	if _cam == null:
		return true
	var pos := n.global_position + Vector3(0, 1.0, 0)
	return pos.distance_to(_cam.global_position) <= LEJOS and _cam.is_position_in_frustum(pos)

static func _paso(m: MotorLeague, delta: float) -> void:
	portador(m)
	if not transiciones_activas:
		return
	_cam = m.get_viewport().get_camera_3d() if fuera_camara and m.is_inside_tree() else null
	for p: Dictionary in m.jugadores:
		var en_curso := float(p.get("ls_trans_hasta", 0.0)) > m.t
		var off := float(p.get("ls_off", 0.0))
		var cuerpo := float(p.get("ls_cuerpo", 0.0))
		if not en_curso and off == 0.0 and cuerpo == 0.0:
			## Lo barato primero: solo los que van con un ciclo normal pueden empezar una transición.
			if p.get("anim_actual") in CICLOS:
				_quizas_empezar(m, p)
			continue
		if not en_curso and cuerpo != 0.0 and not bool(p.get("ls_visto", true)):
			enderezar(p)   ## fuera de cámara no hace falta el cuerpo girado: al camino barato (la compensación se apaga sola)
		var n: Node3D = p.get("node")
		var modelo: Node3D = p.get("ls_modelo")
		if not is_instance_valid(n) or not is_instance_valid(modelo):
			p["ls_off"] = 0.0
			p["ls_cuerpo"] = 0.0
			continue
		var ap: AnimationPlayer = p["anim"]
		if en_curso:
			ap.speed_scale = 1.0
			off = angle_difference(n.rotation.y, float(p["ls_yaw0"]))
		else:
			if p.has("ls_fin_yaw"):
				_al_acabar(p, n)
				off = float(p["ls_off"])
			off = off * exp(-RECOLOCAR * delta) if absf(off) > 0.01 else 0.0   ## (por debajo de ~0,6°, ya está)
			p["ls_off"] = off
			_seguir_con_cuerpo(m, p, ap)
			if float(p.get("ls_trans_hasta", 0.0)) <= m.t and float(p.get("ls_cuerpo", 0.0)) == 0.0 \
					and String(p.get("anim_actual", "")) in CICLOS:
				_quizas_empezar(m, p)
		p["ls_off"] = off + float(p.get("ls_off_extra", 0.0))
		p["ls_off_extra"] = 0.0
		## Girar el modelo recalcula todo su árbol: solo si cambia de verdad.
		var giro := float(p["ls_modelo_base"]) + float(p["ls_off"])
		if absf(giro - modelo.rotation.y) > 0.002:
			modelo.rotation.y = giro

## Acabó el clip: el cuerpo sigue mirando donde lo dejó. Como la marcha real (la de nuestro motor) no tiene por qué haber girado
## lo mismo que el clip, el estado del cuerpo pasa a ser el ángulo permitido más cercano a como mira AHORA respecto a la marcha
## real (y que su velocidad admita); la compensación del modelo solo cubre el resto y se apaga sola.
static func _al_acabar(p: Dictionary, n: Node3D) -> void:
	var mira := float(p["ls_fin_yaw"]) + float(p.get("ls_cuerpo", 0.0))
	p.erase("ls_fin_yaw")
	var rel := angle_difference(n.rotation.y, mira)
	var v: Vector3 = p["vel"]
	var cuerpo := LeagueMovimiento.cuerpo_posible(LeagueMovimiento.rango(Vector2(v.x, v.z).length()), LeagueMovimiento.cuerpo_permitido(rel))
	p["ls_cuerpo"] = cuerpo if angled or cuerpo == 0.0 else 0.0
	p["ls_off"] = angle_difference(float(p["ls_cuerpo"]), rel)

## Con el cuerpo girado y sin clip: el ciclo estable del original (plantilla) o, si su velocidad no lo admite o el motor pide
## otro paso (de espaldas, marcar, cansado…), vuelta a de frente sin salto.
static var _nombre_ciclo := {}   ## plantilla → nombre de su ciclo (sin rehacer la cadena en cada fotograma)

static func _seguir_con_cuerpo(m: MotorLeague, p: Dictionary, ap: AnimationPlayer) -> void:
	var cuerpo := float(p.get("ls_cuerpo", 0.0))
	if cuerpo == 0.0:
		return
	if float(p.get("ls_seguir_t", -1.0)) > m.t and p.get("anim_actual") == p.get("ls_ciclo_actual"):
		ap.speed_scale = float(p.get("ls_escala", 1.0))   ## (el motor la pisa en cada fotograma con la de su ciclo)
		return
	p["ls_seguir_t"] = m.t + CADENCIA
	var v: Vector3 = p["vel"]
	var sp := Vector2(v.x, v.z).length()
	var pedido := String(p.get("ls_pedido", ""))
	p["ls_pedido"] = ""   ## el motor lo vuelve a pedir en cada fotograma
	var par := LeagueMovimiento.plantilla(LeagueMovimiento.rango(sp), cuerpo)
	if par.is_empty() or (pedido != "" and not (pedido in CICLOS)) or is_same(p, m.poseedor):
		enderezar(p)
		if pedido != "":
			m._anim(p, pedido, false)
		return
	_quizas_empezar(m, p)
	if float(p.get("ls_trans_hasta", 0.0)) > m.t:
		return
	var nombre: String = _nombre_ciclo.get(par[0], "")
	if nombre == "":
		nombre = CICLO_CUERPO + String(par[0])
		_nombre_ciclo[par[0]] = nombre
	if p.get("anim_actual") != nombre and ap.has_animation(nombre):
		ap.play(nombre, 0.15)
		p["anim_actual"] = nombre
	p["ls_escala"] = clampf(sp / LeagueMovimiento.rango(sp), 0.7, 1.4)
	p["ls_ciclo_actual"] = nombre
	ap.speed_scale = float(p["ls_escala"])

## Vuelve el cuerpo a de frente sin salto: lo que giraba la plantilla pasa a la compensación del modelo, que se apaga sola.
static func enderezar(p: Dictionary) -> void:
	p["ls_off_extra"] = float(p.get("ls_off_extra", 0.0)) + float(p.get("ls_cuerpo", 0.0))
	p["ls_cuerpo"] = 0.0
	if String(p.get("anim_actual", "")).begins_with(CICLO_CUERPO):
		p["anim_actual"] = ""

## Mientras dura un clip del original o se corre con el cuerpo girado, los ciclos normales no lo pisan (se apunta cuál pidió el
## motor); un gesto de verdad sí.
static func bloquea(p: Dictionary, t: float, nombre: String, gesto: bool) -> bool:
	if float(p.get("ls_trans_hasta", 0.0)) <= t and float(p.get("ls_cuerpo", 0.0)) == 0.0:
		return false
	if gesto:
		cortar(p)
		return false
	p["ls_pedido"] = nombre
	return true

## Copia de la velocidad deseada de `MotorJugable._mover_jugadores` (sin los frenos de duelo, que no cambian la clase de paso).
static func deseada(m: MotorJugable, p: Dictionary, n: Node3D) -> Vector3:
	if not p.has("objetivo") or float(p.get("levanta_hasta", 0.0)) > m.t:
		return Vector3.ZERO
	var obj: Vector3 = p["objetivo"]
	var dif := Vector3(obj.x - n.position.x, 0.0, obj.z - n.position.z)
	var dist := dif.length()
	if dist <= 0.25:
		return Vector3.ZERO
	var tope := (4.4 + float(p["attr"]["rit"]) * 4.2) * (1.0 if bool(p.get("correr", false)) else 0.62) * (0.7 + 0.3 * float(p["aguante"]))
	return dif / dist * minf(tope * float(p.get("freno", 1.0)), dist * 2.5)

static func _quizas_empezar(m: MotorLeague, p: Dictionary) -> void:
	if float(p.get("ls_revisar", -1.0)) > m.t:
		return
	if is_same(p, m.poseedor) or bool(p["por"]) or float(p.get("gesto_hasta", 0.0)) > m.t or float(p.get("mirar_hasta", 0.0)) > m.t \
			or float(p.get("ls_espera", 0.0)) > m.t:
		return
	if not p.has("ls_revisar"):
		p["ls_revisar"] = m.t + CADENCIA * float(m.jugadores.find(p)) / maxf(1.0, float(m.jugadores.size()))
		return
	p["ls_revisar"] = m.t + CADENCIA
	var n: Node3D = p.get("node")
	var ap: AnimationPlayer = p.get("anim")
	if not is_instance_valid(n) or not is_instance_valid(ap):
		return
	p["ls_visto"] = a_la_vista(n)
	if not bool(p["ls_visto"]):
		return
	var v: Vector3 = p["vel"]
	var sp := Vector2(v.x, v.z).length()
	var des := deseada(m, p, n)
	var sp_des := des.length()
	var entra := LeagueMovimiento.rango(sp)
	var sale := LeagueMovimiento.rango(sp_des)
	var rel := angle_difference(n.rotation.y, atan2(des.x, des.z)) if sp_des > 0.1 else 0.0
	var cuerpo := float(p.get("ls_cuerpo", 0.0))
	var mirar := NAN
	var quiere_cuerpo := 0.0
	if angled and m.balon != null:
		var hb := m.balon.position - n.position
		mirar = LeagueMovimiento.mirada(angle_difference(n.rotation.y, atan2(hb.x, hb.z)), sp_des, sp)
		quiere_cuerpo = LeagueMovimiento.cuerpo_posible(maxf(entra, sale) if sale > LeagueMovimiento.IDLE else LeagueMovimiento.IDLE,
			LeagueMovimiento.cuerpo_permitido(mirar - rel))
	var arranca := entra == LeagueMovimiento.IDLE and sale > LeagueMovimiento.IDLE
	var frena := entra > LeagueMovimiento.IDLE and sale == LeagueMovimiento.IDLE
	var gira := entra > LeagueMovimiento.IDLE and sale > LeagueMovimiento.IDLE and absf(rel) >= GIRO_MIN
	var vuelve := entra > LeagueMovimiento.IDLE and absf(angle_difference(quiere_cuerpo, cuerpo)) > 0.01
	if not (arranca or frena or gira or vuelve):
		return
	if not preparar(ap, m.t):
		return
	var c := LeagueMovimiento.elegir(sp, rel, sp_des, cuerpo, mirar, pie_que_toca(p, ap))
	if not c.is_empty() and c.has("auto") and not ap.has_animation(String(c["nombre"])) and not LeagueMovimiento.estable(c):
		_construir_auto(c, ap, m.t)
	if c.is_empty() or LeagueMovimiento.estable(c) or not ap.has_animation(String(c["nombre"])):
		p["ls_espera"] = m.t + ESPERA   ## sin clip que aporte: no se vuelve a buscar en cada fotograma
		return
	var modelo := ap.get_node_or_null(ap.root_node) as Node3D
	if modelo == null or modelo == n:
		return
	if not p.has("ls_modelo_base"):
		p["ls_modelo"] = modelo
		p["ls_modelo_base"] = modelo.rotation.y
	## El marco del clip: su «adelante» es la marcha de ahora, puesta de modo que el cuerpo no salte al empezar.
	var r0 := n.rotation.y + float(p.get("ls_off", 0.0)) + cuerpo - float(c["cuerpo_ini"])
	ap.play(String(c["nombre"]), 0.1)
	ap.speed_scale = 1.0
	p["anim_actual"] = String(c["nombre"])
	p["ls_pedido"] = ""
	p["ls_trans_hasta"] = m.t + float(c["largo"])
	p["ls_yaw0"] = r0
	p["ls_fin_yaw"] = r0 + float(c["ang"])
	p["ls_cuerpo"] = float(c["cuerpo_sale"])
	p["ls_pie"] = String(c["pie_sale"])
	var clave := "loco_arranque" if arranca else ("loco_frenada" if frena else ("loco_giro" if gira else "loco_cuerpo"))
	m.cuenta_toques[clave] = int(m.cuenta_toques.get(clave, 0)) + 1

## El pie que toca mover (L `spatialState.foot`): tras un clip del original, su pie de salida; en un ciclo, el que va en el aire
## (los de League y las plantillas mueven el derecho en la primera mitad; los nuestros, según `AnimPasos.fases`, la fase en la
## que apoya el izquierdo). "" si no se sabe.
static func pie_que_toca(p: Dictionary, ap: AnimationPlayer) -> String:
	var actual := String(p.get("anim_actual", ""))
	if actual.begins_with("ls_movement"):
		return String(p.get("ls_pie", ""))
	if not ap.has_animation(actual) or ap.current_animation != actual:
		return ""
	var fase := fposmod(ap.current_animation_position / maxf(ap.current_animation_length, 0.001), 1.0)
	if AnimPasos.fases.has(actual):   ## (medida: manda sobre la regla de la mitad)
		return "D" if fposmod(fase - float(AnimPasos.fases[actual]), 1.0) < 0.5 else "I"
	if actual.begins_with(CICLO_CUERPO) or actual == "correr":
		return "D" if fase < 0.5 else "I"
	return ""

static var _auto_t := -1.0

## Una intermedia del original se construye la primera vez que se elige (como mucho una por paso del motor).
static func _construir_auto(c: Dictionary, ap: AnimationPlayer, t: float) -> void:
	if t == _auto_t or not ap.has_animation("correr") or ap.get_animation("correr").get_track_count() == 0:
		return
	_auto_t = t
	LeagueAuto.construir(c, ap, String(ap.get_animation("correr").track_get_path(0)).get_slice(":", 0))

static var _preparadas := {}
const TANDA := 8

## Añade los clips de movimiento del original a la biblioteca del jugador (compartida por los de su esqueleto: una vez por
## biblioteca), unos pocos por fotograma. El prefijo de las pistas se lee de su «correr». Devuelve si ya están todos.
static var _tanda_t := -1.0

static func preparar(ap: AnimationPlayer, t: float) -> bool:
	if not ap.has_animation_library(""):
		return false
	var lib := ap.get_animation_library("")
	var id := lib.get_instance_id()
	var sig := int(_preparadas.get(id, 0))
	if sig < 0:
		return true
	if not lib.has_animation("correr") or lib.get_animation("correr").get_track_count() == 0:
		return false
	if t == _tanda_t:
		return false   ## una tanda por paso del motor, para todo el partido
	_tanda_t = t
	var prefijo := String(lib.get_animation("correr").track_get_path(0)).get_slice(":", 0)
	_preparadas[id] = LeagueAnim.movimiento(lib, prefijo, sig, TANDA)
	return int(_preparadas[id]) < 0

## Un gesto de verdad (golpeo, entrada, caída) corta la transición y endereza el cuerpo.
static func cortar(p: Dictionary) -> void:
	p["ls_trans_hasta"] = 0.0
	p.erase("ls_fin_yaw")
	enderezar(p)

## El portador conduce con los ciclos con balón del original según su clase de velocidad (L velocitystate: sprint desde 6,2 m/s),
## al ritmo de su velocidad.
static func portador(m: MotorJugable) -> void:
	var c: Dictionary = m.poseedor
	if c.is_empty():
		return
	if c.has("ls_cuerpo") and (float(c["ls_cuerpo"]) != 0.0 or float(c.get("ls_trans_hasta", 0.0)) > 0.0):
		cortar(c)
	if float(c.get("gesto_hasta", 0.0)) > m.t or not (c.get("anim_actual") in CONDUCIR):
		return
	var sp := Vector2((c["vel"] as Vector3).x, (c["vel"] as Vector3).z).length()
	if sp < 0.5:
		return
	var clave := "conducir_ls_rapido" if sp >= LeagueNucleo.CAMBIO_TROTE_SPRINT else "conducir_ls"
	var ap: AnimationPlayer = c.get("anim")
	if not is_instance_valid(ap) or not ap.has_animation(clave):
		return
	m._anim(c, clave, false)
	ap.speed_scale = clampf(sp / float(LeagueAnim.CICLOS_CONDUCIR[clave][1]), 0.7, 1.4)
