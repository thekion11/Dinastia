extends "res://visor/ciudad_expansion_p6.gd"
## [Capa 7/9 de `ciudad_expansion.gd`] _bandera_mastil, _cartel_m, _instalacion, _dibujar_bloque, _edificios_lejanos, _casas_kenney … (+5)

func _bandera_mastil(p: Vector3) -> void:
	b._cil_en(p + Vector3(0, 7.0, 0), 0.15, 14.0, _mat["claro"])
	StadiumBuilder._bandera_ondeante(b, p + Vector3(1.6, 12.6, 0), Vector2(3.2, 2.0),
		b._color_club("c1", Color(0.2, 0.5, 0.3)), 0.0, 0.3)

## Cartel de metro: poste con la «M» en un disco del color de la línea.
func _cartel_m(p: Vector3, col: Color) -> void:
	b._cil_en(p + Vector3(0, 2.0, 0), 0.12, 4.0, b._mat_simple(Color(0.3, 0.3, 0.32), 0.5))
	var d := b._cil_en(p + Vector3(0, 4.3, 0), 0.9, 0.15, b._mat_simple(col, 0.4, 0.6))
	d.rotation.x = PI * 0.5
	var l := Label3D.new()
	l.text = "M"
	l.font_size = 96
	l.pixel_size = 0.012
	l.modulate = Color.WHITE
	l.position = p + Vector3(0, 4.3, 0.1)
	l.double_sided = true
	b.add_child(l)

