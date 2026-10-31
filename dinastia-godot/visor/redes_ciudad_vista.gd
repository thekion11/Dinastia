class_name RedesCiudadVista
extends Node3D
## EL DIBUJO DE LAS REDES (27-10-2026). El estado vive en `RedesCiudad` (nucleo); aquí se levantan
## las instalaciones y se enseña lo que dice el modelo:
##  · LUZ: línea de alta tensión (torres y cables) del parque eólico a la subestación principal,
##    la central de respaldo y, en cada sector, transformadores en la acera con una lámpara
##    verde (hay corriente) o roja (corte). Las farolas bajan con la fracción de ciudad sin luz.
##  · AGUA: potabilizadora al oeste con su tubería al depósito de siempre, e hidrantes en las aceras.
##  · DRENAJE: sumideros en los bordillos, tapas de alcantarilla en la calzada y la depuradora; un
##    sector desbordado se cubre con una lámina de agua.
##  · GAS: cuatro surtidores bajo la marquesina de cada gasolinera (la pantalla se apaga sin luz) y un
##    punto «Repostar» en `puntos_clic` (E, ver `VidaCiudad.usar_surtidor`).

const SUELO := 0.32
const SUB := Vector3(-1450, 0, -300)         ## subestación principal
const CENTRAL := Vector3(-1450, 0, -520)     ## central de respaldo
const POTAB := Vector3(-1450, 0, 420)        ## potabilizadora
const DEPUR := Vector3(-1450, 0, 760)        ## depuradora
const DEPOSITO := Vector3(-990, 0, 440)      ## el depósito de `_deposito_agua`
const SEPARACION_TORRES := 90.0

var modelo: RedesCiudad
var e: CiudadExpansion
var b: CityBuilder
var bocas: Array = []                        ## [{pos, sector}] tapas por las que se baja al subsuelo
var surtidores: Array = []                   ## [{id, pos, sector, pantalla}]
var cuenta := {}
var _lamparas := {}                          ## sector -> material de la lámpara de sus transformadores
var _cuadrillas := {}                        ## sector -> camión y conos de la cuadrilla (solo con una avería abierta)
var _aguas := {}                             ## sector -> lámina de inundación
var _gris: StandardMaterial3D
var _acero: StandardMaterial3D

static func crear(exp: CiudadExpansion, semilla: int = 1) -> RedesCiudadVista:
	var v := RedesCiudadVista.new()
	v.name = "Redes"
	v.e = exp
	v.b = exp.b
	v.modelo = RedesCiudad.new(semilla)
	exp.b.add_child(v)
	v.montar()
	return v

func montar() -> void:
	_gris = b._mat_simple(Color(0.58, 0.6, 0.62), 0.7)
	_acero = b._mat_simple(Color(0.36, 0.38, 0.4), 0.45)
	_calles()
	_subestacion()
	_central()
	_potabilizadora()
	_depuradora()
	_alta_tension()
	_edificios()
	_gasolineras()
	_inundaciones()
	refrescar()

# ============================================================================ CALLES

func _sitio(p: Vector3, alto: float = 0.0) -> Vector3:
	return Vector3(p.x, b.altura_en(p.x, p.z) + alto, p.z)

