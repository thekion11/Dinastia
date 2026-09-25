class_name SorteoEscena3D
extends Node3D
## El plató del sorteo, en 3D de verdad.
##
## No es una imagen con brillos: es una escena Forward+ (Vulkan) con bombo de
## cristal, bolas con FÍSICA que se apelotonan y ruedan solas, focos de estudio
## con volumen, suelo reflectante y cámara con profundidad de campo. El proyecto
## ya estaba en Forward+ por el estadio 3D, así que aquí no hubo que cambiar el
## método de render -que es de proyecto, no de escena-: solo aprovecharlo.
##
## POR QUÉ FÍSICA Y NO UNA ANIMACIÓN. Una animación de bolas dando vueltas se
## nota falsa a la segunda vez que la ves, porque repite igual. Con `RigidBody3D`
## cada sorteo se apelotona distinto, las bolas se empujan entre ellas y ruedan
## hasta parar. Es la misma razón por la que el partido se simula en vez de
## guionizarse.
##
## EL BOMBO NO LLEVA COLISIONADOR CÓNCAVO. Una malla cóncava para un cuenco sale
## cara y deja colarse cuerpos pequeños. En su lugar hay un anillo de cajas
## inclinadas hacia dentro más un disco de suelo: converge igual, cuesta una
## fracción y ninguna bola se escapa.

## Cuántas bolas hay dentro. Más de veinte y en la Intel UHD de esta máquina la
## física empieza a costar sin que se note nada en pantalla.
const BOLAS_MAX := 46
const RADIO_BOMBO := 0.78
const RADIO_BOLA := 0.072

var _camara: Camera3D
var _bombo: Node3D
var _bolas: Array[RigidBody3D] = []
var _bola_fuera: MeshInstance3D
var _escudo_placa: MeshInstance3D
var _confeti: GPUParticles3D
var _focos: Array[SpotLight3D] = []
var _acento := Color("f5c518")
var _t := 0.0
## Cuenta atrás para el siguiente empujón a las bolas. Ver `_process()`.
var _agitacion := 0.0

## Los planos de cámara. Ver la nota en `_process()`: se corta entre ellos en
## cada bola, que es lo que hace que la escena se lea como una retransmisión y
## no como un salvapantallas girando.
const PLANOS := [
	## General de sala: se ve el escenario, el público y la pantalla. Es el plano
	## con el que se abre y al que se vuelve para respirar.
	{"pos": Vector3(0.0, 2.35, 5.6), "mira": Vector3(0.0, 1.7, -1.2)},
	## Medio del bombo, ligeramente lateral: el plano de trabajo.
	{"pos": Vector3(-1.5, 1.85, 3.0), "mira": Vector3(0.1, 1.45, -0.6)},
	## Contrapicado desde el otro lado, con el presentador en primer término.
	## POR QUÉ ESTE ÁNGULO Y NO OTRO (14-9-2026): con el humanoide real, un
	## ángulo demasiado lateral respecto a hacia dónde mira el presentador
	## (gira -32° en `_montar_presentador_modelo()`) alinea el codo con la
	## cámara y el brazo -doblado de verdad, con el codo hacia el hombro y el
	## antebrazo colgando- se ve proyectado como una sola línea recta
	## "estirada", aunque el hueso esté perfectamente posado (comprobado con
	## `pruebas/captura_parado_aislado.gd`: mismos ángulos de hueso, un plano se
	## ve normal y el otro no). Casi de frente a hacia dónde mira -menos de
	## unos 35-40° de diferencia entre cámara y giro del cuerpo- el codo deja
	## de alinearse con el eje de vista y el brazo se lee doblado, no recto.
	{"pos": Vector3(0.5, 1.62, 2.5), "mira": Vector3(0.85, 1.3, -0.4)},
	## Cerrado de la pantalla gigante: el plano del anuncio.
	{"pos": Vector3(0.3, 2.9, 1.4), "mira": Vector3(0.0, 3.2, -6.0)},
]
var _plano := 0
var _mezcla_plano := 1.0
var _cam_pos := Vector3(0.0, 2.35, 5.6)
var _cam_mira := Vector3(0.0, 1.7, -1.2)

