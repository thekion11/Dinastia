extends BaseIdea
## LA ETAPA «PERSONAJE» (MEGAPLAN fase 1, etapa 6) Y EL CREADOR DEL MENÚ (f1p, 25-10-2026).
## Comprueba los datos (validación, azar coherente, aplicar a la partida), la
## pantalla de la etapa (contrato, validación, confirmación, señales) y el
## creador del menú rehecho sobre las mismas piezas.
## Necesita fotogramas (el 3D y la interfaz), así que no usa `_probar()` sino
## su propio `_ready()` con esperas.

func _ready() -> void:
	await get_tree().process_frame
	_titulo("ETAPA PERSONAJE: datos")
	_datos()
	_azar()
	_aplicar()
	_titulo("ETAPA PERSONAJE: pantalla")
	await _pantalla()
	_titulo("ETAPA PERSONAJE: creador del menú")
	await _creador()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _esperar(n: int) -> void:
	for _i in n:
		await get_tree().process_frame

## El 3D se rehace un instante después del último cambio: se espera tiempo, no fotogramas.
func _esperar_s(s: float) -> void:
	await get_tree().create_timer(s).timeout
	await get_tree().process_frame

func _valido() -> Dictionary:
	var p := PersonajeDatos.nuevo("CHI")
	p["nombre"] = "Andrea"
	p["apellido"] = "Valdés Soto"
	return p

func _datos() -> void:
	var vacio := PersonajeDatos.validar(PersonajeDatos.nuevo("CHI"))
	_comprobar(vacio.has("nombre") and vacio.has("apellido"), "sin nombre ni apellido no se puede confirmar")
	_comprobar(PersonajeDatos.validar(_valido()).is_empty(), "un personaje completo valida sin errores")
	var malos := {"R2D2": "nombre", "A": "nombre", "Maximilianoooooooooooo": "nombre"}
	for nom: String in malos:
		var p := _valido()
		p["nombre"] = nom
		_comprobar(PersonajeDatos.validar(p).has("nombre"), "nombre rechazado: «%s»" % nom)
	var raro := _valido()
	raro["nombre"] = "José-María"
	raro["apellido"] = "O’Higgins"
	_comprobar(PersonajeDatos.validar(raro).is_empty(), "tildes, guiones y apóstrofos valen")
	for edad: int in [PersonajeDatos.EDAD_MIN - 1, PersonajeDatos.EDAD_MAX + 1]:
		var p := _valido()
		p["edad"] = edad
		_comprobar(PersonajeDatos.validar(p).has("edad"), "edad fuera de rango rechazada (%d)" % edad)
	var sin_pais := _valido()
	sin_pais["nacionalidad"] = "XXX"
	_comprobar(PersonajeDatos.validar(sin_pais).has("nacionalidad"), "nacionalidad que no existe rechazada")
	var sin_estilo := _valido()
	sin_estilo["estilo"] = ""
	_comprobar(PersonajeDatos.validar(sin_estilo).has("estilo"), "sin estilo no se confirma")
	var est: Variant = Datos.tabla("DT_ESTILOS")
	var mismas := est is Dictionary
	for e: Array in PersonajeDatos.ESTILOS:
		mismas = mismas and (est as Dictionary).has(String(e[0]))
	_comprobar(mismas, "los estilos son las mismas claves que DT_ESTILOS")
	var p := _valido()
	p["nombre"] = "  ana   maría "
	p["apellido"] = "rojas"
	p["aspecto"] = {"cuerpo": "female", "barba": true}
	var c := PersonajeDatos.cerrar(p)
	_comprobar(String(c["nombre_completo"]) == "Ana María Rojas", "el nombre se pule: «%s»" % c["nombre_completo"])
	_comprobar(bool(c["mujer"]) and int(c["look"]["barba"]) == 0, "una mujer no sale con barba en el retrato 2D")
	_comprobar(int(c["look"]["edad"]) == int(p["edad"]), "la edad pasa al retrato 2D (canas de CaraDT)")

