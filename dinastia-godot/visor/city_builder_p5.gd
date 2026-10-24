extends "res://visor/city_builder_p4.gd"
## [Capa 5/12 de `city_builder.gd`] _detalle_edificio, _arquito, _extra, _poner_extra, _rasgo_instalacion, _personal_en … (+3)

func _detalle_edificio(pos: Vector3, ancho: float, fondo: float, alto: float, e: Dictionary, cubierta := true, marquesina := true) -> void:
	## Se llamaba "hormigon" desde antes de esta sesion sin serlo -color plano
	## puro. `Texturas.hormigon()` de verdad ahora (17-9-2026), duplicado para
	## conservar la rugosidad 0.7 ya afinada aqui en vez del 0.92 por defecto.
	var hormigon: StandardMaterial3D = Texturas.hormigon(Color(0.80, 0.80, 0.79)).duplicate()
	hormigon.roughness = 0.7
	var acento := StandardMaterial3D.new()
	acento.albedo_color = _color_club("c1", Color(0.2, 0.5, 0.3))
	acento.roughness = 0.5
	acento.metallic = 0.2

	## MARQUESINA: un voladizo sobre la entrada, en la cara sur (la que mira al
	## acceso), con dos pilares. Es el gesto que dice "por aquí se entra".
	var z_frente: float = fondo * 0.5
	if not marquesina:
		return
	var mar := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(ancho * 0.5, 0.45, 5.0)
	mar.mesh = mm
	mar.material_override = hormigon
	mar.position = pos + Vector3(0, 4.6, z_frente + 2.2)
	add_child(mar)
	for lado in [-1.0, 1.0]:
		var pil := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.28
		pm.bottom_radius = 0.28
		pm.height = 4.6
		pil.mesh = pm
		pil.material_override = hormigon
		pil.position = pos + Vector3(lado * ancho * 0.21, 2.3, z_frente + 4.2)
		add_child(pil)

	## RÓTULO: banda de color del club sobre la puerta. Ata el edificio al club
	## igual que la franja del tejado, pero a la altura de la vista.
	var rot := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(ancho * 0.46, 1.5, 0.3)
	rot.mesh = rm
	rot.material_override = acento
	rot.position = pos + Vector3(0, 5.9, z_frente + 0.2)
	add_child(rot)

	## MÁQUINAS DE CUBIERTA: climatizadoras y un cajón de escalera. Es lo que
	## rompe la silueta plana del tejado, que es lo que más delata a una caja.
	if not cubierta:
		return
	var maq: StandardMaterial3D = Texturas.metal(Color(0.58, 0.59, 0.61), 0.55).duplicate()
	maq.metallic = 0.35
	for par in [
			{"p": Vector3(-ancho * 0.22, 0, -fondo * 0.18), "s": Vector3(4.2, 2.0, 3.2)},
			{"p": Vector3(ancho * 0.18, 0, fondo * 0.2), "s": Vector3(3.0, 1.5, 2.6)},
			{"p": Vector3(ancho * 0.3, 0, -fondo * 0.26), "s": Vector3(2.4, 2.8, 2.4)},
		]:
		var m2 := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = par["s"]
		m2.mesh = bm2
		m2.material_override = maq
		var s2: Vector3 = par["s"]
		m2.position = pos + (par["p"] as Vector3) + Vector3(0, alto + 0.5 + s2.y * 0.5, 0)
		add_child(m2)

func _arquito(p: Vector3, m: Material) -> void:
	for s in [-1.0, 1.0]:
		_cil_en(p + Vector3(s * 1.8, 0.9, 0), 0.07, 1.8, m)
	var trav := _cil_en(p + Vector3(0, 1.8, 0), 0.07, 3.6, m)
	trav.rotation.z = PI * 0.5

static func _extra(nombre: String) -> PackedScene:
	var r := "res://assets/ciudad/kenney_cars_extra/%s.glb" % nombre
	return load(r) if ResourceLoader.exists(r) else null

func _poner_extra(nombre: String, pos: Vector3, esc: float, giro: float) -> Node3D:
	var e := _extra(nombre)
	if e == null:
		return null
	var n: Node3D = e.instantiate()
	n.scale = Vector3.ONE * esc
	n.position = pos
	n.rotation.y = giro
	add_child(n)
	return n

