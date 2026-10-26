extends "res://pruebas/banco/base.gd"
## [Capa 1/2 de `estadio.gd`] _probar_pantalla_y_vallas, _probar_estadio, _probar_ola_grada, _probar_vallas_led, _probar_guinos_estadio, _probar_estadio_b6 … (+4)

## LA PANTALLA GIGANTE Y LAS VALLAS LED (23-9-2026). Lo que se comprueba aquí
## es la LÓGICA, sin abrir ventana: la parte visual la verifica
## `pruebas/captura_pantalla_gigante.gd` con capturas reales.
##
## Hay dos bugs de verdad detrás de estas comprobaciones, los dos encontrados
## esta misma tanda mirando capturas:
##   - La pantalla estaba clavada en `alto - 1.0` con 9 m de marco FIJOS, así
##     que asomaba por encima del graderío y el techo (`alto + 0.4`) le pasaba
##     por delante partiéndola en dos. En un estadio de 1 nivel además se
##     hundía bajo el césped. Por eso se comprueba contra los TRES niveles.
##   - Los nombres largos de club se salían del lienzo. Por eso la pantalla usa
##     abreviaturas de tres letras, y se comprueba que "D. Limache" da "LIM"
##     (la versión vieja habría dado "D." o un recorte a media palabra).
func _probar_pantalla_y_vallas(m: Mundo) -> void:
	_titulo("PANTALLA GIGANTE Y VALLAS LED")
	var c: Club = m.ligas[0].clubes[0]
	var ab := PantallaEstadio.abreviatura(c)
	_comprobar(ab.length() == 3 and ab == ab.to_upper(),
		"la abreviatura del club son tres letras en mayúscula (%s -> %s)" % [c.nombre, ab])
	## El caso real que reventó la primera versión de la pantalla.
	var falso := Club.new("x", "D. Limache")
	_comprobar(PantallaEstadio.abreviatura(falso) == "LIM",
		"una inicial con punto no cuenta como palabra ('D. Limache' -> %s)" % \
			PantallaEstadio.abreviatura(falso))

	## La pantalla cuelga bajo el techo y sobre el césped en los tres niveles.
	var cruces := 0
	for niveles in [1, 2, 3]:
		var perfil := c.perfil_estadio()
		perfil["niveles"] = niveles
		var alto := StadiumBuilder.altura_de(perfil, niveles * 30000)
		var alto_marco: float = clampf(alto * 0.46, 4.2, 9.0)
		var y: float = alto - 0.8 - alto_marco / 2.0
		if y + alto_marco / 2.0 > alto + 0.4 or y - alto_marco / 2.0 < 0.5:
			cruces += 1
			_linea("  nivel %d: pantalla de %.1f..%.1f m contra techo en %.1f" % [
				niveles, y - alto_marco / 2.0, y + alto_marco / 2.0, alto + 0.4])
	_comprobar(cruces == 0, "la pantalla no se cruza con el techo en 1, 2 ni 3 niveles")

	## Las vallas: cada club con su propio juego, y con su nombre dentro.
	var a: Club = m.ligas[0].clubes[0]
	var b: Club = m.ligas[0].clubes[1]
	var la: Array = StadiumBuilder._anuncios_de(a.perfil_estadio(), a)
	var lb: Array = StadiumBuilder._anuncios_de(b.perfil_estadio(), b)
	_comprobar(la.size() >= 5 and lb.size() >= 5,
		"cada estadio tiene al menos 5 anuncios distintos (%d / %d)" % [la.size(), lb.size()])
	var textos_a: Array = []
	for x: Dictionary in la:
		textos_a.append(String(x["texto"]))
	var textos_b: Array = []
	for x: Dictionary in lb:
		textos_b.append(String(x["texto"]))
	_comprobar(textos_a != textos_b, "dos clubes distintos no anuncian lo mismo")
	_comprobar(textos_a.has(a.nombre.to_upper()) and textos_b.has(b.nombre.to_upper()),
		"las vallas de cada club llevan el nombre de su club")
	_linea("  %s: %s" % [a.nombre, ", ".join(textos_a)])
	## La tinta se decide contra el fondo: sobre un panel claro no puede salir
	## texto blanco. Es lo que hacía ilegible la mitad de las 38 marcas.
	var claro: Dictionary = StadiumBuilder._anuncio("PRUEBA", Color(0.95, 0.95, 0.9))
	var oscuro: Dictionary = StadiumBuilder._anuncio("PRUEBA", Color(0.05, 0.06, 0.1))
	_comprobar(Color(claro["tinta"]).get_luminance() < 0.3 \
		and Color(oscuro["tinta"]).get_luminance() > 0.7,
		"el texto de la valla contrasta con su propio fondo")

