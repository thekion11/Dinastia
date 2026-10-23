extends "res://ui/rueda_prensa_escena3d_p1.gd"
## [Capa 2/3 de `rueda_prensa_escena3d.gd`] _mallas_de, _montar_podio_generado, _montar_podio_procedural, _montar_ocultador_podio, _montar_podio, _montar_dt_generico … (+8)

func _mallas_de(n: Node) -> Array[MeshInstance3D]:
	var salida: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		salida.append(n)
	for h in n.get_children():
		salida.append_array(_mallas_de(h))
	return salida

func _montar_podio_generado() -> bool:
	if not ResourceLoader.exists(RUTA_PODIO_IA):
		return false
	var esc := load(RUTA_PODIO_IA)
	var n := (esc as PackedScene).instantiate() if esc is PackedScene else null
	if n == null:
		return false
	var mallas := _mallas_de(n)
	## COMPROBAR QUE DE VERDAD HAY ALGO QUE PINTAR -misma regla que ya dejó
	## escrita `Sorteo._montar_presentador_modelo()`: un `load()` que no da
	## null no significa que haya una malla visible dentro.
	if mallas.is_empty():
		n.queue_free()
		return false

	var raiz := Node3D.new()
	add_child(raiz)
	raiz.add_child(n)

	## LA ESCALA Y LA POSICIÓN SE MIDEN, NO SE ADIVINAN -mismo motivo que ya
	## dejó escrito Sorteo: cada exportador usa las unidades que le da la
	## gana-. 1,1 m es la altura a la que el modelo se ve proporcionado de
	## verdad -comprobado con capturas de cuatro ángulos-; el ocultador de
	## atrás es quien se encarga de la altura de oclusión, así que aquí ya no
	## hace falta forzar el número para que "tape bien".
	var caja := AABB()
	var primero := true
	for m in mallas:
		var a: AABB = m.mesh.get_aabb() if m.mesh != null else AABB()
		a = m.transform * a
		if primero:
			caja = a
			primero = false
		else:
			caja = caja.merge(a)
	var alto := caja.size.y
	var escala := (1.1 / alto) if alto > 0.001 else 1.0
	raiz.scale = Vector3.ONE * escala
	var centro := (caja.position + caja.size * 0.5) * escala
	var pie_y := caja.position.y * escala
	raiz.position = Vector3(-centro.x, -pie_y, -0.1 - centro.z)

	for m in mallas:
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.albedo_color = TINTE_PODIO
		mat.roughness = 0.7
		m.material_override = mat
	return true

## EL PODIO PROCEDURAL DE RESPALDO. Si el fichero generado no está -por
## ejemplo, en una máquina donde nunca se copió el asset-, la escena sigue
## funcionando con cajas simples en vez de romperse o quedar sin podio.
func _montar_podio_procedural() -> void:
	var met := StandardMaterial3D.new()
	met.albedo_color = Color(0.14, 0.15, 0.17)
	met.metallic = 0.35
	met.roughness = 0.4

	## El cuerpo: una caja recta y, encima, un panel inclinado -el mismo gesto
	## de la foto de referencia (el frente en cuña, no un cubo liso)-.
	var cuerpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 1.05, 0.55)
	cuerpo.mesh = bm
	cuerpo.material_override = met
	cuerpo.position = Vector3(0, 0.525, -0.1)
	add_child(cuerpo)

	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.94, 0.06, 0.6)
	panel.mesh = pm
	panel.material_override = met
	panel.position = Vector3(0, 1.06, -0.08)
	panel.rotation_degrees.x = -8.0
	add_child(panel)

	## Los dos micrófonos de cuello de ganso: mismo par cápsula+cilindro que el
	## brazo del presentador del sorteo, aquí quietos.
	var mic_mat := StandardMaterial3D.new()
	mic_mat.albedo_color = Color(0.05, 0.05, 0.06)
	mic_mat.metallic = 0.2
	mic_mat.roughness = 0.5
	for lado in [-1.0, 1.0]:
		var base_pos := Vector3(lado * 0.22, 1.1, -0.05)
		var cuello := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.012
		cm.bottom_radius = 0.014
		cm.height = 0.32
		cuello.mesh = cm
		cuello.material_override = mic_mat
		cuello.position = base_pos + Vector3(0, 0.16, 0)
		cuello.rotation_degrees.x = -22.0 * lado * 0.4
		add_child(cuello)
		var capsula := MeshInstance3D.new()
		var capm := CapsuleMesh.new()
		capm.radius = 0.028
		capm.height = 0.1
		capsula.mesh = capm
		capsula.material_override = mic_mat
		capsula.rotation_degrees.z = 90.0
		capsula.position = base_pos + Vector3(0.05 * lado, 0.32, 0)
		add_child(capsula)