func _azar() -> void:
	var rng := RandomNumberGenerator.new()
	var choques: Array[String] = []
	var canas_viejo := 0
	var canas_joven := 0
	for s in 400:
		rng.seed = 9000 + s
		var edad := 30 if s % 2 == 0 else 70
		var a := PersonajeDatos.aspecto_coherente(rng, -1, edad)
		var ropa := String(a["ropa"])
		if String(a["cuerpo"]) == "female" and (bool(a["barba"]) or int(a["cara"]) >= 0 or String(a["pelo"]) == "calvo"):
			choques.append("mujer %d" % s)
		if bool(a["corbata"]) and not ropa in PersonajeDatos.CON_CORBATA:
			choques.append("corbata con %s" % ropa)
		if bool(a["manga_corta"]) and not ropa in PersonajeDatos.CON_MANGA_CORTA:
			choques.append("manga corta con %s" % ropa)
		if bool(a["gorra"]) and ropa in ["traje", "abrigo"]:
			choques.append("gorra con %s" % ropa)
		if int(a["tatuaje"]) > 0 and not bool(a["manga_corta"]):
			choques.append("tatuaje tapado")
		var gris := String(a["color_pelo"]) in ["9a9a9a", "e8e8e4"]
		if gris:
			if edad == 70:
				canas_viejo += 1
			else:
				canas_joven += 1
	_comprobar(choques.is_empty(), "400 aspectos al azar sin choques %s" % str(choques.slice(0, 4)))
	_comprobar(canas_joven == 0 and canas_viejo > 60, "canas según la edad (30 años: %d, 70 años: %d de 200)" % [canas_joven, canas_viejo])
	var malos: Array[String] = []
	for cod: String in PersonajeDatos.paises():
		for mujer: bool in [false, true]:
			rng.seed = hash(cod) + int(mujer)
			var np := PersonajeDatos.nombre_al_azar(cod, mujer, rng)
			var p := _valido()
			p["nombre"] = np[0]
			p["apellido"] = np[1]
			p["nacionalidad"] = cod
			if not PersonajeDatos.validar(p).is_empty():
				malos.append("%s %s (%s)" % [np[0], np[1], cod])
	_comprobar(malos.is_empty(), "los nombres al azar de los %d países validan %s" % [PersonajeDatos.paises().size(), str(malos.slice(0, 3))])
	rng.seed = 5
	var todo := PersonajeDatos.al_azar("BRA", rng, 1)
	_comprobar(PersonajeDatos.validar(todo).is_empty() and String(todo["aspecto"]["cuerpo"]) == "female",
		"un personaje entero al azar (mujer, Brasil) es válido: %s %s" % [todo["nombre"], todo["apellido"]])

func _aplicar() -> void:
	var m := _mundo(4242)
	var p := _valido()
	p["edad"] = 51
	p["nacionalidad"] = "URU"
	p["estilo"] = "motivador"
	p["aspecto"] = {"cuerpo": "female", "pelo": "coleta", "gafas": "ver", "barba": true}
	PersonajeDatos.aplicar(p, m.roles, 2026)
	var r := m.roles
	_comprobar(r.nombre == "Andrea Valdés Soto", "aplicar: el nombre del DT")
	_comprobar(String((r.look["p3d"] as Dictionary)["pelo"]) == "coleta" and String(r.aspecto_3d()["cuerpo"]) == "female", "aplicar: el aspecto 3D en Roles.look[p3d]")
	_comprobar(int(r.look["barba"]) == 0 and bool(r.look["gafas"]) and int(r.look["edad"]) == 51, "aplicar: el retrato 2D sigue al 3D")
	_comprobar(Genero.mujer, "aplicar: el juego te trata de entrenadora")
	_comprobar(String(PersonajeDT.del_usuario.get("pelo", "")) == "coleta", "aplicar: la banda del partido ya te ve así")
	var copia := Roles.new(Mundo.new())
	copia.desde_dic(JSON.parse_string(JSON.stringify(r.a_dic())))
	var de := PersonajeDatos.de_roles(copia)
	_comprobar(int(de["edad"]) == 51 and String(de["nacionalidad"]) == "URU" and String(de["estilo"]) == "motivador"
		and String(de["apellido"]) == "Valdés Soto", "el perfil sobrevive a guardar y cargar la partida")
	Genero.fijar(false)

