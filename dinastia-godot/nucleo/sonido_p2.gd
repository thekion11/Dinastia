extends "res://nucleo/sonido_p2_p2.gd"
## [Capa 4/5 de `sonido.gd`] _sintetizar_g3, _sintetizar

## Parte 3 de 3 de `_sintetizar` (la norma de 450 líneas la partió por grupos de sonidos):
## devuelve el sonido si `nombre` es de este grupo y vacío si no.
func _sintetizar_g3(nombre: String, tono: float, largo: float) -> PackedFloat32Array:
	var m: PackedFloat32Array = PackedFloat32Array()
	match nombre:
		"mercado_cierra":
			m.resize(int(1.20 * float(FRECUENCIA)))
			for i6 in 4:
				_mezclar(m, _tono(1500.0 * tono, 0.04, 0.038, "cuadrada"), float(i6) * 0.24)
		"premio_individual":
			m.resize(int(1.00 * float(FRECUENCIA)))
			_mezclar(m, _tono(880.0 * tono, 0.12, 0.04, "seno"))
			_mezclar(m, _tono(1318.0 * tono, 0.40, 0.05, "seno"), 0.12)
			_mezclar(m, _ruido(0.30, 3000.0, 5000.0, 0.03), 0.10)
		"capitania":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _tono(659.0 * tono, 0.30, 0.05, "seno"))
		"retiro_jugador":
			m.resize(int(2.20 * float(FRECUENCIA)))
			_mezclar(m, _tono(220.0 * tono, 1.90, 0.06, "seno"))
			_mezclar(m, _ruido(1.20, 500.0, 2000.0, 0.06), 0.60)
		"debut_juvenil":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(659.0 * tono, 0.14, 0.045, "seno"))
			_mezclar(m, _tono(880.0 * tono, 0.24, 0.045, "seno"), 0.13)
		"ascenso_juvenil":
			m.resize(int(0.80 * float(FRECUENCIA)))
			_mezclar(m, _tono(494.0 * tono, 0.14, 0.05, "sierra"))
			_mezclar(m, _tono(659.0 * tono, 0.30, 0.06, "sierra"), 0.14)
		"sancion_directiva":
			m = _tono(140.0 * tono, 0.45, 0.07, "sierra")
		"reunion_directiva":
			m = _tono(600.0 * tono, 0.08, 0.03, "cuadrada")
			_mezclar(m, _tono(600.0 * tono, 0.08, 0.03, "cuadrada"), 0.20)
		"patrocinio_nuevo":
			m.resize(int(0.55 * float(FRECUENCIA)))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.045, "seno"))
			_mezclar(m, _tono(1108.0 * tono, 0.22, 0.045, "seno"), 0.10)
		"inauguracion_obra":
			m.resize(int(1.60 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.10, 900.0, 300.0, 0.13))
			for hz5 in [349.0, 440.0, 523.0, 659.0]:
				_mezclar(m, _tono(float(hz5) * tono, 0.90, 0.035, "seno"), 0.40)
		"entrada_taquilla":
			m.resize(int(0.30 * float(FRECUENCIA)))
			_mezclar(m, _tono(1320.0 * tono, 0.08, 0.045, "seno"))
		"aumento_socios":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(523.0 * tono, 0.14, 0.04, "seno"))
			_mezclar(m, _tono(784.0 * tono, 0.30, 0.04, "seno"), 0.13)
		"huelga_hinchas":
			m = _ruido(2.40, 1900.0, 2600.0, 0.10)
		"elecciones_club":
			m = _tono(700.0 * tono, 0.10, 0.04, "cuadrada")
			_mezclar(m, _tono(900.0 * tono, 0.10, 0.04, "cuadrada"), 0.16)
		"votacion_ganada":
			m.resize(int(0.70 * float(FRECUENCIA)))
			_mezclar(m, _tono(659.0 * tono, 0.14, 0.045, "seno"))
			_mezclar(m, _tono(988.0 * tono, 0.30, 0.045, "seno"), 0.13)
		"votacion_perdida":
			m = _tono(233.0 * tono, 0.40, 0.06, "sierra")
		"premio_liga":
			m.resize(int(2.2 * float(FRECUENCIA)))
			for hz6 in [262.0, 330.0, 392.0, 523.0]:
				_mezclar(m, _tono(float(hz6) * tono, 1.80, 0.04, "seno"))
			_mezclar(m, _cantico(1.0), 0.4)
		"descenso_administrativo":
			m = _tono(98.0 * tono, 1.40, 0.08, "sierra")
		"multa":
			m.resize(int(0.40 * float(FRECUENCIA)))
			_mezclar(m, _tono(1320.0 * tono, 0.08, 0.04, "seno"))
			_mezclar(m, _tono(880.0 * tono, 0.16, 0.035, "seno"), 0.08)
		"cesion_jugador":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _tono(660.0 * tono, 0.10, 0.04, "seno"))
			_mezclar(m, _tono(550.0 * tono, 0.16, 0.03, "seno"), 0.10)
		"renovacion_rechazada":
			m = _tono(200.0 * tono, 0.40, 0.06, "sierra")
		"agente_llamada":
			m.resize(int(0.60 * float(FRECUENCIA)))
			for rep2 in 3:
				_mezclar(m, _tono(1000.0 * tono, 0.028, 0.030, "seno"), float(rep2) * 0.10)
		"rumor_fichaje":
			m = _tono(500.0 * tono, 0.10, 0.03, "seno")
			_mezclar(m, _ruido(0.20, 900.0, 1400.0, 0.02), 0.05)
		"medico_parte":
			m = _tono(600.0 * tono, 0.10, 0.035, "cuadrada")
		"alta_medica":
			m.resize(int(0.45 * float(FRECUENCIA)))
			_mezclar(m, _tono(659.0 * tono, 0.12, 0.04, "seno"))
			_mezclar(m, _tono(880.0 * tono, 0.20, 0.04, "seno"), 0.11)
		"baja_medica":
			m = _tono(233.0 * tono, 0.30, 0.05, "sierra")
		"entrenamiento_lesion":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.20, 300.0, 100.0, 0.10))
			_mezclar(m, _tono(180.0 * tono, 0.30, 0.05, "sierra"), 0.05)
		"objetivo_cumplido":
			m.resize(int(1.00 * float(FRECUENCIA)))
			_mezclar(m, _tono(523.0 * tono, 0.14, 0.045, "seno"))
			_mezclar(m, _tono(659.0 * tono, 0.14, 0.045, "seno"), 0.13)
			_mezclar(m, _tono(880.0 * tono, 0.40, 0.05, "seno"), 0.26)
		"objetivo_fallado":
			m = _tono(200.0 * tono, 0.50, 0.06, "sierra")
		"mejora_instalaciones":
			m.resize(int(1.10 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.10, 900.0, 300.0, 0.12))
			_mezclar(m, _tono(440.0 * tono, 0.60, 0.035, "seno"), 0.35)

		## --- Mas interfaz ---
		"seleccionar":
			m = _tono(1000.0 * tono, 0.04, 0.04, "seno")
		"deseleccionar":
			m = _tono(700.0 * tono, 0.04, 0.03, "seno")
		"arrastrar":
			m = _tono(500.0 * tono, 0.05, 0.025, "seno")
		"soltar":
			m = _tono(650.0 * tono, 0.06, 0.03, "seno")
		"desbloqueo":
			m.resize(int(0.40 * float(FRECUENCIA)))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.04, "seno"))
			_mezclar(m, _tono(1318.0 * tono, 0.20, 0.04, "seno"), 0.09)
		"nivel_subido":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _tono(659.0 * tono, 0.10, 0.04, "seno"))
			_mezclar(m, _tono(988.0 * tono, 0.30, 0.04, "seno"), 0.09)
		"notificacion":
			m = _tono(1047.0 * tono, 0.08, 0.04, "seno")
		"confirmar":
			m = _tono(880.0 * tono, 0.06, 0.04, "seno")
		"cancelar":
			m = _tono(440.0 * tono, 0.08, 0.04, "cuadrada")
		"deslizar":
			m = _ruido(0.10, 2000.0, 1200.0, 0.025)

		## --- Mas festejos y momentos de gol ---
		"celebracion_grupal":
			m.resize(int(2.0 * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.60, 700.0, 2200.0, 0.15))
			_mezclar(m, _cantico(1.0), 0.4)
		"celebracion_individual":
			m = _ruido(1.00 * largo, 700.0, 2000.0, 0.10)
		"festejo_banco":
			m.resize(int(1.20 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.90, 700.0, 1800.0, 0.10))
		"festejo_hinchada_extra":
			m.resize(int(2.60 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.20, 600.0, 2400.0, 0.20))
			_mezclar(m, _cantico(1.5), 0.4)
			_mezclar(m, _cantico(1.3), 2.0)
		"remontada":
			m.resize(int(3.0 * float(FRECUENCIA)))
			_mezclar(m, _ruido(2.40, 700.0, 220.0, 0.20))
			for hz7 in [392.0, 523.0, 659.0]:
				_mezclar(m, _tono(float(hz7) * tono, 0.50, 0.06, "sierra"), 0.10)
			_mezclar(m, _cantico(1.3), 1.0)
		"gol_agonico":
			m.resize(int(3.4 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.20, 1900.0, 900.0, 0.05))
			_mezclar(m, _ruido(2.60, 700.0, 220.0, 0.24), 0.25)
			_mezclar(m, _cantico(1.6), 0.6)
		"hat_trick":
			m.resize(int(2.6 * float(FRECUENCIA)))
			for hz8 in [523.0, 659.0, 784.0]:
				_mezclar(m, _tono(float(hz8) * tono, 0.30, 0.06, "sierra"), (hz8 - 523.0) / 261.0 * 0.20)
			_mezclar(m, _ruido(1.80, 700.0, 2000.0, 0.14), 0.60)
		"doblete":
			m.resize(int(1.8 * float(FRECUENCIA)))
			_mezclar(m, _tono(523.0 * tono, 0.20, 0.06, "sierra"))
			_mezclar(m, _tono(659.0 * tono, 0.30, 0.06, "sierra"), 0.20)
			_mezclar(m, _ruido(1.20, 700.0, 2000.0, 0.10), 0.45)
		"gol_rapido":
			m.resize(int(2.0 * float(FRECUENCIA)))
			_mezclar(m, _ruido(1.60, 700.0, 220.0, 0.18))
			_mezclar(m, _tono(880.0 * tono, 0.10, 0.05, "seno"))
		"gol_confirmado_var":
			m.resize(int(2.4 * float(FRECUENCIA)))
			for i7 in 2:
				_mezclar(m, _tono(1400.0 * tono, 0.10, 0.04, "cuadrada"), float(i7) * 0.22)
			_mezclar(m, _ruido(1.60, 700.0, 2200.0, 0.16), 0.50)

		## --- Clima y ambiente ---
		"niebla_ambiente":
			m = _ruido(3.00, 200.0, 500.0, 0.04)
		"calor_extremo":
			m = _ruido(2.40, 1200.0, 1600.0, 0.02)
		"frio_extremo":
			m = _ruido(1.60 * largo, 400.0, 900.0, 0.03)
		"noche_estadio":
			m = _ruido(3.20, 100.0, 300.0, 0.04)
		"dia_soleado":
			m = _ruido(2.60, 800.0, 1400.0, 0.03)

		## --- Mas arbitro y disciplina ---
		"tarjeta_banco":
			m = _tono(320.0 * tono, 0.20, 0.06, "cuadrada")
			_mezclar(m, _ruido(0.30, 900.0, 300.0, 0.05), 0.10)
		"protesta_jugador":
			m = _ruido(1.20 * largo, 500.0, 300.0, 0.08)
		"protesta_masiva":
			m = _ruido(2.20 * largo, 500.0, 300.0, 0.14)
		"amonestacion_verbal":
			m = _tono(500.0 * tono, 0.14, 0.04, "seno")
		"tiempo_anadido":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(1400.0 * tono, 0.08, 0.05, "cuadrada"))
		"ventaja":
			m = _tono(700.0 * tono, 0.10, 0.04, "seno")
			_mezclar(m, _tono(900.0 * tono, 0.10, 0.03, "seno"), 0.06)
		"libre_indirecto":
			m = _tono(2650.0 * tono, 0.20 * largo, 0.20, "seno")
		"mano_fuera_area":
			m = _tono(1400.0 * tono, 0.08, 0.05, "cuadrada")
		"fuera_terreno_juego":
			m = _tono(400.0 * tono, 0.10, 0.04, "seno")
		"calambre":
			m.resize(int(0.50 * float(FRECUENCIA)))
			_mezclar(m, _ruido(0.20, 300.0, 100.0, 0.09))
			_mezclar(m, _tono(160.0 * tono, 0.30, 0.04, "sierra"), 0.06)

		## --- Mas estilo de juego ---
		"pase_corto":
			m = _tono(700.0 * tono, 0.04, 0.05, "seno")
		"centro":
			m = _ruido(0.30 * largo, 2000.0, 700.0, 0.06)
		"regate":
			m.resize(int(0.30 * float(FRECUENCIA)))
			_mezclar(m, _tono(600.0 * tono, 0.05, 0.04, "seno"))
			_mezclar(m, _tono(750.0 * tono, 0.05, 0.04, "seno"), 0.08)
		"tiro_potente":
			m = _ruido(0.20 * largo, 3200.0, 700.0, 0.08)
		"tiro_flojo":
			m = _ruido(0.16 * largo, 1400.0, 600.0, 0.04)
		"paso_atras":
			m = _tono(500.0 * tono, 0.06, 0.04, "seno")
		"presion_alta":
			m = _ruido(0.40 * largo, 700.0, 300.0, 0.07)
		"contragolpe":
			m.resize(int(0.60 * float(FRECUENCIA)))
			_mezclar(m, _tono(700.0 * tono, 0.06, 0.05, "seno"))
			_mezclar(m, _ruido(0.40, 2200.0, 700.0, 0.06), 0.05)
		"posesion_larga":
			m = _ruido(2.00, 300.0, 600.0, 0.09)
		"cambio_ritmo":
			m = _tono(500.0 * tono, 0.10, 0.04, "seno")
			_mezclar(m, _tono(700.0 * tono, 0.10, 0.04, "seno"), 0.10)
	return m

func _sintetizar(nombre: String, sal: float) -> AudioStreamWAV:
	var tono := 0.94 + sal * 0.12      ## multiplicador de altura
	var largo := 0.90 + sal * 0.20     ## multiplicador de duración
	var m: PackedFloat32Array = _sintetizar_g1(nombre, tono, largo)
	if m.is_empty():
		m = _sintetizar_g2(nombre, tono, largo)
	if m.is_empty():
		m = _sintetizar_g3(nombre, tono, largo)
	return _a_wav(m)