func _rasgo_instalacion(k: String, pos: Vector3, ancho: float, fondo: float, alto: float, niv: int) -> void:
	var fz: float = fondo * 0.5
	var blanco := _mat_simple(Color(0.95, 0.95, 0.94), 0.5)
	var c1 := _color_club("c1", Color(0.2, 0.5, 0.3))
	match k:
		"med", "rehab":
			## Cruz roja luminosa en la fachada y una ambulancia en la puerta.
			var rojo := _mat_simple(Color(0.9, 0.1, 0.12), 0.4, 1.4)
			var yc := minf(alto - 2.5, 9.0)
			_caja_en(pos + Vector3(ancho * 0.3, yc, fz + 0.3), Vector3(3.6, 1.1, 0.3), rojo)
			_caja_en(pos + Vector3(ancho * 0.3, yc, fz + 0.3), Vector3(1.1, 3.6, 0.3), rojo)
			var amb: PackedScene = load("res://assets/ciudad/kenney_cars/ambulance.glb")
			if amb != null:
				var a: Node3D = amb.instantiate()
				a.scale = Vector3.ONE * 1.65
				a.position = pos + Vector3(-ancho * 0.32, 0, fz + 8.0)
				a.rotation.y = PI * 0.5
				add_child(a)
		"gim":
			## Cristalera a toda la fachada, con máquinas asomando detrás.
			var vidrio := Texturas.cristal(true, false)
			_caja_en(pos + Vector3(0, minf(alto, 6.0) * 0.5, fz + 0.15), Vector3(ancho * 0.8, minf(alto, 6.0) - 0.8, 0.2), vidrio)
			var metal := _mat_simple(Color(0.2, 0.2, 0.22), 0.4)
			for i in 5:
				_caja_en(pos + Vector3(-ancho * 0.3 + i * ancho * 0.15, 0.8, fz - 1.6), Vector3(0.9, 1.6, 2.0), metal)
		"acad", "resid":
			## Tejado a dos aguas y arcos de fútbol pequeños delante.
			var teja := _mat_simple(Color(0.62, 0.28, 0.18), 0.8)
			for s in [-1.0, 1.0]:
				var faldon := _caja_en(pos + Vector3(0, alto + 2.2, s * fondo * 0.25), Vector3(ancho + 1.0, 0.4, fondo * 0.56), teja)
				faldon.rotation.x = -0.42 * s
			if k == "acad":
				for s2 in [-1.0, 1.0]:
					_arquito(pos + Vector3(s2 * ancho * 0.3, 0, fz + 12.0), blanco)
			else:
				## Bicicletas de los chicos: soporte y ruedas del kit.
				for i in 4:
					_poner_extra("wheel-default", pos + Vector3(-ancho * 0.35 + i * 1.2, 0.5, fz + 3.0), 1.4, PI * 0.5)
		"cocina":
			## Terraza con parasoles y chimenea de cocina.
			var paras: PackedScene = load("res://assets/ciudad/kenney_comercial/detail-parasol-a.glb")
			for i in 3:
				if paras != null:
					var pa: Node3D = paras.instantiate()
					pa.scale = Vector3.ONE * 5.0
					pa.position = pos + Vector3(-ancho * 0.3 + i * ancho * 0.3, 0, fz + 9.0)
					add_child(pa)
			var acero := _mat_simple(Color(0.7, 0.7, 0.72), 0.3)
			_cil_en(pos + Vector3(ancho * 0.35, alto + 2.5, -fondo * 0.3), 0.6, 5.0, acero)
		"video", "pren":
			## Parabólicas y antena en el techo; la sala de prensa, con el
			## "photocall" de patrocinadores en la entrada.
			var gris := _mat_simple(Color(0.88, 0.88, 0.9), 0.4)
			for i in 2:
				var plato := _cil_en(pos + Vector3(-ancho * 0.25 + i * 3.5, alto + 2.2, 0), 1.5, 0.3, gris, 0.4)
				plato.rotation.x = -0.9
			_cil_en(pos + Vector3(ancho * 0.3, alto + 4.0, -fondo * 0.2), 0.12, 8.0, gris)
			if k == "pren":
				var photocall := _caja_en(pos + Vector3(0, 1.6, fz + 6.0), Vector3(8.0, 3.2, 0.2), _mat_simple(c1, 0.6))
				photocall.rotation.y = 0.0
		"museo":
			## Pórtico de columnas y la copa dorada sobre su pedestal.
			var piedra := _mat_simple(Color(0.86, 0.83, 0.76), 0.7)
			for i in 6:
				_cil_en(pos + Vector3(-ancho * 0.35 + i * ancho * 0.14, 3.5, fz + 2.0), 0.55, 7.0, piedra)
			_caja_en(pos + Vector3(0, 7.3, fz + 2.0), Vector3(ancho * 0.85, 0.8, 3.0), piedra)
			var oro := _mat_simple(Color(0.95, 0.75, 0.2), 0.25)
			oro.metallic = 0.9
			_caja_en(pos + Vector3(0, 0.8, fz + 11.0), Vector3(2.0, 1.6, 2.0), piedra)
			_cil_en(pos + Vector3(0, 2.4, fz + 11.0), 0.25, 1.6, oro, 0.25)
			_cil_en(pos + Vector3(0, 3.8, fz + 11.0), 0.3, 1.4, oro, 1.1)
		"com":
			## Escaparates con toldos a rayas del club.
			var toldo: PackedScene = load("res://assets/ciudad/kenney_comercial/detail-awning-wide.glb")
			for i in 2:
				if toldo != null:
					var t: Node3D = toldo.instantiate()
					t.scale = Vector3.ONE * 5.0
					t.position = pos + Vector3(-ancho * 0.25 + i * ancho * 0.5, 2.5, fz + 0.4)
					add_child(t)
			_caja_en(pos + Vector3(0, 1.8, fz + 0.12), Vector3(ancho * 0.75, 2.6, 0.12), Texturas.cristal(true, true))
		"guarderia":
			## Parque infantil: tobogán, columpio y arenero de colores.
			var col := [Color(0.95, 0.3, 0.3), Color(0.3, 0.6, 0.95), Color(0.98, 0.8, 0.2)]
			var base_p := pos + Vector3(0, 0, fz + 10.0)
			var tob := _caja_en(base_p + Vector3(-4, 1.2, 0), Vector3(1.2, 0.2, 5.0), _mat_simple(col[0]))
			tob.rotation.x = 0.45
			for s in [-1.0, 1.0]:
				_cil_en(base_p + Vector3(3.0 + s * 1.5, 1.5, 0), 0.1, 3.0, _mat_simple(col[1]))
			_caja_en(base_p + Vector3(3.0, 3.0, 0), Vector3(3.2, 0.15, 0.15), _mat_simple(col[1]))
			_caja_en(base_p + Vector3(0, 0.1, 4.0), Vector3(4.0, 0.2, 3.0), _mat_simple(Color(0.9, 0.82, 0.6)))
		"bienestar":
			## Cúpula de cristal y jardín de piedras.
			var dom := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = minf(ancho, fondo) * 0.22
			sm.height = sm.radius
			sm.is_hemisphere = true
			dom.mesh = sm
			dom.material_override = Texturas.cristal(true, false)
			dom.position = pos + Vector3(0, alto + 0.3, 0)
			add_child(dom)
		"esports":
			## Neón del color del club alrededor del techo y pantalla gigante.
			var neon := _mat_simple(c1.lightened(0.3), 0.3, 3.0)
			for s in [-1.0, 1.0]:
				_caja_en(pos + Vector3(0, alto - 0.3, s * (fondo * 0.5 + 0.1)), Vector3(ancho, 0.25, 0.1), neon)
				_caja_en(pos + Vector3(s * (ancho * 0.5 + 0.1), alto - 0.3, 0), Vector3(0.1, 0.25, fondo), neon)
			_caja_en(pos + Vector3(0, minf(alto, 6.0) * 0.55, fz + 0.2), Vector3(ancho * 0.5, 2.6, 0.15), _mat_simple(Color(0.2, 0.5, 1.0), 0.3, 1.6))
		"ct":
			## Placas solares en el techo y una pizarra táctica gigante.
			var panel := _mat_simple(Color(0.08, 0.12, 0.25), 0.2)
			panel.metallic = 0.6
			for i in 4:
				var pl := _caja_en(pos + Vector3(-ancho * 0.3 + i * ancho * 0.2, alto + 1.0, fondo * 0.15), Vector3(ancho * 0.16, 0.1, 4.0), panel)
				pl.rotation.x = -0.4
			_caja_en(pos + Vector3(-ancho * 0.5 - 0.2, minf(alto, 6.0) * 0.5, 0), Vector3(0.2, 3.5, 7.0), _mat_simple(Color(0.1, 0.35, 0.18), 0.6))
		"piscina":
			## Trampolín y escalerilla junto a la entrada.
			_caja_en(pos + Vector3(ancho * 0.3, 1.5, fz + 3.0), Vector3(0.8, 0.1, 3.5), blanco)
			_cil_en(pos + Vector3(ancho * 0.3, 0.75, fz + 1.5), 0.15, 1.5, blanco)
	## Con nivel alto, bandera del club y jardineras en la entrada.
	if niv >= 4:
		var mastil := _cil_en(pos + Vector3(-ancho * 0.5 - 3.0, 5.0, fz + 3.0), 0.1, 10.0, blanco)
		mastil.name = "Mastil"
		_caja_en(pos + Vector3(-ancho * 0.5 - 2.0, 9.2, fz + 3.0), Vector3(2.0, 1.2, 0.05), _mat_simple(c1, 0.8))
		var verde := _mat_simple(Color(0.18, 0.4, 0.16), 0.9)
		for s in [-1.0, 1.0]:
			_caja_en(pos + Vector3(s * ancho * 0.35, 0.5, fz + 5.0), Vector3(3.0, 1.0, 1.2), _mat_simple(Color(0.5, 0.5, 0.48)))
			_caja_en(pos + Vector3(s * ancho * 0.35, 1.2, fz + 5.0), Vector3(2.8, 0.6, 1.0), verde)

