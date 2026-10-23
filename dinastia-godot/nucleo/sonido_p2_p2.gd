extends "res://nucleo/sonido_p2_p1.gd"
## [Capa 3/5 de `sonido.gd`] _sintetizar_g2

## Parte 2 de 3 de `_sintetizar` (la norma de 450 líneas la partió por grupos de sonidos):
## devuelve el sonido si `nombre` es de este grupo y vacío si no.
func _sintetizar_g2(nombre: String, tono: float, largo: float) -> PackedFloat32Array:
	var m: PackedFloat32Array = PackedFloat32Array()
	match nombre:
		"himno":
			## Ocho notas de himno de club, en modo mayor y con eco de estadio.
			## No es el himno de nadie: es un motivo genérico que suena a uno.
			m.resize(int(3.60 * float(FRECUENCIA)))
			var notas := [392.0, 392.0, 523.0, 494.0, 440.0, 392.0, 349.0, 392.0]
			for i in notas.size():
				var t0h := float(i) * 0.40
				var hz: float = float(notas[i]) * tono
				_mezclar(m, _tono(hz, 0.42, 0.050, "sierra"), t0h)
				_mezclar(m, _tono(hz * 2.0, 0.34, 0.020, "seno"), t0h)
				## El eco: la misma nota 90 ms después y a un tercio de volumen.
				_mezclar(m, _tono(hz, 0.34, 0.017, "sierra"), t0h + 0.09)
			_mezclar(m, _ruido(3.40, 240.0, 700.0, 0.035))
		"fin_temporada":
			## El cierre del año: acorde largo que se abre y se apaga. Ni
			## celebración ni derrota —la temporada se acabó y ya está—.
			m.resize(int(3.00 * float(FRECUENCIA)))
			for hz2 in [262.0, 330.0, 392.0, 523.0]:
				_mezclar(m, _tono(float(hz2) * tono, 2.60, 0.045, "seno"), 0.0)
			_mezclar(m, _ruido(2.40, 500.0, 200.0, 0.07), 0.20)

		## ---------------------------------------------------------------
		##  LOS QUE PEDÍA EL LEEME: UNO PROPIO POR EVENTO
		## ---------------------------------------------------------------
		##
		## El pendiente nº2 del LEEME, en su orden: «candidatos a sonido propio,
		## por orden de cuánto cambian la partida». Hasta ahora nueve tipos de
		## `Aviso` se repartían cinco recetas, así que cobrar una cláusula sonaba
		## exactamente igual que pagar una obra.
		"clausula":
			## Te pagaron la cláusula: dinero mucho, pero no lo elegiste tú. Por
			## eso sube y termina con un golpe seco, no con una fanfarria.
			m.resize(int(1.10 * float(FRECUENCIA)))
			_mezclar(m, _tono(523.0 * tono, 0.12, 0.045, "seno"))
			_mezclar(m, _tono(784.0 * tono, 0.12, 0.045, "seno"), 0.11)
			_mezclar(m, _tono(1047.0 * tono, 0.40, 0.050, "seno"), 0.22)
			_mezclar(m, _ruido(0.30, 200.0, 90.0, 0.10), 0.55)
		"lesion_grave":
			## La versión larga de "lesion": el mismo golpe, pero la caída sigue
			## bajando y no se recupera. Media temporada fuera se tiene que oír.
			m.resize(int(2.20 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.40, 260.0, 80.0, 0.12))
			_mezclar(m, _tono(196.0 * tono, 0.50, 0.070, "sierra"), 0.03)
			_mezclar(m, _tono(147.0 * tono, 0.60, 0.060, "sierra"), 0.42)
			_mezclar(m, _tono(110.0 * tono, 1.20, 0.055, "sierra"), 0.95)
		"oferta":
			## Llega una oferta por uno de los tuyos. Interrogación: dos notas que
			## suben y se quedan colgadas sin resolver.
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(440.0 * tono, 0.14, 0.040, "seno"))
			_mezclar(m, _tono(587.0 * tono, 0.34, 0.042, "seno"), 0.13)
		"contrato_vence":
			## El aviso de que se te va gratis. Un tictac doble y una nota baja:
			## esto es un plazo, no una noticia.
			m.resize(int(0.90 * float(FRECUENCIA)))
			_mezclar(m, _tono(1500.0 * tono, 0.04, 0.038, "cuadrada"))
			_mezclar(m, _tono(1500.0 * tono, 0.04, 0.038, "cuadrada"), 0.20)
			_mezclar(m, _tono(233.0 * tono, 0.45, 0.050, "sierra"), 0.38)
		"obra":
			## La obra terminada: un martillazo y el acorde de "ya está". Es la
			## única del grupo que suena a construcción y no a despacho.
			m.resize(int(1.30 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.10, 900.0, 300.0, 0.13))
			_mezclar(m, _ruido(0.10, 900.0, 300.0, 0.11), 0.16)
			for hz3 in [349.0, 440.0, 523.0]:
				_mezclar(m, _tono(float(hz3) * tono, 0.80, 0.040, "seno"), 0.34)
		"venta":
			## Venta cerrada: la caja de "dinero_entra" con el sello de "contrato"
			## detrás. Vender es cobrar y firmar a la vez.
			m.resize(int(0.80 * float(FRECUENCIA)))
			_mezclar(m, _tono(1320.0 * tono, 0.09, 0.045, "seno"))
			_mezclar(m, _tono(1980.0 * tono, 0.14, 0.038, "seno"), 0.07)
			_mezclar(m, _ruido(0.09, 300.0, 120.0, 0.10), 0.30)
		"ronda_superada":
			## Pasas de ronda: no es un título -eso es "trofeo"-, es seguir vivo.
			## Cuatro notas que suben y la grada detrás, y se acaba.
			m.resize(int(1.80 * float(FRECUENCIA)))
			_mezclar(m, _tono(330.0 * tono, 0.16, 0.050, "sierra"))
			_mezclar(m, _tono(392.0 * tono, 0.16, 0.050, "sierra"), 0.14)
			_mezclar(m, _tono(494.0 * tono, 0.16, 0.050, "sierra"), 0.28)
			_mezclar(m, _tono(659.0 * tono, 0.60, 0.060, "sierra"), 0.42)
			_mezclar(m, _ruido(1.30, 500.0, 1700.0, 0.11), 0.20)
		## EL SONIDO DE GOL QUE SE ELIGE EN EL ESTADIO -`sfxGol(estilo)` del HTML,
		## sus ocho recetas-. `EstadioPropio.ajustes["sonidoGol"]` se podía
		## elegir y pagar, pero `Sonido` tocaba siempre el mismo "gol" fijo: era
		## un desplegable que no hacía nada. Todas llevan debajo el mismo
		## rugido de grada (`ruido(0,2.1,700,220,0.17)`, que en el HTML va antes
		## del `if`), y los `setTimeout(cantico...)` son `_cantico()` mezclado
		## con retraso. Por eso cada una reserva el buffer entero PRIMERO: la
		## trampa ya pagada con "trofeo" -`_mezclar()` no alarga el destino-.
		## Diferencias honestas: `_tono()` no tiene glissando ni onda triangular,
		## así que la sirena se hace por tramos y el triángulo es un seno.
		"gol_bombo":
			m.resize(int(3.3 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			for golpe_b in 7:
				_bombo(m, float(golpe_b) * 0.42, 0.17)
			var trompeta := [523.0, 523.0, 659.0, 784.0, 784.0, 659.0]
			for nt in trompeta.size():
				_mezclar(m, _tono(float(trompeta[nt]) * tono, 0.34, 0.045, "sierra"), 0.5 + float(nt) * 0.42)
			_mezclar(m, _cantico(1.25), 1.0)
		"gol_sirena":
			m.resize(int(3.8 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			var tramos := [88.0, 102.0, 120.0, 130.0, 124.0, 118.0]
			for tr in tramos.size():
				_mezclar(m, _tono(float(tramos[tr]) * tono, 0.70, 0.09, "sierra"), float(tr) * 0.55)
			_mezclar(m, _tono(66.0 * tono, 3.40, 0.05, "seno"))
		"gol_campana":
			m.resize(int(5.3 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			var parciales := [1.0, 2.76, 5.4, 8.9]
			for golpe_c in 4:
				var t_camp := float(golpe_c) * 0.95
				for pj in parciales.size():
					_mezclar(m, _tono(262.0 * float(parciales[pj]) * tono, 2.4 / float(pj + 1), 0.055 / float(pj + 1), "seno"), t_camp)
				_mezclar(m, _ruido(0.12, 3200.0, 1800.0, 0.03), t_camp)
			_mezclar(m, _cantico(1.1), 1.8)
		"gol_organo":
			m.resize(int(3.6 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			var acordes := [[262.0, 330.0, 392.0], [294.0, 370.0, 440.0], [349.0, 440.0, 523.0], [392.0, 494.0, 587.0]]
			for ac in acordes.size():
				for f_org in (acordes[ac] as Array):
					_mezclar(m, _tono(float(f_org) * tono, 0.62, 0.035, "sierra"), float(ac) * 0.55)
					_mezclar(m, _tono(float(f_org) * 2.0 * tono, 0.60, 0.018, "seno"), float(ac) * 0.55)
			_mezclar(m, _cantico(1.15), 1.4)
		"gol_explosion":
			m.resize(int(3.3 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			_mezclar(m, _ruido(0.50, 1800.0, 60.0, 0.28))
			_mezclar(m, _tono(44.0 * tono, 0.70, 0.20, "seno"))
			_mezclar(m, _ruido(1.10, 900.0, 200.0, 0.09), 0.42)
			for chispa in 5:
				_mezclar(m, _ruido(0.14, 2600.0, 1400.0, 0.06), 1.1 + float(chispa) * 0.17)
			_mezclar(m, _cantico(1.35), 1.1)
		"gol_sintetico":
			m.resize(int(2.2 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.05, "cuadrada"))
			_mezclar(m, _tono(1174.0 * tono, 0.10, 0.05, "cuadrada"), 0.09)
			_mezclar(m, _tono(1568.0 * tono, 0.50, 0.06, "cuadrada"), 0.18)
			_mezclar(m, _tono(98.0 * tono, 0.90, 0.09, "sierra"))
			_mezclar(m, _ruido(0.90, 4200.0, 900.0, 0.06), 0.16)
			for eco in 3:
				_mezclar(m, _tono(1568.0 * tono, 0.12, 0.03, "seno"), 0.7 + float(eco) * 0.14)
		"gol_tambores":
			m.resize(int(3.4 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			for golpe_t in 16:
				var t_tam := float(golpe_t) * 0.19
				if golpe_t % 4 == 0:
					_bombo(m, t_tam, 0.15)
				else:
					_mezclar(m, _ruido(0.10, 1400.0, 600.0, 0.055), t_tam)
				if golpe_t % 2 == 1:
					_mezclar(m, _ruido(0.06, 5200.0, 3000.0, 0.03), t_tam + 0.09)
			_mezclar(m, _cantico(1.3), 1.2)
		"gol_silencio":
			## "Solo la gente": sin efecto, el rugido puro y dos cánticos.
			m.resize(int(4.8 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
			_mezclar(m, _ruido(2.60, 520.0, 180.0, 0.11), 0.1)
			_mezclar(m, _cantico(1.4), 0.5)
			_mezclar(m, _cantico(1.2), 2.6)

		## =================================================================
		##  TERCERA TANDA (21-9-2026): de 65 a ~200, a pedido del usuario.
		##  Mismo instrumental de siempre (osciladores + ruido filtrado),
		##  recetas mas breves que las primeras dos tandas a proposito -son
		##  135 nuevas de una vez, no vale la pena un ensayo de una pagina
		##  por cada una-, pero cada una es una composicion propia, no una
		##  copia con el nombre cambiado.
		## =================================================================

		## --- Mas momentos de partido ---
		"saque_banda":
			m = _ruido(0.18 * largo, 1200.0 * tono, 900.0, 0.05)
		"saque_puerta":
			m = _tono(400.0 * tono, 0.14, 0.05, "seno")
			_mezclar(m, _ruido(0.30, 700.0, 300.0, 0.04), 0.05)
		"fuera_de_banda":
			m = _ruido(0.30 * largo, 1500.0, 600.0, 0.06)
		"rebote":
			m = _tono(900.0 * tono, 0.06, 0.10, "seno")
			_mezclar(m, _tono(700.0 * tono, 0.05, 0.07, "seno"), 0.05)
		"palo_doble":
			## Como "poste" pero DOS golpes seguidos -la mala suerte redoblada.
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(1180.0 * tono, 0.20, 0.18, "seno"))
			_mezclar(m, _tono(1180.0 * tono, 0.20, 0.16, "seno"), 0.22)
		"atajada_punos":
			m.resize(int(0.40 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.14, 700.0, 200.0, 0.14))
			_mezclar(m, _tono(150.0 * tono, 0.10, 0.05, "seno"))
		"atajada_pies":
			m.resize(int(0.35 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.10, 900.0, 400.0, 0.10))
			_mezclar(m, _tono(250.0 * tono, 0.12, 0.04, "seno"), 0.03)
		"gol_cabeza":
			m.resize(int(2.6 * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.80, 700.0, 220.0, 0.17))
			_mezclar(m, _tono(220.0 * tono, 0.14, 0.08, "seno"))
			_mezclar(m, _cantico(1.1), 0.6)
		"gol_chilena":
			## La obra de arte: el rugido mas largo del catalogo, la sorpresa
			## primero -silencio breve- y despues explota.
			m.resize(int(3.6 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.30, 2000.0, 500.0, 0.05), 0.0)
			_mezclar(m, _ruido(2.60, 700.0, 220.0, 0.22), 0.35)
			_mezclar(m, _cantico(1.5), 0.9)
			_mezclar(m, _cantico(1.3), 2.4)
		"gol_falta":
			m.resize(int(2.4 * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.80, 700.0, 220.0, 0.17))
			_mezclar(m, _tono(1560.0 * tono, 0.30, 0.10, "seno"))
			_mezclar(m, _cantico(1.1), 0.5)
		"gol_penal":
			m.resize(int(2.4 * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.80, 700.0, 220.0, 0.20))
			_mezclar(m, _tono(660.0 * tono, 0.30, 0.09, "sierra"))
			_mezclar(m, _cantico(1.2), 0.5)
		"autogol":
			## Incomodo, no triste del todo: un acorde raro que no resuelve.
			m.resize(int(1.6 * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.00, 500.0, 200.0, 0.09))
			_mezclar(m, _tono(233.0 * tono, 0.40, 0.05, "sierra"), 0.10)
			_mezclar(m, _tono(247.0 * tono, 0.40, 0.05, "sierra"), 0.20)
		"mano_penal":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(1400.0 * tono, 0.10, 0.05, "cuadrada"))
			_mezclar(m, _ruido(0.40, 900.0, 300.0, 0.07), 0.12)
		"simulacion":
			## El "uy" desconfiado de la grada: ruido corto y disonante.
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.35, 800.0, 600.0, 0.08))
			_mezclar(m, _tono(310.0 * tono, 0.20, 0.03, "sierra"), 0.05)
		"var_anulado":
			m.resize(int(1.20 * float(FRECUENCIA)))
			for i2 in 3:
				_mezclar(m, _tono(1400.0 * tono, 0.10, 0.05, "cuadrada"), float(i2) * 0.22)
			_mezclar(m, _tono(180.0 * tono, 0.50, 0.06, "sierra"), 0.70)
		"medio_tiempo":
			m = _tono(2650.0 * tono, 0.60 * largo, 0.28, "seno")
			_mezclar(m, _tono(3980.0 * tono, 0.60 * largo, 0.14, "seno"))
		"reanudacion":
			m.resize(int(1.0 * float(FRECUENCIA)))
			_mezclar(m, _tono(2650.0 * tono, 0.30, 0.24, "seno"))
			_mezclar(m, _ruido(0.80, 300.0, 900.0, 0.08), 0.10)
		"calentamiento":
			m = _ruido(1.80 * largo, 400.0, 700.0, 0.05)
			_mezclar(m, _tono(300.0, 0.10, 0.03, "seno"), 0.40)
		"salida_tunel":
			m.resize(int(2.2 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.00, 300.0, 1400.0, 0.16))
		"presentacion_alineaciones":
			m.resize(int(1.6 * float(FRECUENCIA)))
			_mezclar(m, _tono(440.0 * tono, 0.16, 0.05, "seno"))
			_mezclar(m, _tono(554.0 * tono, 0.16, 0.05, "seno"), 0.14)
			_mezclar(m, _tono(659.0 * tono, 0.40, 0.06, "seno"), 0.28)
		"despeje":
			m = _tono(500.0 * tono, 0.10, 0.10, "seno")
			_mezclar(m, _ruido(0.14, 700.0, 300.0, 0.05))
		"entrada_dura":
			m.resize(int(0.40 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.16, 300.0, 100.0, 0.13))
			_mezclar(m, _tono(140.0 * tono, 0.12, 0.04, "sierra"), 0.02)
		"recuperacion_balon":
			m = _tono(700.0 * tono, 0.08, 0.07, "seno")
		"pase_largo":
			m = _ruido(0.35 * largo, 2200.0, 500.0, 0.06)
		"control_balon":
			m = _tono(600.0 * tono, 0.05, 0.06, "seno")

		## --- Mas grada ---
		"ola_mexicana":
			## Un barrido de intensidad, izquierda a derecha: ruido que crece
			## y decrece en oleada.
			m.resize(int(2.40 * float(FRECUENCIA)))
			for i3 in 6:
				_mezclar(m, _ruido(0.55, 1200.0, 2000.0, 0.10), float(i3) * 0.30)
		"silbido_agudo":
			m = _tono(3200.0 * tono, 0.60 * largo, 0.08, "seno")
		"coro_rival":
			m = _cantico(0.8)
			_mezclar(m, _ruido(0.30, 1800.0, 2200.0, 0.04))
		"pitos_arbitro":
			m = _ruido(1.60 * largo, 2200.0, 2600.0, 0.12)
		"bocina_vuvuzela":
			m = _tono(233.0 * tono, 1.80 * largo, 0.10, "sierra")
			_mezclar(m, _tono(235.5 * tono, 1.80 * largo, 0.08, "sierra"))
		"tambor_visitante":
			m.resize(int(1.80 * float(FRECUENCIA)))
			for i4 in 6:
				_mezclar(m, _ruido(0.14, 85.0, 50.0, 0.13), float(i4) * 0.30)
		"suspiro_grada":
			m = _ruido(0.60 * largo, 900.0, 300.0, 0.09)
		"alarido_atajada":
			m = _ruido(1.20 * largo, 500.0, 2000.0, 0.14)
			_mezclar(m, _cantico(0.6), 0.3)
		"tension_publico":
			m = _ruido(2.80, 250.0, 700.0, 0.06)
		"silbidos_impaciencia":
			m = _ruido(1.80 * largo, 2000.0, 2400.0, 0.09)
		"ultimo_minuto":
			m.resize(int(1.40 * float(FRECUENCIA)))
			var t0u := 0.0
			var paso_u := 0.30
			while t0u < 1.3:
				_mezclar(m, _tono(1900.0 * tono, 0.03, 0.04, "cuadrada"), t0u)
				t0u += paso_u
				paso_u = maxf(0.08, paso_u * 0.85)
		"descuento_anunciado":
			m.resize(int(0.70 * float(FRECUENCIA)))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.04, "seno"))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.04, "seno"), 0.30)
		"grada_de_pie":
			m = _ruido(2.00 * largo, 500.0, 2200.0, 0.16)
		"bufanda_alzada":
			m = _cantico(1.0)
		"pancarta_desplegada":
			m = _ruido(1.20 * largo, 1400.0, 400.0, 0.05)
		"humo_bengala":
			m = _ruido(1.80 * largo, 3800.0, 3000.0, 0.045)
		"cornetin":
			m = _tono(587.0 * tono, 0.40 * largo, 0.07, "sierra")
		"campanas_iglesia":
			m.resize(int(2.0 * float(FRECUENCIA)))
			for hz4 in [523.0, 659.0]:
				_mezclar(m, _tono(float(hz4) * tono, 1.80, 0.05, "seno"))
		"animador_grada":
			m = _tono(500.0 * tono, 0.30 * largo, 0.06, "cuadrada")
			_mezclar(m, _ruido(0.40, 1400.0, 2000.0, 0.05), 0.28)
		"eco_estadio":
			m.resize(int(2.2 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.30, 900.0, 300.0, 0.10))
			_mezclar(m, _ruido(0.30, 900.0, 300.0, 0.04), 0.35)
		"lluvia_fuerte":
			m = _ruido(3.20, 2800.0, 3200.0, 0.08)
		"viento_fuerte":
			m = _ruido(3.20, 300.0, 700.0, 0.07)
		"trueno":
			m = _ruido(1.60 * largo, 120.0, 40.0, 0.20)
		"multitud_entrando":
			m = _ruido(3.00, 400.0, 900.0, 0.06)
		"multitud_saliendo":
			m = _ruido(3.00, 700.0, 350.0, 0.06)

		## --- Mas gestion / carrera ---
		"entrenamiento":
			m.resize(int(1.0 * float(FRECUENCIA)))
			for i5 in 3:
				_mezclar(m, _tono(600.0 * tono, 0.06, 0.05, "seno"), float(i5) * 0.30)
		"sesion_tactica":
			m = _tono(700.0 * tono, 0.10, 0.04, "cuadrada")
			_mezclar(m, _tono(900.0 * tono, 0.10, 0.04, "cuadrada"), 0.14)
		"rueda_prensa_pregunta":
			m = _tono(500.0 * tono, 0.12, 0.05, "seno")
		"rueda_prensa_aplauso":
			m = _ruido(0.80 * largo, 1400.0, 2000.0, 0.08)
		"scouting_informe":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.10, 1800.0, 900.0, 0.04))
			_mezclar(m, _tono(1200.0 * tono, 0.20, 0.03, "seno"), 0.08)
		"oferta_rechazada":
			m = _tono(220.0 * tono, 0.30, 0.05, "sierra")
		"oferta_aceptada":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _tono(523.0 * tono, 0.14, 0.05, "seno"))
			_mezclar(m, _tono(659.0 * tono, 0.22, 0.05, "seno"), 0.13)
		"renovacion":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.30, 3200.0, 1400.0, 0.03))
			_mezclar(m, _tono(587.0 * tono, 0.24, 0.030, "seno"), 0.36)
		"prestamo":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _tono(660.0 * tono, 0.10, 0.04, "seno"))
			_mezclar(m, _tono(550.0 * tono, 0.16, 0.03, "seno"), 0.10)
		"veto_fichaje":
			m = _tono(196.0 * tono, 0.40, 0.06, "sierra")
	return m
