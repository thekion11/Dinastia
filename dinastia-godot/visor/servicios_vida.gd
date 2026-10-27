class_name ServiciosVida
extends Node3D
## POLICÍA, BOMBEROS Y AMBULANCIA CON VIDA (27-10-2026, pieza E, `PLAN_DEL_LUNES.md` §2.2h). Cada hora de juego puede estallar un incidente
## (`IncidentesCiudad.sortear`): el móvil avisa, los vehículos salen de su edificio con luces y sirena por las calles de la rejilla, se
## paran junto al sitio, atienden (el incendio se apaga más despacio si el sector no tiene presión de agua: `redes`) y vuelven al
## parque. Un coche patrulla recorre siempre las calles junto a la comisaría: si el DT cruza un semáforo en ROJO con la policía a
## la vista, le multan (`IncidentesCiudad.MULTA_SEMAFORO` € de la cartera). Los coches del tráfico NO se apartan para dejar pasar a las
## sirenas (queda para la pasada del motor de tráfico).
const V_MAX := 15.0
const FRENA := 3.2
const ACEL := 3.0
const V_PATRULLA := 8.0
const ESC := 2.3
const VISTA_POLICIA := 70.0
const SEPARA := 9.0                         ## metros entre vehículos parados en el sitio

## uso → [posición de salida]: la registra `CiudadExpansion._instalacion` al montar cada edificio (frente de la manzana, ya en la acera).
static var estaciones := {}

static func registrar(uso: String, c: Vector3, w: float, f: float) -> void:
	var p := Vector3(c.x + w * 0.38, 0.2, c.z + f * 0.42)
	var l: Array = estaciones.get(uso, [])
	if not l.has(p):
		l.append(p)
	estaciones[uso] = l

var vida: VidaCiudad
var incidente := {}
var vehiculos: Array[Dictionary] = []
var multas_puestas := 0
var t := 0.0
var _escena: Node3D
var _escena_tipo := ""
var _pos_ant := Vector3.INF
var _cruce_multado := Vector2i(1 << 20, 0)
var _cruces: Dictionary = {}

static func crear(v: VidaCiudad) -> ServiciosVida:
	var s := ServiciosVida.new()
	s.name = "ServiciosVida"
	s.vida = v
	v.expl.add_child(s)
	s._poner_patrulla()
	return s

func _semilla() -> int:
	return vida.mundo.semana + 53 * vida.mundo.anio

func al_cambiar_hora(hora: int, dia: int) -> void:
	if not incidente.is_empty():
		return
	var d := IncidentesCiudad.sortear(_semilla(), dia, hora)
	if d.is_empty():
		return
	var pos: Vector3 = d["pos"]
	var exp: CiudadExpansion = vida.expl.cb.expansion if vida.expl.cb != null else null
	if exp != null and exp.nombre_calle_en(Vector3(pos.x - 11.0, 0, pos.z)) == "":
		return   ## cae fuera de las calles (el núcleo, el río): hoy no pasa nada
	iniciar(String(d["tipo"]), pos)

## Pone en marcha un incidente: aviso, escena y salida de los vehículos. Devuelve false si falta algún edificio o ya hay otro.
func iniciar(tipo: String, pos: Vector3) -> bool:
	if not incidente.is_empty() or not IncidentesCiudad.TIPOS.has(tipo):
		return false
	var acuden: Array = IncidentesCiudad.TIPOS[tipo]["acuden"]
	for uso: String in acuden:
		if not estaciones.has(uso):
			return false
	incidente = IncidentesCiudad.nuevo(tipo, pos)
	match tipo:
		"incendio":
			_escena = IncendioVisual.fuego(self, pos)
		"accidente":
			_escena = IncendioVisual.accidente(self, pos)
			IncendioVisual.cinta(_escena, Vector3(0, 0, 1.5), 9.0)
		_:
			_escena = IncendioVisual.cinta(self, pos, 5.0)
	_escena_tipo = tipo
	for k in acuden.size():
		_despachar(String(acuden[k]), k, pos)   ## cada uno se para SEPARA m detrás del anterior
	if vida != null:
		vida._notificar(Idiomas.t(IncidentesCiudad.aviso(tipo)))
	Sonido.toca("sirena", Sonido.Bus.AMBIENTE)
	return true

