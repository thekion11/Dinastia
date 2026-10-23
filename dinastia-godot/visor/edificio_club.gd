class_name EdificioClub
extends "res://visor/edificio_club_p1.gd"
## [Capa 2/2 de `edificio_club.gd`] _objeto, _marco_foto, _decorar, montar, reconstruir

## Un objeto del catálogo de `InterioresClub`: un conjunto de piezas si lo hay
## (`DECO_MODULAR`), o hecho a mano con piezas sencillas.
static func _objeto(nodo: Node3D, clave: String, p: Vector3, giro: float, c1: Color, c2: Color) -> void:
	if DECO_MODULAR.has(clave):
		var datos := datos_deco(clave)
		## La tela de sofás, sillones y alfombras, del color del club.
		if clave in ["sofa", "sillon", "alfombra"]:
			for d: Dictionary in datos:
				d["tonos"] = {"carpet": c1.lerp(Color(0.15, 0.15, 0.17), 0.3).to_html(false)}
		var conjunto := Modulos.de_datos(datos, "Deco_" + clave)
		if conjunto.get_child_count() > 0:
			conjunto.position = p
			conjunto.rotation.y = giro
			nodo.add_child(conjunto)
			return
		conjunto.free()
	var raiz := Node3D.new()
	raiz.position = p
	raiz.rotation.y = giro
	nodo.add_child(raiz)
	var oro: StandardMaterial3D = Texturas.metal(Color(0.95, 0.78, 0.3), 0.25)
	match clave:
		"planta":
			TunelVestuario._caja(raiz, Vector3(0, 0.25, 0), Vector3(0.45, 0.5, 0.45), _m(Color(0.55, 0.35, 0.25)), true)
			var copa := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.45
			sm.height = 0.9
			copa.mesh = sm
			copa.position = Vector3(0, 0.95, 0)
			copa.material_override = _m(Color(0.22, 0.5, 0.22), 0.9)
			raiz.add_child(copa)
		"sofa":
			TunelVestuario._caja(raiz, Vector3(0, 0.25, 0), Vector3(1.8, 0.5, 0.8), _m(c1.lerp(Color(0.2, 0.2, 0.22), 0.3), 0.9), true)
			TunelVestuario._caja(raiz, Vector3(0, 0.6, -0.33), Vector3(1.8, 0.7, 0.15), _m(c1.lerp(Color(0.2, 0.2, 0.22), 0.3), 0.9), false)
		"trofeo":
			TunelVestuario._caja(raiz, Vector3(0, 0.45, 0), Vector3(0.6, 0.9, 0.6), _m(Color(0.15, 0.15, 0.17)), true)
			var cm := CylinderMesh.new()
			cm.top_radius = 0.18
			cm.bottom_radius = 0.06
			cm.height = 0.5
			var copa2 := MeshInstance3D.new()
			copa2.mesh = cm
			copa2.position = Vector3(0, 1.15, 0)
			copa2.material_override = oro
			raiz.add_child(copa2)
		"bandera":
			TunelVestuario._caja(raiz, Vector3(0, 1.2, 0), Vector3(0.05, 2.4, 0.05), Texturas.metal(Color(0.8, 0.8, 0.82), 0.3), false)
			TunelVestuario._caja(raiz, Vector3(0.45, 1.9, 0), Vector3(0.8, 0.5, 0.02), _m(c1), false)
			TunelVestuario._caja(raiz, Vector3(0.45, 1.75, 0.012), Vector3(0.8, 0.15, 0.01), _m(c2), false)
		"tele":
			TunelVestuario._caja(raiz, Vector3(0, 0.35, 0), Vector3(1.4, 0.7, 0.45), _m(Color(0.3, 0.2, 0.12)), true)
			var pt := _m(Color(0.15, 0.3, 0.5), 0.2) as StandardMaterial3D
			pt.emission_enabled = true
			pt.emission = Color(0.2, 0.45, 0.8)
			TunelVestuario._caja(raiz, Vector3(0, 1.15, -0.1), Vector3(1.3, 0.75, 0.05), pt, false)
		"alfombra":
			TunelVestuario._caja(raiz, Vector3(0, 0.04, 0.8), Vector3(1.8, 0.02, 1.3), _m(c1.lerp(Color(0.6, 0.1, 0.1), 0.3), 1.0), false)
		"lampara":
			TunelVestuario._caja(raiz, Vector3(0, 0.8, 0), Vector3(0.05, 1.6, 0.05), _m(Color(0.15, 0.15, 0.17)), false)
			var pan := _m(Color(1, 0.95, 0.8), 0.6) as StandardMaterial3D
			pan.emission_enabled = true
			pan.emission = Color(1, 0.9, 0.7)
			TunelVestuario._caja(raiz, Vector3(0, 1.7, 0), Vector3(0.4, 0.3, 0.4), pan, false)
			var luz := OmniLight3D.new()
			luz.position = Vector3(0, 1.6, 0)
			luz.omni_range = 3.5
			luz.light_energy = 0.6
			luz.light_color = Color(1, 0.88, 0.7)
			raiz.add_child(luz)
		"estanteria":
			TunelVestuario._caja(raiz, Vector3(0, 1.0, 0), Vector3(1.2, 2.0, 0.35), _m(Color(0.45, 0.3, 0.18)), true)
			for k in 4:
				TunelVestuario._caja(raiz, Vector3(-0.3 + (k % 2) * 0.6, 0.6 + (k / 2) * 0.7, 0.05), Vector3(0.4, 0.3, 0.2),
					_m([Color(0.7, 0.2, 0.2), Color(0.2, 0.4, 0.7), c1, Color(0.85, 0.8, 0.6)][k]), false)
		"cafe":
			TunelVestuario._caja(raiz, Vector3(0, 0.45, 0), Vector3(0.6, 0.9, 0.5), _m(Color(0.85, 0.85, 0.85)), true)
			TunelVestuario._caja(raiz, Vector3(0, 1.15, 0), Vector3(0.45, 0.5, 0.4), _m(Color(0.1, 0.1, 0.11), 0.3), false)
		"balon":
			TunelVestuario._caja(raiz, Vector3(0, 0.5, 0), Vector3(0.4, 1.0, 0.4), _m(Color(0.15, 0.15, 0.17)), true)
			var bm := SphereMesh.new()
			bm.radius = 0.12
			bm.height = 0.24
			var bal := MeshInstance3D.new()
			bal.mesh = bm
			bal.position = Vector3(0, 1.14, 0)
			bal.material_override = _m(Color(0.97, 0.97, 0.97), 0.4)
			raiz.add_child(bal)
		"bufanda":
			TunelVestuario._caja(raiz, Vector3(0, 1.3, 0), Vector3(0.05, 1.2, 0.05), _m(Color(0.35, 0.25, 0.15)), false)
			for k in 6:
				TunelVestuario._caja(raiz, Vector3(0.05, 1.75 - k * 0.18, 0), Vector3(0.03, 0.18, 0.22), _m(c1 if k % 2 == 0 else c2), false)
		"pizarra":
			TunelVestuario._caja(raiz, Vector3(0, 1.3, 0), Vector3(1.2, 0.9, 0.05), _m(Color(0.12, 0.3, 0.2), 0.8), false)
			TunelVestuario._caja(raiz, Vector3(0, 0.45, 0), Vector3(0.05, 0.9, 0.05), _m(Color(0.35, 0.25, 0.15)), false)
			TunelVestuario._rotulo(raiz, "○ ○ ○\n  ✕ →", Vector3(0, 1.3, 0.04), 0.0, 40, Color(0.95, 0.95, 0.9))
		"maqueta":
			TunelVestuario._caja(raiz, Vector3(0, 0.45, 0), Vector3(0.9, 0.9, 0.7), _m(Color(0.3, 0.2, 0.12)), true)
			TunelVestuario._caja(raiz, Vector3(0, 0.95, 0), Vector3(0.6, 0.1, 0.45), _m(Color(0.2, 0.5, 0.25)), false)
			TunelVestuario._caja(raiz, Vector3(0, 1.0, 0), Vector3(0.75, 0.15, 0.6), _m(c1.lerp(Color(0.7, 0.7, 0.7), 0.5)), false)
		"guitarra":
			TunelVestuario._caja(raiz, Vector3(0, 0.45, 0), Vector3(0.35, 0.5, 0.1), _m(Color(0.6, 0.35, 0.15), 0.4), false)
			TunelVestuario._caja(raiz, Vector3(0, 0.95, 0), Vector3(0.06, 0.6, 0.04), _m(Color(0.25, 0.15, 0.08), 0.4), false)

