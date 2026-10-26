extends BaseIdea
## pmov (25-10-2026): en un cruce, nadie atraviesa a nadie que venga de OTRA ruta.
## Dos coches que llegan a la vez a un cruce sin semáforo, y un coche que se
## encuentra a un peatón cruzando: ni se solapan ni se quedan atascados.

const DT := 1.0 / 30.0

func _probar() -> void:
	_titulo("PMOV: CEDER EL PASO EN CRUCES (tráfico y peatones)")
	_cruce_coches()
	_coche_y_peaton()
	_cruce_peatones()
	_carriles_paralelos()
	_otra_altura()

## Un rectángulo cerrado que pasa por (x0, z0) yendo en la dirección `dir`.
func _bucle(t: TraficoCiudad, ini: Vector2, dir: Vector2) -> int:
	var lado := Vector2(-dir.y, dir.x) * 40.0
	var a := ini - dir * 50.0
	var b := ini + dir * 50.0
	return t.agregar_ruta(PackedVector3Array([Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y),
		Vector3(b.x + lado.x, 0, b.y + lado.y), Vector3(a.x + lado.x, 0, a.y + lado.y)]))

func _trafico() -> TraficoCiudad:
	## Los peatones se paran al azar a mirar el móvil: semilla fija para que la
	## prueba no dependa de la suerte. Por esas pausas (hasta 9 s) el umbral de
## «sigue andando» es 8 m y no los ~20 m de ir sin parar.
	seed(1234)
	var t := TraficoCiudad.new()
	add_child(t)
	t.set_process(false)
	return t

## Simula `seg` segundos y devuelve [distancia mínima entre a y b, s recorrida por a, por b].
func _simular(t: TraficoCiudad, ia: int, ib: int, seg: float) -> Array:
	var na: Node3D = t._vehiculos[ia]["nodo"]
	var nb: Node3D = t._vehiculos[ib]["nodo"]
	var sa0 := float(t._vehiculos[ia]["s"])
	var sb0 := float(t._vehiculos[ib]["s"])
	var minimo := INF
	for i in int(seg / DT):
		t._process(DT)
		minimo = minf(minimo, Vector2(na.position.x - nb.position.x, na.position.z - nb.position.z).length())
	return [minimo, float(t._vehiculos[ia]["s"]) - sa0, float(t._vehiculos[ib]["s"]) - sb0]

func _cruce_coches() -> void:
	var t := _trafico()
	var ra := _bucle(t, Vector2(0, 0), Vector2(1, 0))
	var rb := _bucle(t, Vector2(0, 0), Vector2(0, 1))
	## Los dos a 14 m del cruce y a 10 m/s: llegarían a la vez.
	t.agregar_vehiculo(Node3D.new(), ra, 36.0, 10.0)
	t.agregar_vehiculo(Node3D.new(), rb, 36.0, 10.0)
	var r := _simular(t, 0, 1, 12.0)
	_comprobar(float(r[0]) > 3.0, "dos coches en un cruce no se solapan (mínimo %.2f m > 3)" % float(r[0]))
	_comprobar(float(r[1]) > 80.0 and float(r[2]) > 80.0,
		"y ninguno se queda atascado (%.0f m y %.0f m en 12 s)" % [float(r[1]), float(r[2])])
	t.queue_free()

func _coche_y_peaton() -> void:
	var t := _trafico()
	var rc := _bucle(t, Vector2(0, 0), Vector2(1, 0))
	var rp := _bucle(t, Vector2(0, 0), Vector2(0, 1))
	## El peatón está a 2 m del cruce; el coche, a 12 m y a 10 m/s.
	t.agregar_vehiculo(Node3D.new(), rc, 38.0, 10.0)
	t.agregar_vehiculo(Node3D.new(), rp, 48.0, 1.4, 0.1)
	var r := _simular(t, 0, 1, 20.0)
	_comprobar(float(r[0]) > 1.5, "el coche frena ante el peatón que cruza (mínimo %.2f m > 1,5)" % float(r[0]))
	_comprobar(float(r[1]) > 100.0 and float(r[2]) > 8.0,
		"y luego siguen los dos (coche %.0f m, peatón %.0f m)" % [float(r[1]), float(r[2])])
	t.queue_free()

func _cruce_peatones() -> void:
	var t := _trafico()
	var ra := _bucle(t, Vector2(0, 0), Vector2(1, 0))
	var rb := _bucle(t, Vector2(0, 0), Vector2(0, 1))
	t.agregar_vehiculo(Node3D.new(), ra, 47.0, 1.4, 0.1)
	t.agregar_vehiculo(Node3D.new(), rb, 47.0, 1.4, 0.1)
	var r := _simular(t, 0, 1, 15.0)
	_comprobar(float(r[0]) > 0.45, "dos peatones que se cruzan no se atraviesan (mínimo %.2f m)" % float(r[0]))
	_comprobar(float(r[1]) > 8.0 and float(r[2]) > 8.0,
		"y los dos siguen andando (%.1f m y %.1f m)" % [float(r[1]), float(r[2])])
	t.queue_free()

## Dos coches por carriles contrarios de la misma calle (8 m entre ejes, como
## `CityBuilder.CARRIL`) se cruzan sin frenar.
func _carriles_paralelos() -> void:
	var t := _trafico()
	var ra := t.agregar_ruta(PackedVector3Array([Vector3(-100, 0, -4), Vector3(100, 0, -4), Vector3(100, 0, -60), Vector3(-100, 0, -60)]))
	var rb := t.agregar_ruta(PackedVector3Array([Vector3(100, 0, 4), Vector3(-100, 0, 4), Vector3(-100, 0, 60), Vector3(100, 0, 60)]))
	t.agregar_vehiculo(Node3D.new(), ra, 80.0, 10.0)
	t.agregar_vehiculo(Node3D.new(), rb, 80.0, 10.0)
	var r := _simular(t, 0, 1, 4.0)
	_comprobar(float(r[1]) > 39.0 and float(r[2]) > 39.0,
		"los coches del carril contrario no se frenan entre sí (%.1f m y %.1f m en 4 s)" % [float(r[1]), float(r[2])])
	t.queue_free()

## Un coche por la autopista (a 8 m de altura) no frena por el que pasa debajo.
func _otra_altura() -> void:
	var t := _trafico()
	var ra := _bucle(t, Vector2(0, 0), Vector2(1, 0))
	var rb := t.agregar_ruta(PackedVector3Array([Vector3(0, 8, -50), Vector3(0, 8, 50), Vector3(-40, 8, 50), Vector3(-40, 8, -50)]))
	t.agregar_vehiculo(Node3D.new(), ra, 36.0, 10.0)
	t.agregar_vehiculo(Node3D.new(), rb, 36.0, 10.0)
	var r := _simular(t, 0, 1, 4.0)
	_comprobar(float(r[1]) > 39.0 and float(r[2]) > 39.0,
		"a distinta altura (autopista sobre calle) nadie cede (%.1f m y %.1f m en 4 s)" % [float(r[1]), float(r[2])])
	t.queue_free()