## Cambia de plano. La lleva `Sorteo` en cada bola.
func cortar_plano(indice: int = -1) -> void:
	_plano = (randi() % PLANOS.size()) if indice < 0 else (indice % PLANOS.size())
	_mezcla_plano = 0.0

# ---------------------------------------------------------------------------
#  LA TEXTURA DEL BALÓN
# ---------------------------------------------------------------------------
#
# NO SE PUEDE USAR EL SVG PLANO DE `Sorteo._textura_bola()`. Ese dibujo es un
# círculo visto de frente; envuelto en una esfera, la proyección equirectangular
# lo estira sin piedad y los pentágonos salen como manchas derretidas hacia los
# polos. En la primera captura las bolas parecían palomitas.
#
# La forma correcta es generar la textura EN EL ESPACIO DE LA ESFERA: para cada
# téxel se calcula la dirección 3D a la que corresponde y se mira su ángulo
# contra los doce vértices de un icosaedro, que son exactamente los centros de
# los doce pentágonos negros de un balón clásico. Así los parches salen redondos
# desde cualquier ángulo, porque se han definido sobre la esfera y no sobre un
# papel.

const TEX_ANCHO := 512
const TEX_ALTO := 256
static var _tex_balon: Texture2D = null

## Los doce vértices de un icosaedro normalizados. Salen de las tres "tarjetas
## áureas" perpendiculares: (0, ±1, ±φ) y sus rotaciones cíclicas.
static func _vertices_icosaedro() -> Array[Vector3]:
	var phi := (1.0 + sqrt(5.0)) / 2.0
	var v: Array[Vector3] = []
	for a in [-1.0, 1.0]:
		for b in [-phi, phi]:
			v.append(Vector3(0, a, b).normalized())
			v.append(Vector3(a, b, 0).normalized())
			v.append(Vector3(b, 0, a).normalized())
	return v