## Las instalaciones de la ciudad, cada una con su forma y su rótulo.
func _instalacion(uso: String, r: Rect2) -> void:
	var c := Vector3(r.get_center().x, 0.2, r.get_center().y)
	var w := r.size.x
	var f := r.size.y
	var nombre := ""
	match uso:
		"plaza_mayor":
			nombre = "Plaza Mayor"
			b._caja_en(Vector3(c.x, 0.26, c.z), Vector3(w - 4.0, 0.1, f - 4.0), b._mat_simple(Color(0.62, 0.57, 0.5), 0.85))
			var fuente := b._cil_en(c + Vector3(0, 0.7, 0), 7.0, 1.0, _mat["piedra"])
			fuente.name = "Fuente"
			b._cil_en(c + Vector3(0, 1.1, 0), 6.0, 0.3, _mat["agua"])
			_estatua_idolo(c + Vector3(0, 0, -f * 0.3))
			_mural(c + Vector3(-w * 0.5 + 1.0, 0, 0), PI * 0.5)
			var esquinas: Array = []
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					esquinas.append(c + Vector3(sx * w * 0.36, -0.2, sz * f * 0.36))
			_arboles_en(esquinas, 1.0)
		"ayuntamiento":
			nombre = "Ayuntamiento"
			b._caja_en(c + Vector3(0, 9.0, -6.0), Vector3(w * 0.8, 18.0, f * 0.55), _mat["piedra"])
			b._caja_en(c + Vector3(0, 26.0, -6.0), Vector3(9.0, 16.0, 9.0), _mat["piedra"])
			b._cil_en(c + Vector3(0, 36.0, -6.0), 4.0, 4.0, b._mat_simple(Color(0.35, 0.5, 0.45), 0.4), 0.2)
			for k in 8:
				b._cil_en(c + Vector3(-w * 0.34 + float(k) * w * 0.097, 7.0, f * 0.24), 0.8, 14.0, _mat["piedra"])
			_bandera_mastil(c + Vector3(0, 0, f * 0.4))
		"estacion_central":
			nombre = "Estación Central"
			b._caja_en(c + Vector3(0, 6.0, 0), Vector3(w * 0.85, 12.0, f * 0.7), _mat["claro"])
			b._boveda(c + Vector3(0, 12.0, 0), w * 0.85, f * 0.7, b._mat_simple(Color(0.5, 0.62, 0.7), 0.3), 0.3)
			b._caja_en(c + Vector3(0, 5.0, f * 0.35 + 0.1), Vector3(w * 0.6, 7.0, 0.2), _mat["vidrio"])
			_cartel_m(c + Vector3(w * 0.4, 0, f * 0.45), Color(0.85, 0.15, 0.15))
		"mercado":
			nombre = "Mercado"
			b._caja_en(c + Vector3(0, 4.5, 0), Vector3(w * 0.8, 9.0, f * 0.7), b._mat_simple(Color(0.7, 0.4, 0.3), 0.8))
			b._boveda(c + Vector3(0, 9.0, 0), w * 0.8, f * 0.7, b._mat_simple(Color(0.35, 0.45, 0.4), 0.5), 0.25)
		"cine":
			nombre = "Cine"
			b._caja_en(c + Vector3(0, 9.0, 0), Vector3(w * 0.7, 18.0, f * 0.7), b._mat_simple(Color(0.25, 0.22, 0.3), 0.5))
			var neon := b._mat_simple(Color(1.0, 0.3, 0.6), 0.3, 2.0)
			b._caja_en(c + Vector3(0, 14.0, f * 0.35 + 0.3), Vector3(w * 0.5, 3.0, 0.3), neon)
		"hospital":
			nombre = "Hospital"
			var blanco := b._mat_simple(Color(0.96, 0.96, 0.97), 0.5)
			b._caja_en(c + Vector3(0, 12.0, -8.0), Vector3(w * 0.8, 24.0, f * 0.4), blanco)
			b._caja_en(c + Vector3(-w * 0.25, 5.0, f * 0.15), Vector3(w * 0.35, 10.0, f * 0.4), blanco)
			var rojo := b._mat_simple(Color(0.85, 0.1, 0.1), 0.5, 0.4)
			b._caja_en(c + Vector3(0, 20.0, -8.0 + f * 0.2 + 0.3), Vector3(7.0, 2.0, 0.3), rojo)
			b._caja_en(c + Vector3(0, 20.0, -8.0 + f * 0.2 + 0.3), Vector3(2.0, 7.0, 0.3), rojo)
			b._cil_en(c + Vector3(w * 0.2, 24.2, -8.0), 5.0, 0.3, b._mat_simple(Color(0.3, 0.3, 0.32), 0.6))
		"comisaria":
			nombre = "Comisaría"
			b._caja_en(c + Vector3(0, 6.0, 0), Vector3(w * 0.7, 12.0, f * 0.6), b._mat_simple(Color(0.75, 0.78, 0.84), 0.6))
			b._caja_en(c + Vector3(0, 9.5, f * 0.3 + 0.2), Vector3(w * 0.5, 1.6, 0.3), b._mat_simple(Color(0.15, 0.3, 0.75), 0.5, 0.3))
		"bomberos":
			nombre = "Bomberos"
			b._caja_en(c + Vector3(0, 6.0, 0), Vector3(w * 0.7, 12.0, f * 0.6), b._mat_simple(Color(0.75, 0.2, 0.15), 0.6))
			for k in 3:
				b._caja_en(c + Vector3(-w * 0.22 + float(k) * w * 0.22, 3.5, f * 0.3 + 0.1), Vector3(w * 0.17, 6.0, 0.2), b._mat_simple(Color(0.85, 0.85, 0.85), 0.4))
			b._caja_en(c + Vector3(w * 0.3, 11.0, -f * 0.2), Vector3(5.0, 22.0, 5.0), b._mat_simple(Color(0.75, 0.2, 0.15), 0.6))
		"escuela", "instituto":
			nombre = "Escuela" if uso == "escuela" else "Instituto"
			var lad := b._mat_simple(Color(0.7, 0.42, 0.32), 0.85)
			b._caja_en(c + Vector3(0, 6.0, -f * 0.2), Vector3(w * 0.8, 12.0, f * 0.3), lad)
			b._caja_en(c + Vector3(-w * 0.3, 6.0, f * 0.05), Vector3(w * 0.2, 12.0, f * 0.3), lad)
			## Patio con su cancha.
			b._caja_en(c + Vector3(w * 0.12, 0.25, f * 0.2), Vector3(w * 0.45, 0.1, f * 0.35), b._mat_simple(Color(0.3, 0.5, 0.35), 0.8))
		"universidad":
			nombre = "Universidad"
			b._caja_en(c + Vector3(0, 10.0, -f * 0.15), Vector3(w * 0.85, 20.0, f * 0.35), _mat["piedra"])
			b._cil_en(c + Vector3(0, 22.0, -f * 0.15), 9.0, 6.0, b._mat_simple(Color(0.4, 0.5, 0.6), 0.4), 2.0)
			_lote("cesped", c + Vector3(0, 0.25, f * 0.25), Vector3(w * 0.7, 0.1, f * 0.3))
		"centro_comercial":
			nombre = "Centro Comercial"
			b._caja_en(c + Vector3(0, 8.0, -f * 0.1), Vector3(w * 0.9, 16.0, f * 0.55), _mat["claro"])
			b._caja_en(c + Vector3(0, 7.0, -f * 0.1 + f * 0.275 + 0.2), Vector3(w * 0.7, 10.0, 0.2), _mat["vidrio"])
			_lote("asfalto", c + Vector3(0, 0.25, f * 0.32), Vector3(w * 0.9, 0.1, f * 0.3))
		"gasolinera":
			nombre = "Gasolinera"
			b._caja_en(c + Vector3(0, 6.0, 0), Vector3(w * 0.5, 0.6, f * 0.4), b._mat_simple(Color(0.9, 0.9, 0.9), 0.5))
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					b._cil_en(c + Vector3(sx * w * 0.18, 3.0, sz * f * 0.12), 0.3, 6.0, _mat["claro"])
			b._caja_en(c + Vector3(0, 1.0, 0), Vector3(1.2, 2.0, 2.0), b._mat_simple(Color(0.85, 0.2, 0.15), 0.5))
			b._caja_en(c + Vector3(-w * 0.35, 2.5, -f * 0.3), Vector3(10.0, 5.0, 8.0), _mat["claro"])
		"villa_moderna":
			nombre = "Villa moderna"
			_lote("cesped", Vector3(c.x, 0.27, c.z), Vector3(w, 0.06, f))
			var esc := load(CityBuilder.RUTA_OFICINA_DT) as PackedScene
			if esc != null:
				var n0: Node3D = esc.instantiate()
				var raiz := Node3D.new()
				b.add_child(raiz)
				raiz.add_child(n0)
				var caja := b._caja_de(n0)
				n0.position = -Vector3(caja.position.x + caja.size.x * 0.5, caja.position.y, caja.position.z + caja.size.z * 0.5)
				var s := minf((w - 12.0) / maxf(caja.size.x, 0.01), (f - 12.0) / maxf(caja.size.z, 0.01))
				raiz.scale = Vector3.ONE * s
				raiz.position = c
				cuenta["edificios"] = int(cuenta.get("edificios", 0)) + 1
		"desguace":
			nombre = "Desguace"
			_lote("solar", Vector3(c.x, 0.26, c.z), Vector3(w, 0.05, f))
			b._desguace(c, 404)
			var ex := load("res://assets/ciudad/kenney_cars/tractor-shovel.glb") as PackedScene
			if ex != null:
				_kit(ex, c + Vector3(w * 0.3, 0, -f * 0.25), Vector3.ONE * 2.6, 0.6)
			var caja2 := load("res://assets/ciudad/kenney_cars/box.glb") as PackedScene
			if caja2 != null:
				for k in 6:
					_kit(caja2, c + Vector3(-w * 0.35 + float(k % 3) * 3.0, float(k / 3) * 2.2, -f * 0.3), Vector3.ONE * 2.2, 0.0)
		"granja":
			nombre = "Granja urbana"
			_lote("cesped", Vector3(c.x, 0.27, c.z), Vector3(w, 0.06, f))
			var tierra := b._mat_simple(Color(0.36, 0.26, 0.18), 0.95)
			var verde := b._mat_simple(Color(0.3, 0.55, 0.22), 0.9)
			for k in 8:
				b._caja_en(c + Vector3(-w * 0.4 + float(k) * w * 0.11, 0.35, 0), Vector3(w * 0.07, 0.3, f * 0.7), tierra)
				b._caja_en(c + Vector3(-w * 0.4 + float(k) * w * 0.11, 0.7, 0), Vector3(w * 0.05, 0.5, f * 0.65), verde)
			var tra := load("res://assets/ciudad/kenney_cars/tractor.glb") as PackedScene
			if tra != null:
				_kit(tra, c + Vector3(w * 0.38, 0, f * 0.35), Vector3.ONE * 2.4, PI * 0.5)
			b._caja_en(c + Vector3(-w * 0.3, 5.0, -f * 0.38), Vector3(14.0, 10.0, 9.0), b._mat_simple(Color(0.65, 0.2, 0.15), 0.8))
		"cocheras":
			nombre = "Cocheras de autobuses"
			b._caja_en(c + Vector3(0, 5.0, -f * 0.15), Vector3(w * 0.85, 10.0, f * 0.5), b._mat_simple(Color(0.6, 0.62, 0.6), 0.7))
			for k in 4:
				var n := CityBuilder.autobus([Color(0.85, 0.15, 0.12), Color(0.15, 0.4, 0.8)][k % 2], "")
				n.position = c + Vector3(-w * 0.3 + float(k) * w * 0.2, 0.2, f * 0.3)
				n.name = "Bus"
				b.add_child(n)
		_:
			b._caja_en(c + Vector3(0, 6.0, 0), Vector3(w * 0.7, 12.0, f * 0.6), _mat["claro"])
	if nombre != "":
		b._rotulo(c + Vector3(0, 30.0, 0), nombre, Color(1, 1, 1), 22)
		b.puntos_clic.append({"k": "ciudad_" + uso, "n": nombre, "pos": c, "estado": "ciudad"})
	cuenta["instalaciones"] = int(cuenta.get("instalaciones", 0)) + 1

