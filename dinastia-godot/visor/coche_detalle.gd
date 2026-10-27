class_name CocheDetalle
extends RefCounted
## EL DETALLE DE LOS COCHES (27-10-2026): pedido del dueño, «los autos se ven muy infantiles» y «agrega las patentes».
##  · `pintura(orig)`: material con `coche_real.gdshader` (paleta de Kenney apagada y cristales oscuros), uno por textura.
##  · `placa(i)`: matrículas con el formato argentino «AB 123 CD» (franja azul arriba), generadas con una fuente de 5×7
##    puntos propia (no hace falta cargar nada), 24 distintas y compartidas; delante y detrás de cada coche.
##  · `vestir(modelo, escala, semilla)`: pinta el coche, le pone las dos placas, retrovisores y faros delanteros/traseros.
## Todo con meshes y materiales compartidos: un coche cuesta 7 piezas nuevas sin llamadas de dibujo extra por material.

const N_PLACAS := 24
const LETRAS := "ABCDEFGHJKLMNPRSTUVXYZ"
## Fuente 5×7: cada carácter son 7 filas de 5 bits.
const FUENTE := {
	"A": [14, 17, 17, 31, 17, 17, 17], "B": [30, 17, 17, 30, 17, 17, 30], "C": [14, 17, 16, 16, 16, 17, 14],
	"D": [30, 17, 17, 17, 17, 17, 30], "E": [31, 16, 16, 30, 16, 16, 31], "F": [31, 16, 16, 30, 16, 16, 16],
	"G": [14, 17, 16, 23, 17, 17, 15], "H": [17, 17, 17, 31, 17, 17, 17], "J": [7, 2, 2, 2, 2, 18, 12],
	"K": [17, 18, 20, 24, 20, 18, 17], "L": [16, 16, 16, 16, 16, 16, 31], "M": [17, 27, 21, 21, 17, 17, 17],
	"N": [17, 25, 21, 19, 17, 17, 17], "P": [30, 17, 17, 30, 16, 16, 16], "R": [30, 17, 17, 30, 20, 18, 17],
	"S": [15, 16, 16, 14, 1, 1, 30], "T": [31, 4, 4, 4, 4, 4, 4], "U": [17, 17, 17, 17, 17, 17, 14],
	"V": [17, 17, 17, 17, 17, 10, 4], "X": [17, 17, 10, 4, 10, 17, 17], "Y": [17, 17, 10, 4, 4, 4, 4],
	"Z": [31, 1, 2, 4, 8, 16, 31],
	"0": [14, 17, 19, 21, 25, 17, 14], "1": [4, 12, 4, 4, 4, 4, 14], "2": [14, 17, 1, 2, 4, 8, 31],
	"3": [31, 2, 4, 2, 1, 17, 14], "4": [2, 6, 10, 18, 31, 2, 2], "5": [31, 16, 30, 1, 1, 17, 14],
	"6": [6, 8, 16, 30, 17, 17, 14], "7": [31, 1, 2, 4, 8, 8, 8], "8": [14, 17, 17, 14, 17, 17, 14],
	"9": [14, 17, 17, 15, 1, 2, 12]}

static var _pinturas := {}
static var _n_coches := 0
static var _placas: Array[StandardMaterial3D] = []
static var _quad: QuadMesh
static var _caja: BoxMesh

## El texto de la matrícula número `i` (estable): «AB 123 CD».
static func texto_placa(i: int) -> String:
	var h := absi(hash([i, "placa"]))
	var l := LETRAS.length()
	return "%s%s %03d %s%s" % [LETRAS[h % l], LETRAS[(h / 7) % l], (h / 49) % 1000, LETRAS[(h / 49000) % l], LETRAS[(h / 1000000) % l]]

static func _dibujar(img: Image, texto: String, x0: int, y0: int, esc: int, col: Color) -> void:
	var x := x0
	for ch in texto:
		if FUENTE.has(ch):
			var filas: Array = FUENTE[ch]
			for fy in 7:
				for fx in 5:
					if (int(filas[fy]) >> (4 - fx)) & 1:
						img.fill_rect(Rect2i(x + fx * esc, y0 + fy * esc, esc, esc), col)
		x += 6 * esc if ch != " " else 3 * esc

