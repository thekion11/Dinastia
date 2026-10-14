extends Node
## AUDITORÍA TÉCNICA (14-10-2026, pasada 3): carga todos los shaders y escenas de
## juego, abre y cierra la pantalla principal y cuenta nodos huérfanos y recursos
## que no cargan. Los errores de compilación de shaders salen en el registro.
##   godot --headless --path . res://pruebas/auditoria_tecnica.tscn
var _fallos := 0

func _recoger(dir: String, ext: Array, salida: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		for e in ext:
			if f.ends_with(e):
				salida.append(dir.path_join(f))
	for sub in d.get_directories():
		if sub in [".godot", "capturas", ".git"]:
			continue
		_recoger(dir.path_join(sub), ext, salida)

func _ready() -> void:
	var shaders: Array = []
	_recoger("res://", [".gdshader"], shaders)
	var malos := 0
	for s: String in shaders:
		var sh := load(s) as Shader
		if sh == null:
			malos += 1
			print("SHADER NO CARGA ", s)
	print("shaders: %d, no cargan: %d" % [shaders.size(), malos])
	_fallos += malos
	var escenas: Array = []
	_recoger("res://escenas", [".tscn"], escenas)
	_recoger("res://ui", [".tscn"], escenas)
	var mal_e := 0
	for s: String in escenas:
		var ps := load(s) as PackedScene
		if ps == null:
			mal_e += 1
			print("ESCENA NO CARGA ", s)
	print("escenas de juego: %d, no cargan: %d" % [escenas.size(), mal_e])
	_fallos += mal_e
	## Nodos huérfanos tras abrir y cerrar la pantalla principal varias veces.
	var antes := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	for i in 3:
		var p: Node = (load("res://escenas/principal.tscn") as PackedScene).instantiate()
		add_child(p)
		await get_tree().process_frame
		await get_tree().process_frame
		p.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	var despues := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	print("nodos huérfanos: antes %d, después de 3 aperturas/cierres %d" % [antes, despues])
	print("objetos vivos: %d" % int(Performance.get_monitor(Performance.OBJECT_COUNT)))
	print("===== FIN AUDITORÍA TÉCNICA. %d fallos =====" % _fallos)
	get_tree().quit()
