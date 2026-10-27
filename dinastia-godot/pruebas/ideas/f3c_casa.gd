extends BaseIdea
## FASE 3, BLOQUE 4 «CASA Y FAMILIA» (26-10-2026): la casa del DT por dentro (`CasaDT`):
## la vivienda de los interiores + dormitorio, la familia con cuerpo, los puntos de uso
## (cama, mesa, sofá, personas) y sus efectos en reloj, necesidades y vida.

func _probar() -> void:
	_titulo("F3C: LA CASA DEL DT POR DENTRO")
	var m := _mundo(777)
	m.reloj.sincronizar(m.anio, m.semana)
	if m.vida.perfil.is_empty():
		m.vida.crear_perfil(m.mi_club().id)
	## Un perfil con todo, para que la prueba vea pareja, hijos y mascota.
	m.vida.perfil = {"pareja": "Carolina", "hijos": [{"nombre": "Martina", "edad": 6}, {"nombre": "Agustín", "edad": 14}], "mascota": "Toby"}
	var raiz := Node3D.new()
	add_child(raiz)
	var casa := CasaDT.new()
	var origen := Vector3(10, -400, 20)
	casa.montar(raiz, m, origen)
	_comprobar(casa.interior != null, "la sala existe (vivienda de los interiores)")
	var t := casa.interior.tam_sala() if casa.interior != null else Vector3.ZERO
	_comprobar(t.x > 0 and t.y > 0 and t.z > 0, "la sala tiene tamaño (%s)" % str(t))
	_comprobar(casa.interior != null and casa.interior._fijos.is_empty() and casa.interior._caminantes.is_empty(), "sin desconocidos: ni cocinero ni paseante de serie")
	_comprobar(casa.get_node_or_null("Pieza_bedDouble") != null, "hay cama de matrimonio (catálogo Modulos)")
	## La familia.
	_comprobar(casa.cuerpos.size() == 3, "tantos cuerpos como pareja + hijos (%d)" % casa.cuerpos.size())
	var alturas_ok := true
	for c: Dictionary in casa.cuerpos:
		var n: Node3D = c["nodo"]
		var et: Label3D = null
		for h in n.get_children():
			if h is Label3D:
				et = h
		if et == null or et.text != String(c["nombre"]):
			alturas_ok = false
		if String(c["clave"]) == "hijo" and (et == null or et.position.y > 1.75):
			alturas_ok = false
	_comprobar(alturas_ok, "cada cuerpo lleva su nombre; los hijos son más bajos")
	_comprobar(casa.get_node_or_null("Mascota") != null, "la mascota tiene cuerpo")
	## Puntos de uso.
	var pts := casa.puntos()
	var claves: Array = []
	for p: Dictionary in pts:
		claves.append(String(p["clave"]))
	_comprobar(claves.has("cama") and claves.has("mesa") and claves.has("sofa"), "puntos: cama, mesa y sofá")
	_comprobar(claves.has("pareja") and claves.count("hijo") == 2, "puntos: la pareja y los dos hijos")
	var p_cama := {}
	for p: Dictionary in pts:
		if String(p["clave"]) == "cama":
			p_cama = p
	_comprobar((p_cama["pos"] as Vector3).distance_to(origen) > 1.0 and absf((p_cama["pos"] as Vector3).y - origen.y) < 0.01, "los puntos están en coordenadas del mundo")
	_comprobar(casa.cercano(p_cama["pos"]).get("clave", "") == "cama", "cercano: encima de la cama la encuentra")
	_comprobar(casa.cercano((p_cama["pos"] as Vector3) + Vector3(0.9, 0, 0.9)).get("clave", "") == "cama", "cercano: a 1,3 m también")
	_comprobar(casa.cercano((p_cama["pos"] as Vector3) + Vector3(-5, 0, 0)).is_empty(), "cercano: a 5 m (hacia la pared, lejos de todos), nada")
	## Dormir: hasta las 08:00 y sube la energía.
	m.reloj.avanzar_minutos(600, "trabajo")
	var e0 := m.necesidades.energia()
	var h0 := m.necesidades.hambre()
	var dia0 := m.reloj.dia
	var r := casa.usar("cama")
	_comprobar(m.reloj.hora() == 8 and m.reloj.minutos_de_la_hora() == 0 and m.reloj.dia == dia0 + 1, "dormir deja el reloj a las 08:00 del día siguiente (%s)" % m.reloj.texto_hora())
	_comprobar(m.necesidades.energia() > e0, "dormir sube la energía (%d → %d)" % [e0, m.necesidades.energia()])
	_comprobar(r.get("actividad", "") == "dormir" and int(r.get("minutos", 0)) > 0 and String(r.get("titulo", "")) != "", "usar(cama) devuelve título, minutos y actividad")
	## Comer: baja el hambre.
	_comprobar(m.necesidades.hambre() > 0, "tras dormir hay algo de hambre (%d)" % m.necesidades.hambre())
	h0 = m.necesidades.hambre()
	r = casa.usar("mesa")
	_comprobar(m.necesidades.hambre() < h0, "comer baja el hambre (%d → %d)" % [h0, m.necesidades.hambre()])
	_comprobar(int(r.get("minutos", 0)) == 30, "comer son 30 minutos")
	## Sofá: baja el estrés (tope 0).
	m.vida.estres = 35
	r = casa.usar("sofa")
	_comprobar(m.vida.estres == 33 and int(r.get("minutos", 0)) == 90, "el sofá baja el estrés 2 en 90 minutos")
	m.vida.estres = 1
	casa.usar("sofa")
	_comprobar(m.vida.estres == 0, "el estrés no baja de 0")
	## Hablar: +1 de familia solo una vez al día; frase por tramo.
	m.vida.familia = 50
	r = casa.usar("pareja")
	_comprobar(m.vida.familia == 51 and String(r.get("texto", "")).begins_with("Carolina: «"), "hablar con la pareja: +1 de familia y frase con su nombre")
	casa.usar("hijo", "Martina")
	casa.usar("pareja")
	_comprobar(m.vida.familia == 51, "el mismo día no vuelve a sumar")
	m.reloj.avanzar_minutos(1440, "libre")
	casa.usar("hijo", "Agustín")
	_comprobar(m.vida.familia == 52, "al día siguiente vuelve a sumar una vez")
	m.vida.familia = 90
	var fc := String(casa.usar("pareja")["texto"])
	m.vida.familia = 10
	var fd := String(casa.usar("pareja")["texto"])
	_comprobar(CasaDT.FRASES["contenta"].has(fc.get_slice("«", 1).trim_suffix("»")) and CasaDT.FRASES["dolida"].has(fd.get_slice("«", 1).trim_suffix("»")), "frases distintas: contenta y dolida")
	m.vida.familia = 100
	m.reloj.avanzar_minutos(1440, "libre")
	casa.usar("pareja")
	_comprobar(m.vida.familia == 100, "familia con tope 100")
	_comprobar(casa.usar("nada").is_empty(), "clave desconocida: nada")
	## Traducción de todos los textos.
	var es: Array = []
	for p: Dictionary in pts:
		es.append(String(p["texto"]))
	var antes := Idiomas.idioma
	Idiomas.idioma = "en"
	var en: Array = []
	for p: Dictionary in casa.puntos():
		en.append(String(p["texto"]))
	var r_en := casa.usar("mesa")
	Idiomas.idioma = antes
	var todos := true
	for i in es.size():
		if es[i] == en[i]:
			todos = false
			_linea("  sin traducir: %s" % es[i])
	_comprobar(todos and es.size() == en.size(), "todos los textos de puntos() cambian en inglés")
	_comprobar(String(r_en["titulo"]) == "Eat" and not String(r_en["texto"]).contains("Comes"), "usar() devuelve textos traducidos")
	casa.queue_free()
