extends BaseIdea
## ULTRA PULIDO DEL ESTADIO (25-10-2026, agente «pest»). Lo que se puede comprobar sin GPU de lo que
## se pulió en la grada, la hinchada y los focos:
##   · las barandillas de los pasillos tienen postes VERTICALES (en el mundo, no en la rampa) y cada
##     bandeja su barandilla corrida en el borde de abajo;
##   · el sector visitante va marcado (alfa 0,5) y el resto de la grada no;
##   · `OlaGrada` sabe a qué hinchada le toca cada reacción y tiene la «ocasión»;
##   · los focos son bastidores orientados al campo con proyectores, no cajas.
## Lo visual se mira con `pruebas/captura_camara_tv.tscn`, `captura_exterior.tscn` y
## `captura_diagnostico_grada.tscn`.

func _probar() -> void:
	_titulo("PEST · ULTRA PULIDO DEL ESTADIO")
	Calidad.elegida = Calidad.ALTO
	var club := Club.new("pest_club", "Club Pulido")
	club.color1 = "#8a1c2b"
	club.color2 = "#f2d16b"
	var est := {"forma": "cuenco", "niveles": 2, "visita1": "#0044ff", "visita2": "#ffffff", "focos": "torres"}
	var raiz := Node3D.new()
	StadiumBuilder.build(raiz, est, 40000, 0.85, 4242, club)
	_barandillas(raiz)
	_visitantes(raiz)
	_focos(raiz)
	_reacciones(raiz)
	raiz.free()