# ---------------------------------------------------------------- manzanas

func _dibujar_bloque(bl: Dictionary) -> void:
	var r: Rect2 = bl["rect"]
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	var uso := String(bl["uso"])
	match uso:
		"rio":
			_paseo_rio(r)
		"puerto":
			_puerto(r)
		"casa_grande":
			if bl["celda"] == Vector2i(-2, 6):
				var rr := Rect2(FINCA_GRANDE.position + Vector2(ANCHO_CALLE * 0.5 + ACERA, ANCHO_AV * 0.5 + ACERA),
					FINCA_GRANDE.size - Vector2(ANCHO_CALLE * 0.5 + ACERA + ANCHO_AV * 0.5 + ACERA, ANCHO_AV * 0.5 + ACERA + ANCHO_CALLE * 0.5 + ACERA))
				_casa_grande(rr)
		"parque", "parque_lago":
			_parque(r, uso == "parque_lago")
		"torres":
			_acera_bloque(r)
			_torres(r)
		"comercial":
			_acera_bloque(r)
			_comercial_bloque(r)
		"pisos":
			_acera_bloque(r)
			_pisos(r)
		"industrial":
			_industrial(r)
		"casas":
			_casas(r)
		"lejano":
			_lejanos.append(r)
		"feria":
			## Antes era una manzana lejana: se sigue apuntando para que el azar de
			## `_edificios_lejanos` se consuma igual (no se mueve nada más).
			_lejanos.append(r)
			_sin_lejano.append(r)
			_feria(r)
		_:
			_acera_bloque(r)
			_instalacion(uso, r)
	cuenta[uso] = int(cuenta.get(uso, 0)) + 1
	## Para que el resto de la ciudad (árboles, ánimo) sepa que aquí hay algo.
	if not (uso in ["rio", "parque", "parque_lago", "lejano", "feria"]):
		b._frentes.append(r)

