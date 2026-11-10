class_name VestuarioRealista
extends RefCounted
## EL VESTUARIO MÁS REAL (10-11, sesión 7, sala piloto de «que el club se vea cuidado»; orden del líder: MEDIA y ALTA, ULTRA BAJA y BAJA como están). Lo que cambia, con materiales PBR procedurales del
## repo (`Texturas`: rugosidad y normales por ruido, nada a LFS):
##   · SUELO de resina oscura semibrillante (reflejos suaves de las luces del techo) en lugar del color liso;
##   · PARED de yeso pintado con grano y relieve fino;
##   · AZULEJO blanco brillante (juntas hundidas con mapa de normales, barniz) en el tercio bajo de las paredes largas y del fondo, con una cenefa del color del club;
##   · BANCOS de madera con veta y rugosidad variable (`Texturas.madera`);
##   · en ALTA, SOMBRAS en las luces del techo (el resto de la iluminación y el SSAO los pone `Calidad`/`Ambience`).
## SIN_VESTUARIO_REAL=1 lo apaga para medir el «antes». Con calidad menor que MEDIA no hace nada.

## ESTILO POR PAÍS (sesión 7): cada país lleva sus materiales reales (texturas CC0 de Poly Haven en `assets/cc0/`, ver `herramientas/bajar_cc0.py`), para que un vestuario inglés, uno
## japonés y uno argentino no se vean iguales. «ing»: suelo de tablón oscuro y ladrillo visto (Reino Unido); «jap»: tablón claro de hinoki y paredes lisas (Japón y Asia oriental);
## «lat»: baldosa de barro cocido y yeso de arcilla (España, Italia, Portugal y toda América Latina); «ale»: parqué en espiga y pared beige (centroeuropa); «nor»: laminado claro y hormigón visto (nórdico); «ara»: granito y yeso con relieve geométrico (golfo y Oriente Próximo); «afr»: suelo de arcilla y pared de arcilla con motivos (África); el resto, goma deportiva y yeso beige. El azulejo del tercio bajo es el mismo en todos.
const ESTILOS := {
	"ing": {"suelo": "dark_wooden_planks", "pared": "brick_wall_005", "madera": "dark_wooden_planks", "m_suelo": 1.2, "m_pared": 1.6},
	"jap": {"suelo": "hinoki_planks", "pared": "beige_wall_001", "madera": "hinoki_planks", "m_suelo": 1.2, "m_pared": 2.0},
	"lat": {"suelo": "patterned_terracotta_tiling", "pared": "clay_plaster", "madera": "dark_wooden_planks", "m_suelo": 1.5, "m_pared": 2.0},
	"ale": {"suelo": "herringbone_parquet", "pared": "beige_wall_002", "madera": "dark_wooden_planks", "m_suelo": 1.0, "m_pared": 2.0},
	"nor": {"suelo": "laminate_floor_02", "pared": "brushed_concrete_03", "madera": "laminate_floor_02", "m_suelo": 1.2, "m_pared": 2.0},
	"ara": {"suelo": "granite_tile", "pared": "patterned_clay_plaster", "madera": "dark_wooden_planks", "m_suelo": 1.5, "m_pared": 1.6},
	"afr": {"suelo": "clay_floor_001", "pared": "patterned_clay_wall", "madera": "dark_wooden_planks", "m_suelo": 1.5, "m_pared": 1.6},
	"def": {"suelo": "rubber_tiles", "pared": "beige_wall_001", "madera": "dark_wooden_planks", "m_suelo": 1.5, "m_pared": 2.0},
}
const GRUPOS := {
	"ing": ["ENG", "SCO", "WAL", "NIR", "IRL"],
	"jap": ["JPN", "KOR", "CHN", "TWN", "HKG"],
	"ale": ["GER", "AUT", "SUI", "NED", "BEL", "LUX", "CZE", "POL", "SVK", "HUN", "SLO", "CRO", "SRB"],
	"nor": ["SWE", "NOR", "DEN", "FIN", "ISL"],
	"ara": ["KSA", "UAE", "QAT", "KUW", "BHR", "OMA", "IRN", "IRQ", "JOR", "LIB", "SYR", "TUR", "EGY"],
	"afr": ["NGA", "GHA", "SEN", "CIV", "CMR", "RSA", "ALG", "TUN", "MLI", "COD", "KEN", "TAN", "ZIM", "ZAM", "ANG"],
	"lat": ["ESP", "ITA", "POR", "ARG", "CHI", "URU", "PAR", "BOL", "PER", "COL", "VEN", "ECU", "MEX", "BRA", "CRC", "PAN", "HON", "GUA", "SLV", "CUB", "DOM", "MAR"],
}