func _pantalla() -> void:
	var m := _mundo(777)
	var raiz := Control.new()
	raiz.size = Vector2(1600, 900)
	add_child(raiz)
	var pp := PantallaPersonaje.new()
	pp.configurar({"pais": "ARG", "club": m.mi_club(), "paso": 6, "nombre": "Míster"})
	raiz.add_child(pp)
	var emitido: Array = []
	var volvio := [false]
	pp.terminado.connect(func(d: Dictionary) -> void: emitido.append(d))
	pp.volver.connect(func() -> void: volvio[0] = true)
	await _esperar_s(0.4)
	_comprobar(pp.has_signal("terminado") and pp.has_signal("volver") and pp.has_method("configurar"), "contrato de etapa: terminado, volver y configurar")
	_comprobar(String(pp.personaje()["nacionalidad"]) == "ARG", "la nacionalidad sale del país elegido antes")
	_comprobar(String(pp.personaje()["nombre"]) == "", "«Míster» no se toma como tu nombre")
	var est: EstudioPersonaje = pp.get("_estudio")
	_comprobar(est != null and est.modelo().has("nodo"), "el estudio arma el personaje 3D en vivo")
	pp.call("_confirmar")
	await _esperar(2)
	_comprobar(emitido.is_empty() and pp.get("_capa_confirmar") == null, "sin datos no confirma")
	_comprobar(String(pp.get("_seccion")) == "datos" and (pp.get("_aviso") as Label).visible, "y te lleva a los datos con el aviso en rojo")
	var hojas: HojasPersonaje = pp.get("_hojas")
	hojas.cambiar("cuerpo", "female", true)
	await _esperar_s(0.6)
	_comprobar(String(est.modelo().get("cuerpo", "")) == "female", "cambiar el cuerpo rehace el 3D")
	pp.call("_poner_datos", {"nombre": "lucía", "apellido": "ferreyra", "edad": 39})
	pp.call("_confirmar")
	await _esperar(2)
	var capa: Control = pp.get("_capa_confirmar")
	_comprobar(capa != null and emitido.is_empty(), "con todo bien, primero pide confirmación")
	var acepto: Button = capa.find_child("Aceptar", true, false) if capa != null else null
	_comprobar(acepto != null and ("esa soy yo" in acepto.text.to_lower() or Idiomas.idioma != "es"), "la confirmación habla en femenino a una entrenadora")
	if acepto != null:
		acepto.pressed.emit()
	await _esperar(2)
	_comprobar(emitido.size() == 1, "al confirmar emite terminado una vez")
	if emitido.size() == 1:
		var d: Dictionary = emitido[0]
		var per: Dictionary = d.get("personaje", {})
		_comprobar(String(per.get("nombre_completo", "")) == "Lucía Ferreyra" and int(per.get("edad", 0)) == 39
			and bool(per.get("mujer", false)) and per.get("aspecto") is Dictionary and per.get("look") is Dictionary,
			"terminado({personaje}) trae lo necesario para aplicarlo")
		_comprobar(PersonajeDatos.validar(per).is_empty(), "lo emitido valida")
		var p2 := PantallaPersonaje.new()
		p2.configurar({"personaje": per})
		raiz.add_child(p2)
		await _esperar(3)
		_comprobar(String(p2.personaje()["nombre_completo"]) == "Lucía Ferreyra" and String(p2.personaje()["aspecto"]["cuerpo"]) == "female",
			"al volver a la etapa se recupera lo elegido")
		p2.queue_free()
	(pp.get("_b_atras") as Button).pressed.emit()
	_comprobar(volvio[0], "«Atrás» emite volver")
	raiz.queue_free()
	await _esperar(2)

func _creador() -> void:
	var m := _mundo(778)
	var menu := Control.new()
	menu.size = Vector2(1600, 900)
	add_child(menu)
	var c := CreadorPersonaje.abrir(menu, m)
	var cerrado := [false]
	c.cerrado.connect(func() -> void: cerrado[0] = true)
	await _esperar(15)
	var hojas: HojasPersonaje = c.get("_pestanas")
	_comprobar(hojas != null and hojas.get_tab_count() == 5, "el creador tiene sus 5 hojas (con Conjuntos)")
	## Arrastrar un deslizador = muchos cambios seguidos: un solo Deshacer.
	var alto := float(hojas.asp["altura"])
	for v: float in [1.80, 1.82, 1.84, 1.86]:
		hojas.cambiar("altura", v)
	hojas.deshacer()
	_comprobar(is_equal_approx(float(hojas.asp["altura"]), alto), "un arrastre de deslizador se deshace de una vez")
	hojas.current_tab = 1
	hojas.cambiar("ropa", "polo", true)
	_comprobar(hojas.current_tab == 1, "al cambiar una opción la hoja abierta no salta")
	c.call("_cancelar")
	await _esperar(1)
	_comprobar(not cerrado[0], "Cancelar con cambios pide un segundo toque")
	hojas.cambiar("gafas", "sol", true)
	c.call("_guardar")
	await _esperar(2)
	_comprobar(cerrado[0] and String(m.roles.look["p3d"]["gafas"]) == "sol" and bool(m.roles.look["gafas"]), "Guardar deja el aspecto 3D y el retrato 2D")
	_comprobar(menu.visible, "al cerrar vuelve el menú")
	menu.queue_free()
