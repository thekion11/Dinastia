extends "res://ui/sorteo_escena3d_p1.gd"
## (Parte 2 de 3 de `sorteo_escena3d.gd`.)

# --- el bombo ----------------------------------------------------------------

## El cuenco de metacrilato y su peana. El cristal es transparente CON
## refracción: las bolas se ven a través, deformadas, que es justo lo que se ve
## en la foto de un sorteo de verdad.
func _montar_bombo() -> void:
	_bombo = Node3D.new()
	## Sobre la tarima, no sobre el suelo: la peana baja 1,02 desde aquí, así que
	## a 1,46 apoya justo en el canto de 0,42 del escenario.
	_bombo.position = Vector3(0, 1.46, -0.6)
	add_child(_bombo)

	var cristal := StandardMaterial3D.new()
	cristal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cristal.albedo_color = Color(0.80, 0.88, 0.95, 0.17)
	cristal.metallic = 0.25
	cristal.roughness = 0.03
	## En Compatibility (móvil, web) la refracción no existe y el cristal se
	## pintaba NEGRO y opaco: las bolas no se veían.
	cristal.refraction_enabled = RenderingServer.get_current_rendering_method() != "gl_compatibility"
	cristal.refraction_scale = 0.09
	## CULL_DISABLED: sin esto solo se ve la mitad de atrás y el cristal parece
	## una cáscara en vez de un recipiente.
	cristal.cull_mode = BaseMaterial3D.CULL_DISABLED
	cristal.rim_enabled = true
	cristal.rim = 0.9

	var cuenco := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = RADIO_BOMBO
	esfera.height = RADIO_BOMBO * 2.0
	esfera.is_hemisphere = true
	esfera.radial_segments = 48
	esfera.rings = 24
	cuenco.mesh = esfera
	## Boca arriba: la hemisfera de Godot nace mirando hacia arriba, se voltea.
	cuenco.rotation_degrees.x = 180.0
	cuenco.material_override = cristal
	_bombo.add_child(cuenco)

	var met := StandardMaterial3D.new()
	met.albedo_color = Color(0.85, 0.87, 0.9)
	met.metallic = 1.0
	met.roughness = 0.18

	## El aro del borde: el detalle que hace que el cristal "acabe" en algo en
	## vez de desvanecerse.
	var aro := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = RADIO_BOMBO - 0.012
	toro.outer_radius = RADIO_BOMBO + 0.018
	toro.rings = 48
	aro.mesh = toro
	aro.material_override = met
	_bombo.add_child(aro)

	var tallo := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.07
	cil.bottom_radius = 0.09
	## Del fondo del cuenco (-RADIO) a la peana (-1,02): con el cuenco más
	## grande, el tallo de antes asomaba DENTRO del cristal.
	cil.height = maxf(0.05, 1.02 - RADIO_BOMBO)
	tallo.mesh = cil
	tallo.material_override = met
	tallo.position = Vector3(0, -(1.02 + RADIO_BOMBO) * 0.5, 0)
	_bombo.add_child(tallo)
	var peana := MeshInstance3D.new()
	var cil2 := CylinderMesh.new()
	cil2.top_radius = 0.30
	cil2.bottom_radius = 0.34
	cil2.height = 0.07
	peana.mesh = cil2
	peana.material_override = met
	peana.position = Vector3(0, -1.02, 0)
	_bombo.add_child(peana)

	_montar_paredes_fisicas()

