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
## esquinas). Recorre los decks que llevan «Pasillos» (de `_butacas`) y vuelve a
## sacar, con LA MISMA cuenta que `_butacas`/`_escaleras_de_acceso`, dónde está cada
## peldaño: no se leen los MultiMesh (sin pantalla no guardan sus datos). Cuelga al
## lado los cantos de los pasillos y, en la bandeja baja, los cantos, las zancas y
## el pasamanos de las escaleras que bajan al césped.
## OJO: si cambia el reparto de pasillos de `_butacas` (`es_pasillo`, `PASO_*`) esto
## lo sigue solo; si cambia la posición de los peldaños, hay que tocarlo aquí también
## (lo vigila `pruebas/ideas/pgra_grada.gd`: un canto por peldaño).
static func vestir_escaleras(root: Node3D, mat_baranda: Material) -> void:
	var cantos_acc: Array[Transform3D] = []
	var zancas: Array[Transform3D] = []
	var tubos: Array[Transform3D] = []
	var y_bandeja0 := StadiumBuilder.ALTURA_PIE + StadiumBuilder.subida_bandeja() / 2.0
	for n: Node in root.find_children("Pasillos", "MultiMeshInstance3D", true, false):
		var deck := n.get_parent() as MeshInstance3D
		if deck == null or deck.has_meta("vestido"):
			continue
		deck.set_meta("vestido", true)
		var plano := deck.mesh is PlaneMesh
		var tam := Vector3.ZERO
		if plano:
			tam = Vector3((deck.mesh as PlaneMesh).size.x, 0.4, (deck.mesh as PlaneMesh).size.y)
		elif deck.mesh is BoxMesh:
			tam = (deck.mesh as BoxMesh).size
		else:
			continue
		## Las esquinas son siempre «laterales» (ver `_esquina_grada`).
		var lateral := plano or tam.x < tam.z
		var rake: float = deg_to_rad(StadiumBuilder.RAKE_GRADOS) if plano else (deck.rotation.z if lateral else deck.rotation.x)
		var escalones := escalones_de(deck, tam, lateral, rake)
		multi(deck, "CantosPasillo", cantos_pasillo(escalones, StadiumBuilder.PASO_FILA + 0.02), mat_canto())
		if not plano:
			multi(deck, "ZancasPasillo", zancas_pasillo(escalones, tam, lateral), mat_zanca())
		if plano or deck.get_parent() != root or absf(deck.position.y - y_bandeja0) > 0.1:
			continue
		## Escaleras de acceso: desde el primer peldaño de cada pasillo (fila 0).
		var largo: float = tam.z if lateral else tam.x
		var cuantas: int = maxi(1, int(largo / StadiumBuilder.PASO_BUTACA))
		var por_columna := 0
		for c in cuantas:
			if StadiumBuilder.es_pasillo(c, cuantas):
				por_columna += 1
		if por_columna == 0:
			continue
		for k in por_columna:
			var bajo := deck.transform * escalones[k].origin
			if bajo.y < 0.5:
				continue
			var dir := Vector3(-signf(bajo.x), 0, 0) if lateral else Vector3(0, 0, -signf(bajo.z))
			var np := int(ceil((bajo.y - 0.05) / StadiumBuilder.PELDANO_ALTO))
			var piezas := piezas_escalera(bajo, dir, np, StadiumBuilder.PELDANO_ALTO, StadiumBuilder.PELDANO_FONDO, 1.25)
			cantos_acc.append_array(piezas[0])
			zancas.append_array(piezas[1])
			tubos.append_array(piezas[2])
	multi(root, "CantosAcceso", cantos_acc, mat_canto())
	multi(root, "ZancasAcceso", zancas, mat_zanca())
	multi(root, "PasamanosAcceso", tubos, mat_baranda)

## ZANCAS DE LOS PASILLOS DE TODAS LAS BANDEJAS (27-10-2026, decisión del líder «las altas llevan zancas y barandilla como la baja»): un murete
## de hormigón a cada lado de cada pasillo, de la primera a la última fila, siguiendo la pendiente (la barandilla ya la pone `_montar_pasillos`).
## En el espacio del deck. `escalones` viene fila a fila con `por_fila` pasillos por fila.
static func zancas_pasillo(escalones: Array[Transform3D], tam: Vector3, lateral: bool) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	var largo: float = tam.z if lateral else tam.x
	var cuantas: int = maxi(1, int(largo / StadiumBuilder.PASO_BUTACA))
	var por_fila := 0
	for c in cuantas:
		if StadiumBuilder.es_pasillo(c, cuantas):
			por_fila += 1
	if por_fila == 0 or escalones.size() < por_fila * 2:
		return out
	var filas := escalones.size() / por_fila
	var perp := Vector3(0, 0, 1) if lateral else Vector3(1, 0, 0)
	for k in por_fila:
		var p0 := escalones[k].origin
		var p1 := escalones[(filas - 1) * por_fila + k].origin
		var eje := p1 - p0
		var longitud := eje.length() + StadiumBuilder.PASO_FILA
		var z := eje.normalized()
		var x := perp
		var y := z.cross(x).normalized()
		if y.y < 0.0:
			y = -y
		for lado: float in [-1.0, 1.0]:
			var centro := (p0 + p1) * 0.5 + perp * lado * 0.69 + Vector3(0, 0.22, 0) + y * 0.0
			out.append(Transform3D(Basis(x * 0.12, y * 0.34, z * longitud), centro))
	return out

## Los peldaños de los pasillos de un deck, en su espacio, fila a fila (la fila 0
## primero) y en cada fila de izquierda a derecha: la cuenta de `_butacas`.
static func escalones_de(deck: MeshInstance3D, tam: Vector3, lateral: bool, rake: float) -> Array[Transform3D]:
	var largo: float = tam.z if lateral else tam.x
	var fondo: float = tam.x if lateral else tam.z
	var cuantas: int = maxi(1, int(largo / StadiumBuilder.PASO_BUTACA))
	var filas: int = maxi(1, int(fondo / StadiumBuilder.PASO_FILA))
	var eje_fondo := Vector3(1, 0, 0) if lateral else Vector3(0, 0, 1)
	var sentido: float = 1.0 if (deck.basis * eje_fondo).y >= 0.0 else -1.0
	var giro: float = (-sentido * PI * 0.5) if lateral else (PI if sentido > 0.0 else 0.0)
	var eje_rake := Vector3(0, 0, 1) if lateral else Vector3(1, 0, 0)
	var base := Basis().rotated(Vector3.UP, giro)
	if rake != 0.0:
		base = base.rotated(eje_rake, -rake)
	var out: Array[Transform3D] = []
	for f in filas:
		var d: float = sentido * (-fondo * 0.5 + 0.6 + f * StadiumBuilder.PASO_FILA)
		for c in cuantas:
			if not StadiumBuilder.es_pasillo(c, cuantas):
				continue
			var l: float = -largo * 0.5 + 0.8 + c * StadiumBuilder.PASO_BUTACA
			var p := Vector3(d, 0.24, l) if lateral else Vector3(l, 0.24, d)
			out.append(Transform3D(base, p + Vector3(0, -0.13, 0)))
	return out

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
	var nodo := Node3D.new()
	nodo.position = centro
	root.add_child(nodo)
	return multi(nodo, "VigasTecho", piezas_vigas(tam, cara, lateral), mat)

## Las piezas de `vigas_techo`, relativas al centro de la losa.
static func piezas_vigas(tam: Vector3, cara: Vector3, lateral: bool) -> Array[Transform3D]:
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
	return xfs
