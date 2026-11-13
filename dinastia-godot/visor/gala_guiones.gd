class_name GalaGuiones
extends RefCounted
## LOS GUIONES DE LAS ENTREGAS DE PREMIOS (`GalaPremio3D`) y sus decorados. Uno por premio, todos distintos:
## lugar («campo» = tu estadio con tus compañeros; «gala» = el salón de tu liga; «estadio» = la tarima de la final;
## «mundo» = la gala mundial), objeto (el galardón, `GalaObjetos`), anim (cómo lo celebras; la primera que tenga
## el modelo), camara (orbita / frontal / contrapicado / travelling / alta) y extra (cohetes / flashes / lluvia).
## El galardón va en tu mano derecha: sube y baja con el gesto de cada celebración.

const GUIONES := {
	"revelacion": {"lugar": "campo", "objeto": "estrella", "anim": "puno_al_aire|celebrar", "camara": "orbita", "extra": ""},
	"goleador_club": {"lugar": "campo", "objeto": "bota_plata", "anim": "besar_escudo|celebrar", "camara": "contrapicado", "extra": ""},
	"mejor_club": {"lugar": "campo", "objeto": "placa", "anim": "saludar_publico|aplaudir|celebrar", "camara": "frontal", "extra": "lluvia"},
	"hierro": {"lugar": "campo", "objeto": "hierro", "anim": "brazos_jarra|idle", "camara": "travelling", "extra": ""},
	"duelo": {"lugar": "campo", "objeto": "guante_duelo", "anim": "puno_al_aire|celebrar_ls|celebrar", "camara": "contrapicado", "extra": ""},
	"salto": {"lugar": "campo", "objeto": "flecha", "anim": "saltar|celebrar", "camara": "alta", "extra": ""},
	"once_ideal": {"lugar": "gala", "objeto": "camiseta", "anim": "aplaudir|idle", "camara": "travelling", "extra": "flashes"},
	"muro": {"lugar": "gala", "objeto": "guante", "anim": "puno_al_aire|celebrar", "camara": "frontal", "extra": "flashes"},
	"goleador_liga": {"lugar": "gala", "objeto": "bota", "anim": "aplauso_arriba|celebrar", "camara": "orbita", "extra": "flashes"},
	"asistidor_liga": {"lugar": "gala", "objeto": "orbita", "anim": "saludar_publico|aplaudir", "camara": "travelling", "extra": "flashes"},
	"portero_liga": {"lugar": "gala", "objeto": "guante", "anim": "besar_escudo|celebrar", "camara": "contrapicado", "extra": "flashes"},
	"mvp_liga": {"lugar": "gala", "objeto": "balon", "anim": "celebrar_ls|celebrar", "camara": "alta", "extra": "lluvia"},
	"mvp_copa": {"lugar": "estadio", "objeto": "copa", "anim": "celebrar|saltar", "camara": "orbita", "extra": "lluvia"},
	"mvp_continental": {"lugar": "estadio", "objeto": "continental", "anim": "celebrar_ls|celebrar", "camara": "contrapicado", "extra": "cohetes"},
	## Los TÍTULOS del club, cuando la calidad no deja montar el festejo del equipo entero (`RutaGala`): tú con la copa.
	"trofeo_liga": {"lugar": "estadio", "objeto": "liga", "anim": "celebrar|aplauso_arriba", "camara": "orbita", "extra": "lluvia"},
	"trofeo_copa": {"lugar": "estadio", "objeto": "copa", "anim": "celebrar_ls|celebrar", "camara": "frontal", "extra": "lluvia"},
	"trofeo_continental": {"lugar": "estadio", "objeto": "continental", "anim": "celebrar|celebrar_ls", "camara": "contrapicado", "extra": "cohetes"},
	"trofeo_otro": {"lugar": "estadio", "objeto": "supercopa", "anim": "aplauso_arriba|celebrar", "camara": "travelling", "extra": ""},
	"mundial": {"lugar": "mundo", "objeto": "globo", "anim": "celebrar|celebrar_ls", "camara": "orbita", "extra": "cohetes"},
}

