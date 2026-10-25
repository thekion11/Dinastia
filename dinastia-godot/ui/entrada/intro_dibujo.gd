extends Control
## [Capa 1/3 de `intro.gd`] EL DIBUJO DE LA INTRO DE MARCA: la partitura, los recursos (letra,
## punto de luz, contorno del escudo, partículas), la maqueta y los uniformes de cada
## fotograma. Lo que pinta cada capa está en `intro_capas.gd`; la clase que se usa es
## `IntroMarca` (`intro.gd`).
##
## TODO ES FUNCIÓN PURA DEL TIEMPO `_t`. Nada se integra fotograma a fotograma (ni las
## chispas: su trayectoria con rozamiento tiene fórmula cerrada), así que la intro se puede
## congelar en cualquier instante y la captura sale idéntica a lo que ve el jugador, y una
## caída de fotogramas no deja la animación a medias: el siguiente fotograma ya está en su sitio.
##
## NI UN FICHERO: el repositorio no tiene logotipo ni tipografía de marca (`marca/` solo
## guarda la Tierra), así que la marca se construye aquí: un escudo que se traza en oro,
## una corona, el monograma y la palabra con una serif del sistema. Las chispas usan su
## PROPIO generador con semilla fija: si sacaran números de `Azar` (el determinista de la
## partida), ver la intro cambiaría la liga.

const SHADER_FONDO := preload("res://ui/entrada/intro_fondo.gdshader")
const SHADER_ORO := preload("res://ui/entrada/intro_oro.gdshader")

## LA PARTITURA, en segundos. Escudo que se traza → relleno y corona → letras una a una →
## destello y barrido de brillo → lema → fundido a negro. Total 4,75 s (el plan pide ≤ 5).
const T_TRAZO := 0.25
const D_TRAZO := 1.0
const T_RELLENO := 0.9
const D_RELLENO := 0.55
const T_MONOGRAMA := 1.05
const T_CORONA := 1.2
const T_LETRAS := 1.25
const PASO_LETRA := 0.085
const D_LETRA := 0.6
const T_DESTELLO := 2.42
const D_BARRIDO := 0.85
const T_LEMA := 2.7
const D_LEMA := 0.75
const T_SALIDA := 4.25
const D_SALIDA := 0.5
const DURACION := T_SALIDA + D_SALIDA

const N_BRASAS := 70
const N_CHISPAS := 110
## Proporción del escudo (alto / ancho) y de la corona (alto / ancho del escudo).
const ESCUDO_ALTO := 1.18
const CORONA := [Vector2(-0.24, 0.0), Vector2(0.24, 0.0), Vector2(0.27, -0.14), Vector2(0.13, -0.065),
	Vector2(0.0, -0.20), Vector2(-0.13, -0.065), Vector2(-0.27, -0.14)]

## Una capa de dibujo: llama a la función que le toca. Así cada capa puede llevar su
## material (el oro, la luz aditiva) sin una clase por capa.
class Lienzo extends Control:
	var pintar: Callable
	func _draw() -> void:
		if pintar.is_valid():
			pintar.call(self)

var _t := 0.0
## Negro extra encima de todo (lo sube el salto rápido de `intro.gd`).
var _velo_extra := 0.0
var _nombre := ""
var _lema := ""
var _fuente: Font
var _fuente_lema: Font
var _brillo: Texture2D
var _fondo: ColorRect
var _velo: ColorRect
var _capas: Array[Lienzo] = []
var _mat_fondo: ShaderMaterial
var _mat_oro_escudo: ShaderMaterial
var _mat_oro_letras: ShaderMaterial
## Partículas: [x0, velocidad, tamaño, fase, vaivén, parpadeo, tono] y
## [ángulo, velocidad, vida, tamaño, tono, origen_x].
var _brasas: Array[PackedFloat32Array] = []
var _chispas: Array[PackedFloat32Array] = []

# --- la maqueta (se recalcula solo si cambia el tamaño) ---
var _tam_previo := Vector2(-1, -1)
var _lienzo := Vector2(320, 180)  ## el tamaño con que se maquetó (nunca 0×0)
var _fs := 0.0            ## cuerpo de la palabra
var _fs_lema := 0.0
var _c := Vector2.ZERO    ## centro de la palabra (altura media de las mayúsculas)
var _cap := 0.0           ## alto de mayúscula
var _ancho_palabra := 0.0
var _xs: PackedFloat32Array = []      ## centro de cada letra
var _anchos: PackedFloat32Array = []
var _ce := Vector2.ZERO   ## centro del escudo
var _we := 0.0            ## ancho del escudo
var _medio := PackedVector2Array()    ## medio contorno (derecho), en unidades del ancho
var _medio_largo: PackedFloat32Array = []

func _material_oro() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER_ORO
	return m

