class_name SorteoEscena3D
extends "res://ui/sorteo_escena3d_p2.gd"
## (Parte 3 de 3 de `sorteo_escena3d.gd`.)

func _montar_presentador_siluetas() -> void:
	## Traje azul muy oscuro, no negro: el negro puro contra un plató oscuro se
	## come la silueta y el presentador desaparece.
	var traje := StandardMaterial3D.new()
	traje.albedo_color = Color(0.12, 0.13, 0.19)
	traje.roughness = 0.85
	var piel := StandardMaterial3D.new()
	piel.albedo_color = Color(0.52, 0.40, 0.33)
	piel.roughness = 0.7

	var p := Node3D.new()
	## A la derecha del bombo y un paso por detrás, que es donde se pone quien
	## sortea: no tapa el cuenco y queda dentro del cono de luz.
	p.position = Vector3(1.15, 0.42, -0.35)
	p.rotation.y = deg_to_rad(-32.0)
	add_child(p)

	var torso := MeshInstance3D.new()
	var tm := CapsuleMesh.new()
	tm.radius = 0.21
	tm.height = 0.92
	torso.mesh = tm
	torso.material_override = traje
	torso.position = Vector3(0, 1.02, 0)
	p.add_child(torso)
	var piernas := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.17
	pm.bottom_radius = 0.13
	pm.height = 0.62
	piernas.mesh = pm
	piernas.material_override = traje
	piernas.position = Vector3(0, 0.31, 0)
	p.add_child(piernas)
	var cabeza := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.125
	cm.height = 0.26
	cabeza.mesh = cm
	cabeza.material_override = piel
	cabeza.position = Vector3(0, 1.62, 0)
	p.add_child(cabeza)

	## Hombro en coordenadas LOCALES de `p`: al borde del torso (radio 0,21),
	## un poco por debajo de la cabeza y un poco hacia delante. Colgado de `p`
	## en vez de `self`, el brazo gira y se mueve CON el cuerpo -antes estaba
	## fijo en el mundo y se veía suelto en cuanto el cuerpo tenía su propio
	## ángulo-.
	_montar_brazo_suelto(p, Vector3(0.20, 1.30, 0.05))

func _montar_presentador() -> void:
	if USAR_MODELO_HUMANO and _montar_presentador_modelo():
		return
	_montar_presentador_siluetas()

## La bola que sale y la placa del escudo. Las dos empiezan escondidas.
func _montar_reveladores() -> void:
	_bola_fuera = MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = RADIO_BOLA * 1.05
	esfera.height = RADIO_BOLA * 2.1
	esfera.radial_segments = 32
	esfera.rings = 16
	_bola_fuera.mesh = esfera
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = textura_balon()
	mat.roughness = 0.35
	_bola_fuera.material_override = mat
	_bola_fuera.visible = false
	add_child(_bola_fuera)

	## La placa del escudo mira siempre a la cámara -`billboard`- para no tener
	## que orientarla a mano en cada fotograma.
	_escudo_placa = MeshInstance3D.new()
	var plano := QuadMesh.new()
	plano.size = Vector2(0.9, 0.9)
	_escudo_placa.mesh = plano
	var pm := StandardMaterial3D.new()
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	## Sin sombreado y con emisión: un escudo iluminado por los focos del plató
	## saldría gris, y así se lee igual que en el resto del juego.
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.emission_enabled = true
	pm.emission_energy_multiplier = 1.4
	_escudo_placa.material_override = pm
	_escudo_placa.visible = false
	add_child(_escudo_placa)

	_confeti = GPUParticles3D.new()
	_confeti.amount = 220
	_confeti.lifetime = 3.2
	_confeti.one_shot = true
	_confeti.explosiveness = 0.7
	_confeti.emitting = false
	_confeti.position = Vector3(0, 2.6, 0.6)
	var pp := ParticleProcessMaterial.new()
	pp.direction = Vector3(0, -1, 0)
	pp.spread = 55.0
	pp.initial_velocity_min = 1.2
	pp.initial_velocity_max = 3.4
	pp.gravity = Vector3(0, -2.2, 0)
	pp.scale_min = 0.4
	pp.scale_max = 1.1
	pp.angular_velocity_min = -320.0
	pp.angular_velocity_max = 320.0
	pp.color = _acento
	_confeti.process_material = pp
	var cm := BoxMesh.new()
	cm.size = Vector3(0.05, 0.02, 0.001)
	var cmat := StandardMaterial3D.new()
	cmat.emission_enabled = true
	cmat.emission = _acento
	cmat.emission_energy_multiplier = 2.2
	cm.material = cmat
	_confeti.draw_pass_1 = cm
	add_child(_confeti)

