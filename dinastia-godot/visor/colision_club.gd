class_name ColisionClub
extends RefCounted
## COLISIÓN DE QUIEN RECORRE EL CLUB A PIE (estadio, edificio del club y galería).
##
## Antes (23-10) el personaje se movía por posición y solo se miraba si su
## CENTRO caía dentro de una zona: el cuerpo se metía en las paredes, los
## muebles «sólidos» (StaticBody3D) no frenaban a nadie porque nada los
## consultaba, y la gente del club se atravesaba. Ahora cada paso se parte en
## trozos cortos y cada trozo comprueba, en este orden:
##   1. que el CUERPO entero (un círculo, no un punto) cabe en las zonas;
##   2. que no toca un mueble o pared con colisión (consulta de física real);
##   3. que no se mete dentro de una persona del personal.
## Si el trozo choca, se prueba a deslizar por cada eje; si tampoco, se para.
## Si ya se empieza dentro de algo (un hueco mal puesto), se permite salir.

## Medio ancho del cuerpo contra paredes y muebles.
const RADIO := 0.3
## Lo que ocupa una persona del personal.
const RADIO_GENTE := 0.38
## Longitud máxima de un trozo de paso (nada se salta una pared fina).
const TROZO := 0.15

static var _forma: CylinderShape3D

## ¿Cabe un círculo de `radio` en `local` sin salir de las zonas de `planta`?
## Una unión de zonas vale: cada punto de control puede estar en una distinta
## (así se cruza una puerta o el paso del túnel al vestuario).
static func cabe(zonas: Array, local: Vector3, planta: int, radio := RADIO) -> bool:
	if TunelVestuario.zona_en(zonas, local, planta).is_empty():
		return false
	for i in 8:
		var a := TAU * float(i) / 8.0
		var q := local + Vector3(cos(a), 0.0, sin(a)) * radio
		if TunelVestuario.zona_en(zonas, q, planta).is_empty():
			return false
	return true

## ¿Toca algo con colisión (mueble, pared, valla…) en `pos` (coordenadas del
## padre de `cuerpo`)? Usa el espacio físico del mundo.
static func toca_mueble(cuerpo: Node3D, pos: Vector3, radio := RADIO) -> bool:
	if cuerpo == null or not cuerpo.is_inside_tree():
		return false
	var mundo := cuerpo.get_world_3d()
	var padre := cuerpo.get_parent() as Node3D
	if mundo == null or padre == null:
		return false
	if _forma == null:
		_forma = CylinderShape3D.new()
		_forma.height = 1.2
	_forma.radius = radio
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _forma
	## De 0,3 a 1,5 m sobre el suelo: el piso no cuenta, un mueble sí.
	q.transform = Transform3D(Basis.IDENTITY, padre.to_global(pos + Vector3(0.0, 0.9, 0.0)))
	q.collide_with_areas = false
	q.collide_with_bodies = true
	return not mundo.direct_space_state.intersect_shape(q, 1).is_empty()

## ¿Se mete `local` dentro de alguien del personal? (`desde`: dónde estaba; si
## ya estaba pegado a esa persona, solo cuenta si se acerca más.)
static func toca_gente(pe: PersonalEstadio, local: Vector3, desde: Vector3, planta: int) -> bool:
	if pe == null:
		return false
	var lim := RADIO + RADIO_GENTE
	for g: Dictionary in pe.gente:
		var n: Node3D = g["nodo"]
		if int(g["planta"]) != planta or not is_instance_valid(n) or not n.visible:
			continue
		var d := Vector2(n.position.x - local.x, n.position.z - local.z).length()
		if d < lim and d < Vector2(n.position.x - desde.x, n.position.z - desde.z).length():
			return true
	return false

## Un punto es pisable si cabe en las zonas, no toca muebles y no pisa a nadie.
## `desfase`: lo que se resta a la posición del cuerpo para tener coordenadas
## del estadio (en la ciudad, el estadio está en `CityBuilder.ESTADIO_EN`).
static func libre(cuerpo: Node3D, pos: Vector3, desde: Vector3, zonas: Array, planta: int,
		desfase: Vector3, pe: PersonalEstadio, ya_dentro: bool) -> bool:
	var local := pos - desfase
	if not cabe(zonas, local, planta):
		return false
	if not ya_dentro and toca_mueble(cuerpo, pos):
		return false
	return not toca_gente(pe, local, desde - desfase, planta)

## Mueve de `desde` a `hasta` por trozos, deslizando por las paredes. Devuelve
## dónde queda (misma altura que `desde`).
static func mover(cuerpo: Node3D, desde: Vector3, hasta: Vector3, zonas: Array, planta: int,
		desfase: Vector3, pe: PersonalEstadio) -> Vector3:
	var pos := desde
	var total := hasta - desde
	total.y = 0.0
	var n := maxi(1, ceili(total.length() / TROZO))
	var paso := total / float(n)
	## Si ya empieza tocando un mueble (hueco mal puesto), puede salir.
	var ya_dentro := toca_mueble(cuerpo, desde)
	for i in n:
		var sig := pos + paso
		if libre(cuerpo, sig, pos, zonas, planta, desfase, pe, ya_dentro):
			pos = sig
			continue
		var px := Vector3(sig.x, pos.y, pos.z)
		var pz := Vector3(pos.x, pos.y, sig.z)
		if absf(paso.x) > 1e-5 and libre(cuerpo, px, pos, zonas, planta, desfase, pe, ya_dentro):
			pos = px
		elif absf(paso.z) > 1e-5 and libre(cuerpo, pz, pos, zonas, planta, desfase, pe, ya_dentro):
			pos = pz
		else:
			break
	return pos
