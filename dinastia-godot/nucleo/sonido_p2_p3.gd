extends "res://nucleo/sonido_p2_p2.gd"
## [Capa 4/7 de `sonido.gd`] recetas de la grada, el clima y la ciudad

# --- La grada ----------------------------------------------------------------------------

## El ambiente de fondo. Ruido rosa muy filtrado y muy largo.
func _receta_murmullo(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(3.00, 200.0, 900.0, 0.05)

func _receta_ovacion(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(2.20 * largo, 500.0, 2200.0, 0.16)

## El bombo de la barra: cuatro golpes graves con su tiempo. Es el
## sonido que hace que un estadio suene lleno aunque no haya nadie.
func _receta_tambor(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.20)
	for i in 8:
		_mezclar(m, _ruido(0.16, 90.0, 55.0, 0.16 if i % 2 == 0 else 0.09), float(i) * 0.26)
		_mezclar(m, _tono(62.0 * alto, 0.20, 0.10, "seno"), float(i) * 0.26)
	return m

## Las tres notas de trompeta de tribuna. Desafinada a propósito: en
## una grada nadie afina.
func _receta_trompeta(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.30)
	_mezclar(m, _tono(392.0 * alto * 1.01, 0.30, 0.055, "sierra"))
	_mezclar(m, _tono(523.0 * alto * 0.99, 0.30, 0.055, "sierra"), 0.28)
	_mezclar(m, _tono(659.0 * alto, 0.55, 0.060, "sierra"), 0.56)
	return m

## El silbido de la grada contra los suyos. Ruido agudo y largo, sin
## nada de tono: no hay melodía en una pitada.
func _receta_abucheo(_alto: float, largo: float) -> PackedFloat32Array:
	var m := _ruido(2.20 * largo, 1900.0, 2600.0, 0.13)
	_mezclar(m, _ruido(2.00, 700.0, 500.0, 0.06), 0.10)
	return m

## Aplauso corto y educado. Es el de "buen intento", no el de gol.
func _receta_aplauso(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(0.90 * largo, 1400.0, 2000.0, 0.09)

## El cántico de tribuna, ya solo: existía dentro de "trofeo" y no se
## podía tirar por su cuenta.
func _receta_cantico(_alto: float, _largo: float) -> PackedFloat32Array:
	return _cantico(1.0)

## El siseo de una bengala: ruido agudo constante, sin ataque y sin
## final —se enciende y ya está—.
func _receta_bengala(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(2.60 * largo, 4200.0, 3400.0, 0.055)

## Fondo de partido pasado por agua. Muy filtrado y muy plano: si
## tuviera forma, se notaría que se repite.
func _receta_lluvia_ambiente(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(3.20, 2600.0, 3000.0, 0.045)

## El eco de un vestuario vacío: un golpe de puerta y el zumbido de
## los fluorescentes.
func _receta_vestuario(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.80)
	_mezclar(m, _ruido(0.22, 240.0, 90.0, 0.10))
	_mezclar(m, _tono(100.0, 1.60, 0.018, "seno"), 0.05)
	_mezclar(m, _tono(150.0, 1.60, 0.010, "seno"), 0.05)
	return m

## Las cámaras de la sala de prensa: seis disparos irregulares.
func _receta_flashes(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.30)
	for i in 7:
		_mezclar(m, _ruido(0.045, 5200.0, 2200.0, 0.05), float(i) * 0.17 + float(i % 3) * 0.03)
	return m

## Un barrido de intensidad, izquierda a derecha: ruido que crece
## y decrece en oleada.
func _receta_ola_mexicana(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.40)
	for i3 in 6:
		_mezclar(m, _ruido(0.55, 1200.0, 2000.0, 0.10), float(i3) * 0.30)
	return m

func _receta_silbido_agudo(alto: float, largo: float) -> PackedFloat32Array:
	return _tono(3200.0 * alto, 0.60 * largo, 0.08, "seno")

func _receta_coro_rival(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _cantico(0.8)
	_mezclar(m, _ruido(0.30, 1800.0, 2200.0, 0.04))
	return m

func _receta_pitos_arbitro(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(1.60 * largo, 2200.0, 2600.0, 0.12)

func _receta_bocina_vuvuzela(alto: float, largo: float) -> PackedFloat32Array:
	var m := _tono(233.0 * alto, 1.80 * largo, 0.10, "sierra")
	_mezclar(m, _tono(235.5 * alto, 1.80 * largo, 0.08, "sierra"))
	return m

func _receta_tambor_visitante(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.80)
	for i4 in 6:
		_mezclar(m, _ruido(0.14, 85.0, 50.0, 0.13), float(i4) * 0.30)
	return m

func _receta_suspiro_grada(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(0.60 * largo, 900.0, 300.0, 0.09)

func _receta_alarido_atajada(_alto: float, largo: float) -> PackedFloat32Array:
	var m := _ruido(1.20 * largo, 500.0, 2000.0, 0.14)
	_mezclar(m, _cantico(0.6), 0.3)
	return m

func _receta_tension_publico(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(2.80, 250.0, 700.0, 0.06)

func _receta_silbidos_impaciencia(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(1.80 * largo, 2000.0, 2400.0, 0.09)

func _receta_ultimo_minuto(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.40)
	var t0u := 0.0
	var paso_u := 0.30
	while t0u < 1.3:
		_mezclar(m, _tono(1900.0 * alto, 0.03, 0.04, "cuadrada"), t0u)
		t0u += paso_u
		paso_u = maxf(0.08, paso_u * 0.85)
	return m

func _receta_descuento_anunciado(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.70)
	_mezclar(m, _tono(880.0 * alto, 0.10, 0.04, "seno"))
	_mezclar(m, _tono(880.0 * alto, 0.10, 0.04, "seno"), 0.30)
	return m

func _receta_grada_de_pie(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(2.00 * largo, 500.0, 2200.0, 0.16)

func _receta_bufanda_alzada(_alto: float, _largo: float) -> PackedFloat32Array:
	return _cantico(1.0)

func _receta_pancarta_desplegada(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(1.20 * largo, 1400.0, 400.0, 0.05)

func _receta_humo_bengala(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(1.80 * largo, 3800.0, 3000.0, 0.045)

func _receta_cornetin(alto: float, largo: float) -> PackedFloat32Array:
	return _tono(587.0 * alto, 0.40 * largo, 0.07, "sierra")

func _receta_campanas_iglesia(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.0)
	for hz4 in [523.0, 659.0]:
		_mezclar(m, _tono(float(hz4) * alto, 1.80, 0.05, "seno"))
	return m

func _receta_animador_grada(alto: float, largo: float) -> PackedFloat32Array:
	var m := _tono(500.0 * alto, 0.30 * largo, 0.06, "cuadrada")
	_mezclar(m, _ruido(0.40, 1400.0, 2000.0, 0.05), 0.28)
	return m

func _receta_eco_estadio(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.2)
	_mezclar(m, _ruido(0.30, 900.0, 300.0, 0.10))
	_mezclar(m, _ruido(0.30, 900.0, 300.0, 0.04), 0.35)
	return m

func _receta_multitud_entrando(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(3.00, 400.0, 900.0, 0.06)

func _receta_multitud_saliendo(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(3.00, 700.0, 350.0, 0.06)

# --- Clima -------------------------------------------------------------------------------

func _receta_lluvia_fuerte(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(3.20, 2800.0, 3200.0, 0.08)

func _receta_viento_fuerte(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(3.20, 300.0, 700.0, 0.07)

func _receta_trueno(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(1.60 * largo, 120.0, 40.0, 0.20)

func _receta_niebla_ambiente(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(3.00, 200.0, 500.0, 0.04)

func _receta_calor_extremo(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(2.40, 1200.0, 1600.0, 0.02)

func _receta_frio_extremo(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(1.60 * largo, 400.0, 900.0, 0.03)

func _receta_noche_estadio(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(3.20, 100.0, 300.0, 0.04)

func _receta_dia_soleado(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(2.60, 800.0, 1400.0, 0.03)

# --- La ciudad: recorridos a pie y coches ------------------------------------------------

## Puerta corredera de cristal: el soplido de las hojas (ruido que
## baja de agudo a grave) y un golpe sordo al llegar al tope.
func _receta_puerta(alto: float, largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.75 * largo)
	_mezclar(m, _ruido(0.6 * largo, 2600.0 * alto, 500.0, 0.10))
	_mezclar(m, _tono(95.0 * alto, 0.12, 0.10, "seno"), 0.58 * largo)
	_mezclar(m, _ruido(0.08, 900.0, 300.0, 0.06), 0.58 * largo)
	return m

## Un paso de suela sobre baldosa: golpe grave muy corto y un roce.
func _receta_paso(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(120.0 * alto, 0.07, 0.07, "seno")
	_mezclar(m, _ruido(0.06, 1800.0 * alto, 600.0, 0.05))
	return m

## Golpe de chapa: un ruido grave y seco, el crujido de la carrocería y
## un tintineo metálico que se apaga.
func _receta_choque_coche(alto: float, largo: float) -> PackedFloat32Array:
	var m := _ruido(0.32 * largo, 60.0, 700.0, 0.55)
	_mezclar(m, _ruido(0.18 * largo, 900.0, 3200.0, 0.18), 0.02)
	_mezclar(m, _tono(420.0 * alto, 0.40 * largo, 0.10, "seno"), 0.05)
	return m

## Dos notas a la vez (la bocina de dos tonos de un coche).
func _receta_claxon(alto: float, largo: float) -> PackedFloat32Array:
	var m := _tono(415.0 * alto, 0.45 * largo, 0.16, "cuadrada")
	_mezclar(m, _tono(523.0 * alto, 0.45 * largo, 0.12, "cuadrada"))
	return m
