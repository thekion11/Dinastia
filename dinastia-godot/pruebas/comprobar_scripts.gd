extends SceneTree
## Carga TODOS los scripts del proyecto y avisa de los que no compilan (23-10-2026).
## Lo usa el reparto en capas (`herramientas/partir_gd.py`): un error de sintaxis o de
## tipos en cualquier capa sale aquí aunque el banco no pase por ese archivo.
##
##   godot --headless --path . --script res://pruebas/comprobar_scripts.gd
## Termina con «FIN. 0 fallos» (código 0) o con la lista de los que fallan.

func _initialize() -> void:
	var rutas: Array[String] = []
	_buscar("res://", rutas)
	rutas.sort()
	var fallos := 0
	for r in rutas:
		var s := load(r) as GDScript
		if s == null or not s.can_instantiate():
			fallos += 1
			print("FALLO ", r)
	print("%d scripts comprobados" % rutas.size())
	print("===== FIN. %d fallos" % fallos)
	quit(1 if fallos > 0 else 0)

func _buscar(dir: String, salida: Array[String]) -> void:
	for d in DirAccess.get_directories_at(dir):
		if d.begins_with(".") or d == "addons" or d == "capturas":
			continue
		_buscar(dir.path_join(d), salida)
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			salida.append(dir.path_join(f))