## La transformación de un nodo respecto de `raiz` (el estadio no está en el árbol de escena).
func _en_raiz(n: Node3D, raiz: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var p: Node = n
	while p != null and p != raiz:
		if p is Node3D:
			xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf

## ¿Se pueden leer los datos de un MultiMesh? Sin GPU (`--headless`) el servidor de dibujo no los
## guarda y todo sale a cero: entonces lo que depende de leerlos se comprueba con las funciones puras.
func _multimesh_legible() -> bool:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = 1
	mm.set_instance_transform(0, Transform3D(Basis(), Vector3(1, 2, 3)))
	mm.set_instance_color(0, Color(1, 1, 1, 0.5))
	return mm.get_instance_transform(0).origin == Vector3(1, 2, 3) and is_equal_approx(mm.get_instance_color(0).a, 0.5)

func _barandillas(raiz: Node3D) -> void:
	var nodos := raiz.find_children("Barandillas", "MultiMeshInstance3D", true, false)
	_comprobar(nodos.size() >= 16, "cada bandeja (y cada esquina) lleva su barandilla (%d)" % nodos.size())
	## Siguen en una sola llamada de dibujo por bandeja: una caja unidad compartida.
	var malla: Mesh = (nodos[0] as MultiMeshInstance3D).multimesh.mesh if not nodos.is_empty() else null
	var compartida := malla != null
	for n: Node in nodos:
		compartida = compartida and (n as MultiMeshInstance3D).multimesh.mesh == malla
	_comprobar(compartida, "todas las barandillas comparten la misma malla")
	## Las piezas, con una rampa de verdad (33°) en los dos ejes y los dos sentidos.
	var postes := 0
	var torcidos := 0
	var corridas := 0
	for lateral: bool in [true, false]:
		for signo: float in [1.0, -1.0]:
			var rake := deg_to_rad(StadiumBuilder.RAKE_GRADOS) * signo
			var eje := Vector3(0, 0, 1) if lateral else Vector3(1, 0, 0)
			var deck := Basis().rotated(eje, rake)
			var l: Array[float] = [-10.0, 0.0, 10.0]
			var piezas := StadiumBuilder._piezas_baranda(l, lateral, 10.0, 60.0, signo, rake)
			for t0: Transform3D in piezas:
				var t := Transform3D(deck, Vector3.ZERO) * t0
				var ejes := [t.basis.x.length(), t.basis.y.length(), t.basis.z.length()]
				if ejes[1] > 0.5 and ejes[0] < 0.06 and ejes[2] < 0.06:
					postes += 1
					if t.basis.y.normalized().y < 0.995:
						torcidos += 1
				elif maxf(ejes[0], ejes[2]) > 30.0 and ejes[1] < 0.06:
					var dir: Vector3 = t.basis.x if ejes[0] > ejes[2] else t.basis.z
					if absf(dir.normalized().y) < 0.01:
						corridas += 1
	_comprobar(postes >= 4 * (3 * 5 + 20), "pasamanos con postes y barandilla del borde con los suyos (%d)" % postes)
	_comprobar(torcidos == 0, "todos los postes quedan verticales en el mundo (%d torcidos)" % torcidos)
	_comprobar(corridas == 8, "el borde de cada bandeja lleva dos tubos corridos horizontales (%d de 8)" % corridas)

func _visitantes(raiz: Node3D) -> void:
	if not _multimesh_legible():
		_linea("  (sin GPU no se leen los MultiMesh: el sector visitante se comprueba con «--rendering-driver vulkan»)")
		return
	var visita := 0
	var casa := 0
	var mal_puestos := 0
	for n: Node in raiz.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		var sm := mmi.material_override as ShaderMaterial
		if sm == null or not sm.shader.resource_path.ends_with("hinchada.gdshader"):
			continue
		var mm := mmi.multimesh
		if not mm.use_colors:
			continue
		var xf := _en_raiz(mmi, raiz)
		for k in mm.instance_count:
			if mm.get_instance_color(k).a < 0.75:
				visita += 1
				if (xf * mm.get_instance_transform(k).origin).z > 0.0:
					mal_puestos += 1
			else:
				casa += 1
	_comprobar(visita > 20, "el sector visitante está marcado (%d hinchas)" % visita)
	_comprobar(casa > visita * 10, "el resto de la grada es de casa (%d)" % casa)
	_comprobar(mal_puestos == 0, "los visitantes están en el fondo −Z (%d fuera)" % mal_puestos)

func _focos(raiz: Node3D) -> void:
	var pr := raiz.find_child("ProyectoresFocos", true, false) as MultiMeshInstance3D
	_comprobar(pr != null and pr.multimesh.instance_count == 4 * 18, "cuatro torres con 18 proyectores cada una")
	var bastidores := raiz.find_children("BastidorFoco*", "MeshInstance3D", true, false)
	var bien := 0
	for b: Node in bastidores:
		var t := _en_raiz(b as Node3D, raiz)
		var mira := -t.basis.z.normalized()
		var hacia := (Vector3.ZERO - t.origin)
		hacia.y = 0.0
		if mira.y < -0.15 and Vector2(mira.x, mira.z).normalized().dot(Vector2(hacia.x, hacia.z).normalized()) > 0.9:
			bien += 1
	_comprobar(bastidores.size() == 4 and bien == 4, "los bastidores miran al campo y hacia abajo (%d/%d)" % [bien, bastidores.size()])

func _reacciones(raiz: Node3D) -> void:
	var mats := OlaGrada.materiales(raiz)
	_comprobar(not mats.is_empty(), "hay materiales de hinchada")
	if mats.is_empty():
		return
	var m: ShaderMaterial = mats[0]
	var oc := OlaGrada.lanzar(raiz, "ocasion", Vector3.ZERO, 1)
	_comprobar(oc != null and oc._dura == OlaGrada.DURA_OCASION and float(m.get_shader_parameter("ocasion_edad")) == 0.0,
		"ocasión: la grada se levanta de golpe")
	_comprobar(float(m.get_shader_parameter("ocasion_bando")) == 1.0, "ocasión: le toca a la hinchada visitante")
	oc._process(OlaGrada.DURA_OCASION + 0.1)
	_comprobar(float(m.get_shader_parameter("ocasion_edad")) == -1.0, "ocasión: al terminar se apaga")
	var on := OlaGrada.lanzar(raiz, "onda", Vector3(0, 0, 62))
	_comprobar(on != null and float(m.get_shader_parameter("onda_bando")) == 0.0, "onda de un gol de casa: solo la hinchada de casa")
	_comprobar(OlaGrada.lanzar(raiz, "inventada") == null, "un tipo de reacción que no existe no hace nada")
