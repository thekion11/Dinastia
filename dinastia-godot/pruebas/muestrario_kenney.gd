extends Node3D
## MUESTRARIO DE LOS KITS DE KENNEY (15-10-2026, evaluación: qué piezas sirven
## para la ciudad y sus interiores). Monta filas de modelos de cada kit con la
## escala propuesta en EVALUACION_KENNEY_CIUDAD.md, al lado de referencias de
## medida real (persona de 1,8 m, puerta de 2 m, piso de 3 m, coche de 4,5 m) y
## de un edificio del kit comercial tal como lo usa la ciudad (×5,6), y saca una
## foto por grupo. No toca nada del juego.
##   herramientas/captura.sh res://pruebas/muestrario_kenney.tscn
##   SOLO=nombre  saca solo esa foto (exteriores, modulares, tren, salon, tienda, bar, parque)
## Salida: pruebas/capturas/kenney_<grupo>.png (captura.sh la pasa a JPG).

const K := "res://assets/kenney/"
const C := "res://assets/ciudad/"

## [nombre, posición de cámara, punto al que mira, fov]
var _fotos: Array = []
var _cam: Camera3D
var _n := 0
var _i := 0
var _cache := {}

func _ready() -> void:
	var env := Environment.new()
	var cielo := Sky.new()
	var ps := ProceduralSkyMaterial.new()
	ps.sky_top_color = Color(0.36, 0.55, 0.82)
	ps.sky_horizon_color = Color(0.72, 0.8, 0.88)
	ps.ground_horizon_color = Color(0.6, 0.62, 0.6)
	cielo.sky_material = ps
	env.background_mode = Environment.BG_SKY
	env.sky = cielo
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-48, -35, 0)
	sol.light_energy = 1.15
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 160.0
	add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2400, 600)
	suelo.mesh = pm
	suelo.position = Vector3(600, 0, 0)
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.36, 0.37, 0.36)
	ms.roughness = 0.95
	suelo.material_override = ms
	add_child(suelo)
	_cam = Camera3D.new()
	_cam.far = 2000.0
	add_child(_cam)
	_cam.make_current()
	_exteriores(Vector3(0, 0, 0))
	_modulares(Vector3(260, 0, 0))
	_tren(Vector3(520, 0, 0))
	_salon(Vector3(780, 0, 0))
	_tienda(Vector3(1000, 0, 0))
	_bar(Vector3(1200, 0, 0))
	_parque(Vector3(1400, 0, 0))
	var solo := OS.get_environment("SOLO")
	if solo != "":
		_fotos = _fotos.filter(func(f: Array) -> bool: return f[0] == solo)

# ------------------------------------------------------------------ ayudas

func _esc(ruta: String) -> PackedScene:
	if not _cache.has(ruta):
		_cache[ruta] = load(ruta)
	return _cache[ruta]

func _caja(n: Node, t: Transform3D, acc: Array) -> void:
	var tt := t * (n as Node3D).transform if n is Node3D else t
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var c := tt * (n as MeshInstance3D).mesh.get_aabb()
		acc[0] = c if not acc[1] else (acc[0] as AABB).merge(c)
		acc[1] = true
	for h in n.get_children():
		_caja(h, tt, acc)

## Pone una pieza con su escala y un rótulo con el nombre y la medida real.
func _pon(ruta: String, pos: Vector3, esc: Vector3, giro: float = 0.0, rotulo := true) -> Node3D:
	var e := _esc(ruta)
	if e == null:
		push_warning("no carga " + ruta)
		return null
	var n: Node3D = e.instantiate()
	n.scale = esc
	n.rotation.y = giro
	n.position = pos
	add_child(n)
	if rotulo:
		var acc := [AABB(), false]
		_caja(n, Transform3D.IDENTITY, acc)
		var c: AABB = acc[0]
		var l := Label3D.new()
		l.text = "%s\n%.1f×%.1f×%.1f m" % [ruta.get_file().get_basename(), c.size.x, c.size.y, c.size.z]
		l.font_size = 40
		l.pixel_size = clampf(c.size.y * 0.0025, 0.002, 0.012)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.outline_size = 10
		l.position = pos + Vector3(0, c.size.y + 0.3 + l.pixel_size * 50.0, 0)
		add_child(l)
	return n