func _edificios_lejanos() -> void:
	if _lejanos.is_empty():
		return
	var ts: Array[Transform3D] = []
	var cs: Array[Color] = []
	for r in _lejanos:
		var libre := r in _sin_lejano
		if not libre:
			_lote("acera", Vector3(r.get_center().x, 0.12, r.get_center().y), Vector3(r.size.x, 0.24, r.size.y))
		for k in 4:
			var o := Vector2((float(k % 2) - 0.5) * r.size.x * 0.5, (float(k / 2) - 0.5) * r.size.y * 0.5)
			var w := r.size.x * _rng.randf_range(0.32, 0.42)
			var f := r.size.y * _rng.randf_range(0.32, 0.42)
			var h := _rng.randf_range(14.0, 48.0)
			if libre:
				_rng.randi()   ## (el color, consumido igual)
				continue
			ts.append(Transform3D(Basis.from_scale(Vector3(w, h, f)), Vector3(r.get_center().x + o.x, h * 0.5, r.get_center().y + o.y)))
			cs.append([Color(0.85, 0.83, 0.8), Color(0.75, 0.78, 0.82), Color(0.88, 0.8, 0.7), Color(0.7, 0.72, 0.75)][_rng.randi() % 4])
	## Fachada de verdad (etapa 6): ventanas con marco y de noche encendidas.
	var mat := ShaderMaterial.new()
	mat.shader = load("res://visor/fachada_torre.gdshader") as Shader
	mat.set_shader_parameter("pared_de_instancia", true)
	mat.set_shader_parameter("celda", Vector2(3.0, 3.6))
	## Cristal tintado como el de las torres (sin esto, el azul por defecto
	## del shader: la torre azul de la avenida, 13-10-2026).
	mat.set_shader_parameter("vidrio", Color(0.14, 0.17, 0.2))
	_ventanas_lejanas = mat
	_multimesh(BoxMesh.new(), mat, ts, Vector3.ONE, cs)
	cuenta["edificios"] = int(cuenta.get("edificios", 0)) + ts.size()

