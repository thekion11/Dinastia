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

static func activo() -> bool:
	return Calidad.elegida >= Calidad.MEDIA and OS.get_environment("SIN_VESTUARIO_REAL") == ""

## Suelo de resina: gris azulado con un toque del club, semibrillante, con grano fino.
static func suelo(c1: Color) -> StandardMaterial3D:
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
static func pared() -> StandardMaterial3D:
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
static func madera() -> StandardMaterial3D:
	return Texturas.madera(Color(0.55, 0.38, 0.22), 0.5)

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
		mejor.shadow_enabled = true
		mejor.shadow_bias = 0.05
		mejor.shadow_blur = 1.5