func _probar_estadio() -> void:
	_titulo("PERFIL DE ESTADIO (lo que ve el visor 3D)")
	var m := Mundo.new()
	m.generar(["CHI"], 2026)
	var c: Club = m.ligas[0].clubes[0]
	var p := c.perfil_estadio()
	_linea("  %s: %s de %d niveles, techo %s, %d butacas" % [
		c.nombre, p["forma"], int(p["niveles"]), p["techo"], int(p["aforo"])])
	## ESTABLE, no aleatorio: el rival tiene que jugar siempre en el mismo
	## recinto. Si se sorteara, cada visita seria a un estadio distinto y el
	## mundo dejaria de parecer un mundo.
	var otra := c.perfil_estadio()
	_comprobar(p["forma"] == otra["forma"] and p["techo"] == otra["techo"],
		"el mismo club da siempre el mismo estadio")
	var m2 := Mundo.new()
	m2.generar(["CHI"], 999)
	var c2: Club = null
	for k: Club in m2.clubes.values():
		if k.nombre == c.nombre:
			c2 = k
			break
	if c2 != null:
		_comprobar(c2.perfil_estadio()["forma"] == p["forma"],
			"el estadio no depende de la semilla de la partida")
	## Y el tamano manda sobre el gusto: un club chico no puede tener tres
	## bandejas por mucha reputacion que se le ponga.
	var formas := {}
	var mal := 0
	for k: Club in m.clubes.values():
		var q := k.perfil_estadio()
		formas[q["forma"]] = true
		if k.rep < 62 and int(q["niveles"]) > 1:
			mal += 1
		if int(q["aforo"]) <= 0:
			mal += 1
	_linea("  formas distintas en el mundo: %d" % formas.size())
	_comprobar(formas.size() >= 5, "no todos los clubes tienen el mismo estadio (%d formas)" % formas.size())
	_comprobar(mal == 0, "los niveles y el aforo son coherentes con el club (%d raros)" % mal)
	_probar_pantalla_y_vallas(m)

