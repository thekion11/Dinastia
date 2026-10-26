extends "res://pruebas/banco/partido_p5.gd"
## [Capa 6/6 de `partido.gd`] _probar_prorroga_y_penales, _probar_partido_abandonado

## PRÓRROGA Y PENALES (17-10-2026). Lo que no necesita el 3D: el acta que se
## alarga al 120' con un cambio más, la tanda del césped que `penales()` ya no
## vuelve a sortear (y la copa respeta), el reloj de la prórroga del motor y
## cuándo está decidida una tanda. La prueba con el partido entero en el
## césped es `pruebas/prueba_prorroga_penales.tscn`.
func _probar_prorroga_y_penales() -> void:
	_titulo("PRÓRROGA Y TANDA DE PENALES DEL MOTOR REAL")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var p := Partido.new(a, b)
	p.preparar()
	p.motor_externo = true
	while p.minuto < 89:
		p.simular_minuto()
	p.prorroga_externa()
	p.simular_minuto()
	_comprobar(not p.terminado_ya and p.minuto == 90 and p.minutos_fin == 120, "con prórroga el acta no termina en el 90'")
	_comprobar(p.MAX_CAMBIOS + p.cambios_extra == 6, "en la prórroga hay un cambio más")
	p.penales_externos(3, 4)
	while not p.terminado_ya:
		p.simular_minuto()
	_comprobar(p.minuto == 120, "el acta termina en el 120'")
	_comprobar(p.penales() == [3, 4] and p.penales() == [3, 4] and p.penales_en_cesped, "`penales()` devuelve la tanda del césped, siempre la misma")
	var copa := Copa.new("Copa de prueba")
	copa.vivos.assign([a, b])
	p.goles_local = 1
	p.goles_visita = 1
	var res := copa.jugar_ronda(p)
	_comprobar(not res.is_empty() and (res[0] as Dictionary)["pasa"] == b and (res[0] as Dictionary)["penales"] == [3, 4], "la copa clasifica al que ganó la tanda del césped")
	var p2 := Partido.new(a, b)
	p2.preparar()
	while not p2.terminado_ya:
		p2.simular_minuto()
	_comprobar(p2.minuto == 90 and not p2.penales_en_cesped, "sin motor ni prórroga: termina en el 90' como siempre")
	## El reloj del motor en la prórroga.
	var mo := MotorJugable.new()
	mo.duracion_mitad = 180.0
	mo.sortear_anadido()
	mo.mitad = 3
	mo.t = 30.0
	var m3 := mo.minuto()
	mo.mitad = 4
	mo.t = 59.0
	var m4 := mo.minuto()
	_comprobar(m3 == 97 and m4 == 119 and is_equal_approx(mo.dur_mitad(), 60.0), "prórroga de 15' (un tercio de la mitad): 97' y 119' (%d', %d')" % [m3, m4])
	_comprobar(mo.anadido.size() == 4 and mo._anadido_de(4) > 0.0, "la prórroga tiene su añadido")
	mo.free()
	_comprobar(MotorJugable.tanda_decidida([[true, true, true], [false, false, false]]), "tanda: 3-0 tras tres cada uno está decidida")
	_comprobar(not MotorJugable.tanda_decidida([[true, true, true, true, true], [true, true, true, true, true]]), "tanda: 5-5 sigue a muerte súbita")
	_comprobar(MotorJugable.tanda_decidida([[true, true, true, true, true, false], [true, true, true, true, true, true]]), "tanda: 5-6 en la muerte súbita está decidida")
	_comprobar(not MotorJugable.tanda_decidida([[true, true, true, true, true, true], [true, true, true, true, true]]), "tanda: en la muerte súbita el segundo aún tira")
	var circ := MarcadorTanda.circulos([true, false], 5)
	_comprobar(circ.count("●") == 2 and circ.count("○") == 3, "el marcador de la tanda pinta ●● y tres huecos")

## EL PARTIDO ABANDONADO A MEDIAS (17-10-2026): cerrar el juego perdiendo y
## volver a cargar NO repite el partido desde el 0-0, y recargar no cambia nada.
func _probar_partido_abandonado() -> void:
	_titulo("PARTIDO ABANDONADO A MEDIAS: NO SE PUEDE REPETIR HASTA GANAR")
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var par := m.proximo_partido()
	var p := Partido.new(par[0], par[1])
	p.preparar()
	PartidoPendiente.abrir(m, p)
	p.goles_local = 0
	p.goles_visita = 2
	p.minuto = 60
	PartidoPendiente.actualizar(m, p)
	## La partida tal como quedó guardada (recargarla es partir siempre de aquí).
	var foto := Partida.instantanea(m)
	var d := PartidoPendiente.pendiente(m)
	_comprobar(not d.is_empty() and int(d["gv"]) == 2 and int(d["minuto"]) == 60, "el partido en curso queda apuntado con su marcador y su minuto")
	var r1 := PartidoPendiente.resolver(m, d)
	_comprobar(r1 != null and r1.terminado_ya and r1.goles_visita >= 2, "al cargar se completa desde el 0-2 del 60' (no desde 0-0): %d-%d" % [r1.goles_local, r1.goles_visita])
	_comprobar(PartidoPendiente.pendiente(m).is_empty(), "una vez resuelto, deja de estar pendiente")
	## Recargar = otra vez el mismo resultado (azar fijo para ese partido).
	var m2 := Partida.desde_instantanea(foto)
	var r2 := PartidoPendiente.resolver(m2, d)
	_comprobar(r2 != null and r2.goles_local == r1.goles_local and r2.goles_visita == r1.goles_visita, "recargar da el mismo resultado (%d-%d)" % [r2.goles_local, r2.goles_visita])
	d["minuto"] = 90
	var r3 := PartidoPendiente.resolver(m, d)
	_comprobar(r3 != null and r3.goles_local == 0 and r3.goles_visita == 2, "si ya se había pitado el final, queda el resultado tal cual")
