extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), mundo_3d, repaso 3: AL LÍMITE. Abrir y cerrar la ciudad varias veces (fugas de nodos), cambiar la calidad con la ciudad abierta, horas absurdas, luces fuera de rango,
## y estadios con perfiles extremos (aforo 0 y medio millón, 1 a 3 niveles, forma desconocida, colores vacíos o rotos). Cualquier «SCRIPT ERROR» de la salida hace fallar la corrida.
const Comun := preload("res://pruebas/bancos/ciudad_comun.gd")

func _probar() -> void:
	_titulo("A4 MUNDO_3D: al límite (fugas, calidad a mitad, horas absurdas, estadios extremos)")
	## A4_PARTE=1 (fugas) | 2 (calidad a mitad y horas) | 3 (estadios extremos y tráfico): cada trozo cabe holgado en los 600 s de `especiales.sh` (software, sin GPU: 1 ≈ 190 s, 2 ≈ 190 s).
	## Sin variable, todo.
	var parte := OS.get_environment("A4_PARTE")
	var t0 := Time.get_ticks_msec()
	if parte == "" or parte == "1":
		await _fugas()
		_linea("  (tiempo) fugas: %d s" % ((Time.get_ticks_msec() - t0) / 1000))
	if parte == "" or parte == "2":
		await _calidad_y_horas()
		_linea("  (tiempo) calidad y horas: %d s" % ((Time.get_ticks_msec() - t0) / 1000))
	if parte == "" or parte == "3":
		await _estadios_extremos()
		_linea("  (tiempo) estadios extremos: %d s" % ((Time.get_ticks_msec() - t0) / 1000))
		await _trafico_estres()
		_linea("  (tiempo) estadios + tráfico: %d s" % ((Time.get_ticks_msec() - t0) / 1000))

func _nodos() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

## ---- abrir y cerrar la ciudad 3 veces
func _fugas() -> void:
	var base := 0
	var cuentas: Array[int] = []
	var huerfanos: Array[int] = []
	for i in 3:
		var c: Dictionary = await Comun.abrir(self, 777 + i)
		(c["vc"] as Node).free()
		for k in 10:
			await get_tree().process_frame
		cuentas.append(_nodos())
		huerfanos.append(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	print("  nodos tras cada abrir/cerrar: %s · huérfanos: %s" % [str(cuentas), str(huerfanos)])
	_comprobar(cuentas[2] - cuentas[0] < 400, "abrir y cerrar la ciudad no acumula nodos (%d → %d → %d)" % [cuentas[0], cuentas[1], cuentas[2]])
	_comprobar(huerfanos[2] - huerfanos[0] < 50, "ni nodos huérfanos (%d → %d)" % [huerfanos[0], huerfanos[2]])

## ---- calidad a mitad y horas absurdas
func _calidad_y_horas() -> void:
	var c: Dictionary = await Comun.abrir(self, 777, Calidad.ALTO)
	var vc: Node = c["vc"]
	var cb: Node = c["cb"]
	for nivel in [Calidad.MINIMO, Calidad.MEDIO, Calidad.ULTRA, Calidad.MINIMO, Calidad.ALTO]:
		Calidad.elegida = nivel
		Calidad.aplicar_viewport(get_viewport(), nivel)
		for h in [0.0, 6.0, 19.5, 23.99, 12.0]:   ## termina a mediodía: con sol, ALTO y más deben tener sombra
			vc.set("_hora", h)
			vc.call("_aplicar_hora")
			await get_tree().process_frame
		var con_sombra := 0
		for l in vc.find_children("*", "Light3D", true, false):
			if (l as Light3D).shadow_enabled and (l as Light3D).visible:
				con_sombra += 1
		_comprobar((nivel > Calidad.MINIMO and con_sombra >= 1) or (nivel <= Calidad.MINIMO and con_sombra == 0), "cambiando a calidad %d con la ciudad abierta y el sol alto: sombras según nivel (%d luces con sombra)" % [nivel, con_sombra])
	for h in [-5.0, 24.0, 25.0, 100.0, 0.0001]:
		vc.set("_hora", h)
		vc.call("_aplicar_hora")
		await get_tree().process_frame
	var sol: Variant = vc.get("_sol")
	_comprobar(sol != null and is_finite((sol as DirectionalLight3D).light_energy) and (sol as DirectionalLight3D).light_energy >= 0.0, "horas fuera de 0-24: el sol sigue con energía finita y no negativa")
	for f in [-5.0, 0.0, 0.5, 1.0, 7.0]:
		cb.encender_luces(f)
	var ok := true
	for m in (cb.get("_mats_torre") as Array):
		var n: Variant = (m as ShaderMaterial).get_shader_parameter("noche")
		if n == null or not is_finite(float(n)) or float(n) < 0.0 or float(n) > 1.0:
			ok = false
	_comprobar(ok, "encender_luces(−5…7): la «noche» de las torres queda recortada a 0-1")
	Calidad.elegida = Calidad.MEDIO
	(c["vc"] as Node).free()

## ---- estadios con perfiles extremos
func _estadios_extremos() -> void:
	Calidad.elegida = Calidad.MEDIO
	Partido.limpiar_contexto()
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, 777)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var club := m.mi_club()
	var base: Dictionary = m.perfil_estadio_de(club)
	var vistas := {}
	var casos := {
		"aforo 0": {"aforo": 0},
		"aforo 1": {"aforo": 1},
		"aforo 500000": {"aforo": 500000},
		"3 niveles": {"niveles": 3, "aforo": 90000},
		"forma desconocida": {"forma": "xyz"},
		"colores vacíos": {"asiento1": "", "asiento2": "", "asiento3": "", "cespedClaro": "", "lineaCol": ""},
		"colores rotos": {"asiento1": "zzz", "asiento2": "#12", "cespedOscuro": "rojo", "luzClub": "#gggggg"},
		"sin claves": {},
	}
	for nombre in casos:
		var perfil := base.duplicate(true)
		if nombre == "sin claves":
			perfil = {}
		for k in casos[nombre]:
			perfil[k] = casos[nombre][k]
		Azar.sembrar(4242)
		var v := VistaEstadio.new()
		add_child(v)
		await v.abrir(club, 0.5, null, null, perfil)
		for i in 20:
			await get_tree().process_frame
		var r: Node3D = v.get("_raiz3d")
		var butacas := 0
		for g in r.find_children("Butacas*", "MultiMeshInstance3D", true, false):
			var mm := (g as MultiMeshInstance3D).multimesh
			for q in mm.instance_count:
				if mm.get_instance_color(q).a > 0.5 and mm.get_instance_transform(q).basis.get_scale().y > 0.01:
					butacas += 1
		vistas[nombre] = butacas
		print("  estadio «%s»: %d nodos, %d butacas" % [nombre, r.find_children("*", "Node", true, false).size(), butacas])
		_comprobar(r.get_node_or_null("Cesped") != null, "estadio «%s»: se construye con su césped" % nombre)
		v.free()
	print("  butacas visibles por aforo: ", vistas)
	_comprobar(int(vistas["aforo 1"]) < int(vistas["aforo 500000"]), "el aforo manda en las butacas: aforo 1 → %d visibles, aforo 500 000 → %d" % [int(vistas["aforo 1"]), int(vistas["aforo 500000"])])

