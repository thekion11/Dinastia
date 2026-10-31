extends BaseIdea
## REGISTRO DE FALLOS (plan §10): el autoload `Registro` oye los avisos del
## motor, los guarda en user://registro.txt sin rutas personales, rota y arma
## el informe que copia el botón de Ajustes.

func _probar() -> void:
	_titulo("REGISTRO DE FALLOS DEL JUGADOR")
	_comprobar(get_node_or_null("/root/Registro") != null, "el autoload Registro está cargado")
	var marca := "SONDA_REG_%d" % Time.get_ticks_usec()
	push_warning(marca + " en " + ProjectSettings.globalize_path("user://partidas/x.sav"))
	var ult := "\n".join(Registro.ultimas(50))
	_comprobar(ult.contains(marca), "un push_warning del juego llega al registro")
	_comprobar(ult.contains("AVISO: " + marca), "se apunta como AVISO")
	_comprobar(ult.contains("reg_registro.gd:"), "dice la línea del script que lo lanzó, no la de C++")
	_comprobar(not ult.contains(ProjectSettings.globalize_path("user://")), "la ruta absoluta de usuario no sale en el registro")
	_comprobar(ult.contains("user://partidas/x.sav"), "la ruta queda reescrita como user://")
	var home := OS.get_environment("HOME")
	if home.length() > 3:
		_comprobar(not Registro.limpiar("abro " + home + "/doc").contains(home), "el HOME se tacha")
	## Repetidos: diez iguales seguidos ocupan una línea y un contador.
	for i in 10:
		Registro.apuntar("AVISO", marca + " repetido")
	Registro.apuntar("AVISO", marca + " otro")
	var r2 := Registro.ultimas(20)
	var n_rep := 0
	for l: String in r2:
		if l.ends_with(marca + " repetido"):
			n_rep += 1
	_comprobar(n_rep == 1, "una línea repetida se escribe una sola vez (%d)" % n_rep)
	_comprobar("\n".join(r2).contains("repetido 9 veces más"), "y se cuenta cuántas veces se repitió")
	var inf := Registro.informe(30)
	_comprobar(inf.begins_with("INFORME DE FALLOS"), "el informe empieza con su cabecera")
	_comprobar(inf.contains("Godot 4.") and inf.contains(OS.get_name()) and inf.contains("idioma"), "el informe lleva versión, SO e idioma")
	_comprobar(inf.split("\n").size() <= 30 + 4, "el informe se limita a las últimas N líneas (cabecera: título, sistema, contacto, separador)")
	## Rotación: más de 256 KB pasan a registro.1.txt.
	var grande := "x".repeat(1000)
	for i in 300:
		Registro._escribir_linea(grande)
	_comprobar(FileAccess.file_exists("user://registro.1.txt"), "al pasar de 256 KB rota a registro.1.txt")
	_comprobar(FileAccess.get_file_as_bytes(Registro.RUTA).size() <= Registro.TAMANO_MAX, "el actual no pasa del tope")
	_comprobar(not FileAccess.file_exists("user://registro.3.txt"), "nunca hay más de 3 archivos")
	_comprobar(Registro.carpeta() != "", "hay carpeta que abrir")
	## Limpia la sonda: el relleno de «x» no debe quedarse en el registro.
	for i in Registro.ARCHIVOS:
		var ruta := Registro._ruta(i)
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))
	## M-430: los errores de la sesión anterior se cuentan al arrancar (solo los de la última cabecera).
	var prueba := "user://registro_prueba_m430.txt"
	var f := FileAccess.open(prueba, FileAccess.WRITE)
	f.store_string("===== sesión vieja\n10:00:00 ERROR: a\n===== sesión 2\n10:00:01 ERROR: b  [x.gd:1 f]\n10:00:02 AVISO: c\n10:00:03 SCRIPT: d\n")
	f.close()
	_comprobar(Registro._contar_errores_ultima_sesion(prueba) == 2, "cuenta los errores (no los avisos) de la última sesión")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(prueba))
