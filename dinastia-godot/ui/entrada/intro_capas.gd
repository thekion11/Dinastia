extends "res://ui/entrada/intro_dibujo.gd"
## [Capa 2/3 de `intro.gd`] LAS CAPAS DE LA INTRO DE MARCA, de abajo arriba: fondo (shader),
## base (relleno del escudo y sombra de las letras), escudo en oro, palabra en oro, lema y luz
## aditiva (brasas, chispas, destellos), y el velo negro del fundido. Cada una es un `Lienzo`
## con su material; aquí está lo que pinta cada una en función de `_t`.

func _montar() -> void:
	_nombre = Idiomas.t("DINASTÍA")
	_lema = Idiomas.t("FÚTBOL MANAGER")
	_fuente = _serif(700)
	_fuente_lema = _serif(600)
	_brillo = _textura_brillo()
	_medio = _medio_contorno()
	_medio_largo = _largos(_medio)
	_sembrar_particulas()
	_fondo = ColorRect.new()
	_mat_fondo = ShaderMaterial.new()
	_mat_fondo.shader = SHADER_FONDO
	_fondo.material = _mat_fondo
	_agregar(_fondo)
	_mat_oro_escudo = _material_oro()
	_mat_oro_letras = _material_oro()
	_capa(_pintar_base, null)
	_capa(_pintar_escudo, _mat_oro_escudo)
	_capa(_pintar_palabra, _mat_oro_letras)
	_capa(_pintar_lema, null)
	var aditivo := CanvasItemMaterial.new()
	aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_capa(_pintar_luz, aditivo)
	_velo = ColorRect.new()
	_velo.color = Color.BLACK
	_agregar(_velo)

func _agregar(n: Control) -> void:
	n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(n)

func _capa(f: Callable, mat: Material) -> void:
	var l := Lienzo.new()
	l.pintar = f
	l.material = mat
	_agregar(l)
	_capas.append(l)

# --- las capas ------------------------------------------------------------------