## Las bolas. Nacen escalonadas en altura para que caigan unas sobre otras y se
## coloquen solas: por eso el montón nunca sale igual dos veces.
func _montar_bolas() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = textura_balon()
	mat.roughness = 0.78
	mat.metallic = 0.0
	## Plástico satinado: ni mate ni espejo, que es lo que son de verdad. Bajo
	## de especular a propósito -a 0,65 los focos las dejaban blancas y el dibujo
	## del balón desaparecía bajo el brillo.
	mat.metallic_specular = 0.12
	for i in BOLAS_MAX:
		var b := RigidBody3D.new()
		b.mass = 0.06
		## Deteccion continua: a este tamaño y con estos empujones las bolas se
		## atravesaban entre ellas y se veían aplastadas, como si fueran óvalos.
		b.continuous_cd = true
		b.contact_monitor = false
		var fis := PhysicsMaterial.new()
		fis.bounce = 0.35
		fis.friction = 0.55
		b.physics_material_override = fis
		var forma := CollisionShape3D.new()
		var ef := SphereShape3D.new()
		ef.radius = RADIO_BOLA
		forma.shape = ef
		b.add_child(forma)
		var m := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = RADIO_BOLA
		esfera.height = RADIO_BOLA * 2.0
		esfera.radial_segments = 32
		esfera.rings = 16
		m.mesh = esfera
		m.material_override = mat
		b.add_child(m)
		## DENTRO DEL CUENCO, no encima. El cuenco tiene el centro en y=0.92 y un
		## radio de 0.62, así que su interior va de y=0.30 a y=0.92. La primera
		## versión las soltaba hasta un metro por encima del borde: caían fuera,
		## rebotaban por el plató y en la captura se veían flotando en el aire.
		## Ángulo áureo para repartirlas sin que queden en filas.
		var ang := float(i) * 2.399
		var rad := 0.05 + fmod(float(i) * 0.13, 0.45)
		var alto := -RADIO_BOMBO + 0.16 + float(i % 9) * 0.072
		b.position = _bombo.position + Vector3(cos(ang) * rad, alto, sin(ang) * rad)
		add_child(b)
		_bolas.append(b)

## LAS CAPAS DE PROFUNDIDAD. Un plató con un solo objeto en medio se ve plano
## por muy bien iluminado que esté: falta cosa DELANTE y cosa DETRÁS del sujeto.
## Aquí van cuatro:
##   · dos columnas de luz que enmarcan el bombo (fondo)
##   · una tarima con borde luminoso donde se apoya (medio)
##   · polvo suspendido que cruza el haz (aire)
##   · un aro de suelo que recoge el reflejo (base)
func _montar_capas(fondo: Color) -> void:
	## Columnas: los pilares del decorado. Emiten poco, pero al estar en el
	## plano de atrás dan escala y separan el bombo de la pared.
	for lado in [-1.0, 1.0]:
		var col := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.22, 5.4, 0.22)
		col.mesh = cm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = fondo.darkened(0.7)
		mat.emission_enabled = true
		mat.emission = _acento
		mat.emission_energy_multiplier = 0.55
		col.material_override = mat
		col.position = Vector3(lado * 2.5, 2.7, -4.6)
		add_child(col)

	## La tarima: el bombo tiene que apoyarse en ALGO. Sin ella flota sobre un
	## suelo infinito y se nota que es una escena montada, no un plató.
	## El disco decorativo se quitó: desde que hay tarima de verdad, su borde
	## luminoso cruzaba por delante del bombo y lo partía en dos.
	var tarima := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 1.15
	tm.bottom_radius = 1.3
	tm.height = 0.22
	tarima.mesh = tm
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = fondo.darkened(0.6)
	tmat.metallic = 0.6
	tmat.roughness = 0.35
	tarima.material_override = tmat
	tarima.position = Vector3(0, 0.53, -0.6)
	tarima.visible = false
	add_child(tarima)
	## El aro luminoso del borde de la tarima: es la línea que engancha la vista
	## y la lleva al centro.
	var aro := MeshInstance3D.new()
	var am := TorusMesh.new()
	am.inner_radius = 1.19
	am.outer_radius = 1.215
	am.rings = 64
	aro.mesh = am
	var amat := StandardMaterial3D.new()
	amat.albedo_color = _acento
	amat.emission_enabled = true
	amat.emission = _acento
	amat.emission_energy_multiplier = 0.85
	aro.material_override = amat
	aro.position = Vector3(0, 0.65, -0.6)
	aro.visible = false
	add_child(aro)

	## Polvo en suspensión. Es la capa que más barato sale y más aporta: motas
	## cruzando el haz de los focos, que es lo que hace que el aire "exista".
	##
	## LA PRIMERA VERSIÓN SE LEÍA COMO UN CIELO ESTRELLADO, no como polvo: 340
	## motas blancas a brillo casi pleno (1,6 de emisión, 0,55 de alfa) llenaban
	## el fotograma entero -incluso detrás de la pantalla y por encima de la
	## pared, fuera de cualquier foco- y en la distancia cada una queda como un
	## punto fijo indistinguible de una estrella. Menos cantidad, mucho menos
	## brillo y una caja de emisión más baja y pegada al suelo -donde de verdad
	## se ve cruzar la luz de los focos- es lo que separa "hay aire" de
	## "hay un planetario detrás".
	var polvo := GPUParticles3D.new()
	polvo.amount = 90
	polvo.lifetime = 10.0
	polvo.preprocess = 6.0
	polvo.visibility_aabb = AABB(Vector3(-4, -0.5, -3.5), Vector3(8, 3.5, 5.5))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(2.6, 1.1, 1.8)
	pm.direction = Vector3(0.2, 1, 0)
	pm.spread = 30.0
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.09
	pm.gravity = Vector3(0, 0.008, 0)
	pm.scale_min = 0.2
	pm.scale_max = 0.6
	pm.color = Color(1, 1, 1, 0.5)
	polvo.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.012, 0.012)
	var qmat := StandardMaterial3D.new()
	qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qmat.emission_enabled = true
	qmat.emission = Color(1, 1, 1)
	qmat.emission_energy_multiplier = 0.6
	qmat.albedo_color = Color(1, 1, 1, 0.3)
	qm.material = qmat
	polvo.draw_pass_1 = qm
	polvo.position = Vector3(0, 1.1, 0.4)
	add_child(polvo)