static func textura_balon() -> Texture2D:
	if _tex_balon != null:
		return _tex_balon
	var vs := _vertices_icosaedro()
	var img := Image.create(TEX_ANCHO, TEX_ALTO, false, Image.FORMAT_RGB8)
	## El ángulo del parche: 0,45 rad deja los pentágonos separados por costuras
	## blancas de grosor creíble. Más y se tocan; menos y parecen lunares.
	var umbral := 0.45
	var borde := 0.035
	for y in TEX_ALTO:
		## v va de 0 (polo norte) a 1 (polo sur): latitud de π/2 a -π/2.
		var lat := PI * (0.5 - float(y) / float(TEX_ALTO - 1))
		var cl := cos(lat)
		var sl := sin(lat)
		for x in TEX_ANCHO:
			var lon := TAU * float(x) / float(TEX_ANCHO - 1)
			var dir := Vector3(cl * cos(lon), sl, cl * sin(lon))
			var mejor := 9.0
			for vv in vs:
				var ang := acos(clampf(dir.dot(vv), -1.0, 1.0))
				if ang < mejor:
					mejor = ang
			var c: Color
			if mejor < umbral - borde:
				c = Color(0.09, 0.10, 0.12)
			elif mejor < umbral:
				## Antialias del borde: sin esto las costuras salen dentadas y se
				## nota muchísimo cuando la bola gira.
				var t := (mejor - (umbral - borde)) / borde
				c = Color(0.09, 0.10, 0.12).lerp(Color(0.96, 0.96, 0.94), t)
			else:
				## El blanco no es plano: un gradiente muy suave hacia las
				## costuras da la sensación de cuero cosido en vez de plástico.
				var s := clampf((mejor - umbral) / 0.35, 0.0, 1.0)
				c = Color(0.88, 0.88, 0.86).lerp(Color(0.99, 0.99, 0.97), s)
			img.set_pixel(x, y, c)
	_tex_balon = ImageTexture.create_from_image(img)
	return _tex_balon

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
	env.ambient_light_color = fondo.lightened(0.1)
	env.ambient_light_energy = 0.85
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
func _montar_sala(fondo: Color) -> void:
	var oscuro := StandardMaterial3D.new()
	oscuro.albedo_color = fondo.darkened(0.72)
	oscuro.roughness = 0.75

	## LA TARIMA. Elevada 42 cm sobre el patio de butacas, que es lo que hace que
	## se lea como escenario y no como suelo. El bombo se apoya encima.
	var deck := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(13.0, 0.42, 7.0)
	deck.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = fondo.darkened(0.62)
	dmat.metallic = 0.45
	dmat.roughness = 0.3
	deck.material_override = dmat
	deck.position = Vector3(0, 0.21, -1.6)
	add_child(deck)
	## El canto luminoso del borde: en toda gala la tarima lleva una tira de LED
	## que la dibuja contra la oscuridad del patio.
	var canto := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(13.0, 0.05, 0.06)
	canto.mesh = cm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = _acento
	cmat.emission_enabled = true
	cmat.emission = _acento
	cmat.emission_energy_multiplier = 2.2
	canto.material_override = cmat
	canto.position = Vector3(0, 0.40, 1.9)
	add_child(canto)

	## LAS PAREDES LATERALES, giradas hacia dentro. Cierran el encuadre por los
	## lados: sin ellas la vista se escapa a negro y la sala no tiene tamaño.
	for lado in [-1.0, 1.0]:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.25, 6.5, 9.0)
		m.mesh = bm
		m.material_override = oscuro
		m.position = Vector3(lado * 7.2, 3.2, -1.5)
		m.rotation.y = deg_to_rad(-lado * 9.0)
		add_child(m)

	## EL TECHO Y EL TRUSS. Las barras negras cruzadas de las que cuelgan los
	## focos. Es el detalle que más dice "esto es un recinto" con menos gasto.
	var techo := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(15.0, 0.3, 12.0)
	techo.mesh = tm
	techo.material_override = oscuro
	techo.position = Vector3(0, 6.3, -0.5)
	add_child(techo)
	var barra := StandardMaterial3D.new()
	barra.albedo_color = Color(0.13, 0.14, 0.16)
	barra.metallic = 0.7
	barra.roughness = 0.45
	for i in 4:
		var t := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(13.0, 0.14, 0.14)
		t.mesh = bm2
		t.material_override = barra
		t.position = Vector3(0, 5.85, -3.2 + float(i) * 1.6)
		add_child(t)
		## Los cuerpos de foco colgados del truss, apagados salvo el central.
		for j in 7:
			var foco := MeshInstance3D.new()
			var fm := CylinderMesh.new()
			fm.top_radius = 0.11
			fm.bottom_radius = 0.15
			fm.height = 0.34
			foco.mesh = fm
			foco.material_override = barra
			foco.position = Vector3(-4.5 + float(j) * 1.5, 5.62, -3.2 + float(i) * 1.6)
			foco.rotation.x = deg_to_rad(28.0)
			add_child(foco)

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

# --- decorado ----------------------------------------------------------------

## El suelo: negro y PULIDO, para que refleje el bombo y las luces. El reflejo es
## lo que separa un plató de una caja negra con cosas dentro.
func _montar_suelo(fondo: Color) -> void:
	var m := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(40, 40)
	m.mesh = plano
	var mat := StandardMaterial3D.new()
	mat.albedo_color = fondo.darkened(0.8)
	mat.metallic = 0.85
	mat.roughness = 0.12
	mat.metallic_specular = 0.9
	m.material_override = mat
	m.position.y = -0.02
	add_child(m)

# ---------------------------------------------------------------------------
#  LA PANTALLA GIGANTE Y EL PRESENTADOR
# ---------------------------------------------------------------------------

