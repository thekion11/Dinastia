extends BaseIdea
## pmov (27-10-2026, pieza F-2): coches y buses del tráfico arrancan y frenan con suavidad. Un coche ante un semáforo
## en rojo y un bus ante su parada bajan la velocidad con rampa (nunca más de FRENADA m/s², sin tirones) y paran a
## tiempo; al ponerse en verde o acabar la espera, arrancan con rampa (nunca más de ARRANQUE m/s²).

const DT := 1.0 / 30.0

func _probar() -> void:
	_titulo("PMOV: SUAVIDAD DEL TRÁFICO (frenar en rojo, parar en la parada, arrancar)")
	_semaforo()
	_parada_bus()
	_metro()

func _trafico() -> TraficoCiudad:
	seed(77)
	var t := TraficoCiudad.new()
	add_child(t)
	t.set_process(false)
	return t

## Ruta recta de 400 m (en un bucle grande para que no dé la vuelta).
func _recta(t: TraficoCiudad) -> int:
	return t.agregar_ruta(PackedVector3Array([Vector3(0, 0, 0), Vector3(400, 0, 0), Vector3(400, 0, 60), Vector3(0, 0, 60)]))

## Simula `seg` segundos y devuelve [mayor deceleración, mayor aceleración, mayor tirón].
func _medir(t: TraficoCiudad, v: Dictionary, seg: float) -> Array:
	var frenada := 0.0
	var arranque := 0.0
	var tiron := 0.0
	var a_ant := 0.0
	var v_ant := float(v.get("vact", v["vel"]))
	for i in int(seg / DT):
		t._process(DT)
		var va := float(v.get("vact", v["vel"]))
		var a := (va - v_ant) / DT
		if va < 0.7 and v_ant < 0.7:
			v_ant = va   ## por debajo de 0,7 m/s ya está parado a todos los efectos (llega a la línea o a la parada)
			continue
		frenada = maxf(frenada, -a)
		arranque = maxf(arranque, a)
		tiron = maxf(tiron, absf(a - a_ant))
		a_ant = a
		v_ant = va
	return [frenada, arranque, tiron]

func _semaforo() -> void:
	_linea("· Semáforo en rojo")
	var t := _trafico()
	var sem := Semaforos.new()
	sem.t = Semaforos.VERDE + Semaforos.AMBAR + 1.0   ## eje 0 en rojo, quieto (no está en el árbol)
	t.semaforos = sem
	var r := _recta(t)
	t.agregar_control(r, 150.0, 0)
	t.agregar_vehiculo(Node3D.new(), r, 20.0, 12.0)
	var v: Dictionary = t._vehiculos[0]
	var m := _medir(t, v, 25.0)
	_comprobar(float(m[0]) <= TraficoCiudad.FRENADA + 0.3, "frena como mucho a %.2f m/s² (tope %.1f)" % [float(m[0]), TraficoCiudad.FRENADA])
	_comprobar(float(m[2]) < 1.0, "sin tirones (%.2f m/s² de cambio por fotograma)" % float(m[2]))
	var s := float(v["s"])
	_comprobar(s < 150.0 and s > 140.0, "y para antes de la línea, a %.1f m de ella" % (150.0 - s))
	_comprobar(float(v["vact"]) < 0.05, "con el semáforo en rojo se queda quieto (%.2f m/s)" % float(v["vact"]))
	sem.t = 1.0   ## eje 0 en verde
	m = _medir(t, v, 8.0)
	_comprobar(float(m[1]) <= TraficoCiudad.ARRANQUE + 0.3 and float(m[1]) > 1.0, "en verde arranca a %.2f m/s² (tope %.1f)" % [float(m[1]), TraficoCiudad.ARRANQUE])
	_comprobar(float(v["vact"]) > 8.0, "y recupera la marcha (%.1f m/s tras 8 s)" % float(v["vact"]))
	sem.free()
	t.queue_free()

func _parada_bus() -> void:
	_linea("· Parada del bus")
	var t := _trafico()
	var r := _recta(t)
	t.agregar_vehiculo(Node3D.new(), r, 20.0, 10.0)
	t.agregar_paradas_al_ultimo([120.0], 6.0)
	var v: Dictionary = t._vehiculos[0]
	var m := _medir(t, v, 14.0)
	_comprobar(float(m[0]) <= TraficoCiudad.FRENADA + 0.3, "el bus frena como mucho a %.2f m/s²" % float(m[0]))
	_comprobar(float(m[2]) < 1.0, "sin tirones (%.2f)" % float(m[2]))
	_comprobar(absf(float(v["s"]) - 120.0) < 1.0 and float(v.get("espera", 0.0)) > 0.0, "y para en la parada (a %.1f m, espera %.1f s)" % [120.0 - float(v["s"]), float(v.get("espera", 0.0))])
	m = _medir(t, v, 14.0)
	_comprobar(float(m[1]) <= TraficoCiudad.ARRANQUE + 0.3 and float(v["s"]) > 140.0, "pasada la espera, arranca con rampa (%.2f m/s²) y sigue (s=%.0f)" % [float(m[1]), float(v["s"])])
	t.queue_free()

func _metro() -> void:
	_linea("· Metro")
	var t := MetroCiudad.Tren.new(1400.0, PackedFloat32Array([100.0, 400.0, 700.0, 1000.0, 1300.0]), 0.0, 1.0)
	var v_ant := 0.0
	var a_ant := 0.0
	var acel := 0.0
	var tiron := 0.0
	var pico := 0.0
	var salto := 0.0   ## el mayor salto de posición en un fotograma menos lo que tocaba por velocidad (el «tirón» de llegar)
	for i in int(400.0 / DT):
		var s0 := t.s
		var paradas0 := t.paradas_hechas
		t.simular(DT)
		pico = maxf(pico, t.v)
		if t.paradas_hechas == paradas0 and t.espera <= 0.0 and t.v > 0.0:
			var a := (t.v - v_ant) / DT
			acel = maxf(acel, absf(a))
			tiron = maxf(tiron, absf(a - a_ant))
			a_ant = a
		elif t.paradas_hechas > paradas0:
			salto = maxf(salto, absf(t.s - s0) - v_ant * DT)
			a_ant = 0.0
		v_ant = t.v
	_comprobar(t.paradas_hechas >= 4, "el tren hace sus paradas (%d en 400 s)" % t.paradas_hechas)
	_comprobar(pico > 10.0, "y coge velocidad (%.1f m/s)" % pico)
	_comprobar(acel <= MetroCiudad.ACEL + 0.1, "acelera y frena como mucho a %.2f m/s² (tope %.1f)" % [acel, MetroCiudad.ACEL])
	_comprobar(tiron < 0.2, "con rampa: la aceleración cambia %.3f m/s² por fotograma (%.1f m/s³)" % [tiron, tiron / DT])
	_comprobar(salto < 0.4, "y se posa en el andén sin saltar (%.2f m de ajuste al llegar)" % salto)
