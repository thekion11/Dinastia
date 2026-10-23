extends "res://visor/city_builder_p2.gd"
## (Parte 3 de 12 de `city_builder.gd`.)

func _construir_vias() -> void:
	if _mat_blanco == null:
		_mat_blanco = StandardMaterial3D.new()
		_mat_blanco.albedo_color = Color(0.9, 0.9, 0.87)
		_mat_blanco.roughness = 0.7
		_mat_bordillo = Texturas.hormigon(Color(0.66, 0.66, 0.64), 61)
		_mat_tapa = StandardMaterial3D.new()
		_mat_tapa.albedo_color = Color(0.16, 0.16, 0.17)
		_mat_tapa.metallic = 0.6
		_mat_tapa.roughness = 0.5
	var baldosa := Texturas.baldosa()
	var borde_acera: float = BORDILLO + ACERA
	for i in _vias.size():
		var v: Dictionary = _vias[i]
		var h: bool = v["h"]
		var c: Vector3 = v["c"]
		var t: Vector2 = v["tam"]
		var ca: float = c.x if h else c.z
		var cl: float = c.z if h else c.x
		var largo: float = t.x if h else t.y
		var ancho: float = t.y if h else t.x
		var lo: float = ca - largo * 0.5
		var hi: float = ca + largo * 0.5
		## Pone una caja de `da` a lo largo por `dl` a lo ancho, centrada en
		## (a, l) de este tramo.
		var caja := func(a: float, l: float, da: float, dl: float, alto: float, y: float, mat: Material) -> void:
			var mi := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(da, alto, dl) if h else Vector3(dl, alto, da)
			mi.mesh = b
			mi.material_override = mat
			mi.position = Vector3(a, y, l) if h else Vector3(l, y, a)
			add_child(mi)
		var otros: Array = []
		for j in _vias.size():
			if j != i:
				var r := _rect_en(_vias[j], h)
				r.append(j)
				otros.append(r)
		## ¿Cada punta desemboca en otra calle?
		var conecta := {}
		for fin: float in [lo, hi]:
			conecta[fin] = null
			for r: Array in otros:
				if fin >= r[0] - 1.0 and fin <= r[1] + 1.0 and cl >= r[2] - 1.0 and cl <= r[3] + 1.0:
					conecta[fin] = r
					break

		for s_l: float in [-1.0, 1.0]:
			var banda_b := [cl + s_l * ancho * 0.5, cl + s_l * (ancho * 0.5 + BORDILLO)]
			var banda_a := [cl + s_l * (ancho * 0.5 + BORDILLO), cl + s_l * (ancho * 0.5 + borde_acera)]
			banda_b.sort()
			banda_a.sort()
			var huecos: Array = []
			for r: Array in otros:
				if _solapa(banda_a[0], banda_a[1], r[2], r[3]) or _solapa(banda_b[0], banda_b[1], r[2], r[3]):
					## La esquina la pone el tramo apuntado antes.
					var extra: float = 0.0 if i < int(r[4]) else borde_acera
					huecos.append([r[0] - extra, r[1] + extra])
			var desde := lo
			var hasta := hi
			## Esquina exterior: la acera de fuera sigue hasta cerrar la vuelta.
			for fin: float in [lo, hi]:
				var r2: Variant = conecta[fin]
				if r2 == null or i > int(r2[4]):
					continue
				if _solapa(banda_a[0], banda_a[1], r2[2], r2[3]):
					continue
				if fin == lo:
					desde = float(r2[0]) - borde_acera
				else:
					hasta = float(r2[1]) + borde_acera
			for tr: Array in _restar(desde, hasta, huecos):
				var da: float = tr[1] - tr[0]
				var am: float = (tr[0] + tr[1]) * 0.5
				caja.call(am, (banda_b[0] + banda_b[1]) * 0.5, da, BORDILLO, 0.22, 0.11, _mat_bordillo)
				caja.call(am, (banda_a[0] + banda_a[1]) * 0.5, da, ACERA, 0.18, 0.09, baldosa)
			## Línea de borde y sumideros: se cortan justo en el asfalto ajeno.
			var l_linea: float = cl + s_l * (ancho * 0.5 - 0.6)
			var huecos_l: Array = []
			for r: Array in otros:
				if l_linea >= r[2] and l_linea <= r[3]:
					huecos_l.append([r[0], r[1]])
			for tr: Array in _restar(lo, hi, huecos_l):
				caja.call((tr[0] + tr[1]) * 0.5, l_linea, tr[1] - tr[0], 0.15, 0.02, 0.13, _mat_blanco)
				var d: float = tr[0] + 20.0
				while d < tr[1] - 10.0:
					caja.call(d, cl + s_l * (ancho * 0.5 - 0.3), 0.9, 0.45, 0.02, 0.125, _mat_tapa)
					d += 40.0

		## Eje discontinuo (trazos de 4 m cada 10 m) y tapas de registro, fuera
		## de los cruces.
		var dentro := func(a: float, l: float) -> bool:
			for r: Array in otros:
				if a >= r[0] - 2.0 and a <= r[1] + 2.0 and l >= r[2] and l <= r[3]:
					return true
			return false
		var a_eje: float = lo + 5.0
		while a_eje < hi - 2.0:
			if not dentro.call(a_eje, cl):
				caja.call(a_eje, cl, 4.0, 0.15, 0.02, 0.13, _mat_blanco)
			a_eje += 10.0
		var dt: float = lo + 35.0
		while dt < hi - 20.0:
			if not dentro.call(dt, cl + ancho * 0.22):
				var tapa := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.35
				cm.bottom_radius = 0.35
				cm.height = 0.02
				tapa.mesh = cm
				tapa.material_override = _mat_tapa
				tapa.position = Vector3(dt, 0.125, cl + ancho * 0.22) if h else Vector3(cl + ancho * 0.22, 0.125, dt)
				add_child(tapa)
			dt += 70.0

		## FONDO DE SACO: la punta que no da a ninguna calle se cierra con
		## bordillo y acera de lado a lado.
		for fin: float in [lo, hi]:
			if conecta[fin] != null:
				continue
			var hacia: float = -1.0 if fin == lo else 1.0
			var total: float = ancho + 2.0 * borde_acera
			caja.call(fin + hacia * BORDILLO * 0.5, cl, BORDILLO, ancho, 0.22, 0.11, _mat_bordillo)
			caja.call(fin + hacia * (BORDILLO + ACERA * 0.5), cl, ACERA, total, 0.18, 0.09, baldosa)

