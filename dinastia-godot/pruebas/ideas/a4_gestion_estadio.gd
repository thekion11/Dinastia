extends BaseIdea
## MEGA AUDITORÍA 4 (4-11-2026), repaso 5 CRUZADO: ESTADIO Y CLUB al límite (obras, ampliaciones, aforo, precios de entrada, socios).
##   1. Obras (`Instalaciones`): todas las obras hasta el nivel máximo con caja enorme, 0, en rojo; reputación 0/100/−5/1000; dos obras a la vez: nivel ≤ máximo, coste ≥ 0 o −1, caja entera, mantenimiento e ingresos del mes ≥ 0.
##   2. Estadio propio: reformas con campos/valores inválidos, `niveles` 0/−3/99, sin caja, todos los presets; aforo efectivo con 0, −5 y 10⁹.
##   3. Taquilla y partidos: precio de entrada 0/−3/10⁶, socios 0/−5/10⁶, aforo 0/−5/10⁹: estimar_taquilla finita y ≥ 0 y la gente ≤ aforo; 20 semanas de mundo con esos valores sin romper la caja (finita).

func _probar() -> void:
	_titulo("A4 CRUZADO (gestión): estadio y club al límite")
	_obras()
	_estadio()
	await _taquilla()

func _club(saldo: int, rep: int) -> Club:
	var c := Club.new()
	c.id = "x"
	c.nombre = "Club X"
	c.saldo = saldo
	c.rep = rep
	c.socios = 5000
	return c

func _obras() -> void:
	var mal: Array[String] = []
	for rep in [0, 40, 100, -5, 1000]:
		for saldo in [2000000000, 0, -5000000]:
			var o := Instalaciones.new()
			var c := _club(saldo, rep)
			var arrancadas := 0
			for vuelta in 60:
				for clave: String in Instalaciones.CATALOGO.keys():
					var coste := o.coste(clave, rep)
					if coste < -1:
						mal.append("coste %d de %s con rep %d" % [coste, clave, rep])
					var antes := c.saldo
					var r := o.iniciar(clave, c)
					if r == "":
						arrancadas += 1
						if c.saldo != antes - coste:
							mal.append("cobro de %s: %d → %d, coste %d" % [clave, antes, c.saldo, coste])
					elif c.saldo != antes:
						mal.append("«%s» se rechazó pero la caja cambió (%s)" % [clave, r])
				o.avanzar_semana(c)
				o.mantenimiento_del_mes(rep)
				for ing: Dictionary in o.ingresos_del_mes(c):
					if int(ing["monto"]) < 0:
						mal.append("ingreso negativo %s" % str(ing))
			for clave: String in Instalaciones.CATALOGO.keys():
				if o.nivel(clave) > o.maximo(clave):
					mal.append("%s nivel %d > máx %d" % [clave, o.nivel(clave), o.maximo(clave)])
			if o.mantenimiento_del_mes(rep) < 0:
				mal.append("mantenimiento negativo")
			if saldo <= 0 and arrancadas > 0:
				mal.append("obras sin caja (rep %d, saldo %d): %d arrancadas" % [rep, saldo, arrancadas])
	_comprobar(mal.is_empty(), "obras al límite (5 reputaciones × 3 cajas × 60 semanas): niveles, cobros y rechazos coherentes (%d fallos%s)" % [mal.size(), "" if mal.is_empty() else ": " + str(mal.slice(0, 3))])
	var o2 := Instalaciones.new()
	var c2 := _club(2000000000, 100)
	_comprobar(o2.iniciar("trib", c2) == "" and o2.iniciar("trib", c2) != "", "dos obras en la misma instalación a la vez: la segunda se rechaza")
	_comprobar(o2.iniciar("no_existe", c2) != "" and o2.coste("no_existe", 50) == -1, "obra inexistente: se rechaza")