## Referencias de medida: persona 1,8 m (roja), puerta 2 m (marco blanco),
## piso de 3 m (barra amarilla) y coche de 4,5 m (caja azul).
func _referencias(p: Vector3, con_coche := true) -> void:
	var rojo := StandardMaterial3D.new()
	rojo.albedo_color = Color(0.85, 0.15, 0.12)
	var cap := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.25
	cm.height = 1.8
	cap.mesh = cm
	cap.material_override = rojo
	cap.position = p + Vector3(0, 0.9, 0)
	add_child(cap)
	var amarillo := StandardMaterial3D.new()
	amarillo.albedo_color = Color(0.95, 0.8, 0.1)
	for k in 2:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.15, 3.0, 0.15)
		b.mesh = bm
		b.material_override = amarillo if k == 0 else rojo
		b.position = p + Vector3(1.0, 1.5 + float(k) * 3.0, 0)
		add_child(b)
	var blanco := StandardMaterial3D.new()
	blanco.albedo_color = Color(0.95, 0.95, 0.95)
	for x: float in [-0.5, 0.5]:
		var pa := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(0.1, 2.0, 0.1)
		pa.mesh = pb
		pa.material_override = blanco
		pa.position = p + Vector3(2.5 + x, 1.0, 0)
		add_child(pa)
	var dintel := MeshInstance3D.new()
	var db := BoxMesh.new()
	db.size = Vector3(1.1, 0.1, 0.1)
	dintel.mesh = db
	dintel.material_override = blanco
	dintel.position = p + Vector3(2.5, 2.0, 0)
	add_child(dintel)
	if con_coche:
		var azul := StandardMaterial3D.new()
		azul.albedo_color = Color(0.2, 0.35, 0.75)
		var co := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(1.85, 1.5, 4.5)
		co.mesh = cb
		co.material_override = azul
		co.position = p + Vector3(5.0, 0.75, 0)
		add_child(co)
	var l := Label3D.new()
	l.text = "persona 1,8 · piso 3 m · puerta 2 m" + (" · coche 4,5" if con_coche else "")
	l.font_size = 36
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.outline_size = 10
	l.position = p + Vector3(2.5, 6.6, 0)
	add_child(l)

