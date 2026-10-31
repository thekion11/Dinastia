class_name AtropelloCiudad
extends RefCounted
## EL ATROPELLO CON REACCIÓN (31-10-2026, mejora F del coche; `docs/04_auditorias/coches_31_10.md`): antes el
## peatón era un obstáculo sólido más. Ahora, si el golpe que multa (más de 25 km/h contra algo que se mueve)
## es contra una persona, esta salta a un lado y se queda un momento quieta, aturdida pero sin daño. Además:
## la multa sube a 150 €, el móvil avisa y, una vez por semana, sale en La Tribuna. Los vecinos de alrededor
## se asustan (`TraficoCiudad.asustar`).

const MULTA := 150
const SALTO := 1.4          ## metros que se aparta, de lado
const ATURDIDO := 2.0       ## segundos quieto

## El peatón con el que choca el coche ahora mismo (a menos de `alcance` del morro), o vacío.
static func peaton_delante(e: ExploradorCiudad, alcance := 2.6) -> Dictionary:
	if e == null or e.trafico == null or e.cuerpo == null:
		return {}
	var morro := e.cuerpo.position + Vector3(sin(e.rumbo), 0, cos(e.rumbo)) * 2.0 * signf(e.vel if e.vel != 0.0 else 1.0)
	var mejor: Dictionary = {}
	var md := alcance * alcance
	for v: Dictionary in e.trafico._vehiculos:
		if not bool(v.get("peaton", false)) or not is_instance_valid(v["nodo"]):
			continue
		var p: Vector3 = (v["nodo"] as Node3D).position
		var d := Vector2(p.x - morro.x, p.z - morro.z).length_squared()
		if d < md:
			md = d
			mejor = v
	return mejor

## La reacción del peatón: se aparta de un salto hacia el lado contrario al coche y se queda aturdido.
static func reaccionar(e: ExploradorCiudad, v: Dictionary) -> void:
	var nodo: Node3D = v["nodo"]
	var lado := Vector3(cos(e.rumbo), 0, -sin(e.rumbo))
	if lado.dot(nodo.position - e.cuerpo.position) < 0.0:
		lado = -lado
	nodo.position += lado * SALTO
	e.trafico.asustar(nodo.position, 10.0)   ## los de alrededor se asustan (antes de aturdirlo: el susto quita la espera)
	v["susto"] = 0.0
	v["espera"] = ATURDIDO
	v["pausa"] = true
	e.trafico._animar(v, "parado")

## Cobra la multa del atropello y anota el titular (una vez por semana). Devuelve el aviso para el móvil.
static func multar(vida: VidaCiudad) -> String:
	var m := vida.mundo
	var via := ""
	if m.roles != null and m.roles.cartera != null:
		via = String(m.roles.cartera.cobrar(m.roles, MULTA, "Multa por atropello", CarteraDT.clave_dia(m.anio, m.semana, m.reloj.dia))["via"])
	var clave := m.anio * 100 + m.semana
	if vida._titular_atropello != clave:
		vida._titular_atropello = clave
		vida._titular("El DT golpea a un peatón con su coche", "El vecino, ileso pero asustado. La policía le impone una multa de 150 euros.")
	if via != "":
		return Idiomas.t("🚓 Has golpeado a un peatón (ileso): multa de %d € (pagada en %s).") % [MULTA, Idiomas.t(via)]
	return Idiomas.t("🚓 Has golpeado a un peatón (ileso): multa de %d €, que queda anotada.") % MULTA