func _color_club(cual: String, porDefecto: Color) -> Color:
	var club: Dictionary = datos.get("club", {})
	var s := str(club.get(cual, ""))
	if s.begins_with("#") and s.length() >= 7:
		return Color(s)
	return porDefecto

## Una farola: pie, mástil negro que se estrecha, brazo curvo y la luminaria.
## `hacia` es el ángulo al que apunta el brazo, para que el brazo caiga sobre
## la calzada y no hacia el campo.
func _una_farola(pos: Vector3, hacia: float) -> void:
	## `Texturas.metal()` (17-9-2026) en vez de color plano -docenas de farolas
	## por mapa (9x2 en la calle principal, mas el anillo entero)-. Duplicada
	## para conservar el metalico 0.55 ya afinado -menos cromado que el 0.75
	## por defecto-, pero las texturas de ruido caras de generar siguen
	## compartidas por referencia desde el cache de `Texturas`.
	var negro: StandardMaterial3D = Texturas.metal(Color(0.055, 0.058, 0.065), 0.42).duplicate()
	negro.metallic = 0.55

	var raiz := Node3D.new()
	raiz.position = pos
	raiz.rotation.y = hacia
	add_child(raiz)

	## Pie: un dado ancho abajo, que es lo que hace que no parezca un palo
	## clavado en el césped.
	var pie := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.42
	pm.bottom_radius = 0.62
	pm.height = 1.1
	pie.mesh = pm
	pie.material_override = negro
	pie.position = Vector3(0, 0.55, 0)
	raiz.add_child(pie)

	var mastil := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.17
	mm.bottom_radius = 0.34
	mm.height = FAROLA_ALTO
	mastil.mesh = mm
	mastil.material_override = negro
	mastil.position = Vector3(0, FAROLA_ALTO * 0.5 + 0.8, 0)
	raiz.add_child(mastil)

	## El brazo: tres tramos cortos girando un poco cada uno. Es la forma más
	## barata de sugerir una curva sin generar una malla a medida, y el brazo
	## curvo es justo lo que distingue una farola de calle de un poste.
	var largo := 1.5
	var punta := Vector3(0, FAROLA_ALTO + 0.6, 0)
	var ang := -0.95
	for i in range(3):
		var tramo := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.15
		tm.bottom_radius = 0.16
		tm.height = largo
		tramo.mesh = tm
		tramo.material_override = negro
		## RENDIMIENTO (17-9-2026): 3 tramos x cada farola del mapa (docenas)
		## son muchas mallas finas proyectando sombra por un brazo de 1,5 m que
		## ya queda bajo la sombra del mastil. Sin sombra propia no se nota.
		tramo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var dir := Vector3(sin(ang), cos(ang), 0)
		tramo.position = punta + dir * (largo * 0.5)
		tramo.rotation.z = -ang
		raiz.add_child(tramo)
		punta += dir * largo
		ang += 0.62

	## LA LUMINARIA: la carcasa negra y, debajo, el cristal que de verdad
	## emite. Se guarda su material para poder encenderlo y teñirlo con el
	## ciclo del sol sin reconstruir nada.
	var carcasa := MeshInstance3D.new()
	var cm2 := BoxMesh.new()
	cm2.size = Vector3(1.9, 0.42, 0.85)
	carcasa.mesh = cm2
	carcasa.material_override = negro
	carcasa.position = punta + Vector3(0.55, -0.1, 0)
	raiz.add_child(carcasa)

	var vidrio := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(1.6, 0.16, 0.7)
	vidrio.mesh = vm
	var lm := StandardMaterial3D.new()
	lm.albedo_color = _luz_color
	lm.emission_enabled = true
	lm.emission = _luz_color
	lm.emission_energy_multiplier = 0.0    ## la enciende el ciclo del sol
	vidrio.material_override = lm
	vidrio.position = punta + Vector3(0.55, -0.34, 0)
	raiz.add_child(vidrio)
	_luminarias.append(lm)

	var luz := OmniLight3D.new()
	luz.omni_range = 46.0
	luz.light_energy = 0.0
	luz.light_color = _luz_color
	luz.position = punta + Vector3(0.55, -0.6, 0)
	raiz.add_child(luz)
	_farolas_luz.append(luz)

	## BANDERINES DEL CLUB en el mástil, a media altura. Es el detalle que dice
	## de QUIÉN es esta ciudad -que es de lo que va toda esta pantalla-: en
	## cuanto los ves repetidos calle abajo, el mapa deja de ser "una ciudad" y
	## pasa a ser "la ciudad del club". Dos paños, uno de cada color.
	var colores := [_color_club("c1", Color(0.2, 0.5, 0.3)), _color_club("c2", Color(0.9, 0.9, 0.9))]
	for i in range(2):
		## `Texturas.tela()` (17-9-2026) en vez de color plano -mismo criterio
		## que el resto de banderas del proyecto esta sesion. `cull_mode` ya
		## viene en `Texturas.tela()`.
		var tela: StandardMaterial3D = Texturas.tela(colores[i]).duplicate()
		tela.roughness = 0.9
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.08, 2.2, 1.35)
		b.mesh = bm
		b.material_override = tela
		## RENDIMIENTO: dos banderines x docenas de farolas -sombra apagada,
		## una tela de este tamaño no se nota si no la tira.
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		b.position = Vector3(0.45 * (1.0 if i == 0 else -1.0), FAROLA_ALTO * 0.62, 0)
		raiz.add_child(b)