## Un marco colgado con una foto del modo foto (`user://fotos/*.png`).
static func _marco_foto(nodo: Node3D, ruta: String, p: Vector3, lado: float) -> void:
	TunelVestuario._caja(nodo, p, Vector3(0.05, 0.95, 1.35), TunelVestuario._mat(Color(0.1, 0.08, 0.06), 0.5), false)
	var img := Image.load_from_file(ProjectSettings.globalize_path(ruta)) if FileAccess.file_exists(ruta) else null
	if img == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.2, 0.8)
	q.mesh = qm
	q.material_override = mat
	## La foto mira al centro de la sala (pared izquierda → +X).
	q.position = p + Vector3(-lado * 0.03, 0, 0)
	q.rotation.y = -lado * PI / 2.0
	nodo.add_child(q)

## PERSONALIZAR (fase 5): pintura de las paredes, los objetos de los seis
## huecos y los cuatro marcos con tus fotos.
static func _decorar(nodo: Node3D, sala: String, a: float, b: float, z_out: float, z_tab: float, y0: float,
		c1: Color, c2: Color, gusto: Dictionary) -> void:
	if gusto.is_empty():
		return
	var zc := (z_out + z_tab) / 2.0
	var fondo := z_tab - z_out
	if String(gusto.get("pared", "")) != "":
		var pm := TunelVestuario._mat(Color(String(gusto["pared"])), 0.85)
		## Una piel de pintura sobre las cuatro paredes de la sala (la del
		## pasillo, a los lados de la puerta).
		TunelVestuario._caja(nodo, Vector3((a + b) / 2.0, y0 + ALTO_LIBRE / 2.0, z_out + 0.06), Vector3(b - a - 0.25, ALTO_LIBRE - 0.05, 0.02), pm, false)
		TunelVestuario._caja(nodo, Vector3(a + 0.13, y0 + ALTO_LIBRE / 2.0, zc), Vector3(0.02, ALTO_LIBRE - 0.05, fondo - 0.25), pm, false)
		TunelVestuario._caja(nodo, Vector3(b - 0.13, y0 + ALTO_LIBRE / 2.0, zc), Vector3(0.02, ALTO_LIBRE - 0.05, fondo - 0.25), pm, false)
		var c := (a + b) / 2.0
		for tr: Vector2 in StadiumBuilder._tramos_sin_hueco(c, b - a - 0.25, c - PUERTA / 2.0, c + PUERTA / 2.0):
			TunelVestuario._caja(nodo, Vector3(tr.x, y0 + ALTO_LIBRE / 2.0, z_tab - 0.12), Vector3(tr.y, ALTO_LIBRE - 0.05, 0.02), pm, false)
	## Los seis huecos: las cuatro esquinas y el medio de cada lado.
	var huecos := [Vector3(a + 0.7, 0, z_out + 0.7), Vector3(b - 0.7, 0, z_out + 0.7), Vector3(a + 0.6, 0, zc),
		Vector3(b - 0.6, 0, zc), Vector3(a + 0.7, 0, z_tab - 0.9), Vector3(b - 0.7, 0, z_tab - 0.9)]
	var deco: Array = gusto.get("deco", [])
	for i in mini(deco.size(), huecos.size()):
		var clave := String(deco[i])
		if clave != "":
			var h: Vector3 = huecos[i]
			## Mirando al centro de la sala.
			var giro := atan2((a + b) / 2.0 - h.x, zc - h.z)
			_objeto(nodo, clave, Vector3(h.x, y0, h.z), giro, c1, c2)
	## Los cuatro marcos, dos en cada pared larga, con tus fotos.
	var fotos: Array = gusto.get("fotos", [])
	for i in mini(fotos.size(), 4):
		var ruta := String(fotos[i])
		if ruta == "":
			continue
		var lado := -1.0 if i < 2 else 1.0
		var x := (a + 0.16) if lado < 0.0 else (b - 0.16)
		var z := z_out + fondo * (0.3 if i % 2 == 0 else 0.62)
		_marco_foto(nodo, ruta, Vector3(x, y0 + 1.75, z), lado)

