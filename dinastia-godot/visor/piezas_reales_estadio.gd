class_name PiezasRealesEstadio
extends RefCounted
## PIEZAS PARA RECREAR ESTADIOS REALES (10-11, plan `docs/04_auditorias/ESTADIOS_REALISTAS_PLAN.md`). Todas OPCIONALES: un perfil sin
## estas claves construye el mismo estadio de siempre (no se añade ni un nodo). Cada pieza es UN MultiMesh (una llamada de dibujo):
##   arco          {"alto": m, "lado": "este|oeste|centro", "inclina": grados, "color": hex} → arco tubular a lo largo del campo, sobre
##                 una tribuna lateral (tipo Wembley) o por el centro (tipo Moses Mabhida)
##   torres_rampa  n (4, 8, 11…) + "torres_col"                                       → cilindros de rampas alrededor (tipo San Siro)
##   costillas     n + "costillas_col"                                                → costillas exteriores verticales (tipo Parc des Princes);
##                                                                                      no en calidad MÍNIMA
## El color de la pista (`pista_col`) lo lee `_pista_atletismo`; los techos por lado (`techo_lados`) y las alturas por lado
## (`niveles_lado`) se traducen al perfil en `Club.perfil_estadio()`.
const SEG_ARCO := 18

static func montar(root: Node3D, est: Dictionary, dx: float, dz: float, fondo: float, alto: float) -> int:
	var n := 0
	if est.get("arco") is Dictionary:
		_arco(root, est["arco"] as Dictionary, dx, dz, fondo, alto)
		n += 1
	if int(est.get("torres_rampa", 0)) > 0:
		_torres(root, int(est["torres_rampa"]), Color(String(est.get("torres_col", "#b8b8b8"))), dx, dz, fondo, alto)
		n += 1
	if int(est.get("costillas", 0)) > 0 and Calidad.elegida > Calidad.MINIMO:
		_costillas(root, int(est["costillas"]), Color(String(est.get("costillas_col", "#d8d8d8"))), dx, dz, fondo, alto)
		n += 1
	return n

static func _mm(root: Node3D, nombre: String, malla: Mesh, mat: Material, trans: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla
	mm.instance_count = trans.size()
	for i in trans.size():
		mm.set_instance_transform(i, trans[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nombre
	mmi.multimesh = mm
	mmi.material_override = mat
	root.add_child(mmi)
	return mmi

static func _metal(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.6
	m.roughness = 0.35
	return m

## El arco: un semicírculo de tramos tubulares que va de un extremo al otro del estadio por encima de una tribuna.
static func _arco(root: Node3D, a: Dictionary, dx: float, dz: float, fondo: float, alto: float) -> void:
	var h := float(a.get("alto", alto * 2.6))
	var radio := dz + fondo * 0.6   ## el campo es largo en Z: el arco lo cruza de fondo a fondo
	var lado := String(a.get("lado", "oeste"))
	var x := 0.0 if lado == "centro" else (dx + fondo * 0.55) * (-1.0 if lado == "oeste" else 1.0)
	var inclina := deg_to_rad(float(a.get("inclina", 0.0 if lado == "centro" else 22.0))) * (-1.0 if lado == "oeste" else 1.0)
	var grosor := maxf(1.6, h * 0.018)
	var cil := CylinderMesh.new()
	cil.top_radius = grosor
	cil.bottom_radius = grosor
	cil.radial_segments = 8
	cil.rings = 1
	var pts: Array[Vector3] = []
	for i in SEG_ARCO + 1:
		var t := PI * float(i) / SEG_ARCO
		var y := sin(t) * h
		pts.append(Vector3(x + sin(inclina) * y, y, -cos(t) * radio))
	var trans: Array = []
	for i in SEG_ARCO:
		var p0 := pts[i]
		var p1 := pts[i + 1]
		var eje := (p1 - p0)
		var arriba := eje.normalized()
		var lado_v := arriba.cross(Vector3.RIGHT if absf(arriba.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD).normalized()
		## Columnas de la base: el eje Y del cilindro (alto 2) va a lo largo del tramo y se estira a su largo (+5 % para que no queden huecos).
		var b := Basis(lado_v, arriba * (eje.length() * 0.525), lado_v.cross(arriba))
		trans.append(Transform3D(b, (p0 + p1) * 0.5))
	cil.height = 2.0
	_mm(root, "ArcoEstadio", cil, _metal(Color(String(a.get("color", "#e8e8ec")))), trans)

## Las torres de rampas: cilindros repartidos por fuera del graderío, un poco más altos que la grada.
static func _torres(root: Node3D, n: int, col: Color, dx: float, dz: float, fondo: float, alto: float) -> void:
	var cil := CylinderMesh.new()
	cil.top_radius = 5.0
	cil.bottom_radius = 5.0
	cil.height = alto * 1.08
	cil.radial_segments = 12
	cil.rings = 4
	var rx := dx + fondo + 6.0
	var rz := dz + fondo + 6.0
	var trans: Array = []
	for i in n:
		var a := TAU * (float(i) + 0.5) / n
		trans.append(Transform3D(Basis(), Vector3(cos(a) * rx, alto * 0.54, sin(a) * rz)))
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.85
	_mm(root, "TorresRampa", cil, m, trans)

## Costillas exteriores: vigas verticales inclinadas hacia afuera alrededor del estadio.
static func _costillas(root: Node3D, n: int, col: Color, dx: float, dz: float, fondo: float, alto: float) -> void:
	var caja := BoxMesh.new()
	caja.size = Vector3(1.4, alto * 1.15, 2.2)
	var rx := dx + fondo + 2.0
	var rz := dz + fondo + 2.0
	var trans: Array = []
	for i in n:
		var a := TAU * float(i) / n
		var pos := Vector3(cos(a) * rx, alto * 0.55, sin(a) * rz)
		var b := Basis(Vector3.UP, -a).rotated(Vector3(cos(a), 0, sin(a)).cross(Vector3.UP).normalized(), deg_to_rad(10.0))
		trans.append(Transform3D(b, pos))
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.7
	_mm(root, "CostillasFachada", caja, m, trans)
