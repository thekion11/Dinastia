class_name RuedaPrensaExtras
extends RefCounted
## LO QUE LA RUEDA DE PRENSA DE REFERENCIA TIENE Y LA NUESTRA NO (10-11, vídeo del dueño; análisis en
## `docs/04_auditorias/PROLOGO_REFERENCIA_2026-11-10.md` §2, mejoras R2 y R4):
##   - una BARRA DE FOCOS colgada sobre el atril, a la vista en el plano general (los focos se ven, la sala no es una caja negra);
##   - el RAMO DE MICRÓFONOS de los medios delante del DT (cada uno con su cubo de color de la cadena) y un BALÓN con los colores del club.
## Piezas sueltas baratas (unas 20 mallas pequeñas); en calidad MÍNIMA solo los micrófonos y el balón.
const COLORES_MEDIOS: Array[Color] = [Color(0.85, 0.12, 0.12), Color(0.1, 0.35, 0.8), Color(0.95, 0.75, 0.1), Color(0.1, 0.6, 0.3),
	Color(0.92, 0.92, 0.92), Color(0.55, 0.15, 0.6)]

## `mesa`: a la altura de la mesa larga con el DT sentado (`RuedaPrensaMesa`); si no, sobre el atril.
static func montar(escena: Node3D, c1: Color, c2: Color, mesa := false) -> void:
	_ramo(escena, mesa)
	_balon(escena, c1, c2, mesa)
	if Calidad.elegida > Calidad.MINIMO:
		_focos(escena)

static func _mat(c: Color, rug := 0.6, emis := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	if emis > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emis
	return m

## Cuatro micrófonos de mano en sus soportes, apuntando a la boca del DT, cada uno con el cubo de color de su cadena.
static func _ramo(escena: Node3D, mesa: bool) -> void:
	var negro := _mat(Color(0.05, 0.05, 0.06), 0.45)
	var boca := Vector3(0, 1.17, -0.9) if mesa else Vector3(0, 1.58, -0.55)
	var xs: Array[float] = [-0.26, -0.13, 0.13, 0.26]
	for k in xs.size():
		var base := Vector3(xs[k], 0.8, -0.42 - absf(xs[k]) * 0.15) if mesa else Vector3(xs[k], 1.13, -0.02 - absf(xs[k]) * 0.15)
		var dir := (boca - base).normalized()
		var mic := Node3D.new()
		mic.name = "MicMedio%d" % k
		escena.add_child(mic)
		mic.position = base
		mic.look_at(base + dir, Vector3.UP)   ## -Z mira a la boca
		var cuerpo := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.016
		cm.bottom_radius = 0.012
		cm.height = 0.2
		cuerpo.mesh = cm
		cuerpo.material_override = negro
		cuerpo.rotation_degrees.x = -90.0
		cuerpo.position = Vector3(0, 0, -0.1)
		mic.add_child(cuerpo)
		var cubo := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.055, 0.055, 0.055)
		cubo.mesh = bm
		cubo.material_override = _mat(COLORES_MEDIOS[k % COLORES_MEDIOS.size()], 0.5)
		cubo.position = Vector3(0, 0, -0.17)
		mic.add_child(cubo)
		var rejilla := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.024
		sm.height = 0.048
		rejilla.mesh = sm
		rejilla.material_override = _mat(Color(0.25, 0.25, 0.27), 0.9)
		rejilla.position = Vector3(0, 0, -0.215)
		mic.add_child(rejilla)

## Un balón con los colores del club sobre el atril, a la derecha del DT (en la referencia, con el escudo).
static func _balon(escena: Node3D, c1: Color, c2: Color, mesa: bool) -> void:
	var b := MeshInstance3D.new()
	b.name = "BalonAtril"
	var sm := SphereMesh.new()
	sm.radius = 0.11
	sm.height = 0.22
	b.mesh = sm
	var img := Image.create(8, 4, false, Image.FORMAT_RGB8)
	for x in 8:
		for y in 4:
			img.set_pixel(x, y, Color.WHITE if (x + y) % 2 == 0 else (c1 if c1.get_luminance() < 0.85 else c2))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 0.45
	b.material_override = m
	b.position = Vector3(-0.55, 0.89, -0.4) if mesa else Vector3(0.38, 1.24, -0.04)
	escena.add_child(b)

## La barra de focos sobre el atril: un tubo negro y seis focos con la boca encendida, apuntando a la mesa.
static func _focos(escena: Node3D) -> void:
	var negro := _mat(Color(0.06, 0.06, 0.07), 0.5)
	var barra := MeshInstance3D.new()
	barra.name = "BarraFocos"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.03
	cm.bottom_radius = 0.03
	cm.height = 3.6
	barra.mesh = cm
	barra.material_override = negro
	barra.rotation_degrees.z = 90.0
	barra.position = Vector3(0, 3.25, 0.5)
	escena.add_child(barra)
	var boca := _mat(Color(1.0, 0.95, 0.85), 0.3, 4.0)
	for i in 6:
		var x := -1.5 + float(i) * 0.6
		var foco := Node3D.new()
		escena.add_child(foco)
		foco.position = Vector3(x, 3.1, 0.5)
		foco.look_at(Vector3(x * 0.3, 1.2, -0.3), Vector3.UP)
		var lata := MeshInstance3D.new()
		var lm := CylinderMesh.new()
		lm.top_radius = 0.07
		lm.bottom_radius = 0.09
		lm.height = 0.22
		lata.mesh = lm
		lata.material_override = negro
		lata.rotation_degrees.x = -90.0
		foco.add_child(lata)
		var disco := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = 0.075
		dm.bottom_radius = 0.075
		dm.height = 0.01
		disco.mesh = dm
		disco.material_override = boca
		disco.rotation_degrees.x = -90.0
		disco.position = Vector3(0, 0, -0.115)
		foco.add_child(disco)
