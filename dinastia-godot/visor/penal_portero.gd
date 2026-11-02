class_name PenalPortero
extends RefCounted
## EL PORTERO ANTE UN PENAL (2-11-2026, sacado de `motor_jugable_p7.gd`): en pleno partido y en la tanda.

## EL PENAL EN EL PARTIDO (25-10-2026): a 11 m no da tiempo a reaccionar, así que
## el portero adivina el lado, como en la tanda (antes reaccionaba al tiro y paraba
## 4 de cada 9: la sonda medía un 43 % de penales marcados; en el fútbol, ~76 %).
static func en_juego(m: MotorJugable, gk: Dictionary, cruce: Vector3) -> void:
	## (2-11, M-119) Lee al lanzador como en la tanda: va más al lado natural de su pie y, con reflejos,
	## a veces lee la carrera (`_lado_portero_tanda`). Ese lado es el del portero (su izquierda = +1):
	## mirando a −Z su izquierda es +X; mirando a +Z, −X.
	var lz: Dictionary = m._tiro_vivo.get("p", {})
	var sitio := lado(m, lz, gk, 1 if m._arco_propio(gk).z > 0.0 else -1)
	var ref := float(gk["attr"]["ref"])
	var para := false
	if sitio == 0:
		para = absf(cruce.x) < 1.1 and cruce.y < 2.0
	elif signf(cruce.x) == float(sitio):
		var alcance := 1.4 + (float(gk["attr"]["div"]) + ref) * 0.6
		para = absf(cruce.x) < alcance and cruce.y < (1.6 if absf(cruce.x) > 2.3 else 2.1) and m._rng.randf() < 0.62 + ref * 0.3
	if para:
		MotorParada.programar(m, gk, cruce, sitio != 0)
		return
	## Se tira al lado que eligió (y el balón entra o se va por el otro).
	if sitio != 0:
		var lado_anim := "izq" if float(sitio) * m.dir_ataque(bool(gk["es_local"])) > 0.0 else "der"
		m._anim(gk, "estirada_media_%s" % lado_anim, true)
		gk["vel"] = Vector3(float(sitio) * 6.0, 0, 0)
		gk["objetivo"] = Vector3(m.pos(gk).x + float(sitio) * 2.2, 0, m.pos(gk).z)

## LA LECTURA DEL LANZADOR (M-119, 20-10): el portero de la IA se tira más al
## lado natural del pie del que patea (el diestro, a su izquierda = +X; el
## zurdo, al revés) y, según sus reflejos, a veces lee la carrera y va al lado
## bueno. Antes adivinaba 40/40/20 a ciegas.
## `mira`: +1 si el portero mira a −Z (su izquierda es +X, como en la tanda), −1 si mira a +Z. Devuelve el lado en X del mundo.
static func lado(m: MotorJugable, lz: Dictionary, gk: Dictionary, mira := 1) -> int:
	var ref := float((gk.get("attr", {}) as Dictionary).get("ref", 0.5))
	if m._rng.randf() < 0.04 + 0.12 * ref:
		var x := m.vel_balon.x
		return 0 if absf(x) < 0.6 else int(signf(x))
	var natural := (-1 if AnimExtra.es_zurdo(String(lz.get("id", ""))) else 1) * mira
	var r := m._rng.randf()
	return natural if r < 0.46 else (-natural if r < 0.82 else 0)