## El contorno entero del escudo (cerrado), en píxeles, con escala `k` sobre su centro.
func _contorno(k: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for v in _medio:
		p.append(_ce + v * _we * k)
	for i in range(_medio.size() - 2, 0, -1):
		p.append(_ce + Vector2(-_medio[i].x, _medio[i].y) * _we * k)
	return p

## El primer `f` (0..1) del medio contorno, en píxeles; `lado` = 1 derecha, -1 izquierda.
func _medio_parcial(f: float, lado: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	var hasta := f * _medio_largo[_medio_largo.size() - 1]
	for i in _medio.size():
		var v := _medio[i]
		if _medio_largo[i] > hasta and i > 0:
			var u := (hasta - _medio_largo[i - 1]) / maxf(0.0001, _medio_largo[i] - _medio_largo[i - 1])
			v = _medio[i - 1].lerp(_medio[i], u)
			p.append(_ce + Vector2(v.x * lado, v.y) * _we)
			break
		p.append(_ce + Vector2(v.x * lado, v.y) * _we)
	return p

## Debajo del oro: el relleno esmeralda del escudo y la sombra de las letras.
func _pintar_base(c: Control) -> void:
	var a := smoothstep(0.0, 1.0, _tramo(_t, T_RELLENO, D_RELLENO))
	if a > 0.0:
		var pol := _contorno(1.0)
		var cols := PackedColorArray()
		var arriba := _ce.y - _we * ESCUDO_ALTO * 0.5
		for v in pol:
			var y := (v.y - arriba) / (_we * ESCUDO_ALTO)
			cols.append(Color(0.075, 0.20, 0.13, a).lerp(Color(0.02, 0.065, 0.042, a), y))
		c.draw_polygon(pol, cols)
		## Medio escudo en sombra: da volumen sin dibujar un bisel.
		var der := PackedVector2Array()
		for v in _medio:
			der.append(_ce + v * _we)
		c.draw_colored_polygon(der, Color(0, 0, 0, 0.22 * a))
	for i in _nombre.length():
		var l := _letra(i, _t)
		## La sombra llega al final, cuando la letra ya está casi en su sitio: con la letra
		## grande y medio transparente, una sombra entera la ensuciaba.
		var sombra := 0.55 * l.y * smoothstep(0.35, 0.9, l.w)
		if sombra > 0.0:
			_char(c, _fuente, i, Vector2(l.x, _y_letra(l)) + Vector2(0, _fs * 0.045), l.z, Color(0, 0, 0, sombra))

func _pintar_escudo(c: Control) -> void:
	var lw := maxf(1.5, _we * 0.030)
	var f := _trazo()
	## Cerrado de una pieza en cuanto se encuentran: dos medias líneas dejan una muesca en las juntas.
	if f >= 0.995:
		var todo := _contorno(1.0)
		todo.append(todo[0])
		c.draw_polyline(todo, Color.WHITE, lw, true)
	elif f > 0.0:
		c.draw_polyline(_medio_parcial(f, 1.0), Color.WHITE, lw, true)
		c.draw_polyline(_medio_parcial(f, -1.0), Color.WHITE, lw, true)
	var r := smoothstep(0.0, 1.0, _tramo(_t, T_RELLENO + 0.15, D_RELLENO))
	if r > 0.0:
		var dentro := _contorno(lerpf(0.94, 0.86, r))
		dentro.append(dentro[0])
		c.draw_polyline(dentro, Color(1, 1, 1, r * 0.85), lw * 0.45, true)
	## El monograma: la inicial de la marca, centrada en el escudo.
	var pm := _tramo(_t, T_MONOGRAMA, 0.55)
	if pm > 0.0:
		var fm := int(_we * ESCUDO_ALTO * 0.50)
		var ch := _nombre.substr(0, 1)
		var w := _fuente.get_char_size(ch.unicode_at(0), fm).x
		c.draw_set_transform(_ce + Vector2(0, -_we * 0.03), 0.0, Vector2.ONE * lerpf(0.6, 1.0, _sal_atras(pm)))
		c.draw_char(_fuente, Vector2(-w * 0.5, fm * 0.35), ch, fm, Color(1, 1, 1, smoothstep(0.0, 0.5, pm)))
		c.draw_set_transform_matrix(Transform2D.IDENTITY)
	## La corona, encima del escudo.
	var pc := _tramo(_t, T_CORONA, 0.5)
	if pc > 0.0:
		var base := Vector2(_ce.x, _ce.y - _we * (ESCUDO_ALTO * 0.5 + 0.05))
		var k := _we * lerpf(0.5, 1.0, _sal_atras(pc))
		var col := Color(1, 1, 1, smoothstep(0.0, 0.4, pc))
		var pol := PackedVector2Array()
		for v: Vector2 in CORONA:
			pol.append(base + v * k)
		c.draw_colored_polygon(pol, col)
		for i in [2, 4, 6]:
			c.draw_circle(base + (CORONA[i] as Vector2) * k, k * 0.03, col, true, -1.0, true)

func _pintar_palabra(c: Control) -> void:
	for i in _nombre.length():
		var l := _letra(i, _t)
		if l.y <= 0.0:
			continue
		## Estela: la misma letra un instante antes, tenue. Se lee como movimiento, no como copia.
		if l.w < 1.0:
			for k in [1, 2]:
				var e := _letra(i, _t - 0.035 * float(k))
				if e.y > 0.0:
					_char(c, _fuente, i, Vector2(e.x, _y_letra(e)), e.z, Color(1, 1, 1, e.y * 0.22 / float(k)))
		_char(c, _fuente, i, Vector2(l.x, _y_letra(l)), l.z, Color(1, 1, 1, l.y))

## La letra baja a su sitio desde un poco más arriba mientras se forma.
func _y_letra(l: Vector4) -> float:
	return _c.y - _fs * 0.20 * (1.0 - _sal_expo(l.w))

## Una letra de la palabra centrada en `centro` (centro de su mayúscula) y escalada `k`.
func _char(c: Control, f: Font, i: int, centro: Vector2, k: float, col: Color) -> void:
	c.draw_set_transform(centro, 0.0, Vector2(k, k))
	c.draw_char(f, Vector2(-_anchos[i] * 0.5, _cap * 0.5), _nombre[i], int(_fs), col)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

func _pintar_lema(c: Control) -> void:
	var p := _tramo(_t, T_LEMA, D_LEMA)
	if p <= 0.0:
		return
	var e := _sal_expo(p)
	var fs := int(_fs_lema)
	var hueco := _fs_lema * lerpf(0.95, 0.45, e)
	var anchos: Array[float] = []
	var total := 0.0
	for ch in _lema:
		var w := _fuente_lema.get_char_size(ch.unicode_at(0), fs).x
		anchos.append(w)
		total += w + hueco
	total -= hueco
	if total > _lienzo.x * 0.8:
		hueco = maxf(0.0, hueco - (total - _lienzo.x * 0.8) / maxf(1.0, float(_lema.length() - 1)))
		total = _lienzo.x * 0.8
	var y := _c.y + _cap * 0.5 + _fs * 0.50 + _fs_lema
	var col := Color(0.86, 0.80, 0.62, smoothstep(0.0, 0.7, p))
	var x := _lienzo.x * 0.5 - total * 0.5
	for i in _lema.length():
		c.draw_char(_fuente_lema, Vector2(x, y), _lema[i], fs, col)
		x += anchos[i] + hueco
	## Dos filetes de oro que se abren hacia fuera, finos y desvanecidos en la punta.
	var largo := lerpf(0.0, minf(_lienzo.x * 0.12, _fs * 1.6), e)
	var ym := y - _fs_lema * 0.36
	var dentro := total * 0.5 + _fs_lema * 0.9
	for lado in [-1.0, 1.0]:
		var a := Vector2(_lienzo.x * 0.5 + lado * dentro, ym)
		var b := Vector2(_lienzo.x * 0.5 + lado * (dentro + largo), ym)
		var g := maxf(0.6, _fs_lema * 0.06)
		var oro := Color(0.86, 0.66, 0.28, col.a)
		var fin := Color(0.86, 0.66, 0.28, 0.0)
		c.draw_polygon(PackedVector2Array([a + Vector2(0, -g), b + Vector2(0, -g), b + Vector2(0, g), a + Vector2(0, g)]),
			PackedColorArray([oro, fin, fin, oro]))

## Encima de todo, en aditivo: brasas, cabezas del trazo, chispas y destellos.
func _pintar_luz(c: Control) -> void:
	var s := _lienzo
	var esc := _fs / 110.0
	var d := _destello()
	var viva := smoothstep(0.0, 1.0, _tramo(_t, 0.15, 0.9))
	for b in _brasas:
		var y := s.y * (1.08 - fmod(b[3] + _t * b[1], 1.16))
		var x := b[0] * s.x + sin(_t * 0.9 + b[3] * TAU) * b[4] * s.y * 0.02
		var a := viva * (0.35 + 0.65 * (0.5 + 0.5 * sin(_t * b[5] + b[3] * 20.0))) * smoothstep(0.0, s.y * 0.3, y)
		var r := b[2] * esc * (1.0 + 0.8 * d) * 2.2
		_punto(c, Vector2(x, y), r, Color(1.0, 0.62 + 0.18 * b[6], 0.25, a * 0.5))
	## Las cabezas del trazo del escudo: dos puntos de luz que bajan y se encuentran.
	var ft := _tramo(_t, T_TRAZO, D_TRAZO)
	if ft > 0.0 and ft < 1.0:
		var f := _trazo()
		var fuerza := 1.0 - smoothstep(0.9, 1.0, ft)
		for lado in [1.0, -1.0]:
			var tramo := _medio_parcial(f, lado)
			var cab := tramo[tramo.size() - 1]
			_punto(c, cab, _we * 0.20, Color(1.0, 0.75, 0.35, 0.55 * fuerza))
			_punto(c, cab, _we * 0.05, Color(1.0, 0.95, 0.85, 0.9 * fuerza))
	## La letra que se está formando brilla con luz propia (en aditivo) y se apaga al
	## asentarse: sin esto, grande y medio transparente sobre el verde, se veía color oliva.
	for i in _nombre.length():
		var l := _letra(i, _t)
		if l.y > 0.0 and l.w < 1.0:
			_char(c, _fuente, i, Vector2(l.x, _y_letra(l)), l.z, Color(1.0, 0.74, 0.34, l.y * 0.45 * (1.0 - _sal_expo(l.w))))
	## Cada letra, al asentarse, deja un brillo breve.
	for i in _nombre.length():
		var tau := _t - (T_LETRAS + float(i) * PASO_LETRA + D_LETRA * 0.30)
		if tau > 0.0 and tau < 0.45:
			_punto(c, Vector2(_xs[i], _c.y), _fs * 0.9, Color(1.0, 0.78, 0.40, 0.22 * pow(1.0 - tau / 0.45, 2.0)))
	## El destello: halo, raya horizontal (como la de un objetivo de cine) y su núcleo.
	if d > 0.01:
		_punto(c, _c, _fs * 3.2, Color(1.0, 0.72, 0.35, 0.35 * d))
		_raya(c, _c, Vector2(s.x * (0.75 + 0.45 * d), _fs * 0.10), Color(1.0, 0.78, 0.45, 0.55 * d))
		_raya(c, _c, Vector2(s.x * 0.55, _fs * 0.03), Color(1.0, 0.96, 0.88, 0.9 * d))
	_pintar_chispas(c)
	## Un último guiño de luz en la punta de la última letra, cuando acaba el barrido.
	var tg := _tramo(_t, T_DESTELLO + D_BARRIDO - 0.1, 0.7)
	if tg > 0.0 and tg < 1.0 and not _xs.is_empty():
		var en := sin(tg * PI)
		var pg := Vector2(_xs[_xs.size() - 1] + _anchos[_anchos.size() - 1] * 0.32, _c.y - _cap * 0.5)
		_raya(c, pg, Vector2(_fs * 0.9 * en, _fs * 0.035), Color(1, 0.95, 0.85, 0.9 * en))
		_raya(c, pg, Vector2(_fs * 0.035, _fs * 0.6 * en), Color(1, 0.95, 0.85, 0.9 * en))
		_punto(c, pg, _fs * 0.35 * en, Color(1.0, 0.8, 0.45, 0.5 * en))

func _pintar_chispas(c: Control) -> void:
	var tau := _t - T_DESTELLO
	if tau < 0.0:
		return
	const ROCE := 2.6
	for ch in _chispas:
		if tau > ch[2]:
			continue
		var dir := Vector2(cos(ch[0]), sin(ch[0]) * 0.62)
		var v := ch[1] * _fs
		var origen := _c + Vector2(ch[5] * _ancho_palabra * 0.8, 0.0)
		var p := origen + dir * (v / ROCE) * (1.0 - exp(-ROCE * tau)) + Vector2(0, 0.35 * _fs * tau * tau)
		var vel := dir * v * exp(-ROCE * tau) + Vector2(0, 0.7 * _fs * tau)
		var a := pow(1.0 - tau / ch[2], 1.6)
		var tam := ch[3] * _fs / 110.0
		var col := Color(1.0, 0.70 + 0.25 * ch[4], 0.30 + 0.3 * ch[4], a)
		## La cola, corta y más tenue que la cabeza: se lee como chispa y no como confeti.
		var cola := vel * 0.016
		if cola.length() > tam:
			c.draw_line(p - cola, p, Color(col.r, col.g, col.b, a * 0.6), maxf(1.0, tam * 0.55), true)
		_punto(c, p, tam * 1.1, Color(1.0, 0.95, 0.8, a))
		_punto(c, p, tam * 3.0, Color(col.r, col.g * 0.85, col.b * 0.6, a * 0.45))

func _punto(c: Control, p: Vector2, r: float, col: Color) -> void:
	c.draw_texture_rect(_brillo, Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, col)

func _raya(c: Control, p: Vector2, tam: Vector2, col: Color) -> void:
	c.draw_texture_rect(_brillo, Rect2(p - tam * 0.5, tam), false, col)
