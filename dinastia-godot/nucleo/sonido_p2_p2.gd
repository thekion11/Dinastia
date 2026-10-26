extends "res://nucleo/sonido_p2_p1.gd"
## [Capa 3/7 de `sonido.gd`] recetas de goles, festejos y títulos

# --- Goles -------------------------------------------------------------------------------

## Rugido: ruido grave que se abre, más una fanfarria de tres notas.
func _receta_gol(alto: float, largo: float) -> PackedFloat32Array:
	var m := _ruido(1.60 * largo, 300.0, 1500.0, 0.22)
	_mezclar(m, _tono(523.0 * alto, 0.9, 0.09, "sierra"), 0.05)
	_mezclar(m, _tono(659.0 * alto, 0.8, 0.09, "sierra"), 0.20)
	_mezclar(m, _tono(784.0 * alto, 1.0, 0.10, "sierra"), 0.36)
	return m

## El silencio incómodo: murmullo que se apaga y dos notas tristes.
func _receta_gol_rival(alto: float, largo: float) -> PackedFloat32Array:
	var m := _ruido(1.20 * largo, 420.0, 140.0, 0.14)
	_mezclar(m, _tono(392.0 * alto, 0.16, 0.05, "sierra"), 0.05)
	_mezclar(m, _tono(311.0 * alto, 0.36, 0.05, "sierra"), 0.20)
	return m

func _receta_gol_cabeza(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.6)
	_mezclar(m, _ruido(1.80, 700.0, 220.0, 0.17))
	_mezclar(m, _tono(220.0 * alto, 0.14, 0.08, "seno"))
	_mezclar(m, _cantico(1.1), 0.6)
	return m

