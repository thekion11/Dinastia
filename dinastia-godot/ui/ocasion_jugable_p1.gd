extends Control
## (Parte 1 de 2 de `ocasion_jugable.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `ocasion_jugable.gd`, conserva la clase.)

## LA OCASIÓN JUGABLE, EN EL ESTADIO (26-10-2026, fila 14 de la propuesta de la sesión 4).
##
## Vive dentro de `VistaEstadio` cuando el partido lo juega el motor real del 3D
## (`MotorJugable`, en piloto automático: tú eres el DT, no un jugador). En 3-6
## llegadas claras de tu equipo el partido SE PARA (el motor no da ni un paso y el
## mundo queda casi quieto), la cámara baja a pie de campo detrás del que lleva el
## balón y eliges: PASE, CONDUCCIÓN o TIRO. Cada botón lleva su probabilidad, que
## sale de la lectura de `OcasionesDT` (el modelo de `MotorLibre`).
##
## LO QUE PASA DESPUÉS NO LO DECIDE ESTA CLASE: la elección se le da al motor del
## césped -el mismo `_tirar()` y `_pasar_a()` que usa su IA, con el error, el portero
## y los defensas de siempre-. Así el gol (o la atajada) es tan real como cualquier
## otro del partido y el acta, la tabla y las estadísticas no notan la diferencia.
## Tras un pase o una conducción puede tocar decidir otra vez (como mucho tres
## veces); toda la ocasión dura como mucho 15 s reales y, si no eliges, el jugador
## hace lo que recomienda el cuerpo técnico.
##
## Quien la monta llama a `tras_paso()` después de CADA paso del motor (para cazar
## la jugada antes de que la IA la resuelva) y a `vigilar(delta)` una vez por
## fotograma; mientras `congela()` sea true no se avanza el motor.

signal empieza(numero: int)
signal termina(resultado: String)

## Clave del ajuste (se elige en el panel previo al partido, `InformeRival`).
const PREF := "ocasiones_jugables"
const META := "ocasiones_jugables"
## Sin pantalla (banco, pruebas) no se monta, salvo que una prueba lo pida.
static var forzar := false
const CLAVES := ["pase", "conducir", "tiro"]
const ICONOS := {"pase": "➡️", "conducir": "🏃", "tiro": "🎯"}
const TECLAS := {"pase": "1", "conducir": "2", "tiro": "3"}

var motor: MotorJugable
var partido: Partido
var mi_lado := -1
var rig: CameraRig = null
## En el juego: el mundo casi se para mientras eliges y la jugada va a cámara
## algo lenta. Las pruebas lo apagan (y cuentan el tiempo con su propio delta).
var camara_lenta := true
var reloj_real := true

var cupo := 0
var hechas := 0
## Una entrada por decisión: {min, ocasion, eleccion, prob, recomendada, auto}; y
## una por ocasión cerrada: {min, ocasion, resultado}.
var historial: Array = []
var _proxima := 0
var _fase := ""             ## "" | "eligiendo" | "jugando"
var _portador: Dictionary = {}
var _lect: Dictionary = {}
var _pasos := 0
var _t_elegir := 0.0
var _t_total := 0.0
var _espera := ""
var _t_espera := 0.0
var _resultado := ""
var _us_antes := 0
var _rng := RandomNumberGenerator.new()

var _caja: PanelContainer
var _cabecera: Label
var _consejo: Label
var _botones: Dictionary = {}
var _barra: ProgressBar
var _franjas: Array[ColorRect] = []
var _aviso: Label
var _t_aviso := 0.0

## ¿Está encendido en el panel previo al partido? Por defecto, sí.
static func encendida() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(CajonAjustes.RUTA) != OK:
		return true
	return bool(cfg.get_value(CajonAjustes.SECCION, PREF, true))

static func guardar(si: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, PREF, si)
	cfg.save(CajonAjustes.RUTA)

func configurar(m: MotorJugable, p: Partido, lado: int, rig_: CameraRig = null) -> void:
	motor = m
	partido = p
	mi_lado = lado
	rig = rig_
	var semilla := hash(p.local.id + "|" + p.visita.id + "|ocasiones")
	_rng.seed = semilla
	cupo = OcasionesDT.cupo(semilla, p.minuto, p.minutos_fin)
	## Tras el descanso en el camarín el estadio se vuelve a abrir: el cupo y las ya
	## jugadas siguen siendo las del partido (se guardan en él), no se empieza de cero.
	if p.has_meta(META):
		var d: Dictionary = p.get_meta(META)
		cupo = int(d["cupo"])
		hechas = int(d["hechas"])
	_proxima = OcasionesDT.primer_minuto(semilla, p.minuto)
	motor.gol.connect(_al_gol)
	motor.remate.connect(_al_remate)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	(self as OcasionJugable)._construir()