## La caja lisa detrás del modelo generado. Mismas medidas que tenía el
## podio procedural completo -ya probadas y correctas-, pero sin los
## micrófonos: esos ya los aporta el modelo generado, y duplicarlos se vería
## raro (cuatro brazos de micrófono en vez de dos).
func _montar_ocultador_podio() -> void:
	var met := StandardMaterial3D.new()
	met.albedo_color = TINTE_PODIO.darkened(0.15)
	met.metallic = 0.2
	met.roughness = 0.6
	## MÁS BAJA A PROPÓSITO -0,75 m, no 1,05-: si el ocultador llega tan alto
	## como el podio procedural completo, se traga la mesa y los micrófonos
	## del modelo generado -que a 1,1 m de alto tienen la mesa a media altura,
	## no al tope-, y solo asoman las puntas. Dejándolo más bajo, la mesa y
	## los micrófonos del modelo generado quedan POR ENCIMA del ocultador,
	## visibles de verdad, y el DT solo asoma del pecho para arriba.
	var cuerpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.86, 0.75, 0.5)
	cuerpo.mesh = bm
	cuerpo.material_override = met
	cuerpo.position = Vector3(0, 0.375, -0.12)
	add_child(cuerpo)

func _montar_podio() -> void:
	## Con el personaje 3D, el podio procedural completo (a la altura del pecho):
	## el generado con su caja oscura dejaba una franja negra en la cintura.
	var uso_generado := USAR_PODIO_IA and PersonajeDT.del_usuario.is_empty() and _montar_podio_generado()
	## El ocultador SIEMPRE se monta -tanto si el modelo generado cargó como
	## si no-: es lo único de lo que depende que el DT quede bien tapado, así
	## que no puede fallar en silencio si el asset generado no está.
	if not uso_generado:
		## Sin el modelo generado, el ocultador no hace falta -el podio
		## procedural completo ya se tapa a sí mismo-.
		_montar_podio_procedural()
	else:
		_montar_ocultador_podio()

# ---------------------------------------------------------------------------
#  EL DT, DE PECHO PARA ARRIBA
# ---------------------------------------------------------------------------

## AZUL MARINO VISIBLE, NO NEGRO PURO. La primera versión usaba un traje casi
## negro (0.11,0.12,0.17) contra un fondo casi negro (0.05,0.05,0.06): por
## bien iluminado que estuviera, el contraste de color era tan bajo que el DT
## se leía como una mancha sin forma. Mismo problema, mismo arreglo, que ya se
## documentó para el presentador del sorteo -"el negro puro contra un plató
## oscuro se come la silueta"-. Se mantiene como RESPALDO genérico si no hay
## `look_dt` -por ejemplo, una prueba vieja que llama a `montar()` sin el
## parámetro nuevo-.
func _montar_dt_generico() -> void:
	var traje := StandardMaterial3D.new()
	traje.albedo_color = Color(0.16, 0.19, 0.30)
	traje.roughness = 0.75
	var piel := StandardMaterial3D.new()
	piel.albedo_color = Color(0.56, 0.44, 0.36)
	piel.roughness = 0.65

	var torso := MeshInstance3D.new()
	var tm := CapsuleMesh.new()
	tm.radius = 0.22
	tm.height = 1.05
	torso.mesh = tm
	torso.material_override = traje
	torso.position = Vector3(0, 0.95, -0.5)
	add_child(torso)

	_dt_cabeza = MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.15
	cm.height = 0.3
	_dt_cabeza.mesh = cm
	_dt_cabeza.material_override = piel
	_dt_cabeza.position = Vector3(0, 1.68, -0.5)
	add_child(_dt_cabeza)

	var corbata := MeshInstance3D.new()
	var com := BoxMesh.new()
	com.size = Vector3(0.06, 0.32, 0.02)
	corbata.mesh = com
	var cor_mat := StandardMaterial3D.new()
	cor_mat.albedo_color = Color(0.55, 0.12, 0.14)
	cor_mat.roughness = 0.6
	corbata.material_override = cor_mat
	corbata.position = Vector3(0, 1.28, -0.24)
	add_child(corbata)