## Farolas a lo largo del anillo, por el lado de fuera. Cumplen dos funciones y
## las dos importan: de día llenan el vacío entre la calle y el campo -que era
## justo lo que se sentía desangelado-, y de noche son las que dibujan el
## trazado de la ciudad cuando ya no se ve el asfalto.
func _farolas_anillo() -> void:
	## `hacia` = el ángulo que pone el brazo sobre la calzada, que en el anillo
	## es siempre hacia el centro del mapa.
	var puestos: Array = []
	var paso := 62.0
	var z := RING_Z_NORTE + paso * 0.5
	while z < RING_Z_SUR:
		## Sobre la acera (26-9-2026): a 13 m quedaban dentro de las
		## fachadas de los frentes urbanos.
		puestos.append({"p": Vector3(-RING_X - 11.3, 0, z), "a": -PI * 0.5})
		puestos.append({"p": Vector3(RING_X + 11.3, 0, z), "a": PI * 0.5})
		z += paso
	var x := -RING_X + paso * 0.5
	while x < RING_X:
		puestos.append({"p": Vector3(x, 0, RING_Z_NORTE - 11.3), "a": 0.0})
		puestos.append({"p": Vector3(x, 0, RING_Z_SUR + 11.3), "a": PI})
		x += paso
	for d in puestos:
		## Ni en mitad de la boca de un ramal que entra al anillo.
		var p: Vector3 = d["p"]
		var en_calle := false
		for v in _vias:
			var r := _rect_en(v, true)
			if p.x > r[0] - 1.0 and p.x < r[1] + 1.0 and p.z > r[2] - 1.0 and p.z < r[3] + 1.0:
				en_calle = true
				break
		if not en_calle:
			_una_farola(p, float(d["a"]))

