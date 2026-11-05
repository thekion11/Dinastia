extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 del mundo 3D: un vehículo de emergencia con la SIRENA ENCENDIDA y EN MOVIMIENTO (como los de `ServiciosVida`: va por su ruta a 15 m/s y no mira al resto) en medio del tráfico.
##   Se le hace recorrer 600 m de una ruta con coches (a 15 m/s) y se mide, cada 0,1 s, la distancia a coches, buses y peatones: ¿los atraviesa (< 1,5 m)? ¿cuántos coches están quietos en SU carril delante de él?
##   El resto del tráfico frena a < 55 m de una sirena (`TraficoCiudad.sirena_cerca`), pero un coche que se queda parado EN su carril no se aparta: el vehículo de emergencia lo atraviesa.
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")
const PASO := 0.1

func _probar() -> void:
	_titulo("A4 MUNDO_3D: sirena en movimiento en medio del tráfico")
	var c: Dictionary = await Comun.abrir(self)
	var cb: Node = c["cb"]
	var t: Object = cb.get_node_or_null("Trafico")
	t.set_process(false)
	var sem: Object = t.get("semaforos")
	if sem != null:
		sem.set_process(false)
	var rutas: Array = t.get("_rutas")
	var otros: Array = []
	var cuenta := {}
	for v: Dictionary in t.get("_vehiculos"):
		var n: Node3D = v["nodo"]
		if not is_instance_valid(n) or String(n.name).begins_with("kart"):
			continue
		otros.append(v)
		if not bool(v.get("peaton", false)):
			cuenta[int(v["ruta"])] = int(cuenta.get(int(v["ruta"]), 0)) + 1
	var orden: Array = cuenta.keys()
	orden.sort_custom(func(x: int, y: int) -> bool: return int(cuenta[x]) > int(cuenta[y]))
	var rutas_prueba: Array = orden.slice(0, 5)
	var amb := Node3D.new()
	amb.name = "Ambulancia_prueba"
	var mi := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(2.1, 2.4, 5.5)
	mi.mesh = caja
	amb.add_child(mi)
	cb.add_child(amb)
	(TraficoCiudad.sirenas as Array).append(amb)
	var dentro := 0
	var pares := {}
	var recorrido_total := 0.0
	for mejor in rutas_prueba:
		var ruta: Object = rutas[int(mejor)]
		var largo: float = float(ruta.get("largo"))
		var s := 0.0
		var vel := 0.0
		var min_dist := INF
		for i in 1000:   ## 100 s por ruta
			if sem != null:
				sem.call("_process", PASO)
			t.call("_process", PASO)
			var pr: Array = ruta.call("en", s)
			var frente: Vector3 = pr[1]
			var lim := INF if OS.get_environment("SIN_FRENO") != "" else ServiciosVida.limite_por_delante(pr[0], frente, t)   ## lo MISMO que hace `ServiciosVida` con el tráfico
			vel = move_toward(vel, minf(15.0, lim), (3.0 if lim > vel else 3.2) * PASO)
			s += vel * PASO
			if s > largo - 1.0:
				break
			pr = ruta.call("en", s)
			amb.position = pr[0]
			amb.rotation.y = atan2((pr[1] as Vector3).x, (pr[1] as Vector3).z)
			for v: Dictionary in otros:
				var n: Node3D = v["nodo"]
				if not is_instance_valid(n):
					continue
				var rel := n.position - amb.position
				rel.y = 0.0
				var d := rel.length()
				if d < 1.6 and absf(n.position.y - amb.position.y) < 2.5 and i > 30:   ## (los 3 primeros segundos no cuentan: el vehículo de prueba nace encima de la ruta)
					var tipo := "bus" if String(n.name).begins_with("Bus_") else ("peatón" if bool(v.get("peaton", false)) else "coche")
					var k := "%s %s" % [tipo, n.name]
					if not pares.has(k):
						pares[k] = true
						dentro += 1
						var fr: Vector3 = pr[1]
						var rot := n.rotation.y
						print("    ATRAVIESA %s a %.2f m en t=%.1f s (ruta %d, s=%.0f) · frente %.1f lateral %.1f · su ruta %d vact %.1f rumbo·mío %.2f cola %s lod %s · amb vel %.1f lim %.1f" % [k, d, float(i) * PASO, int(mejor), s, rel.x * fr.x + rel.z * fr.z, rel.x * fr.z - rel.z * fr.x, int(v["ruta"]), float(v.get("vact", -1.0)), sin(rot) * fr.x + cos(rot) * fr.z, str(v.has("cola")), str(v.get("lod")), vel, lim])
				if String(n.name).begins_with("Bus_") or not bool(v.get("peaton", false)):
					min_dist = minf(min_dist, d)
			if i % 25 == 0:
				await get_tree().process_frame
		recorrido_total += s
		print("  (info) ruta %d (%d coches): recorrió %.0f m en 100 s (a 15 m/s serían 1500), distancia mínima a un vehículo %.2f m" % [int(mejor), int(cuenta[mejor]), s, min_dist])
	print("  (info) atraviesa a %d vehículos/peatones; recorrido total %.0f m" % [dentro, recorrido_total])
	_comprobar(recorrido_total > 1500.0, "con el tráfico delante la ambulancia avanza (no se queda parada para siempre: %.0f m en 5 × 100 s)" % recorrido_total)
	## Umbral (5-11, CI): la gente se coloca con un generador propio sin semilla (`_rng_gente`), así que el recuento con freno cambia de una ejecución a otra:
	## medido 0, 1, 2, 3 y 4 (4 en el CI, con tope 3 fallaba). SIN freno da siempre exactamente 7. Un tope de 5 queda por encima del ruido del freno que
	## funciona y 2 por debajo del freno roto (SIN_FRENO=1 → 7), así que sigue vigilando lo mismo.
	_comprobar(dentro <= 5, "el vehículo de emergencia que respeta `ServiciosVida.limite_por_delante` casi no atraviesa (tope 5; con freno 0-4, sin freno 7) a nadie en 5 rutas × 100 s (%d atravesados)" % dentro)
	(TraficoCiudad.sirenas as Array).erase(amb)
	amb.queue_free()
	(c["vc"] as Node).free()