## La obra de arte: el rugido mas largo del catalogo, la sorpresa
## primero -silencio breve- y despues explota.
func _receta_gol_chilena(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(3.6)
	_mezclar(m, _ruido(0.30, 2000.0, 500.0, 0.05), 0.0)
	_mezclar(m, _ruido(2.60, 700.0, 220.0, 0.22), 0.35)
	_mezclar(m, _cantico(1.5), 0.9)
	_mezclar(m, _cantico(1.3), 2.4)
	return m

func _receta_gol_falta(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.4)
	_mezclar(m, _ruido(1.80, 700.0, 220.0, 0.17))
	_mezclar(m, _tono(1560.0 * alto, 0.30, 0.10, "seno"))
	_mezclar(m, _cantico(1.1), 0.5)
	return m

func _receta_gol_penal(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.4)
	_mezclar(m, _ruido(1.80, 700.0, 220.0, 0.20))
	_mezclar(m, _tono(660.0 * alto, 0.30, 0.09, "sierra"))
	_mezclar(m, _cantico(1.2), 0.5)
	return m

## Incomodo, no triste del todo: un acorde raro que no resuelve.
func _receta_autogol(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.6)
	_mezclar(m, _ruido(1.00, 500.0, 200.0, 0.09))
	_mezclar(m, _tono(233.0 * alto, 0.40, 0.05, "sierra"), 0.10)
	_mezclar(m, _tono(247.0 * alto, 0.40, 0.05, "sierra"), 0.20)
	return m

# --- El sonido de gol que se elige en el estadio -----------------------------------------

## EL SONIDO DE GOL QUE SE ELIGE EN EL ESTADIO -`sfxGol(estilo)` del HTML, sus ocho
## recetas-. `EstadioPropio.ajustes["sonidoGol"]` se podía elegir y pagar, pero `Sonido`
## tocaba siempre el mismo "gol" fijo: era un desplegable que no hacía nada. Todas llevan
## debajo el mismo rugido de grada (`ruido(0,2.1,700,220,0.17)`, que en el HTML va antes
## del `if`), y los `setTimeout(cantico...)` son `_cantico()` mezclado con retraso (cada una
## abre con un lienzo de su duración; si una capa acaba después, `_mezclar()` alarga el
## destino). Diferencias honestas: `_tono()` no tiene glissando ni onda
## triangular, así que la sirena se hace por tramos y el triángulo es un seno.

func _receta_gol_bombo(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(3.3)
	_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
	for golpe_b in 7:
		_bombo(m, float(golpe_b) * 0.42, 0.17)
	var trompeta := [523.0, 523.0, 659.0, 784.0, 784.0, 659.0]
	for nt in trompeta.size():
		_mezclar(m, _tono(float(trompeta[nt]) * alto, 0.34, 0.045, "sierra"), 0.5 + float(nt) * 0.42)
	_mezclar(m, _cantico(1.25), 1.0)
	return m

func _receta_gol_sirena(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(3.8)
	_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
	var tramos := [88.0, 102.0, 120.0, 130.0, 124.0, 118.0]
	for tr in tramos.size():
		_mezclar(m, _tono(float(tramos[tr]) * alto, 0.70, 0.09, "sierra"), float(tr) * 0.55)
	_mezclar(m, _tono(66.0 * alto, 3.40, 0.05, "seno"))
	return m

func _receta_gol_campana(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(5.3)
	_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
	var parciales := [1.0, 2.76, 5.4, 8.9]
	for golpe_c in 4:
		var t_camp := float(golpe_c) * 0.95
		for pj in parciales.size():
			_mezclar(m, _tono(262.0 * float(parciales[pj]) * alto, 2.4 / float(pj + 1), 0.055 / float(pj + 1), "seno"), t_camp)
		_mezclar(m, _ruido(0.12, 3200.0, 1800.0, 0.03), t_camp)
	_mezclar(m, _cantico(1.1), 1.8)
	return m

func _receta_gol_organo(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(3.6)
	_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
	var acordes := [[262.0, 330.0, 392.0], [294.0, 370.0, 440.0], [349.0, 440.0, 523.0], [392.0, 494.0, 587.0]]
	for ac in acordes.size():
		for f_org in (acordes[ac] as Array):
			_mezclar(m, _tono(float(f_org) * alto, 0.62, 0.035, "sierra"), float(ac) * 0.55)
			_mezclar(m, _tono(float(f_org) * 2.0 * alto, 0.60, 0.018, "seno"), float(ac) * 0.55)
	_mezclar(m, _cantico(1.15), 1.4)
	return m

func _receta_gol_explosion(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(3.3)
	_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
	_mezclar(m, _ruido(0.50, 1800.0, 60.0, 0.28))
	_mezclar(m, _tono(44.0 * alto, 0.70, 0.20, "seno"))
	_mezclar(m, _ruido(1.10, 900.0, 200.0, 0.09), 0.42)
	for chispa in 5:
		_mezclar(m, _ruido(0.14, 2600.0, 1400.0, 0.06), 1.1 + float(chispa) * 0.17)
	_mezclar(m, _cantico(1.35), 1.1)
	return m

func _receta_gol_sintetico(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.2)
	_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
	_mezclar(m, _tono(880.0 * alto, 0.10, 0.05, "cuadrada"))
	_mezclar(m, _tono(1174.0 * alto, 0.10, 0.05, "cuadrada"), 0.09)
	_mezclar(m, _tono(1568.0 * alto, 0.50, 0.06, "cuadrada"), 0.18)
	_mezclar(m, _tono(98.0 * alto, 0.90, 0.09, "sierra"))
	_mezclar(m, _ruido(0.90, 4200.0, 900.0, 0.06), 0.16)
	for eco in 3:
		_mezclar(m, _tono(1568.0 * alto, 0.12, 0.03, "seno"), 0.7 + float(eco) * 0.14)
	return m

func _receta_gol_tambores(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(3.4)
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
	return m

## "Solo la gente": sin efecto, el rugido puro y dos cánticos.
func _receta_gol_silencio(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(4.8)
	_mezclar(m, _ruido(2.10, 700.0, 220.0, 0.17))
	_mezclar(m, _ruido(2.60, 520.0, 180.0, 0.11), 0.1)
	_mezclar(m, _cantico(1.4), 0.5)
	_mezclar(m, _cantico(1.2), 2.6)
	return m

# --- Festejos y goles especiales ---------------------------------------------------------

func _receta_celebracion_grupal(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.0)
	_mezclar(m, _ruido(1.60, 700.0, 2200.0, 0.15))
	_mezclar(m, _cantico(1.0), 0.4)
	return m

func _receta_celebracion_individual(_alto: float, largo: float) -> PackedFloat32Array:
	return _ruido(1.00 * largo, 700.0, 2000.0, 0.10)

func _receta_festejo_banco(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.20)
	_mezclar(m, _ruido(0.90, 700.0, 1800.0, 0.10))
	return m

func _receta_festejo_hinchada_extra(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.60)
	_mezclar(m, _ruido(2.20, 600.0, 2400.0, 0.20))
	_mezclar(m, _cantico(1.5), 0.4)
	_mezclar(m, _cantico(1.3), 2.0)
	return m

func _receta_remontada(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(3.0)
	_mezclar(m, _ruido(2.40, 700.0, 220.0, 0.20))
	for hz7 in [392.0, 523.0, 659.0]:
		_mezclar(m, _tono(float(hz7) * alto, 0.50, 0.06, "sierra"), 0.10)
	_mezclar(m, _cantico(1.3), 1.0)
	return m

func _receta_gol_agonico(_alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(3.4)
	_mezclar(m, _ruido(0.20, 1900.0, 900.0, 0.05))
	_mezclar(m, _ruido(2.60, 700.0, 220.0, 0.24), 0.25)
	_mezclar(m, _cantico(1.6), 0.6)
	return m

func _receta_hat_trick(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.6)
	for hz8 in [523.0, 659.0, 784.0]:
		_mezclar(m, _tono(float(hz8) * alto, 0.30, 0.06, "sierra"), (hz8 - 523.0) / 261.0 * 0.20)
	_mezclar(m, _ruido(1.80, 700.0, 2000.0, 0.14), 0.60)
	return m

func _receta_doblete(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.8)
	_mezclar(m, _tono(523.0 * alto, 0.20, 0.06, "sierra"))
	_mezclar(m, _tono(659.0 * alto, 0.30, 0.06, "sierra"), 0.20)
	_mezclar(m, _ruido(1.20, 700.0, 2000.0, 0.10), 0.45)
	return m

func _receta_gol_rapido(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.0)
	_mezclar(m, _ruido(1.60, 700.0, 220.0, 0.18))
	_mezclar(m, _tono(880.0 * alto, 0.10, 0.05, "seno"))
	return m

func _receta_gol_confirmado_var(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(2.4)
	for i7 in 2:
		_mezclar(m, _tono(1400.0 * alto, 0.10, 0.04, "cuadrada"), float(i7) * 0.22)
	_mezclar(m, _ruido(1.60, 700.0, 2200.0, 0.16), 0.50)
	return m

# --- Títulos, rondas y temporada ---------------------------------------------------------

## El festejo mas largo del catalogo: fanfarria de cuatro notas +
## rugido + dos "canticos" de tribuna a los 0.7s y a los 3s -los
## `setTimeout(...,700)` y `...,3000)` del HTML-. El lienzo de 5 s es
## de cuando `_mezclar()` no alargaba el destino; aun así se quedaba
## corto en las variantes breves (el cántico de los 3 s dura 2,1 s y
## se comía el final). Desde el 25-10-2026 `_mezclar()` alarga.
func _receta_trofeo(alto: float, largo: float) -> PackedFloat32Array:
	var m := _lienzo(5.0 * largo)
	_mezclar(m, _tono(523.0 * alto, 0.14 * largo, 0.05, "cuadrada"))
	_mezclar(m, _tono(659.0 * alto, 0.14 * largo, 0.05, "cuadrada"), 0.14)
	_mezclar(m, _tono(784.0 * alto, 0.14 * largo, 0.05, "cuadrada"), 0.28)
	_mezclar(m, _tono(1047.0 * alto, 0.50 * largo, 0.05, "cuadrada"), 0.42)
	_mezclar(m, _ruido(2.40 * largo, 700.0, 240.0, 0.15))
	_mezclar(m, _cantico(1.3), 0.70)
	_mezclar(m, _cantico(1.3), 3.00)
	return m

## Pasas de ronda: no es un título -eso es "trofeo"-, es seguir vivo.
## Cuatro notas que suben y la grada detrás, y se acaba.
func _receta_ronda_superada(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.80)
	_mezclar(m, _tono(330.0 * alto, 0.16, 0.050, "sierra"))
	_mezclar(m, _tono(392.0 * alto, 0.16, 0.050, "sierra"), 0.14)
	_mezclar(m, _tono(494.0 * alto, 0.16, 0.050, "sierra"), 0.28)
	_mezclar(m, _tono(659.0 * alto, 0.60, 0.060, "sierra"), 0.42)
	_mezclar(m, _ruido(1.30, 500.0, 1700.0, 0.11), 0.20)
	return m

## Una subida de tres escalones mas una nota larga y un oleaje de
## grada: mas grande que "fichaje", mas corto que "trofeo" -no hay
## cantico, esto no es un titulo-.
func _receta_ascenso(alto: float, largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.6 * largo)
	_mezclar(m, _tono(392.0 * alto, 0.18 * largo, 0.06, "sierra"))
	_mezclar(m, _tono(494.0 * alto, 0.18 * largo, 0.06, "sierra"), 0.16)
	_mezclar(m, _tono(587.0 * alto, 0.18 * largo, 0.06, "sierra"), 0.32)
	_mezclar(m, _tono(784.0 * alto, 0.55 * largo, 0.08, "sierra"), 0.48)
	_mezclar(m, _ruido(1.10 * largo, 400.0, 1600.0, 0.12), 0.10)
	return m

## El espejo del ascenso: ruido que se apaga y tres escalones
## bajando, largo porque es un golpe que se asienta, no un
## sobresalto como "gol_rival".
func _receta_descenso(alto: float, largo: float) -> PackedFloat32Array:
	var m := _lienzo(1.6 * largo)
	_mezclar(m, _ruido(1.30 * largo, 500.0, 160.0, 0.12))
	_mezclar(m, _tono(311.0 * alto, 0.30 * largo, 0.05, "sierra"), 0.05)
	_mezclar(m, _tono(262.0 * alto, 0.30 * largo, 0.05, "sierra"), 0.30)
	_mezclar(m, _tono(196.0 * alto, 0.50 * largo, 0.06, "sierra"), 0.60)
	return m

## Ocho notas de himno de club, en modo mayor y con eco de estadio.
## No es el himno de nadie: es un motivo genérico que suena a uno.
func _receta_himno(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(3.60)
	var notas := [392.0, 392.0, 523.0, 494.0, 440.0, 392.0, 349.0, 392.0]
	for i in notas.size():
		var t0h := float(i) * 0.40
		var hz: float = float(notas[i]) * alto
		_mezclar(m, _tono(hz, 0.42, 0.050, "sierra"), t0h)
		_mezclar(m, _tono(hz * 2.0, 0.34, 0.020, "seno"), t0h)
		## El eco: la misma nota 90 ms después y a un tercio de volumen.
		_mezclar(m, _tono(hz, 0.34, 0.017, "sierra"), t0h + 0.09)
	_mezclar(m, _ruido(3.40, 240.0, 700.0, 0.035))
	return m

## El cierre del año: acorde largo que se abre y se apaga. Ni
## celebración ni derrota —la temporada se acabó y ya está—.
func _receta_fin_temporada(alto: float, _largo: float) -> PackedFloat32Array:
	var m := _lienzo(3.00)
	for hz2 in [262.0, 330.0, 392.0, 523.0]:
		_mezclar(m, _tono(float(hz2) * alto, 2.60, 0.045, "seno"), 0.0)
	_mezclar(m, _ruido(2.40, 500.0, 200.0, 0.07), 0.20)
	return m