func congela() -> bool:
	return _fase == "eligiendo"

func activa() -> bool:
	return _fase != ""

func _lado_de(p: Dictionary) -> int:
	return 0 if bool(p["es_local"]) else 1

func _dist_arco(p: Dictionary) -> float:
	var arco := motor._arco_rival(p)
	var yo := motor.pos(p)
	return Vector2(yo.x - arco.x, yo.z - arco.z).length()

# ---------------------------------------------------------------------------
#  CADA PASO DEL MOTOR
# ---------------------------------------------------------------------------

## Devuelve true si el motor debe dejar de avanzar (empezó una decisión).
func tras_paso() -> bool:
	if motor == null or mi_lado < 0:
		return false
	if _fase == "jugando":
		return _seguir_jugada()
	if _fase != "" or hechas >= cupo or motor.control_equipo >= 0 or motor.practica or motor.estado != "juego":
		return false
	var m := motor.minuto()
	if m < _proxima:
		return false
	var p := motor.poseedor
	if p.is_empty() or bool(p["por"]) or _lado_de(p) != mi_lado or not motor._tiro_vivo.is_empty():
		return false
	## Si quedan pocos minutos para las que faltan, vale una llegada algo menos clara.
	var listo := OcasionesDT.nivel(m, partido.minutos_fin, hechas, cupo)
	if not OcasionesDT.es_clara(_dist_arco(p), motor.pos(p).x, motor._presion(p), listo):
		return false
	return _abrir(p)

func _abrir(p: Dictionary) -> bool:
	var lect := _leer(p)
	if lect.is_empty() or not lect.has("recomendada"):
		return false
	_lect = lect
	_portador = p
	if _pasos == 0:
		hechas += 1
		partido.set_meta(META, {"cupo": cupo, "hechas": hechas})
		_t_total = 0.0
		_resultado = ""
		empieza.emit(hechas)
		Sonido.toca("ocasion")
	_pasos += 1
	_fase = "eligiendo"
	## Que su IA no la resuelva mientras decides.
	motor._decision_en = motor.t + 99.0
	_t_elegir = clampf(OcasionesDT.SEGUNDOS_MAX - _t_total - 2.0, 2.5, OcasionesDT.SEGUNDOS_ELEGIR)
	_us_antes = Time.get_ticks_usec()
	if camara_lenta:
		Engine.time_scale = 0.04
	(self as OcasionJugable)._pintar()
	_camara_pie(p)
	return true

## La lectura con las posiciones de ahora mismo (ver `OcasionesDT.lectura`).
func _leer(p: Dictionary) -> Dictionary:
	var local := mi_lado == 0
	var pos: Dictionary = {}
	for q: Dictionary in motor.jugadores:
		if not motor.expulsados.has(q):
			pos[String(q["id"])] = OcasionesDT.a_plano(motor.pos(q), local)
	var mios: Array = partido.once_local if local else partido.once_visita
	var suyos: Array = partido.once_visita if local else partido.once_local
	var lect := OcasionesDT.lectura(mios, suyos, pos, String(p["id"]))
	if lect.is_empty():
		return lect
	## El tiro y la recomendación, en la moneda del motor que juega (ver
	## `OcasionesDT.prob_tiro_3d`): el pase y la conducción valen el tiro que vendría.
	var d := _dist_arco(p)
	lect.erase("tiro")
	if d <= OcasionesDT.DIST_APURADA:
		lect["tiro"] = {"prob": _gol_desde(p, motor.pos(p))}
	var tras_pase := 0.0
	if lect.has("pase"):
		lect["pase"]["prob"] = float(lect["pase"]["prob"]) * OcasionesDT.AJUSTE_PASE_3D
		var q := _jugador_3d(String(lect["pase"]["receptor_id"]))
		tras_pase = _gol_desde(q, motor.pos(q)) if not q.is_empty() else 0.0
	var adelante := motor.pos(p) + (motor._arco_rival(p) - motor.pos(p)).normalized() * 6.0
	lect["recomendada"] = OcasionesDT.recomendar(lect, tras_pase, _gol_desde(p, adelante))
	return lect

## La probabilidad de gol si `q` tirara desde `desde` (con los rivales donde están).
func _gol_desde(q: Dictionary, desde: Vector3) -> float:
	var arco := motor._arco_rival(q)
	var d := Vector2(desde.x - arco.x, desde.z - arco.z).length()
	return OcasionesDT.prob_tiro_3d(d, desde.x, _tapada(q, desde, arco), float(q["attr"]["tir"])) * OcasionesDT.AJUSTE_TIRO_EN_JUEGO

