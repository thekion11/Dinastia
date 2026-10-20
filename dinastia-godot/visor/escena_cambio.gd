class_name EscenaCambio
extends Node3D
## EL CAMBIO EN EL CÉSPED (17-10-2026, M-104). Hasta hoy, con el motor real, el
## que salía desaparecía de golpe y el que entraba aparecía en la banda. Ahora:
##   1. El cuarto árbitro levanta el cartel LED con los dos dorsales (el que
##      entra en verde, el que sale en rojo), reutilizando `CuartoArbitro`.
##   2. El que entra espera en la banda, junto al cuarto árbitro (sujeto en su
##      sitio y con `freno_duelo` = 0: el equipo juega con diez, como en la
##      realidad, hasta que se cruzan).
##   3. El que sale trota y, al acercarse, camina hasta la banda; se chocan la
##      mano (`chocar_mano`, los dos) y el que entra arranca hacia su sitio.
##   4. El que sale sigue caminando fuera del campo y se borra.
## Si el que sale está demasiado lejos (más de ESPERA_MAX segundos), el que
## entra no espera más: arranca y no hay palmada. El reloj es el del motor
## (`motor.t`): se para con la pausa y corre con la velocidad del partido.
## Fuera de ese rato no queda nada: ni nodos ni coste por fotograma.
##   EscenaCambio.iniciar(raiz, spawner, motor, nodo_sale, anim_sale, entra, dorsal_sale, dorsal_entra, kit)

const X_LINEA := 34.4          ## donde espera el que entra (pisando la banda)
const Z_ESPERA := 3.4          ## junto al cuarto árbitro (que está en z = 1,6)
const ESPERA_MAX := 7.0
const V_TROTE := 3.8
const V_PASO := 1.6
const DURACION_MAX := 16.0

var fase := "acude"            ## acude → palmada → se_va
var entra_nodo: Node3D
## Para las capturas: congela la escena (el motor también se para aparte).
var congelar := false
## Carrera de Jugador: el nodo del que sale es del motor; al final se esconde
## (no se borra) por si algo lo sigue mirando.
var borrar_al_salir := true
var _motor: MotorJugable
var _sale: Node3D
var _ap_sale: AnimationPlayer
var _entra: Dictionary = {}
var _t := 0.0
var _t_motor := 0.0
var _t_palmada := 0.0
var _punto := Vector3.ZERO
var _anim_actual := ""
var _sujeto := true
var _fuera := Vector3.INF

static func iniciar(raiz: Node3D, spawner: PlayerSpawner, motor: MotorJugable, nodo_sale: Node3D, anim_sale: AnimationPlayer,
		entra: Dictionary, dorsal_sale: int, dorsal_entra: int, kit: Dictionary = {}) -> EscenaCambio:
	if raiz == null or motor == null or not is_instance_valid(nodo_sale) or entra.is_empty():
		return null
	CuartoArbitro.levantar_cambio(raiz, spawner, dorsal_sale, dorsal_entra, kit)
	## Dos cambios a la vez (doble cambio): el segundo espera un metro más allá.
	var ya := 0
	for h in raiz.get_children():
		if h is EscenaCambio:
			ya += 1
	var e := EscenaCambio.new()
	e.name = "EscenaCambio"
	raiz.add_child(e)
	e._motor = motor
	e._sale = nodo_sale
	e._ap_sale = anim_sale
	e._entra = entra
	e._t_motor = motor.t
	e.entra_nodo = entra.get("node")
	## El que entra, en la banda junto al cuarto árbitro, mirando al campo.
	e._punto = Vector3(X_LINEA, 0, Z_ESPERA + 1.3 * float(ya))
	if is_instance_valid(e.entra_nodo):
		e.entra_nodo.position = e._punto
		e.entra_nodo.rotation.y = -PI * 0.5
	entra["vel"] = Vector3.ZERO
	entra["freno_duelo_hasta"] = motor.t + ESPERA_MAX
	entra["freno_duelo"] = 0.0
	e._poner_anim("trotar")
	return e

