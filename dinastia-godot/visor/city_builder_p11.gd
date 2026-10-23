extends "res://visor/city_builder_p10.gd"
## (Parte 11 de 12 de `city_builder.gd`.)

## La marea de gente alrededor del estadio.
##
## 8-10-2026: antes era una cápsula por persona, toda del color del club, y
## desde arriba se leían como PALOS blancos y negros clavados en el césped
## (el usuario: «¿esas cosas negras y blancas como palos son personas?»).
## Ahora cada hincha tiene piernas con pantalón, torso y brazos con la
## camiseta, cuello y cabeza con su tono de piel: tres MultiMesh que comparten
## posiciones (una sola llamada de dibujo por pieza para los 600).
func _hinchada_estadio(c1: Color, c2: Color, rng: RandomNumberGenerator) -> void:
	var piezas := _mallas_hincha_de_pie()
	var n := 600
	var mms: Array[MultiMesh] = []
	for pz in 3:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = piezas[pz]
		mm.instance_count = n
		mms.append(mm)
	var pieles := [Color(0.96, 0.8, 0.66), Color(0.87, 0.67, 0.5), Color(0.72, 0.52, 0.36), Color(0.5, 0.34, 0.22), Color(0.34, 0.22, 0.15)]
	var pantalones := [Color(0.16, 0.2, 0.32), Color(0.12, 0.12, 0.14), Color(0.3, 0.32, 0.36), Color(0.42, 0.36, 0.28), Color(0.22, 0.3, 0.48)]
	for k in n:
		var ang := rng.randf() * TAU
		var r := rng.randf_range(105.0, 150.0)
		var p := ESTADIO_EN + Vector3(cos(ang) * r, 0.0, sin(ang) * r * 0.8)
		## Nadie dentro de un edificio (el vestuario del estadio, por ejemplo).
		for intento in 8:
			if not _en_huella(p):
				break
			ang = rng.randf() * TAU
			p = ESTADIO_EN + Vector3(cos(ang) * r, 0.0, sin(ang) * r * 0.8)
		## Mirando más o menos al estadio, cada uno a su altura.
		var hacia := ESTADIO_EN - p
		var giro := atan2(hacia.x, hacia.z) + rng.randf_range(-0.9, 0.9)
		var esc := rng.randf_range(0.9, 1.08)
		var t := Transform3D(Basis(Vector3.UP, giro).scaled(Vector3.ONE * esc), p)
		var tono := rng.randf()
		var camiseta: Color = c1 if tono < 0.45 else (c2 if tono < 0.7 else Color(0.2, 0.22, 0.25).lerp(Color(0.85, 0.85, 0.85), rng.randf()))
		var cols := [pantalones[rng.randi() % pantalones.size()], camiseta, pieles[rng.randi() % pieles.size()]]
		for pz in 3:
			mms[pz].set_instance_transform(k, t)
			mms[pz].set_instance_color(k, cols[pz])
	var gente := Node3D.new()
	gente.name = "Hinchada"
	add_child(gente)
	for pz in 3:
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mms[pz]
		gente.add_child(mi)
	_rotulo(ESTADIO_EN + Vector3(0, 62.0, 0), "⚽ HOY HAY PARTIDO", Color(1.0, 0.85, 0.3))