func _personal_en(k: String, pos: Vector3, fondo: float, niv: int) -> void:
	if not is_inside_tree():
		_personal_pendiente.append([k, pos, fondo, niv])
		return
	var cuantos := 1 + (1 if niv >= 4 else 0) + (1 if niv >= 7 else 0)
	var cols: Array = UNIFORMES.get(k, ["455a64", "ffffff"])
	var c1 := _color_club("c1", Color(0.2, 0.5, 0.3))
	var c2 := _color_club("c2", Color.WHITE)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(k + "|personal")
	for i in cuantos:
		var raiz := Node3D.new()
		add_child(raiz)
		var col_a: Color = c1 if cols[0] == "club" else Color(String(cols[0]))
		var col_b: Color = c2 if cols[1] == "club2" else (c1 if cols[1] == "club" else Color(String(cols[1])))
		var asp := {"cuerpo": "female" if rng.randf() < 0.45 else "male", "ropa": "polo",
			"c_ropa": col_a.to_html(false), "c_ropa2": col_b.to_html(false),
			"pelo": PersonajeDT.CORTES[rng.randi() % 10], "color_pelo": PersonajeDT.COLORES_PELO[rng.randi() % 6],
			"piel": PersonajeDT.PIELES[rng.randi() % PersonajeDT.PIELES.size()], "reloj": false,
			"altura": rng.randf_range(1.6, 1.88)}
		if k in ["cocina", "med", "rehab"]:
			## Bata o chaquetilla lisa, blanca de arriba abajo.
			asp["c_ropa2"] = col_a.to_html(false)
		var d := PersonajeDT.crear(raiz, asp, c1, c2)
		if d.is_empty():
			raiz.queue_free()
			continue
		raiz.position = pos + Vector3(-4.0 + i * 3.2, 0, fondo * 0.5 + 6.0 + rng.randf_range(-1.0, 1.0))
		raiz.rotation.y = rng.randf_range(-0.6, 0.6)
		var ap: AnimationPlayer = d["anim"]
		for g: String in ["hablar", "brazos_jarra", "parado"]:
			if ap.has_animation(g) and rng.randf() < 0.6:
				ap.play(g)
				ap.seek(rng.randf() * ap.current_animation_length, true)
				break
		for mi in raiz.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).visibility_range_end = 260.0

