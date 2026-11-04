extends BaseIdea
## A4-M3D (repaso 5 cruzado, 4-11-2026): la ciudad con tráfico, metro y vecinos funcionando durante muchos
## fotogramas (una sesión larga) no acumula nodos ni objetos: lo que nace (coches, peatones, pasajeros) se libera.
const DATOS := {"club": {"nombre": "Andino FC", "c1": Color(0.8, 0.1, 0.1), "c2": Color.WHITE, "cap": 30000, "rep": 60, "socios": 20000,
	"estadioNom": "Estadio"}, "inst": {}, "obras": [], "terrenos": [], "negocios": {}, "perfil_estadio": {}, "dia_partido": true, "vecinos": 30}

func _medir() -> Dictionary:
	return {"nodos": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "objetos": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"mem": int(OS.get_static_memory_usage() / 1048576)}

func _probar() -> void:
	_titulo("CIUDAD EN MARCHA MUCHO TIEMPO")
	## El autoload Sonido sintetiza sus ~820 sonidos en un hilo durante los primeros segundos (en una máquina lenta,
	## como el CI, tarda más que unos cuantos ciclos): sin esperar a que termine, esa carga parece una fuga.
	get_node("/root/Sonido")._generar_todo()
	var n := int(OS.get_environment("TRAMOS")) if OS.get_environment("TRAMOS") != "" else 4
	var b := CityBuilder.new()
	add_child(b)
	b.build(DATOS)
	var fotos: Array = []
	for t in n:
		for f in 150:
			await get_tree().process_frame
		fotos.append(_medir())
		_linea("tramo %d (150 fotogramas): %s" % [t + 1, fotos[t]])
	var u: Dictionary = fotos[n - 1]
	var k: Dictionary = fotos[1]
	_comprobar(u["nodos"] <= k["nodos"] + 60, "los nodos no crecen con el tiempo (%d → %d)" % [k["nodos"], u["nodos"]])
	_comprobar(u["objetos"] <= k["objetos"] + 150 * (n - 2), "los objetos no crecen con el tiempo (%d → %d)" % [k["objetos"], u["objetos"]])
	_comprobar(u["mem"] <= k["mem"] + 10 * (n - 2), "la memoria no crece con el tiempo (%d → %d MB)" % [k["mem"], u["mem"]])