## Las casas del kit suburbano: la fachada del modelo mira a −Z; se gira para que
## dé a la calle y se apoya con el frente en `zf`, centrada en `x`. Devuelve false
## si los modelos no cargan (y entonces se dibujan las cajas).
func _casas_kenney() -> bool:
	var mallas: Array = []
	for letra: String in MODELOS_CASA:
		var ps := load("res://assets/kenney/suburbano/building-type-%s.glb" % letra) as PackedScene
		if ps == null:
			return false
		var inst := ps.instantiate()
		var mis := inst.find_children("*", "MeshInstance3D", true, false)
		var malla: Mesh = (mis[0] as MeshInstance3D).mesh if not mis.is_empty() else null
		inst.free()
		if malla == null:
			return false
		mallas.append(malla)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://visor/casa_kenney.gdshader")
	mat.set_shader_parameter("paleta", load("res://assets/kenney/suburbano/Textures/colormap.png"))
	var grupos: Array = []
	for i in mallas.size():
		grupos.append([])
	for c: Dictionary in _kenney_casas:
		(grupos[int(c["m"])] as Array).append(c)
	for i in mallas.size():
		var lista: Array = grupos[i]
		if lista.is_empty():
			continue
		var malla: Mesh = mallas[i]
		var caja := malla.get_aabb()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = malla
		mm.instance_count = lista.size()
		for k in lista.size():
			var c: Dictionary = lista[k]
			var s := minf(ESCALA_CASA, float(c["ancho_max"]) / maxf(caja.size.x, 0.01))
			var giro := PI if float(c["lado"]) > 0.0 else 0.0
			var base := Basis(Vector3.UP, giro).scaled(Vector3.ONE * s)
			## El punto de abajo, en el centro del frente, cae en la línea de fachada.
			var frente := Vector3(caja.get_center().x, caja.position.y, caja.position.z)
			var pos := Vector3(float(c["x"]), 0.1, float(c["zf"])) - base * frente
			mm.set_instance_transform(k, Transform3D(base, pos))
			## Pasteles algo apagados: con los de `COLORES_CASA` tal cual, a pleno
			## sol las fachadas se quemaban en blanco.
			## El shader recibe estos colores tal cual (en lineal): se convierten,
			## o el tejado de teja salía rosa pálido.
			mm.set_instance_color(k, (c["col"] as Color).lerp(Color(0.72, 0.7, 0.66), 0.25).srgb_to_linear())
			mm.set_instance_custom_data(k, (c["tejado"] as Color).srgb_to_linear())
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = mat
		b.add_child(mi)
	return true

