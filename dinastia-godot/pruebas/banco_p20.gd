extends "res://pruebas/banco_p20_p1.gd"
## [Capa 22/27 de `banco.gd`] _probar_tanda_c_2, _probar_tanda_c

## Tramo 2 de 2 de `_probar_tanda_c` (la norma de 450 líneas la troceó).
func _probar_tanda_c_2(m: Mundo, c, o, mf: Mundo, cj, yo, cj3):
	_comprobar(cj3.caps == cj.caps and cj3.pj_carrera == 1 and cj3.goles_carrera == 1, "la selección y los totales se guardan")
	cj.club(mf).soltar(yo)
	## EL RETIRO Y EL PASO A ENTRENADOR, en un mundo aparte (cambia el mando).
	var mr := Mundo.new()
	mr.generar(["CHI"], 4242)
	var cjr := CarreraJugador.crear(mr, "Prueba Veterano", "MC", false, 7)
	mr.carrera_jugador = cjr
	var vet := cjr.jugador(mr)
	vet.edad = 34
	cjr.fama = 60
	cjr.retiro_anunciado = true
	_comprobar(cjr.toca_retirarse(mr), "si anunciaste el retiro, toca colgar las botas")
	var ofs := cjr.ofertas_de_banquillo(mr)
	_comprobar(not ofs.is_empty() and ofs.size() <= 3, "al retirarte te ofrecen banquillos (%d)" % ofs.size())
	if not ofs.is_empty():
		_comprobar(cjr.pasar_a_entrenador(mr, ofs[0]) and mr.mi_club_id == (ofs[0] as Club).id and cjr.retirado,
			"te retiras y diriges a %s en el mismo mundo" % (ofs[0] as Club).nombre)
		_comprobar(mr.roles.nombre == "Prueba Veterano" and mr.roles.rol == Roles.DT, "el entrenador eres tú, con tu nombre de jugador")
	## LAS BUTACAS DE LOS RIVALES, de los colores de su club (no el verde del visor).
	var riv_b: Club = mf.ligas[0].clubes[1]
	## Las del club, salvo que su estadio real tenga colores propios (`asientos`).
	var tab_est: Variant = Datos.tabla("ESTADIO_CLUB")
	var propios: bool = tab_est is Dictionary and (tab_est as Dictionary).has(riv_b.nombre) and ((tab_est as Dictionary)[riv_b.nombre] as Dictionary).has("asientos")
	_comprobar(propios or String(riv_b.perfil_estadio().get("asiento1", "")) == riv_b.color1, "las butacas de un rival llevan los colores de su club (o los de su estadio real)")
	if propios:
		_comprobar(String(riv_b.perfil_estadio().get("asiento1", "")) == String(((tab_est as Dictionary)[riv_b.nombre] as Dictionary)["asientos"][0]), "el estadio con colores propios los aplica")
	## LOS OBJETIVOS EN EL BORDE: directiva, confianza, próximo partido y misiones del mentor.
	PanelObjetivos.ruta = "user://objetivos_banco.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PanelObjetivos.ruta))
	var objs := PanelObjetivos.lista(mf, "dt")
	var mis_obj: Array = objs.filter(func(o: Dictionary) -> bool: return bool(o.get("mentor", false)))
	_comprobar(objs.size() >= 4 and String(objs[0]["icono"]) == "🏆" and not bool(objs[0]["hecho"]), "los objetivos: la meta de la directiva, sin cumplir antes de jugar (%d)" % objs.size())
	_comprobar(mis_obj.size() >= 3 and mis_obj.all(func(o: Dictionary) -> bool: return not bool(o["hecho"])), "las misiones del mentor salen en el panel, pendientes")
	PanelObjetivos.marcar_mision("dt", String(mis_obj[0]["texto"]))
	_comprobar(bool(PanelObjetivos.lista(mf, "dt").filter(func(o: Dictionary) -> bool: return String(o["texto"]) == String(mis_obj[0]["texto"]))[0]["hecho"]), "una misión cumplida queda tachada y se guarda")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PanelObjetivos.ruta))
	## LA PRESENTACIÓN EN EL ESTADIO: tres planos por tiempo; cerrar avisa una vez.
	var cin := CinematicaFichaje.new()
	_comprobar(cin.plano(1.0) == 1 and cin.plano(5.0) == 2 and cin.plano(9.0) == 3, "la cinemática del fichaje tiene tres planos")
	var avisos_cin := [0]
	cin.terminada.connect(func() -> void: avisos_cin[0] += 1)
	cin.cerrar()
	cin.cerrar()
	_comprobar(avisos_cin[0] == 1, "saltar la cinemática avisa una sola vez")
	## META (bloque 50): cromos, museo global, mundo heredado.
	var sobres_antes := int(Meta.leer()["sobres"])
	mf.roles.sumar_trofeo("Copa de Prueba")
	var dm := Meta.leer()
	_comprobar(int(dm["sobres"]) == sobres_antes + 1 and String((dm["museo"] as Array)[0]["titulo"]) == "Copa de Prueba", "un título va al museo global y da un sobre")
	var rng_m := RandomNumberGenerator.new()
	rng_m.seed = 5
	var salen := Meta.abrir_sobre(mf, rng_m)
	_comprobar(salen.size() == Meta.POR_SOBRE and int(Meta.leer()["sobres"]) == sobres_antes, "abrir un sobre da %d cromos y gasta el sobre" % Meta.POR_SOBRE)
	_comprobar((Meta.leer()["cromos"] as Dictionary).size() >= 1, "los cromos quedan en el álbum")
	var cm0: Club = mf.clubes.values()[0]
	var rep_real := cm0.rep
	cm0.rep = 97
	Meta.fin_de_temporada(mf)
	cm0.rep = rep_real
	_comprobar(Meta.hay_legado(), "al cerrar la temporada se guarda el mundo para heredar")
	var mh := Mundo.new()
	Meta.heredar_proximo = true
	mh.generar(["CHI"], 12)
	var cm_h: Club = null
	for c_h: Club in mh.clubes.values():
		if c_h.nombre == cm0.nombre:
			cm_h = c_h
	_comprobar(cm_h != null and cm_h.rep == 97 and not Meta.heredar_proximo, "el mundo heredado arranca con la reputación de la última partida")
	## FONDO DE INVERSIÓN: comprar, tope del 49 %, dividendos, vender, guardar.
	var fi := FondoInversion.new()
	fi.caja = 1000000000
	var otros: Array = mf.clubes.values().filter(func(x: Club) -> bool: return x.id != mf.mi_club_id)
	var obj: Club = otros[0]
	_comprobar(fi.comprar(mf, obj, 0.25) == "" and is_equal_approx(float(fi.cartera[obj.id]), 0.25), "el fondo compra un 25 %")
	fi.comprar(mf, obj, 0.4)
	_comprobar(float(fi.cartera[obj.id]) <= FondoInversion.MAX_PCT + 0.0001 and fi.comprar(mf, obj, 0.1) != "", "nunca pasa del 49 % de un club")
	_comprobar(fi.comprar(mf, mf.mi_club(), 0.1) != "", "no compra su propio club")
	mf.semana = 4
	var div := fi.semana(mf)
	_comprobar(div >= 0 and fi.dividendos_totales == div and fi.historia.size() == 1, "cada cuatro semanas reparte dividendos (%s)" % _dinero(div))
	var fi2 := FondoInversion.new()
	fi2.desde_dic(fi.a_dic())
	_comprobar(fi2.caja == fi.caja and fi2.cartera.size() == 1 and fi2.dividendos_totales == fi.dividendos_totales, "el fondo se guarda con la partida")
	var caja_antes := fi.caja
	_comprobar(fi.vender(mf, obj, 1.0) == "" and fi.cartera.is_empty() and fi.caja > caja_antes, "vender todo devuelve caja y vacía la cartera")
	## Cantera.
	var ec := m.eventos_cantera
	var hubo := false
	for sem in 60:
		ec.semana(m.academia, c, 2026, sem)
		if not ec.pendiente.is_empty():
			hubo = true
			break
	_comprobar(hubo, "la academia trae asuntos para decidir")
	if hubo:
		var r = ec.resolver("a", m.academia, c)
		_comprobar(not r.is_empty() and ec.pendiente.is_empty(), "el asunto de la academia se resuelve")
	_comprobar(ec.visitar(m.academia, 2026, 70) == "" and ec.visitar(m.academia, 2026, 70) != "", "una visita a la academia por semana")
	## Ramas.
	m.hinchada.ramas["femenino"] = true
	var res = m.hinchada.temporada_ramas(c, 2026)
	_comprobar(res.size() == 1 and int(res[0]["puesto"]) >= 1 and int(res[0]["puesto"]) <= 12, "la rama femenina termina en un puesto (%d.º)" % int(res[0]["puesto"]))
	_comprobar(int(m.hinchada.anios_rama["femenino"]) == 1, "la rama suma temporadas")
	## Ficha.
	var cuenta := {}
	for j: Jugador in m.jugadores():
		var pd := j.pierna_debil()
		cuenta[pd] = int(cuenta.get(pd, 0)) + 1
	_comprobar(cuenta.size() == 5 and int(cuenta.get(2, 0)) + int(cuenta.get(3, 0)) > int(cuenta.get(5, 0)) * 5, "pierna débil de 1 a 5, casi todos 2-3: %s" % str(cuenta))
	var j0: Jugador = c.plantilla[0]
	j0.premios.append({"anio": 2026, "premio": "Equipo ideal de la temporada"})
	_comprobar(Partida._dic_a_jugador(Partida._jugador_a_dic(j0)).premios.size() == 1, "los premios se guardan")

func _probar_tanda_c() -> void:
	var _r1 = _probar_tanda_c_1()
	var m: Mundo = _r1[0]
	var c = _r1[1]
	var o = _r1[2]
	var mf: Mundo = _r1[3]
	var cj = _r1[4]
	var yo = _r1[5]
	var cj3 = _r1[6]
	_probar_tanda_c_2(m, c, o, mf, cj, yo, cj3)
