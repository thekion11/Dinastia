extends BaseIdea
## PRECALENTAR LAS ANIMACIONES EN UN HILO (M-348, 28-10-2026): la biblioteca que arma el hilo es la misma que la del hilo principal, queda en la caché
## y crear después un personaje ya no paga el armado (la primera vez costaba ~2,6 s).

func _ready() -> void:
	await get_tree().process_frame
	_titulo("ANIMACIONES PRECALENTADAS EN UN HILO")
	## La de referencia, armada en el hilo principal con un esqueleto aparte (sin caché de por medio).
	var d0 := FutbolistaQ.crear(1.9, "male")
	var esq0: Skeleton3D = d0["esqueleto"]
	var pref := str((d0["anim"] as AnimationPlayer).get_path_to(esq0))
	var ref: AnimationLibrary = AnimQuaternius._construir(esq0, pref, true)
	## El hilo NUNCA construye: solo carga de la caché de disco. Se deja esa caché preparada (una construcción normal la escribe) y se vacía la de memoria,
	## así la prueba no depende de si el equipo ya tenía caché de una partida anterior (en un equipo limpio fallaba siempre).
	var d_pre := FutbolistaQ.crear(1.9, "male")
	FutbolistaQ.terminar(d_pre, true)
	(d_pre["nodo"] as Node).free()
	AnimQuaternius._bibliotecas.clear()
	var id := PrecalentarAnim.lanzar(["male"])
	_comprobar(id >= 0, "lanzar da el id de la tarea")
	_comprobar(PrecalentarAnim.lanzar(["male"]) == -1, "una segunda vez no vuelve a lanzar")
	while not PrecalentarAnim.terminado():
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(id)
	await get_tree().process_frame
	await get_tree().process_frame
	var d := FutbolistaQ.crear(1.9, "male")
	add_child(d["nodo"])
	## (6-11) Recuento y no tiempo (regla: nada de tiempos en headless): si la biblioteca ya está en la caché, `terminar` no arma ninguna nueva.
	var n_antes: int = AnimQuaternius._bibliotecas.size()
	FutbolistaQ.terminar(d, true)
	var n_despues: int = AnimQuaternius._bibliotecas.size()
	_comprobar(n_antes > 0 and n_despues == n_antes, "tras precalentar, `terminar` reutiliza la caché y no arma bibliotecas nuevas (%d → %d)" % [n_antes, n_despues])
	var lib: AnimationLibrary = (d["anim"] as AnimationPlayer).get_animation_library("")
	_comprobar(lib.get_animation_list().size() == ref.get_animation_list().size() and lib.get_animation_list().size() > 100,
		"la misma cantidad de animaciones que armada en el hilo principal (%d)" % lib.get_animation_list().size())
	var pistas_hilo := 0
	var pistas_ref := 0
	for n in ref.get_animation_list():
		pistas_ref += ref.get_animation(n).get_track_count()
		pistas_hilo += lib.get_animation(n).get_track_count() if lib.has_animation(n) else -1000000
	_comprobar(pistas_hilo == pistas_ref, "y las mismas pistas en total (%d)" % pistas_ref)
	d0["nodo"].free()
	d["nodo"].free()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)
