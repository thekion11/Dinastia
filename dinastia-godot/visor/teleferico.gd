class_name Teleferico
extends Node3D
## EL TELEFÉRICO DEL CERRO (27-10-2026, pedido del dueño): la estación de abajo está al este de la ciudad (en el llano, plana),
## cinco torres suben por la ladera y la estación de arriba está en la cima del cerro (`CityBuilder.MONTE_*`). Dos cabinas van y
## vienen por cables paralelos, se cruzan a mitad de camino y esperan unos segundos en cada estación (`CICLO` s reales).
## E en la estación de abajo te sube de verdad: el paseo pasa 12 minutos de juego y apareces en el MIRADOR (`MiradorCerro`);
## E en la estación de arriba te baja. El mapa del transporte (`MapaTransporte`) lo dibuja como la línea T.

const BASE_XZ := Vector2(1400.0, 560.0)
const CIMA_XZ := Vector2(2230.0, 1230.0)
const VIAJE := 120.0                         ## segundos reales de una subida
const ESPERA := 10.0
const CICLO := (VIAJE + ESPERA) * 2.0
const ALTO_CABLE := 11.0
const N_TORRES := 8

var base := Vector3.ZERO                     ## suelo de la estación de abajo
var cima := Vector3.ZERO                     ## suelo de la estación de arriba
var puntos: PackedVector3Array = []          ## cable: estación de abajo, torres, estación de arriba
var mirador: MiradorCerro
var cabinas: Array[Node3D] = []
var _largos: PackedFloat32Array = []
var _t := 0.0
var _balanceo := [{"th": 0.0, "om": 0.0, "d": 0.0}, {"th": 0.0, "om": 0.0, "d": 0.0}]
var cuenta := {}

static func montar(b: CityBuilder) -> Teleferico:
	var t := Teleferico.new()
	t.name = "Teleferico"
	b.add_child(t)
	t._construir(b)
	return t

func datos() -> Dictionary:
	return {"nombre": "Teleférico del Cerro", "base": base, "cima": cima, "color": Color(0.95, 0.6, 0.1)}

func _suelo(b: CityBuilder, xz: Vector2) -> Vector3:
	return Vector3(xz.x, b.altura_en(xz.x, xz.y), xz.y)

func _caja(b: CityBuilder, pos: Vector3, tam: Vector3, mat: Material, giro: float = 0.0) -> void:
	var mi := b._caja_en(pos, tam, mat, giro)
	b.remove_child(mi)
	mi.position = pos
	add_child(mi)

func _tubo(p: Vector3, q: Vector3, r: float, mat: Material) -> void:
	var d := q - p
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = d.length()
	cm.radial_segments = 6
	cm.rings = 0
	mi.mesh = cm
	mi.material_override = mat
	mi.position = (p + q) * 0.5
	mi.basis = Basis(Quaternion(Vector3.UP, d.normalized()))
	add_child(mi)

func _rotulo(pos: Vector3, texto: String, tam: float, giro: float = 0.0) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font_size = 64
	l.pixel_size = tam
	l.outline_size = 10
	l.position = pos
	l.rotation.y = giro
	add_child(l)