func _edificio(e: Dictionary, niv: int, enObra: bool, pos: Vector3) -> void:
	## La ALTURA sale del nivel: 4 metros por planta. Es la senal visual mas barata
	## y mas clara de "aqui he invertido".
	var plantas: int = maxi(1, niv)
	## 6 m por planta y no 4: a 4 los edificios quedaban como losas aplastadas y no
	## se podian CONTAR las plantas de un vistazo, que es justo lo que tiene que
	## comunicar el nivel de la instalacion.
	var alto := 6.0 * plantas
	var ancho: float = float(e["ancho"]) * (1.0 + 0.06 * (plantas - 1))
	var fondo: float = float(e["fondo"]) * (1.0 + 0.06 * (plantas - 1))

	var mat: StandardMaterial3D
	if enObra and niv <= 0:
		## En obra y sin nivel todavia: se ve el esqueleto, no un edificio acabado.
		mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.45, 0.25)
		mat.roughness = 1.0
	else:
		## `Texturas.hormigon()` (17-9-2026): el comentario de esta funcion ya
		## PEDIA hormigon pintado desde antes de esta sesion -"nada de plastico
		## brillante"- pero nunca se conecto la fabrica de texturas de verdad,
		## solo se afino rugosidad/metalico sobre un color plano. DUPLICADO
		## antes de sobreescribir esos tres valores: son las paredes mas
		## repetidas del mapa -una entrada de cache por cada color de club que
		## exista, compartida entre todos los edificios de ese club.
		## Fachada clara con el color de la instalación en tono suave (antes
		## el color puro sobre el hormigón oscuro dejaba el complejo casi negro).
		## 7-10-2026: una sola paleta para todo el complejo -hormigón claro con
		## el color de la instalación muy suave y el acento del club-. Con la
		## textura de hormigón y el color al 45 % salían cajas casi negras.
		mat = _mat_simple((e["col"] as Color).lerp(Color(0.93, 0.92, 0.89), 0.72), 0.7)
	## CADA INSTALACIÓN CON SU ARQUITECTURA (7-10-2026, «a la ciudad le falta
	## mejorar las instalaciones»): hasta hoy el cuerpo era SIEMPRE la misma
	## caja y solo cambiaban los adornos, así que desde el mapa la piscina, el
	## museo y la tienda eran el mismo bloque repetido en cuadrícula. Ahora la
	## forma dice qué es: nave con bóveda, pabellón de cristal con el agua
	## dentro, torre de habitaciones, clínica escalonada, templo con columnas,
	## escuela en L, pabellón con terraza, caja de medios con cristal oscuro.
	var forma := String(FORMAS.get(String(e["k"]), "caja")) if not (enObra and niv <= 0) else "caja"
	huellas.append(Rect2(pos.x - ancho * 0.5, pos.z - fondo * 0.5, ancho, fondo))
	_cuerpo_instalacion(forma, pos, ancho, fondo, alto, plantas, mat)

	## Franja del color del club en el tejado: ata los edificios al club y no a
	## un poligono industrial cualquiera.
	## Solo las formas de tejado plano a la altura `alto` llevan la franja y
	## las máquinas: en una bóveda o un frontón atravesarían la cubierta.
	var plano := forma in ["caja", "medios", "tienda", "clinica", "escuela"]
	if plano:
		var techo := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(ancho + 0.6, 0.5, fondo + 0.6)
		if forma == "escuela":
			tm.size = Vector3(ancho + 0.6, 0.5, fondo * 0.56 + 0.6)
		techo.mesh = tm
		var tmat := StandardMaterial3D.new()
		tmat.albedo_color = _color_club("c1", Color(0.2, 0.5, 0.3))
		techo.material_override = tmat
		techo.position = pos + Vector3(0, alto + 0.25, -fondo * 0.22 if forma == "escuela" else 0.0)
		add_child(techo)

	_detalle_edificio(pos, ancho, fondo, alto, e, plano, not (forma in ["templo", "pabellon"]))
	_rasgo_instalacion(String(e["k"]), pos, ancho, fondo, alto, niv)
	if not enObra or niv > 0:
		_personal_en(String(e["k"]), pos, fondo, niv)

	etiquetas.append({
		"pos": pos + Vector3(0, alto + 3.0, 0),
		"texto": str(e["n"]) + ("  (en obra)" if enObra else ""),
		"nivel": niv,
	})