static func estilo_de(pais: String) -> String:
	for k: String in GRUPOS:
		if (GRUPOS[k] as Array).has(pais):
			return k
	return "def"

## Material PBR con las tres texturas de `assets/cc0/<id>/` (null si faltan: se usa el procedural de antes). `metros`: lo que mide un lado de la textura.
static func _pbr(ident: String, metros: float, tinte := Color.WHITE) -> StandardMaterial3D:
	var base := "res://assets/cc0/%s/" % ident
	if not ResourceLoader.exists(base + "diff.jpg"):
		return null
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(base + "diff.jpg") as Texture2D
	m.albedo_color = tinte
	if ResourceLoader.exists(base + "nor.jpg"):
		m.normal_enabled = true
		m.normal_texture = load(base + "nor.jpg") as Texture2D
		m.normal_scale = 0.8
	if ResourceLoader.exists(base + "rough.jpg"):
		m.roughness_texture = load(base + "rough.jpg") as Texture2D
		m.roughness = 1.0
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metros
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

static func activo() -> bool:
	return Calidad.elegida >= Calidad.MEDIA and OS.get_environment("SIN_VESTUARIO_REAL") == ""

## Suelo de resina: gris azulado con un toque del club, semibrillante, con grano fino.
static func suelo(c1: Color, pais := "") -> StandardMaterial3D:
	var e: Dictionary = ESTILOS[estilo_de(pais)]
	var real := _pbr(String(e["suelo"]), float(e["m_suelo"]))
	if real != null:
		real.clearcoat_enabled = true
		real.clearcoat = 0.25
		return real
	var m := (Texturas.hormigon(Color(0.27, 0.28, 0.3).lerp(c1, 0.05), 41).duplicate() as StandardMaterial3D)
	m.roughness = 0.42
	m.roughness_texture = null
	m.normal_scale = 0.04
	m.metallic_specular = 0.7
	m.clearcoat_enabled = true
	m.clearcoat = 0.35
	m.clearcoat_roughness = 0.3
	return m

## Yeso pintado.
static func pared(pais := "") -> StandardMaterial3D:
	var e: Dictionary = ESTILOS[estilo_de(pais)]
	var real := _pbr(String(e["pared"]), float(e["m_pared"]))
	if real != null:
		return real
	var m := (Texturas.hormigon(Color(0.9, 0.89, 0.86), 29).duplicate() as StandardMaterial3D)
	m.albedo_texture = null   ## el ruido del hormigón en una pared pintada parecía granito
	m.detail_enabled = false
	m.roughness = 0.9
	m.roughness_texture = null
	m.normal_scale = 0.05
	return m

static var _azulejo: StandardMaterial3D = null

## Azulejo blanco de 30 cm con juntas hundidas (albedo con la junta más oscura + normal con la ranura), barnizado.
static func azulejo() -> StandardMaterial3D:
	if _azulejo != null:
		return _azulejo
	var n := 256
	var alb := Image.create(n, n, false, Image.FORMAT_RGB8)
	var nor := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var paso := 128   ## 128 px = 0,3 m con el reparto de abajo: dos azulejos por lado
	for y in n:
		for x in n:
			var gx := x % paso
			var gy := y % paso
			var junta := gx < 3 or gy < 3
			var v := 0.93 + (rng.randf() - 0.5) * 0.03
			if junta:
				v = 0.62
			alb.set_pixel(x, y, Color(v, v, v * 1.01))
			## normal: la ranura inclina la superficie hacia dentro en sus dos bordes
			var nx := 0.5
			var ny := 0.5
			if gx < 3:
				nx = 0.5 + (0.28 if gx < 1 else -0.0)
			if gy < 3:
				ny = 0.5 + (0.28 if gy < 1 else -0.0)
			nor.set_pixel(x, y, Color(nx, ny, 1.0))
	alb.generate_mipmaps()
	nor.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(alb)
	m.albedo_color = Color(0.95, 0.96, 0.97)
	m.normal_enabled = true
	m.normal_texture = ImageTexture.create_from_image(nor)
	m.normal_scale = 0.8
	m.roughness = 0.22
	m.metallic_specular = 0.8
	m.clearcoat_enabled = true
	m.clearcoat = 0.6
	m.clearcoat_roughness = 0.12
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(1.0 / 0.6, 1.0 / 0.6, 1.0 / 0.6)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_azulejo = m
	return m

