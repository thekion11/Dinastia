class_name DetalleGrada
extends RefCounted
## LO QUE HACE CREÍBLE UNA GRADA (26-10-2026, «cajas grises» y «tribunas falsas»).
## Visto con la cámara real del partido (`pruebas/ideas/_pgra_captura.gd`): las
## escaleras que suben del césped a la grada eran cuñas grises lisas -cada peldaño
## una caja del mismo gris, sin canto ni barandilla- y desde la tele se leían como
## rampas de cartón. Aquí, piezas de detalle que se cuelgan de lo que ya existe:
##   · el canto de cada peldaño en amarillo de seguridad (como en cualquier estadio),
##     en los pasillos de la grada y en las escaleras de acceso;
##   · las zancas (los muretes laterales) y el pasamanos de las escaleras de acceso.
## Todo son instancias de una caja unidad: UNA llamada de dibujo por material y
## tribuna, sin sombra propia (como las butacas).

const AMARILLO := Color(0.93, 0.76, 0.16)
static var _mat_canto: StandardMaterial3D
static var _mat_zanca: StandardMaterial3D
static var _caja: BoxMesh

static func _unidad() -> BoxMesh:
	if _caja == null:
		_caja = BoxMesh.new()
	return _caja

static func mat_canto() -> StandardMaterial3D:
	if _mat_canto == null:
		_mat_canto = StandardMaterial3D.new()
		_mat_canto.albedo_color = AMARILLO
		_mat_canto.roughness = 0.6
	return _mat_canto

static func mat_zanca() -> StandardMaterial3D:
	if _mat_zanca == null:
		_mat_zanca = Texturas.hormigon(Color(0.58, 0.58, 0.6), 97).duplicate()
		_mat_zanca.uv1_world_triplanar = true
		_mat_zanca.uv1_scale = Vector3(0.5, 0.5, 0.5)
		_mat_zanca.normal_enabled = false
	return _mat_zanca