## LA PANTALLA DEL FONDO. En un sorteo de verdad la pared no es decorado: es
## donde aparece el club que acaba de salir, en grande, para que lo vea la sala.
## Sin ella la cinemática no CUENTA nada — el bombo se agita y hay que fiarse de
## un rótulo pequeño abajo.
##
## Se hace con un `SubViewport` que contiene interfaz 2D normal -escudo, nombre,
## grupo- y su `ViewportTexture` se pega como emisión a un plano. Es la única
## forma de tener TEXTO NÍTIDO dentro de una escena 3D: una malla con letras se
## ve borrosa en cuanto la cámara se mueve, y el rasterizador de SVG de este
## proyecto ni siquiera dibuja `<text>`.
var _pantalla_vp: SubViewport
var _pantalla_escudo: TextureRect
var _pantalla_nombre: Label
var _pantalla_grupo: Label

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

## EL PRESENTADOR (reescrito 14-9-2026, pedido explícito: "estéticamente deja
## qué desear el presentador y la animación"). Ya no es una silueta de cajas:
## es el MISMO modelo humano realista que usan los 22 del campo
## (`Futbolista`/`AnimMixamo`, `visor/player_spawner.gd`), vestido de traje
## liso con `Vestidor` -el mismo mecanismo que ya viste al árbitro sin
## equipación de club-, con una animación real de pie (`parado`, la que hace
## que respire y reparta el peso) y el gesto de sacar la bola resuelto con
## `mostrar_tarjeta` -la misma animación del árbitro levantando la tarjeta en
## alto sirve tal cual para "levantar la bola y mostrarla"-.
var _brazo: Node3D
var _mano: MeshInstance3D
## El AnimationPlayer del modelo real, si se pudo montar. Null -> se usa el
## brazo suelto de respaldo (silueta), que sigue funcionando igual que antes.
var _anim_presentador: AnimationPlayer

# ---------------------------------------------------------------------------
#  EL TRAJE DEL PRESENTADOR
# ---------------------------------------------------------------------------
#
# El usuario pidió "usar el vagabundo que tenemos en recursos y ponerle un
# traje". El "Vagabond" de `sorpresa/` NO es una persona: es un VELERO —sus
# grupos son casco, quilla, mástil, velas, timón y cabina—. El nombre engaña.
#
# El atlas `skaterMaleA.png` + `characterMedium.fbx` (repintar rectángulos de
# torso/piernas/zapatos a mano) fue el primer intento y quedó descartado: el
# humanoide real de 22-del-campo (`futbolista_cr7.glb` vía `Futbolista.gd`) ya
# resuelve esto mejor -reusa el mismo esqueleto puesto en pose, la misma
## escala medida y el mismo `Vestidor.vestir()` con `color_liso` que ya viste
# a árbitros y jueces de línea sin equipación de club-.

## SI SE USA EL HUMANOIDE REAL O LA SILUETA DE RESPALDO.
##
## `Futbolista.crear()`/`terminar()` -la MISMA fábrica que usa
## `player_spawner.gd` para los 22 del campo- resuelve exactamente el problema
## que dejó esto apagado hasta hoy: el modelo humano con esqueleto Mixamo
## necesitaba enderezarse, escalarse y montar su `AnimationPlayer` a mano, y
## ese trabajo YA está hecho y probado ahí -no hay que repetirlo aquí ni
## instanciar el `.glb` a pelo-.
const USAR_MODELO_HUMANO := true

func _montar_presentador() -> void:
	if USAR_MODELO_HUMANO and _montar_presentador_modelo():
		return
	_montar_presentador_siluetas()

