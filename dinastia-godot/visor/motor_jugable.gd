class_name MotorJugable
extends "res://visor/motor_jugable_p11.gd"
## (Parte 12 de 12 de `motor_jugable.gd`.)

## Un paso de simulación. Público para poder correrlo en las pruebas sin
## esperar al reloj.
func paso(delta: float) -> void:
	if estado == "fin":
		return
	## CÁMARA LENTA del tiro potente (FC 26): medio segundo real a un tercio.
	if lento > 0.0:
		lento -= delta
		delta *= 0.35
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
			if t >= dur_mitad() + _anadido_de(mitad):
				_fin_de_mitad()
				return
			if not poseedor.is_empty():
				posesion[0 if bool(poseedor["es_local"]) else 1] += delta
			_mover_balon(delta)
			_duelos()
			if estado != "juego":
				_mover_jugadores(delta)
				_actualizar_balon_visual(delta)
				return
			_disputas(delta)
			if control_equipo >= 0 and not autopiloto:
				_control_de_equipo()
			_ia_equipos(delta)
			if practica:
				_paso_practica()
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
			## Con el equipo en tus manos ya manejas a alguien durante el saque
			## (si no, el cursor no aparecía hasta que se reanudaba el juego).
			if control_equipo >= 0 and not autopiloto and usuario.is_empty():
				var lz: Dictionary = saque.get("lanzador", {})
				var cand := _mio_mas_cercano(control_equipo == 0, {} if bool(lanza_usuario.get(String(saque.get("tipo", "")), false)) else lz)
				if not cand.is_empty():
					_poner_usuario(cand)
			_colocar_saque(delta)
		"tanda":
			t += delta
			_paso_tanda(delta)
			return
		"gol", "descanso":
			_mover_balon(delta)
			_ia_celebracion(delta)
			## Antes de la prórroga, un descanso corto algo más largo.
			if _t_estado > (duracion_gol if estado == "gol" else (5.0 if mitad == 2 else 3.2)):
				if estado == "descanso":
					## 2 = segunda parte (saca la visita), 3 y 4 = prórroga.
					mitad += 1
					t = 0.0
					_saque_de_centro(mitad % 2 == 1)
				else:
					var saca_local: bool = not bool(saque.get("gol_local", true))
					_saque_de_centro(saca_local)
	_mover_jugadores(delta)
	if estado == "juego":
		_cuerpos()
	_actualizar_balon_visual(delta)

# ---------------------------------------------------------------- bucle

func _physics_process(delta: float) -> void:
	paso(delta)

## El VAR anula un gol ya celebrado: solo el marcador del motor (el acta la
## corrige `Partido.anular_gol_externo`).
func anular_gol(de_local: bool) -> void:
	var i := 0 if de_local else 1
	goles[i] = maxi(goles[i] - 1, 0)

func posesion_local() -> int:
	var tot: float = float(posesion[0]) + float(posesion[1])
	return int(round(posesion[0] / tot * 100.0)) if tot > 0.0 else 50