func _poner_anim(nombre: String) -> void:
	if _anim_actual == nombre or not is_instance_valid(_ap_sale) or not _ap_sale.has_animation(nombre):
		return
	_ap_sale.play(nombre, 0.25)
	_ap_sale.speed_scale = 1.0
	_anim_actual = nombre

## Suelta al que entra (el motor vuelve a moverlo).
func _soltar() -> void:
	_sujeto = false
	if not _entra.is_empty():
		_entra["freno_duelo_hasta"] = 0.0
		_entra["freno_duelo"] = 1.0

func _process(_delta: float) -> void:
	if congelar or _motor == null:
		return
	## El reloj del partido (acotado: un fotograma lento no teletransporta).
	var dt := clampf(_motor.t - _t_motor, 0.0, 0.2)
	_t_motor = _motor.t
	_t += dt
	if not is_instance_valid(_sale):
		_soltar()
		queue_free()
		return
	## Mientras espera, quieto en su sitio: el freno no basta si el motor
	## recoloca a todos (un saque) o lo empuja; esto corre después del paso
	## del motor (hijo de la raíz 3D, que es hija de la vista).
	if _sujeto and _motor.poseedor == _entra:
		_soltar()
	if _sujeto and is_instance_valid(entra_nodo):
		entra_nodo.position = _punto
		_entra["vel"] = Vector3.ZERO
	match fase:
		"acude":
			## Al lado del que entra, por el lado del campo.
			var meta := _punto + Vector3(-0.85, 0, -0.25)
			var dif := meta - _sale.position
			dif.y = 0.0
			var d := dif.length()
			if d < 0.12:
				_palmada()
				return
			var v := V_TROTE if d > 9.0 else V_PASO
			_poner_anim("trotar" if d > 9.0 else "caminar")
			_sale.position += dif / d * minf(v * dt, d)
			_sale.rotation.y = rotate_toward(_sale.rotation.y, atan2(dif.x, dif.z), 6.0 * dt)
			if _t > ESPERA_MAX:
				## Demasiado lejos: el que entra no espera más.
				_soltar()
				fase = "se_va"
		"palmada":
			## Frente a frente mientras chocan.
			var hacia := (entra_nodo.position - _sale.position) if is_instance_valid(entra_nodo) else Vector3.FORWARD
			_sale.rotation.y = rotate_toward(_sale.rotation.y, atan2(hacia.x, hacia.z), 8.0 * dt)
			if is_instance_valid(entra_nodo):
				entra_nodo.rotation.y = atan2(-hacia.x, -hacia.z)
			if _t - _t_palmada > 1.0:
				_soltar()
				fase = "se_va"
		"se_va":
			## Fuera del campo, hacia la banda (y se borra al salir).
			## (El destino se fija una vez: recalculado cada fotograma, se alejaba.)
			if _fuera == Vector3.INF:
				_fuera = Vector3(X_LINEA + 4.0, 0, _sale.position.z - 2.0)
			var dif2 := _fuera - _sale.position
			dif2.y = 0.0
			_poner_anim("caminar")
			if dif2.length() < 0.2 or _t > DURACION_MAX:
				if borrar_al_salir:
					_sale.queue_free()
				else:
					_sale.visible = false
				queue_free()
				return
			_sale.position += dif2.normalized() * V_PASO * dt
			_sale.rotation.y = rotate_toward(_sale.rotation.y, atan2(dif2.x, dif2.z), 5.0 * dt)

func _palmada() -> void:
	fase = "palmada"
	_t_palmada = _t
	_anim_actual = ""
	if is_instance_valid(_ap_sale) and _ap_sale.has_animation("chocar_mano"):
		_ap_sale.play("chocar_mano", 0.15)
		_anim_actual = "chocar_mano"
	## El que entra, igual (un gesto del motor: no le cambia la animación).
	var ap: AnimationPlayer = _entra.get("anim")
	if is_instance_valid(ap) and ap.has_animation("chocar_mano"):
		ap.play("chocar_mano", 0.15)
		_entra["gesto_hasta"] = _motor.t + 1.1
		_entra["anim_actual"] = "chocar_mano"
	if is_instance_valid(entra_nodo):
		var hacia := _sale.position - entra_nodo.position
		entra_nodo.rotation.y = atan2(hacia.x, hacia.z)
