extends Node
## LAS CIFRAS DEL PARTIDO SIMULADO CONTRA EL FÚTBOL REAL (3-11-2026, orden del líder): juega TODOS los cruces (ida y vuelta) de las primeras divisiones de varias ligas, en varias
## semillas, y da por partido: goles, amarillas, rojas, penales, córners, faltas, remates, posesión (del grande en casa frente a un chico, y al revés) y el reparto de resultados.
## Referencias del fútbol real (primeras divisiones europeas y sudamericanas): goles 2,4-2,9 · amarillas 3,5-4 · rojas 0,1-0,2 · penales 0,25-0,3 · córners ~10 · faltas ~22 ·
## empates ~25 % · victoria local ~45 % · posesión del grande en casa ~58-65 %. Herramienta, no prueba del banco.
##   godot --headless --path . res://pruebas/zz_medir_stats.tscn      (SEMILLAS=3 PAISES=CHI,ARG,ESP,ENG)
var _n := 0
var _t := {}
var _amarillas := 0
var _rojas := 0
var _penales := 0
var _gl_ganan := 0
var _empates := 0
var _gl_pos_grande := 0.0
var _n_grande := 0
var _gl_pos_chico := 0.0
var _n_chico := 0

func _on_tarjeta(_j: Jugador, roja: bool, _m: int) -> void:
	if roja:
		_rojas += 1
	else:
		_amarillas += 1

func _on_decision(texto: String, _m: int) -> void:
	if texto.contains("Penal para"):
		_penales += 1

func _sumar(k: String, v: float) -> void:
	_t[k] = float(_t.get(k, 0.0)) + v

func _ready() -> void:
	var paises := (OS.get_environment("PAISES") if OS.get_environment("PAISES") != "" else "CHI,ARG,ESP,ENG").split(",")
	var semillas := int(OS.get_environment("SEMILLAS")) if OS.get_environment("SEMILLAS") != "" else 3
	var lista: Array[String] = []
	for x in paises:
		lista.append(String(x))
	for s in semillas:
		var m := Mundo.new()
		m.generar(lista, 1000 + s * 77)
		m.reloj.sincronizar(m.anio, m.semana)
		Partido.ctx_anio = m.anio
		Partido.ctx_semana = m.semana
		for liga: Liga in m.ligas:
			if liga.division() != 1:
				continue
			var clubes: Array = liga.clubes.duplicate()
			clubes.sort_custom(func(a: Club, b: Club) -> bool: return a.rep > b.rep)
			_cruzar(clubes, maxi(1, clubes.size() / 4))
	var f := float(maxi(1, _n))
	print("PARTIDOS %d (primeras de %s, %d semillas)" % [_n, ",".join(lista), semillas])
	print("  goles %.2f · amarillas %.2f · rojas %.2f · penales %.2f · córners %.1f · faltas %.1f · remates %.1f (a puerta %.1f) · fueras %.1f" % [
		float(_t["goles"]) / f, _amarillas / f, _rojas / f, _penales / f, float(_t["corners"]) / f, float(_t["faltas"]) / f, float(_t["remates"]) / f, float(_t["a_puerta"]) / f, float(_t["fueras"]) / f])
	print("  victoria local %.1f %% · empates %.1f %% · victoria visitante %.1f %%" % [100.0 * _gl_ganan / f, 100.0 * _empates / f, 100.0 * (f - _gl_ganan - _empates) / f])
	print("  posesión del local: grande en casa vs chico %.1f %% (%d) · chico en casa vs grande %.1f %% (%d)" % [_gl_pos_grande / maxf(1.0, _n_grande), _n_grande, _gl_pos_chico / maxf(1.0, _n_chico), _n_chico])
	get_tree().quit()

## Todos los cruces (ida y vuelta) de una liga de primera división.
func _cruzar(clubes: Array, cuarto: int) -> void:
	for a: Club in clubes:
		for b: Club in clubes:
			if a == b:
				continue
			_jugar(a, b, clubes, cuarto)

## Un partido: reinicia sanciones y lesiones, lo simula y anota sus estadísticas.
func _jugar(a: Club, b: Club, clubes: Array, cuarto: int) -> void:
	for c: Club in [a, b]:
		for j: Jugador in c.plantilla:
			j.suspension = 0
			j.lesion = 0
	var p := Partido.new(a, b)
	p.tarjeta.connect(_on_tarjeta)
	p.decision_arbitral.connect(_on_decision)
	p.simular()
	_n += 1
	_sumar("goles", p.goles_local + p.goles_visita)
	_sumar("corners", p.corners_local + p.corners_visita)
	_sumar("faltas", p.faltas_local + p.faltas_visita)
	_sumar("remates", p.remates_local + p.remates_visita)
	_sumar("a_puerta", p.tiros_puerta_local + p.tiros_puerta_visita)
	_sumar("fueras", p.fueras_local + p.fueras_visita)
	if p.goles_local > p.goles_visita:
		_gl_ganan += 1
	elif p.goles_local == p.goles_visita:
		_empates += 1
	var rl := clubes.find(a)
	var rv := clubes.find(b)
	if rl < cuarto and rv >= clubes.size() - cuarto:
		_gl_pos_grande += p.posesion_local
		_n_grande += 1
	elif rv < cuarto and rl >= clubes.size() - cuarto:
		_gl_pos_chico += p.posesion_local
		_n_chico += 1
