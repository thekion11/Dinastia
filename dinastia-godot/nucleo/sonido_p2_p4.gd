extends "res://nucleo/sonido_p2_p3.gd"
## [Capa 5/7 de `sonido.gd`] recetas de la gestión y la carrera

# --- La gestión: plantilla, contratos y dinero -------------------------------------------

## Cinco de estos (lesion, cambio, fichaje, ascenso y descenso, este último en la capa de
## títulos) el HTML nunca los tuvo -no hay `sfx('lesion')` ni nada parecido en `juego.js`-:
## antes esos momentos sonaban a silencio. Son composición propia con el mismo
## instrumental de siempre (osciladores + ruido filtrado), no un port de nada.

## Un golpe sordo y una caida de dos notas: preocupado, no tragico.
func _receta_lesion(alto: float, largo: float) -> PackedFloat32Array:
	var m := _ruido(0.35 * largo, 260.0 * alto, 90.0, 0.10)
	_mezclar(m, _tono(200.0 * alto, 0.28 * largo, 0.07, "sierra"), 0.02)
	_mezclar(m, _tono(140.0 * alto, 0.30 * largo, 0.05, "sierra"), 0.16)
	return m

## Dos pitidos de pizarra, neutros: ni buena ni mala noticia.
func _receta_cambio(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(700.0 * alto, 0.09, 0.05, "cuadrada")
	_mezclar(m, _tono(900.0 * alto, 0.09, 0.05, "cuadrada"), 0.12)
	return m

## Un arpegio corto que sube mas un brillo de ruido agudo: "trato
## cerrado". Mas pequeno que "trofeo" -esto pasa cada semana, no
## una vez al año-.
func _receta_fichaje(alto: float, largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.60 * largo)
	_mezclar(m, _tono(440.0 * alto, 0.12 * largo, 0.05, "seno"))
	_mezclar(m, _tono(554.0 * alto, 0.12 * largo, 0.05, "seno"), 0.10)
	_mezclar(m, _tono(659.0 * alto, 0.22 * largo, 0.06, "seno"), 0.20)
	_mezclar(m, _ruido(0.40 * largo, 1800.0, 2600.0, 0.04), 0.02)
	return m

## El bolígrafo y el sello: firmar tiene que sonar a papel, no a
## fanfarria. La fanfarria ya la tiene "fichaje".
func _receta_contrato(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.70)
	_mezclar(m, _ruido(0.30, 3200.0, 1400.0, 0.035))
	_mezclar(m, _ruido(0.10, 300.0, 120.0, 0.11), 0.34)
	_mezclar(m, _tono(523.0 * alto, 0.22, 0.030, "seno"), 0.40)
	return m

## Te echaron. Una nota grave, larga y sola. Nada de ruido de grada:
## esto no pasa en el campo.
func _receta_despido(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.20)
	_mezclar(m, _tono(87.0 * alto, 1.90, 0.09, "sierra"))
	_mezclar(m, _tono(131.0 * alto, 1.10, 0.045, "seno"), 0.30)
	return m

## Caja registradora corta: dos monedas que suben.
func _receta_dinero_entra(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.32)
	_mezclar(m, _tono(1320.0 * alto, 0.09, 0.045, "seno"))
	_mezclar(m, _tono(1980.0 * alto, 0.16, 0.038, "seno"), 0.07)
	return m

## Y las mismas dos, bajando.
func _receta_dinero_sale(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.32)
	_mezclar(m, _tono(1320.0 * alto, 0.09, 0.040, "seno"))
	_mezclar(m, _tono(880.0 * alto, 0.16, 0.034, "seno"), 0.07)
	return m

## El bombo girando: bolas de plástico chocando. Ruido corto repetido
## catorce veces a destiempo, que es lo que suena a bombo.
func _receta_sorteo(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.80)
	for i in 16:
		var tb := float(i) * 0.11 + float((i * 7) % 5) * 0.014
		_mezclar(m, _ruido(0.05, 1500.0 + float((i * 13) % 900), 700.0, 0.055), tb)
	return m

# --- Los que pedía el LEEME: uno propio por evento ---------------------------------------

## El pendiente nº2 del LEEME, en su orden: «candidatos a sonido propio, por orden de
## cuánto cambian la partida». Hasta entonces nueve tipos de `Aviso` se repartían cinco
## recetas, así que cobrar una cláusula sonaba exactamente igual que pagar una obra.

## Te pagaron la cláusula: dinero mucho, pero no lo elegiste tú. Por
## eso sube y termina con un golpe seco, no con una fanfarria.
func _receta_clausula(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.10)
	_mezclar(m, _tono(523.0 * alto, 0.12, 0.045, "seno"))
	_mezclar(m, _tono(784.0 * alto, 0.12, 0.045, "seno"), 0.11)
	_mezclar(m, _tono(1047.0 * alto, 0.40, 0.050, "seno"), 0.22)
	_mezclar(m, _ruido(0.30, 200.0, 90.0, 0.10), 0.55)
	return m

## La versión larga de "lesion": el mismo golpe, pero la caída sigue
## bajando y no se recupera. Media temporada fuera se tiene que oír.
func _receta_lesion_grave(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.20)
	_mezclar(m, _ruido(0.40, 260.0, 80.0, 0.12))
	_mezclar(m, _tono(196.0 * alto, 0.50, 0.070, "sierra"), 0.03)
	_mezclar(m, _tono(147.0 * alto, 0.60, 0.060, "sierra"), 0.42)
	_mezclar(m, _tono(110.0 * alto, 1.20, 0.055, "sierra"), 0.95)
	return m

## Llega una oferta por uno de los tuyos. Interrogación: dos notas que
## suben y se quedan colgadas sin resolver.
func _receta_oferta(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.60)
	_mezclar(m, _tono(440.0 * alto, 0.14, 0.040, "seno"))
	_mezclar(m, _tono(587.0 * alto, 0.34, 0.042, "seno"), 0.13)
	return m

## El aviso de que se te va gratis. Un tictac doble y una nota baja:
## esto es un plazo, no una noticia.
func _receta_contrato_vence(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.90)
	_mezclar(m, _tono(1500.0 * alto, 0.04, 0.038, "cuadrada"))
	_mezclar(m, _tono(1500.0 * alto, 0.04, 0.038, "cuadrada"), 0.20)
	_mezclar(m, _tono(233.0 * alto, 0.45, 0.050, "sierra"), 0.38)
	return m

## La obra terminada: un martillazo y el acorde de "ya está". Es la
## única del grupo que suena a construcción y no a despacho.
func _receta_obra(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.30)
	_mezclar(m, _ruido(0.10, 900.0, 300.0, 0.13))
	_mezclar(m, _ruido(0.10, 900.0, 300.0, 0.11), 0.16)
	for hz3 in [349.0, 440.0, 523.0]:
		_mezclar(m, _tono(float(hz3) * alto, 0.80, 0.040, "seno"), 0.34)
	return m

## Venta cerrada: la caja de "dinero_entra" con el sello de "contrato"
## detrás. Vender es cobrar y firmar a la vez.
func _receta_venta(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.80)
	_mezclar(m, _tono(1320.0 * alto, 0.09, 0.045, "seno"))
	_mezclar(m, _tono(1980.0 * alto, 0.14, 0.038, "seno"), 0.07)
	_mezclar(m, _ruido(0.09, 300.0, 120.0, 0.10), 0.30)
	return m

# --- Más gestión y carrera (tercera tanda) -----------------------------------------------

func _receta_entrenamiento(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.0)
	for i5 in 3:
		_mezclar(m, _tono(600.0 * alto, 0.06, 0.05, "seno"), float(i5) * 0.30)
	return m

func _receta_sesion_tactica(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(700.0 * alto, 0.10, 0.04, "cuadrada")
	_mezclar(m, _tono(900.0 * alto, 0.10, 0.04, "cuadrada"), 0.14)
	return m

func _receta_rueda_prensa_pregunta(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(500.0 * alto, 0.12, 0.05, "seno")

func _receta_rueda_prensa_aplauso(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(0.80 * largo, 1400.0, 2000.0, 0.08)

func _receta_scouting_informe(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.50)
	_mezclar(m, _ruido(0.10, 1800.0, 900.0, 0.04))
	_mezclar(m, _tono(1200.0 * alto, 0.20, 0.03, "seno"), 0.08)
	return m

func _receta_oferta_rechazada(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(220.0 * alto, 0.30, 0.05, "sierra")

func _receta_oferta_aceptada(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.50)
	_mezclar(m, _tono(523.0 * alto, 0.14, 0.05, "seno"))
	_mezclar(m, _tono(659.0 * alto, 0.22, 0.05, "seno"), 0.13)
	return m

func _receta_renovacion(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.60)
	_mezclar(m, _ruido(0.30, 3200.0, 1400.0, 0.03))
	_mezclar(m, _tono(587.0 * alto, 0.24, 0.030, "seno"), 0.36)
	return m

func _receta_prestamo(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.50)
	_mezclar(m, _tono(660.0 * alto, 0.10, 0.04, "seno"))
	_mezclar(m, _tono(550.0 * alto, 0.16, 0.03, "seno"), 0.10)
	return m

func _receta_veto_fichaje(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(196.0 * alto, 0.40, 0.06, "sierra")

func _receta_mercado_cierra(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.20)
	for i6 in 4:
		_mezclar(m, _tono(1500.0 * alto, 0.04, 0.038, "cuadrada"), float(i6) * 0.24)
	return m

func _receta_premio_individual(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.00)
	_mezclar(m, _tono(880.0 * alto, 0.12, 0.04, "seno"))
	_mezclar(m, _tono(1318.0 * alto, 0.40, 0.05, "seno"), 0.12)
	_mezclar(m, _ruido(0.30, 3000.0, 5000.0, 0.03), 0.10)
	return m

func _receta_capitania(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.50)
	_mezclar(m, _tono(659.0 * alto, 0.30, 0.05, "seno"))
	return m

func _receta_retiro_jugador(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.20)
	_mezclar(m, _tono(220.0 * alto, 1.90, 0.06, "seno"))
	_mezclar(m, _ruido(1.20, 500.0, 2000.0, 0.06), 0.60)
	return m

func _receta_debut_juvenil(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.60)
	_mezclar(m, _tono(659.0 * alto, 0.14, 0.045, "seno"))
	_mezclar(m, _tono(880.0 * alto, 0.24, 0.045, "seno"), 0.13)
	return m

func _receta_ascenso_juvenil(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.80)
	_mezclar(m, _tono(494.0 * alto, 0.14, 0.05, "sierra"))
	_mezclar(m, _tono(659.0 * alto, 0.30, 0.06, "sierra"), 0.14)
	return m

func _receta_sancion_directiva(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(140.0 * alto, 0.45, 0.07, "sierra")

func _receta_reunion_directiva(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(600.0 * alto, 0.08, 0.03, "cuadrada")
	_mezclar(m, _tono(600.0 * alto, 0.08, 0.03, "cuadrada"), 0.20)
	return m

func _receta_patrocinio_nuevo(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.55)
	_mezclar(m, _tono(880.0 * alto, 0.10, 0.045, "seno"))
	_mezclar(m, _tono(1108.0 * alto, 0.22, 0.045, "seno"), 0.10)
	return m

func _receta_inauguracion_obra(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.60)
	_mezclar(m, _ruido(0.10, 900.0, 300.0, 0.13))
	for hz5 in [349.0, 440.0, 523.0, 659.0]:
		_mezclar(m, _tono(float(hz5) * alto, 0.90, 0.035, "seno"), 0.40)
	return m

func _receta_entrada_taquilla(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.30)
	_mezclar(m, _tono(1320.0 * alto, 0.08, 0.045, "seno"))
	return m

func _receta_aumento_socios(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.60)
	_mezclar(m, _tono(523.0 * alto, 0.14, 0.04, "seno"))
	_mezclar(m, _tono(784.0 * alto, 0.30, 0.04, "seno"), 0.13)
	return m

func _receta_huelga_hinchas(_alto: float, _largo: float) -> PackedFloat32Array:
	return _ruido(2.40, 1900.0, 2600.0, 0.10)

func _receta_elecciones_club(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(700.0 * alto, 0.10, 0.04, "cuadrada")
	_mezclar(m, _tono(900.0 * alto, 0.10, 0.04, "cuadrada"), 0.16)
	return m

func _receta_votacion_ganada(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.70)
	_mezclar(m, _tono(659.0 * alto, 0.14, 0.045, "seno"))
	_mezclar(m, _tono(988.0 * alto, 0.30, 0.045, "seno"), 0.13)
	return m

func _receta_votacion_perdida(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(233.0 * alto, 0.40, 0.06, "sierra")

func _receta_premio_liga(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.2)
	for hz6 in [262.0, 330.0, 392.0, 523.0]:
		_mezclar(m, _tono(float(hz6) * alto, 1.80, 0.04, "seno"))
	_mezclar(m, _cantico(1.0), 0.4)
	return m

func _receta_descenso_administrativo(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(98.0 * alto, 1.40, 0.08, "sierra")

func _receta_multa(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.40)
	_mezclar(m, _tono(1320.0 * alto, 0.08, 0.04, "seno"))
	_mezclar(m, _tono(880.0 * alto, 0.16, 0.035, "seno"), 0.08)
	return m

func _receta_cesion_jugador(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.50)
	_mezclar(m, _tono(660.0 * alto, 0.10, 0.04, "seno"))
	_mezclar(m, _tono(550.0 * alto, 0.16, 0.03, "seno"), 0.10)
	return m

func _receta_renovacion_rechazada(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(200.0 * alto, 0.40, 0.06, "sierra")

func _receta_agente_llamada(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.60)
	for rep2 in 3:
		_mezclar(m, _tono(1000.0 * alto, 0.028, 0.030, "seno"), float(rep2) * 0.10)
	return m

func _receta_rumor_fichaje(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _tono(500.0 * alto, 0.10, 0.03, "seno")
	_mezclar(m, _ruido(0.20, 900.0, 1400.0, 0.02), 0.05)
	return m

func _receta_medico_parte(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(600.0 * alto, 0.10, 0.035, "cuadrada")

func _receta_alta_medica(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.45)
	_mezclar(m, _tono(659.0 * alto, 0.12, 0.04, "seno"))
	_mezclar(m, _tono(880.0 * alto, 0.20, 0.04, "seno"), 0.11)
	return m

func _receta_baja_medica(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(233.0 * alto, 0.30, 0.05, "sierra")

func _receta_entrenamiento_lesion(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(0.60)
	_mezclar(m, _ruido(0.20, 300.0, 100.0, 0.10))
	_mezclar(m, _tono(180.0 * alto, 0.30, 0.05, "sierra"), 0.05)
	return m

func _receta_objetivo_cumplido(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.00)
	_mezclar(m, _tono(523.0 * alto, 0.14, 0.045, "seno"))
	_mezclar(m, _tono(659.0 * alto, 0.14, 0.045, "seno"), 0.13)
	_mezclar(m, _tono(880.0 * alto, 0.40, 0.05, "seno"), 0.26)
	return m

func _receta_objetivo_fallado(alto: float, _largo: float) -> PackedFloat32Array:
	return _tono(200.0 * alto, 0.50, 0.06, "sierra")

func _receta_mejora_instalaciones(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.10)
	_mezclar(m, _ruido(0.10, 900.0, 300.0, 0.12))
	_mezclar(m, _tono(440.0 * alto, 0.60, 0.035, "seno"), 0.35)
	return m