## Lo que se ve en cada calle: hidrantes, sumideros, tapas y transformadores.
func _calles() -> void:
	var tapas: Array[Transform3D] = []
	var rejillas: Array[Transform3D] = []
	var hidrantes: Array[Transform3D] = []
	var cajas: Array[Transform3D] = []
	var por_sector := {}                     ## sector -> lámparas de transformador
	var candidatas: Array = []
	var i := 0
	for t: Dictionary in e.tramos:
		i += 1
		if bool(t["puente"]):
			continue
		var a: Vector3 = t["a"]
		var c: Vector3 = t["b"]
		var ancho: float = t["ancho"]
		var vertical := absf(a.x - c.x) < 0.1
		var dd := (c - a).normalized()
		var lado := Vector3(1, 0, 0) if vertical else Vector3(0, 0, 1)
		var largo := a.distance_to(c)
		if largo < 40.0:
			continue
		var mid := (a + c) * 0.5
		var sec := RedesCiudad.sector_en(mid.x, mid.z)
		tapas.append(Transform3D(Basis.from_scale(Vector3(0.9, 0.05, 0.9)), mid + lado * ancho * 0.25 + Vector3(0, SUELO, 0)))
		candidatas.append(mid + lado * ancho * 0.25)
		var rej := Vector3(0.5, 0.05, 0.9) if vertical else Vector3(0.9, 0.05, 0.5)
		for f: float in [0.3, 0.7]:
			for s: float in [-1.0, 1.0]:
				rejillas.append(Transform3D(Basis.from_scale(rej), a.lerp(c, f) + lado * s * (ancho * 0.5 - 0.45) + Vector3(0, SUELO, 0)))
		if i % 2 == 0:
			hidrantes.append(Transform3D(Basis.from_scale(Vector3(0.3, 0.8, 0.3)), a + dd * 14.0 + lado * (ancho * 0.5 + 1.1) + Vector3(0, 0.65, 0)))
		if i % 4 == 0:
			var pie := mid + dd * 9.0 - lado * (ancho * 0.5 + CiudadExpansion.ACERA * 0.55)
			cajas.append(Transform3D(Basis.from_scale(Vector3(1.4, 1.7, 1.1)), pie + Vector3(0, 1.1, 0)))
			if not por_sector.has(sec):
				por_sector[sec] = []
			(por_sector[sec] as Array).append(Transform3D(Basis.from_scale(Vector3(0.3, 0.2, 0.3)), pie + Vector3(0, 2.05, 0)))
	var cil := CylinderMesh.new()
	cil.top_radius = 0.5
	cil.bottom_radius = 0.5
	cil.height = 1.0
	cil.radial_segments = 10
	cil.rings = 0
	e._multimesh(cil, b._mat_simple(Color(0.18, 0.18, 0.19), 0.6), tapas, Vector3.ONE)
	e._multimesh(BoxMesh.new(), b._mat_simple(Color(0.12, 0.12, 0.13), 0.5), rejillas, Vector3.ONE)
	e._multimesh(cil, b._mat_simple(Color(0.8, 0.12, 0.1), 0.5), hidrantes, Vector3.ONE)
	e._multimesh(BoxMesh.new(), b._mat_simple(Color(0.4, 0.46, 0.42), 0.7), cajas, Vector3.ONE)
	for sec: Vector2i in por_sector:
		var m := b._mat_simple(Color(0.1, 0.8, 0.2), 0.4, 1.6)
		_lamparas[sec] = m
		var lista: Array[Transform3D] = []
		lista.assign(por_sector[sec])
		e._multimesh(BoxMesh.new(), m, lista, Vector3.ONE)
	_bocas(candidatas)
	_cuadrillas_montar(candidatas)
	cuenta["tapas"] = tapas.size()
	cuenta["sumideros"] = rejillas.size()
	cuenta["hidrantes"] = hidrantes.size()
	cuenta["transformadores"] = cajas.size()