## Una serif de rótulo, pedida al sistema por nombre (como las tipografías de Ajustes): la
## primera que exista. Cinzel/Trajan si alguien las tiene; Palatino y Georgia en Windows y
## macOS; Liberation/DejaVu Serif en Linux; «serif» siempre resuelve algo.
static func _serif(peso: int) -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Cinzel", "Trajan Pro", "Palatino Linotype", "Book Antiqua",
		"Palatino", "Georgia", "Times New Roman", "Liberation Serif", "DejaVu Serif", "serif"])
	f.font_weight = peso
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	## Mipmaps: las letras entran a casi el doble de tamaño y encogen; sin ellos, al
	## escalarse se ven dentadas.
	f.generate_mipmaps = true
	return f

## Un punto de luz redondo y suave, para chispas, brasas y destellos (se pinta en aditivo).
static func _textura_brillo() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.22, 0.55, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.12), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 96
	t.height = 96
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t

## Medio escudo (el lado derecho), de arriba al centro a la punta de abajo, en unidades del
## ancho: borde superior con una leve caída hacia el centro, costado recto y la curva hasta la
## punta. Se traza a la vez por los dos lados y los trazos se encuentran abajo.
static func _medio_contorno() -> PackedVector2Array:
	var h := ESCUDO_ALTO
	var p := PackedVector2Array()
	for i in 13:
		p.append(_bezier(Vector2(0.0, -0.46 * h), Vector2(0.28, -0.46 * h), Vector2(0.5, -0.5 * h), float(i) / 12.0))
	for i in range(1, 9):
		p.append(Vector2(0.5, lerpf(-0.5 * h, 0.02 * h, float(i) / 8.0)))
	for i in range(1, 29):
		p.append(_bezier(Vector2(0.5, 0.02 * h), Vector2(0.5, 0.33 * h), Vector2(0.0, 0.5 * h), float(i) / 28.0))
	return p

static func _bezier(a: Vector2, c: Vector2, b: Vector2, u: float) -> Vector2:
	return a.lerp(c, u).lerp(c.lerp(b, u), u)

static func _largos(p: PackedVector2Array) -> PackedFloat32Array:
	var l := PackedFloat32Array([0.0])
	for i in range(1, p.size()):
		l.append(l[i - 1] + p[i].distance_to(p[i - 1]))
	return l

func _sembrar_particulas() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 20261026
	for i in N_BRASAS:
		## Más brasas cerca del centro que en los bordes.
		var x0 := 0.5 + (r.randf() - 0.5) * (0.35 + 0.65 * r.randf())
		_brasas.append(PackedFloat32Array([x0, r.randf_range(0.035, 0.10), r.randf_range(1.0, 3.2),
			r.randf(), r.randf_range(0.3, 1.0), r.randf_range(2.0, 7.0), r.randf()]))
	for i in N_CHISPAS:
		_chispas.append(PackedFloat32Array([r.randf() * TAU, r.randf_range(3.0, 13.0) * (0.6 + 0.4 * r.randf()),
			r.randf_range(0.7, 1.7), r.randf_range(1.2, 3.4), r.randf(), r.randf() - 0.5]))

# --- maqueta --------------------------------------------------------------------

func _maquetar() -> void:
	if size == _tam_previo or _fuente == null:
		return
	_tam_previo = size
	## Antes de la primera maqueta el control mide 0×0: con eso el cuerpo de letra saldría 0
	## y la fuente protesta. Una pantalla de verdad nunca es tan pequeña.
	var s := size.max(Vector2(320, 180))
	_lienzo = s
	_fs = clampf(minf(s.x * 0.105, s.y * 0.15), 24.0, 240.0)
	_medir_palabra()
	## Que la palabra quepa siempre (un móvil en vertical, una traducción más larga).
	if _ancho_palabra > s.x * 0.86:
		_fs *= s.x * 0.86 / _ancho_palabra
		_medir_palabra()
	_cap = _fs * 0.70
	_we = _fs * 1.42 / ESCUDO_ALTO
	_fs_lema = maxf(11.0, _fs * 0.20)
	var corona := _we * 0.26
	var alto := corona + _we * ESCUDO_ALTO + _fs * 0.42 + _cap + _fs * 0.50 + _fs_lema
	var arriba := s.y * 0.5 - alto * 0.5 - s.y * 0.015
	_ce = Vector2(s.x * 0.5, arriba + corona + _we * ESCUDO_ALTO * 0.5)
	_c = Vector2(s.x * 0.5, _ce.y + _we * ESCUDO_ALTO * 0.5 + _fs * 0.42 + _cap * 0.5)