## EL PÚBLICO. Filas de butacas y siluetas sentadas, en penumbra y por delante
## de la tarima. No se les ve la cara -ni falta-: lo que hacen es tapar el borde
## inferior del encuadre y decir que hay gente mirando. Es el mismo truco de la
## grada del estadio, y cuesta lo mismo: cajas y cápsulas.
func _montar_publico(fondo: Color) -> void:
	var mat_butaca := StandardMaterial3D.new()
	mat_butaca.albedo_color = fondo.darkened(0.85)
	mat_butaca.roughness = 0.9
	var mat_gente := StandardMaterial3D.new()
	mat_gente.albedo_color = Color(0.05, 0.055, 0.07)
	mat_gente.roughness = 0.95
	for fila in 5:
		var z := 2.7 + float(fila) * 0.95
		## Las filas de atrás van un poco más altas: patio en pendiente.
		var y := 0.0 + float(fila) * 0.12
		for i in 22:
			var x := -6.3 + float(i) * 0.6
			## Ni una fila llena del todo: los huecos son lo que hace que parezca
			## público y no una cuadrícula.
			if fmod(float(fila * 31 + i * 17) * 0.113, 1.0) < 0.18:
				continue
			var b := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.5, 0.5, 0.5)
			b.mesh = bm
			b.material_override = mat_butaca
			b.position = Vector3(x, y + 0.25, z)
			add_child(b)
			var cab := MeshInstance3D.new()
			var capsula := CapsuleMesh.new()
			capsula.radius = 0.16
			capsula.height = 0.62
			cab.mesh = capsula
			cab.material_override = mat_gente
			cab.position = Vector3(x, y + 0.78, z + 0.04)
			add_child(cab)

func _montar_pantalla_gigante(fondo: Color) -> void:
	_pantalla_vp = SubViewport.new()
	_pantalla_vp.size = Vector2i(1024, 512)
	_pantalla_vp.transparent_bg = false
	_pantalla_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_pantalla_vp)

	var f := ColorRect.new()
	f.color = fondo.darkened(0.25)
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pantalla_vp.add_child(f)
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 18)
	_pantalla_vp.add_child(caja)

	_pantalla_grupo = Label.new()
	_pantalla_grupo.text = ""
	_pantalla_grupo.add_theme_font_size_override("font_size", 46)
	_pantalla_grupo.add_theme_color_override("font_color", _acento)
	_pantalla_grupo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(_pantalla_grupo)

	_pantalla_escudo = TextureRect.new()
	_pantalla_escudo.custom_minimum_size = Vector2(210, 210)
	_pantalla_escudo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pantalla_escudo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pantalla_escudo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caja.add_child(_pantalla_escudo)

	_pantalla_nombre = Label.new()
	_pantalla_nombre.text = ""
	_pantalla_nombre.add_theme_font_size_override("font_size", 62)
	_pantalla_nombre.add_theme_color_override("font_color", Color("f2f6f3"))
	_pantalla_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caja.add_child(_pantalla_nombre)

	## El plano donde se proyecta, delante de los paneles LED.
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(7.4, 3.7)
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.15
	var tex := _pantalla_vp.get_texture()
	mat.albedo_texture = tex
	mat.emission_texture = tex
	m.material_override = mat
	m.position = Vector3(0, 3.35, -6.2)
	add_child(m)