func _despachar(uso: String, idx: int, pos: Vector3) -> void:
	var salida: Vector3 = (estaciones[uso] as Array)[0]
	var ruta := IncidentesCiudad.ruta_calles(salida, pos)
	var v := _vehiculo(uso, ruta, true)
	v["parada"] = maxf(IncidentesCiudad.largo_de(ruta) - float(idx) * SEPARA, 1.0)
	v["estado"] = "ida"

## Un vehículo de emergencia con su barra de luces y, si va de servicio, la sirena.
func _vehiculo(uso: String, ruta: PackedVector3Array, servicio: bool) -> Dictionary:
	var ps := load(IncendioVisual.COCHES % String(IncidentesCiudad.MODELO[uso])) as PackedScene
	var nodo: Node3D = ps.instantiate() if ps != null else Node3D.new()
	nodo.scale = Vector3.ONE * ESC
	add_child(nodo)
	var v := {"nodo": nodo, "uso": uso, "ruta": ruta, "s": 0.0, "vel": 0.0, "estado": "ida", "parada": 0.0, "servicio": servicio}
	_barra(v)
	if servicio:
		_sirena(v, true)
	_colocar(v)
	vehiculos.append(v)
	return v

## Barra de luces roja y azul en el techo, con una luz real para cada color.
func _barra(v: Dictionary) -> void:
	var nodo: Node3D = v["nodo"]
	var techo := 1.35
	var mallas := nodo.find_children("*", "MeshInstance3D", true, false)
	if not mallas.is_empty():
		techo = 0.0
		for m: MeshInstance3D in mallas:
			techo = maxf(techo, (m.global_transform * m.get_aabb()).end.y - nodo.global_position.y)
		techo = techo / ESC
	var luces := []
	for k in 2:
		var col := Color(1.0, 0.1, 0.1) if k == 0 else Color(0.15, 0.3, 1.0)
		var mi := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(0.18, 0.08, 0.16)
		mi.mesh = caja
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = mat
		mi.position = Vector3(-0.15 + float(k) * 0.3, techo + 0.05, 0.0)
		mi.name = "Barra%d" % k
		nodo.add_child(mi)
		var luz := OmniLight3D.new()
		luz.light_color = col
		luz.omni_range = 11.0
		luz.light_energy = 0.0
		luz.shadow_enabled = false
		luz.position = mi.position + Vector3(0, 0.3, 0)
		luz.name = "LuzBarra%d" % k
		nodo.add_child(luz)
		luces.append([mat, luz])
	v["luces"] = luces

func _sirena(v: Dictionary, on: bool) -> void:
	var nodo: Node3D = v["nodo"]
	var p := nodo.get_node_or_null("Sirena") as AudioStreamPlayer3D
	if not on:
		if p != null:
			p.stop()
		return
	var banco: Array = Sonido.banco("sirena")
	if p == null and not banco.is_empty() and banco[0] is AudioStreamWAV:
		var st := (banco[0] as AudioStreamWAV).duplicate() as AudioStreamWAV
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = st.data.size() / 2
		p = AudioStreamPlayer3D.new()
		p.name = "Sirena"
		p.stream = st
		p.unit_size = 22.0
		p.max_distance = 220.0
		p.volume_db = linear_to_db(maxf(0.001, float(Sonido.volumen[Sonido.Bus.AMBIENTE]))) - 4.0
		nodo.add_child(p)
	if p != null and Sonido.encendido and not p.playing and p.is_inside_tree():
		p.play()

## El coche patrulla: una vuelta fija por las calles que rodean la comisaría (dos manzanas), siempre en marcha y sin sirena.
func _poner_patrulla() -> void:
	if not estaciones.has("comisaria"):
		return
	var s: Vector3 = (estaciones["comisaria"] as Array)[0]
	var x0 := floorf(s.x / IncidentesCiudad.CELDA) * IncidentesCiudad.CELDA
	var x1 := x0 + IncidentesCiudad.CELDA
	var z1 := roundf((s.z + 4.0) / IncidentesCiudad.CELDA) * IncidentesCiudad.CELDA
	var z0 := z1 - IncidentesCiudad.CELDA * 2.0
	var m0 := Vector3(x0, 0.2, (z0 + z1) * 0.5)
	var ruta := IncidentesCiudad.redondear(PackedVector3Array([m0, Vector3(x0, 0.2, z0), Vector3(x1, 0.2, z0), Vector3(x1, 0.2, z1), Vector3(x0, 0.2, z1), m0]), 14.0)
	var v := _vehiculo("comisaria", ruta, false)
	v["estado"] = "patrulla"
	v["vel"] = V_PATRULLA
	v["luces_on"] = false