func _estacion(b: CityBuilder, suelo: Vector3, giro: float, nombre: String, mats: Dictionary) -> void:
	## Edificio de la estación (cuerpo, tejado inclinado, rueda del cable) con su rótulo; `giro` orienta la fachada.
	var base_n := Node3D.new()
	base_n.position = suelo
	base_n.rotation.y = giro
	add_child(base_n)
	for par in [[Vector3(0, 0.6, 0), Vector3(22, 1.2, 12), mats["losa"]], [Vector3(0, 3.4, 0), Vector3(16, 5.6, 9), mats["muro"]],
			[Vector3(0, 6.6, 0), Vector3(18, 0.7, 11), mats["tejado"]], [Vector3(0, 8.6, 0), Vector3(1.2, 4.0, 1.2), mats["acero"]]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = par[1]
		mi.mesh = bm
		mi.material_override = par[2]
		mi.position = par[0]
		base_n.add_child(mi)
	var rueda := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 2.6
	cm.bottom_radius = 2.6
	cm.height = 0.8
	rueda.mesh = cm
	rueda.material_override = mats["acero"]
	rueda.rotation.x = PI * 0.5
	rueda.position = Vector3(0, ALTO_CABLE - 0.8, -4.5)
	base_n.add_child(rueda)
	## Andén cubierto delante, con marquesina sobre cuatro columnas, y el rótulo grande sobre la fachada.
	for par in [[Vector3(0, 0.25, 9.8), Vector3(22, 0.5, 8), mats["losa"]], [Vector3(0, 5.4, 9.8), Vector3(23, 0.4, 8.8), mats["tejado"]],
			[Vector3(0, 9.4, 2.4), Vector3(17, 2.2, 0.4), mats["acero"]]]:
		var mi2 := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = par[1]
		mi2.mesh = bm2
		mi2.material_override = par[2]
		mi2.position = par[0]
		base_n.add_child(mi2)
	for cx: float in [-10.0, 10.0]:
		for cz: float in [6.4, 13.2]:
			var col := MeshInstance3D.new()
			var bc := BoxMesh.new()
			bc.size = Vector3(0.5, 5.0, 0.5)
			col.mesh = bc
			col.material_override = mats["acero"]
			col.position = Vector3(cx, 2.9, cz)
			base_n.add_child(col)
	var l := Label3D.new()
	l.text = nombre
	l.font_size = 64
	l.pixel_size = 0.03
	l.outline_size = 12
	l.position = Vector3(0, 9.4, 2.7)
	base_n.add_child(l)
	## Escalera lateral del suelo (-0,2) a la losa (1,2): 6 peldaños que `EscaleraVida` hace subir y bajar a la gente.
	for s in 6:
		var alto_s := 1.4 * float(s + 1) / 6.0
		var peld := MeshInstance3D.new()
		var bp := BoxMesh.new()
		bp.size = Vector3(0.4, alto_s, 2.6)
		peld.mesh = bp
		peld.material_override = mats["losa"]
		peld.position = Vector3(13.4 - 0.4 * float(s), -0.2 + alto_s * 0.5, 0.0)
		base_n.add_child(peld)
	EscaleraVida.registrar(b, suelo + base_n.basis * Vector3(13.6, -0.2, 0), suelo + base_n.basis * Vector3(11.4, 1.2, 0), 6)

func _construir(b: CityBuilder) -> void:
	base = _suelo(b, BASE_XZ)
	cima = _suelo(b, CIMA_XZ)
	cima.y += 0.5
	var mats := {"losa": b._mat_simple(Color(0.62, 0.62, 0.6), 0.9), "muro": b._mat_simple(Color(0.86, 0.84, 0.78), 0.8),
		"tejado": b._mat_simple(Color(0.8, 0.32, 0.12), 0.7), "acero": b._mat_simple(Color(0.34, 0.36, 0.38), 0.5)}
	var dir := Vector3(cima.x - base.x, 0, cima.z - base.z).normalized()
	var giro := atan2(dir.x, dir.z)                   ## la estación mira hacia donde sube el cable
	_estacion(b, base + Vector3(0, 0.2, 0), giro + PI, "TELEFÉRICO DEL CERRO", mats)
	## La estación de arriba es una losa plana en la ladera (sobre pilotes) donde apoya el mirador.
	_caja(b, cima + Vector3(0, -6.0, 0), Vector3(46, 12.0, 34), mats["losa"], giro)
	_estacion(b, cima + Vector3(0, 0.1, 0), giro, "CIMA · MIRADOR", mats)
	## El cable: de la rueda de abajo a la de arriba, con torres cuya cabeza nunca queda por debajo del terreno.
	var cable_base := base + Vector3(0, ALTO_CABLE, 0) + dir * 4.5      ## las ruedas miran la una a la otra
	var cable_cima := cima + Vector3(0, ALTO_CABLE, 0) - dir * 4.5
	puntos = PackedVector3Array([cable_base])
	for k in range(1, N_TORRES + 1):
		var f := float(k) / float(N_TORRES + 1)
		var p := cable_base.lerp(cable_cima, f)
		var suelo_p := b.altura_en(p.x, p.z)
		p.y = maxf(p.y, suelo_p + ALTO_CABLE + 4.0)
		puntos.append(p)
		TelefericoPaisaje.torre(self, b, p, giro, mats["acero"])
	puntos.append(cable_cima)
	var lateral := Vector3(dir.z, 0, -dir.x) * 2.5
	for lado: float in [-1.0, 1.0]:
		for i in puntos.size() - 1:
			_tubo(puntos[i] + lateral * lado, puntos[i + 1] + lateral * lado, 0.07, mats["acero"])
	_largos = PackedFloat32Array([0.0])
	for i in puntos.size() - 1:
		_largos.append(_largos[i] + puntos[i].distance_to(puntos[i + 1]))
	## Las dos cabinas (una por cable): rojas con cristal.
	var roja := b._mat_simple(Color(0.75, 0.15, 0.12), 0.4)
	var vid := b._mat_simple(Color(0.2, 0.3, 0.4), 0.1)
	for lado2 in 2:
		var cab := Node3D.new()
		add_child(cab)
		for par in [[Vector3(0, -2.4, 0), Vector3(3.4, 0.3, 2.6), roja], [Vector3(0, -3.4, 0), Vector3(3.4, 1.9, 2.6), vid], [Vector3(0, -4.6, 0), Vector3(3.5, 0.5, 2.7), roja],
				[Vector3(0, -2.0, 0), Vector3(0.18, 2.0, 0.18), mats["acero"]]]:
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = par[1]
			mi.mesh = bm
			mi.material_override = par[2]
			mi.position = par[0]
			cab.add_child(mi)
		cab.rotation.y = giro + PI * 0.5
		cab.scale = Vector3.ONE * 1.8                 ## grandes: se ven desde la ciudad
		cabinas.append(cab)
	TelefericoPaisaje.montar(self, b, base, cima)
	mirador = MiradorCerro.new()
	mirador.configurar(self, b, giro)
	b.puntos_clic.append({"k": "tele_base", "n": "Teleférico: subir al Cerro", "pos": base + dir * -9.0, "estado": "ciudad", "radio": 22.0, "alcance": 8.0})
	cuenta["torres"] = N_TORRES
	cuenta["largo"] = _largos[_largos.size() - 1]
	_poner_cabinas(0.0)

## Dónde está el punto de la cabina a `d` metros del arranque, sobre el cable del lado `lado` (-1 / 1).
func _en_cable(d: float, lado: float) -> Vector3:
	var largo := _largos[_largos.size() - 1]
	d = clampf(d, 0.0, largo)
	var i := 0
	while i < _largos.size() - 2 and _largos[i + 1] < d:
		i += 1
	var f := (d - _largos[i]) / maxf(_largos[i + 1] - _largos[i], 0.01)
	var dir := Vector3(cima.x - base.x, 0, cima.z - base.z).normalized()
	return puntos[i].lerp(puntos[i + 1], f) + Vector3(dir.z, 0, -dir.x) * 2.5 * lado

## Fracción (0..1) del recorrido de la cabina que sale de abajo en el instante `t` del ciclo (sube, espera, baja, espera).
## Perfil quíntico (27-10-2026, pieza F-4): velocidad Y aceleración nulas al arrancar y al llegar, antes cúbico (la aceleración
## saltaba al salir de la estación).
static func avance(t: float) -> float:
	var u := fposmod(t, CICLO)
	if u < VIAJE:
		return _quintico(u / VIAJE)
	if u < VIAJE + ESPERA:
		return 1.0
	if u < 2.0 * VIAJE + ESPERA:
		return 1.0 - _quintico((u - VIAJE - ESPERA) / VIAJE)
	return 0.0

static func _quintico(k: float) -> float:
	return k * k * k * (10.0 - 15.0 * k + 6.0 * k * k)

## Segunda derivada de `avance` respecto al tiempo (por segundo²): lo que acelera la cabina que sube, con signo.
static func avance_acel(t: float) -> float:
	var u := fposmod(t, CICLO)
	if u < VIAJE:
		var k := u / VIAJE
		return (60.0 * k - 180.0 * k * k + 120.0 * k * k * k) / (VIAJE * VIAJE)
	if u >= VIAJE + ESPERA and u < 2.0 * VIAJE + ESPERA:
		var k2 := (u - VIAJE - ESPERA) / VIAJE
		return -(60.0 * k2 - 180.0 * k2 * k2 + 120.0 * k2 * k2 * k2) / (VIAJE * VIAJE)
	return 0.0

func _poner_cabinas(t: float) -> void:
	var largo := _largos[_largos.size() - 1]
	var f := avance(t)
	cabinas[0].position = _en_cable(largo * f, -1.0)
	cabinas[1].position = _en_cable(largo * (1.0 - f), 1.0)

## BALANCEO (27-10-2026): cada cabina cuelga de su pinza como un péndulo de `LARGO_PERIODO` m (T ≈ 5,7 s) amortiguado: la
## aceleración a lo largo del cable la inclina hacia atrás al arrancar y hacia delante al frenar, y al pasar por una torre
## recibe un pequeño tirón que se apaga solo; además, un vaivén lateral muy suave. `th` es el ángulo hacia atrás (rad).
const COLGADO := 8.0
const AMORTIGUA := 0.35
const LIMITE_BALANCEO := 0.12

func _balancear(t: float, delta: float) -> void:
	var largo := _largos[_largos.size() - 1]
	var f_acel := avance_acel(t) * largo
	var d0 := largo * avance(t)
	for i in 2:
		var d := d0 if i == 0 else largo - d0
		var a_cable := f_acel if i == 0 else -f_acel
		var sw: Dictionary = _balanceo[i]
		var pasada := 0.0
		for q in range(1, _largos.size() - 1):
			if (float(sw["d"]) - _largos[q]) * (d - _largos[q]) < 0.0:
				pasada = 0.03 * signf(d - float(sw["d"]))
		sw["d"] = d
		var th := float(sw["th"])
		var om := float(sw["om"]) + pasada
		var paso := minf(delta, 0.05)
		om += (a_cable / COLGADO - 9.8 / COLGADO * th - AMORTIGUA * om) * paso
		th = clampf(th + om * paso, -LIMITE_BALANCEO, LIMITE_BALANCEO)
		sw["th"] = th
		sw["om"] = om
		cabinas[i].rotation.z = th
		cabinas[i].rotation.x = sin(t * 0.7 + float(i) * 2.4) * 0.012

func _process(delta: float) -> void:
	_t += delta
	_poner_cabinas(_t)
	_balancear(_t, delta)

## E en una estación del teleférico: sube al mirador o baja a la ciudad (con fundido y 12 minutos de juego).
static func usar(e, k: String) -> bool:
	if e.cb == null or e.cb.expansion == null or e.cb.expansion.tele_nodo == null:
		return false
	var t: Teleferico = e.cb.expansion.tele_nodo
	if k == "tele_base":
		if e.modo != "pie" or e.estado != "calle":
			e._aviso.text = Idiomas.t("Deja el coche y sube a pie.")
			return true
		t.mirador.entrar(e)
		return true
	if k == "tele_cima":
		t.mirador.salir(e)
		return true
	if k == "tele_mirar":
		t.mirador.mirar(e)
		return true
	return false
