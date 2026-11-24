extends "res://pruebas/banco/partido_p4_h.gd"
## [Capa 4/6 de `partido.gd`] _probar_tanda_c_1


## [Capa 21/27 de `banco.gd`] _probar_tanda_c_1

## TANDA C: instalaciones a 10 niveles (tribunas a 5, rendimiento a la mitad por
## encima de 5), trabajadores con carácter y eventos, asuntos de la academia, las
## ramas compiten, pierna débil y premios en la ficha.
## Tramo 1 de 2 de `_probar_tanda_c` (la norma de 450 líneas la troceó).
func _probar_tanda_c_1() -> Array:
	_titulo("TANDA C: INSTALACIONES, TRABAJADORES, CANTERA, RAMAS, FICHA")
	var m := Mundo.new()
	m.generar(["CHI"], 5150)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.saldo = 2000000000
	var o := m.obras
	_pt_instalaciones(m, c, o)
	_pt_personal(m, c, o)
	_pt_reputacion(m, c, o)
	_pt_retos()
	var mf := _pt_fundar()
	_pt_redes(mf)
	_pt_movil(mf)
	_pt_contratos()
	_pt_mercado(mf)
	_pt_insolvencia()
	_pt_reglamento()
	_pt_editor_competiciones()
	_pt_estadio_colores(mf)
	_pt_balones(mf)
	_pt_camisetas_pase(mf)
	var cj := _pt_carrera(mf)
	return [m, c, o, mf, cj[0], cj[1], cj[2]]

## (12-11, sesión 15) EL REMATE DE CABEZA EN C4 (`MejorasC4Cabeza`): al palo contrario al portero, abajo y más fuerte; fuera de C4, nada.
func _probar_cabeza_c4() -> void:
	_titulo("C4: EL REMATE DE CABEZA")
	var r := _motor_de_prueba(11)
	var motor: MotorJugable = r[0]
	var yo: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return bool(p["es_local"]) and not bool(p["por"]))[0]
	var gk: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and bool(p["por"]))[0]
	var arco := motor._arco_rival(yo)
	(gk["node"] as Node3D).position = Vector3(2.0, 0, arco.z)
	var d := Vector3(2.5, 1.8, arco.z)
	var antes := [MejorasC4Cabeza.activo, MejorasC4Cabeza.solo_c4]
	MejorasC4Cabeza.activo = true
	_comprobar(MejorasC4Cabeza.destino(motor, yo, d) == d and is_equal_approx(MejorasC4Cabeza.velocidad(motor, 15.0), 15.0), "fuera de C4 no cambia nada")
	MejorasC4Cabeza.solo_c4 = false
	var otro := 0
	var abajo := true
	for i in 40:
		var n := MejorasC4Cabeza.destino(motor, yo, d)
		otro += 1 if n.x < 0.0 else 0
		abajo = abajo and n.y <= 1.2 and is_equal_approx(absf(n.x), d.x)
	_comprobar(abajo, "el cabezazo va abajo y al mismo ancho")
	_comprobar(otro > 15 and otro < 40, "con el portero cargado a un palo, casi siempre al otro (%d de 40)" % otro)
	var fuera := Vector3(5.0, 1.0, arco.z)
	_comprobar(MejorasC4Cabeza.destino(motor, yo, fuera) == fuera, "el cabezazo que ya va fuera no se toca")
	_comprobar(MejorasC4Cabeza.velocidad(motor, 15.0) > 15.0, "sale más fuerte")
	MejorasC4Cabeza.activo = antes[0]; MejorasC4Cabeza.solo_c4 = antes[1]
	(r[1] as Node3D).queue_free()

## (12-11, sesión 15) MÁS PASES AL HUECO EN C4 (`MejorasC4Hueco`): el lateral que se incorpora también recibe al espacio; con la línea tapada, no.
func _probar_hueco_c4() -> void:
	_titulo("C4: MÁS PASES AL HUECO")
	var r := _motor_de_prueba(13)
	var motor: MotorJugable = r[0]
	var yo: Dictionary = {}
	var lat: Dictionary = {}
	for p: Dictionary in motor.jugadores:
		(p["node"] as Node3D).position = Vector3(-30.0, 0, -50.0) if bool(p["es_local"]) else Vector3(30.0, 0, -20.0)
		if bool(p["es_local"]) and not bool(p["por"]):
			if yo.is_empty() and motor._rol(p) == "MC":
				yo = p
			elif lat.is_empty() and motor._rol(p) in ["LD", "LI"]:
				lat = p
	var d := motor.dir_ataque(true)
	var linea := motor._ultima_linea(false)
	(yo["node"] as Node3D).position = Vector3(0, 0, linea - d * 15.0)
	(lat["node"] as Node3D).position = Vector3(8.0, 0, linea - d * 1.0)
	var antes := MejorasC4Hueco.activo
	MejorasC4Hueco.activo = false
	_comprobar(MejorasC4Hueco.buscar(motor, yo).is_empty(), "con la bandera apagada no busca")
	MejorasC4Hueco.activo = true
	_comprobar(MejorasC4Hueco.buscar(motor, yo) == lat, "el lateral que se incorpora recibe al hueco")
	var rival: Dictionary = motor.jugadores.filter(func(p: Dictionary) -> bool: return not bool(p["es_local"]) and not bool(p["por"]))[0]
	(rival["node"] as Node3D).position = ((yo["node"] as Node3D).position + (lat["node"] as Node3D).position + Vector3(0, 0, d * 7.0)) * 0.5
	_comprobar(MejorasC4Hueco.buscar(motor, yo).is_empty(), "con un rival en la línea de pase, no")
	MejorasC4Hueco.activo = antes
	(r[1] as Node3D).queue_free()