## VALLAS LED EN MULTIMESH (20-10-2026): menos llamadas de dibujo y la misma
## animación (anuncios que cambian y el anillo del gol).
## M-036/044 (20-10): la ola y la onda escriben su reloj en el público y lo apagan.
func _probar_ola_grada() -> void:
	print("\n--- La ola y la onda de la grada ---")
	var raiz := Node3D.new()
	add_child(raiz)
	var mmi := MultiMeshInstance3D.new()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://visor/hinchada.gdshader")
	mmi.material_override = mat
	raiz.add_child(mmi)
	var otro := MultiMeshInstance3D.new()
	otro.material_override = mat
	raiz.add_child(otro)
	_comprobar(OlaGrada.materiales(raiz).size() == 1, "ola: el material compartido se cuenta una vez")
	var ola := OlaGrada.lanzar(raiz, "ola")
	_comprobar(ola != null and float(mat.get_shader_parameter("ola_edad")) == 0.0, "ola: arranca con el reloj en 0")
	ola._process(1.5)
	_comprobar(is_equal_approx(float(mat.get_shader_parameter("ola_edad")), 1.5), "ola: el reloj avanza en el material")
	ola._process(OlaGrada.DURA_OLA)
	_comprobar(float(mat.get_shader_parameter("ola_edad")) < 0.0, "ola: al terminar queda apagada (-1)")
	var onda := OlaGrada.lanzar(raiz, "onda", Vector3(0, 0, 62))
	_comprobar(onda != null and (mat.get_shader_parameter("onda_centro") as Vector3).z == 62.0, "onda: sale del fondo del gol")
	onda.free()
	_comprobar(float(mat.get_shader_parameter("onda_edad")) < 0.0, "onda: si se corta, también se apaga")
	var pro := OlaGrada.lanzar(raiz, "protesta")
	_comprobar(pro != null and float(mat.get_shader_parameter("protesta_edad")) == 0.0 and pro._dura == OlaGrada.DURA_PROTESTA, "protesta: de pie unos segundos")
	pro.free()
	OlaGrada.mirar(raiz, Vector3(3, 0, -7))
	_comprobar((mat.get_shader_parameter("balon_pos") as Vector3) == Vector3(3, 0, -7) and float(mat.get_shader_parameter("mira_balon")) == 1.0, "grada: sigue el balón con la cabeza")
	OlaGrada.piel_de_pais(raiz, "ARG")
	var s_arg := float(mat.get_shader_parameter("piel_sesgo"))
	OlaGrada.piel_de_pais(raiz, "BRA")
	_comprobar(s_arg > float(mat.get_shader_parameter("piel_sesgo")), "grada: la piel depende del país (ARG más clara que BRA)")
	_comprobar(OlaGrada.lanzar(Node3D.new(), "ola") == null, "ola: sin público no hace nada")
	raiz.free()


func _probar_vallas_led() -> void:
	_titulo("VALLAS LED EN MULTIMESH")
	var raiz := Node3D.new()
	add_child(raiz)
	var led := VallasLed.new()
	raiz.add_child(led)
	led.sembrar([{"texto": "UNO", "fondo": Color(0.9, 0.1, 0.1), "tinta": Color.WHITE},
		{"texto": "DOS", "fondo": Color(0.1, 0.1, 0.9), "tinta": Color.WHITE}])
	for i in 4:
		var caja := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.25, 1.1, 5.75) if i < 2 else Vector3(5.75, 1.1, 0.25)
		caja.mesh = bm
		caja.position = Vector3(i * 6.0, 0.55, 0)
		led.add_child(caja)
		var l := Label3D.new()
		led.add_child(l)
		led.registrar(caja, l, i)
	led._process(0.016)
	var mmis := led.find_children("Paneles*", "MultiMeshInstance3D", false, false)
	_comprobar(mmis.size() == 2, "laterales y fondos en dos MultiMesh (%d)" % mmis.size())
	var p0: Dictionary = led._paneles[0]
	_comprobar(p0.has("mm") and p0.get("caja") == null, "las cajas sueltas se quitan")
	var antes: Color = p0.get("color", Color.BLACK)
	led._process(VallasLed.SEG + 0.1)
	_comprobar(Color(p0.get("color", Color.BLACK)) != antes, "al cambiar el anuncio cambia el color del panel")
	led.evento(["GOL"], Color(1, 0.8, 0), Color(0, 0.4, 0))
	led._process(0.4)
	var c: Color = p0.get("color", Color.BLACK)
	var club := [Color(1, 0.8, 0).srgb_to_linear(), Color(0, 0.4, 0).srgb_to_linear()]
	_comprobar(c.a > 0.3 and (Color(c.r, c.g, c.b).is_equal_approx(Color(club[0].r, club[0].g, club[0].b))
		or Color(c.r, c.g, c.b).is_equal_approx(Color(club[1].r, club[1].g, club[1].b))), "en el gol el panel brilla con los colores del club (%s)" % str(c))
	raiz.queue_free()