func _suelo(p: Vector3, tam: Vector2, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(tam.x, 0.04, tam.y)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.8
	mi.material_override = m
	mi.position = p + Vector3(0, 0.02, 0)
	add_child(mi)

# ------------------------------------------------------------------ grupos

## Casas del kit suburbano y naves del industrial, a la escala de la ciudad
## (×5,6, la misma que `CiudadExpansion._fachadas` da al kit comercial).
func _exteriores(o: Vector3) -> void:
	var s := Vector3.ONE * 5.6
	_referencias(o + Vector3(-12, 0, 8))
	_pon(C + "kenney_comercial/building-a.glb", o + Vector3(-12, 0, -8), s)
	var casas := ["building-type-a", "building-type-c", "building-type-f", "building-type-k", "building-type-n", "building-type-t", "building-type-u"]
	for k in casas.size():
		_pon(K + "suburbano/%s.glb" % casas[k], o + Vector3(2.0 + float(k) * 12.0, 0, 6), s, PI)
	_pon(K + "suburbano/fence-1x4.glb", o + Vector3(38.0, 0, 13.0), s, PI, false)
	_pon(K + "suburbano/planter.glb", o + Vector3(50.0, 0, 13.0), s, PI, false)
	_pon(K + "suburbano/driveway-long.glb", o + Vector3(62.0, 0, 13.0), s, PI, false)
	_pon(K + "suburbano/tree-large.glb", o + Vector3(86.0, 0, 6.0), s)
	var naves := ["building-a", "building-c", "building-l", "building-q", "building-r"]
	for k in naves.size():
		_pon(K + "industrial/%s.glb" % naves[k], o + Vector3(4.0 + float(k) * 16.0, 0, -18), s, PI)
	_pon(K + "industrial/chimney-large.glb", o + Vector3(84.0, 0, -18), s)
	_pon(K + "industrial/water-tower.glb", o + Vector3(92.0, 0, -18), s)
	_pon(K + "industrial/detail-tank-large.glb", o + Vector3(100.0, 0, -18), s)
	_pon(K + "industrial/shipping-container-a.glb", o + Vector3(84.0, 0, -6), Vector3.ONE * 7.4)
	_pon(K + "industrial/solar-panel-landscape-group.glb", o + Vector3(94.0, 0, -6), s)
	_fotos.append(["exteriores", o + Vector3(30, 26, 44), o + Vector3(30, 3, -4), 55.0])
	_fotos.append(["exteriores_calle", o + Vector3(-8, 1.7, 19), o + Vector3(20, 3.5, 6), 60.0])

## Edificios modulares (bloque de 1 = un piso: ×4,8 → 3 m de alto) y el Building
## Kit (ya está en metros: puerta de 2,1, pared de 2,4; ×1,25 para pisos de 3 m).
func _modulares(o: Vector3) -> void:
	_referencias(o + Vector3(-10, 0, 8))
	var s := Vector3.ONE * 4.8
	var muestras := ["building-sample-house-a", "building-sample-house-b", "building-sample-house-c", "building-sample-tower-a", "building-sample-tower-c"]
	for k in muestras.size():
		_pon(K + "edificios_modulares/%s.glb" % muestras[k], o + Vector3(float(k) * 13.0, 0, -6), s, 0.0)
	## Una fachada armada pieza a pieza: planta baja con puerta y dos pisos.
	var f0 := o + Vector3(70, 0, -6)
	var piezas := [["building-door-window", "building-window-awnings", "building-window"],
		["building-window-balcony", "building-window-sill", "building-windows-sills"],
		["building-window-large", "building-window-large-middle", "building-window-large-right"]]
	for piso in 3:
		for c in 3:
			_pon(K + "edificios_modulares/%s.glb" % piezas[piso][c], f0 + Vector3(float(c) * 4.8, float(piso) * 0.62 * 4.8, 0), s, 0.0, false)
	for c in 3:
		_pon(K + "edificios_modulares/roof-flat-border-straight.glb", f0 + Vector3(float(c) * 4.8, 3.0 * 0.62 * 4.8, 0), s, 0.0, false)
	## Building Kit a ×1,25: muro con puerta, ventanas, puerta animada, escalera.
	var b := Vector3.ONE * 1.25
	var kit := ["wall-doorway-square", "wall-window-square-detailed", "wall-window-wide-round-detailed", "door-rotate-square-a", "stairs-open", "column", "gutter-vertical-wall"]
	for k in kit.size():
		_pon(K + "kit_edificios/%s.glb" % kit[k], o + Vector3(float(k) * 5.0, 0, 10), b, PI * 0.5)
	_fotos.append(["modulares", o + Vector3(36, 16, 36), o + Vector3(36, 4, -2), 58.0])

## Trenes: el metro del kit a escala uniforme (juguete: 5,7 m de coche), el
## mismo estirado a 18 m, un tranvía, y la caja de un coche de metro real
## (3 × 3,6 × 16 m) como el de `MetroCiudad._tren_real`.
func _tren(o: Vector3) -> void:
	_referencias(o + Vector3(-6, 0, 12))
	_pon(K + "tren/train-electric-subway-a.glb", o + Vector3(0, 0, 0), Vector3.ONE * 2.2)
	_pon(K + "tren/train-electric-subway-a.glb", o + Vector3(8, 0, 0), Vector3(2.2, 2.2, 6.9))
	_pon(K + "tren/train-tram-modern.glb", o + Vector3(16, 0, 0), Vector3.ONE * 2.3)
	_pon(K + "tren/train-electric-city-c.glb", o + Vector3(24, 0, 0), Vector3(2.5, 2.2, 6.0))
	_pon(K + "tren/train-carriage-container-red.glb", o + Vector3(32, 0, 0), Vector3(2.5, 2.4, 5.0))
	for k in 6:
		_pon(K + "tren/track-single.glb", o + Vector3(32, 0, -10.0 + float(k) * 3.0), Vector3.ONE * 3.0, 0.0, false)
	var real := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.0, 3.6, 16.0)
	real.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.93, 0.94, 0.96)
	real.material_override = m
	real.position = o + Vector3(42, 2.0, 0)
	add_child(real)
	var l := Label3D.new()
	l.text = "metro actual (caja 3×3,6×16)"
	l.font_size = 40
	l.pixel_size = 0.008
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.outline_size = 10
	l.position = o + Vector3(42, 4.8, 0)
	add_child(l)
	_fotos.append(["tren", o + Vector3(18, 9, 34), o + Vector3(18, 2, 2), 62.0])

