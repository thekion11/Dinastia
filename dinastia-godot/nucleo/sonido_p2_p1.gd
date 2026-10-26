extends "res://nucleo/sonido_p1.gd"
## [Capa 2/7 de `sonido.gd`] recetas del partido: campo, árbitro y estilo de juego

# --- El partido: silbatos, remates y paradas ---------------------------------------------

## Dos armónicos muy juntos batiendo entre sí: es lo que hace que un
## silbato suene a silbato y no a pitido de horno.
func _receta_silbato(alto: float, largo: float) -> PackedFloat32Array:
	var m := _tono(2650.0 * alto, 0.34 * largo, 0.30, "seno")
	_mezclar(m, _tono(3980.0 * alto, 0.34 * largo, 0.16, "seno"))
	_mezclar(m, _ruido(0.34 * largo, 2400.0, 3600.0, 0.05))
	return m

func _receta_pitido_final(alto: float, largo: float) -> PackedFloat32Array:
	var m := _tono(2650.0 * alto, 1.10 * largo, 0.30, "seno")
	_mezclar(m, _tono(3980.0 * alto, 1.10 * largo, 0.16, "seno"))
	return m

## El pitido de arranque: uno solo, más largo que el de falta, con el
## murmullo de la grada subiendo por detrás.
func _receta_saque_inicial(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.40)
	_mezclar(m, _tono(2650.0 * alto, 0.50, 0.26, "seno"))
	_mezclar(m, _tono(3980.0 * alto, 0.50, 0.13, "seno"))
	_mezclar(m, _ruido(1.20, 300.0, 1400.0, 0.14), 0.18)
	return m

func _receta_medio_tiempo(alto: float, largo: float) -> PackedFloat32Array:
	var m := _tono(2650.0 * alto, 0.60 * largo, 0.28, "seno")
	_mezclar(m, _tono(3980.0 * alto, 0.60 * largo, 0.14, "seno"))
	return m

func _receta_reanudacion(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.0)
	_mezclar(m, _tono(2650.0 * alto, 0.30, 0.24, "seno"))
	_mezclar(m, _ruido(0.80, 300.0, 900.0, 0.08), 0.10)
	return m

func _receta_roja(alto: float, largo: float) -> PackedFloat32Array:
	var m := _tono(150.0 * alto, 0.35 * largo, 0.09, "sierra")
	_mezclar(m, _ruido(0.80 * largo, 900.0, 300.0, 0.08), 0.10)
	return m

func _receta_amarilla(alto: float, largo: float) -> PackedFloat32Array:
	return _tono(320.0 * alto, 0.18 * largo, 0.06, "cuadrada")

## Amarilla + roja pegadas: se oye la primera y se entiende la
## segunda antes de leer nada.
func _receta_segunda_amarilla(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.90)
	_mezclar(m, _tono(320.0 * alto, 0.16, 0.055, "cuadrada"))
	_mezclar(m, _tono(150.0 * alto, 0.34, 0.085, "sierra"), 0.22)
	_mezclar(m, _ruido(0.60, 900.0, 300.0, 0.07), 0.26)
	return m

## Golpe seco y metálico: un tono alto que se apaga en nada.
func _receta_poste(alto: float, largo: float) -> PackedFloat32Array:
	var m := _tono(1180.0 * alto, 0.30 * largo, 0.20, "seno")
	_mezclar(m, _tono(2360.0 * alto, 0.16 * largo, 0.08, "seno"))
	return m

## Como el poste pero más agudo y con más cola: el larguero canta.
func _receta_travesano(alto: float, largo: float) -> PackedFloat32Array:
	var m := _tono(1560.0 * alto, 0.45 * largo, 0.20, "seno")
	_mezclar(m, _tono(3120.0 * alto, 0.24 * largo, 0.07, "seno"))
	_mezclar(m, _ruido(0.50, 600.0, 900.0, 0.06), 0.06)
	return m

## Como "poste" pero DOS golpes seguidos -la mala suerte redoblada.
func _receta_palo_doble(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.60)
	_mezclar(m, _tono(1180.0 * alto, 0.20, 0.18, "seno"))
	_mezclar(m, _tono(1180.0 * alto, 0.20, 0.16, "seno"), 0.22)
	return m

