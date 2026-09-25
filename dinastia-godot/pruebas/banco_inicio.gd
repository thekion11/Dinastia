extends Node
## Banco de pruebas de la pantalla de inicio: que "Continuar" se active solo
## cuando hay partida, y que Principal recoja el mundo que le deja Inicio en
## vez de generar uno nuevo. Sin ventana, sin nadie mirando -las capturas ya
## comprobaron a ojo que la portada se dibuja bien; esto comprueba el enganche.
##
##     godot --headless --path . res://pruebas/banco_inicio.tscn
##
## Se espera un fotograma antes de mirar dentro de Principal por la misma
## razon que pruebas/captura.gd espera doce: _ready() de un nodo recien anadido
## no se puede dar por terminado en la misma linea que hizo add_child().

var _fallos: Array[String] = []
var _pantalla: Control
var _club_esperado := ""
var _mundo_elegido: Mundo
var _club_elegido_id := ""
var _n := 0

func _ready() -> void:
	_linea("===== BANCO: PANTALLA DE INICIO =====")
	_probar_deteccion_de_partida()
	_arrancar_carga_desde_inicio()

func _process(_d: float) -> void:
	_n += 1
	if _n == 3:
		_comprobar(Principal.mundo_a_cargar == null, "_ready() consume mundo_a_cargar (no se reusa en la siguiente apertura)")
		var mundo_final = _pantalla.get("mundo")
		_comprobar(mundo_final != null, "Principal termino con un mundo puesto")
		if mundo_final != null:
			_comprobar(mundo_final.mi_club().nombre == _club_esperado,
				"el club cargado es el que se guardo (%s)" % _club_esperado)
		_pantalla.queue_free()
		Partida.borrar("partida")
		_arrancar_modo_y_dificultad()
	if _n == 6:
		var mundo_final2 = _pantalla.get("mundo")
		_comprobar(Principal.modo_elegido == "", "_ready() consume modo_elegido igual que mundo_a_cargar")
		_comprobar(mundo_final2 != null and mundo_final2.roles.rol == "ayudante",
			"seleccion_modo.gd -> Principal aplica el rol elegido (ayudante)")
		_comprobar(mundo_final2 != null and mundo_final2.roles.nombre == "Prueba Banco",
			"y el nombre del entrenador elegido")
		## El saldo base de un club recien generado es exactamente Eco.ref_caja(rep)
		## -Mundo.generar() lo pone ahi sin tocar-, asi que sirve de referencia
		## exacta sin depender de la semilla al azar de _nuevo_mundo().
		if mundo_final2 != null:
			## Mismo orden que Mundo.generar(): ref_caja() se trunca a entero
			## PRIMERO (así queda `c.saldo` en la generación) y sobre ese entero
			## se aplica el multiplicador de dificultad, no sobre el flotante.
			var base := int(Eco.ref_caja(float(mundo_final2.mi_club().rep)))
			var esperado := int(round(float(base) * 0.55))
			_comprobar(mundo_final2.mi_club().saldo == esperado,
				"'leyenda' escala la caja inicial x0,55 de verdad (%d, esperados %d)" % [mundo_final2.mi_club().saldo, esperado])
		_pantalla.queue_free()
		_arrancar_desde_eleccion_club()
	if _n == 9:
		var mundo_final3 = _pantalla.get("mundo")
		_comprobar(Principal.mundo_pregenerado == null, "_ready() consume mundo_pregenerado igual que los otros dos canales")
		_comprobar(mundo_final3 == _mundo_elegido, "Principal usa el MISMO mundo que eleccion_club.gd generó y eligió, no uno nuevo")
		_comprobar(mundo_final3 != null and mundo_final3.mi_club_id == _club_elegido_id,
			"se queda con el club que se eligió a mano, no el primero de Chile")
		_comprobar(mundo_final3 != null and mundo_final3.roles.rol == "dir",
			"el modo también se aplica en este tercer canal (Director Deportivo)")
		_comprobar(mundo_final3 != null and mundo_final3.tiene_desafio("pobreza"),
			"y los desafíos elegidos en eleccion_club.gd llegan hasta Mundo.desafios")
		if mundo_final3 != null:
			var esperado_pobreza := int(round(Eco.ref_caja(float(mundo_final3.mi_club().rep)) * 0.04))
			_comprobar(mundo_final3.mi_club().saldo == esperado_pobreza,
				"y 'pobreza' se aplicó de verdad sobre la caja (%d, esperados %d)" % [mundo_final3.mi_club().saldo, esperado_pobreza])
		_pantalla.queue_free()
		_cerrar()