## EL DT CON SU CARA DE VERDAD (14-9-2026). Hasta hoy era una cápsula lisa con
## una esfera de "piel" encima -ni rasgos, ni corte de pelo, ni el traje que el
## jugador eligió en Mi Carrera-. `CaraDT.textura()` YA dibuja ese retrato
## completo -cara con los rasgos elegidos, corte de pelo, traje y corbata,
## viewBox cuadrado de hombros para arriba- porque es EL MISMO SVG que ya se
## usa en la pantalla de Mi Carrera; no hace falta un sistema de UV-mapping
## sobre geometría 3D -eso sigue pausado a propósito, ver ROADMAP fase 5- para
## que el jugador se vea a sí mismo en su propia rueda de prensa: basta con
## mostrar ese mismo retrato en un plano dentro de la escena.
func _montar_dt(look_dt: Dictionary) -> void:
	if look_dt.is_empty():
		_montar_dt_generico()
		return
	var tex := CaraDT.textura(look_dt, 256)
	if tex == null:
		_montar_dt_generico()
		return
	var quad := MeshInstance3D.new()
	var q := QuadMesh.new()
	## El SVG es cuadrado (64x64, hombros hasta arriba de la cabeza): 0,95 m de
	## lado da unos hombros de ancho creíble sin devorar la pared de sponsors,
	## del mismo orden que medía la cápsula genérica que reemplaza.
	q.size = Vector2(0.95, 0.95)
	quad.mesh = q
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	## UNSHADED + emission, igual que la pared de sponsors: el retrato ya trae
	## su propio sombreado pintado en el SVG, así que depender de las luces del
	## plató solo lo oscurecía sin aportar nada.
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission_energy_multiplier = 0.9
	## El fondo de tarjeta del SVG (`rect opacity=".3"`) se traduce en alpha
	## parcial, no en un rectángulo sólido detrás de la figura.
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad.material_override = mat
	## Centrado en la misma altura que ocupaba el conjunto torso+cabeza
	## genérico (de ~0,4 a ~1,83 m): el quad de 0,95 m centrado en Y=1.12 va de
	## 0,645 a 1,595, tapado por abajo por el podio igual que antes.
	quad.position = Vector3(0, 1.12, -0.5)
	add_child(quad)
	_dt_quad = quad

## Una cápsula que va exactamente de `desde` a `hasta`. `Quaternion(from, to)`
## da la rotación de arco más corto que lleva un eje a otro -aquí, del +Y por
## defecto de `CapsuleMesh` a la dirección real del brazo-, así que no hace
## falta descomponer en ángulos de Euler ni arriesgarse a un signo cambiado.
func _segmento(desde: Vector3, hasta: Vector3, radio: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = radio
	cm.height = maxf(desde.distance_to(hasta), radio * 2.1)
	mi.mesh = cm
	mi.material_override = mat
	var medio := (desde + hasta) * 0.5
	var dir := (hasta - desde).normalized()
	mi.transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)), medio)
	return mi