## El "uuuh" de la grada cuando la pelota pasa cerca. `nombre` no
## lleva variacion de altura por jugada -eso lo pone el navegador
## con R(0,140) en cada disparo, aqui ya lo cubren las variantes-.
func _receta_ocasion(alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(0.72 * largo, 630.0 * alto, 1008.0 * alto, 0.10)

## Manotazo del arquero mas, casi siempre, el aplauso de la grada
## detras -el HTML lo tiraba solo un 45% de las veces; aqui suena
## siempre porque la variedad ya la dan las cuatro variantes-.
func _receta_atajada(alto: float, largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.68 * largo)
	_mezclar(m, _ruido(0.40 * largo, 800.0 * alto, 500.0, 0.07))
	_mezclar(m, _tono(300.0 * alto, 0.10, 0.03, "seno"))
	_mezclar(m, _ruido(0.50, 520.0, 900.0, 0.05), 0.18)
	return m

func _receta_atajada_punos(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.40)
	_mezclar(m, _ruido(0.14, 700.0, 200.0, 0.14))
	_mezclar(m, _tono(150.0 * alto, 0.10, 0.05, "seno"))
	return m

func _receta_atajada_pies(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.35)
	_mezclar(m, _ruido(0.10, 900.0, 400.0, 0.10))
	_mezclar(m, _tono(250.0 * alto, 0.12, 0.04, "seno"), 0.03)
	return m

func _receta_falta(alto: float, largo: float) -> PackedFloat32Array:
	var m := _ruido(0.22 * largo, 2400.0 * alto, 2300.0, 0.085)
	_mezclar(m, _tono(220.0 * alto, 0.12, 0.025, "seno"), 0.06)
	return m

func _receta_corner(alto: float, largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.65 * largo)
	_mezclar(m, _ruido(0.18 * largo, 2300.0 * alto, 2200.0, 0.07))
	_mezclar(m, _ruido(0.45, 520.0, 780.0, 0.05), 0.20)
	return m

## LA TENSIÓN. No es un golpe: es un silencio que se llena. Un
## redoble grave que crece y no resuelve —lo que resuelve es lo que
## suene después, "gol" o "atajada"—.
func _receta_penal(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.80)
	for i in 26:
		var t0p := float(i) * 0.065
		_mezclar(m, _ruido(0.05, 110.0, 70.0, 0.03 + float(i) * 0.0035), t0p)
	_mezclar(m, _tono(98.0 * alto, 1.60, 0.05, "sierra"))
	return m

## El "ooooh" que se corta en seco y el golpe del poste que no fue.
func _receta_penal_fallado(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.20)
	_mezclar(m, _ruido(0.55, 700.0, 1100.0, 0.13))
	_mezclar(m, _ruido(0.60, 420.0, 120.0, 0.09), 0.45)
	_mezclar(m, _tono(174.0 * alto, 0.40, 0.05, "sierra"), 0.40)
	return m

## El silbido del balón y el suspiro corto de la grada.
func _receta_remate_fuera(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.80)
	_mezclar(m, _ruido(0.20, 3000.0, 800.0, 0.06))
	_mezclar(m, _ruido(0.55, 560.0, 300.0, 0.07), 0.16)
	return m

## El VAR: tres pitidos electrónicos iguales, fríos, sin grada. Es a
## propósito la cosa menos futbolística del catálogo.
func _receta_var(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.90)
	for i in 3:
		_mezclar(m, _tono(1400.0 * alto, 0.10, 0.05, "cuadrada"), float(i) * 0.22)
	return m

func _receta_var_anulado(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.20)
	for i2 in 3:
		_mezclar(m, _tono(1400.0 * alto, 0.10, 0.05, "cuadrada"), float(i2) * 0.22)
	_mezclar(m, _tono(180.0 * alto, 0.50, 0.06, "sierra"), 0.70)
	return m

## Un pitido corto y el murmullo de protesta: nadie aplaude un fuera
## de juego.
func _receta_fuera_de_juego(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.90)
	_mezclar(m, _ruido(0.16, 2400.0, 2300.0, 0.075))
	_mezclar(m, _ruido(0.65, 380.0, 220.0, 0.07), 0.14)
	return m

## Los últimos minutos: un tictac que se acelera. No avisa de nada
## que no sepas; lo que hace es que se te note en el cuerpo.
func _receta_cronometro(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.40)
	var t0c := 0.0
	var paso_c := 0.34
	while t0c < 2.2:
		_mezclar(m, _tono(1700.0 * alto, 0.03, 0.045, "cuadrada"), t0c)
		t0c += paso_c
		paso_c = maxf(0.10, paso_c * 0.88)
	return m

# --- Más momentos de partido (tercera tanda) ---------------------------------------------

## TERCERA TANDA (21-9-2026): de 65 a ~200 sonidos, a pedido del usuario. Mismo
## instrumental de siempre (osciladores + ruido filtrado), recetas más breves que las
## de las dos primeras tandas a propósito -son 135 nuevas de una vez-, pero cada una es
## una composición propia, no una copia con el nombre cambiado.

func _receta_saque_banda(alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(0.18 * largo, 1200.0 * alto, 900.0, 0.05)

func _receta_saque_puerta(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(400.0 * alto, 0.14, 0.05, "seno")
	_mezclar(m, _ruido(0.30, 700.0, 300.0, 0.04), 0.05)
	return m

func _receta_fuera_de_banda(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(0.30 * largo, 1500.0, 600.0, 0.06)

func _receta_rebote(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(900.0 * alto, 0.06, 0.10, "seno")
	_mezclar(m, _tono(700.0 * alto, 0.05, 0.07, "seno"), 0.05)
	return m

func _receta_mano_penal(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.60)
	_mezclar(m, _tono(1400.0 * alto, 0.10, 0.05, "cuadrada"))
	_mezclar(m, _ruido(0.40, 900.0, 300.0, 0.07), 0.12)
	return m

## El "uy" desconfiado de la grada: ruido corto y disonante.
func _receta_simulacion(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.50)
	_mezclar(m, _ruido(0.35, 800.0, 600.0, 0.08))
	_mezclar(m, _tono(310.0 * alto, 0.20, 0.03, "sierra"), 0.05)
	return m

func _receta_calentamiento(_alto: float, largo: float) -> PackedFloat32Array:
	var m := _ruido(1.80 * largo, 400.0, 700.0, 0.05)
	_mezclar(m, _tono(300.0, 0.10, 0.03, "seno"), 0.40)
	return m

func _receta_salida_tunel(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.2)
	_mezclar(m, _ruido(2.00, 300.0, 1400.0, 0.16))
	return m

func _receta_presentacion_alineaciones(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.6)
	_mezclar(m, _tono(440.0 * alto, 0.16, 0.05, "seno"))
	_mezclar(m, _tono(554.0 * alto, 0.16, 0.05, "seno"), 0.14)
	_mezclar(m, _tono(659.0 * alto, 0.40, 0.06, "seno"), 0.28)
	return m

func _receta_despeje(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(500.0 * alto, 0.10, 0.10, "seno")
	_mezclar(m, _ruido(0.14, 700.0, 300.0, 0.05))
	return m

func _receta_entrada_dura(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.40)
	_mezclar(m, _ruido(0.16, 300.0, 100.0, 0.13))
	_mezclar(m, _tono(140.0 * alto, 0.12, 0.04, "sierra"), 0.02)
	return m

func _receta_recuperacion_balon(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(700.0 * alto, 0.08, 0.07, "seno")

func _receta_pase_largo(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(0.35 * largo, 2200.0, 500.0, 0.06)

func _receta_control_balon(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(600.0 * alto, 0.05, 0.06, "seno")

# --- Árbitro y disciplina ----------------------------------------------------------------

func _receta_tarjeta_banco(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(320.0 * alto, 0.20, 0.06, "cuadrada")
	_mezclar(m, _ruido(0.30, 900.0, 300.0, 0.05), 0.10)
	return m

func _receta_protesta_jugador(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(1.20 * largo, 500.0, 300.0, 0.08)

func _receta_protesta_masiva(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(2.20 * largo, 500.0, 300.0, 0.14)

func _receta_amonestacion_verbal(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(500.0 * alto, 0.14, 0.04, "seno")

func _receta_tiempo_anadido(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.60)
	_mezclar(m, _tono(1400.0 * alto, 0.08, 0.05, "cuadrada"))
	return m

func _receta_ventaja(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(700.0 * alto, 0.10, 0.04, "seno")
	_mezclar(m, _tono(900.0 * alto, 0.10, 0.03, "seno"), 0.06)
	return m

func _receta_libre_indirecto(alto: float, largo: float) -> PackedFloat32Array:
	return _tono(2650.0 * alto, 0.20 * largo, 0.20, "seno")

func _receta_mano_fuera_area(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(1400.0 * alto, 0.08, 0.05, "cuadrada")

func _receta_fuera_terreno_juego(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(400.0 * alto, 0.10, 0.04, "seno")

func _receta_calambre(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.50)
	_mezclar(m, _ruido(0.20, 300.0, 100.0, 0.09))
	_mezclar(m, _tono(160.0 * alto, 0.30, 0.04, "sierra"), 0.06)
	return m

# --- Estilo de juego ---------------------------------------------------------------------

func _receta_pase_corto(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(700.0 * alto, 0.04, 0.05, "seno")

func _receta_centro(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(0.30 * largo, 2000.0, 700.0, 0.06)

func _receta_regate(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.30)
	_mezclar(m, _tono(600.0 * alto, 0.05, 0.04, "seno"))
	_mezclar(m, _tono(750.0 * alto, 0.05, 0.04, "seno"), 0.08)
	return m

func _receta_tiro_potente(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(0.20 * largo, 3200.0, 700.0, 0.08)

func _receta_tiro_flojo(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(0.16 * largo, 1400.0, 600.0, 0.04)

func _receta_paso_atras(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(500.0 * alto, 0.06, 0.04, "seno")

func _receta_presion_alta(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(0.40 * largo, 700.0, 300.0, 0.07)

func _receta_contragolpe(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.60)
	_mezclar(m, _tono(700.0 * alto, 0.06, 0.05, "seno"))
	_mezclar(m, _ruido(0.40, 2200.0, 700.0, 0.06), 0.05)
	return m

func _receta_posesion_larga(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(2.00, 300.0, 600.0, 0.09)

func _receta_cambio_ritmo(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(500.0 * alto, 0.10, 0.04, "seno")
	_mezclar(m, _tono(700.0 * alto, 0.10, 0.04, "seno"), 0.10)
	return m