func _montar_camara() -> void:
	_camara = Camera3D.new()
	_camara.fov = 42.0
	add_child(_camara)
	_camara.position = Vector3(0, 2.15, 5.2)
	_camara.look_at(Vector3(0, 1.42, -0.6), Vector3.UP)
	## Profundidad de campo: el fondo desenfocado es lo que hace que parezca
	## grabado con una cámara y no calculado con una lente perfecta.
	var at := CameraAttributesPractical.new()
	at.dof_blur_far_enabled = true
	at.dof_blur_far_distance = 5.0
	at.dof_blur_far_transition = 2.5
	at.dof_blur_amount = 0.06
	_camara.attributes = at

func montar(acento: Color, fondo: Color, nivel: int = Calidad.ALTO) -> void:
	_acento = acento
	var we := Calidad.entorno(nivel, Calidad.NOCHE)
	add_child(we)
	## El cielo del estadio no pinta nada en un plató: se cambia por un color
	## plano y oscuro para que la vista caiga en el bombo, no en el horizonte.
	var env := we.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = fondo.darkened(0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	## (MEGAPLAN fase 1: la escena salía muy oscura. El ambiente era casi el
	## color del fondo -un verde muy oscuro-; ahora va hacia el blanco.)
	env.ambient_light_color = fondo.lerp(Color(0.85, 0.86, 0.9), 0.5)
	env.ambient_light_energy = 1.0
	## El resplandor sube respecto al estadio: en un plató las luces SON el
	## decorado, y sin bloom los focos parecen bombillas pintadas.
	env.glow_enabled = true
	env.glow_intensity = 0.95
	env.glow_bloom = 0.2
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	## Niebla fina: es lo que hace VISIBLES los conos de luz. Sin esto los focos
	## iluminan pero no se ven, y se pierde la mitad del efecto de plató.
	env.volumetric_fog_enabled = nivel >= Calidad.ALTO
	env.volumetric_fog_density = 0.055
	env.volumetric_fog_albedo = Color(0.85, 0.88, 0.95)
	env.volumetric_fog_length = 40.0
	## La exposición baja a 1,0. `Calidad.NOCHE` la deja en 1,4 porque está
	## pensada para un estadio de noche, donde casi todo es oscuro; aquí hay tres
	## focos apuntando a un objeto BLANCO, y a 1,4 los balones salían reventados:
	## se veían los parches negros flotando sobre una mancha sin forma.
	env.tonemap_exposure = 1.0

	_montar_suelo(fondo)
	_montar_sala(fondo)
	_montar_pared(fondo)
	_montar_luces()
	_montar_bombo()
	_montar_bolas()
	_montar_capas(fondo)
	_montar_publico(fondo)
	_montar_pantalla_gigante(fondo)
	_montar_presentador()
	_montar_reveladores()
	_montar_camara()

## LA SALA. Antes esto era un bombo flotando sobre un disco en mitad de la nada:
## se veía que era una escena montada, no un sitio. Un sorteo es una GALA, y una
## gala tiene tarima elevada, paredes que cierran, techo con truss de focos y
## gente sentada mirando. Sin esas cuatro cosas no hay sala, hay un objeto.
## LAS BANDERAS DEL ESTUDIO (MEGAPLAN fase 4): mástiles a los dos lados del
## fondo de la tarima con las banderas de los países que entran en el bombo
## (en una copa nacional, la del país repetida). Tela que ondea con el dibujo
## de `Banderas`.
func poner_banderas(codigos: Array) -> void:
	if codigos.is_empty():
		return
	var asta := StandardMaterial3D.new()
	asta.albedo_color = Color(0.82, 0.83, 0.86)
	asta.metallic = 0.9
	asta.roughness = 0.25
	var puestos: Array = []
	## Contra la pared del fondo, a los lados de la pantalla gigante: se leen
	## de frente y no se tapan entre sí.
	for lado in [-1.0, 1.0]:
		for k in 3:
			puestos.append(Vector3(lado * (3.7 + float(k) * 0.95), 0.42, -4.6))
	for i in puestos.size():
		var cod := String(codigos[i % codigos.size()])
		var base: Vector3 = puestos[i]
		var palo := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.025
		cm.bottom_radius = 0.035
		cm.height = 3.0
		palo.mesh = cm
		palo.material_override = asta
		palo.position = base + Vector3(0, 1.5, 0)
		add_child(palo)
		var qm := QuadMesh.new()
		qm.size = Vector2(0.82, 0.55)
		qm.subdivide_width = 12
		qm.subdivide_depth = 5
		qm.center_offset = Vector3(0.41, 0, 0)
		var tela := MeshInstance3D.new()
		tela.mesh = qm
		var mat := ShaderMaterial.new()
		mat.shader = StadiumBuilder.SHADER_BANDERA
		mat.set_shader_parameter("usa_dibujo", true)
		mat.set_shader_parameter("espejo", base.x > 0.0)
		mat.set_shader_parameter("dibujo", Banderas.textura(cod))
		mat.set_shader_parameter("tela", Texturas.tela(Color.WHITE).detail_albedo)
		mat.set_shader_parameter("ancho", 0.82)
		mat.set_shader_parameter("fase", float(i) * 1.3)
		mat.set_shader_parameter("viento", 0.35)
		tela.material_override = mat
		## La tela sale del asta hacia el centro del plató.
		var hacia_centro := -signf(base.x)
		tela.position = base + Vector3(0, 2.62, 0.03)
		tela.rotation.y = 0.0 if hacia_centro > 0.0 else PI
		add_child(tela)

## Lo que se anuncia en la pantalla gigante. Se llama al revelar cada bola.
func anunciar(escudo: Texture2D, nombre: String, grupo: String) -> void:
	if _pantalla_escudo == null:
		return
	_pantalla_escudo.texture = escudo
	_pantalla_nombre.text = nombre
	_pantalla_grupo.text = grupo

## Lo que pone la pantalla ANTES de que salga la primera bola. Sin esto se veía
## un rectángulo negro enorme al fondo de la sala durante los primeros segundos,
## que es justo cuando el jugador está mirando el decorado.
func rotular(competicion: String, ronda: String) -> void:
	if _pantalla_nombre == null:
		return
	_pantalla_grupo.text = competicion
	_pantalla_nombre.text = ronda
	_pantalla_escudo.texture = null

func _mallas_de(n: Node) -> Array[MeshInstance3D]:
	var salida: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		salida.append(n)
	for h in n.get_children():
		salida.append_array(_mallas_de(h))
	return salida

## El gesto de sacar la bola: el brazo se levanta, entra en el bombo y vuelve.
## Con el modelo real, es la misma animación del árbitro mostrando la tarjeta
## -levantar la mano en alto- y luego vuelve a "parado"; con la silueta de
## respaldo, sigue siendo el Tween del brazo suelto de siempre.
func gesto_sacar() -> Tween:
	if _presentador_real != null:
		var tr := create_tween()
		tr.tween_property(_presentador_real, "rotation", Vector3(deg_to_rad(6.0), _giro_presentador - deg_to_rad(22.0), 0), 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tr.tween_interval(0.35)
		tr.tween_property(_presentador_real, "rotation", Vector3(0, _giro_presentador, 0), 0.55) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		return tr
	if _anim_presentador != null and _anim_presentador.has_animation("mostrar_tarjeta"):
		_anim_presentador.stop()
		_anim_presentador.play("mostrar_tarjeta")
		var tv := create_tween()
		tv.tween_interval(_anim_presentador.get_animation("mostrar_tarjeta").length)
		tv.tween_callback(func() -> void:
			if _anim_presentador != null and _anim_presentador.has_animation("parado"):
				_anim_presentador.play("parado"))
		return tv
	var t := create_tween()
	t.tween_property(_brazo, "rotation_degrees", Vector3(0, 0, -74), 0.45) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(0.25)
	t.tween_property(_brazo, "rotation_degrees", Vector3(0, 0, 6), 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return t

# --- movimiento --------------------------------------------------------------

func _process(delta: float) -> void:
	_t += delta
	## La cámara respira: un vaivén lentísimo alrededor del bombo. Sin esto la
	## escena es un render fijo por bonito que sea.
	## LA CÁMARA. Antes era una sola órbita lentísima y por eso la cinemática se
	## veía plana: una retransmisión de verdad CORTA entre planos, no da vueltas
	## alrededor de un objeto durante minuto y medio. Ahora hay cuatro posiciones
	## -general de sala, medio del bombo, contrapicado del presentador y cerrado
	## de la pantalla- y se cambia de plano en cada bola. Dentro de cada plano la
	## cámara deriva un poco, que es lo que la separa de una foto fija.
	if _camara != null:
		## Tipo explícito: indexar un Array devuelve Variant y `:=` no infiere.
		var d: Dictionary = PLANOS[_plano]
		var desde: Vector3 = d["pos"]
		var hacia: Vector3 = d["mira"]
		var deriva := Vector3(sin(_t * 0.24) * 0.22, sin(_t * 0.33) * 0.07, cos(_t * 0.19) * 0.16)
		## El cambio de plano no es un salto seco: se interpola en medio segundo,
		## lo justo para que se lea como un travelling corto y no como un corte
		## de montaje, que en una escena tan quieta chirriaría.
		_mezcla_plano = minf(1.0, _mezcla_plano + delta * 2.0)
		_cam_pos = _cam_pos.lerp(desde + deriva, clampf(delta * 3.5, 0.0, 1.0))
		_cam_mira = _cam_mira.lerp(hacia, clampf(delta * 3.5, 0.0, 1.0))
		_camara.position = _cam_pos
		_camara.look_at(_cam_mira, Vector3.UP)
	## El presentador respira: sin esqueleto, es lo que lo separa de una estatua.
	if _presentador_real != null:
		_presentador_real.scale = Vector3(1.0, 1.0 + sin(_t * 1.5) * 0.004, 1.0)
	## Los focos barren despacio y desfasados entre sí: eso da vida al plató.
	for i in _focos.size():
		var f := _focos[i]
		var d := sin(_t * (0.35 + float(i) * 0.11) + float(i) * 2.1) * 1.3
		f.look_at_from_position(f.position, Vector3(d, 1.3, -0.6), Vector3.UP)

	## EL BOMBO GIRA Y LAS BOLAS NUNCA PARAN.
	##
	## Con física a secas las bolas se asientan en el fondo en segundo y medio y
	## a partir de ahí la escena se congela: se veía un montón quieto dentro de
	## un cristal, que es justo lo contrario de un sorteo. La solución no es
	## animarlas -volvería a repetir- sino no dejar que el sistema llegue al
	## reposo: el cuenco gira despacio y cada pocas décimas cae un empujón suave.
	## Siguen siendo física de verdad, solo que nunca se duerme.
	if _bombo != null:
		_bombo.rotation.y += delta * 0.5
	_agitacion -= delta
	if _agitacion <= 0.0:
		_agitacion = 0.28
		for b in _bolas:
			if not b.freeze:
				b.apply_central_impulse(Vector3(
					randf_range(-0.02, 0.02), randf_range(0.012, 0.05), randf_range(-0.02, 0.02)))
				## Un poco de giro propio: sin esto ruedan como canicas y no se
				## aprecia el dibujo del balón.
				b.apply_torque_impulse(Vector3(
					randf_range(-0.004, 0.004), randf_range(-0.004, 0.004), randf_range(-0.004, 0.004)))

## Agita el bombo: un empujón a cada bola, como hace el que dirige el sorteo.
func agitar() -> void:
	for b in _bolas:
		if not b.freeze:
			b.apply_central_impulse(Vector3(
				randf_range(-0.09, 0.09), randf_range(0.05, 0.20), randf_range(-0.09, 0.09)))

## Saca una bola: se congela y esconde una de las de dentro, y la bola "de
## fuera" sube girando hasta la altura de la cámara.
func sacar_bola() -> Tween:
	for b in _bolas:
		if not b.freeze:
			b.freeze = true
			b.visible = false
			break
	_bola_fuera.visible = true
	_bola_fuera.position = _bombo.position + Vector3(0, -0.2, 0)
	_bola_fuera.scale = Vector3.ONE
	_bola_fuera.rotation = Vector3.ZERO
	_escudo_placa.visible = false
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_bola_fuera, "position", Vector3(0, 1.62, 1.15), 0.85) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_bola_fuera, "rotation", Vector3(TAU * 1.5, TAU * 2.0, 0), 0.85)
	t.tween_property(_bola_fuera, "scale", Vector3.ONE * 1.9, 0.85) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t

## La bola se abre y aparece el escudo. La bola se encoge mientras el escudo
## crece: leído como una sola cosa, parece que sale de dentro.
func revelar(escudo: Texture2D) -> Tween:
	var pm := _escudo_placa.material_override as StandardMaterial3D
	pm.albedo_texture = escudo
	pm.emission_texture = escudo
	_escudo_placa.position = _bola_fuera.position
	_escudo_placa.scale = Vector3.ONE * 0.2
	_escudo_placa.visible = true
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_bola_fuera, "scale", Vector3.ONE * 0.05, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(_escudo_placa, "scale", Vector3.ONE, 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t

## Confeti. SOLO cuando sale tu club: si cayera en cada bola dejaría de
## significar nada.
func celebrar() -> void:
	_confeti.restart()
	_confeti.emitting = true