static func placa(i: int) -> StandardMaterial3D:
	if _placas.is_empty():
		for k in N_PLACAS:
			var img := Image.create(128, 40, false, Image.FORMAT_RGBA8)
			img.fill(Color(0.93, 0.93, 0.9))
			img.fill_rect(Rect2i(0, 0, 128, 9), Color(0.1, 0.25, 0.6))      ## franja azul del país
			_dibujar(img, texto_placa(k), 6, 13, 3, Color(0.06, 0.06, 0.08))
			var m := StandardMaterial3D.new()
			m.albedo_texture = ImageTexture.create_from_image(img)
			m.roughness = 0.5
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			_placas.append(m)
	return _placas[posmod(i, N_PLACAS)]

static func pintura(orig: Material) -> Material:
	var tex: Texture2D = (orig as StandardMaterial3D).albedo_texture if orig is StandardMaterial3D else null
	if tex == null:
		return orig
	if not _pinturas.has(tex):
		var m := ShaderMaterial.new()
		m.shader = load("res://visor/coche_real.gdshader")
		m.set_shader_parameter("paleta", tex)
		_pinturas[tex] = m
	return _pinturas[tex]

static func _pieza(padre: Node3D, pos: Vector3, tam: Vector3, mat: Material) -> void:
	if _caja == null:
		_caja = BoxMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = _caja
	mi.scale = tam
	mi.position = pos
	mi.material_override = mat
	padre.add_child(mi)

## Pinta el coche y le pone placas, retrovisores y faros. `escala` es la escala del modelo (para medir en metros reales).
static func vestir(modelo: Node3D, escala: Vector3, semilla: int = -1) -> void:
	if semilla < 0:
		_n_coches += 1
		semilla = _n_coches
	var cuerpo: MeshInstance3D = null
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var orig := m.mesh.surface_get_material(0) if m.mesh != null and m.mesh.get_surface_count() > 0 else null
		if orig != null:
			m.material_override = pintura(orig)
		if String(m.name) == "body":
			cuerpo = m
	if cuerpo == null:
		return
	var a := cuerpo.get_aabb()
	var sx := maxf(escala.x, 0.01)
	var sy := maxf(escala.y, 0.01)
	var sz := maxf(escala.z, 0.01)
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2(1, 1)
	var h := absi(hash([semilla, "coche"]))
	var plano := Vector3(0.52 / sx, 0.13 / sy, 1.0)
	var y := cuerpo.position.y + a.position.y + 0.5 / sy
	var zt := cuerpo.position.z + a.position.z - 0.012 / sz       ## detrás
	var zd := cuerpo.position.z + a.end.z + 0.012 / sz            ## delante
	for lado in 2:
		var mi := MeshInstance3D.new()
		mi.mesh = _quad
		mi.scale = plano
		mi.material_override = placa(h + lado * 7)
		mi.position = Vector3(cuerpo.position.x, y, zd if lado == 0 else zt)
		mi.rotation.y = 0.0 if lado == 0 else PI
		modelo.add_child(mi)
	## Faros delanteros (blancos) y pilotos traseros (rojos), apagados de día; retrovisores.
	for sxl: float in [-1.0, 1.0]:
		var cx := cuerpo.position.x + sxl * (a.size.x * 0.5 - 0.32 / sx)
		var cy := cuerpo.position.y + a.position.y
		_pieza(modelo, Vector3(cx, cy + 0.6 / sy, zd - 0.03 / sz), Vector3(0.2 / sx, 0.08 / sy, 0.06 / sz), _faro(true))
		_pieza(modelo, Vector3(cx, cy + 0.64 / sy, zt + 0.03 / sz), Vector3(0.2 / sx, 0.08 / sy, 0.06 / sz), _faro(false))
		_pieza(modelo, Vector3(cuerpo.position.x + sxl * (a.size.x * 0.5 + 0.02 / sx), cy + a.size.y * 0.56, cuerpo.position.z + a.position.z + a.size.z * 0.62), Vector3(0.1 / sx, 0.07 / sy, 0.16 / sz), _retrovisor())

static var _faros := {}
static func _faro(blanco: bool) -> StandardMaterial3D:
	if not _faros.has(blanco):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.95, 0.95, 0.85) if blanco else Color(0.7, 0.05, 0.05)
		m.emission_enabled = true
		m.emission = m.albedo_color
		m.emission_energy_multiplier = 0.25
		_faros[blanco] = m
	return _faros[blanco]

static var _retro: StandardMaterial3D
static func _retrovisor() -> StandardMaterial3D:
	if _retro == null:
		_retro = StandardMaterial3D.new()
		_retro.albedo_color = Color(0.05, 0.05, 0.06)
		_retro.roughness = 0.3
	return _retro
