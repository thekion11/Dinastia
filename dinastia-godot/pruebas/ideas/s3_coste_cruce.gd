extends BaseIdea
## s3 (26-10-2026): COSTE DEL TRÁFICO EN UN CRUCE LLENO. 64 peatones (4 aceras × 2 sentidos ×
## 8) y 16 coches dentro de un cuadrado de 40 m, sin cámara (todos en la rejilla de ceder el paso
## y en el nivel de detalle más caro): µs por `_process`. Complementa `sonda_explorador`
## (la ciudad real, con ~25 móviles cerca). Exige que siga holgado y que nadie se quede atascado.
## Medido el 26-10 en este contenedor: 2,40 ms antes de esquivar de lado y 2,66 ms después (+10 %:
## casi nadie se para, y el que no se para recorre la comprobación entera). En la ciudad real
## (`sonda_explorador`) no cambia: 1,24 → 1,23 ms. El tope deja margen para máquinas más lentas.
const DT := 1.0 / 30.0
const TOPE_US := 3200.0

func _probar() -> void:
	_titulo("S3: COSTE DEL TRÁFICO EN UN CRUCE LLENO")
	seed(99)
	var t := TraficoCiudad.new()
	add_child(t)
	t.set_process(false)
	var rutas: Array[int] = []
	## Dos aceras por calle (a ±6 m del eje), un sentido por ruta y el contrario en la de al lado.
	for eje in [Vector2(1, 0), Vector2(0, 1)]:
		for off in [-6.0, 6.0]:
			for sentido in [1.0, -1.0]:
				var d: Vector2 = eje * sentido
				var lado := Vector2(-d.y, d.x)
				var c: Vector2 = Vector2(-eje.y, eje.x) * off
				var a := c - d * 60.0
				var b := c + d * 60.0
				var e := b + lado * 30.0
				var f := a + lado * 30.0
				rutas.append(t.agregar_ruta(PackedVector3Array([Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(e.x, 0, e.y), Vector3(f.x, 0, f.y)])))
	for r in rutas:
		for k in 8:
			t.agregar_vehiculo(Node3D.new(), r, 40.0 + k * 5.0, randf_range(1.1, 1.5), 0.18)
	## Coches por el centro de las dos calles.
	for eje in [Vector2(1, 0), Vector2(0, 1)]:
		var a: Vector2 = -eje * 80.0
		var b: Vector2 = eje * 80.0
		var lado: Vector2 = Vector2(-eje.y, eje.x) * 30.0
		var rc := t.agregar_ruta(PackedVector3Array([Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(b.x + lado.x, 0, b.y + lado.y), Vector3(a.x + lado.x, 0, a.y + lado.y)]))
		for k in 8:
			t.agregar_vehiculo(Node3D.new(), rc, 50.0 + k * 9.0, 9.0)
	var s0: Array[float] = []
	for v: Dictionary in t._vehiculos:
		s0.append(float(v["s"]))
	for i in 30:
		t._process(DT)
	var t0 := Time.get_ticks_usec()
	var n := 300
	for i in n:
		t._process(DT)
	var us := float(Time.get_ticks_usec() - t0) / n
	_linea("  %d peatones y 16 coches: %.0f µs por fotograma" % [t._vehiculos.size() - 16, us])
	_comprobar(us < TOPE_US, "el cruce lleno cuesta menos de %.1f ms por fotograma (%.2f ms)" % [TOPE_US / 1000.0, us / 1000.0])
	var quietos := 0
	for i in t._vehiculos.size():
		if float(t._vehiculos[i]["s"]) - s0[i] < 3.0:
			quietos += 1
	_comprobar(quietos <= 4, "en 11 s casi nadie se queda atascado (%d de %d sin avanzar 3 m)" % [quietos, t._vehiculos.size()])
	t.queue_free()