func _montar_presentador_realista() -> bool:
	if not PersonaRealista.disponible():
		return false
	var p := PersonaRealista.crear(PersonaRealista.aspecto("presentador_sorteo",
		{"ropa": "negro", "pantalon": "gris", "pelo": "negro", "piel": "media", "alto": 1.82, "ancho": 1.0}))
	if p == null:
		return false
	p.position = Vector3(1.15, 0.42, -0.35)
	_giro_presentador = deg_to_rad(-32.0)
	p.rotation.y = _giro_presentador
	add_child(p)
	_presentador_real = p
	return true

## El presentador es el mismo cuerpo que usan los 22 del campo, con "parado"
## y "mostrar_tarjeta" en su catálogo.
func _montar_presentador_quaternius() -> bool:
	var d := FutbolistaQ.crear(1.78, "male")
	if d.is_empty():
		return false
	var raiz: Node3D = d["nodo"]
	raiz.position = Vector3(1.15, 0.42, -0.35)
	raiz.rotation.y = deg_to_rad(-32.0)
	add_child(raiz)
	FutbolistaQ.terminar(d, true)
	## Traje azul marino oscuro, de manga y pantalón largos: mismo tono que la
	## silueta de respaldo. Solapa un poco más clara que el traje.
	var traje := Color(0.12, 0.13, 0.19)
	if not VestidorQ.vestir_equipacion(d, traje, Color(0.2, 0.22, 0.3), "liso",
			Color(0.82, 0.63, 0.5), Color(0.14, 0.11, 0.09), traje, Color(0.05, 0.05, 0.06), true):
		VestidorQ.vestir(d, traje)
	_anim_presentador = d["anim"]
	if _anim_presentador != null and _anim_presentador.has_animation("parado"):
		_anim_presentador.play("parado")
	return true

func _montar_presentador_modelo() -> bool:
	return _montar_presentador_realista() or _montar_presentador_quaternius()

## El brazo que entra en el bombo, aparte del modelo: así el gesto funciona
## igual con el humanoide y con la silueta, y no depende de que el esqueleto
## importado tenga los huesos con el nombre que uno espera.
## `padre` y `hombro`: EL BRAZO TIENE QUE COLGAR DEL CUERPO, NO DEL PLATÓ. La
## primera versión lo colgaba de `self` en una posición absoluta ajustada a
## ojo para que "más o menos" coincidiera con el torso; en cuanto la cámara
## giraba o el cuerpo llevaba su propio giro (`p.rotation.y`), el hombro y el
## brazo dejaban de coincidir y en captura se veía un brazo flotando aparte
## de la silueta. Colgándolo del mismo `Node3D` que el torso -en coordenadas
## LOCALES de ese cuerpo- el hombro queda pegado al torso sea cual sea el
## giro con el que se monte al presentador. Sin argumentos se mantiene el
## comportamiento antiguo -colgado de `self`, posición absoluta-: esta función
## ya solo la usa `_montar_presentador_siluetas()`, el respaldo para cuando
## `FutbolistaQ.crear()` no puede montar el modelo (`d.is_empty()`).
func _montar_brazo_suelto(padre: Node3D = null, hombro: Vector3 = Vector3(0.93, 1.78, -0.33)) -> void:
	var traje_mat := StandardMaterial3D.new()
	traje_mat.albedo_color = Color(0.10, 0.11, 0.16)
	traje_mat.roughness = 0.85
	var piel := StandardMaterial3D.new()
	piel.albedo_color = Color(0.52, 0.40, 0.33)
	piel.roughness = 0.7
	_brazo = Node3D.new()
	_brazo.position = hombro
	(padre if padre != null else self).add_child(_brazo)
	var antebrazo := MeshInstance3D.new()
	var am := CapsuleMesh.new()
	am.radius = 0.062
	am.height = 0.72
	antebrazo.mesh = am
	antebrazo.material_override = traje_mat
	antebrazo.position = Vector3(0, -0.36, 0)
	_brazo.add_child(antebrazo)
	_mano = MeshInstance3D.new()
	var mm := SphereMesh.new()
	mm.radius = 0.075
	mm.height = 0.15
	_mano.mesh = mm
	_mano.material_override = piel
	_mano.position = Vector3(0, -0.74, 0)
	_brazo.add_child(_mano)
	_brazo.rotation_degrees = Vector3(0, 0, 6)