## ---- 10 minutos de tráfico y gente a paso fino: nada se pierde, nada sale NaN, los nodos no crecen
func _trafico_estres() -> void:
	var c: Dictionary = await Comun.abrir(self, 777)
	var cb: Node = c["cb"]
	var t: Object = cb.get_node_or_null("Trafico")
	t.set_process(false)
	var sem: Object = t.get("semaforos")
	if sem != null:
		sem.set_process(false)
	var antes: int = (t.get("_vehiculos") as Array).size()
	var nodos0 := _nodos()
	var malos := 0
	for i in 6000:   ## 10 min a 0,1 s
		if sem != null:
			sem.call("_process", 0.1)
		t.call("_process", 0.1)
		if i % 100 == 0:
			await get_tree().process_frame
			for v: Dictionary in t.get("_vehiculos"):
				if is_instance_valid(v["nodo"]):
					var p: Vector3 = (v["nodo"] as Node3D).position
					if not (is_finite(p.x) and is_finite(p.y) and is_finite(p.z)) or absf(p.x) > 4000.0 or absf(p.z) > 4000.0 or p.y < -60.0 or p.y > 400.0:
						malos += 1
	var despues: int = (t.get("_vehiculos") as Array).size()
	print("  tráfico 10 min: vehículos %d → %d, posiciones fuera de rango %d, nodos %d → %d" % [antes, despues, malos, nodos0, _nodos()])
	_comprobar(malos == 0, "10 min de tráfico: ninguna posición NaN ni fuera del mundo (%d)" % malos)
	_comprobar(despues >= antes - 10, "10 min de tráfico: no se pierden vehículos (%d → %d)" % [antes, despues])
	_comprobar(_nodos() - nodos0 < 600, "10 min de tráfico: los nodos no se disparan (%d → %d)" % [nodos0, _nodos()])
	t.set_process(true)
	if sem != null:
		sem.set_process(true)
	(c["vc"] as Node).free()