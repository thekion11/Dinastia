extends BaseIdea
## 7 NIVELES DE CALIDAD (6-11-2026, docs/04_auditorias/calidad_7_niveles_2026-11-06.md). Fija: (1) los valores del enum y sus alias viejos,
## (2) la migración del número guardado (archivo viejo −1/0/1/2 sin `version_calidad`, archivo nuevo, ida y vuelta, config del club y del orquestador),
## (3) que el nivel POR DEFECTO es el más bajo en cada plataforma simulada y que ninguna ruta (sin archivo, equipo fuerte o débil, móvil, web)
## lo sube, y (4) que `elegida` nunca sale de −3…3 aunque el archivo diga lo que diga.

func _probar() -> void:
	_titulo("REN: 7 NIVELES DE CALIDAD, MIGRACIÓN Y DEFECTO")
	_comprobar(Calidad.ULTRA_BAJA == -3 and Calidad.BAJA == -2 and Calidad.MEDIA_BAJA == -1 and Calidad.MEDIA == 0 \
			and Calidad.MEDIA_ALTA == 1 and Calidad.ALTA == 2 and Calidad.ULTRA_ALTA == 3, "los siete valores van de −3 a 3 en orden")
	_comprobar(Calidad.MINIMO == Calidad.ULTRA_BAJA and Calidad.MEDIO == Calidad.MEDIA and Calidad.ALTO == Calidad.ALTA \
			and Calidad.ULTRA == Calidad.ULTRA_ALTA, "los nombres viejos son alias de los nuevos")
	_comprobar(Calidad.NIVEL_DEFECTO == Calidad.ULTRA_BAJA, "el nivel por defecto es ULTRA BAJA")
	## Esquema viejo (sin versión o 1)
	for par in [[-1, Calidad.ULTRA_BAJA], [0, Calidad.MEDIA], [1, Calidad.ALTA], [2, Calidad.ULTRA_ALTA], [-9, Calidad.ULTRA_BAJA], [9, Calidad.ULTRA_ALTA]]:
		_comprobar(Calidad.desde_guardado(par[0]) == par[1] and Calidad.desde_guardado(par[0], 1) == par[1], "viejo %d → %d" % [par[0], par[1]])
	## Esquema nuevo (versión 2): pasa tal cual y se recorta a −3…3
	for v in range(-3, 4):
		_comprobar(Calidad.desde_guardado(v, Calidad.VERSION) == v, "nuevo %d se queda en %d" % [v, v])
	_comprobar(Calidad.desde_guardado(-50, Calidad.VERSION) == Calidad.ULTRA_BAJA and Calidad.desde_guardado(50, Calidad.VERSION) == Calidad.ULTRA_ALTA, "nuevo fuera de rango se recorta")
	## Archivos reales de ajustes (user:// es propio de cada prueba)
	var viejo := {-1: Calidad.ULTRA_BAJA, 0: Calidad.MEDIA, 1: Calidad.ALTA, 2: Calidad.ULTRA_ALTA}
	for k in viejo:
		_escribir_cfg({"calidad": k})
		Calidad.elegida = Calidad.ALTA
		Calidad.cargar()
		_comprobar(Calidad.elegida == viejo[k], "archivo viejo calidad=%d → %d (sin version_calidad)" % [k, viejo[k]])
		Calidad.guardar()   ## al guardar ya queda en el esquema nuevo
		var cf := ConfigFile.new()
		cf.load(Calidad.ARCHIVO)
		_comprobar(int(cf.get_value("grafica", "version_calidad", 0)) == Calidad.VERSION and int(cf.get_value("grafica", "calidad")) == viejo[k], "tras guardar queda version_calidad=%d y calidad=%d" % [Calidad.VERSION, viejo[k]])
		Calidad.elegida = Calidad.MEDIA
		Calidad.cargar()
		_comprobar(Calidad.elegida == viejo[k], "ida y vuelta del archivo nuevo: %d" % viejo[k])
	for v in range(-3, 4):
		_escribir_cfg({"calidad": v, "version_calidad": Calidad.VERSION})
		Calidad.cargar()
		_comprobar(Calidad.elegida == v, "archivo nuevo calidad=%d" % v)
	## Config del club y del orquestador: lo viejo se convierte; lo nuevo (con versión) pasa
	var cd := ConfigClubDatos.new()
	cd.desde_dic({"maquina": {"calidad": 1}})
	_comprobar(cd.calidad == Calidad.ALTA, "config del club vieja (calidad=1) → ALTA")
	cd.desde_dic({"maquina": {"calidad": -2, "version_calidad": Calidad.VERSION}})
	_comprobar(cd.calidad == Calidad.BAJA, "config del club nueva (calidad=-2, versión 2) → BAJA")
	## Defecto: sin archivo, en cada plataforma simulada, nunca más alto que ULTRA BAJA
	var perfiles := {
		"PC fuerte": {"gpu": "NVIDIA RTX 4090", "ram_mb": 32000, "hilos": 16, "debil": false, "motivos": []},
		"PC modesto": {"gpu": "Intel UHD Graphics", "ram_mb": 4096, "hilos": 2, "debil": true, "motivos": ["prueba"]},
		"móvil": {"gpu": "Adreno (TM) 640", "ram_mb": 6000, "hilos": 8, "debil": true, "motivos": ["móvil"]},
		"web": {"gpu": "ANGLE", "ram_mb": 0, "hilos": 4, "debil": true, "motivos": ["web"]},
	}
	for nombre in perfiles:
		_borrar_cfg()
		Calidad.elegida = Calidad.NIVEL_DEFECTO
		CalidadAuto.aplicar_si_primera_vez(perfiles[nombre])
		_comprobar(Calidad.elegida == Calidad.ULTRA_BAJA, "%s: sin archivo, el nivel sigue siendo ULTRA BAJA" % nombre)
		_borrar_cfg()
		Calidad.elegida = Calidad.NIVEL_DEFECTO
		Calidad.cargar()
		_comprobar(Calidad.elegida == Calidad.ULTRA_BAJA, "%s: cargar() sin archivo deja ULTRA BAJA" % nombre)
	_borrar_cfg()

func _escribir_cfg(d: Dictionary) -> void:
	var cf := ConfigFile.new()
	for k in d:
		cf.set_value("grafica", k, d[k])
	cf.save(Calidad.ARCHIVO)

func _borrar_cfg() -> void:
	if FileAccess.file_exists(Calidad.ARCHIVO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Calidad.ARCHIVO))
