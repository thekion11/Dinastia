class_name CamarografosSiguen
extends Node
## LOS CAMARÓGRAFOS SIGUEN LA JUGADA (14-10-2026, pedido: «los NPC cámaras
## deberían seguir la jugada»). Antes miraban siempre al centro del campo,
## clavados. Ahora cada operador gira con su cámara hacia el balón (con la
## inercia de un trípode: no da latigazos), sin pasarse de su abanico; el de
## la banda, además, camina por su carril siguiendo la altura de la jugada,
## como el de la steadicam de la tele.

var balon: Node3D
## [base (Node3D con la cámara y el operador dentro), giro de reposo, carril]
var _puestos: Array = []

const GIRO_MAX := 1.25          ## rad a cada lado de su giro de reposo
const VEL_GIRO := 1.6           ## rad/s, la cabeza del trípode
const CARRIL_Z := 30.0          ## el de la banda va de -30 a 30 m
const VEL_CARRIL := 3.2         ## m/s, caminando con la cámara al hombro

func agregar(base: Node3D, operador: Dictionary) -> void:
	var carril := absf(base.position.x) > 30.0 and absf(base.position.z) < 5.0
	_puestos.append([base, base.rotation.y, carril, operador])

func _process(delta: float) -> void:
	if not is_instance_valid(balon):
		return
	var b := balon.global_position
	for pu: Array in _puestos:
		var base: Node3D = pu[0]
		if not is_instance_valid(base):
			continue
		var anda := false
		if bool(pu[2]):
			var z_obj := clampf(b.z * 0.85, -CARRIL_Z, CARRIL_Z)
			var dz := z_obj - base.position.z
			if absf(dz) > 1.5:
				base.position.z = move_toward(base.position.z, z_obj, VEL_CARRIL * delta)
				anda = true
		var hacia := b - base.global_position
		var giro0: float = pu[1]
		var deseado := atan2(hacia.x, hacia.z)
		var dif := clampf(wrapf(deseado - giro0, -PI, PI), -GIRO_MAX, GIRO_MAX)
		base.rotation.y = rotate_toward(base.rotation.y, giro0 + dif, VEL_GIRO * delta)
		var op: Dictionary = pu[3]
		var ap: AnimationPlayer = op.get("anim")
		if is_instance_valid(ap):
			var quiere := "caminar" if anda and ap.has_animation("caminar") else "parado"
			if ap.has_animation(quiere) and ap.current_animation != quiere:
				ap.play(quiere, 0.3)
