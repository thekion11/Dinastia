class_name PrecalentarAnim
extends RefCounted
## LA PRIMERA VEZ QUE SE CREA UN PERSONAJE (M-348, 28-10-2026): armar las ~350 animaciones de `AnimQuaternius` cuesta ~2,6-3 s (la segunda vez, 0: está en caché) y
## caía en medio de abrir el estadio, la ciudad o la mascota. Aquí se arman ANTES, en un hilo, mientras el jugador está en el menú: se crea un esqueleto aparte
## (sin colgarlo del árbol: solo se lee) y el hilo llena la misma caché (`_en_cache`, con candado). Probado: el hilo principal sigue pintando fotogramas. NUNCA esperar a este hilo bloqueando el principal (se cuelga: el hilo hace `load`).

static var _lanzado := false
static var _tarea := -1
static var _fin := false

## Lanza (una sola vez) el armado de las animaciones de los cuerpos dados, uno tras otro en el mismo hilo, con y sin acciones experimentales. No bloquea:
## devuelve el id de la tarea (para esperarla en las pruebas) o -1.
static func lanzar(cuerpos: Array = ["male", "female"]) -> int:
	if _lanzado:
		return -1
	var trabajos: Array = []
	for cuerpo: String in cuerpos:
		var d := FutbolistaQ.crear(1.9, cuerpo)
		if d.is_empty():
			continue
		var esq: Skeleton3D = d["esqueleto"]
		trabajos.append([esq, str((d["anim"] as AnimationPlayer).get_path_to(esq)), d["nodo"]])
	if trabajos.is_empty():
		return -1
	_lanzado = true
	_tarea = WorkerThreadPool.add_task(func() -> void:
		for t: Array in trabajos:
			for acciones in [true, false]:
				AnimQuaternius._en_cache(t[0], t[1], acciones)
			(t[2] as Node).queue_free.call_deferred())
	return _tarea

## Si el hilo ya acabó (o no se lanzó). Las pruebas lo sondean pintando fotogramas: el hilo principal NO debe bloquearse esperándolo, porque el hilo
## carga recursos (`load` de las animaciones de fútbol) y eso puede necesitar al principal (se colgaba con `wait_for_task_completion`).
static func terminado() -> bool:
	if _fin or _tarea < 0:
		return true
	_fin = WorkerThreadPool.is_task_completed(_tarea)   ## (tras `wait_for_task_completion` el id ya no vale: por eso se recuerda)
	return _fin