## EL PRESENTADOR ES EL MODELO QUATERNIUS (CC0), no `futbolista_cr7.glb`
## (25-9-2026). Aquel trae de fábrica la camiseta real del Al-Nassr -escudo y
## patrocinador incluidos- y no tiene licencia conocida, así que no viaja en
## ninguna versión publicada (ver `LICENCIAS.md`). Es el mismo cuerpo que ya
## usan los 22 del campo, con "parado" y "mostrar_tarjeta" en su catálogo. El
## modelo viejo queda solo como respaldo de desarrollo.
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
	if _montar_presentador_quaternius():
		return true
	var d := Futbolista.crear(1.78)
	if d.is_empty():
		return false
	var raiz: Node3D = d["nodo"]
	## Misma posición y orientación que ya tenía calibradas la silueta: en el
	## hueco entre valla y tribuna... no, aquí es la tarima (Y=0,42, la cara
	## superior de `deck` en `_montar_sala()`), un paso detrás del bombo.
	raiz.position = Vector3(1.15, 0.42, -0.35)
	raiz.rotation.y = deg_to_rad(-32.0)
	add_child(raiz)
	## `terminar()` necesita el nodo YA dentro del árbol -endereza, escala a la
	## altura pedida y monta el catálogo de animaciones Mixamo en el
	## `AnimationPlayer`, todo medido, no adivinado (ver los comentarios de
	## `Futbolista.gd`, trampas ya pagadas ahí).
	Futbolista.terminar(d)
	## TRAJE LISO, no equipación de club: mismo mecanismo que ya viste al
	## árbitro y a los jueces de línea (`Vestidor.vestir()` con `color_liso`).
	## Azul marino oscuro, el mismo tono que ya usaba la silueta -contra un
	## plató oscuro un traje negro puro se come la figura-.
	var modelo: Node3D = d["modelo"]
	Vestidor.vestir(modelo, "", Color(0.52, 0.40, 0.33), Color(0.14, 0.11, 0.09),
		Color(0.12, 0.13, 0.19, 1.0))
	## DE PIE, RESPIRANDO: `parado()` es la animación base de todo el catálogo
	## Mixamo -mece el peso, la cabeza y los brazos en un ciclo de 3,2 s-, la
	## misma que usan los 22 del campo cuando no hay balón cerca. Sin esto el
	## modelo real se quedaba tan tieso como la silueta que reemplaza.
	_anim_presentador = d["anim"]
	if _anim_presentador != null and _anim_presentador.has_animation("parado"):
		_anim_presentador.play("parado")
	return true

func _mallas_de(n: Node) -> Array[MeshInstance3D]:
	var salida: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		salida.append(n)
	for h in n.get_children():
		salida.append_array(_mallas_de(h))
	return salida

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
## `Futbolista.crear()` no puede montar el modelo real (`d.is_empty()`).
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

## El gesto de sacar la bola: el brazo se levanta, entra en el bombo y vuelve.
## Con el modelo real, es la misma animación del árbitro mostrando la tarjeta
## -levantar la mano en alto- y luego vuelve a "parado"; con la silueta de
## respaldo, sigue siendo el Tween del brazo suelto de siempre.
func gesto_sacar() -> Tween:
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

## La pantalla de fondo con paneles LED en el color de la competición. Es lo que
## da la identidad: el mismo sorteo en azul es la Champions y en amarillo la
## Libertadores, sin escribir el nombre en ninguna parte.
func _montar_pared(fondo: Color) -> void:
	var pared := Node3D.new()
	pared.position = Vector3(0, 0, -6.4)
	add_child(pared)
	## LA PARED ANTES ERA RUIDO PURO: cada panel con un brillo al azar sin
	## relación con el de al lado, y en captura se leía como un tablero de
	## ajedrez verde y amarillo, no como una pantalla. Una pared LED de
	## verdad muestra UN gráfico -un degradado, un logo, una animación- que
	## varía suave de panel a panel; el único ruido de una pantalla real es
	## la costura entre módulos, que es un detalle minúsculo, no el 65% de
	## rango que había aquí. Ahora el brillo sale de la DISTANCIA al centro
	## de la pared -un resplandor que se apaga hacia los bordes, como el
	## gráfico de fondo de cualquier plató- y el azar que queda es solo la
	## costura, con un rango diez veces más chico.
	var centro_col := 10.5
	var centro_fila := 6.0
	for fila in 13:
		for col in 22:
			var p := MeshInstance3D.new()
			var caja := BoxMesh.new()
			caja.size = Vector3(0.62, 0.42, 0.06)
			p.mesh = caja
			var mat := StandardMaterial3D.new()
			var dist := Vector2(float(col) - centro_col, float(fila) - centro_fila).length() / 12.0
			var v := clampf(1.0 - dist, 0.1, 1.0)
			## La costura entre módulos: una variación mínima, no el brillo.
			v += (fmod(float(fila * 7 + col * 13) * 0.137, 1.0) - 0.5) * 0.08
			v = clampf(v, 0.08, 1.0)
			## OJO CON LA ENERGÍA. A 1,7 la pared quemaba la escena entera: el
			## bombo se veía en contraluz, los rótulos no se leían y todo salía
			## amarillo. Una pared LED de plató ILUMINA POCO -está lejos y es
			## decorado-, así que va por debajo de 0,4. Se vio en captura, que es
			## la única forma de cazar un problema de exposición.
			mat.albedo_color = fondo.darkened(0.35)
			mat.emission_enabled = true
			mat.emission = _acento.lerp(fondo, 0.7)
			mat.emission_energy_multiplier = v * 0.6
			p.material_override = mat
			p.position = Vector3(-6.6 + float(col) * 0.63, 0.55 + float(fila) * 0.43, 0.0)
			pared.add_child(p)