func _medir_palabra() -> void:
	_anchos.clear()
	_xs.clear()
	var hueco := _fs * 0.14
	var total := 0.0
	for ch in _nombre:
		var w := _fuente.get_char_size(ch.unicode_at(0), int(_fs)).x
		_anchos.append(w)
		total += w
	total += hueco * maxf(0.0, float(_nombre.length() - 1))
	_ancho_palabra = total
	var x := _lienzo.x * 0.5 - total * 0.5
	for w in _anchos:
		_xs.append(x + w * 0.5)
		x += w + hueco

# --- el tiempo ------------------------------------------------------------------

static func _tramo(t: float, t0: float, d: float) -> float:
	return clampf((t - t0) / d, 0.0, 1.0)

static func _sal_expo(x: float) -> float:
	return 1.0 if x >= 1.0 else 1.0 - pow(2.0, -10.0 * x)

## Sale pasándose un pelo y vuelve: el «pop» de la corona y del monograma.
static func _sal_atras(x: float) -> float:
	var c := 1.6
	return 1.0 + (c + 1.0) * pow(x - 1.0, 3.0) + c * pow(x - 1.0, 2.0)

## Cuánto lleva trazado el escudo (0..1). Salida cúbica y no exponencial: con la exponencial
## el contorno estaba hecho a los 0,4 s y las dos cabezas de luz apenas se veían bajar.
func _trazo() -> float:
	return 1.0 - pow(1.0 - _tramo(_t, T_TRAZO, D_TRAZO), 3.0)

func _destello() -> float:
	var a := _t - T_DESTELLO
	if a < -0.12:
		return 0.0
	if a < 0.0:
		return pow((a + 0.12) / 0.12, 2.0)
	return exp(-a * 3.2)

func _salida() -> float:
	return maxf(smoothstep(0.0, 1.0, _tramo(_t, T_SALIDA, D_SALIDA)), _velo_extra)

## Estado de la letra i en un instante: x = posición, y = alfa, z = escala; w = progreso.
func _letra(i: int, t: float) -> Vector4:
	var p := _tramo(t, T_LETRAS + float(i) * PASO_LETRA, D_LETRA)
	var e := _sal_expo(p)
	var x := _xs[i] + (_xs[i] - _c.x) * 0.45 * (1.0 - e)
	return Vector4(x, smoothstep(0.0, 0.45, p), lerpf(1.85, 1.0, e), p)

## Lo que cambia en cada fotograma: uniformes y repintado de las capas.
func _pintar() -> void:
	_maquetar()
	var vista := get_viewport_rect().size if is_inside_tree() else size
	var g := get_global_transform_with_canvas() if is_inside_tree() else Transform2D.IDENTITY
	_mat_fondo.set_shader_parameter("tiempo", _t)
	_mat_fondo.set_shader_parameter("aparicion", smoothstep(0.0, 1.0, _tramo(_t, 0.0, 0.9)))
	var d := _destello()
	_mat_fondo.set_shader_parameter("rayos", 0.55 * smoothstep(0.0, 1.0, _tramo(_t, 0.4, 1.6)) + 1.2 * d)
	_mat_fondo.set_shader_parameter("destello", d)
	_mat_fondo.set_shader_parameter("centro_rayos", _ce / _lienzo)
	_mat_fondo.set_shader_parameter("centro_destello", _c / _lienzo)
	_mat_fondo.set_shader_parameter("aspecto", _lienzo.x / _lienzo.y)
	var arriba_e := _ce.y - _we * (ESCUDO_ALTO * 0.5 + 0.22)
	_poner_caja(_mat_oro_escudo, g, vista, Vector2(_ce.x - _we * 0.5, arriba_e), Vector2(_ce.x + _we * 0.5, _ce.y + _we * ESCUDO_ALTO * 0.5))
	_poner_caja(_mat_oro_letras, g, vista, Vector2(_c.x - _ancho_palabra * 0.5, _c.y - _cap * 0.62), Vector2(_c.x + _ancho_palabra * 0.5, _c.y + _cap * 0.5))
	_mat_oro_letras.set_shader_parameter("barrido", _barrido(T_DESTELLO + 0.02))
	_mat_oro_escudo.set_shader_parameter("barrido", _barrido(T_DESTELLO + 0.22))
	_velo.color.a = _salida()
	for l in _capas:
		l.queue_redraw()

func _barrido(t0: float) -> float:
	if _t < t0 or _t > t0 + D_BARRIDO:
		return -9.0
	return lerpf(-0.3, 1.3, smoothstep(0.0, 1.0, _tramo(_t, t0, D_BARRIDO)))

func _poner_caja(m: ShaderMaterial, g: Transform2D, vista: Vector2, a: Vector2, b: Vector2) -> void:
	var pa := (g * a) / vista.max(Vector2.ONE)
	var pb := (g * b) / vista.max(Vector2.ONE)
	m.set_shader_parameter("caja", Vector4(pa.x, pa.y, pb.x, pb.y))
