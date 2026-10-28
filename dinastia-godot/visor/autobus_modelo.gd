class_name AutobusModelo
extends RefCounted
## EL AUTOBÚS DE LA CIUDAD (modelo procedural; antes `CityBuilder.autobus`, sacado el 28-10-2026 al crecer con la librea «Red»,
## los pasos de rueda, el parabrisas inclinado y los espejos). Mira a +Z; las puertas van del lado de la acera (`PasajerosBus.lado_puerta`).

static func crear(col: Color, destino: String = "", numero: String = "") -> Node3D:
	var raiz := Node3D.new()
	## LIBREA «RED» (28-10-2026, orden 13): cuerpo blanco con el faldón rojo, el filete del color del recorrido (`col`) y cristales oscuros.
	var rojo_red := StandardMaterial3D.new()
	rojo_red.albedo_color = Color(0.70, 0.03, 0.11)
	rojo_red.roughness = 0.6
	rojo_red.metallic_specular = 0.3
	var filete := StandardMaterial3D.new()
	filete.albedo_color = col
	filete.roughness = 0.6
	var blanco := StandardMaterial3D.new()
	blanco.albedo_color = Color(0.95, 0.95, 0.94)
	blanco.roughness = 0.5
	blanco.metallic_specular = 0.3
	var vidrio := InteriorBus.vidrio()
	var goma := StandardMaterial3D.new()
	goma.albedo_color = Color(0.05, 0.05, 0.055)
	goma.roughness = 0.9
	var llanta := StandardMaterial3D.new()
	llanta.albedo_color = Color(0.7, 0.72, 0.75)
	llanta.metallic = 0.8
	llanta.roughness = 0.35
	var negro := StandardMaterial3D.new()
	negro.albedo_color = Color(0.03, 0.03, 0.035)
	negro.roughness = 0.7
	var piezas := [
		[Vector3(0, 1.0, 0), Vector3(2.55, 1.2, 12.0), blanco],            ## faldón
		[Vector3(0, 0.78, 0), Vector3(2.57, 0.55, 12.02), rojo_red],       ## banda roja baja
		[Vector3(0, 1.17, 0), Vector3(2.57, 0.06, 12.02), filete],         ## filete del recorrido
		[Vector3(0, 2.3, 0), Vector3(2.5, 1.4, 11.9), vidrio],             ## ventanas
		[Vector3(0, 3.05, 0), Vector3(2.55, 0.2, 12.0), blanco],           ## techo
		[Vector3(0, 3.25, -1.5), Vector3(1.8, 0.25, 3.0), blanco],         ## climatizador
		[Vector3(0, 1.0, 6.02), Vector3(2.4, 0.5, 0.05), blanco],          ## parachoques
		[Vector3(0, 0.62, 6.04), Vector3(2.5, 0.3, 0.06), negro],          ## faldón del morro
		[Vector3(0, 2.85, 6.0), Vector3(1.8, 0.28, 0.06), null],           ## rótulo
	]
	for pz: Array in piezas:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = pz[1]
		mi.mesh = bm
		mi.position = pz[0]
		if pz[2] != null:
			mi.material_override = pz[2]
		else:
			var led := StandardMaterial3D.new()
			led.albedo_color = Color(1.0, 0.7, 0.1)
			led.emission_enabled = true
			led.emission = Color(1.0, 0.6, 0.1)
			led.emission_energy_multiplier = 1.5
			mi.material_override = led
		raiz.add_child(mi)
	## Parabrisas inclinado (la parte de arriba retrasada 14°), con su marco.
	var pb := MeshInstance3D.new()
	var pbm := BoxMesh.new()
	pbm.size = Vector3(2.34, 1.5, 0.08)
	pb.mesh = pbm
	pb.material_override = vidrio
	pb.position = Vector3(0, 2.3, 5.94)
	pb.rotation_degrees.x = -14.0
	raiz.add_child(pb)
	var marco := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(2.5, 0.08, 0.12)
	marco.mesh = mm
	marco.material_override = negro
	marco.position = Vector3(0, 3.0, 5.84)
	raiz.add_child(marco)
	## Espejos retrovisores en los dos lados, con su brazo.
	for xm: float in [-1.42, 1.42]:
		var br := MeshInstance3D.new()
		var brm := BoxMesh.new()
		brm.size = Vector3(0.28, 0.04, 0.04)
		br.mesh = brm
		br.material_override = negro
		br.position = Vector3(xm * 0.93, 2.55, 5.8)
		raiz.add_child(br)
		var esp := MeshInstance3D.new()
		var em := BoxMesh.new()
		em.size = Vector3(0.1, 0.34, 0.2)
		esp.mesh = em
		esp.material_override = negro
		esp.position = Vector3(xm, 2.45, 5.8)
		raiz.add_child(esp)
	## Pilares entre ventanas y las dos puertas: en el lado de la ACERA (el derecho del autobús, que mira a +Z: −X; antes en +X, el lado de la calzada).
	for k in 7:
		var pil := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(2.58, 1.4, 0.18)
		pil.mesh = bm2
		pil.material_override = blanco
		pil.position = Vector3(0, 2.3, -5.4 + float(k) * 1.8)
		raiz.add_child(pil)
	for zp: float in [4.6, -0.8]:
		var pu := MeshInstance3D.new()
		var bm3 := BoxMesh.new()
		bm3.size = Vector3(0.06, 2.3, 1.2)
		pu.mesh = bm3
		pu.material_override = vidrio
		pu.position = Vector3(PasajerosBus.lado_puerta() * 1.29, 1.55, zp)
		raiz.add_child(pu)
	## Ruedas a escala (neumático de 0,46 m de radio con su llanta) y los pasos de rueda: un arco negro alrededor de cada una, en el costado.
	for zr: float in [3.8, -3.6]:
		for xr: float in [-1.12, 1.12]:
			var r := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.46
			cm.bottom_radius = 0.46
			cm.height = 0.3
			cm.radial_segments = 20
			r.mesh = cm
			r.material_override = goma
			r.rotation.z = PI * 0.5
			r.position = Vector3(xr, 0.46, zr)
			raiz.add_child(r)
			var ll := MeshInstance3D.new()
			var lm := CylinderMesh.new()
			lm.top_radius = 0.26
			lm.bottom_radius = 0.26
			lm.height = 0.32
			lm.radial_segments = 14
			ll.mesh = lm
			ll.material_override = llanta
			ll.rotation.z = PI * 0.5
			ll.position = Vector3(xr, 0.46, zr)
			raiz.add_child(ll)
			var arco := MeshInstance3D.new()
			var am := CylinderMesh.new()
			am.top_radius = 0.64
			am.bottom_radius = 0.64
			am.height = 0.04
			am.radial_segments = 22
			arco.mesh = am
			arco.material_override = negro
			arco.rotation.z = PI * 0.5
			arco.position = Vector3(signf(xr) * 1.282, 0.62, zr)
			raiz.add_child(arco)
	InteriorBus.montar(raiz)
	if destino != "":
		var l := Label3D.new()
		l.text = destino
		l.font_size = 32
		l.pixel_size = 0.006
		l.modulate = Color(0.1, 0.05, 0.0)
		l.outline_size = 0
		l.position = Vector3(0, 2.85, 6.04)
		raiz.add_child(l)
	## EL NÚMERO DE LA LÍNEA (27-10-2026): grande en los dos costados y detrás, más las dos placas.
	if numero != "":
		for lado: float in [-1.0, 1.0]:
			var ln := Label3D.new()
			ln.text = numero
			ln.font_size = 120
			ln.pixel_size = 0.011
			ln.modulate = Color.WHITE
			ln.outline_size = 14
			ln.outline_modulate = Color(0.05, 0.05, 0.08)
			ln.position = Vector3(lado * 1.29, 1.45, 1.5)   ## entre las dos puertas (ni sobre una puerta ni sobre una rueda)
			ln.rotation.y = lado * PI * 0.5
			raiz.add_child(ln)
		var lt := Label3D.new()
		lt.text = numero
		lt.font_size = 110
		lt.pixel_size = 0.012
		lt.outline_size = 12
		lt.position = Vector3(0, 2.3, -6.04)
		lt.rotation.y = PI
		raiz.add_child(lt)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.52, 0.13)
	for lado2 in 2:
		var pl := MeshInstance3D.new()
		pl.mesh = quad
		pl.material_override = CocheDetalle.placa(hash(destino) + lado2 * 5)
		pl.position = Vector3(0, 0.62, 6.04 if lado2 == 0 else -6.04)
		pl.rotation.y = 0.0 if lado2 == 0 else PI
		raiz.add_child(pl)
	return raiz
