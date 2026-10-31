class_name AparcarCoche
extends RefCounted
## APARCAR Y BAJARSE DEL COCHE (31-10-2026, mejora D; `docs/04_auditorias/coches_31_10.md`). Antes el modo
## (coche / a pie) se fijaba al empezar el paseo. Ahora, con F:
##  · en coche y parado (menos de 5 km/h): te bajas. El coche se queda aparcado donde estaba (sólido: nadie
##    lo atraviesa, con sus daños) y sigues a pie, a un lado de la puerta del conductor;
##  · a pie y junto a tu coche aparcado (menos de 3,5 m): te subes y sigues conduciendo con el mismo rumbo.
## Todo ocurre en el MISMO explorador (la vida, el reloj, el prólogo y el móvil siguen enganchados): solo se
## cambia el cuerpo y el modo. El coche aparcado vive mientras dura el paseo.

const VEL_MAX_BAJAR := 1.4      ## m/s (~5 km/h)
const DIST_SUBIR := 3.5

## F: bajarse o subirse. Devuelve el aviso para el jugador ("" si no hizo nada).
static func alternar(e: ExploradorCiudad) -> String:
	if e.estado != "calle":
		return ""
	if e.modo == "coche":
		if absf(e.vel) > VEL_MAX_BAJAR:
			return Idiomas.t("Para el coche para bajarte (F).")
		bajar(e)
		return Idiomas.t("🅿️ Coche aparcado. F junto a él para volver a subir.")
	var a := aparcado(e)
	if a == null:
		return ""
	if Vector2(a.position.x - e.cuerpo.position.x, a.position.z - e.cuerpo.position.z).length() > DIST_SUBIR:
		return Idiomas.t("Tu coche está aparcado a %d m.") % roundi(a.position.distance_to(e.cuerpo.position))
	subir(e)
	return ""

static func aparcado(e: ExploradorCiudad) -> Node3D:
	if not e.has_meta("coche_aparcado"):
		return null
	var a: Variant = e.get_meta("coche_aparcado")
	return a as Node3D if is_instance_valid(a) else null

## Te bajas: el cuerpo del coche se queda aparcado (y sólido) y tú sales a pie por la izquierda.
static func bajar(e: ExploradorCiudad) -> void:
	var coche := e.cuerpo
	var rumbo := e.rumbo
	var pos := coche.position
	e.remove_child(coche)
	e.add_child(coche)   ## sigue colgado del explorador, pero ya no es «el cuerpo»
	coche.name = "CocheAparcado"
	e.set_meta("coche_aparcado", coche)
	var circ: Array = []
	for c: Vector3 in e._puntos_forma(pos, rumbo):
		var v := Vector3(c.x, c.z, ExploradorCiudad.RADIO_COCHE)
		var k := Vector2i(floori(c.x / ExploradorCiudad.CELDA_CIRC), floori(c.z / ExploradorCiudad.CELDA_CIRC))
		if not e._rej_circ.has(k):
			e._rej_circ[k] = []
		(e._rej_circ[k] as Array).append(v)
		circ.append([k, v])
	e.set_meta("circulos_aparcado", circ)
	e.set_meta("rumbo_aparcado", rumbo)
	if e._motor_sonido != null:   ## el motor se apaga al bajar (se vuelve a crear al conducir)
		e._motor_sonido.queue_free()
		e._motor_sonido = null
	_cambiar_cuerpo(e, "pie", pos + Vector3(cos(rumbo), 0, -sin(rumbo)) * 2.2, rumbo)

## Te subes: el coche aparcado vuelve a ser tu cuerpo y deja de ser un obstáculo.
static func subir(e: ExploradorCiudad) -> void:
	var coche := aparcado(e)
	if coche == null:
		return
	for par: Array in e.get_meta("circulos_aparcado", []):
		(e._rej_circ.get(par[0], []) as Array).erase(par[1])
	e.remove_meta("coche_aparcado")
	e.remove_meta("circulos_aparcado")
	var pie := e.cuerpo
	e.modo = "coche"
	e.cuerpo = coche
	coche.name = "Cuerpo"
	e.rumbo = float(e.get_meta("rumbo_aparcado", e.rumbo))
	e.vel = 0.0
	e._anim = null   ## el coche no tiene esqueleto
	pie.queue_free()
	_avisar_trafico(e)

static func _cambiar_cuerpo(e: ExploradorCiudad, modo: String, pos: Vector3, rumbo: float) -> void:
	e.modo = modo
	e.vel = 0.0
	e.cuerpo = e._crear_cuerpo()
	e.add_child(e.cuerpo)
	e.cuerpo.position = e.buscar_libre(pos)
	e.rumbo = rumbo
	_avisar_trafico(e)

static func _avisar_trafico(e: ExploradorCiudad) -> void:
	if e.trafico != null:
		e.trafico.jugador = e.cuerpo
		e.trafico.jugador_huella = Vector2(ExploradorCiudad.RADIO_COCHE, ExploradorCiudad.SEP_COCHE + ExploradorCiudad.RADIO_COCHE) \
			if e.modo == "coche" else Vector2(ExploradorCiudad.RADIO_PIE, ExploradorCiudad.RADIO_PIE) * 0.6
