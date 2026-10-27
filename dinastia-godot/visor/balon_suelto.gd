class_name BalonSuelto
extends Node3D
## UN BALÓN SUELTO EN EL PARQUE (27-10-2026, semana 6 del plan): se patea a pie. Sin física de motor (el suelo de la ciudad no tiene colisión: es una altura,
## `ExploradorCiudad.altura_suelo`): gravedad, bote, rozamiento al rodar y rebote en los bordes del parque. El DT patea al pasar a menos de 0,8 m
## andando (la dirección mezcla hacia dónde va y por dónde le entra el balón); en coche no. Sin azar: nada toca `_rng`.
const RADIO := 0.22
const GRAVEDAD := 18.0
const REBOTE := 0.55
const ROZAMIENTO := 1.4        ## fracción de la velocidad que pierde por segundo al rodar
const ALCANCE := 0.8
const ENFRIAR := 0.3

var jugador: Node3D
var activo := Callable()       ## ¿se puede patear ahora? (el explorador: solo a pie); vacío = siempre
var limites := Rect2(-1e9, -1e9, 2e9, 2e9)
var vel := Vector3.ZERO
var patadas := 0
var _prev := Vector3.INF
var _enfriar := 0.0
var _malla := Node3D.new()

func _ready() -> void:
	name = "BalonSuelto"
	var blanco := StandardMaterial3D.new()
	blanco.albedo_color = Color(0.96, 0.96, 0.94)
	blanco.roughness = 0.5
	var negro := StandardMaterial3D.new()
	negro.albedo_color = Color(0.08, 0.08, 0.1)
	negro.roughness = 0.6
	var esfera := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = RADIO
	sm.height = RADIO * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	esfera.mesh = sm
	esfera.material_override = blanco
	_malla.add_child(esfera)
	## Parches negros (seis, uno por eje) para que se vea que rueda.
	for dir: Vector3 in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var p := MeshInstance3D.new()
		var pm := SphereMesh.new()
		pm.radius = RADIO * 0.38
		pm.height = RADIO * 0.76
		pm.radial_segments = 8
		pm.rings = 4
		p.mesh = pm
		p.material_override = negro
		p.position = dir * RADIO * 0.8
		_malla.add_child(p)
	add_child(_malla)

func _physics_process(dt: float) -> void:
	_patear(dt)
	vel.y -= GRAVEDAD * dt
	position += vel * dt
	var suelo := ExploradorCiudad.altura_suelo(position.x, position.z) + RADIO
	var rodando := false
	if position.y <= suelo:
		position.y = suelo
		if vel.y < 0.0:
			vel.y = -vel.y * REBOTE
			if vel.y < 1.0:
				vel.y = 0.0
		rodando = vel.y == 0.0
	if rodando:
		var f := maxf(0.0, 1.0 - ROZAMIENTO * dt)
		vel.x *= f
		vel.z *= f
		if Vector2(vel.x, vel.z).length() < 0.05:
			vel.x = 0.0
			vel.z = 0.0
	## Rebote en los bordes del parque.
	if position.x < limites.position.x or position.x > limites.end.x:
		position.x = clampf(position.x, limites.position.x, limites.end.x)
		vel.x = -vel.x * REBOTE
	if position.z < limites.position.y or position.z > limites.end.y:
		position.z = clampf(position.z, limites.position.y, limites.end.y)
		vel.z = -vel.z * REBOTE
	## Rueda: gira alrededor del eje perpendicular a su avance.
	var h := Vector2(vel.x, vel.z)
	if h.length() > 0.05:
		_malla.rotate(Vector3(vel.z, 0.0, -vel.x).normalized(), h.length() / RADIO * dt)

func _patear(dt: float) -> void:
	if jugador == null or not is_instance_valid(jugador):
		return
	var p := jugador.global_position
	var vj := Vector3.ZERO
	if _prev != Vector3.INF:
		vj = (p - _prev) / maxf(dt, 0.0001)
		vj.y = 0.0
	_prev = p
	_enfriar = maxf(0.0, _enfriar - dt)
	if activo.is_valid() and not bool(activo.call()):
		return
	var d := Vector2(position.x - p.x, position.z - p.z)
	var vel_j := Vector2(vj.x, vj.z)
	if _enfriar > 0.0 or d.length() > ALCANCE or vel_j.length() < 0.6 or vel_j.length() > 30.0:
		return
	var dir := (d.normalized() * 0.4 + vel_j.normalized() * 0.6).normalized()
	var v := clampf(vel_j.length() * 2.0 + 3.0, 4.0, 13.0)
	vel = Vector3(dir.x * v, 2.5 + v * 0.15, dir.y * v)
	_enfriar = ENFRIAR
	patadas += 1