## Madera de los bancos.
## (10-11) Materiales compartidos del edificio del club por país y tipo («madera», «baldosa», «resina», «pared»): una sola instancia por clave, así
## el `Lote`/fusión sigue agrupando por material y la memoria no crece con cada sala.
static var _cache_sala := {}
static func sala(tipo: String, pais := "") -> StandardMaterial3D:
	var clave := "%s|%s" % [tipo, estilo_de(pais)]
	if _cache_sala.has(clave):
		return _cache_sala[clave]
	var e: Dictionary = ESTILOS[estilo_de(pais)]
	var m: StandardMaterial3D = null
	match tipo:
		"madera":
			m = _pbr(String(e["madera"]), 2.0)
		"baldosa":
			m = _pbr("floor_tiles_06", 1.5)
		"resina":
			m = _pbr(String(e["suelo"]), float(e["m_suelo"]))
		"pared":
			m = _pbr(String(e["pared"]), float(e["m_pared"]))
	_cache_sala[clave] = m
	return m

## Tipo de suelo real (`sala`) por sala; «» = se queda el color liso.
static func tipo_suelo(sala: String) -> String:
	match sala:
		"Oficina del DT", "Despacho del presidente", "Comedor del plantel", "Museo del club", "Museo ampliado":
			return "madera"
		"Enfermería":
			return "baldosa"
		"Sala de vídeo", "Sala de prensa", "Utilería":
			return "resina"
	return ""

static func madera(pais := "") -> StandardMaterial3D:
	var e: Dictionary = ESTILOS[estilo_de(pais)]
	var real := _pbr(String(e["madera"]), 1.0)
	return real if real != null else Texturas.madera(Color(0.55, 0.38, 0.22), 0.5)

## El tercio bajo de las paredes con azulejo y cenefa del club. Las pieles de pintura van a x ± (VEST_MEDIO − 0.02) (0,04 de grueso): el azulejo, de 2 cm, se pega por dentro.
## `caja` es `TunelVestuario._caja(nodo, centro, tamaño, material, sólido)`.
static func azulejos(nodo: Node3D, x0: float, z_out: float, z_fin: float, c1: Color) -> void:
	var az := azulejo()
	var cen := PiezasObra._mat(c1, 0.5)
	var medio := TunelMedidas.VEST_MEDIO
	var zc := (z_out + z_fin) / 2.0
	var largo := z_fin - z_out - 0.1
	var alto := 1.15
	for lado in [-1.0, 1.0]:
		var x: float = x0 + lado * (medio - 0.05)
		PiezasObra._caja(nodo, Vector3(x, alto / 2.0, zc), Vector3(0.02, alto, largo), az, false)
		PiezasObra._caja(nodo, Vector3(x - lado * 0.001, alto + 0.04, zc), Vector3(0.025, 0.08, largo), cen, false)

## Sombra en UNA luz (la central del techo; solo ALTA): cada luz puntual con sombra repite toda la escena 6 veces (con las tres del techo, +1.176 llamadas en ARG), con una sola ~+390. Esa sombra
## sienta al personaje y a los bancos en el suelo. `nodo` es el del túnel/vestuario; `x0` y `z_centro` dicen cuál es la luz central.
static func sombras(nodo: Node3D, x0: float, z_centro: float) -> void:
	if not activo() or Calidad.elegida < Calidad.ALTO:
		return
	var mejor: OmniLight3D = null
	var d_mejor := 1e9
	for o in nodo.find_children("*", "OmniLight3D", true, false):
		var l := o as OmniLight3D
		if l.omni_range < 12.0:
			continue
		var d := absf(l.position.z - z_centro) + absf(l.position.x - x0)
		if d < d_mejor:
			d_mejor = d
			mejor = l
	if mejor != null:
		mejor.shadow_enabled = Calidad.sombra_solar(Calidad.elegida)   ## (10-11) en ULTRA BAJA y BAJA las luces no proyectan sombra (vigilante p6_calidad_minima)
		mejor.shadow_bias = 0.05
		mejor.shadow_blur = 1.5