## ¿Algún rival de campo (el portero no cuenta: siempre está en esa línea) tapa
## el camino del balón entre `desde` y el arco?
func _tapada(q: Dictionary, desde: Vector3, arco: Vector3) -> bool:
	var a := Vector2(desde.x, desde.z)
	var b := Vector2(arco.x, arco.z)
	for r: Dictionary in motor.jugadores:
		if bool(r["es_local"]) == bool(q["es_local"]) or bool(r["por"]) or motor.expulsados.has(r):
			continue
		var c := Vector2(motor.pos(r).x, motor.pos(r).z)
		var cerca := Geometry2D.get_closest_point_to_segment(c, a, b)
		var f := a.distance_to(cerca) / maxf(a.distance_to(b), 0.1)
		if c.distance_to(cerca) < 1.0 and f > 0.03 and f < 0.92:
			return true
	return false

## Lo que va pasando tras la elección. true = otra decisión (se para el motor).
func _seguir_jugada() -> bool:
	var dueno := motor.poseedor
	if motor.estado != "juego":
		_cerrar(_resultado if _resultado != "" else "parado")
		return false
	var dt := motor.t - _t_espera
	if _espera == "tiro":
		if (motor._tiro_vivo.is_empty() and dt > 0.4) or dt > 4.0:
			_cerrar(_resultado if _resultado != "" else "fallo")
		return false
	if not dueno.is_empty() and _lado_de(dueno) != mi_lado:
		_cerrar("perdida")
		return false
	var otra := _pasos < OcasionesDT.PASOS_MAX and _t_total < OcasionesDT.SEGUNDOS_MAX - 3.0
	if _espera == "pase":
		if not dueno.is_empty() and dueno != _portador and dt > 0.15:
			if otra and not bool(dueno["por"]) and _dist_arco(dueno) <= OcasionesDT.DIST_MINIMO:
				return _abrir(dueno)
			_cerrar("pase")
		elif dt > 4.0:
			_cerrar("perdida")
		return false
	## Conducción: al cabo de 1,3 s (si sigue con ella) toca decidir otra vez.
	if dueno == _portador and dt >= 1.3:
		if otra and _dist_arco(dueno) <= OcasionesDT.DIST_MINIMO:
			return _abrir(dueno)
		_cerrar("sigue")
	elif dueno.is_empty() and dt > 2.5:
		_cerrar("perdida")
	return false

func _al_gol(es_local: bool, _autor: String, _asist: String) -> void:
	if _fase != "" and es_local == (mi_lado == 0):
		_resultado = "gol"

func _al_remate(es_local: bool, _autor: String, tipo: String) -> void:
	if _fase == "jugando" and _espera == "tiro" and es_local == (mi_lado == 0) and _resultado == "":
		_resultado = tipo

# ---------------------------------------------------------------------------
#  LA ELECCIÓN
# ---------------------------------------------------------------------------

func elegir(clave: String, auto := false) -> void:
	if _fase != "eligiendo" or not _lect.has(clave):
		return
	var p := _portador
	historial.append({"min": motor.minuto(), "ocasion": hechas, "eleccion": clave, "prob": float(_lect[clave]["prob"]),
		"recomendada": String(_lect["recomendada"]), "auto": auto})
	_fase = "jugando"
	_caja.visible = false
	(self as OcasionJugable)._franjas_visibles(false)
	if camara_lenta:
		Engine.time_scale = 0.65
	motor._decision_en = motor.t
	_espera = clave
	_t_espera = motor.t
	match clave:
		"tiro":
			## EL MISMO TIRO QUE HARÍA LA IA (`_ia_portador`): a un palo al azar, raso
			## o arriba, con la fuerza al azar, del generador del motor. Un tiro «de
			## manual» (al palo contrario, raso) convertía el 30-60 % hasta desde 25 m
			## (sonda del 26-10): las ocasiones habrían sido goles de regalo y el
			## partido ya no sería el que se simula.
			var r := motor._rng
			var palo := (1.0 if r.randf() < 0.5 else -1.0) * (r.randf_range(MotorJugable.PALO_TIRO, 1.0) if MotorJugable.TIRO_PULIDO else r.randf_range(0.55, 0.95))
			var alto := -0.45 if r.randf() < 0.6 else 0.55
			motor._tirar(p, Vector2(palo, alto), clampf(0.55 + r.randf() * 0.4, 0.0, 1.0))
			if rig != null and is_instance_valid(motor.balon):
				_plano(motor.pos(p), motor.balon, 3.5)
		"pase":
			var q := _jugador_3d(String(_lect["pase"]["receptor_id"]))
			if q.is_empty():
				_cerrar("pase")
				return
			var al_hueco := (motor.pos(q).z - motor.pos(p).z) * MotorJugable.dir_ataque(mi_lado == 0) > 6.0
			motor._pasar_a(p, q, float(_lect["pase"]["dist"]) > 30.0, al_hueco)
		"conducir":
			## Con margen: la IA no debe soltarla justo cuando toca volver a decidir.
			motor._decision_en = motor.t + 2.3
			p["correr"] = true