## FASE 4, E9: el rasgo del estadio real se DIBUJA y le da un apodo genérico.
func _probar_guinos_estadio() -> void:
	_titulo("GUIÑOS DE LOS ESTADIOS REALES (FASE 4, E9)")
	_comprobar(GuinosEstadio.apodo({"rasgo": "Herradura abierta a la cordillera"}) == "El Mirador", "cordillera → «El Mirador»")
	_comprobar(GuinosEstadio.apodo({"rasgo": "La caldera: tres bandejas"}) == "La Caldera", "caldera → «La Caldera»")
	_comprobar(GuinosEstadio.apodo({"rasgo": "", "niveles": 1}) == "", "sin rasgo ni tamaño: sin apodo inventado")
	var tabla: Dictionary = Datos.tabla("ESTADIO_CLUB")
	var con_apodo := 0
	for k: String in tabla:
		if GuinosEstadio.apodo(tabla[k]) != "":
			con_apodo += 1
	_comprobar(con_apodo >= 100, "%d de %d estadios reales con apodo (≥100)" % [con_apodo, tabla.size()])
	for caso: Array in [["Herradura abierta a la cordillera", 6], ["Cuatro torres rojas en las esquinas", 4], ["Junto al río", 1], ["Estadio minero en pleno desierto", 15]]:
		var raiz := Node3D.new()
		GuinosEstadio.montar(raiz, {"rasgo": caso[0]}, 40.0, 58.0, 20.0, 18.0)
		var n := raiz.get_child(0).get_child_count() if raiz.get_child_count() > 0 else 0
		_comprobar(n >= int(caso[1]), "«%s» dibuja %d piezas (≥%d)" % [caso[0], n, caso[1]])
		raiz.free()

## B6: el estadio por secciones -fachada, colores por tribuna, luz, superficie-,
## los ocho estilos nuevos y el exterior.
func _probar_estadio_b6() -> void:
	_titulo("ESTADIO B6: FACHADA, COLORES POR SECCIÓN, LUZ, SUPERFICIE, EXTERIOR, 24 ESTILOS")
	var m := Mundo.new()
	m.generar(["CHI"], 909)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var mio := m.mi_club()
	mio.saldo = 500000000
	var e := m.estadio
	_comprobar(e.presets().size() == 24, "24 estilos (16 + 8): %d" % e.presets().size())
	var todos_validos := true
	for p: Array in EstadioPropio.PRESETS_B6:
		for k: String in (p[3] as Dictionary):
			if k == "niveles":
				continue
			if not e.ajustes.has(k) or not e.es_valido(k, p[3][k]):
				todos_validos = false
				print("    estilo %s: «%s»=%s no vale" % [p[0], k, p[3][k]])
	_comprobar(todos_validos, "cada valor de los 8 estilos nuevos existe en su catálogo")
	for k: String in EstadioPropio.DEF_B6:
		if not e.ajustes.has(k):
			_comprobar(false, "clave nueva sembrada: %s" % k)
	var viejo := EstadioPropio.new()
	viejo.desde_dic({"nombre": "", "ajustes": {"forma": "oval"}})
	_comprobar(viejo.ajustes.has("fachada") and String(viejo.ajustes["forma"]) == "oval", "un guardado viejo carga con las claves nuevas")
	_comprobar(e.opciones("fachadaCol").size() == EstadioPropio.PALETA.size() and e.opciones("fachada").size() == 5, "la interfaz ve los catálogos nuevos")
	_comprobar(e.presupuesto(mio, {"fachada": "ladrillo"}) > 0, "revestir la fachada cuesta")
	_comprobar(e.presupuesto(mio, {"fachadaCol": "#b01e2d", "techoCol": "#1b1d22"}) == 0, "pintar es gratis")
	_comprobar(e.reformar(mio, {"fachada": "vidrio"}) == "" and e.terminar_obra() and String(e.perfil(mio)["fachada"]) == "vidrio", "la reforma llega al perfil")
	_comprobar(e.reformar(mio, {"fachada": "marmol"}) != "", "una fachada inventada se rechaza")
	## Colores por tribuna.
	e.reformar(mio, {"personalizar_bandejas": true, "bandeja_norte_col1": "#e8c21a"})
	e.terminar_obra()
	var pf := e.perfil(mio)
	_comprobar(String(pf["bandejas"]["norte"]["col1"]) == "#e8c21a" and String(pf["bandejas"]["sur"]["col1"]) == "", "cada tribuna lleva sus colores")
	## Superficie: efecto real.
	_comprobar(e.factor_lesion() == 1.0 and e.factor_desgaste_cesped() == 1.0, "natural: sin cambios")
	e.reformar(mio, {"superficie": "artificial"})
	e.terminar_obra()
	_comprobar(e.factor_lesion() > 1.0 and e.factor_desgaste_cesped() == 0.0, "artificial: más lesiones, no se estropea")
	e.reformar(mio, {"superficie": "hibrido"})
	e.terminar_obra()
	_comprobar(e.factor_lesion() < 1.0, "híbrido: menos lesiones")
	m.avanzar_semana()
	_comprobar(is_equal_approx(Partido.ctx_lesion_local, e.factor_lesion()), "la semana usa la superficie de tu estadio")
	Partido.limpiar_contexto()
	_comprobar(Partido.ctx_lesion_local == 1.0, "limpiar el contexto la devuelve a 1")
	## La luz.
	var luces := {}
	for l: String in ["neutra", "calida", "fria", "club"]:
		luces[StadiumBuilder.color_luz({"luzFocos": l, "luzClub": "#b01e2d"}).to_html()] = true
	_comprobar(luces.size() == 4, "las cuatro luces se distinguen")
	## El exterior se construye (sin pantalla: solo el árbol de nodos).
	var raiz := Node3D.new()
	add_child(raiz)
	StadiumBuilder.build(raiz, e.perfil(mio), 40000, 0.8, 1, mio)
	var ext := raiz.find_child("Exterior", false, false)
	_comprobar(ext != null and ext.find_children("*", "Label3D", false, false).size() >= 2, "hay taquillas, tienda y rótulos fuera")
	raiz.queue_free()

