extends BaseSO
## COMÚN · el arranque: la escena principal y todos los autoloads de project.godot existen y cargan, están en el árbol y en el orden que
## pide el proyecto (Parches primero, Registro después), y el sistema es uno de los seis conocidos. Vale igual en cada sistema.
func _nombre() -> String:
	return "com_arranque_autoloads"

func _probar() -> void:
	_titulo("COMÚN · arranque y autoloads [%s]" % sistema())
	_comprobar(["windows", "linux", "macos", "android", "ios", "web"].has(sistema()), "sistema conocido: %s" % sistema())
	var cf := ConfigFile.new()
	_comprobar(cf.load("res://project.godot") == OK, "project.godot se lee desde res:// (en un export va dentro del paquete)")
	var principal := String(ProjectSettings.get_setting("application/run/main_scene", ""))
	_comprobar(principal != "" and ResourceLoader.exists(principal), "la escena principal existe: %s" % principal)
	var orden: Array[String] = []
	for k in ProjectSettings.get_property_list():
		var nombre := String(k["name"])
		if nombre.begins_with("autoload/"):
			orden.append(nombre.trim_prefix("autoload/"))
	_comprobar(orden.size() >= 10, "hay %d autoloads" % orden.size())
	_comprobar(orden.size() > 1 and orden[0] == "Parches" and orden[1] == "Registro", "Parches va primero y Registro segundo (%s)" % str(orden.slice(0, 2)))
	for nombre in orden:
		var ruta := String(ProjectSettings.get_setting("autoload/" + nombre)).trim_prefix("*")
		_comprobar(ResourceLoader.exists(ruta), "autoload %s: %s existe" % [nombre, ruta])
		_comprobar(get_tree().root.has_node(nombre), "autoload %s está en el árbol" % nombre)
	_comprobar(Idiomas.idioma != "", "Idiomas listo (%s)" % Idiomas.idioma)
	_comprobar(Datos.cuantas() > 20, "Datos cargó %d tablas" % Datos.cuantas())
	var proy := String(ProjectSettings.get_setting("application/config/name", ""))
	_comprobar(proy != "", "el proyecto tiene nombre: %s" % proy)
	_comprobar(bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", false)), "el toque emula el ratón (la interfaz son botones): sin esto el móvil no responde")