## Un salón-cocina con el Furniture Kit a ×2 (silla 0,94 m, nevera 1,84).
func _salon(o: Vector3) -> void:
	_suelo(o, Vector2(12, 9), Color(0.62, 0.47, 0.33))
	var s := Vector3.ONE * 2.0
	## Paredes del kit (1,29 → 2,6 m) al fondo y a la izquierda.
	for k in 6:
		_pon(K + "muebles/%s.glb" % ("wallWindow" if k == 2 or k == 4 else "wall"), o + Vector3(-6.0 + float(k) * 2.0, 0, -4.5), s, 0.0, false)
	for k in 4:
		_pon(K + "muebles/%s.glb" % ("wallDoorway" if k == 1 else "wall"), o + Vector3(-6.0, 0, -2.5 + float(k) * 2.0), s, PI * 0.5, false)
	_pon(K + "muebles/loungeSofa.glb", o + Vector3(-3.0, 0, 1.5), s, PI)
	_pon(K + "muebles/tableCoffee.glb", o + Vector3(-3.0, 0, -0.2), s, 0.0, false)
	_pon(K + "muebles/rugRectangle.glb", o + Vector3(-3.0, 0, 0.0), s, 0.0, false)
	_pon(K + "muebles/cabinetTelevision.glb", o + Vector3(-3.0, 0, -3.8), s)
	_pon(K + "muebles/televisionModern.glb", o + Vector3(-3.0, 0.62, -3.8), s, 0.0, false)
	_pon(K + "muebles/bookcaseOpen.glb", o + Vector3(-5.4, 0, -1.0), s, PI * 0.5)
	_pon(K + "muebles/lampRoundFloor.glb", o + Vector3(-5.2, 0, 1.6), s, 0.0, false)
	_pon(K + "muebles/pottedPlant.glb", o + Vector3(-0.5, 0, -3.9), s, 0.0, false)
	var cocina := ["kitchenCabinetDrawer", "kitchenSink", "kitchenCabinet", "kitchenStove", "kitchenCabinetDrawer"]
	for k in cocina.size():
		_pon(K + "muebles/%s.glb" % cocina[k], o + Vector3(1.0 + float(k) * 0.86, 0, -4.0), s, 0.0, k == 3)
	_pon(K + "muebles/kitchenFridgeLarge.glb", o + Vector3(5.4, 0, -3.9), s)
	_pon(K + "muebles/table.glb", o + Vector3(3.0, 0, -0.5), s)
	for k in 2:
		_pon(K + "muebles/chairCushion.glb", o + Vector3(2.4 + float(k) * 1.2, 0, 0.6), s, PI, false)
		_pon(K + "muebles/chairCushion.glb", o + Vector3(2.4 + float(k) * 1.2, 0, -1.6), s, 0.0, false)
	_pon(K + "comida/plate-dinner.glb", o + Vector3(2.6, 0.68, -0.5), Vector3.ONE * 0.3, 0.0, false)
	_pon(K + "comida/pizza.glb", o + Vector3(3.4, 0.68, -0.5), Vector3.ONE * 0.4, 0.0, false)
	_pon(K + "mini_mercado/character-employee.glb", o + Vector3(1.0, 0, 1.5), Vector3.ONE * 2.4, PI)
	_referencias(o + Vector3(5.5, 0, 3.0), false)
	var luz := OmniLight3D.new()
	luz.position = o + Vector3(0, 2.6, 0)
	luz.omni_range = 9.0
	luz.light_energy = 0.8
	add_child(luz)
	_fotos.append(["salon", o + Vector3(1.0, 5.2, 7.5), o + Vector3(0.0, 0.6, -1.5), 60.0])

## Supermercado (Mini Market ×2,4: el empleado mide 1,73 m) y recreativos
## (Mini Arcade ×2,4).
func _tienda(o: Vector3) -> void:
	_suelo(o, Vector2(26, 12), Color(0.85, 0.85, 0.82))
	var s := Vector3.ONE * 2.4
	for k in 4:
		_pon(K + "mini_mercado/%s.glb" % ("shelf-bags" if k % 2 == 0 else "shelf-boxes"), o + Vector3(-11.0 + float(k) * 1.95, 0, -3.0), s, 0.0, k == 0)
	_pon(K + "mini_mercado/shelf-end.glb", o + Vector3(-11.0 + 4.0 * 1.95 - 0.5, 0, -3.0), s, 0.0, false)
	_pon(K + "mini_mercado/display-fruit.glb", o + Vector3(-10.0, 0, 1.0), s)
	_pon(K + "mini_mercado/display-bread.glb", o + Vector3(-8.0, 0, 1.0), s)
	_pon(K + "mini_mercado/freezers-standing.glb", o + Vector3(-5.5, 0, 1.0), s)
	_pon(K + "mini_mercado/cash-register.glb", o + Vector3(-3.0, 0, 3.0), s, PI)
	_pon(K + "mini_mercado/character-employee.glb", o + Vector3(-3.0, 0, 4.4), s, PI, false)
	_pon(K + "mini_mercado/shopping-cart.glb", o + Vector3(-6.0, 0, 4.0), s, 0.0, false)
	var arcade := ["arcade-machine", "pinball", "air-hockey", "claw-machine", "dance-machine", "basketball-game", "vending-machine", "prize-wheel"]
	for k in arcade.size():
		_pon(K + "mini_arcade/%s.glb" % arcade[k], o + Vector3(1.5 + float(k % 4) * 2.8, 0, -3.0 + float(k / 4) * 4.5), s)
	_pon(K + "mini_arcade/character-gamer.glb", o + Vector3(1.5, 0, -1.6), s, PI, false)
	_referencias(o + Vector3(-11.0, 0, 4.5), false)
	_fotos.append(["tienda", o + Vector3(0.0, 7.5, 13.0), o + Vector3(0.0, 0.5, -1.0), 62.0])