func _probar_b6_formas_led() -> void:
	_titulo("B6: FORMAS NUEVAS DE ESTADIO Y COLORES DE LAS LED")
	var g := StadiumBuilder.geom_de_forma("dos")
	_comprobar(0 in g["abiertas"] and 1 in g["abiertas"], "«dos tribunas» deja abiertos los dos fondos")
	_comprobar(int(StadiumBuilder.geom_de_forma("principal").get("principal", -1)) == 2,
		"«tribuna de honor» agranda el lateral de los banquillos")
	var ep := EstadioPropio.new()
	var formas: Array = ep.opciones("forma").map(func(o): return o["clave"])
	_comprobar("dos" in formas and "principal" in formas, "las formas nuevas salen en el diseñador")
	ep.ajustes["forma"] = "dos"
	_comprobar(ep.ambiente() < 0, "sin fondos el estadio hace menos ruido (%d)" % ep.ambiente())
	var leds: Array = ep.opciones("ledPaleta").map(func(o): return o["clave"])
	_comprobar(leds.size() >= 7 and "arcoiris" in leds, "7 paletas de LED en el diseñador")
	var neon := StadiumBuilder._anuncios_de({"ledPaleta": "neon"}, null)
	_comprobar(neon.all(func(a): return (a["fondo"] as Color).get_luminance() < 0.1), "neón: paneles negros")
	var propia := StadiumBuilder._anuncios_de({"ledFondo": "#6b2d8f", "ledTinta": "#e8c21a"}, null)
	_comprobar(propia.all(func(a): return a["fondo"] == Color("#6b2d8f") and a["tinta"] == Color("#e8c21a")),
		"colores elegidos a mano: fondo y letra")
	var solo_fondo := StadiumBuilder._anuncios_de({"ledFondo": "#ffffff"}, null)
	_comprobar(solo_fondo.all(func(a): return (a["tinta"] as Color).get_luminance() < 0.3),
		"solo fondo blanco: la letra se oscurece sola")

