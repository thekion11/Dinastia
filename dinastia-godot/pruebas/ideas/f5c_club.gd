extends BaseIdea
## f5c · CLUB AMPLIADO (fase 5), lógica: la coordinadora de cada rama pide presupuesto en la
## semana 5 y aprobarlo cuesta caja y sube la fuerza de la rama; un título de rama suma una copa
## al museo; un trofeo nuevo del primer equipo trae la cita «celebración» y publicarla sube el ánimo.

func _probar() -> void:
	_titulo("f5c: club ampliado (ramas, trofeos, celebración)")
	var m := _mundo(55)
	m.reloj.sincronizar(m.anio, m.semana)
	var c := m.mi_club()
	m.hinchada.ramas["futsal"] = true
	m.citas.semana(m, Citas.RAMA_SEMANA)
	var cr := {}
	for x: Dictionary in m.citas.pendientes():
		if x["tipo"] == "rama":
			cr = x
	_comprobar(not cr.is_empty() and String(cr["clave"]) == "futsal", "con una rama abierta, su coordinadora cita en la semana 5")
	var saldo0 := c.saldo
	var r := m.citas.resolver(m, String(cr["id"]), 0)
	var coste := int(420000 * Citas.RAMA_EXTRA)
	_comprobar(not r.is_empty() and c.saldo == saldo0 - coste and int(m.hinchada.bono_rama.get("futsal", -1)) == m.anio, "aprobar el extra cuesta el 10 %% del coste anual (%s)" % Eco.dinero(coste))
	## La fuerza de la rama sube esa temporada (mismo hash, +0,06 → mejor puesto o igual).
	## Sin el bono (otro año de hash igual no hay): se compara quitando y poniendo el bono con los mismos años.
	var anios0 := int(m.hinchada.anios_rama.get("futsal", 0))
	m.hinchada.bono_rama.erase("futsal")
	var sin: Dictionary = m.hinchada.temporada_ramas(c, m.anio)[0]
	m.hinchada.anios_rama["futsal"] = anios0
	m.hinchada.bono_rama["futsal"] = m.anio
	var con: Dictionary = m.hinchada.temporada_ramas(c, m.anio)[0]
	_comprobar(int(con["puesto"]) <= int(sin["puesto"]), "y la rama termina igual o mejor (%d vs %d sin extra)" % [int(con["puesto"]), int(sin["puesto"])])
	## Un título de rama: una copa más en el museo (lo que cuenta Principal).
	var copas0 := m.roles.trofeos.size()
	m.hinchada.palmares_ramas.push_front({"anio": m.anio, "rama": "Futsal", "clave": "futsal", "puesto": 1})
	var copas := copas0
	for rr: Dictionary in m.hinchada.palmares_ramas:
		if int(rr.get("puesto", 9)) == 1:
			copas += 1
	_comprobar(copas == copas0 + 1, "el título de la rama suma una copa al museo")
	## Un trofeo nuevo del primer equipo → cita «celebración» el lunes en el museo.
	m.citas.semana(m, 7)
	m.roles.trofeos.append({"anio": m.anio, "titulo": "Liga"})
	m.citas.semana(m, 8)
	var cc := {}
	for x: Dictionary in m.citas.pendientes():
		if x["tipo"] == "celebracion":
			cc = x
	_comprobar(not cc.is_empty() and int(cc["dia"]) == 0, "un trofeo nuevo trae la celebración del lunes en el museo")
	var animo0 := m.prensa.animo
	var pubs0 := m.redes.publicaciones.size()
	var rc := m.citas.resolver(m, String(cc["id"]), 0)
	_comprobar(not rc.is_empty() and m.prensa.animo >= mini(animo0 + 3, 100) and m.redes.publicaciones.size() == pubs0 + 1, "levantar la copa sube el ánimo (+3, y la foto suma lo suyo) y publica la foto")
	m.citas.semana(m, 9)
	var otra := false
	for x: Dictionary in m.citas.pendientes():
		if x["tipo"] == "celebracion":
			otra = true
	_comprobar(not otra, "el mismo trofeo no se celebra dos veces")
	var d := m.citas.a_dic()
	var c2 := Citas.new()
	c2.desde_dic(d)
	_comprobar(c2._trofeos_vistos == m.citas._trofeos_vistos, "lo celebrado sobrevive a guardar y cargar")
	## §2.5: la rama también pide VISIBILIDAD (un partido en el estadio) y celebra sus títulos.
	_comprobar(m.citas.opciones(m, cr).size() == 3, "la coordinadora ofrece tres respuestas: presupuesto, no o visibilidad")
	var socios0 := c.socios
	var cesped0 := m.ciudad.cesped
	var cv := cr.duplicate()
	cv["estado"] = "pendiente"
	cv["id"] = "prueba_vis"
	m.citas.lista.append(cv)
	var rv := m.citas.resolver(m, "prueba_vis", 2)
	_comprobar(not rv.is_empty() and c.socios == socios0 + CitasRamas.VISIBILIDAD_SOCIOS and m.ciudad.cesped == maxi(0, cesped0 - CitasRamas.VISIBILIDAD_CESPED)
		and int(m.hinchada.visib_rama.get("futsal", -1)) == m.anio, "visibilidad: la rama juega en el estadio (+socios, algo de fuerza, el césped se resiente)")
	var celebradas := m.citas._ramas_vistas
	m.hinchada.palmares_ramas.push_front({"anio": m.anio, "rama": "Futsal", "clave": "futsal", "puesto": 1})
	m.citas.semana(m, 10)
	var crr := {}
	for x: Dictionary in m.citas.pendientes():
		if x["tipo"] == "celebracion" and String(x["clave"]) == "rama|futsal":
			crr = x
	_comprobar(not crr.is_empty() and m.citas._ramas_vistas == celebradas + 1, "un título nuevo de la rama trae su celebración en el museo")
	var s1 := c.socios
	var rr2 := m.citas.resolver(m, String(crr["id"]), 0) if not crr.is_empty() else {}
	_comprobar(not rr2.is_empty() and c.socios == s1 + CitasRamas.CELEBRACION_SOCIOS, "levantar la copa de la rama suma socios y la foto")
	_comprobar(Citas.new().a_dic().has("ramas") and m.hinchada.a_dic().has("visib_rama"), "la visibilidad y los títulos celebrados se guardan")
	## EL MUSEO QUE CRECE (27-10): capacidad real en la planta 2 y planta 3 «Museo ampliado» por el ascensor.
	var ctx0 := EdificioClub.ctx
	var hitos: Array = []
	for k in 9:
		hitos.append({"anio": 1990 + k * 3, "titulo": "Liga"})
	EdificioClub.ctx = {"inst": {"museo": 3}, "titulos": 9, "hitos": hitos}
	_comprobar(not EdificioClub.plantas().has(3), "con el museo a nivel 3 el ascensor no llega a la planta 3")
	var sala := Node3D.new()
	SalasClub.museo(sala, Rect2(0.0, 0.0, 3.6, 6.0), 0.0, Color("#c01020"), Color("#f2f2f2"), 9, 3)
	var cuerpos := sala.find_children("*", "StaticBody3D", false, false).size()
	_comprobar(cuerpos == SalasClub.MAX_SALA, "con 9 títulos la sala de la planta 2 llena sus %d vitrinas y no más (%d)" % [SalasClub.MAX_SALA, cuerpos])
	sala.free()
	EdificioClub.ctx = {"inst": {"museo": 4}, "obras": {"museo": 2}, "titulos": 9, "hitos": hitos}
	_comprobar(MuseoAmpliado.en_obra(EdificioClub.ctx) and EdificioClub.plantas().has(3), "la obra que lleva el museo a nivel 5 ya deja la planta 3 (en obra)")
	var dt := TunelVestuario.datos({"forma": "cuenco"}, 2)
	var asc3 := false
	for z: Dictionary in dt["zonas"]:
		if int(z.get("planta", 0)) == 3 and String(z["nombre"]) == "Ascensor":
			asc3 = true
	_comprobar(asc3, "el ascensor para en la planta 3")
	var raiz := Node3D.new()
	TunelVestuario.montar(raiz, {"forma": "cuenco", "club_nombre": "Mi Club"}, 2, null)
	_comprobar(raiz.find_child("AnimMuseoAmpliado", true, false) == null, "en obra no hay copas que iluminar")
	raiz.free()
	EdificioClub.ctx = {"inst": {"museo": 5}, "titulos": 9, "hitos": hitos}
	_comprobar(MuseoAmpliado.terminada(EdificioClub.ctx) and EdificioClub.nombre_planta(3) == "Museo ampliado", "terminada la obra, la planta 3 se llama «Museo ampliado»")
	var raiz2 := Node3D.new()
	TunelVestuario.montar(raiz2, {"forma": "cuenco", "club_nombre": "Mi Club"}, 2, null)
	var anim := raiz2.find_child("AnimMuseoAmpliado", true, false) as MuseoAmpliadoAnim
	_comprobar(anim != null and anim.copas.size() == 3, "la planta 3 lleva una copa por título del séptimo en adelante (3 de 9): %d" % (anim.copas.size() if anim != null else -1))
	raiz2.free()
	EdificioClub.ctx = ctx0
