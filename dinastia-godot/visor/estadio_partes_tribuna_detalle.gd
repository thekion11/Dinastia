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
