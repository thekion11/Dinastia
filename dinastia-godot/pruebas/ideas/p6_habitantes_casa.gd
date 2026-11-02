extends BaseIdea
## M-187: la gente de una vivienda cambia con la hora (duerme de noche, cocina en las comidas, ve la tele por la tarde).

func _probar() -> void:
	_titulo("P6: HABITANTES DE LA VIVIENDA SEGÚN LA HORA")
	var noche := HabitantesCasa.plan(2.0)
	_comprobar(not bool(noche["cocina"]) and not bool(noche["sofa"]) and not bool(noche["pasea"]) and float(noche["mesa"]) == 0.0 and String(noche["estado"]) == "Duermen", "a las 2:00 la familia duerme: nadie a la vista")
	var desayuno := HabitantesCasa.plan(7.5)
	_comprobar(bool(desayuno["cocina"]) and float(desayuno["mesa"]) > 0.5 and not bool(desayuno["sofa"]), "a las 7:30 se cocina y se desayuna")
	var tarde := HabitantesCasa.plan(16.0)
	_comprobar(bool(tarde["pasea"]) and not bool(tarde["cocina"]) and not bool(tarde["sofa"]), "a las 16:00 alguien anda por casa y no se cocina")
	var tele := HabitantesCasa.plan(22.0)
	_comprobar(bool(tele["sofa"]) and not bool(tele["pasea"]), "a las 22:00 se ve la tele en el sofá")
	var cena := HabitantesCasa.plan(20.0)
	_comprobar(bool(cena["cocina"]) and bool(cena["sofa"]) and float(cena["mesa"]) > 0.5, "a las 20:00 se cena (y la tele ya está puesta)")
	var cambian := {}
	for h in range(0, 24):
		cambian[String(HabitantesCasa.plan(float(h))["estado"])] = true
	_comprobar(cambian.size() >= 4, "a lo largo del día hay %d estados distintos" % cambian.size())
	PersonalEstadio.hora = -1.0
	_comprobar(is_equal_approx(HabitantesCasa.hora_actual(), 12.0), "sin reloj de ciudad se asume mediodía")
	PersonalEstadio.hora = 22.5
	_comprobar(is_equal_approx(HabitantesCasa.hora_actual(), 22.5), "con reloj usa la hora de la ciudad")
	PersonalEstadio.hora = -1.0
