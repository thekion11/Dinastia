extends BaseIdea
## A4-M3D (repaso 5 cruzado, 4-11-2026): la ciudad se construye y se libera VARIAS veces (entrar y salir de la
## ciudad en una sesión larga) sin que crezcan los nodos, los objetos ni la memoria, y el terreno responde a
## posiciones extremas (muy lejos, negativas, enormes) sin NaN ni cuelgue.
const DATOS := {"club": {"nombre": "Andino FC", "c1": Color(0.8, 0.1, 0.1), "c2": Color.WHITE, "cap": 30000, "rep": 60, "socios": 20000,
	"estadioNom": "Estadio"}, "inst": {}, "obras": [], "terrenos": [], "negocios": {}, "perfil_estadio": {}, "dia_partido": true, "vecinos": 30}

func _medir() -> Dictionary:
	return {"nodos": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "objetos": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"huerfanos": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), "mem": int(OS.get_static_memory_usage() / 1048576)}

func _probar() -> void:
	_titulo("CICLOS DE CIUDAD Y TERRENO EXTREMO")
	var tras: Array = []
	for i in (int(OS.get_environment("CICLOS")) if OS.get_environment("CICLOS") != "" else 5):
		var b := CityBuilder.new()
		add_child(b)
		b.build(DATOS)
		await get_tree().process_frame
		remove_child(b)
		b.free()
		await get_tree().process_frame
		await get_tree().process_frame
		tras.append(_medir())
		_linea("ciclo %d: %s" % [i + 1, tras[i]])
	## El primer ciclo calienta cachés; del 2.º al 4.º no debe crecer nada de forma sostenida.
	_comprobar(tras[tras.size() - 1]["nodos"] <= tras[1]["nodos"] + 50, "los nodos no crecen entre ciclos (%d → %d)" % [tras[1]["nodos"], tras[tras.size() - 1]["nodos"]])
	_comprobar(tras[tras.size() - 1]["huerfanos"] <= tras[1]["huerfanos"] + 20, "no se acumulan nodos huérfanos (%d → %d)" % [tras[1]["huerfanos"], tras[tras.size() - 1]["huerfanos"]])
	_comprobar(tras[tras.size() - 1]["objetos"] <= tras[1]["objetos"] + 12 * (tras.size() - 2), "los objetos no crecen entre ciclos (%d → %d)" % [tras[1]["objetos"], tras[tras.size() - 1]["objetos"]])
	_comprobar(tras[tras.size() - 1]["mem"] <= tras[1]["mem"] + 2 * (tras.size() - 2), "la memoria estática no crece entre ciclos (%d → %d MB)" % [tras[1]["mem"], tras[tras.size() - 1]["mem"]])
	var b2 := CityBuilder.new()
	add_child(b2)
	var malos := 0
	for p in [Vector2(0, 0), Vector2(-1.0e5, 1.0e5), Vector2(1.0e7, -1.0e7), Vector2(1.0e-9, -1.0e-9), Vector2(5000, 5000), Vector2(-300, 40)]:
		var h := b2.altura_en(p.x, p.y)
		if not is_finite(h): malos += 1
	_comprobar(malos == 0, "altura_en devuelve valores finitos en posiciones extremas (%d no finitas)" % malos)
