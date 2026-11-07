class_name CargaPartes
extends RefCounted
## LA CARGA DE LA CIUDAD EN PARTES CORTAS (6-11-2026, orden del dueño: ningún trozo de carga por encima de ~200 ms). Las pasadas de optimización de la ciudad
## (`Optimizar`: primitivas, trocear, butacas, distancias, obstáculos, agrupar) eran UN bloque de ~2-3 s sin ceder un solo fotograma. Aquí se hace lo mismo, en el mismo
## orden y con las mismas funciones de `Optimizar`, pero recorriendo los bucles pieza a pieza y cediendo un fotograma cada ~40 ms (`CityBuilder.ceder`, que solo cede si la
## ciudad se arma por partes). Las funciones de `Optimizar` siguen siendo síncronas (las llaman otros sin `await`); el resultado es idéntico al de antes.
## Se llama por `load("res://visor/carga_partes.gd")`: `CityBuilder` no la nombra (evita una dependencia circular con el explorador).

## `cb`: el `CityBuilder` (sin tipo a propósito, por la dependencia circular).
static func optimizar(cb) -> void:
	if OS.get_environment("SIN_OPTIMIZAR") != "":
		return
	Optimizar.primitivas(cb)
	await cb._marca("opt_primitivas")
	await _trocear(cb)
	if not is_instance_valid(cb):
		return
	await cb._marca("opt_trocear")
	Optimizar.butacas_livianas(cb, true)
	await cb._marca("opt_butacas")
	Optimizar.distancias(cb)
	if cb.modo_prologo:   ## (sigue puesto hasta que `completa`: el prólogo lo apaga al acabar `_resto`)
		OptimizarGrada.limitar_vista(cb, 220.0 if Calidad.elegida <= Calidad.BAJA else 380.0)   ## (7-11) ULTRA BAJA y BAJA: 220 m
	elif EscalaMovil.es_movil() or Calidad.motor_ligero or OS.get_environment("MOVIL_SIM") != "":   ## móvil / motor ligero: no se dibuja lo pequeño a más de 450 m
		OptimizarGrada.limitar_vista(cb, 450.0)
	await cb._marca("despejar")
	## (30-10-2026: aquí se repetían primitivas, butacas livianas y distancias -una copia de una fusión vieja-; la segunda pasada no cambiaba nada y costaba ~150 ms.)
	var circ := await _obstaculos(cb)
	if not is_instance_valid(cb):
		return
	## Los bancos (asiento a 0,75 m y respaldo bajo) quedaban por debajo del umbral de 0,9 m y se atravesaban andando (27-10-2026, plan §4 colisiones): un círculo por asiento.
	for a: Dictionary in cb.asientos:
		var pa: Vector3 = a["p"]
		circ.append(Vector3(pa.x, pa.z, 0.42))
	cb.circulos = circ
	await cb._marca("obstaculos")
	OclusoresCiudad.montar(cb)
	await cb._marca("oclusores")
	await _agrupar(cb)
	if not is_instance_valid(cb):
		return
	await cb._marca("opt_agrupar")
	await OptimizarGrada.al_final(cb, cb.modo_prologo, cb)   ## zonas de vista + tope de distancia de ULTRA BAJA/BAJA (7-11)

static func _trocear(cb) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var fuera := Optimizar.trocear_fuera(cb)
	for n in cb.find_children("*", "MultiMeshInstance3D", true, false):
		await cb.ceder()
		if not is_instance_valid(cb):
			return   ## (cambio de escena mientras cedía)
		if is_instance_valid(n):
			Optimizar.trocear_uno(n, fuera, cb)

static func _obstaculos(cb) -> PackedVector3Array:
	var sal := PackedVector3Array()
	var rej := Optimizar._rejilla(ExploradorCiudad.construir_obstaculos(cb))
	for n in cb.find_children("*", "MeshInstance3D", true, false):
		await cb.ceder()
		if not is_instance_valid(cb):
			return sal   ## (cambio de escena mientras cedía)
		if is_instance_valid(n):
			Optimizar.obstaculo_malla(n, cb, rej, sal, 0.9, 0.9)
	for n in cb.find_children("*", "MultiMeshInstance3D", true, false):
		await cb.ceder()
		if not is_instance_valid(cb):
			return sal   ## (cambio de escena mientras cedía)
		if is_instance_valid(n):
			Optimizar.obstaculo_multimalla(n, cb, rej, sal, 0.9, 0.9)
	return sal

static func _agrupar(cb) -> void:
	var ctx := Optimizar.agrupar_inicio(cb)
	for n in cb.find_children("*", "MeshInstance3D", true, false):
		await cb.ceder()
		if not is_instance_valid(cb):
			return   ## (cambio de escena mientras cedía)
		if is_instance_valid(n):
			Optimizar.agrupar_uno(n, cb, true, ctx)
	Optimizar.agrupar_detalle(ctx)
	for k: String in (ctx["grupos"] as Dictionary).keys():
		await cb.ceder()
		if not is_instance_valid(cb):
			return
		Optimizar.agrupar_fusion(k, cb, ctx)
	Optimizar.agrupar_fin(cb, ctx)