func _estadio() -> void:
	var m := Mundo.new()
	var paises: Array[String] = ["CHI"]
	m.generar(paises, 66)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var yo := m.mi_club()
	var est: EstadioPropio = m.estadio
	var obras: Instalaciones = m.obras
	for aforo in [0, -5, 1000000000, 20000]:
		yo.estadio_aforo = aforo
		var ae := est.aforo_efectivo(yo)
		var niv := est.niveles_maximos(yo, obras)
		_comprobar(niv >= 1 and niv <= EstadioPropio.NIVELES_MAX and ae is int, "aforo %d: bandejas máximas %d (1-%d), aforo efectivo %d" % [aforo, niv, EstadioPropio.NIVELES_MAX, ae])
	yo.estadio_aforo = 20000
	yo.saldo = 500000000
	var r_malo := est.reformar(yo, {"campo_que_no_existe": 3})
	_comprobar(r_malo != "", "reforma con un campo inexistente: se rechaza (%s)" % r_malo)
	_comprobar(est.reformar(yo, {}) != "", "reforma vacía: se rechaza")
	for n in [0, -3, 99, 2]:
		yo.saldo = 500000000
		var r := est.reformar(yo, {"niveles": n}, obras)
		var v := int(est.ajustes.get("niveles", 1))
		_comprobar(v >= 1 and v <= EstadioPropio.NIVELES_MAX, "reforma con niveles=%d: queda en %d (1-%d) (%s)" % [n, v, EstadioPropio.NIVELES_MAX, r if r != "" else "ok"])
	yo.saldo = 0
	var antes := yo.saldo
	var r_pobre := est.reformar(yo, {"niveles": 3}, obras)
	_comprobar(yo.saldo == antes and (r_pobre != "" or est.presupuesto(yo, {"niveles": 3}, obras) <= 0), "reforma sin caja: se rechaza o no cuesta nada, y la caja no baja (%s)" % r_pobre)
	var mal := 0
	for p: Variant in est.presets():
		var clave := String((p as Dictionary).get("clave", p)) if p is Dictionary else String(p[0])
		yo.saldo = 2000000000
		est.aplicar_preset(yo, clave, obras)
		for dias in 40:
			est.avanzar_semana()
		if yo.saldo > 2000000000 or yo.saldo < -2000000000:
			mal += 1
	_comprobar(mal == 0, "todos los presets se aplican con caja de sobra y las obras terminan (%d malos)" % mal)

func _taquilla() -> void:
	var rotas: Array[String] = []
	for caso in [[6.0, 0], [0.0, 5000], [-3.0, 5000], [1000000.0, 5000], [6.0, 1000000], [6.0, -5], [0.0, 0]]:
		for aforo in [0, -5, 1000000000, 20000]:
			Partido.limpiar_contexto()
			var m := Mundo.new()
			var paises: Array[String] = ["CHI"]
			m.generar(paises, 91)
			m.tomar_el_mando(m.ligas[0].clubes[0].id)
			var yo := m.mi_club()
			yo.precio_entrada = float(caso[0])
			yo.socios = int(caso[1])
			yo.estadio_aforo = aforo
			var t := m.estimar_taquilla(yo)
			var g := int(t["gente"])
			var monto := int(t["monto"])
			if g < 0:
				rotas.append("gente %d (precio %s, socios %d, aforo %d)" % [g, str(caso[0]), int(caso[1]), aforo])
			if aforo > 0 and aforo < 100000 and g > aforo * 2:
				rotas.append("gente %d muy por encima del aforo %d" % [g, aforo])
			if not is_finite(float(monto)):
				rotas.append("monto no finito")
			for i in 8:
				m.avanzar_semana()
			if not is_finite(float(yo.saldo)) or absi(yo.saldo) > 9000000000000000:
				rotas.append("caja desbordada %d (precio %s, socios %d, aforo %d)" % [yo.saldo, str(caso[0]), int(caso[1]), aforo])
			if yo.socios < mini(0, int(caso[1])):
				rotas.append("socios negativos %d (caso %s)" % [yo.socios, str(caso)])
		await get_tree().process_frame
	_comprobar(rotas.is_empty(), "taquilla con precios 0/−3/10⁶, socios 0/−5/10⁶ y aforos 0/−5/10⁹ (28 combinaciones × 8 semanas): %d fallos%s" % [rotas.size(), "" if rotas.is_empty() else ": " + str(rotas.slice(0, 5))])
