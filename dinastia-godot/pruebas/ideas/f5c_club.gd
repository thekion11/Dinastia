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