## Las tapas «buenas» (easter egg): la más cercana al centro de cinco sectores. Se distinguen por un
## aro de óxido; de pie sobre una, E baja al subsuelo (`SubsueloCiudad`).
func _bocas(candidatas: Array) -> void:
	var lado := float(RedesCiudad.LADO_SECTOR) * CiudadExpansion.CELDA
	var oxido: Array[Transform3D] = []
	for sec: Vector2i in [Vector2i(2, 2), Vector2i(2, 1), Vector2i(1, 2), Vector2i(3, 2), Vector2i(2, 3)]:
		var centro := Vector3((float(sec.x * RedesCiudad.LADO_SECTOR - 12) - 0.5) * CiudadExpansion.CELDA + lado * 0.5, 0, \
			(float(sec.y * RedesCiudad.LADO_SECTOR - 12) - 0.5) * CiudadExpansion.CELDA + lado * 0.5)
		var mejor := Vector3.INF
		for c: Vector3 in candidatas:
			if mejor == Vector3.INF or c.distance_squared_to(centro) < mejor.distance_squared_to(centro):
				mejor = c
		if mejor == Vector3.INF:
			continue
		bocas.append({"pos": mejor, "sector": sec})
		oxido.append(Transform3D(Basis.from_scale(Vector3(1.15, 0.05, 1.15)), mejor + Vector3(0, SUELO - 0.01, 0)))
		b.puntos_clic.append({"k": "alcantarilla_%d" % (bocas.size() - 1), "n": "Bajar por la alcantarilla", "pos": mejor, \
			"estado": "ciudad", "radio": 3.0})
	var cil := CylinderMesh.new()
	cil.top_radius = 0.5
	cil.bottom_radius = 0.5
	cil.height = 1.0
	cil.radial_segments = 12
	cil.rings = 0
	e._multimesh(cil, b._mat_simple(Color(0.42, 0.24, 0.14), 0.8), oxido, Vector3.ONE)
	cuenta["bocas"] = bocas.size()

## LAS CUADRILLAS (27-10): un camión con conos y baliza junto a la tapa más cercana al centro de cada sector; solo se ve
## mientras hay una avería abierta en él y desaparece al repararse (`refrescar`).
func _cuadrillas_montar(candidatas: Array) -> void:
	var camion := load("res://assets/ciudad/kenney_cars/delivery-flat.glb") as PackedScene
	var cono := load("res://assets/ciudad/kenney_cars/cone.glb") as PackedScene
	var lado := float(RedesCiudad.LADO_SECTOR) * CiudadExpansion.CELDA
	var baliza := b._mat_simple(Color(1.0, 0.55, 0.05), 0.4, 3.0)
	for sec in RedesCiudad.sectores():
		var centro := Vector3((float(sec.x * RedesCiudad.LADO_SECTOR - 12) - 0.5) * CiudadExpansion.CELDA + lado * 0.5, 0, \
			(float(sec.y * RedesCiudad.LADO_SECTOR - 12) - 0.5) * CiudadExpansion.CELDA + lado * 0.5)
		var mejor := Vector3.INF
		for c: Vector3 in candidatas:
			if mejor == Vector3.INF or c.distance_squared_to(centro) < mejor.distance_squared_to(centro):
				mejor = c
		if mejor == Vector3.INF:
			continue
		var grupo := Node3D.new()
		grupo.name = "Cuadrilla_%d_%d" % [sec.x, sec.y]
		grupo.position = mejor
		grupo.visible = false
		if camion != null:
			var t: Node3D = camion.instantiate()
			t.scale = Vector3.ONE * 2.6
			t.position = Vector3(0, 0.3, 0)
			grupo.add_child(t)
		var luz := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5, 0.25, 0.5)
		luz.mesh = bm
		luz.material_override = baliza
		luz.position = Vector3(0, 3.6, 0)
		grupo.add_child(luz)
		if cono != null:
			for k in 4:
				var c3: Node3D = cono.instantiate()
				c3.scale = Vector3.ONE * 2.0
				c3.position = Vector3(-4.5 + float(k) * 3.0, 0.45, 5.0)
				grupo.add_child(c3)
		b.add_child(grupo)
		_cuadrillas[sec] = grupo
	cuenta["cuadrillas"] = _cuadrillas.size()

# ============================================================================ INSTALACIONES

func _rotulo(p: Vector3, texto: String) -> void:
	var l := Label3D.new()
	l.text = Idiomas.t(texto)   ## M-333
	l.font_size = 64
	l.pixel_size = 0.05
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.outline_size = 10
	l.position = p
	b.add_child(l)

## Una losa llana de hormigón bajo la instalación (el terreno de fuera es de loma).
func _losa(c: Vector3, ancho: float, fondo: float) -> Vector3:
	var p := _sitio(c)
	b._caja_en(p + Vector3(0, -1.8, 0), Vector3(ancho, 4.0, fondo), b._mat_simple(Color(0.5, 0.5, 0.5), 0.9))
	return p + Vector3(0, 0.2, 0)

