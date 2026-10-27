extends BaseIdea
## s3g · CADA GESTO CON SU HABILIDAD Y SU CLIMA (pedido del dueño, 27-10-2026; `GestoTecnico`). Cada tipo de
## tiro y de pase pesa sus propios atributos, la pierna débil cuesta según sus estrellas y el clima del
## partido cambia el error, el agarre del portero y lo que rueda el balón.

func _probar() -> void:
	_titulo("S3G: cada tiro y cada pase con su habilidad, su pie y su clima")
	_habilidades()
	_pie_malo()
	_clima()
	_en_el_motor()

func _jugador(attr: Dictionary, pie := "D", estrellas := 3) -> Dictionary:
	var nd := Node3D.new()
	add_child(nd)
	return {"attr": attr, "pie": pie, "pierna_debil": estrellas, "node": nd}

func _habilidades() -> void:
	_linea("· Habilidad por gesto")
	## Un mediapunta fino: poco tiro, mucho pase y regate.
	var fino := _jugador({"tir": 0.55, "pas": 0.95, "reg": 0.95, "fis": 0.4})
	## Un delantero tanque: buen tiro, mucho físico, poco toque.
	var tanque := _jugador({"tir": 0.8, "pas": 0.45, "reg": 0.4, "fis": 0.95})
	_comprobar(GestoTecnico.tiro(fino, "rosca") > GestoTecnico.tiro(fino, ""), "el fino pone mejor una rosca (%.2f) que un tiro normal (%.2f)" % [GestoTecnico.tiro(fino, "rosca"), GestoTecnico.tiro(fino, "")])
	_comprobar(GestoTecnico.tiro(fino, "vaselina") > GestoTecnico.tiro(tanque, "vaselina"), "y la vaselina es suya, no del tanque (%.2f frente a %.2f)" % [GestoTecnico.tiro(fino, "vaselina"), GestoTecnico.tiro(tanque, "vaselina")])
	_comprobar(GestoTecnico.tiro(tanque, "potente") > GestoTecnico.tiro(fino, "potente"), "el cañonazo es del tanque (%.2f frente a %.2f)" % [GestoTecnico.tiro(tanque, "potente"), GestoTecnico.tiro(fino, "potente")])
	_comprobar(GestoTecnico.tiro(tanque, "cabeza") > GestoTecnico.tiro(fino, "cabeza"), "y el cabezazo también (%.2f frente a %.2f)" % [GestoTecnico.tiro(tanque, "cabeza"), GestoTecnico.tiro(fino, "cabeza")])
	_comprobar(GestoTecnico.pase(fino, false, true, false) > GestoTecnico.pase(tanque, false, true, false), "el pase al hueco es del que ve y regatea")
	_comprobar(is_equal_approx(GestoTecnico.pase(fino, false, false, false), 0.95), "el pase corto sigue siendo el «pase» a secas")
	_comprobar(is_equal_approx(GestoTecnico.tiro(tanque, ""), 0.8), "y el tiro normal, el «tiro» a secas")
	for t: String in GestoTecnico.TIROS:
		var suma := 0.0
		for k: String in GestoTecnico.TIROS[t]:
			suma += float(GestoTecnico.TIROS[t][k])
		if not is_equal_approx(suma, 1.0):
			_comprobar(false, "los pesos del tiro «%s» suman 1 (%.2f)" % [t, suma])

func _pie_malo() -> void:
	_linea("· El pie malo")
	var diestro := _jugador({"tir": 0.8}, "D", 1)
	var ambi := _jugador({"tir": 0.8}, "D", 5)
	var zurdo := _jugador({"tir": 0.8}, "I", 2)
	## Todos miran a +Z (rotación 0): +X queda a su izquierda.
	var izq := Vector3(20, 0, 20)
	var der := Vector3(-20, 0, 20)
	var recto := Vector3(0, 0, 20)
	_comprobar(is_equal_approx(GestoTecnico.factor_pie(diestro, Vector3.ZERO, der), 1.0) and is_equal_approx(GestoTecnico.factor_pie(diestro, Vector3.ZERO, recto), 1.0), "el diestro, a su derecha o recto, con su pie bueno: sin castigo")
	_comprobar(is_equal_approx(GestoTecnico.factor_pie(diestro, Vector3.ZERO, izq), 1.48), "cruzado a su izquierda con una estrella de pierna débil: un 48 %% más de error (%.2f)" % GestoTecnico.factor_pie(diestro, Vector3.ZERO, izq))
	_comprobar(is_equal_approx(GestoTecnico.factor_pie(ambi, Vector3.ZERO, izq), 1.0), "el ambidiestro (cinco estrellas) no pierde nada")
	_comprobar(is_equal_approx(GestoTecnico.factor_pie(zurdo, Vector3.ZERO, der), 1.36) and is_equal_approx(GestoTecnico.factor_pie(zurdo, Vector3.ZERO, izq), 1.0), "el zurdo sufre al revés (a su derecha, %.2f)" % GestoTecnico.factor_pie(zurdo, Vector3.ZERO, der))

func _clima() -> void:
	_linea("· El clima")
	var m := MotorJugable.new()
	add_child(m)
	GestoTecnico.fijar_clima(m, "noche")
	_comprobar(is_equal_approx(GestoTecnico.factor_clima(m, true), 1.0) and is_equal_approx(GestoTecnico.agarre(m), 1.0) and is_equal_approx(float(m.get("_roce_clima")), 1.0), "de noche y seco, nada cambia")
	GestoTecnico.fijar_clima(m, "lluvia")
	_comprobar(GestoTecnico.factor_clima(m, false) > 1.0 and GestoTecnico.agarre(m) < 1.0 and float(m.get("_roce_clima")) < 1.0, "con lluvia: más error, el portero bloca menos y el balón resbala (roce %.2f)" % float(m.get("_roce_clima")))
	GestoTecnico.fijar_clima(m, "tormenta")
	_comprobar(GestoTecnico.factor_clima(m, true) > GestoTecnico.factor_clima(m, false) * 1.1, "con tormenta, lo que va por el aire sufre más (%.2f frente a %.2f)" % [GestoTecnico.factor_clima(m, true), GestoTecnico.factor_clima(m, false)])
	GestoTecnico.fijar_clima(m, "nieve")
	_comprobar(float(m.get("_roce_clima")) > 1.0, "con nieve el balón frena antes (roce %.2f)" % float(m.get("_roce_clima")))
	m.queue_free()

## En el motor de verdad: el mismo pase rodando llega más lejos con lluvia que con nieve.
func _en_el_motor() -> void:
	_linea("· En el motor")
	var lejos := {}
	for clave: String in ["noche", "lluvia", "nieve"]:
		var m := MotorJugable.new()
		add_child(m)
		var b := Node3D.new()
		add_child(b)
		m.set("balon", b)
		GestoTecnico.fijar_clima(m, clave)
		b.position = Vector3(0, MotorJugable.R, 0)
		m.set("vel_balon", Vector3(0, 0, 12.0))
		for i in 240:
			m.call("_mover_balon", 1.0 / 60.0)
		lejos[clave] = b.position.z
		m.queue_free()
		b.queue_free()
	_comprobar(float(lejos["lluvia"]) > float(lejos["noche"]) and float(lejos["noche"]) > float(lejos["nieve"]), "un balón a 12 m/s rueda %.1f m con lluvia, %.1f en seco y %.1f con nieve" % [float(lejos["lluvia"]), float(lejos["noche"]), float(lejos["nieve"])])
