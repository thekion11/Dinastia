extends BaseIdea
## FASE 1, ETAPA 4: LA CONFIGURACIÓN DEL CLUB (`PantallaConfigClub` + `ConfigClubDatos`).
## El modelo (validación, ida y vuelta del diccionario, aplicar al club y a la máquina sin
## tocar los archivos de verdad) y la pantalla entera: sus 8 pasos, la vista previa, la
## navegación con errores, volver, y confirmar → `terminado({"config": …})`.

const PRUEBA_PREFS := "user://f1c_prefs_prueba.cfg"

## La pantalla necesita fotogramas: se sobreescribe el `_ready` de la base para esperar.
func _ready() -> void:
	await get_tree().process_frame
	_probar()
	await _probar_pantalla()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _probar() -> void:
	_titulo("CONFIGURACIÓN DEL CLUB: EL MODELO")
	_comprobar(ConfigClubDatos.FPS == Principal.FPS_OPCIONES, "las opciones de FPS son las del menú central")
	for k: String in MascotaQ.ANIMALES:
		_comprobar(ConfigClubDatos.ANIMALES.has(k), "el animal «%s» tiene nombre e icono" % k)
	var m := Mundo.new()
	m.generar(["CHI"], 4141)
	## Fundar un club: el nombre lo pone el jugador.
	var d := ConfigClubDatos.new()
	d.desde_estado({"mundo": m, "modo": "creador"})
	_comprobar(d.crea_club and d.club.nombre == "", "al fundar, el nombre empieza vacío")
	_comprobar(d.hay_graves(0), "sin nombre no se puede confirmar")
	d.club.nombre = "Atlético Pruebas"
	_comprobar(not d.hay_graves(), "con nombre ya no hay errores graves (%s)" % str(d.validar()))
	d.club.nombre = Nombres.visible(m.ligas[0].clubes[3].nombre)
	_comprobar(d.hay_graves(0), "un nombre de otro club existente es un error")
	d.club.nombre = "  x "
	_comprobar(d.hay_graves(0), "un nombre de una letra es un error")
	d.club.nombre = "Atlético Pruebas"
	d.club.estadio_nombre = "ab"
	_comprobar(d.hay_graves(0), "un estadio de dos letras es un error (vacío sí vale)")
	d.club.estadio_nombre = ""
	d.club.color1 = "#204060"
	d.club.color2 = "#214161"
	var leves := d.validar().filter(func(p: Dictionary) -> bool: return not bool(p["grave"]))
	_comprobar(not leves.is_empty() and not d.hay_graves(), "dos colores casi iguales: aviso, no bloqueo")
	d.club.color2 = "#f2c230"
	d.mascota = "tiburon"
	d.estilo_estadio = "bombonera"
	d.vivienda = "jardin"
	d.lema = "Siempre adelante"
	d.fps = 120
	d.densidad = "alta"
	var cfg := d.a_dic()
	_comprobar(String(cfg.get("nombre_club", "")) == "Atlético Pruebas", "al fundar sale «nombre_club» (lo lee el orquestador)")
	_comprobar((cfg["club"]["identidad"] as Dictionary).keys() == Club.new().identidad_a_dic().keys(),
		"la identidad sale en el formato de Club.identidad_a_dic()")
	_comprobar(String(cfg["club"]["identidad"]["esc_f"]) != "" and String(cfg["club"]["identidad"]["esc_p"]) != "",
		"forma y patrón del escudo salen explícitos (lo que se ve es lo que queda)")
	_comprobar(not (cfg["club"]["identidad"]["kit_x"] as Dictionary).has("escudo_tex"), "sin texturas dentro del diccionario")
	_comprobar(not cfg.has("mascota"), "«mascota» no va plana (en el orquestador es la mascota de la familia)")
	var d2 := ConfigClubDatos.new()
	d2.desde_estado({"mundo": m, "modo": "creador", "config": cfg})
	_comprobar(d2.a_dic() == cfg, "ida y vuelta: volver a la etapa no pierde nada")
	_comprobar(OrquestadorMundo.crea_club({"config": cfg}), "el orquestador entiende que se funda un club")

	## Tomar un club existente: conserva nombre, escudo y mascota de siempre.
	var real: Club = m.ligas[0].clubes[2]
	var d3 := ConfigClubDatos.new()
	d3.desde_estado({"mundo": m, "modo": "dt", "pais": {"pais": "CHI", "club_id": real.id}})
	_comprobar(not d3.crea_club and d3.club.nombre == real.nombre, "un club existente llega con su nombre")
	_comprobar(d3.mascota == EstadioExtras.animal_de(real), "y con su mascota de siempre")
	_comprobar(Escudo.svg_de(d3.club) == Escudo.svg_de(real), "y con su mismo escudo")
	var cfg3 := d3.a_dic()
	_comprobar(not cfg3.has("nombre_club") and not OrquestadorMundo.crea_club({"config": cfg3}),
		"sin fundar no sale «nombre_club»: el orquestador no crea un club")

	## Aplicar al club y al mundo.
	_titulo("CONFIGURACIÓN DEL CLUB: APLICAR")
	m.tomar_el_mando(real.id)
	ConfigClubDatos.aplicar_al_club(cfg, real, m)
	_comprobar(real.nombre == "Atlético Pruebas" and real.color2 == "#f2c230", "nombre y colores aplicados")
	_comprobar(Escudo.svg_de(real) == Escudo.svg_de(d.club), "el escudo aplicado es el de la vista previa")
	_comprobar(DisenosKit.kit_de_club(real)["dis"] == DisenosKit.kit_de_club(d.club)["dis"], "la camiseta aplicada es la de la vista previa")
	var masc: String = String(real.get("mascota")) if "mascota" in real else String(real.get_meta("mascota", ""))
	_comprobar(masc == "tiburon", "la mascota queda en el club")
	var pre: Dictionary = ConfigClubDatos.presets().filter(func(p: Dictionary) -> bool: return p["clave"] == "bombonera")[0]
	_comprobar(String(m.estadio.ajustes.get("forma")) == String(pre["cambios"]["forma"]) and m.estadio.obra.is_empty(),
		"el estilo del estadio se estrena sin obra")
	_comprobar(m.estadio.real_de == real.id, "y no lo pisa el estadio real del club")
	_comprobar(int(m.estadio.ajustes.get("niveles", 1)) <= m.estadio.niveles_maximos(real, m.obras), "sin bandejas que el club no sostiene")
	_comprobar(m.vida == null or m.vida.vivienda == "jardin", "la casa elegida")
	_comprobar(m.comercial == null or m.comercial.lema == "Siempre adelante", "el lema")
	var calidad_antes := Calidad.elegida
	ConfigClubDatos.aplicar_maquina(cfg, PRUEBA_PREFS)
	var cf := ConfigFile.new()
	cf.load(PRUEBA_PREFS)
	_comprobar(int(cf.get_value("pantalla", "fps", -1)) == 120, "los FPS quedan en las preferencias")
	_comprobar(Calidad.elegida == calidad_antes, "con un archivo de prueba no se toca la gráfica de verdad")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PRUEBA_PREFS))