func _probar_tunel_navegable() -> void:
	_titulo("TÚNEL DE VERDAD Y ESTADIO A PIE")
	var t: Array = StadiumBuilder._tramos_sin_hueco(0.0, 100.0, -3.2, 3.2)
	_comprobar(t.size() == 2 and is_equal_approx((t[0] as Vector2).y + (t[1] as Vector2).y, 93.6), "el hueco parte la bandeja en dos trozos")
	_comprobar(StadiumBuilder._tramos_sin_hueco(0.0, 10.0, 20.0, 26.0).size() == 1, "si el hueco no la toca, queda entera")
	## En las 8 formas y con túnel central y de esquina: del vestuario se llega
	## caminando al centro del campo.
	var fallos := []
	for forma: String in ["cuenco", "oval", "rect", "caldera", "herradura", "ingles", "dos", "principal"]:
		for tunel: String in ["central", "esquina"]:
			var est := {"forma": forma, "tunel": tunel}
			var ex := ExploradorEstadio.new()
			ex._datos = TunelVestuario.datos(est, 2)
			ex.zonas = ex._datos["zonas"]
			ex.cuerpo = Node3D.new()
			ex.cuerpo.position = ex._datos["inicio"]
			ex.rumbo = PI
			## Hacia el eje del túnel y luego recto al campo.
			var x0: float = ex._datos["x0"]
			for i in 400:
				var p: Vector3 = ex.cuerpo.position
				## Al eje del túnel, recto por él hasta la cancha y luego al centro.
				var objetivo := Vector3(x0 * 0.5, 0, 0.0)
				if p.z > float(ex._datos["z_out"]):
					objetivo = Vector3(x0, 0, float(ex._datos["z_out"]) - 1.0)
				elif p.z > 52.0:
					objetivo = Vector3(x0, 0, 50.0)
				var dir := (objetivo - p)
				dir.y = 0
				ex.rumbo = atan2(dir.x, dir.z)
				ex.paso(Vector2(0, 1), true, 1.0 / 10.0)
			if ex.zona_en(ex.cuerpo.position).get("nombre", "") != "Campo" or ex.cuerpo.position.z > 30.0:
				fallos.append("%s/%s z=%.1f" % [forma, tunel, ex.cuerpo.position.z])
			ex.cuerpo.free()
			ex.free()
	_comprobar(fallos.is_empty(), "del vestuario al campo a pie en las 8 formas %s" % str(fallos))
	## Fuera de las zonas no se puede pisar (la grada, por ejemplo).
	var ex2 := ExploradorEstadio.new()
	ex2.zonas = TunelVestuario.datos({"forma": "cuenco"}, 2)["zonas"]
	_comprobar(ex2.zona_en(Vector3(20, 0, 64)).is_empty(), "la grada no se pisa")
	ex2.free()
	## El estadio se construye con el pasillo y el vestuario.
	var raiz := Node3D.new()
	StadiumBuilder.build(raiz, {"forma": "cuenco", "niveles": 2}, 30000, 0.8, 7)
	var tv := raiz.get_node_or_null("TunelVestuario")
	var cuerpos := 0
	if tv != null:
		for h in tv.get_children():
			if h is StaticBody3D:
				cuerpos += 1
	_comprobar(tv != null and cuerpos >= 10, "el túnel y el vestuario tienen colisión (%d piezas)" % cuerpos)
	raiz.free()