func _casas_multimesh() -> void:
	if _casas_t.is_empty():
		return
	## Jardín: setos, camino y buzón, con casa de Kenney o con las cajas.
	_multimesh(BoxMesh.new(), _mat["hoja"], _setos_t, Vector3.ONE)
	_multimesh(BoxMesh.new(), b._mat_simple(Color(0.7, 0.66, 0.6), 0.9), _caminos_t, Vector3.ONE)
	_multimesh(BoxMesh.new(), b._mat_simple(Color(0.15, 0.3, 0.55), 0.5), _buzones_t, Vector3.ONE)
	if _casas_kenney():
		return
	_multimesh(BoxMesh.new(), null, _casas_t, Vector3.ONE, _casas_col)
	var prisma := PrismMesh.new()
	_multimesh(prisma, null, _techos_t, Vector3.ONE, _techos_col)
	_multimesh(BoxMesh.new(), b._mat_simple(Color(0.36, 0.22, 0.14), 0.7), _puertas_t, Vector3.ONE)
	_multimesh(BoxMesh.new(), b._mat_simple(Color(0.96, 0.96, 0.94), 0.6), _marcos_t, Vector3.ONE)
	var vid := b._mat_simple(Color(0.2, 0.28, 0.36), 0.12)
	vid.metallic = 0.6
	_multimesh(BoxMesh.new(), vid, _vidrios_t, Vector3.ONE)
	_multimesh(BoxMesh.new(), b._mat_simple(Color(0.55, 0.3, 0.24), 0.8), _chimeneas_t, Vector3.ONE)
	if not _det_t.is_empty():
		_multimesh(BoxMesh.new(), null, _det_t, Vector3.ONE, _det_c)

## Dibuja los bloques modulares: un MultiMesh por pieza, color de pared en
## COLOR y remates + toldo en CUSTOM; las cajas de las azoteas, en otro.
func _modular_multimesh() -> void:
	if _mod_t.is_empty():
		return
	var mat := ShaderMaterial.new()
	mat.shader = load("res://visor/bloque_modular.gdshader")
	mat.set_shader_parameter("paleta", load(RUTA_MOD + "Textures/colormap.png"))
	for ruta: String in _mod_t:
		var k := _malla_kit(ruta)
		if k.is_empty():
			continue
		var g: Dictionary = _mod_t[ruta]
		var ts: Array[Transform3D] = g["t"]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = k["malla"]
		mm.instance_count = ts.size()
		for i in ts.size():
			mm.set_instance_transform(i, ts[i])
			mm.set_instance_color(i, (g["c"] as Array[Color])[i])
			mm.set_instance_custom_data(i, (g["d"] as Array[Color])[i])
		var mi := MultiMeshInstance3D.new()
		mi.name = "Modular"
		mi.multimesh = mm
		mi.material_override = mat
		b.add_child(mi)
		cuenta["piezas_modulares"] = int(cuenta.get("piezas_modulares", 0)) + ts.size()
	_multimesh(BoxMesh.new(), null, _mod_cajas_t, Vector3.ONE, _mod_cajas_c)
	_mod_t.clear()

## Las bocas del metro: escalera que baja, barandilla y la «M».
func _bocas_metro() -> void:
	var n := 0
	for linea: Dictionary in lineas_metro:
		if bool(linea.get("elevada", false)):
			continue   ## la elevada tiene sus escaleras al andén
		var col: Color = linea["color"]
		for e: Vector3 in linea["estaciones"]:
			var p := e + Vector3(ANCHO_AV * 0.5 + ACERA + 3.0, 0, ANCHO_AV * 0.5 + ACERA + 3.0)
			b._caja_en(p + Vector3(0, 0.15, 0), Vector3(3.2, 0.3, 7.0), b._mat_simple(Color(0.2, 0.2, 0.22), 0.6))
			for s in 6:
				_lote("acera", p + Vector3(0, -0.2 - float(s) * 0.35, -2.5 + float(s) * 0.9), Vector3(2.6, 0.2, 0.9))
			for lado: float in [-1.0, 1.0]:
				b._caja_en(p + Vector3(lado * 1.7, 0.6, 0), Vector3(0.12, 1.0, 7.0), b._mat_simple(Color(0.55, 0.56, 0.58), 0.3))
			_cartel_m(p + Vector3(2.4, 0, -3.0), col)
			n += 1
	cuenta["bocas_metro"] = n