func _process(delta: float) -> void:
	t += delta
	var i := vehiculos.size() - 1
	while i >= 0:
		if not _mover(vehiculos[i], delta):
			var n: Node3D = vehiculos[i]["nodo"]
			if is_instance_valid(n):
				n.queue_free()
			vehiculos.remove_at(i)
		i -= 1
	if incidente.is_empty():
		return
	var ritmo := 1.0
	if String(incidente["tipo"]) == "incendio":
		ritmo = IncidentesCiudad.ritmo_fuego(_hay_presion(incidente["pos"]))
	var fase := IncidentesCiudad.avanzar(incidente, delta, ritmo)
	if _escena_tipo == "incendio":
		IncendioVisual.animar(_escena, t, IncidentesCiudad.pendiente(incidente) if fase != "camino" else 1.0)
	elif _escena_tipo == "accidente":
		IncendioVisual.parpadeo(_escena, t)
	if fase == "resuelto":
		_resolver()

func _hay_presion(pos: Vector3) -> bool:
	var red: RedesCiudadVista = vida._redes() if vida != null else null
	if red == null or red.modelo == null:
		return true
	return bool(red.modelo.presion.get(RedesCiudad.sector_en(pos.x, pos.z), true))

func _resolver() -> void:
	var tipo := String(incidente["tipo"])
	if vida != null:
		vida._notificar(Idiomas.t(IncidentesCiudad.resuelto(tipo)))
		if tipo == "incendio":
			if _hay_presion(incidente["pos"]):
				vida._titular("Los bomberos apagan un incendio en el centro", "Sin heridos: el fuego no pasó de la acera.", "bien")
			else:
				vida._titular("Un incendio tarda en apagarse por falta de agua", "Los bomberos esperaron presión en la red del sector: «hay que arreglar las tuberías».")
	for v in vehiculos:
		if bool(v["servicio"]) and v["estado"] != "vuelta":
			var r: PackedVector3Array = v["ruta"]
			var inv := PackedVector3Array()
			for k in range(r.size() - 1, -1, -1):
				inv.append(r[k])
			v["ruta"] = inv
			v["s"] = IncidentesCiudad.largo_de(inv) - float(v["s"])
			v["estado"] = "vuelta"
			v["parada"] = IncidentesCiudad.largo_de(inv)
			_luces(v, false)
			_sirena(v, false)
	if _escena != null and is_instance_valid(_escena):
		_escena.queue_free()
	_escena = null
	_escena_tipo = ""
	incidente = {}

## Avanza un vehículo. Devuelve false cuando ya está de vuelta en el parque (hay que quitarlo).
func _mover(v: Dictionary, delta: float) -> bool:
	var ruta: PackedVector3Array = v["ruta"]
	var largo := IncidentesCiudad.largo_de(ruta)
	var s := float(v["s"])
	var vel := float(v["vel"])
	match String(v["estado"]):
		"patrulla":
			vel = V_PATRULLA
			s = fposmod(s + vel * delta, largo)
		"atiende":
			vel = 0.0
		_:
			var resta := float(v["parada"]) - s
			var objetivo := V_MAX
			if v["estado"] == "ida":
				objetivo = minf(objetivo, sqrt(2.0 * FRENA * maxf(resta, 0.0)) + 0.4)
			else:
				objetivo = minf(objetivo * 0.7, sqrt(2.0 * FRENA * maxf(resta, 0.0)) + 0.4)
			var antes := float((IncidentesCiudad.punto_en(ruta, s))[1])
			var despues := float((IncidentesCiudad.punto_en(ruta, s + 12.0))[1])
			objetivo = minf(objetivo, lerpf(V_MAX, 6.0, clampf(absf(angle_difference(antes, despues)) / 0.8, 0.0, 1.0)))
			vel = move_toward(vel, objetivo, (ACEL if objetivo > vel else FRENA) * delta)
			s = minf(s + vel * delta, float(v["parada"]))
			if resta <= 0.05:
				if v["estado"] == "vuelta":
					return false
				v["estado"] = "atiende"
				vel = 0.0
				IncidentesCiudad.llega(incidente)
	v["s"] = s
	v["vel"] = vel
	_colocar(v)
	var en_servicio: bool = bool(v["servicio"]) and v["estado"] != "vuelta"
	_luces(v, en_servicio)
	if v["estado"] == "atiende":
		_sirena(v, false)
	return true