## ESCUDO GRANDE del club en la pared del fondo (entre la pizarra y la puerta de la calle: x0 + 2,9), pintado: `Escudo.textura` (el mismo del menú) en un plano de 2 m. Solo MEDIA y ALTA.
static func escudo(nodo: Node3D, x0: float, z_fin: float, mi: Club) -> void:
	if not activo() or mi == null:
		return
	var tex := Escudo.textura(mi, 256 if Calidad.elegida >= Calidad.ALTO else 128)
	if tex == null:
		return
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.55
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.9, 1.9)
	q.mesh = qm
	q.material_override = m
	q.position = Vector3(x0 + 2.9, 1.8, z_fin - 0.055)
	q.rotation.y = PI   ## mira a −Z, hacia dentro de la sala
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	q.name = "EscudoVestuario"
	nodo.add_child(q)

## PIZARRA TÁCTICA con la formación del club: el campo en azul sobre el blanco y once fichas del color del club (portero del segundo) repartidas como dice `tactica.formacion`
## («4-2-3-1»: portero, línea de 4, de 2, de 3 y de 1). Reemplaza al «4-3-3» escrito a mano. Solo MEDIA y ALTA.
static func pizarra(nodo: Node3D, x0: float, z_fin: float, c1: Color, c2: Color, mi: Club) -> void:
	var formacion := String(mi.tactica.formacion) if mi != null else "4-3-3"
	var lineas: Array[int] = []
	for p in formacion.split("-"):
		if p.is_valid_int():
			lineas.append(int(p))
	if lineas.is_empty() or lineas.reduce(func(a: int, b: int) -> int: return a + b) != 10:
		lineas = [4, 3, 3]
	var an := 512
	var al := 320
	var img := Image.create(an, al, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.97, 0.98, 0.98))
	var azul := Color(0.15, 0.22, 0.5)
	## Campo: borde, línea de medio campo, círculo central y las dos áreas.
	for x in range(18, an - 18):
		for t in 3:
			img.set_pixel(x, 18 + t, azul)
			img.set_pixel(x, al - 21 + t, azul)
	for y in range(18, al - 18):
		for t in 3:
			img.set_pixel(18 + t, y, azul)
			img.set_pixel(an - 21 + t, y, azul)
			img.set_pixel(an / 2 + t, y, azul)
	for a in 360:
		var ang := deg_to_rad(float(a))
		for t in 3:
			var r := 44.0 + float(t)
			img.set_pixel(clampi(an / 2 + int(cos(ang) * r), 0, an - 1), clampi(al / 2 + int(sin(ang) * r), 0, al - 1), azul)
	## Las dos áreas (rectángulos de 66 × 120 px a cada lado).
	for lado_der in [false, true]:
		var x_borde := an - 18 if lado_der else 18
		var x_fondo := x_borde + (-66 if lado_der else 66)
		for t in 3:
			for x in range(mini(x_borde, x_fondo), maxi(x_borde, x_fondo)):
				img.set_pixel(x, 100 + t, azul)
				img.set_pixel(x, 217 + t, azul)
			for y in range(100, 220):
				img.set_pixel(x_fondo + t, y, azul)
	## Fichas: portero a la izquierda y las líneas hacia la derecha (el equipo ataca a la derecha).
	var fichas: Array[Vector2] = [Vector2(48, al / 2)]
	var n_l := lineas.size()
	for i in n_l:
		var x := lerpf(120.0, 440.0, float(i + 1) / float(n_l + 1)) - 20.0 + 20.0 * float(i) / float(maxi(n_l - 1, 1))
		for j in lineas[i]:
			fichas.append(Vector2(x, lerpf(48.0, al - 48.0, (float(j) + 0.5) / float(lineas[i]))))
	for k in fichas.size():
		var c := fichas[k]
		var col := c2 if k == 0 else c1
		for dy in range(-15, 16):
			for dx in range(-15, 16):
				var d := sqrt(float(dx * dx + dy * dy))
				if d <= 15.0:
					img.set_pixel(clampi(int(c.x) + dx, 0, an - 1), clampi(int(c.y) + dy, 0, al - 1), Color.WHITE if d > 12.0 else col)
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 0.3
	m.metallic_specular = 0.6
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(3.1, 1.94)
	q.mesh = qm
	q.material_override = m
	q.position = Vector3(x0, 1.7, z_fin - 0.135)
	q.rotation.y = PI
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	q.name = "PizarraFormacion"
	nodo.add_child(q)
	PiezasObra._rotulo(nodo, formacion, Vector3(x0, 2.82, z_fin - 0.14), PI, 36, azul)