# ---------------------------------------------------------------- calles

## La red de calles: un anillo alrededor del recinto del club y un ramal corto
## a cada parcela. Es lo que convierte cinco cosas sueltas en un sitio por el
## que se puede ir: sin calles, una parcela a 300 m del estadio parece un error
## de colocación, no un terreno del otro lado de la calle.
func _calles() -> void:
	vias_mapa.clear()
	## La red de calles entera -el anillo completo mas los ramales a cada
	## parcela, la mayor superficie de asfalto del mapa- tambien conecta
	## `Texturas.asfalto()` (17-9-2026).
	var asfalto: StandardMaterial3D = Texturas.asfalto(Color(0.13, 0.13, 0.145)).duplicate()
	asfalto.roughness = 0.45
	asfalto.metallic = 0.1
	var linea := StandardMaterial3D.new()
	linea.albedo_color = Color(0.85, 0.82, 0.55)
	linea.roughness = 0.8

	## El anillo, en cuatro tramos.
	var largo_ns: float = RING_Z_SUR - RING_Z_NORTE
	var centro_ns: float = (RING_Z_SUR + RING_Z_NORTE) * 0.5
	_via(Vector3(-RING_X, 0, centro_ns), Vector2(ANCHO_CALLE, largo_ns), asfalto, linea, false)
	_via(Vector3(RING_X, 0, centro_ns), Vector2(ANCHO_CALLE, largo_ns), asfalto, linea, false)
	_via(Vector3(0, 0, RING_Z_NORTE), Vector2(RING_X * 2.0 + ANCHO_CALLE, ANCHO_CALLE), asfalto, linea, true)
	_via(Vector3(0, 0, RING_Z_SUR), Vector2(RING_X * 2.0 + ANCHO_CALLE, ANCHO_CALLE), asfalto, linea, true)

	## Ramales del anillo a cada parcela: un trozo corto que ata la parcela a
	## la calle, para que se lea que da a ella y no que flota al lado.
	for clave: String in PARCELAS:
		var p: Dictionary = PARCELAS[clave]
		var pos: Vector2 = p["pos"]
		var borde_x: float = pos.x - float(p["ancho"]) * 0.5 * signf(pos.x)
		var desde: float = RING_X * signf(pos.x)
		var medio: float = (borde_x + desde) * 0.5
		var largo: float = absf(borde_x - desde) + ANCHO_CALLE
		_via(Vector3(medio, 0, pos.y), Vector2(largo, ANCHO_CALLE), asfalto, linea, true)

	## Y el ramal al barrio residencial, que cuelga del tramo sur del anillo.
	## Termina delante del portón de la finca (la acera del fondo de saco
	## queda justo ante la verja).
	var fin_barrio: float = FINCA_PORTON_Z - BORDILLO - ACERA
	_via(Vector3(BARRIO_EN.x, 0, (RING_Z_SUR + fin_barrio) * 0.5),
		Vector2(ANCHO_CALLE, fin_barrio - RING_Z_SUR), asfalto, linea, false)

	## El acceso al karting, que cuelga del anillo sur hasta sus boxes.
	var fin_k: float = KARTING_EN.z - 22.0 - 16.0
	_via(Vector3(KARTING_EN.x, 0, (RING_Z_SUR + fin_k) * 0.5),
		Vector2(ANCHO_CALLE, fin_k - RING_Z_SUR), asfalto, linea, false)

	## EL EJE EXTERIOR (12-9-2026): "integrar... un eje vial mejor conectado
	## entre la zona industrial, el centro comercial y el estadio". Tenía
	## razón: con solo el anillo, para ir de la zona industrial (este) al
	## centro comercial (oeste) había que rodear el recinto del club por
	## dentro. Este segundo anillo pasa POR FUERA, rozando las cuatro parcelas,
	## y las conecta entre sí directamente. Es lo que en una ciudad de verdad
	## es la circunvalación, y de paso encierra el mapa como un conjunto.
	var ex_x := 392.0
	var ex_n := EX_N
	var ex_s := EX_S
	var largo_ex: float = ex_s - ex_n
	var centro_ex: float = (ex_s + ex_n) * 0.5
	_via(Vector3(-ex_x, 0, centro_ex), Vector2(ANCHO_CALLE, largo_ex), asfalto, linea, false)
	_via(Vector3(ex_x, 0, centro_ex), Vector2(ANCHO_CALLE, largo_ex), asfalto, linea, false)
	_via(Vector3(0, 0, ex_n), Vector2(ex_x * 2.0 + ANCHO_CALLE, ANCHO_CALLE), asfalto, linea, true)
	_via(Vector3(0, 0, ex_s), Vector2(ex_x * 2.0 + ANCHO_CALLE, ANCHO_CALLE), asfalto, linea, true)

	## PASOS DE CEBRA en cada cruce. Es el detalle más barato que existe para
	## que un cruce de dos franjas grises se lea como una intersección de
	## verdad, y además marca por dónde se entra a cada parcela.
	var cebra := StandardMaterial3D.new()
	cebra.albedo_color = Color(0.93, 0.93, 0.90)
	cebra.roughness = 0.75
	for clave: String in PARCELAS:
		var pp: Dictionary = PARCELAS[clave]
		var ppos: Vector2 = pp["pos"]
		_cebra(Vector3(RING_X * signf(ppos.x), 0, ppos.y), true, cebra)
	_cebra(Vector3(0, 0, RING_Z_SUR), false, cebra)
	_cebra(Vector3(BARRIO_EN.x, 0, RING_Z_SUR), false, cebra)
	_construir_vias()
	_farolas_anillo()