func _probar_edificio_club() -> void:
	_titulo("ESTADIO 2.0: EL EDIFICIO DEL CLUB POR PLANTAS")
	var d := TunelVestuario.datos({"forma": "cuenco"}, 2)
	var zonas: Array = d["zonas"]
	var x0: float = d["x0"]
	var sin_asc := []
	for p in EdificioClub.plantas():
		var hay := false
		for z: Dictionary in zonas:
			if int(z.get("planta", 0)) == p and String(z["nombre"]) == "Ascensor":
				hay = true
		if not hay:
			sin_asc.append(p)
	_comprobar(sin_asc.is_empty(), "ascensor en las 5 plantas %s" % str(sin_asc))
	## Cada sala: se pisa su centro, y desde su puerta se llega al pasillo.
	var mal := []
	var z_tab: float = float(d["z_fin"]) - EdificioClub.PASILLO - 0.1
	for f: Array in EdificioClub.PLANTAS:
		for sala: Array in f[2]:
			var c := x0 + (float(sala[1]) + float(sala[2])) / 2.0
			var centro := Vector3(c, 0, (float(d["z_out"]) + z_tab) / 2.0)
			if String(TunelVestuario.zona_en(zonas, centro, int(f[0])).get("nombre", "")) != String(sala[0]):
				mal.append(String(sala[0]))
			## Del centro de la sala al pasillo, recto por la puerta.
			var z := centro.z
			var ok := true
			while z < z_tab + 0.8:
				if TunelVestuario.zona_en(zonas, Vector3(c, 0, z), int(f[0])).is_empty():
					ok = false
					break
				z += 0.2
			if not ok:
				mal.append(String(sala[0]) + " (puerta)")
	_comprobar(mal.is_empty(), "las 11 salas se pisan y se sale al pasillo %s" % str(mal))
	## Sin plantilla a mano, las taquillas no inventan nombres.
	var antes := EdificioClub.ctx
	EdificioClub.ctx = {"plantilla": [[10, "Prueba Diez"]]}
	var raiz := Node3D.new()
	TunelVestuario.montar(raiz, {"forma": "cuenco", "club_nombre": "Mi Club"}, 2, null)
	var con_nombre := false
	for n in raiz.find_children("*", "Label3D", true, false):
		if (n as Label3D).text.contains("Prueba Diez"):
			con_nombre = true
	_comprobar(con_nombre, "la taquilla lleva el dorsal y el nombre del jugador")
	_comprobar(raiz.find_child("EdificioClub", true, false) != null, "el edificio del club se construye")
	raiz.free()
	EdificioClub.ctx = antes

func _probar_personal_estadio() -> void:
	_titulo("ESTADIO 2.0: LA GENTE DEL CLUB EN SU PUESTO")
	var d := TunelVestuario.datos({"forma": "cuenco"}, 2)
	var pe := PersonalEstadio.new()
	pe.preparar(d, Color.RED, Color.WHITE)
	var mal := []
	for clave: String in PersonalEstadio.PUESTOS:
		var p: Array = PersonalEstadio.PUESTOS[clave]
		var ruta := pe._ruta(clave, int(p[0]), String(p[1]))
		if ruta.size() < 2:
			mal.append(clave + " sin ruta")
			continue
		## Cada tramo de la rutina se camina sin salir de las zonas.
		for i in range(ruta.size() - 1):
			var a: Vector3 = ruta[i]
			var b: Vector3 = ruta[i + 1]
			for k in 11:
				var q := a.lerp(b, float(k) / 10.0)
				## El portero y el hincha trabajan FUERA, en la acera de la
				## entrada: ni dentro del edificio ni dentro de la garita.
				if clave in ["portero", "hincha"]:
					var rg := EntradaClub.rect_garita(float(d["x0"]), float(d["z_fin"]))
					if q.z < float(d["z_fin"]) + 0.4 or rg.grow(0.3).has_point(Vector2(q.x, q.z)):
						mal.append("%s tramo %d" % [clave, i])
						break
				elif TunelVestuario.zona_en(d["zonas"], q, int(p[0])).is_empty():
					mal.append("%s tramo %d" % [clave, i])
					break
	_comprobar(mal.is_empty(), "las %d personas tienen puesto y rutina en su sitio %s" % [PersonalEstadio.PUESTOS.size(), str(mal)])
	_comprobar(PersonalEstadio.PUESTOS.has("portero"), "hay portero en la entrada del club")
	_comprobar(String(PersonalEstadio.PUESTOS["utilero"][1]) == "Utilería" and String(PersonalEstadio.PUESTOS["presidente"][1]) == "Despacho del presidente",
		"el utilero en la utilería y el presidente en su despacho")
	pe.free()