## Un MultiMesh de cajas unidad con `xfs`, colgado de `padre`.
static func multi(padre: Node3D, nombre: String, xfs: Array[Transform3D], mat: Material) -> MultiMeshInstance3D:
	if xfs.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _unidad()
	mm.instance_count = xfs.size()
	for k in xfs.size():
		mm.set_instance_transform(k, xfs[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nombre
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(mmi)
	return mmi

## Los cantos de los peldaños de los pasillos de una bandeja (en el espacio del
## deck). `escalones` son las cajas de `_montar_pasillos` (1,25 × 0,42 × fila):
## su +Z local mira al campo y van de pie, así que el canto es la arista de
## arriba de su cara +Z.
static func cantos_pasillo(escalones: Array[Transform3D], fondo_fila: float) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	var pieza := Transform3D(Basis.from_scale(Vector3(1.27, 0.05, 0.09)), Vector3(0.0, 0.195, fondo_fila * 0.5 - 0.04))
	for e: Transform3D in escalones:
		## Las columnas de pasillo de las filas sin escalón (escala cero) no existen.
		if e.basis.get_scale().x < 0.01:
			continue
		out.append(Transform3D(e.basis.orthonormalized(), e.origin) * pieza)
	return out

## Una escalera de acceso del campo a la grada: `bajo` es el primer peldaño de la
## grada (en el mundo), `dir` el sentido hacia el campo (horizontal), `n` los
## peldaños. Devuelve [cantos, zancas, pasamanos] para sumar a los MultiMesh.
static func piezas_escalera(bajo: Vector3, dir: Vector3, n: int, alto_p: float, fondo_p: float,
		ancho: float) -> Array:
	var cantos: Array[Transform3D] = []
	var zancas: Array[Transform3D] = []
	var tubos: Array[Transform3D] = []
	var perp := Vector3.UP.cross(dir).normalized()
	for k in n:
		var alto := bajo.y - float(k) * alto_p
		var c := bajo + dir * (0.45 + float(k) * fondo_p + fondo_p * 0.5 - 0.035)
		c.y = alto - 0.1 - 0.02
		cantos.append(Transform3D(Basis(perp * (ancho + 0.02), Vector3.UP * 0.05, dir * 0.075), c))
	if n < 2:
		return [cantos, zancas, tubos]
	## La línea de los cantos, de arriba abajo: por ella van la zanca y el pasamanos.
	var arriba := bajo + dir * (0.45) + Vector3(0, -0.1, 0)
	var abajo := bajo + dir * (0.45 + float(n) * fondo_p) + Vector3(0, -0.1 - float(n) * alto_p, 0)
	abajo.y = maxf(abajo.y, 0.0)
	var eje := abajo - arriba
	var largo := eje.length()
	var z := eje / largo
	var y := z.cross(perp).normalized()
	if y.y < 0.0:
		y = -y
	for lado: float in [-1.0, 1.0]:
		var borde := perp * lado * (ancho * 0.5 + 0.07)
		## La zanca: un murete inclinado de 0,14 m que tapa la punta de los peldaños.
		var centro_z := (arriba + abajo) * 0.5 + borde + y * 0.08
		zancas.append(Transform3D(Basis(perp * 0.14, y * 0.42, z * (largo + 0.3)), centro_z))
		## El pasamanos, a 0,9 m sobre la zanca, con un poste en cada punta y uno al medio.
		tubos.append(Transform3D(Basis(perp * 0.05, y * 0.05, z * largo), centro_z + Vector3.UP * 0.95))
		for t: float in [0.04, 0.5, 0.96]:
			var p := arriba.lerp(abajo, t) + borde + Vector3.UP * 0.6
			tubos.append(Transform3D(Basis.from_scale(Vector3(0.045, 0.85, 0.045)), p))
	return [cantos, zancas, tubos]

## VESTIR LO QUE YA LEVANTÓ LA GRADA (se llama al final de las tribunas y las
## esquinas). Lee las cajas que dejaron `_montar_pasillos` («Pasillos», en cada
## deck) y `_escaleras_de_acceso` («EscalerasAcceso», en la raíz) y les añade el
## canto de los peldaños y, a las de acceso, sus zancas y pasamanos. No toca las
## piezas de origen: solo cuelga MultiMesh nuevos al lado.
static func vestir_escaleras(root: Node3D, mat_baranda: Material) -> void:
	var cantos_acc: Array[Transform3D] = []
	var zancas: Array[Transform3D] = []
	var tubos: Array[Transform3D] = []
	for n: Node in root.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		if mmi.multimesh == null or mmi.has_meta("vestida"):
			continue
		mmi.set_meta("vestida", true)
		var nombre := String(mmi.name)
		var mm := mmi.multimesh
		if nombre.contains("Pasillos") and mm.mesh is BoxMesh:
			var esc: Array[Transform3D] = []
			for k in mm.instance_count:
				esc.append(mm.get_instance_transform(k))
			multi(mmi.get_parent() as Node3D, "CantosPasillo", cantos_pasillo(esc, (mm.mesh as BoxMesh).size.z), mat_canto())
		elif nombre.contains("EscalerasAcceso") and mmi.get_parent() == root:
			_vestir_acceso(mmi, cantos_acc, zancas, tubos)
	multi(root, "CantosAcceso", cantos_acc, mat_canto())
	multi(root, "ZancasAcceso", zancas, mat_zanca())
	multi(root, "PasamanosAcceso", tubos, mat_baranda)

## Agrupa los peldaños de «EscalerasAcceso» por escalera (misma línea y mismo
## lado) y saca de cada una sus piezas con `piezas_escalera`.
static func _vestir_acceso(mmi: MultiMeshInstance3D, cantos: Array[Transform3D], zancas: Array[Transform3D],
		tubos: Array[Transform3D]) -> void:
	var mm := mmi.multimesh
	var grupos := {}
	for k in mm.instance_count:
		var xf := mmi.transform * mm.get_instance_transform(k)
		var e := xf.basis.get_scale()
		var lateral := e.x < e.z
		var o := xf.origin
		var clave := "%s|%d|%d" % [lateral, roundi((o.z if lateral else o.x) * 10.0), signi(roundi(o.x if lateral else o.z))]
		if not grupos.has(clave):
			grupos[clave] = []
		(grupos[clave] as Array).append([o.y + e.y * 0.5, o, lateral, minf(e.x, e.z), maxf(e.x, e.z)])
	for clave: String in grupos:
		var pel: Array = grupos[clave]
		pel.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
		var p0: Array = pel[0]
		var o0: Vector3 = p0[1]
		var lateral: bool = p0[2]
		var dir := Vector3(-signf(o0.x), 0, 0) if lateral else Vector3(0, 0, -signf(o0.z))
		var fondo_p: float = p0[3]
		## El primer peldaño está a 0,45 m del de la grada y su cara de arriba,
		## 0,1 m por debajo (ver `_escaleras_de_acceso`).
		var bajo := o0 - dir * 0.45
		bajo.y = float(p0[0]) + 0.1
		var alto_p := 0.18
		if pel.size() > 1:
			alto_p = float(pel[0][0]) - float(pel[1][0])
		var piezas := piezas_escalera(bajo, dir, pel.size(), alto_p, fondo_p, float(p0[4]))
		cantos.append_array(piezas[0])
		zancas.append_array(piezas[1])
		tubos.append_array(piezas[2])

## LA CUBIERTA VISTA DESDE ABAJO (26-10-2026). Desde la cámara de TV el techo de
## enfrente se ve por debajo, y era una losa lisa de 0,5 m: una tabla flotando.
## Ahora lleva su estructura: las vigas en ménsula que la sostienen (cada ~9 m,
## más altas atrás, donde empotran en la tribuna) y el canto del borde (una
## visera de 1,1 m que da la línea limpia del techo). Un MultiMesh por tribuna,
## colgado del centro de la losa para que `ocultar_techo_ante` lo esconda con
## ella cuando la cámara está detrás.
## `centro`: el centro de la losa; `tam`: su tamaño; `cara`: hacia el campo.
static func vigas_techo(root: Node3D, centro: Vector3, tam: Vector3, cara: Vector3, lateral: bool,
		mat: Material) -> GeometryInstance3D:
	var largo := tam.z if lateral else tam.x
	var fondo := tam.x if lateral else tam.z
	var a_lo_largo := Vector3(0, 0, 1) if lateral else Vector3(1, 0, 0)
	var y_bajo := -tam.y * 0.5
	var xfs: Array[Transform3D] = []
	var n := maxi(2, int(largo / 9.0))
	for k in n + 1:
		var l := -largo * 0.5 + 1.0 + (largo - 2.0) * float(k) / float(n)
		## Dos tramos: el de atrás más alto (empotrado) y el vuelo más fino.
		for tramo: Vector3 in [Vector3(-0.25, 1.1, 0.5), Vector3(0.22, 0.65, 0.44)]:
			var c := a_lo_largo * l + cara * (fondo * tramo.x) + Vector3(0, y_bajo - tramo.y * 0.5, 0)
			var esc := Vector3(fondo * tramo.z, tramo.y, 0.32) if lateral else Vector3(0.32, tramo.y, fondo * tramo.z)
			xfs.append(Transform3D(Basis.from_scale(esc), c))
	## El canto del borde, a todo lo largo.
	var esc_c := Vector3(0.3, 1.1, largo) if lateral else Vector3(largo, 1.1, 0.3)
	xfs.append(Transform3D(Basis.from_scale(esc_c), cara * (fondo * 0.5 - 0.15) + Vector3(0, -0.3, 0)))
	## Una correa a media luz, a todo lo largo.
	var esc_r := Vector3(0.25, 0.35, largo) if lateral else Vector3(largo, 0.35, 0.25)
	xfs.append(Transform3D(Basis.from_scale(esc_r), cara * (fondo * 0.05) + Vector3(0, y_bajo - 0.2, 0)))
	var nodo := Node3D.new()
	nodo.position = centro
	root.add_child(nodo)
	return multi(nodo, "VigasTecho", xfs, mat)