func _subestacion() -> void:
	var p := _losa(SUB, 70.0, 60.0)
	for k in 4:
		var q := p + Vector3(-22.0 + float(k) * 14.0, 0, 8.0)
		b._caja_en(q + Vector3(0, 3.0, 0), Vector3(7.0, 6.0, 5.0), b._mat_simple(Color(0.45, 0.5, 0.46), 0.6))
		for a in 3:
			b._cil_en(q + Vector3(-2.0 + float(a) * 2.0, 7.2, 0), 0.4, 2.4, b._mat_simple(Color(0.8, 0.72, 0.55), 0.4))
	b._caja_en(p + Vector3(-12, 12.0, -12), Vector3(1.0, 24.0, 1.0), _acero)
	b._caja_en(p + Vector3(12, 12.0, -12), Vector3(1.0, 24.0, 1.0), _acero)
	b._caja_en(p + Vector3(0, 23.0, -12), Vector3(26.0, 1.0, 1.0), _acero)
	b._caja_en(p + Vector3(25, 2.5, -18), Vector3(10.0, 5.0, 8.0), _gris)
	_rotulo(p + Vector3(0, 30.0, 0), "SUBESTACIÓN PRINCIPAL")
	cuenta["subestacion"] = 1

func _central() -> void:
	var p := _losa(CENTRAL, 60.0, 44.0)
	b._caja_en(p + Vector3(0, 7.0, 0), Vector3(34.0, 14.0, 20.0), _gris)
	for k in 2:
		b._cil_en(p + Vector3(-8.0 + float(k) * 16.0, 24.0, -10.0), 2.0, 40.0, b._mat_simple(Color(0.72, 0.7, 0.68), 0.8), 1.5)
	b._caja_en(p + Vector3(0, 15.2, 0), Vector3(36.0, 0.8, 22.0), _acero)
	_rotulo(p + Vector3(0, 46.0, 0), "CENTRAL DE RESPALDO")
	cuenta["central"] = 1

func _potabilizadora() -> void:
	var p := _losa(POTAB, 64.0, 50.0)
	var azul := b._mat_simple(Color(0.55, 0.75, 0.85), 0.35)
	for k in 3:
		b._cil_en(p + Vector3(-18.0 + float(k) * 18.0, 2.0, 6.0), 7.5, 4.0, azul)
	b._caja_en(p + Vector3(0, 4.0, -14.0), Vector3(30.0, 8.0, 10.0), _gris)
	_rotulo(p + Vector3(0, 16.0, 0), "POTABILIZADORA")
	_tuberia(p + Vector3(32.0, 1.2, -14.0), _sitio(DEPOSITO, 1.2), 0.7)
	cuenta["potabilizadora"] = 1

func _depuradora() -> void:
	var p := _losa(DEPUR, 64.0, 50.0)
	var verde := b._mat_simple(Color(0.35, 0.5, 0.4), 0.5)
	for k in 2:
		b._cil_en(p + Vector3(-14.0 + float(k) * 28.0, 1.5, 4.0), 11.0, 3.0, verde)
	b._caja_en(p + Vector3(0, 3.5, -16.0), Vector3(26.0, 7.0, 9.0), _gris)
	_rotulo(p + Vector3(0, 14.0, 0), "DEPURADORA")
	cuenta["depuradora"] = 1

# ============================================================================ LÍNEAS

func _tuberia(p: Vector3, q: Vector3, r: float) -> void:
	var d := q - p
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = d.length()
	cm.radial_segments = 8
	cm.rings = 0
	mi.mesh = cm
	mi.material_override = _acero
	mi.position = (p + q) * 0.5
	mi.basis = Basis(Quaternion(Vector3.UP, d.normalized()))
	b.add_child(mi)