## Quien te lo entrega: el de más media de tu club que no seas tú.
static func quien_entrega(club: Club, j: Jugador) -> Jugador:
	var mejor: Jugador = null
	for o: Jugador in club.plantilla:
		if o != j and (mejor == null or o.ovr > mejor.ovr):
			mejor = o
	return mejor

## Tus compañeros aplaudiendo detrás, en arco (los cuatro primeros de tu plantilla que no seáis ni tú ni quien entrega).
static func companeros(g: GalaPremio3D, raiz: Node3D, spawner, club: Club, j: Jugador, c1: Color, c2: Color) -> void:
	var entrega := quien_entrega(club, j)
	var n := 0
	for o: Jugador in club.plantilla:
		if o == j or o == entrega or n >= (2 if Calidad.elegida <= Calidad.MINIMO else 4):   ## en la calidad mínima, dos compañeros
			continue
		var x := -3.0 + float(n) * 1.6
		g._jugador(raiz, spawner, o, Vector3(x, 0.0, -2.4 - absf(x + 0.6) * 0.15), 0.0, "aplaudir|idle", c1, c2, n * 0.41)
		n += 1

## La tarima de la final, con la lona del torneo. Devuelve la altura del suelo.
static func tarima(g: GalaPremio3D, raiz: Node3D, c1: Color, titulo: String) -> float:
	g._caja(raiz, Vector3(0, 0.25, 0), Vector3(9.0, 0.5, 3.4), g._mat(Color(0.08, 0.09, 0.12), 0.5))
	g._caja(raiz, Vector3(0, 0.52, 1.7), Vector3(9.0, 0.06, 0.06), g._mat(Color(0.95, 0.78, 0.3), 0.3, 1.5))
	g._caja(raiz, Vector3(0, 1.9, -1.9), Vector3(9.0, 2.8, 0.08), g._mat(c1.darkened(0.45)))
	_rotulo(raiz, titulo, Vector3(0, 2.6, -1.84), 0.9)
	return 0.5