func _jugador_3d(id: String) -> Dictionary:
	for q: Dictionary in motor.jugadores:
		if String(q["id"]) == id:
			return q
	return {}

func _cerrar(resultado: String) -> void:
	if _fase == "":
		return
	_fase = ""
	_pasos = 0
	_espera = ""
	if motor._decision_en > motor.t + 50.0:
		motor._decision_en = motor.t + 0.3
	Engine.time_scale = 1.0
	_caja.visible = false
	(self as OcasionJugable)._franjas_visibles(false)
	if rig != null:
		rig.quitar_inserto()
	historial.append({"min": motor.minuto(), "ocasion": hechas, "resultado": resultado})
	_proxima = motor.minuto() + OcasionesDT.hueco(motor.minuto(), partido.minutos_fin, cupo - hechas)
	(self as OcasionJugable)._avisar(resultado)
	termina.emit(resultado)

## Una vez por fotograma: la cuenta atrás y el tope de 15 s.
func vigilar(delta: float) -> void:
	var dr := delta
	if reloj_real:
		var ahora := Time.get_ticks_usec()
		## Tope de 0,25 s: si se abrió la pausa o un panel, al volver no se
		## descuenta todo ese rato de golpe.
		dr = minf(float(ahora - _us_antes) / 1000000.0, 0.25)
		_us_antes = ahora
	if _t_aviso > 0.0:
		_t_aviso -= dr
		_aviso.modulate.a = clampf(_t_aviso / 0.5, 0.0, 1.0)
	if _fase == "":
		return
	_t_total += dr
	if _fase == "eligiendo":
		_t_elegir -= dr
		_barra.value = maxf(_t_elegir, 0.0)
		if _t_elegir <= 0.0 or _t_total >= OcasionesDT.SEGUNDOS_MAX:
			elegir(String(_lect["recomendada"]), true)
	elif _t_total >= OcasionesDT.SEGUNDOS_MAX:
		_cerrar("tiempo")

func _input(e: InputEvent) -> void:
	if _fase != "eligiendo" or not (e is InputEventKey or e is InputEventJoypadButton) or not e.is_pressed():
		return
	var clave := ""
	if e is InputEventKey:
		match (e as InputEventKey).physical_keycode:
			KEY_1, KEY_KP_1: clave = "pase"
			KEY_2, KEY_KP_2: clave = "conducir"
			KEY_3, KEY_KP_3: clave = "tiro"
	if clave == "":
		if e.is_action_pressed("jugar_pase"): clave = "pase"
		elif e.is_action_pressed("jugar_centro"): clave = "conducir"
		elif e.is_action_pressed("jugar_tiro"): clave = "tiro"
	if clave != "" and _lect.has(clave):
		get_viewport().set_input_as_handled()
		elegir(clave)

func _exit_tree() -> void:
	## Nunca dejar el mundo a cámara lenta si se cierra el estadio a mitad.
	if _fase != "" or Engine.time_scale != 1.0:
		Engine.time_scale = 1.0

# ---------------------------------------------------------------------------
#  LA CÁMARA A PIE DE CAMPO
# ---------------------------------------------------------------------------

## Detrás del que lleva el balón, a la altura de los ojos, mirando al arco.
func _camara_pie(p: Dictionary) -> void:
	if rig == null:
		return
	var yo := motor.pos(p)
	var d := MotorJugable.dir_ataque(mi_lado == 0)
	var lado := 1.0 if yo.x <= 0.0 else -1.0
	var cam := yo + Vector3(lado * 2.2, 1.7, -d * 6.5)
	cam.x = clampf(cam.x, -36.0, 36.0)
	cam.z = clampf(cam.z, -56.0, 56.0)
	var mira := yo.lerp(motor._arco_rival(p), 0.45) + Vector3(0, 1.0, 0)
	if not rig.insertar_plano("ocasion", cam, mira, 46.0, 60.0, p["node"]):
		return

func _plano(desde: Vector3, sigue: Node3D, dur: float) -> void:
	var d := MotorJugable.dir_ataque(mi_lado == 0)
	var cam := desde + Vector3(4.5 * (1.0 if desde.x <= 0.0 else -1.0), 1.6, -d * 4.0)
	rig.insertar_plano("ocasion", cam, sigue.global_position + Vector3(0, 0.8, 0), 42.0, dur, sigue)
