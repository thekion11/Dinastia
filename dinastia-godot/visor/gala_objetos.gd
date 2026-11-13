class_name GalaObjetos
extends RefCounted
## LOS GALARDONES DE «LA RUTA», hechos por código (como `Trofeo3D`: siluetas propias que se reconocen de lejos, sin
## copiar ningún trofeo real). Todos sobre una peana oscura, de unos 45 cm, con la base en y = 0:
##   bota (oro) y bota_plata · guante (el del portero) · balon (el del mejor jugador) · orbita (el balón con su aro: el
##   del asistidor) · estrella (la revelación) · camiseta (el once ideal, con su «11») · hierro (la mancuerna del hombre
##   de hierro) · flecha (el gran salto) · guante_duelo (el del duelo ganado) · placa (con el escudo de TU club) ·
##   copa / continental / globo (los de `Trofeo3D`, en pequeño).

static func _metal(c: Color, rugosidad := 0.25) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.9
	m.roughness = rugosidad
	m.emission_enabled = true   ## un poco de luz propia: se ve también en el salón oscuro
	m.emission = c
	m.emission_energy_multiplier = 0.25
	return m

static func _pieza(padre: Node3D, malla: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO, escala := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = escala
	padre.add_child(mi)
	return mi

static func _caja(tam: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = tam
	return b

static func _cil(radio: float, alto: float, arriba := -1.0) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.bottom_radius = radio
	c.top_radius = radio if arriba < 0.0 else arriba
	c.height = alto
	c.radial_segments = 20
	return c

static func _bola(radio: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radio
	s.height = radio * 2.0
	s.radial_segments = 20
	s.rings = 10
	return s

static func crear(tipo: String, club: Club = null) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Galardon_" + tipo
	var oro := _metal(Color(0.95, 0.76, 0.32))
	var plata := _metal(Color(0.86, 0.87, 0.9))
	var negro := StandardMaterial3D.new()
	negro.albedo_color = Color(0.07, 0.06, 0.07)
	negro.roughness = 0.35
	if tipo in ["copa", "continental", "globo", "liga", "supercopa"]:
		var t := Trofeo3D.crear("mundial_clubes" if tipo == "globo" else tipo, 0.5)
		raiz.add_child(t)
		return raiz
	_pieza(raiz, _cil(0.11, 0.06), negro, Vector3(0, 0.03, 0))   ## la peana
	match tipo:
		"bota", "bota_plata":
			var m := oro if tipo == "bota" else plata
			_pieza(raiz, _caja(Vector3(0.1, 0.07, 0.26)), m, Vector3(0, 0.12, 0.02))              ## el pie
			_pieza(raiz, _bola(0.055), m, Vector3(0, 0.125, 0.15), Vector3.ZERO, Vector3(0.9, 0.65, 1.0))   ## la puntera
			_pieza(raiz, _cil(0.05, 0.14, 0.055), m, Vector3(0, 0.22, -0.07))                     ## la caña
			_pieza(raiz, _caja(Vector3(0.105, 0.015, 0.27)), negro, Vector3(0, 0.08, 0.02))        ## la suela
			for z: float in [-0.08, 0.0, 0.1]:
				for x: float in [-0.03, 0.03]:
					_pieza(raiz, _cil(0.008, 0.02), m, Vector3(x, 0.065, z))                       ## los tacos
		"guante":
			_pieza(raiz, _caja(Vector3(0.16, 0.17, 0.05)), oro, Vector3(0, 0.2, 0))                ## la palma
			_pieza(raiz, _cil(0.07, 0.07, 0.085), oro, Vector3(0, 0.09, 0))                        ## el puño
			for k in 4:
				var c := CapsuleMesh.new()
				c.radius = 0.02
				c.height = 0.13 if k in [1, 2] else 0.11
				_pieza(raiz, c, oro, Vector3(-0.06 + k * 0.04, 0.34, 0))                           ## los dedos
			var pulgar := CapsuleMesh.new()
			pulgar.radius = 0.021
			pulgar.height = 0.1
			_pieza(raiz, pulgar, oro, Vector3(0.105, 0.22, 0), Vector3(0, 0, -40))
		"balon", "orbita":
			var m2 := oro if tipo == "balon" else plata
			_pieza(raiz, _cil(0.02, 0.14, 0.045), m2, Vector3(0, 0.13, 0))                         ## el pie
			_pieza(raiz, _bola(0.11), m2, Vector3(0, 0.3, 0))
			if tipo == "orbita":
				var aro := TorusMesh.new()
				aro.inner_radius = 0.135
				aro.outer_radius = 0.155
				_pieza(raiz, aro, oro, Vector3(0, 0.3, 0), Vector3(25, 0, 15))                     ## el aro del pase
		"estrella":
			_pieza(raiz, _cil(0.012, 0.16), plata, Vector3(0, 0.14, 0))
			for k in 5:
				var punta := PrismMesh.new()
				punta.size = Vector3(0.07, 0.12, 0.035)
				var a := deg_to_rad(72.0 * k)
				_pieza(raiz, punta, oro, Vector3(sin(a) * 0.075, 0.3 + cos(a) * 0.075, 0), Vector3(0, 0, -72.0 * k))
			_pieza(raiz, _cil(0.055, 0.035), oro, Vector3(0, 0.3, 0), Vector3(90, 0, 0))
		"camiseta":
			_pieza(raiz, _caja(Vector3(0.2, 0.24, 0.03)), oro, Vector3(0, 0.2, 0))
			for lado: float in [-1.0, 1.0]:
				_pieza(raiz, _caja(Vector3(0.09, 0.07, 0.03)), oro, Vector3(0.13 * lado, 0.28, 0), Vector3(0, 0, 25.0 * lado))
			var n := Label3D.new()
			n.text = "11"
			n.font_size = 64
			n.pixel_size = 0.0022
			n.modulate = Color(0.12, 0.1, 0.06)
			n.position = Vector3(0, 0.2, 0.018)
			raiz.add_child(n)
		"hierro":
			var acero := _metal(Color(0.55, 0.58, 0.62), 0.4)
			_pieza(raiz, _cil(0.015, 0.26), acero, Vector3(0, 0.2, 0), Vector3(0, 0, 90))          ## la barra
			for lado2: float in [-1.0, 1.0]:
				_pieza(raiz, _cil(0.075, 0.04), acero, Vector3(0.11 * lado2, 0.2, 0), Vector3(0, 0, 90))
				_pieza(raiz, _cil(0.055, 0.03), acero, Vector3(0.145 * lado2, 0.2, 0), Vector3(0, 0, 90))
			_pieza(raiz, _cil(0.02, 0.1), negro, Vector3(0, 0.1, 0))
		"flecha":
			_pieza(raiz, _caja(Vector3(0.05, 0.2, 0.04)), oro, Vector3(0, 0.17, 0))
			var cabeza := PrismMesh.new()
			cabeza.size = Vector3(0.16, 0.13, 0.04)
			_pieza(raiz, cabeza, oro, Vector3(0, 0.335, 0))
		"guante_duelo":
			var rojo := _metal(Color(0.85, 0.22, 0.25), 0.45)
			_pieza(raiz, _bola(0.09), rojo, Vector3(0, 0.26, 0), Vector3.ZERO, Vector3(1.0, 1.15, 0.85))
			_pieza(raiz, _bola(0.04), rojo, Vector3(0.085, 0.22, 0.02))                            ## el pulgar
			_pieza(raiz, _cil(0.06, 0.08), oro, Vector3(0, 0.13, 0))                               ## el puño
		_:   ## "placa": madera con el escudo de tu club
			var madera := StandardMaterial3D.new()
			madera.albedo_color = Color(0.3, 0.19, 0.11)
			madera.roughness = 0.6
			_pieza(raiz, _caja(Vector3(0.26, 0.3, 0.025)), madera, Vector3(0, 0.22, 0))
			_pieza(raiz, _caja(Vector3(0.2, 0.035, 0.008)), oro, Vector3(0, 0.1, 0.015))
			if club != null:
				var q := QuadMesh.new()
				q.size = Vector2(0.17, 0.17)
				var me := StandardMaterial3D.new()
				me.albedo_texture = load("res://ui/escudo.gd").textura(club, 128)
				me.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				_pieza(raiz, q, me, Vector3(0, 0.25, 0.014))
	return raiz
