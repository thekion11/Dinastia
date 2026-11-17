extends SceneTree
## Carga TODOS los scripts del proyecto y avisa de los que no compilan (23-10-2026).
## Lo usa el reparto en capas (`herramientas/partir_gd.py`): un error de sintaxis o de
## tipos en cualquier capa sale aquí aunque el banco no pase por ese archivo.
## (16-11-2026, informe F-03) También aplica la NORMA DE 450 LÍNEAS: como corre a la vez que el
## banco (`herramientas/banco.sh`), un script que la pase deja el banco en rojo antes de subir.
##
##   godot --headless --path . --script res://pruebas/comprobar_scripts.gd
## Termina con «FIN. 0 fallos» (código 0) o con la lista de los que fallan.

const LIMITE := 450
## Fuera de la norma, igual que en `herramientas/revisar_lineas.py`: lo genera una herramienta (se parte en el generador).
const EXCEPCIONES := ["res://nucleo/dialogos_ciudad.gd"]
## PENDIENTES DE PARTIR, con su tope actual: pasan mientras no CREZCAN. Cada uno lleva quién lo parte;
## al partirlo se BORRA de aquí. No añadir nada sin ese motivo.
const PENDIENTES := {
}

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
		var n := _lineas(r)
		if n > LIMITE and not EXCEPCIONES.has(r) and n > int(PENDIENTES.get(r, LIMITE)):
			fallos += 1
			print("FALLO %s: %d líneas (norma de %d; partir con herramientas/partir_gd.py)" % [r, n, LIMITE])
	print("%d scripts comprobados" % rutas.size())
	print("===== FIN. %d fallos" % fallos)
	quit(1 if fallos > 0 else 0)

## Las mismas líneas que cuenta `revisar_lineas.py` (una por salto; la última sin salto también cuenta).
func _lineas(ruta: String) -> int:
	var texto := FileAccess.get_file_as_string(ruta)
	if texto.is_empty():
		return 0
	return texto.count("\n") + (0 if texto.ends_with("\n") else 1)

func _buscar(dir: String, salida: Array[String]) -> void:
	for d in DirAccess.get_directories_at(dir):
		## (31-10) Lo que Godot ignora (`.gdignore`: `nativo/`, con godot-cpp descargado al compilar) tampoco se comprueba.
		if d.begins_with(".") or d == "addons" or d == "capturas" or FileAccess.file_exists(dir.path_join(d).path_join(".gdignore")):
			continue
		_buscar(dir.path_join(d), salida)
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			salida.append(dir.path_join(f))
