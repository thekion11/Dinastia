extends BaseIdea
## El tráfico cede el paso a las sirenas (27-10-2026, pieza E): coches y buses frenan con su rampa de siempre cuando un vehículo de emergencia
## con la sirena puesta está a menos de `RADIO_SIRENA` m, y arrancan cuando se aleja o la apaga.

const DT := 1.0 / 30.0

func _correr(t: TraficoCiudad, seg: float) -> void:
	for i in int(seg / DT):
		t._process(DT)

func _probar() -> void:
	_titulo("CIUDAD · EL TRÁFICO CEDE EL PASO A LAS SIRENAS")
	seed(5)
	TraficoCiudad.sirenas.clear()
	var t := TraficoCiudad.new()
	add_child(t)
	t.set_process(false)
	var r := t.agregar_ruta(PackedVector3Array([Vector3(0, 0, 0), Vector3(600, 0, 0), Vector3(600, 0, 60), Vector3(0, 0, 60)]))
	t.agregar_vehiculo(Node3D.new(), r, 20.0, 12.0)
	var v: Dictionary = t._vehiculos[0]
	_correr(t, 4.0)
	_comprobar(float(v["vact"]) > 9.0, "sin sirenas circula (%.1f m/s)" % float(v["vact"]))
	var amb := Node3D.new()
	add_child(amb)
	amb.position = Vector3(float(v["nodo"].position.x) + 40.0, 0, 3.0)   ## a 40 m, de frente
	TraficoCiudad.sirenas.append(amb)
	var frenada := 0.0
	var v_ant := float(v["vact"])
	for i in int(8.0 / DT):
		t._process(DT)
		frenada = maxf(frenada, (v_ant - float(v["vact"])) / DT)
		v_ant = float(v["vact"])
	_comprobar(float(v["vact"]) < 0.1, "con una sirena a menos de %d m frena hasta parar (%.2f m/s)" % [int(TraficoCiudad.RADIO_SIRENA), float(v["vact"])])
	_comprobar(frenada <= TraficoCiudad.FRENADA + 0.3, "con la rampa de siempre: nunca más de %.1f m/s² (%.2f)" % [TraficoCiudad.FRENADA, frenada])
	## Se aleja: el tráfico arranca.
	amb.position = Vector3(float(v["nodo"].position.x) + 400.0, 0, 3.0)
	_correr(t, 8.0)
	_comprobar(float(v["vact"]) > 8.0, "cuando la sirena queda lejos recupera la marcha (%.1f m/s)" % float(v["vact"]))
	## La apaga (o desaparece): no frena aunque esté al lado.
	amb.position = Vector3(float(v["nodo"].position.x) + 20.0, 0, 3.0)
	TraficoCiudad.sirenas.erase(amb)
	_correr(t, 3.0)
	_comprobar(float(v["vact"]) > 8.0, "una ambulancia sin sirena no hace parar a nadie")
	_comprobar(not TraficoCiudad.sirena_cerca(Vector3(1000, 0, 1000)), "y la función no ve sirenas lejanas ni borradas")
	TraficoCiudad.sirenas.clear()
	amb.free()
	t.queue_free()
