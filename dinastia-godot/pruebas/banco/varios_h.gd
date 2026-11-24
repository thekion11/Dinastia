extends "res://pruebas/banco/varios_p13.gd"
## [Capa de `varios.gd`, 21-11 refactor de forma] Secciones de «TOP 25 (2.ª TANDA)»: cambio, sorteo,
## valoraciones, despido y escudo. Cada bloque es independiente (el de valoraciones comparte su
## mundo dentro de la sección); el orden de las comprobaciones y los textos son los de antes.


## M-104: el cartel del cambio, con los dos dorsales por las dos caras.
func _tp_cartel() -> void:
	var cartel := CuartoArbitro.cartel_lineas([["9", CuartoArbitro.VERDE], ["17", CuartoArbitro.ROJO]])
	var nueves := 0
	var diecisiete := 0
	for l in cartel.find_children("*", "Label3D", true, false):
		nueves += 1 if (l as Label3D).text == "9" else 0
		diecisiete += 1 if (l as Label3D).text == "17" and (l as Label3D).modulate == CuartoArbitro.ROJO else 0
	_comprobar(nueves == 2 and diecisiete == 2, "cambio: cartel con el que entra (verde) y el que sale (rojo) por las dos caras")
	cartel.free()


## M-104: la escena (el que entra espera sujeto, palmada, se suelta, se va).
func _tp_escena_cambio() -> void:
	## M-104: la escena (el que entra espera sujeto, palmada, se suelta, se va).
	var motor := MotorJugable.new()
	add_child(motor)
	motor.set_physics_process(false)
	var raiz := Node3D.new()
	add_child(raiz)
	var sale := Node3D.new()
	raiz.add_child(sale)
	sale.position = Vector3(30.0, 0, 2.0)
	var en_nodo := Node3D.new()
	raiz.add_child(en_nodo)
	en_nodo.position = Vector3(10.0, 0, 0)
	var entra := {"node": en_nodo, "vel": Vector3.ONE}
	var esc := EscenaCambio.iniciar(raiz, null, motor, sale, null, entra, 17, 9)
	_comprobar(esc != null and raiz.get_node_or_null("CuartoArbitro") != null, "cambio: sale el cuarto árbitro con el cartel")
	var fases: Array = []
	var quieto := true
	for i in 120:
		motor.t += 0.1
		en_nodo.position += Vector3(-0.3, 0, 0)   ## como si el motor lo moviera
		if is_instance_valid(esc):
			esc._process(0.1)
			if not fases.has(esc.fase):
				fases.append(esc.fase)
			if esc.fase == "acude" and en_nodo.position.distance_to(Vector3(EscenaCambio.X_LINEA, 0, EscenaCambio.Z_ESPERA)) > 0.01:
				quieto = false
	_comprobar(quieto, "cambio: el que entra espera en la banda hasta la palmada")
	_comprobar(fases.has("palmada") and fases.has("se_va"), "cambio: se chocan la mano y el que sale se va (%s)" % str(fases))
	_comprobar(is_equal_approx(float(entra.get("freno_duelo", 0.0)), 1.0), "cambio: el que entra queda suelto después")
	_comprobar(not is_instance_valid(esc) or esc.is_queued_for_deletion(), "cambio: la escena se borra sola")
	motor.queue_free()
	raiz.queue_free()


## M-160 y clips: el sorteo cabe en la ceremonia; los gestos existen.
func _tp_sorteo_clips() -> void:
	## M-160 y clips: el sorteo cabe en la ceremonia; los gestos existen.
	_comprobar(CeremoniaPartido.T_FIN >= CeremoniaPartido.T_VUELO + CeremoniaPartido.T_SALIDA + CeremoniaPartido.T_FILA * 2.0 + 3.5
		and CeremoniaPartido.T_SORTEO <= 5.0, "sorteo: ≈4 s al final de la ceremonia")
	var expr: Array = AnimFutbol.familias()["expresivo"]
	_comprobar(expr.has("chocar_mano") and expr.has("dar_mano"), "clips nuevos: chocar_mano y dar_mano")


## M-141 (valoraciones deterministas y ordenadas), 19-10 (partido mirado cierra notas una vez) y
## M-238 (resumen de la etapa del despido). Comparten el mismo mundo.
func _tp_valoraciones_despido() -> void:
	## M-141: valoraciones deterministas, ordenadas y sin tocar el resultado.
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var par := m.proximo_partido()
	var p := Partido.new(par[0], par[1])
	p.simular()
	var v1 := p.valoraciones()
	var v2 := p.valoraciones()
	var orden := true
	for i in range(1, v1.size()):
		if float(v1[i]["nota"]) > float(v1[i - 1]["nota"]):
			orden = false
	_comprobar(v1.size() >= 22 and orden, "valoraciones: los 22, de mejor a peor (%d)" % v1.size())
	var iguales := v1.size() == v2.size()
	for i in mini(v1.size(), v2.size()):
		iguales = iguales and float(v1[i]["nota"]) == float(v2[i]["nota"])
	_comprobar(iguales, "valoraciones: pedirlas dos veces da lo mismo")
	var rango := true
	for x: Dictionary in v1:
		rango = rango and float(x["nota"]) >= 3.0 and float(x["nota"]) <= 10.0
	_comprobar(rango, "valoraciones: entre 3 y 10")
	_comprobar(p.mejor_del_partido() == v1[0], "valoraciones: el mejor del partido es el primero")
	## 19-10: un partido MIRADO (minuto a minuto, sin `simular()`) también
	## cierra notas y forma, una sola vez y sin tocar el azar.
	var par2 := m.proximo_partido()
	var pm := Partido.new(par2[1], par2[0])
	pm.preparar()
	while not pm.terminado_ya:
		pm.simular_minuto()
	var j0: Jugador = pm.once_local[0]
	var antes_n := j0.notas.size()
	var antes_p := j0.partidos
	pm.cerrar_notas_mirado()
	pm.cerrar_notas_mirado()
	_comprobar(j0.partidos == antes_p + 1 and (j0.notas.size() == antes_n + 1 or antes_n >= 8),
		"partido mirado: cuenta en notas y partidos una sola vez")
	## M-238: el resumen de la etapa del despido.
	var filas := EscenaDespido.datos_etapa(m)
	var claves: Array = []
	for f: Array in filas:
		claves.append(f[0])
	_comprobar(claves.has("Temporadas") and claves.has("Títulos") and claves.has("Balance (G-E-P)"), "despido: resumen con temporadas, balance y títulos")


## M-051: el escudo, más grande y con relieve.
func _tp_escudo() -> void:
	## M-051: el escudo, más grande y con relieve.
	var sh := load("res://visor/equipacion_q.gdshader") as Shader
	_comprobar(sh.code.contains("h_escudo") and sh.code.contains("/ 0.104 + 0.5"), "escudo: 10,4 cm de ancho y relieve en el shader")
