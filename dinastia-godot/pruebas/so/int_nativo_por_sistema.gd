extends BaseSO
## INTEGRACIÓN · extensión C++ = GDScript, según el sistema: donde hay binario (Linux, Windows x86_64, Android arm64) la extensión TIENE que
## cargar y dar los mismos bytes que GDScript; donde no hay (Web, macOS, iOS), `Nativo.obj()` es null y la ruta GDScript (el respaldo) da
## el mismo resultado que daría C++. Así ningún sistema se salta la comprobación: cada uno comprueba la suya.
func _nombre() -> String:
	return "int_nativo_por_sistema"

func _probar() -> void:
	_titulo("INTEGRACIÓN · nativo C++ = GDScript [%s %s]" % [sistema(), Engine.get_architecture_name()])
	var nat := Nativo.obj()
	var esperado := se_espera_nativo() and OS.get_environment("DINASTIA_SIN_NATIVO") != "1"
	_comprobar((nat != null) == esperado, "extensión %s (esperado para %s/%s: %s)" % ["cargada" if nat != null else "ausente", sistema(), Engine.get_architecture_name(), "sí" if esperado else "no"])
	## El binario que le toca a este sistema existe en disco.
	var cf := ConfigFile.new()
	_comprobar(cf.load("res://bin_nativo/dinastia.gdextension") == OK, "dinastia.gdextension se lee")
	var clave := "%s.%s.%s" % [sistema(), "debug" if OS.has_feature("debug") else "release", Engine.get_architecture_name()]
	if se_espera_nativo():
		_comprobar(cf.has_section_key("libraries", clave), "el .gdextension declara la biblioteca «%s»" % clave)
	else:
		_comprobar(not cf.has_section_key("libraries", clave), "el .gdextension NO declara biblioteca para «%s» (usa GDScript)" % clave)
	## Rampa de ruido: la ruta pública (nativa o respaldo) = la versión GDScript, byte a byte.
	var n := FastNoiseLite.new()
	n.seed = 97
	var img := n.get_seamless_image(256, 256, false, false, 0.1, true)
	var lut := RuidosFondo._lut(0.78)
	_comprobar(RuidosFondo._con_rampa_gd(img, lut).get_data() == RuidosFondo._con_rampa(img, lut).get_data(), "rampa de ruido: ruta pública = GDScript")
	## Terreno de la ciudad.
	var r := FastNoiseLite.new()
	r.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	r.seed = 20260912
	r.frequency = 0.00055
	r.fractal_octaves = 4
	r.fractal_lacunarity = 2.1
	var d := FastNoiseLite.new()
	d.noise_type = FastNoiseLite.TYPE_SIMPLEX
	d.seed = 771
	d.frequency = 0.0035
	_comprobar(var_to_bytes(TerrenoArreglos.calcular_gd(r, d)) == var_to_bytes(TerrenoArreglos.calcular(r, d)), "terreno: ruta pública = GDScript")
	_comprobar(CityBuilder._imagen_hierba_gd().get_data() == CityBuilder._imagen_hierba().get_data(), "hierba: ruta pública = GDScript")
	## Once automático en 12 clubes.
	var m := _mundo(20261105)
	var forms: Dictionary = Datos.tabla("FORMS")
	var comparados := 0
	var distintos := 0
	for c: Club in m.clubes.values().slice(0, 12):
		for fk: String in forms.keys().slice(0, 4):
			var ranuras: Array = (forms[fk] as Dictionary).get("s", [])
			var orden: Array = []
			for i in ranuras.size():
				orden.append(i)
			orden.sort_custom(func(a: int, b: int) -> bool: return PesosPuesto.es_portero(String(ranuras[a][0])) and not PesosPuesto.es_portero(String(ranuras[b][0])))
			var libres: Array = c.disponibles()
			var ag := OnceAuto.asignar_gd(libres, ranuras, orden)
			var ap: Dictionary = OnceAuto._nativo(nat, libres, ranuras, orden) if nat != null else ag
			comparados += 1
			var igual := ag.keys() == ap.keys()
			if igual:
				for i: int in ag:
					igual = igual and (ag[i] as Jugador).id == (ap[i] as Jugador).id
			distintos += int(not igual)
	_comprobar(comparados >= 40 and distintos == 0, "once automático: %d armados, %d distintos" % [comparados, distintos])