## Las torres de alta tensión del parque eólico (donde lo deja `_parque_eolico`) a la subestación.
func _alta_tension() -> void:
	var ini := _sitio(Vector3(-345, 0, -1780))
	var fin := _sitio(SUB + Vector3(0, 0, -30))
	var n := maxi(2, int(ini.distance_to(fin) / SEPARACION_TORRES))
	var dir := Vector3(fin.x - ini.x, 0, fin.z - ini.z).normalized()
	var lateral := Vector3(-dir.z, 0, dir.x)
	var anterior: Array = []
	for k in n + 1:
		var f := float(k) / float(n)
		var p := _sitio(ini.lerp(fin, f))
		b._caja_en(p + Vector3(0, 11.0, 0), Vector3(0.9, 22.0, 0.9), _acero)
		b._caja_en(p + Vector3(0, 20.0, 0), Vector3(12.0, 0.6, 0.6), _acero, atan2(-lateral.z, lateral.x))
		var puntas: Array = []
		for s: float in [-1.0, 0.0, 1.0]:
			puntas.append(p + Vector3(0, 19.5, 0) + lateral * s * 5.5)
		if not anterior.is_empty():
			for j in 3:
				_tuberia(anterior[j], puntas[j], 0.06)
		anterior = puntas
	cuenta["torres"] = n + 1

# ============================================================================ EDIFICIOS

## Los edificios de la ciudad (los de `ESPECIALES`) se CONECTAN al modelo: cada uno consume luz y agua de SU sector.
func _edificios() -> void:
	var vistos := {}
	var gas_n := 0
	modelo.registrar_edificio("estadio", CityBuilder.ESTADIO_EN, String(b.datos.get("club", {}).get("estadioNom", "Estadio del club")))
	for bl: Dictionary in e.bloques:
		var uso := String(bl["uso"])
		if not RedesCiudad.CONSUMO.has(uso) or (vistos.has(uso) and uso != "gasolinera"):
			continue
		vistos[uso] = true
		var r: Rect2 = bl["rect"]
		var nombre := ""
		if uso == "gasolinera":
			gas_n += 1
			nombre = "Gasolinera %d" % gas_n
		modelo.registrar_edificio(uso, Vector3(r.get_center().x, 0, r.get_center().y), nombre)
	cuenta["edificios_conectados"] = modelo.edificios.size()
	modelo.recalcular()

# ============================================================================ GASOLINERAS

func _gasolineras() -> void:
	var id := 0
	for bl: Dictionary in e.bloques:
		if String(bl["uso"]) != "gasolinera":
			continue
		var r: Rect2 = bl["rect"]
		var c := Vector3(r.get_center().x, 0, r.get_center().y)
		var pantalla := b._mat_simple(Color(0.1, 0.9, 0.3), 0.4, 1.4)
		for sx: float in [-1.0, 1.0]:
			for k: float in [0.09, 0.2]:
				var q := c + Vector3(sx * r.size.x * k, 0, 0)
				b._caja_en(q + Vector3(0, 1.0, 0), Vector3(0.7, 1.6, 0.5), b._mat_simple(Color(0.85, 0.85, 0.87), 0.5))
				b._caja_en(q + Vector3(0, 1.45, 0.27), Vector3(0.45, 0.3, 0.05), pantalla)
		var sec := RedesCiudad.sector_en(c.x, c.z)
		surtidores.append({"id": id, "pos": c, "sector": sec, "pantalla": pantalla, "cisterna": _camion_cisterna(c + Vector3(r.size.x * 0.32, 0.3, r.size.y * 0.22))})
		b.puntos_clic.append({"k": "surtidor_%d" % id, "n": "Repostar · Gasolinera", "pos": c, "estado": "ciudad", "radio": 26.0, "alcance": 8.0})
		id += 1
	cuenta["surtidores"] = surtidores.size() * 4

# ============================================================================ ESTADO