## LAS MANOS APOYADAS EN EL PODIO (14-9-2026, pedido explícito tras el gesto
## del sorteo: "invierte en eso"). Un DT que nunca gesticula ni apoya las
## manos se lee como una foto pegada en cuanto la cámara se aleja del plano de
## trabajo -el retrato de `_montar_dt()` es un plano 2D fijo-. Un brazo por
## lado, cada uno UN SOLO TRAMO recto desde el hombro hasta la mano, sin codo
## intermedio: depurar el gesto del presentador del sorteo esta misma sesión
## costó horas por un codo que, visto desde cierto plano de cámara, se
## alineaba con la vista y el brazo se leía como una línea estirada -mismo
## hueso, misma pose, solo cambiaba el ángulo-. Un tramo único no tiene ese
## riesgo desde ningún ángulo, y a la distancia y el tamaño con que se ve un
## DT de pecho para arriba no se nota la falta del codo.
func _montar_gesto_dt(look_dt: Dictionary) -> void:
	var piel_mat := StandardMaterial3D.new()
	piel_mat.albedo_color = Color(String(look_dt.get("piel", "#c68863")))
	piel_mat.roughness = 0.7
	var manga := StandardMaterial3D.new()
	## Azul marino fijo, no el traje que eligió `CaraDT`: la manga casi no se
	## ve -la tapan el propio brazo y el borde del podio-, así que no vale la
	## pena acoplarse a qué traje salió sorteado para acertar el tono exacto.
	manga.albedo_color = Color(0.15, 0.17, 0.26)
	manga.roughness = 0.8
	_dt_brazos.clear()
	for lado in [-1.0, 1.0]:
		## RE-MEDIDO UNA SEGUNDA VEZ mirando la captura con calibración real
		## (proyectando `Vector3(0,y,-0.5)` a píxeles): el borde del podio que
		## de verdad tapa al DT en esta escena no está a 1,05 m -la altura del
		## `cuerpo` procedural completo-, sino a los 0,75 m del ocultador que
		## se monta CON el podio generado por IA (`USAR_PODIO_IA := true`, el
		## camino que corre de verdad aquí). Con eso, el hueco visible entre
		## el borde del podio y la barbilla es minúsculo -pura cuestión de
		## cuánto torso deja ver este plano tan cerrado-: un brazo en
		## DIAGONAL desde un "hombro" alto no cabe sin pegarse a la cara. Lo
		## que sí cabe, y es más real de todos modos -un antebrazo apoyado en
		## una mesa queda plano sobre ella, no en diagonal desde el hombro- es
		## un tramo casi HORIZONTAL a la altura de la propia mesa (0,85 m,
		## justo por encima del ocultador) que va desde cerca del cuerpo hasta
		## el borde delantero.
		var hombro := Vector3(lado * 0.2, 0.85, -0.35)
		var mano_pos := Vector3(lado * 0.23, 0.85, -0.05)
		var brazo := Node3D.new()
		add_child(brazo)
		brazo.add_child(_segmento(hombro, mano_pos, 0.045, manga))
		var mano := MeshInstance3D.new()
		var mm := SphereMesh.new()
		mm.radius = 0.048
		mm.height = 0.096
		mano.mesh = mm
		mano.material_override = piel_mat
		mano.position = mano_pos
		brazo.add_child(mano)
		_dt_brazos.append(brazo)

# ---------------------------------------------------------------------------
#  CÁMARA
# ---------------------------------------------------------------------------

func _montar_camara() -> void:
	_camara = Camera3D.new()
	_camara.fov = 34.0
	add_child(_camara)
	_cam_pos = CAM_POS
	_cam_mira = CAM_MIRA
	## `look_at_from_position()` y no `position=` + `look_at()`: en el momento
	## en que `montar()` corre, esta escena todavía puede no estar dentro del
	## árbol -`_abrir_rueda_pantalla_completa()` arma el `SubViewport` entero
	## antes de colgarlo del popup-, y `look_at()` a secas exige un transform
	## global válido, que
	## solo existe una vez dentro del árbol. `look_at_from_position()` calcula
	## la orientación sin depender de eso.
	_camara.look_at_from_position(_cam_pos, _cam_mira, Vector3.UP)
	var at := CameraAttributesPractical.new()
	at.dof_blur_far_enabled = true
	at.dof_blur_far_distance = 3.2
	at.dof_blur_far_transition = 1.8
	at.dof_blur_amount = 0.05
	_camara.attributes = at