## Una obra se VE: andamio alrededor, subiendo con el avance, y una grúa.
func _obra_en_curso(pos: Vector3, ancho: float, fondo: float, alto_final: float, avance: float) -> void:
	## Conos de obra alrededor (del Car Kit, 26-9-2026).
	for k in 12:
		var a := TAU * float(k) / 12.0
		_poner_extra("cone-flat", pos + Vector3(cos(a) * (ancho * 0.5 + 4.0), 0, sin(a) * (fondo * 0.5 + 4.0)), 2.4, a)
	var tubo := StandardMaterial3D.new()
	tubo.albedo_color = Color(0.85, 0.62, 0.18)
	tubo.roughness = 0.6
	var alto := maxf(3.0, alto_final * clampf(avance + 0.15, 0.15, 1.0))
	var paso := 4.0
	for lado in 4:
		var largo: float = ancho if lado < 2 else fondo
		var n := int(largo / paso) + 1
		for k in n:
			var t := -largo / 2.0 + float(k) * paso
			var p: Vector3
			match lado:
				0: p = Vector3(t, 0, fondo / 2.0 + 1.2)
				1: p = Vector3(t, 0, -fondo / 2.0 - 1.2)
				2: p = Vector3(ancho / 2.0 + 1.2, 0, t)
				_: p = Vector3(-ancho / 2.0 - 1.2, 0, t)
			var poste := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.18, alto, 0.18)
			poste.mesh = bm
			poste.material_override = tubo
			poste.position = pos + p + Vector3(0, alto / 2.0, 0)
			add_child(poste)
	## Pasarelas cada 3 m de altura.
	var pisos := int(alto / 3.0)
	for f in pisos:
		var y := 3.0 * float(f + 1)
		for z in [fondo / 2.0 + 1.2, -fondo / 2.0 - 1.2]:
			var tabla := MeshInstance3D.new()
			var tm := BoxMesh.new()
			tm.size = Vector3(ancho + 2.4, 0.12, 0.9)
			tabla.mesh = tm
			tabla.material_override = tubo
			tabla.position = pos + Vector3(0, y, z)
			add_child(tabla)
	_grua(pos + Vector3(ancho / 2.0 + 9.0, 0, -fondo / 2.0 - 6.0), alto_final + 22.0)