## DÍA DE PARTIDO: banderas del club en las farolas del anillo y la hinchada
## caminando hacia el estadio. La gente es un MultiMesh de cápsulas -600 en un
## solo draw call- con los dos colores del club y ropa neutra.
func _dia_de_partido() -> void:
	var c1 := _color_club("c1", Color(0.2, 0.5, 0.3))
	var c2 := _color_club("c2", Color(1, 1, 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	_banderas_anillo(c1, c2)
	_hinchada_estadio(c1, c2, rng)

func _animo_del_club() -> void:
	var animo: Dictionary = datos.get("animo", {})
	if animo.is_empty():
		return
	var c1 := _color_club("c1", Color(0.2, 0.5, 0.3))
	var c2 := _color_club("c2", Color(1, 1, 1))
	animo_montado = CiudadAnimo.montar(self, animo, _frentes, ESTADIO_EN, c1, c2)
	var est := String(animo.get("estado", "normal"))
	if est == "euforia":
		_banderas_anillo(c1, c2)
	var txt := {"euforia": "🏆 LA CIUDAD ESTÁ DE FIESTA", "bien": "🙂 Buen ambiente en la ciudad",
		"mal": "😒 La ciudad empieza a impacientarse", "crisis": "😡 LA CIUDAD ESTÁ HARTA"}.get(est, "") as String
	if txt != "":
		var col := Color(1.0, 0.85, 0.3) if est in ["euforia", "bien"] else Color(1.0, 0.45, 0.4)
		_rotulo(ESTADIO_EN + Vector3(0, 78.0, 0), "%s · %s" % [txt, String(animo.get("motivo", ""))], col, 26)

## El humor del barrio sobre el barrio.
func _rotulo_barrio() -> void:
	if not datos.has("vecinos"):
		return
	var v := int(datos["vecinos"])
	var cara := "🙂" if v >= 65 else ("😠" if v <= 35 else "😐")
	var col := Color(0.55, 0.9, 0.6) if v >= 65 else (Color(1.0, 0.5, 0.45) if v <= 35 else Color(1.0, 0.85, 0.45))
	_rotulo(BARRIO_EN + Vector3(0, 55.0, 0), "%s Vecinos %d/100" % [cara, v], col)

func _despejar_vestuario(n: Node, t: Transform3D = Transform3D()) -> void:
	## Se llama antes de que la ciudad esté en el árbol: las posiciones se
	## componen a mano (relativas a la ciudad), no con `global_position`.
	if _rect_vestuario.size == Vector2.ZERO or n.name == "TunelVestuario":
		return
	for h in n.get_children():
		if not (h is Node3D):
			continue
		var th: Transform3D = t * (h as Node3D).transform
		if h is MeshInstance3D:
			var mi := h as MeshInstance3D
			var p := th.origin
			var en_entrada := _rect_entrada.has_point(Vector2(p.x, p.z)) and p.y < 3.0 and mi.get_aabb().size.y >= 0.3 and mi.get_aabb().size.y < 3.5
			if mi.mesh != null and (en_entrada or (_rect_vestuario.has_point(Vector2(p.x, p.z)) and mi.get_aabb().size.y < 0.3 and p.y < 0.5)):
				mi.get_parent().remove_child(mi)
				mi.queue_free()
				continue
		_despejar_vestuario(h, th)

## Recorre TODO lo construido y viste los rascacielos y bloques simples del
## kit, sea quien sea el que los puso (se reconocen por el nombre de la malla).
func vestir_todas_las_torres() -> int:
	var cuenta := 0
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null or m3.material_override != null:
			continue
		var nombre := m3.mesh.resource_name
		if nombre.begins_with("building-skyscraper") or nombre.begins_with("low-detail-building"):
			vestir_torre(m3, hash(Vector2(m3.global_position.x, m3.global_position.z)))
			cuenta += 1
	return cuenta

func build(d: Dictionary) -> void:
	datos = d
	## La ciudad vieja se quita YA, no al final del cuadro: con `queue_free` las
	## dos ciudades convivían un cuadro y el motor avisaba «material is null»
	## al soltar la vieja (7-10-2026).
	for c in get_children():
		remove_child(c)
		c.free()
	etiquetas.clear()
	circulos = PackedVector3Array()
	_mats_torre.clear()
	puntos_clic.clear()
	_rotulos = Node3D.new()
	_rotulos.name = "Rotulos"
	_farolas_luz.clear()
	_ventanas_mat.clear()
	_vias.clear()
	_frentes.clear()
	huellas.clear()
	_rect_vestuario = Rect2()
	_anillo_con_banderas = false
	_luminarias.clear()
	_luz_color = _color_luces()
	_t_marca = Time.get_ticks_usec()

	_suelo()
	_marca("_suelo")
	_calles()
	_marca("_calles")
	_estadio()
	_marca("_estadio")
	_campos()
	_marca("_campos")
	_complejo()
	_marca("_complejo")
	_huerto()
	_marca("_huerto")
	_piscina_olimpica()
	_marca("_piscina_olimpica")
	_polideportivo()
	_marca("_polideportivo")
	_canchas_secundarias()
	_marca("_canchas_secundarias")
	_aparcamiento()
	_marca("_aparcamiento")
	_paradas_bus()
	_marca("_paradas_bus")
	_perimetro()
	_marca("_perimetro")
	_parcelas()
	_marca("_parcelas")
	_barrio_residencial()
	_marca("_barrio_residencial")
	_frentes_urbanos()
	_marca("_frentes_urbanos")
	## LA CIUDAD GRANDE (7-10-2026): sustituye a los tres distritos sueltos de
	## la pasada anterior por una ciudad entera con su red vial.
	expansion = CiudadExpansion.new(self)
	expansion.construir()
	_marca("expansion.construir")
	_karting()
	_marca("_karting")
	_arbolado()
	_marca("_arbolado")
	_horizonte()
	_marca("_horizonte")
	_trafico()
	_marca("_trafico")
	## B7: el día de partido, el ánimo del barrio y los rótulos flotantes.
	if bool(datos.get("dia_partido", false)):
		_dia_de_partido()
		_marca("_dia_de_partido")
	_animo_del_club()
	_marca("_animo_del_club")
	_rotulo_barrio()
	_marca("_rotulo_barrio")
	add_child(_rotulos)
	_despejar_vestuario(self)
	## Etapa 3: primitivas con el detalle justo y butacas livianas (el estadio
	## se ve de lejos; al entrar a pie vuelven las buenas).
	## (SIN_OPTIMIZAR=1 lo apaga, para comparar capturas antes/después.)
	var n_torres := vestir_todas_las_torres()
	if _medir_tiempos:
		var nombres := {}
		for mi in find_children("*", "MeshInstance3D", true, false):
			var m4 := (mi as MeshInstance3D).mesh
			if m4 is ArrayMesh and Optimizar._tris(m4) > 1500:
				nombres[m4.resource_name] = int(nombres.get(m4.resource_name, 0)) + 1
		print("TORRES vestidas ", n_torres, "  mallas pesadas: ", nombres)
	if OS.get_environment("SIN_OPTIMIZAR") == "":
		Optimizar.primitivas(self)
		Optimizar.trocear(self)
		Optimizar.butacas_livianas(self, true)
		Optimizar.distancias(self)
		_marca("despejar")
		Optimizar.primitivas(self)
		Optimizar.butacas_livianas(self, true)
		Optimizar.distancias(self)
		_marca("opt_distancias")
		circulos = Optimizar.obstaculos(self, ExploradorCiudad.construir_obstaculos(self))
		_marca("obstaculos")
		OclusoresCiudad.montar(self)
		_marca("oclusores")
		Optimizar.agrupar(self)
		_marca("opt_agrupar")

## `noche` va de 0 (pleno día) a 1 (noche cerrada). Lo llama el ciclo del sol
## de `VistaCiudad` en cada fotograma. Las farolas se encienden con la luz, y
## las ventanas pasan de un reflejo apagado a estar iluminadas por dentro:
## es lo que hace que a las 22:00 la ciudad deportiva siga estando AHÍ en vez
## de desaparecer en un bloque negro.
func encender_luces(noche: float) -> void:
	if expansion != null:
		expansion.encender(noche)
	## Los faros de los coches (M-175).
	var traf := get_node_or_null("Trafico") as TraficoCiudad
	if traf != null:
		traf.faros(noche)
	var f: float = clampf(noche, 0.0, 1.0)
	for mt in _mats_torre:
		mt.set_shader_parameter("noche", f)
	StadiumBuilder.encender_conos(f)
	for l in _farolas_luz:
		if is_instance_valid(l):
			## 5,4 y no 2,4: se midió que a 2,4 las farolas SÍ estaban
			## encendidas -energía correcta, color correcto, visibles- pero el
			## charco de luz en el suelo no llegaba a leerse. El fallo no era
			## que no funcionaran, era que no se notaban.
			l.light_energy = 5.4 * f
			l.visible = f > 0.02
	## La luminaria se enciende ANTES que la luz del suelo y se apaga después:
	## en la vida real ves la bombilla encendida un buen rato antes de que se
	## note en el asfalto, y ese desfase es justo lo que hace creíble el
	## atardecer. `pow` con exponente < 1 sube rápido al principio.
	##
	## Y EL MULTIPLICADOR ES 1,6 POR EL `glow`, no por el brillo en sí:
	## `glow_hdr_threshold` está en 1,05, así que todo canal que pase de ahí
	## florece. Con 7 -el primer intento- un cian (0,49 · 0,88 · 1,0) se iba a
	## (3,4 · 6,2 · 7): los TRES canales por encima del umbral, y el halo salía
	## BLANCO, con lo que el color elegido no se veía -que era justo lo único
	## que se le pedía a la farola-. Con 1,6 el canal rojo se queda en 0,79,
	## por debajo del umbral, y el halo conserva el tono.
	## 2,2 y no 7: a 7 el tonemapper satura la luminaria a BLANCO y el color
	## elegido no se veía -que es justo lo único que se pedía de ella-. El
	## brillo que hace falta para que se note de lejos lo pone el halo (`glow`
	## del entorno), no la emisión bruta.
	for lm in _luminarias:
		if lm != null:
			lm.emission_energy_multiplier = 1.6 * pow(f, 0.45)
	for m in _ventanas_mat:
		if m != null:
			## Cada tira se enciende en SU propio umbral de la noche (0,55 de
			## margen) y llega a SU propio techo de brillo (0,5 a 1,0): así no
			## se prende todo el edificio de golpe a la misma hora, y unas
			## pocas ventanas se quedan siempre más apagadas que el resto,
			## como una oficina vacía o alguien que ya se fue.
			var azar: float = m.get_meta("_azar_ventana", 0.5)
			var umbral: float = azar * 0.55
			var t: float = clampf((f - umbral) / (1.0 - umbral), 0.0, 1.0)
			## El TECHO no sale del mismo azar que el umbral tal cual -si no,
			## las que se encienden tarde serían siempre además las más
			## tenues, demasiado ordenado para verse al azar de verdad-. Un
			## segundo valor derivado del primero, y cerca de un tercio de las
			## ventanas se quedan oscuras -o casi- toda la noche: ninguna
			## oficina real enciende el 100% de sus luces a la vez.
			var azar2: float = fmod(azar * 7.13 + 0.37, 1.0)
			var techo: float = 1.0 - smoothstep(0.60, 0.93, azar2) * 0.88
			m.emission_energy_multiplier = lerpf(0.18, 2.6 * techo, t)
	## El río también sigue la hora: de noche un agua igual de clara que a
	## mediodía se vería como una franja fluorescente en mitad del campo.
	if _agua_mat != null:
		_agua_mat.set_shader_parameter("brillo", lerpf(1.0, 0.28, f))

func _notification(que: int) -> void:
	if que == NOTIFICATION_ENTER_TREE and not _personal_pendiente.is_empty():
		var lista := _personal_pendiente.duplicate()
		_personal_pendiente.clear()
		for p: Array in lista:
			_personal_en(String(p[0]), p[1], float(p[2]), int(p[3]))

func _hacer_velero() -> Node3D:
	var malla := load(RUTA_VELERO)
	if malla == null:
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.93, 0.93, 0.90)
	mat.roughness = 0.45
	mi.material_override = mat
	## Escala MEDIDA, no a ojo -misma regla de siempre-: se ajusta para que el
	## casco mida unos 13 m, que es un velero de recreo de verdad.
	var esc := 1.0
	if mi.mesh != null:
		var caja: AABB = mi.mesh.get_aabb()
		var largo: float = maxf(maxf(caja.size.x, caja.size.z), 0.001)
		esc = 13.0 / largo
	mi.scale = Vector3.ONE * esc
	return mi

func _franja(centro: Vector3, tam: Vector2, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(tam.x, 0.1, tam.y)
	m.mesh = bm
	m.material_override = mat
	m.position = Vector3(centro.x, altura_en(centro.x, centro.z) + 0.05, centro.z)
	add_child(m)

## Una torre del kit en el centro del distrito norte, con su plaza.
func _torre_distrito(esc: PackedScene, c: Vector3, rng: RandomNumberGenerator) -> void:
	var t: Node3D = esc.instantiate()
	var s: float = 3.6 * rng.randf_range(0.85, 1.3) * lerpf(0.85, 1.3, _empuje_club())
	t.scale = Vector3.ONE * s
	t.rotation.y = float(rng.randi() % 4) * PI * 0.5
	t.position = Vector3(c.x, altura_en(c.x, c.z) - 0.1, c.z)
	vestir_torre(t, hash(Vector2(c.x, c.z)))
	add_child(t)
	var caja := _caja_de(t)
	_frentes.append(Rect2(c.x - caja.size.x * s * 0.5, c.z - caja.size.z * s * 0.5, caja.size.x * s, caja.size.z * s))

## Una manzana: fachadas del kit mirando a la calle por los cuatro lados y un
## bloque alto dentro que asoma por encima.
func _manzana(c: Vector3, comercial: Array[PackedScene], naves: Array[PackedScene], toldos: Array[PackedScene], rng: RandomNumberGenerator) -> void:
	var lados := [
		{"n": Vector3(0, 0, 1), "dir": Vector3.RIGHT, "largo": MANZANA.x, "fondo": MANZANA.y},
		{"n": Vector3(0, 0, -1), "dir": Vector3.LEFT, "largo": MANZANA.x, "fondo": MANZANA.y},
		{"n": Vector3(1, 0, 0), "dir": Vector3.FORWARD, "largo": MANZANA.y, "fondo": MANZANA.x},
		{"n": Vector3(-1, 0, 0), "dir": Vector3.BACK, "largo": MANZANA.y, "fondo": MANZANA.x},
	]
	for l: Dictionary in lados:
		var n: Vector3 = l["n"]
		var dir: Vector3 = l["dir"]
		var largo: float = float(l["largo"]) - 14.0   ## las esquinas quedan libres
		var u := -largo * 0.5
		var giro := atan2(n.x, n.z)
		while u < largo * 0.5 - 5.0:
			var nodo: Node3D = comercial[rng.randi() % comercial.size()].instantiate()
			if rng.randf() < 0.45:
				tenir(nodo, rng.randi())
			var s: float = 4.6 * rng.randf_range(0.9, 1.1)
			nodo.scale = Vector3.ONE * s
			var caja := _caja_de(nodo)
			var ancho: float = maxf(caja.size.x * s, 5.0)
			var fondo: float = maxf(caja.size.z * s, 5.0)
			if u + ancho > largo * 0.5:
				nodo.free()
				break
			var p: Vector3 = c + dir * (u + ancho * 0.5) + n * (float(l["fondo"]) * 0.5 - fondo * 0.5 - 0.5)
			nodo.rotation.y = giro
			nodo.position = Vector3(p.x, altura_en(p.x, p.z) - 0.1, p.z)
			add_child(nodo)
			_frentes.append(_rect_de(p, dir, ancho, fondo))
			if not toldos.is_empty() and rng.randf() < 0.25:
				var tl: Node3D = toldos[rng.randi() % toldos.size()].instantiate()
				tl.scale = Vector3.ONE * 3.8
				tl.rotation.y = giro
				var tp: Vector3 = c + dir * (u + ancho * 0.5) + n * (float(l["fondo"]) * 0.5 + 1.2)
				tl.position = Vector3(tp.x, altura_en(tp.x, tp.z), tp.z)
				add_child(tl)
			u += ancho + rng.randf_range(0.3, 2.0)
	if not naves.is_empty() and rng.randf() < 0.85:
		var b: Node3D = naves[rng.randi() % naves.size()].instantiate()
		vestir_torre(b, int(b.get_instance_id()))
		var sb: float = 5.5 * rng.randf_range(0.9, 1.2)
		b.scale = Vector3.ONE * sb
		b.rotation.y = float(rng.randi() % 4) * PI * 0.5
		b.position = Vector3(c.x, altura_en(c.x, c.z) - 0.1, c.z)
		add_child(b)