func _linea(t: String) -> void:
	print(t)

func _comprobar(condicion: bool, que: String) -> void:
	if condicion:
		_linea("  ok    %s" % que)
	else:
		_fallos.append(que)
		_linea("  FALLO %s" % que)

## _hay_partida() de Inicio.gd es lo que decide si "Continuar" sale activo. Se
## borra antes por si quedo un fichero de una corrida anterior.
func _probar_deteccion_de_partida() -> void:
	Partida.borrar("partida")
	var inicio_vacio := Inicio.new()
	_comprobar(not inicio_vacio.call("_hay_partida"), "sin guardado, _hay_partida() da false")
	inicio_vacio.free()

	var m := Mundo.new()
	m.generar(["CHI"], 777)
	m.tomar_el_mando(m.ligas[0].clubes[3].id)
	_club_esperado = m.mi_club().nombre
	_comprobar(Partida.guardar(m, "partida"), "se guarda una partida de prueba")

	var inicio_con := Inicio.new()
	_comprobar(inicio_con.call("_hay_partida"), "con guardado, _hay_partida() da true")
	inicio_con.free()

## Principal.mundo_a_cargar es el unico canal para pasarle una partida ya
## cargada a la escena que arranca sola por run/main_scene. Si _ready() no lo
## mirara, "Continuar" cargaria el fichero y aun asi acabarias con un mundo
## nuevo sin darte cuenta -el fallo mas dificil de notar que hay aqui.
func _arrancar_carga_desde_inicio() -> void:
	var cargado := Partida.cargar("partida")
	_comprobar(cargado != null, "la partida de prueba se recupera del disco")
	if cargado == null:
		_cerrar()
		return
	Principal.mundo_a_cargar = cargado
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

## El modo y la dificultad elegidos en seleccion_modo.gd, aplicados por
## Principal cuando arranca un mundo nuevo (no uno cargado). Mismo canal de
## variables estaticas que mundo_a_cargar, mismo riesgo si nadie los mirara.
func _arrancar_modo_y_dificultad() -> void:
	Principal.modo_elegido = "ayudante"
	Principal.dt_nombre_elegido = "Prueba Banco"
	Principal.dificultad_elegida = "leyenda"
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

## El tercer canal: `ui/eleccion_club.gd` genera el mundo ENTERO y hace
## `tomar_el_mando()` sobre el club que se eligió a mano -no el primero de
## Chile-, y dice deja el resultado en `Principal.mundo_pregenerado` para que
## `_ready()` lo recoja y solo le aplique dificultad y modo encima.
func _arrancar_desde_eleccion_club() -> void:
	_mundo_elegido = Mundo.new()
	_mundo_elegido.generar([], 555)
	## Un club que NO es el primero de Chile, para que la prueba distinga de
	## verdad "el club elegido" de "el de siempre".
	var club: Club = _mundo_elegido.ligas[0].clubes[7]
	_club_elegido_id = club.id
	_mundo_elegido.tomar_el_mando(club.id)
	Principal.modo_elegido = "dir"
	Principal.dt_nombre_elegido = "Prueba Asistente"
	Principal.dificultad_elegida = "normal"
	Principal.desafios_elegidos = ["pobreza"]
	Principal.mundo_pregenerado = _mundo_elegido
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _cerrar() -> void:
	_linea("")
	if _fallos.is_empty():
		_linea("===== FIN. 0 fallos =====")
	else:
		_linea("===== FIN. %d FALLOS =====" % _fallos.size())
		for f in _fallos:
			_linea("  - %s" % f)
	get_tree().quit(0 if _fallos.is_empty() else 1)