## `look_dt`: el aspecto de quien habla de verdad (`Roles.look_efectivo()` si el
## jugador es el DT, o `CaraDT.look_de_nombre()` del empleado si no). Vacío ->
## geometría genérica de siempre (compatibilidad hacia atrás).
## `clubes_competencia`: los clubes de tu liga -la pared de sponsors ahora
## muestra SUS escudos, como una pared de prensa real de un torneo, en vez de
## marcas genéricas. Vacío -> las marcas de siempre (compatibilidad hacia atrás).
func montar(club: Club, acento: Color, nivel: int = Calidad.ALTO, look_dt: Dictionary = {},
		clubes_competencia: Array = []) -> void:
	var we := Calidad.entorno(nivel, Calidad.NOCHE)
	add_child(we)
	var env := we.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.72, 0.78)
	env.ambient_light_energy = 0.85
	## Bloom suave: los focos de sala tienen que quemar un poco, o el plató se
	## ve plano y de oficina en vez de televisado.
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.15
	env.glow_hdr_threshold = 1.1
	env.tonemap_exposure = 1.0
	env.volumetric_fog_enabled = false

	_montar_suelo()
	_montar_sala()
	_montar_periodistas()
	_montar_fondo_sponsors(club, acento, clubes_competencia)
	_montar_banderas(club)
	_montar_luces()
	_montar_podio()
	## TU PERSONAJE 3D en el atril (13-10-2026), si lo creaste: se monta al
	## entrar en el árbol (medir los huesos lo necesita). Si no, el retrato.
	if not PersonajeDT.del_usuario.is_empty():
		_dt_3d_pendiente = true
	else:
		_montar_dt(look_dt)
		_montar_gesto_dt(look_dt)
	_montar_camara()

## Corta a otro plano -mismo patrón que `SorteoEscena3D.cortar_plano()`-.
## Se llama sola por tiempo (ver `_process()`); no depende de que
## `principal.gd` avise de cada pregunta nueva, así que funciona igual
## aunque el jugador tarde en elegir una respuesta.
func _cortar_plano() -> void:
	_plano = (_plano + 1) % PLANOS.size()

func _montar_dt_3d() -> void:
	_dt_3d_pendiente = false
	var raiz := Node3D.new()
	raiz.position = Vector3(0, 0.0, -0.78)
	add_child(raiz)
	_dt_3d = PersonajeDT.crear(raiz, PersonajeDT.del_usuario)
	if _dt_3d.is_empty():
		raiz.queue_free()
		_montar_dt({})
		return
	Expresion.de(raiz)

## Cada pocos segundos un gesto de manos y una cara, como quien contesta.
func _gesticular_dt(delta: float) -> void:
	if _dt_3d.is_empty():
		return
	_t_gesto_dt -= delta
	if _t_gesto_dt > 0.0:
		return
	_t_gesto_dt = _rng_dt.randf_range(3.5, 6.5)
	var ap: AnimationPlayer = _dt_3d.get("anim")
	var gesto: String = GESTOS_PRENSA[_rng_dt.randi() % GESTOS_PRENSA.size()]
	if ap != null:
		var lib := ap.get_animation_library("")
		if lib != null and not lib.has_animation(gesto) and AnimExtra.UAL.has(gesto):
			var esq: Skeleton3D = _dt_3d.get("esqueleto")
			var clip: Animation = AnimQuaternius.cargar_real(String(AnimExtra.UAL[gesto]), str(ap.get_path_to(esq)))
			if clip != null:
				lib.add_animation(gesto, clip)
		if ap.has_animation(gesto):
			ap.play(gesto, 0.3)
			ap.queue("parado")
	var raiz: Node = (_dt_3d["nodo"] as Node).get_parent()
	Expresion.de(raiz).poner(["concentrado", "alegre", "neutral", "enfado"][_rng_dt.randi() % 4], 3.0)
