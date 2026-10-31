extends SceneTree
## HORNEA LAS 4 BIBLIOTECAS DE ANIMACIÓN PARA EL BUILD (30-10-2026, rendimiento).
## La primera vez que se juega, construirlas costaba ~6 s (1,4 s en la pantalla del personaje y
## el resto al abrir el primer estadio). Las arma con el código actual, igual que en el juego
## (modelo en el árbol, sin caché), y las deja en la carpeta pedida con un `manifiesto.json`
## (versión del juego y del motor). Lo llama el plugin `addons/cache_horneada` al exportar;
## a mano:  godot --headless --path . --script res://herramientas/hornear_animaciones.gd -- <carpeta>

func _init() -> void:
	_hornear.call_deferred()

func _hornear() -> void:
	var args := OS.get_cmdline_user_args()
	var carpeta: String = args[0] if args.size() > 0 else "user://cache_horneada"
	OS.set_environment("DINASTIA_SIN_CACHE", "1")   ## construirlas de verdad, no leer otra caché
	DirAccess.make_dir_recursive_absolute(carpeta)
	for exp: bool in [false, true]:
		for cuerpo in ["male", "female"]:
			var d := FutbolistaQ.crear(FutbolistaQ.ALTURA_BASE, cuerpo)
			root.add_child(d["nodo"])
			FutbolistaQ.terminar(d, exp)
	var n := 0
	for clave: String in AnimQuaternius._bibliotecas:
		var lib: AnimationLibrary = AnimQuaternius._bibliotecas[clave]
		var ruta := carpeta.path_join(CacheDisco.nombre_horneada("anim|" + clave))
		if ResourceSaver.save(lib, ruta, ResourceSaver.FLAG_COMPRESS) == OK:
			n += 1
	var f := FileAccess.open(carpeta.path_join("manifiesto.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(CacheDisco.manifiesto_actual()))
	f.close()
	print("HORNEADAS %d bibliotecas en %s" % [n, carpeta])
	quit(0 if n == 4 else 1)