## Las marquesinas de las paradas de autobús.
func _marquesinas_bus() -> void:
	var n := 0
	for l: Dictionary in lineas_bus:
		for p: Vector3 in l["paradas"]:
			var q := p
			## A la acera más cercana: se aparta del eje de la avenida.
			var dir := Vector3(signf(p.x - snappedf(p.x, CELDA)), 0, signf(p.z - snappedf(p.z, CELDA)))
			if absf(p.x - snappedf(p.x, CELDA)) < absf(p.z - snappedf(p.z, CELDA)):
				q = Vector3(snappedf(p.x, CELDA) + signf(dir.x if dir.x != 0.0 else 1.0) * (ANCHO_AV * 0.5 + ACERA * 0.6), 0, p.z)
			else:
				q = Vector3(p.x, 0, snappedf(p.z, CELDA) + signf(dir.z if dir.z != 0.0 else 1.0) * (ANCHO_AV * 0.5 + ACERA * 0.6))
			b._caja_en(q + Vector3(0, 2.6, 0), Vector3(3.5, 0.15, 1.6), _mat["claro"])
			b._caja_en(q + Vector3(0, 1.3, -0.7), Vector3(3.5, 2.4, 0.08), _mat["vidrio"])
			b._caja_en(q + Vector3(0, 0.55, -0.3), Vector3(2.8, 0.15, 0.5), _mat["tronco"])
			n += 1
	cuenta["paradas_bus"] = n

func _guirnaldas() -> void:
	var colores := [Color(1, 0.3, 0.3), Color(1, 0.85, 0.3), Color(0.3, 0.8, 1), Color(0.4, 1, 0.5), Color(1, 0.45, 0.9)]
	var por_color: Array = []
	for _c in colores:
		por_color.append([] as Array[Transform3D])
	var n := 0
	## Cable y postes (15-10-2026): antes las bombillas flotaban sueltas en el aire.
	var cables: Array[Transform3D] = []
	var postes_g: Array[Transform3D] = []
	for t: Dictionary in tramos:
		var a: Vector3 = t["a"]
		var c: Vector3 = t["b"]
		var m := (a + c) * 0.5
		if not (m.z < NUC_Z0 and absf(m.x) < 450.0) or bool(t["av"]):
			continue
		var vertical := absf(a.x - c.x) < 0.1
		var ancho: float = t["ancho"]
		## Cuatro guirnaldas cruzando la calle a lo largo del tramo.
		for q in 4:
			var p := a.lerp(c, (float(q) + 0.5) / 4.0)
			var e0 := p + (Vector3(-ancho * 0.5 - 1.0, 0, 0) if vertical else Vector3(0, 0, -ancho * 0.5 - 1.0))
			var e1 := p + (Vector3(ancho * 0.5 + 1.0, 0, 0) if vertical else Vector3(0, 0, ancho * 0.5 + 1.0))
			var prev := Vector3.ZERO
			for s in 12:
				var f := float(s) / 11.0
				var pos := e0.lerp(e1, f) + Vector3(0, 7.5 - 1.6 * sin(f * PI), 0)
				if s > 0:
					cables.append(_tramo_cable(prev, pos, 0.025))
				prev = pos
				## La bombilla cuelga justo bajo el cable.
				(por_color[s % colores.size()] as Array).append(Transform3D(Basis.from_scale(Vector3.ONE * 0.24), pos - Vector3(0, 0.16, 0)))
				n += 1
			for e: Vector3 in [e0, e1]:
				postes_g.append(Transform3D(Basis.from_scale(Vector3(0.09, 7.7, 0.09)), e + Vector3(0, 3.85, 0)))
	for k in colores.size():
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colores[k]
		mat.emission_enabled = true
		mat.emission = colores[k]
		mat.emission_energy_multiplier = 0.2
		_bombillas.append(mat)
		var esf := SphereMesh.new()
		esf.radial_segments = 6
		esf.rings = 3
		var lista: Array[Transform3D] = []
		lista.assign(por_color[k])
		_multimesh(esf, mat, lista, Vector3.ONE)
	var oscuro := b._mat_simple(Color(0.12, 0.12, 0.13), 0.6)
	_multimesh(CylinderMesh.new(), oscuro, cables, Vector3.ONE)
	_multimesh(CylinderMesh.new(), oscuro, postes_g, Vector3.ONE)
	cuenta["bombillas"] = n