func _probar_pantalla() -> void:
	_titulo("CONFIGURACIÓN DEL CLUB: LA PANTALLA")
	var m := Mundo.new()
	m.generar(["CHI"], 5252)
	var p := PantallaConfigClub.new()
	p.configurar({"mundo": m, "modo": "creador"})
	var emitido: Array = []
	var volvio: Array = []
	p.terminado.connect(func(x: Dictionary) -> void: emitido.append(x))
	p.volver.connect(func() -> void: volvio.append(true))
	add_child(p)
	await get_tree().process_frame
	_comprobar(p._chips.size() == 8, "ocho pasos en la barra")
	_comprobar(p._contenido.get_child_count() > 0, "el primer paso se pinta")
	p.siguiente()
	_comprobar(p._paso == 0, "sin nombre no se avanza")
	_comprobar(p._aviso.text.contains("3"), "y el pie dice por qué: «%s»" % p._aviso.text)
	var campo: LineEdit = p._contenido.find_child("CampoNombre", true, false)
	_comprobar(campo != null and campo.editable, "el nombre se escribe en el primer paso")
	campo.text = "Deportivo Vista"
	campo.text_changed.emit(campo.text)
	for i in 12:
		await get_tree().process_frame
	_comprobar(p._p_escudo.texture != null and p._p_kit.texture != null, "la vista previa tiene escudo y equipación")
	_comprobar(p._p_nombre.text == "Deportivo Vista", "y el nombre en vivo")
	var antes := p._p_kit.texture
	p.siguiente()
	p.siguiente()
	_comprobar(p._paso == 2, "con nombre se avanza")
	p._color_kit(0, "#aa1111")
	for i in 12:
		await get_tree().process_frame
	_comprobar(p._p_kit.texture != antes and p.datos.club.kit_color1 == "#aa1111", "cambiar un color de camiseta rehace la vista previa")
	for paso in range(8):
		p.ir_a(paso)
		await get_tree().process_frame
		_comprobar(p._contenido.get_child_count() > 0, "el paso %d (%s) se pinta" % [paso + 1, p.PASOS[paso][1]])
		if paso == 1:
			for i in 30:
				await get_tree().process_frame
			var con := 0
			for mini: Array in p._minis_escudo:
				if (mini[0] as TextureRect).texture != null:
					con += 1
			_comprobar(con == Escudo.FORMAS.size() + Escudo.PATRONES.size(), "las %d miniaturas del escudo se dibujan (%d)" % [Escudo.FORMAS.size() + Escudo.PATRONES.size(), con])
		if paso == 3:
			await get_tree().process_frame
			var vm: Node = p._vista_mascota
			_comprobar(vm != null and vm.find_child("Mascota", true, false) != null, "la mascota sale en 3D")
	p.ir_a(0)
	p.atras()
	_comprobar(volvio.size() == 1, "«Volver» en el primer paso pide la etapa anterior")
	p.ir_a(7)
	p.siguiente()
	await get_tree().process_frame
	var capa: Node = p.find_child("Confirmacion", true, false)
	_comprobar(capa != null and emitido.is_empty(), "confirmar pide confirmación antes de emitir")
	var si: Button = capa.find_child("BotonConfirmar", true, false) if capa != null else null
	if si != null:
		si.pressed.emit()
	_comprobar(emitido.size() == 1 and (emitido[0] as Dictionary).has("config"), "«Sí, confirmar» emite terminado({config})")
	if emitido.size() == 1:
		var cfg: Dictionary = emitido[0]["config"]
		_comprobar(String(cfg["club"]["nombre"]) == "Deportivo Vista" and String(cfg["nombre_club"]) == "Deportivo Vista", "con lo elegido")
		_comprobar(String(cfg["club"]["identidad"]["kit_c1"]) == "#aa1111", "incluida la camiseta")
	p.queue_free()
	await get_tree().process_frame