func _inundaciones() -> void:
	var lado := float(RedesCiudad.LADO_SECTOR) * CiudadExpansion.CELDA
	var agua := b._mat_simple(Color(0.25, 0.45, 0.6), 0.1)
	agua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	agua.albedo_color = Color(0.25, 0.45, 0.6, 0.55)
	for sec in RedesCiudad.sectores():
		var mi := MeshInstance3D.new()
		var pl := PlaneMesh.new()
		pl.size = Vector2(lado, lado)
		mi.mesh = pl
		mi.material_override = agua
		mi.position = Vector3((float(sec.x * RedesCiudad.LADO_SECTOR - 12) - 0.5) * CiudadExpansion.CELDA + lado * 0.5, 0.42, \
			(float(sec.y * RedesCiudad.LADO_SECTOR - 12) - 0.5) * CiudadExpansion.CELDA + lado * 0.5)
		mi.visible = false
		b.add_child(mi)
		_aguas[sec] = mi

## Una hora de juego (`Reloj.hora_cambiada`): el clima de la semana manda viento y lluvia.
func hora_cambiada(hora: int, clima: String) -> void:
	var t := RedesCiudad.tiempo_de(clima, hora)
	modelo.pasar(1, hora, float(t["viento"]), float(t["lluvia"]), clima)
	refrescar()

## La partida manda: el estado de las redes es el de `Mundo.redes_ciudad` (los edificios son los de ESTA ciudad).
func adoptar(m: RedesCiudad) -> void:
	if m == null or m == modelo:
		return
	m.recibir_edificios(modelo.edificios)
	modelo = m
	refrescar()

## Lo que el evento del apagón quiere contar al jugador ({tipo, texto}).
func tomar_avisos() -> Array:
	return modelo.evento.tomar_avisos()

func refrescar() -> void:
	for sec: Vector2i in _lamparas:
		var m: StandardMaterial3D = _lamparas[sec]
		var ok := modelo.hay_luz(sec)
		m.albedo_color = Color(0.1, 0.8, 0.2) if ok else Color(0.9, 0.1, 0.1)
		m.emission = m.albedo_color
	for sec: Vector2i in _cuadrillas:
		(_cuadrillas[sec] as Node3D).visible = modelo.hay_averia(sec)
	for sec: Vector2i in _aguas:
		(_aguas[sec] as MeshInstance3D).visible = bool(modelo.inundado.get(sec, false))
	for s: Dictionary in surtidores:
		var pm: StandardMaterial3D = s["pantalla"]
		pm.emission_energy_multiplier = 1.4 if modelo.hay_luz(s["sector"]) else 0.0
		if is_instance_valid(s.get("cisterna")):
			(s["cisterna"] as Node3D).visible = modelo.cisterna.has(int(s["id"]))

func fraccion_luz() -> float:
	return modelo.fraccion_luz()

## Los datos del surtidor `id` (o {}).
func surtidor(id: int) -> Dictionary:
	for s: Dictionary in surtidores:
		if int(s["id"]) == id:
			return s
	return {}

## EL CAMIÓN CISTERNA (§2.5, 30-10): el camión de reparto del kit con un depósito blanco encima; solo se ve
## mientras descarga en su gasolinera (`RedesCiudad.cisterna`, unas horas tras quedarse bajo el 20 %).
func _camion_cisterna(p: Vector3) -> Node3D:
	var g := Node3D.new()
	g.name = "Cisterna"
	g.position = p
	g.visible = false
	var camion := load("res://assets/ciudad/kenney_cars/delivery-flat.glb") as PackedScene
	if camion != null:
		var t: Node3D = camion.instantiate()
		t.scale = Vector3.ONE * 2.6
		g.add_child(t)
	var tanque := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 4.2
	tanque.mesh = cm
	tanque.rotation.x = PI * 0.5
	tanque.position = Vector3(0, 2.4, -0.9)
	tanque.material_override = b._mat_simple(Color(0.92, 0.92, 0.9), 0.35)
	g.add_child(tanque)
	var franja := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 1.02
	fm.bottom_radius = 1.02
	fm.height = 0.5
	franja.mesh = fm
	franja.rotation.x = PI * 0.5
	franja.position = tanque.position
	franja.material_override = b._mat_simple(Color(0.85, 0.15, 0.1), 0.4)
	g.add_child(franja)
	b.add_child(g)
	return g
