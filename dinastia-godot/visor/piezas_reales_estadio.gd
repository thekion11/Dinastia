class_name PiezasRealesEstadio
extends RefCounted
## PIEZAS PARA RECREAR ESTADIOS REALES (10-11, plan `docs/04_auditorias/ESTADIOS_REALISTAS_PLAN.md`). Todas OPCIONALES: un perfil sin
## estas claves construye el mismo estadio de siempre (no se añade ni un nodo). Cada pieza es UN MultiMesh (una llamada de dibujo):
##   arco          {"alto": m, "lado": "este|oeste|centro", "inclina": grados, "color": hex} → arco tubular a lo largo del campo, sobre
##                 una tribuna lateral (tipo Wembley) o por el centro (tipo Moses Mabhida)
##   torres_rampa  n (4, 8, 11…) + "torres_col"                                       → cilindros de rampas alrededor (tipo San Siro)
##   costillas     n + "costillas_col"                                                → costillas exteriores verticales (tipo Parc des Princes);
##                                                                                      no en calidad MÍNIMA
##   fachada_curva {"color": hex}  → un anillo elíptico que envuelve el estadio: el óvalo se ve curvo por fuera
##   colchon       {"color": hex, "filas": n} → paneles que se iluminan del color del club (tipo Allianz Arena)
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
	if est.get("fachada_curva") is Dictionary:
		_fachada_curva(root, est["fachada_curva"] as Dictionary, dx, dz, fondo, alto)
		n += 1
	if est.get("colchon") is Dictionary:
		_colchon(root, est["colchon"] as Dictionary, dx, dz, fondo, alto)
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

## La fachada curva: un anillo de SUPERELIPSE (exponente 4, un rectángulo de esquinas redondeadas) que envuelve también las
## esquinas y las puntas de las tribunas; con una elipse simple las esquinas la atravesaban y la tapaban. Una malla, dos caras.
const EXP_CURVA := 4.0
static func radio_curva(dx: float, dz: float, fondo: float) -> Vector2:
	return Vector2(dx + fondo, dz + fondo) * 1.2 + Vector2(2.0, 2.0)   ## 2·(1/1,2)^4 < 1: la esquina queda dentro

static func _fachada_curva(root: Node3D, f: Dictionary, dx: float, dz: float, fondo: float, alto: float) -> void:
	var r := radio_curva(dx, dz, fondo)
	var n := 64 if Calidad.elegida > Calidad.MINIMO else 36
	var h := alto * 1.02
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector3] = []
	for i in n + 1:
		var a := TAU * float(i) / n
		var c := cos(a)
		var s := sin(a)
		pts.append(Vector3(signf(c) * pow(absf(c), 2.0 / EXP_CURVA) * r.x, 0, signf(s) * pow(absf(s), 2.0 / EXP_CURVA) * r.y))
	for i in n:
		var p0 := pts[i]
		var p1 := pts[i + 1]
		var nor := Vector3(p1.z - p0.z, 0, p0.x - p1.x).normalized()
		if nor.dot(p0 + p1) < 0.0:
			nor = -nor
		st.set_normal(nor)
		for v: Vector3 in [p0, p1, p1 + Vector3.UP * h, p0, p1 + Vector3.UP * h, p0 + Vector3.UP * h]:
			st.add_vertex(v)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(String(f.get("color", "#c9ccd1")))
	m.roughness = 0.8
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mm(root, "FachadaCurva", st.commit(), m, [Transform3D()])

## El «colchón»: filas de paneles alrededor del estadio, al tresbolillo, con luz propia del color dado. Un MultiMesh.
static func _colchon(root: Node3D, f: Dictionary, dx: float, dz: float, fondo: float, alto: float) -> void:
	var filas := int(f.get("filas", 4))
	var por_fila := 56
	var panel := BoxMesh.new()
	panel.size = Vector3(1.0, 1.0, 0.6)
	var paso_y := alto * 1.02 / filas
	var rc := radio_curva(dx, dz, fondo) + Vector2(0.4, 0.4)   ## el colchón va sobre la misma superelipse
	var ancho := 3.7 * (rc.x + rc.y) * 1.12 / por_fila   ## perímetro de la superelipse ≈ 3,7·(a+b)
	var trans: Array = []
	for fila in filas:
		for i in por_fila:
			var a := TAU * (float(i) + (0.5 if fila % 2 == 1 else 0.0)) / por_fila
			var c := cos(a)
			var sn := sin(a)
			var pos := Vector3(signf(c) * pow(absf(c), 0.5) * rc.x, paso_y * (fila + 0.5), signf(sn) * pow(absf(sn), 0.5) * rc.y)
			var nrm := Vector3(signf(c) * pow(absf(c), 1.5) / rc.x, 0, signf(sn) * pow(absf(sn), 1.5) / rc.y).normalized()
			var b := Basis.looking_at(-nrm, Vector3.UP) if nrm.length() > 0.5 else Basis()
			trans.append(Transform3D(Basis(b.x * ancho * 0.96, b.y * paso_y * 0.94, b.z), pos))
	var m := StandardMaterial3D.new()
	var col := Color(String(f.get("color", "#dc052d")))
	m.albedo_color = col.lightened(0.3)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 1.6
	m.roughness = 0.4
	_mm(root, "Colchon", panel, m, trans)