## Un bar/comedor: mostrador del kit de muebles con comida del Food Kit (×0,3:
## plato de 27 cm, lata de 12 cm) y taburetes.
func _bar(o: Vector3) -> void:
	_suelo(o, Vector2(10, 7), Color(0.3, 0.22, 0.16))
	var s := Vector3.ONE * 2.0
	for k in 6:
		_pon(K + "muebles/kitchenBar.glb", o + Vector3(-2.5 + float(k) * 0.86, 0, -1.0), s, PI, false)
		_pon(K + "muebles/stoolBar.glb", o + Vector3(-2.5 + float(k) * 0.86, 0, 0.0), s, 0.0, false)
	var comida := ["burger", "fries", "soda-can", "pizza", "hot-dog", "glass-wine", "cocktail", "cup-coffee", "croissant", "donut-sprinkles", "sandwich", "plate-dinner"]
	for k in comida.size():
		_pon(K + "comida/%s.glb" % comida[k], o + Vector3(-2.7 + float(k) * 0.45, 0.85, -1.0), Vector3.ONE * 0.3, 0.0, false)
	_pon(K + "muebles/tableRound.glb", o + Vector3(2.5, 0, 1.5), s)
	_pon(K + "comida/plate-dinner.glb", o + Vector3(2.5, 0.75, 1.5), Vector3.ONE * 0.3, 0.0, false)
	_pon(K + "comida/burger-cheese.glb", o + Vector3(2.5, 0.8, 1.5), Vector3.ONE * 0.3, 0.0, false)
	_pon(K + "mini_mercado/character-employee.glb", o + Vector3(-0.5, 0, -2.0), Vector3.ONE * 2.4, 0.0, false)
	_fotos.append(["bar", o + Vector3(0.5, 2.6, 3.6), o + Vector3(-0.5, 0.9, -1.0), 55.0])

## Parque de atracciones (Coaster Kit ×2,2) y puestos.
func _parque(o: Vector3) -> void:
	_referencias(o + Vector3(-14, 0, 8))
	var s := Vector3.ONE * 2.2
	_pon(K + "montana_rusa/park-entrance.glb", o + Vector3(-6, 0, 4), Vector3.ONE * 2.5)
	_pon(K + "montana_rusa/stall-food.glb", o + Vector3(2, 0, 6), s, PI)
	_pon(K + "montana_rusa/stall-drinks.glb", o + Vector3(6, 0, 6), s, PI)
	_pon(K + "montana_rusa/stall-information.glb", o + Vector3(10, 0, 6), s, PI)
	_pon(K + "montana_rusa/stall-toilets.glb", o + Vector3(14, 0, 6), s, PI)
	var piezas := ["coaster-steel-straight", "coaster-steel-straight-hill-beginning", "coaster-steel-straight-hill-complete", "coaster-steel-straight-hill-end", "coaster-steel-straight"]
	for k in piezas.size():
		_pon(K + "montana_rusa/%s.glb" % piezas[k], o + Vector3(0, 2.2, -4.0 + float(k) * -8.8) , s, PI * 0.5 * 0.0, false)
	for k in 5:
		_pon(K + "montana_rusa/support-large.glb", o + Vector3(0, 0, -4.0 + float(k) * -8.8), Vector3(2.2, 2.2, 2.2), 0.0, false)
	_pon(K + "montana_rusa/coaster-train-front.glb", o + Vector3(0, 2.2, -8.0), s, 0.0)
	_pon(K + "montana_rusa/coaster-steel-looping.glb", o + Vector3(12, 2.2, -14), s, PI * 0.5)
	_fotos.append(["parque", o + Vector3(16, 10, 22), o + Vector3(0, 3, -6), 62.0])

# ------------------------------------------------------------------ fotos

func _process(_d: float) -> void:
	_n += 1
	if _i >= _fotos.size():
		get_tree().quit()
		return
	var f: Array = _fotos[_i]
	if _n == 3:
		_cam.fov = float(f[3])
		_cam.position = f[1]
		_cam.look_at(f[2], Vector3.UP)
	if _n == 9:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/kenney_%s.png" % f[0])
		print("FOTO kenney_", f[0])
		_i += 1
		_n = 0
