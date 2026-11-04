extends BaseIdea
## LAS CIFRAS DEL PARTIDO SIMULADO, CONTRA EL FÚTBOL REAL (3-11-2026): juega todos los cruces (ida y vuelta) de las primeras de CHI y ARG (480 partidos, semilla fija) y comprueba que
## los promedios por partido caen en el rango real, con margen para el ruido de la muestra (σ del promedio ≈ 0,12 en amarillas, ≈ 0,03 en goles). Para medir más ancho y por partes:
## `zz_medir_stats.tscn`. Si una de estas cifras sale a propósito de su rango (se retoca el balance), se cambia aquí diciéndolo.
##   (4-11, recalibración del simulado: decisión del dueño) remates 21-29 · a puerta 7,3-9,7 · conversión por remate 9-13 % · el portero para el 60-80 % de lo que va a puerta
##   goles 2,4-2,95 · amarillas 3,3-4,2 · rojas 0,08-0,25 · penales 0,2-0,4 · córners 9-11,5 · faltas 20-25 · fueras 3-5 · empates 20-31 % · victoria local 40-52 %
var _amarillas := 0
var _rojas := 0
var _penales := 0
var _remates := 0
var _a_puerta := 0

func _decision(texto: String, _m: int) -> void:
	if "Penal para" in texto:
		_penales += 1

func _tarjeta(_j: Jugador, roja: bool, _m: int) -> void:
	if roja:
		_rojas += 1
	else:
		_amarillas += 1

func _ready() -> void:
	await get_tree().process_frame
	_titulo("CIFRAS DEL PARTIDO SIMULADO")
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 1000)
	m.reloj.sincronizar(m.anio, m.semana)
	Partido.ctx_anio = m.anio
	Partido.ctx_semana = m.semana
	var n := 0
	var goles := 0.0
	var corners := 0.0
	var faltas := 0.0
	var fueras := 0.0
	var empates := 0
	var locales := 0
	for liga: Liga in m.ligas:
		if liga.division() != 1:
			continue
		for a: Club in liga.clubes:
			for b: Club in liga.clubes:
				if a == b:
					continue
				for c: Club in [a, b]:
					for j: Jugador in c.plantilla:
						j.suspension = 0
						j.lesion = 0
				var p := Partido.new(a, b)
				p.tarjeta.connect(_tarjeta)
				p.decision_arbitral.connect(_decision)
				p.simular()
				n += 1
				goles += p.goles_local + p.goles_visita
				_remates += p.remates_local + p.remates_visita
				_a_puerta += p.tiros_puerta_local + p.tiros_puerta_visita
				corners += p.corners_local + p.corners_visita
				faltas += p.faltas_local + p.faltas_visita
				fueras += p.fueras_local + p.fueras_visita
				if p.goles_local == p.goles_visita:
					empates += 1
				elif p.goles_local > p.goles_visita:
					locales += 1
	var f := float(maxi(1, n))
	print("  %d partidos: goles %.2f · amarillas %.2f · rojas %.2f · penales %.2f · córners %.1f · faltas %.1f · fueras %.1f · empates %.1f %%" % [n, goles / f, _amarillas / f, _rojas / f, _penales / f, corners / f, faltas / f, fueras / f, 100.0 * empates / f])
	_comprobar(n >= 400, "se jugaron %d partidos" % n)
	_comprobar(goles / f >= 2.4 and goles / f <= 2.95, "goles por partido %.2f dentro de 2,4-2,95" % (goles / f))
	_comprobar(_remates / f >= 21.0 and _remates / f <= 29.0, "remates por partido %.1f dentro de 21-29 (~25 en el fútbol real)" % (_remates / f))
	_comprobar(_a_puerta / f >= 7.3 and _a_puerta / f <= 9.7, "remates a puerta por partido %.1f dentro de 7,3-9,7 (~8,5)" % (_a_puerta / f))
	var conv := goles / maxf(1.0, float(_remates))
	_comprobar(conv >= 0.09 and conv <= 0.13, "conversión por remate %.1f %% dentro de 9-13 %% (~11 %%)" % (100.0 * conv))
	var paradas := 1.0 - goles / maxf(1.0, float(_a_puerta))
	_comprobar(paradas >= 0.60 and paradas <= 0.80, "el portero para el %.0f %% de lo que va a puerta (60-80 %%)" % (100.0 * paradas))
	_comprobar(_amarillas / f >= 3.3 and _amarillas / f <= 4.2, "amarillas por partido %.2f dentro de 3,3-4,2" % (_amarillas / f))
	_comprobar(_rojas / f >= 0.08 and _rojas / f <= 0.25, "rojas por partido %.2f dentro de 0,08-0,25" % (_rojas / f))
	_comprobar(_penales / f >= 0.2 and _penales / f <= 0.4, "penales por partido %.2f dentro de 0,2-0,4" % (_penales / f))
	_comprobar(corners / f >= 9.0 and corners / f <= 11.5, "córners por partido %.1f dentro de 9-11,5" % (corners / f))
	_comprobar(faltas / f >= 20.0 and faltas / f <= 25.0, "faltas por partido %.1f dentro de 20-25" % (faltas / f))
	_comprobar(fueras / f >= 3.0 and fueras / f <= 5.0, "fueras de juego por partido %.1f dentro de 3-5" % (fueras / f))
	_comprobar(100.0 * empates / f >= 20.0 and 100.0 * empates / f <= 31.0, "empates %.1f %% dentro de 20-31 %%" % (100.0 * empates / f))
	_comprobar(100.0 * locales / f >= 40.0 and 100.0 * locales / f <= 52.0, "victoria local %.1f %% dentro de 40-52 %%" % (100.0 * locales / f))
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