## Tres focos de estudio y un contraluz. Los focos se mueven en `_process`: un
## plató con las luces quietas parece una foto.
func _montar_luces() -> void:
	for i in 3:
		var f := SpotLight3D.new()
		## La luz PRINCIPAL va blanca. Tiñendo los tres focos con el acento, un
		## sorteo de Libertadores salía entero amarillo y no se distinguía el
		## cristal del metal ni del balón. El color lo pone el decorado -pared,
		## aro, contraluz-, no la luz que baña al sujeto.
		f.light_color = Color.WHITE if i == 1 else Color.WHITE.lerp(_acento, 0.4)
		f.light_energy = 4.0 if i == 1 else 2.4
		f.spot_range = 14.0
		f.spot_angle = 26.0
		f.spot_attenuation = 1.4
		f.shadow_enabled = i == 1
		var pos := Vector3(-2.6 + float(i) * 2.6, 4.2, 1.4)
		add_child(f)
		f.look_at_from_position(pos, Vector3(0, 1.4, -0.6), Vector3.UP)
		_focos.append(f)
	## Contraluz frío por detrás: recorta la silueta del bombo contra la pared.
	var contra := OmniLight3D.new()
	contra.light_color = _acento
	contra.light_energy = 4.5
	contra.omni_range = 9.0
	contra.position = Vector3(0, 1.6, -2.6)
	add_child(contra)

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
	cristal.refraction_enabled = true
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
	cil.height = 0.55
	tallo.mesh = cil
	tallo.material_override = met
	tallo.position = Vector3(0, -0.72, 0)
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

## El colisionador del cuenco: anillo de cajas inclinadas hacia dentro más un
## disco de suelo. Ver la nota de cabecera.
func _montar_paredes_fisicas() -> void:
	var cuerpo := StaticBody3D.new()
	_bombo.add_child(cuerpo)
	var suelo := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = RADIO_BOMBO
	cil.height = 0.08
	suelo.shape = cil
	## El suelo del colisionador tiene que coincidir con el fondo VISIBLE del
	## cuenco. Con +0,04 quedaba diez centímetros por encima y las bolas
	## descansaban en el aire, formando un anillo flotante dentro del cristal.
	## El cilindro mide 0,08 de alto, así que su centro va a -RADIO-0,04 para que
	## su cara superior caiga justo en -RADIO.
	suelo.position = Vector3(0, -RADIO_BOMBO - 0.04, 0)
	cuerpo.add_child(suelo)
	for i in 18:
		var ang := float(i) * TAU / 18.0
		var pared := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = Vector3(0.24, RADIO_BOMBO * 1.5, 0.04)
		pared.shape = caja
		var r := RADIO_BOMBO + 0.02
		pared.position = Vector3(cos(ang) * r, -0.08, sin(ang) * r)
		pared.rotation.y = -ang + PI * 0.5
		## Inclinadas hacia dentro: el cuenco se estrecha abajo y las bolas se
		## amontonan en el centro en vez de quedarse pegadas al borde.
		pared.rotation.x = deg_to_rad(-14.0)
		cuerpo.add_child(pared)

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