static func montar(padre: Node3D, x0: float, z_out: float, z_fin: float, c1: Color, c2: Color,
		horm: StandardMaterial3D, luz: StandardMaterial3D, nombre_club: String) -> void:
	var nodo := Node3D.new()
	nodo.name = "EdificioClub"
	nodo.add_to_group("edificio_club")
	## Para rehacerlo al decorar (`reconstruir`).
	nodo.set_meta("args", [x0, z_out, z_fin, c1, c2, horm, luz, nombre_club])
	padre.add_child(nodo)
	var ancho := TunelVestuario.VEST_MEDIO * 2.0
	var zc := (z_out + z_fin) / 2.0
	var fondo := z_fin - z_out
	var z_tabique := z_fin - PASILLO - 0.1
	## Etapa 2: 0,94 se quemaba a blanco puro con las luces de sala.
	var pared := TunelVestuario._mat(Color(0.82, 0.81, 0.78), 0.85)
	var suelo := TunelVestuario._mat(Color(0.5, 0.5, 0.52), 0.9)
	var vidrio: StandardMaterial3D = Texturas.cristal(true, true)
	## El ascensor de la planta 0 (dentro del vestuario, junto a la pizarra).
	_ascensor(nodo, x0, z_fin, 0.0)
	for f: Array in PLANTAS:
		var p := int(f[0])
		var y0 := float(p) * ALTO_PLANTA
		var bajo_tierra := p < 0
		## El cascarón de la planta.
		TunelVestuario._caja(nodo, Vector3(x0, y0 - 0.1, zc), Vector3(ancho + 0.6, 0.2, fondo + 0.6), horm, true)
		TunelVestuario._caja(nodo, Vector3(x0, y0 + 0.01, zc), Vector3(ancho, 0.02, fondo), suelo, false)
		TunelVestuario._caja(nodo, Vector3(x0, y0 + ALTO_LIBRE + 0.25, zc), Vector3(ancho + 0.6, 0.5, fondo + 0.6), horm, true)
		for lado in [-1.0, 1.0]:
			TunelVestuario._caja(nodo, Vector3(x0 + lado * (TunelVestuario.VEST_MEDIO + 0.15), y0 + ALTO_LIBRE / 2.0, zc),
				Vector3(0.3, ALTO_LIBRE, fondo + 0.6), horm, true)
			TunelVestuario._caja(nodo, Vector3(x0 + lado * (TunelVestuario.VEST_MEDIO - 0.02), y0 + ALTO_LIBRE / 2.0, zc),
				Vector3(0.04, ALTO_LIBRE, fondo), pared, false)
		TunelVestuario._caja(nodo, Vector3(x0, y0 + ALTO_LIBRE / 2.0, z_out - 0.15), Vector3(ancho + 0.6, ALTO_LIBRE, 0.3), horm, true)
		if p == GaleriaClub.PLANTA:
			_pared_galeria(nodo, x0, z_fin, y0, ancho, horm, pared, c1)
		else:
			TunelVestuario._caja(nodo, Vector3(x0, y0 + ALTO_LIBRE / 2.0, z_fin + 0.15), Vector3(ancho + 0.6, ALTO_LIBRE, 0.3), horm, true)
			TunelVestuario._caja(nodo, Vector3(x0, y0 + ALTO_LIBRE / 2.0, z_fin - 0.02), Vector3(ancho, ALTO_LIBRE, 0.04), pared, false)
		TunelVestuario._caja(nodo, Vector3(x0, y0 + ALTO_LIBRE / 2.0, z_out + 0.02), Vector3(ancho, ALTO_LIBRE, 0.04), pared, false)
		## Ventanas corridas en las plantas de arriba (a la calle y a los lados).
		if not bajo_tierra:
			TunelVestuario._caja(nodo, Vector3(x0, y0 + 1.9, z_fin + 0.31), Vector3(ancho - 1.0, 1.4, 0.04), vidrio, false)
		## El tabique del pasillo, con una puerta por sala.
		var huecos: Array = []
		for sala: Array in f[2]:
			var c := x0 + (float(sala[1]) + float(sala[2])) / 2.0
			huecos.append(Vector2(c - PUERTA / 2.0, c + PUERTA / 2.0))
		var tramos: Array = [Vector2(x0 - TunelVestuario.VEST_MEDIO, x0 + TunelVestuario.VEST_MEDIO)]
		for h: Vector2 in huecos:
			var nuevos: Array = []
			for t: Vector2 in tramos:
				for tr: Vector2 in StadiumBuilder._tramos_sin_hueco((t.x + t.y) / 2.0, t.y - t.x, h.x, h.y):
					nuevos.append(Vector2(tr.x - tr.y / 2.0, tr.x + tr.y / 2.0))
			tramos = nuevos
		for t: Vector2 in tramos:
			TunelVestuario._caja(nodo, Vector3((t.x + t.y) / 2.0, y0 + ALTO_LIBRE / 2.0, z_tabique), Vector3(t.y - t.x, ALTO_LIBRE, 0.2), pared, true)
		for h: Vector2 in huecos:
			TunelVestuario._caja(nodo, Vector3((h.x + h.y) / 2.0, y0 + (ALTO_LIBRE + 2.4) / 2.0, z_tabique), Vector3(h.y - h.x, ALTO_LIBRE - 2.4, 0.2), pared, false)
		## Tabiques entre salas.
		var salas: Array = f[2]
		for i in range(1, salas.size()):
			var xs := x0 + float(salas[i][1])
			TunelVestuario._caja(nodo, Vector3(xs, y0 + ALTO_LIBRE / 2.0, (z_out + z_tabique) / 2.0),
				Vector3(0.2, ALTO_LIBRE, z_tabique - z_out), pared, true)
		TunelVestuario._caja(nodo, Vector3(x0, y0 + ALTO_LIBRE - 0.01, z_fin - PASILLO / 2.0), Vector3(ancho - 0.1, 0.02, PASILLO - 0.1),
			TunelVestuario._mat(Color(0.8, 0.8, 0.78), 0.9), false)
		## Luz del pasillo y rótulo de la planta junto al ascensor.
		var lp := OmniLight3D.new()
		lp.position = Vector3(x0, y0 + ALTO_LIBRE - 0.4, z_fin - PASILLO / 2.0)
		lp.omni_range = 10.0
		lp.light_energy = 0.75
		nodo.add_child(lp)
		TunelVestuario._rotulo(nodo, Idiomas.t("PLANTA %d · %s") % [p, Idiomas.t(String(f[1])).to_upper()],
			Vector3(x0 + (ASC_X0 + ASC_X1) / 2.0, y0 + ALTO_LIBRE - 0.45, z_fin - 0.06), PI, 34, c1.lerp(Color(0.1, 0.1, 0.12), 0.2))
		_ascensor(nodo, x0, z_fin, y0)
		## Cada sala: su rótulo sobre la puerta (del lado del pasillo), su luz y
		## su contenido.
		for sala: Array in salas:
			var a: float = x0 + float(sala[1])
			var b: float = x0 + float(sala[2])
			var c := (a + b) / 2.0
			TunelVestuario._rotulo(nodo, Idiomas.t(String(sala[0])).to_upper(), Vector3(c, y0 + 2.75, z_tabique + 0.12), 0.0, 34, Color(0.15, 0.16, 0.2))
			var o := OmniLight3D.new()
			o.position = Vector3(c, y0 + ALTO_LIBRE - 0.4, (z_out + z_tabique) / 2.0)
			o.omni_range = maxf(6.0, (b - a) * 0.9)
			o.light_energy = 0.9
			nodo.add_child(o)
			TunelVestuario._caja(nodo, Vector3(c, y0 + ALTO_LIBRE - 0.03, (z_out + z_tabique) / 2.0), Vector3(1.8, 0.05, 0.6), luz, false)
			## Suelo y techo propios de la sala.
			var gusto := _gusto(String(sala[0]))
			var col_suelo := Color(String(gusto["suelo"])) if String(gusto.get("suelo", "")) != "" else _suelo_de(String(sala[0]))
			TunelVestuario._caja(nodo, Vector3(c, y0 + 0.025, (z_out + z_tabique) / 2.0), Vector3(b - a - 0.2, 0.01, z_tabique - z_out - 0.1),
				TunelVestuario._mat(col_suelo, 0.75), false)
			TunelVestuario._caja(nodo, Vector3(c, y0 + ALTO_LIBRE - 0.01, (z_out + z_tabique) / 2.0), Vector3(b - a - 0.2, 0.02, z_tabique - z_out - 0.1),
				TunelVestuario._mat(Color(0.8, 0.8, 0.78), 0.9), false)
			var caja := Rect2(a + 0.2, z_out + 0.2, b - a - 0.4, z_tabique - z_out - 0.4)
			_amueblar(nodo, String(sala[0]), caja, y0, c1, c2, nombre_club)
			_decorar(nodo, String(sala[0]), a, b, z_out, z_tabique, y0, c1, c2, gusto)

## Rehace el edificio con la decoración nueva (se llama al decorar).
static func reconstruir(viejo: Node3D) -> void:
	if not is_instance_valid(viejo) or not viejo.has_meta("args"):
		return
	var a: Array = viejo.get_meta("args")
	var padre := viejo.get_parent()
	padre.remove_child(viejo)
	## Los muebles modulares no se tiran: vuelven a la reserva y el edificio
	## nuevo los vuelve a sacar de ahí (`Modulos`).
	for n in viejo.find_children("Pieza_*", "Node3D", true, false):
		if (n as Node3D).has_meta("pieza"):
			Modulos.devolver(n as Node3D)
	viejo.queue_free()
	montar(padre, a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7])
