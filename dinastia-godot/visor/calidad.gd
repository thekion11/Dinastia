class_name Calidad
extends "res://visor/calidad_p1.gd"
## (Parte 2 de 2 de `calidad.gd`.)

## Vuelve a abrir el juego con el motor elegido y cierra este.
static func relanzar(arbol: SceneTree) -> bool:
	var args := PackedStringArray()
	var saltar := false
	for a in OS.get_cmdline_args():
		if saltar:
			saltar = false
			continue
		if a == "--rendering-method" or a == "--rendering-driver":
			saltar = true
			continue
		args.append(a)
	if motor_ligero:
		args.append_array(["--rendering-method", "gl_compatibility"])
	if OS.create_process(OS.get_executable_path(), args) <= 0:
		return false
	arbol.quit()
	return true