## El salón de la gala: escenario, telón con la bandera del país de tu liga y el escudo de tu club, el nombre de la
## liga y el del premio, atril y un patio de butacas en una sola llamada. En la mundial, una fila de banderas.
static func salon(g: GalaPremio3D, raiz: Node3D, datos: Dictionary, club: Club, titulo: String, mundial: bool) -> float:
	var oro := Color(0.95, 0.78, 0.3)
	g._caja(raiz, Vector3(0, -0.05, 4.0), Vector3(26, 0.1, 22), g._mat(Color(0.05, 0.05, 0.07), 0.25))   ## el suelo del salón
	g._caja(raiz, Vector3(0, 0.3, -0.4), Vector3(11.0, 0.6, 4.6), g._mat(Color(0.09, 0.08, 0.11), 0.35))   ## el escenario
	g._caja(raiz, Vector3(0, 0.62, 1.9), Vector3(11.0, 0.05, 0.05), g._mat(oro, 0.3, 1.6))
	g._caja(raiz, Vector3(0, 3.2, -2.8), Vector3(12.0, 5.4, 0.1), g._mat(Color(0.16, 0.05, 0.08) if not mundial else Color(0.05, 0.07, 0.16), 0.8))   ## el telón
	g._caja(raiz, Vector3(1.0, 1.15, 0.2), Vector3(0.5, 1.1, 0.4), g._mat(Color(0.12, 0.11, 0.14), 0.4))   ## el atril
	_rotulo(raiz, titulo, Vector3(0, 4.9, -2.7), 1.25)
	_rotulo(raiz, Nombres.visible(String(datos.get("liga", ""))) if not mundial else "", Vector3(0, 4.1, -2.7), 0.8)
	if mundial:
		var paises: Array = []
		var m: Mundo = datos.get("mundo")
		for l: Liga in (m.ligas if m != null else []):
			if not paises.has(l.pais) and paises.size() < 7:
				paises.append(l.pais)
		for k in paises.size():
			_cuadro(raiz, Banderas.textura(String(paises[k])), Vector3(-4.8 + k * 1.6, 2.6, -2.7), Vector2(1.4, 0.9))
	else:
		_cuadro(raiz, Banderas.textura(String(datos.get("pais", club.pais))), Vector3(-3.6, 2.5, -2.7), Vector2(2.4, 1.5))
		_cuadro(raiz, load("res://ui/escudo.gd").textura(club, 256), Vector3(3.6, 2.5, -2.7), Vector2(1.6, 1.6))
	## El patio de butacas: 240 siluetas, casi todas oscuras.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = 240
	var bm := BoxMesh.new()
	bm.size = Vector3(0.42, 0.6, 0.3)
	mm.mesh = bm
	var azar := RandomNumberGenerator.new()
	azar.seed = hash(club.id)
	for i in 240:
		var fila := i / 24
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(-8.0 + float(i % 24) * 0.7, 0.3 + fila * 0.12, 4.2 + fila * 0.9)))
		var r := azar.randf()
		mm.set_instance_color(i, Color(0.06, 0.06, 0.08) if r < 0.8 else (Color(club.color1).darkened(0.3) if r < 0.92 else Color(0.5, 0.48, 0.45)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mmi.material_override = mat
	raiz.add_child(mmi)
	## La luz: un cenital cálido sobre el escenario y dos de contra con los colores del club.
	var cenital := SpotLight3D.new()
	cenital.spot_range = 14.0
	cenital.spot_angle = 30.0
	cenital.light_energy = 7.0
	cenital.light_color = Color(1, 0.95, 0.85)
	cenital.shadow_enabled = Calidad.elegida > Calidad.BAJA
	raiz.add_child(cenital)
	cenital.transform = Transform3D(Basis(), Vector3(-0.6, 8.0, 4.5)).looking_at(Vector3(-0.3, 1.2, 0.2), Vector3.UP)
	for lado: float in [-1.0, 1.0]:
		var contra := OmniLight3D.new()
		contra.position = Vector3(5.0 * lado, 3.0, -1.8)
		contra.omni_range = 7.0
		contra.light_energy = 2.2
		contra.light_color = (Color(club.color1) if lado < 0.0 else Color(club.color2)).lightened(0.35)
		raiz.add_child(contra)
	return 0.6

static func _rotulo(raiz: Node3D, texto: String, pos: Vector3, alto: float) -> void:
	if texto == "":
		return
	var l := Label3D.new()
	l.text = texto.to_upper()
	l.font_size = 96
	l.pixel_size = alto / 150.0
	l.modulate = Color(1.0, 0.86, 0.45)
	l.outline_size = 0
	l.position = pos
	l.width = 1600.0
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(l)

static func _cuadro(raiz: Node3D, tex: Texture2D, pos: Vector3, tam: Vector2) -> void:
	if tex == null:
		return
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = tam
	mi.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.roughness = 0.9
	mi.material_override = mat
	mi.position = pos
	raiz.add_child(mi)

## El confeti: con los colores del club, apagado hasta que levantas el premio. «lluvia» = más cantidad.
static func confeti(g: GalaPremio3D, raiz: Node3D, c1: Color, c2: Color, extra: String) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 260 if extra == "lluvia" else 120
	p.lifetime = 4.5
	p.position = Vector3(-0.6, 8.0, 0.5)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(5, 0.4, 3)
	p.gravity = Vector3(0, -1.7, 0)
	p.direction = Vector3(0, -1, 0)
	p.spread = 30.0
	p.angular_velocity_min = -180.0
	p.angular_velocity_max = 180.0
	var qm := QuadMesh.new()
	qm.size = Vector2(0.08, 0.05)
	p.mesh = qm
	var grad := Gradient.new()
	grad.set_color(0, c1.lightened(0.2))
	grad.set_color(1, c2.lightened(0.1))
	p.color_initial_ramp = grad
	var mat := g._mat(Color(1, 1, 1), 0.3, 0.0)
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	p.material_override = mat
	p.emitting = false
	raiz.add_child(p)
	return p