func _colocar(v: Dictionary) -> void:
	var nodo: Node3D = v["nodo"]
	var pr := IncidentesCiudad.punto_en(v["ruta"], float(v["s"]))
	nodo.position = pr[0]
	nodo.rotation.y = lerp_angle(nodo.rotation.y, float(pr[1]), 0.25 if float(v["s"]) > 0.0 else 1.0)

## Barra encendida: rojo y azul se alternan cuatro veces por segundo.
func _luces(v: Dictionary, on: bool) -> void:
	var fase := fmod(t * 4.0, 1.0) < 0.5
	var k := 0
	for par: Array in v.get("luces", []):
		var enc := on and (fase == (k == 0))
		(par[0] as StandardMaterial3D).emission_energy_multiplier = 3.0 if enc else 0.0
		(par[1] as OmniLight3D).light_energy = 2.5 if enc else 0.0
		k += 1

# ==================================================================== MULTAS

## La ve la policía: algún coche de la comisaría a menos de `VISTA_POLICIA` m (el patrulla, o el que va de servicio).
func policia_cerca(pos: Vector3) -> bool:
	for v in vehiculos:
		if v["uso"] == "comisaria" and (v["nodo"] as Node3D).position.distance_to(pos) < VISTA_POLICIA:
			return true
	return false

## Lo llama el explorador cada fotograma que conduce el DT: ¿cruza en rojo (no ámbar) a más de 12 km/h con la policía delante?
func vigilar(pos: Vector3, vel_ms: float) -> void:
	var exp: CiudadExpansion = vida.expl.cb.expansion if vida.expl.cb != null else null
	if exp == null or exp.semaforos == null:
		return
	if _cruces.is_empty():
		for p: Vector3 in exp.cruces_semaforo:
			_cruces[Vector2i(roundi(p.x / IncidentesCiudad.CELDA), roundi(p.z / IncidentesCiudad.CELDA))] = p
	vigilar_en(pos, vel_ms, exp.semaforos)

func vigilar_en(pos: Vector3, vel_ms: float, sem: Semaforos) -> void:
	var dir := Vector3.ZERO if _pos_ant == Vector3.INF else pos - _pos_ant
	_pos_ant = pos
	var clave := Vector2i(roundi(pos.x / IncidentesCiudad.CELDA), roundi(pos.z / IncidentesCiudad.CELDA))
	if not _cruces.has(clave):
		return
	var c: Vector3 = _cruces[clave]
	if absf(pos.x - c.x) > 7.0 or absf(pos.z - c.z) > 7.0:
		if absf(pos.x - c.x) > 16.0 or absf(pos.z - c.z) > 16.0:
			_cruce_multado = Vector2i(1 << 20, 0)   ## ya salió del cruce: el siguiente en rojo vuelve a multar
		return
	if clave == _cruce_multado or vel_ms * 3.6 < 12.0 or dir.length() < 0.001:
		return
	var eje := 0 if absf(dir.z) > absf(dir.x) else 1
	if sem.estado(eje) != "r" or not policia_cerca(pos):
		return
	_cruce_multado = clave
	multar(IncidentesCiudad.MULTA_SEMAFORO)

## Cobra la multa de la cartera del DT (efectivo y, si no alcanza, la tarjeta); si no puede pagarla, queda anotada.
func multar(importe: int) -> String:
	multas_puestas += 1
	var m: Mundo = vida.mundo
	var via := ""
	var cartera: CarteraDT = m.roles.cartera if m.roles != null else null
	if cartera != null:
		var dia := CarteraDT.clave_dia(m.anio, m.semana, m.reloj.dia)
		var r := cartera.cobrar(m.roles, importe, "Multa de tráfico", dia)
		via = String(r["via"])
	vida.expl.multas += 1
	Sonido.toca("sirena", Sonido.Bus.AMBIENTE)
	if via != "":
		vida._notificar(Idiomas.t("🚓 Multa de %d € por saltarte un semáforo en rojo (pagada en %s).") % [importe, Idiomas.t(via)])
	else:
		vida._notificar(Idiomas.t("🚓 Multa de %d € por saltarte un semáforo en rojo: no pudiste pagarla y queda anotada.") % importe)
	return via
