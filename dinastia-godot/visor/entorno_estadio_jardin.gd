class_name EntornoEstadioJardin
extends RefCounted
## LA EXPLANADA DEL ESTADIO (26-10-2026, «el exterior no es creíble»). Visto con
## la cámara a pie de calle (`pruebas/ideas/_pgra_captura.gd`, toma «llegada»):
## entre la plaza y la avenida no había nada, solo el hormigón oscuro de relleno
## de `StadiumBuilder._explanada_de_fondo` (un solar de 30 m de ancho alrededor
## de todo el recinto). Ahora es un parque urbano: césped, paseos de losa que
## llevan de la avenida a la plaza, jardineras con seto en el borde de la plaza y
## bolardos donde los paseos entran en ella.
## Barato: 2 planos de césped/losa por lado y 3 MultiMesh para todo (unas 12
## llamadas), sin sombra los bolardos.
##   EntornoEstadioJardin.montar(e, px, pz, cx, cz, calle)  (lo llama EntornoEstadio)

const ANCHO_PASEO := 8.0

static func montar(e: Node3D, px: float, pz: float, cx: float, cz: float, calle: float) -> void:
	## Hasta el bordillo interior de la acera de la avenida.
	var bx := cx - calle * 0.5 - 3.0
	var bz := cz - calle * 0.5 - 3.0
	var cesped: StandardMaterial3D = Texturas.cesped(Color(0.32, 0.47, 0.25), 37)
	EntornoEstadio._plano(e, Vector2(bx * 2.0, bz * 2.0), Vector3(0, -0.135, 0), cesped)
	var losa: StandardMaterial3D = Texturas.baldosa(Color(0.7, 0.68, 0.64), 13).duplicate()
	losa.uv1_scale = Vector3(0.45, 0.45, 0.45)
	var paseos := paseos_de(px, pz, bx, bz)
	for pa: Array in paseos:
		EntornoEstadio._plano(e, pa[1], pa[0], losa)
	_borde_plaza(e, px, pz, paseos)

## Los paseos: dónde cruzan la franja de césped en cada lado. Cada uno es
## [centro, tamaño, normal del lado]. Por −X y −Z van los aparcamientos: allí los
## paseos salen del centro (de los coches a la plaza) y pasan por sus puntas.
static func paseos_de(px: float, pz: float, bx: float, bz: float) -> Array:
	var en_x: Array = [0.0, -pz * 0.55, pz * 0.55]
	var en_z: Array = [0.0, -px * 0.55, px * 0.55]
	var punta_x := pz * 0.7 + 7.0
	var punta_z := px * 0.7 + 7.0
	var paseos: Array = []
	for s: float in [1.0, -1.0]:
		var lista_x: Array = en_x if s > 0.0 else [0.0, -punta_x, punta_x]
		for t: float in lista_x:
			if absf(t) + ANCHO_PASEO * 0.5 < pz:
				paseos.append([Vector3(s * (px + bx) * 0.5, -0.125, t), Vector2(bx - px, ANCHO_PASEO), Vector3(s, 0, 0)])
		var lista_z: Array = en_z if s > 0.0 else [0.0, -punta_z, punta_z]
		for t: float in lista_z:
			if absf(t) + ANCHO_PASEO * 0.5 < px:
				paseos.append([Vector3(t, -0.125, s * (pz + bz) * 0.5), Vector2(ANCHO_PASEO, bz - pz), Vector3(0, 0, s)])
	return paseos

## Jardineras con seto a lo largo del borde de la plaza (dejando libres los
## paseos y las esquinas) y bolardos a la entrada de cada paseo.
static func _borde_plaza(e: Node3D, px: float, pz: float, paseos: Array) -> void:
	var piezas := piezas_borde(px, pz, paseos)
	var macetas: Array[Transform3D] = piezas["macetas"]
	var setos: Array[Transform3D] = piezas["setos"]
	var bolardos: Array[Transform3D] = piezas["bolardos"]
	var hormigon: StandardMaterial3D = Texturas.hormigon(Color(0.68, 0.67, 0.63), 19).duplicate()
	hormigon.uv1_world_triplanar = true
	hormigon.uv1_scale = Vector3(0.5, 0.5, 0.5)
	hormigon.normal_enabled = false
	var hoja := StandardMaterial3D.new()
	hoja.albedo_texture = (Texturas.enredadera(29) as StandardMaterial3D).albedo_texture
	hoja.albedo_color = Color(0.85, 1.0, 0.8)
	hoja.uv1_triplanar = true
	hoja.uv1_world_triplanar = true
	hoja.uv1_scale = Vector3(0.6, 0.6, 0.6)
	hoja.roughness = 0.9
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.24, 0.25, 0.27)
	metal.metallic = 0.5
	metal.roughness = 0.4
	DetalleGrada.multi(e, "Jardineras", macetas, hormigon)
	DetalleGrada.multi(e, "Setos", setos, hoja)
	var bol := DetalleGrada.multi(e, "Bolardos", bolardos, metal)
	if bol != null:
		bol.visibility_range_end = 160.0

## Dónde va cada jardinera, seto y bolardo (en el mundo).
static func piezas_borde(px: float, pz: float, paseos: Array) -> Dictionary:
	var macetas: Array[Transform3D] = []
	var setos: Array[Transform3D] = []
	var bolardos: Array[Transform3D] = []
	var largo_j := 7.0
	for lado: int in 4:
		var n := Vector3(1, 0, 0) if lado == 0 else (Vector3(-1, 0, 0) if lado == 1 else (Vector3(0, 0, 1) if lado == 2 else Vector3(0, 0, -1)))
		var a_lo_largo := Vector3(-n.z, 0, n.x)
		var mitad := pz if absf(n.x) > 0.5 else px
		var borde := px if absf(n.x) > 0.5 else pz
		## Los huecos: los paseos de este lado (en coordenada a lo largo).
		var huecos: Array = []
		for pa: Array in paseos:
			if (pa[2] as Vector3).is_equal_approx(n):
				var cen: Vector3 = pa[0]
				huecos.append(cen.dot(a_lo_largo))
		var t := -mitad + 10.0
		while t + largo_j < mitad - 10.0:
			var medio := t + largo_j * 0.5
			var libre := true
			for h: float in huecos:
				if absf(medio - h) < ANCHO_PASEO * 0.5 + largo_j * 0.5 + 1.0:
					libre = false
			if libre:
				var c := n * (borde + 1.6) + a_lo_largo * medio
				var giro := Basis(Vector3.UP, atan2(a_lo_largo.x, a_lo_largo.z))
				macetas.append(Transform3D(giro.scaled_local(Vector3(1.6, 0.55, largo_j)), c + Vector3(0, 0.15, 0)))
				setos.append(Transform3D(giro.scaled_local(Vector3(1.3, 0.55, largo_j - 0.3)), c + Vector3(0, 0.6, 0)))
			t += largo_j + 2.5
		## Bolardos en la boca de cada paseo.
		for h: float in huecos:
			for k in 6:
				var dl := (float(k) - 2.5) * 1.5
				bolardos.append(Transform3D(Basis.from_scale(Vector3(0.22, 0.9, 0.22)), n * (borde + 0.6) + a_lo_largo * (h + dl) + Vector3(0, 0.33, 0)))
	return {"macetas": macetas, "setos": setos, "bolardos": bolardos}