## La grúa torre: mástil de celosía (en cajas), pluma y contrapluma.
func _grua(pos: Vector3, alto: float) -> void:
	var amarillo := StandardMaterial3D.new()
	amarillo.albedo_color = Color(0.95, 0.72, 0.10)
	amarillo.roughness = 0.5
	var raiz := Node3D.new()
	raiz.name = "Grua"
	raiz.position = pos
	add_child(raiz)
	var mastil := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, alto, 1.6)
	mastil.mesh = bm
	mastil.material_override = amarillo
	mastil.position = Vector3(0, alto / 2.0, 0)
	raiz.add_child(mastil)
	var pluma := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(1.0, 1.0, alto * 0.9)
	pluma.mesh = pm
	pluma.material_override = amarillo
	pluma.position = Vector3(0, alto + 0.5, alto * 0.3)
	raiz.add_child(pluma)
	var contrapeso := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(2.2, 2.0, 3.0)
	contrapeso.mesh = cm
	var gris := StandardMaterial3D.new()
	gris.albedo_color = Color(0.35, 0.36, 0.38)
	contrapeso.material_override = gris
	contrapeso.position = Vector3(0, alto - 0.2, -alto * 0.12)
	raiz.add_child(contrapeso)
	## El cable con su carga, colgando de la punta.
	var cable := MeshInstance3D.new()
	var cbm := BoxMesh.new()
	cbm.size = Vector3(0.08, alto * 0.45, 0.08)
	cable.mesh = cbm
	cable.material_override = gris
	cable.position = Vector3(0, alto - alto * 0.225, alto * 0.62)
	raiz.add_child(cable)
	raiz.rotation.y = float(int(pos.x * 7.0 + pos.z) % 360) * PI / 180.0