## EL CAMPUS (7-10-2026): un paseo peatonal delante de cada fila de
## instalaciones, el acceso pavimentado de cada puerta hasta el paseo, y bancos,
## farolillos y árboles en línea. Es lo que une los edificios en UN complejo en
## vez de cajas sueltas sobre una losa.
func _campus() -> void:
	var losa := _mat_simple(Color(0.8, 0.77, 0.7), 0.9)
	var banco := _mat_simple(Color(0.45, 0.32, 0.2), 0.8)
	var hoja := _mat_simple(Color(0.2, 0.42, 0.22), 0.9)
	var tronco := _mat_simple(Color(0.35, 0.26, 0.18), 0.9)
	var filas := int(ceil(float(EDIFICIOS.size()) / 4.0))
	for fila in filas:
		var z := FILA_0_Z + float(fila) * FILA_PASO + 19.0
		## La última fila da ya a la calle exterior: su acera hace de paseo.
		if z + 6.0 > EX_S - ANCHO_CALLE * 0.5 - 2.0:
			continue
		for lado in [-1.0, 1.0]:
			## Del borde del complejo a la avenida central, sin pisarla.
			_caja_en(Vector3(lado * 82.0, 0.05, z), Vector3(146.0, 0.1, 6.0), losa)
			for k in 7:
				var x: float = lado * (18.0 + float(k) * 20.0)
				_cil_en(Vector3(x, 1.4, z - 4.2), 0.18, 2.8, tronco)
				_cil_en(Vector3(x, 3.6, z - 4.2), 1.6, 2.6, hoja, 0.4)
				_caja_en(Vector3(x + 7.0, 0.35, z + 3.6), Vector3(2.2, 0.7, 0.6), banco)
		## El acceso de cada edificio de la fila hasta el paseo.
		for col in 4:
			var i := fila * 4 + col
			if i >= EDIFICIOS.size():
				break
			var e: Dictionary = EDIFICIOS[i]
			var x2 := -111.0 + float(col) * 74.0
			var z0 := FILA_0_Z + float(fila) * FILA_PASO + float(e["fondo"]) * 0.5
			var largo := maxf(1.0, (z - 3.0) - z0)
			_caja_en(Vector3(x2, 0.06, z0 + largo * 0.5), Vector3(7.0, 0.1, largo), losa)
