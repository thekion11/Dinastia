extends "res://pruebas/banco_p19.gd"
## [Capa 21/27 de `banco.gd`] _probar_tanda_c_1

## [Capa 21/27 de `banco.gd`] _probar_tanda_c_1

## TANDA C: instalaciones a 10 niveles (tribunas a 5, rendimiento a la mitad por
## encima de 5), trabajadores con carácter y eventos, asuntos de la academia, las
## ramas compiten, pierna débil y premios en la ficha.
## Tramo 1 de 2 de `_probar_tanda_c` (la norma de 450 líneas la troceó).
func _probar_tanda_c_1() -> Array:
	_titulo("TANDA C: INSTALACIONES, TRABAJADORES, CANTERA, RAMAS, FICHA")
	var m := Mundo.new()
	m.generar(["CHI"], 5150)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var c := m.mi_club()
	c.saldo = 2000000000
	var o := m.obras
	_comprobar(o.maximo("ct") == 10 and o.maximo("trib") == 5, "10 niveles, las tribunas se quedan en 5")
	o.niveles["ct"] = 5
	var r5 := o.ritmo_de_progreso()
	o.niveles["ct"] = 10
	var r10 := o.ritmo_de_progreso()
	_comprobar(r10 > r5 and (r10 - r5) < (r5 - 1.0), "de 6 a 10 cada nivel rinde la mitad (%.2f → %.2f)" % [r5, r10])
	_comprobar(o.coste("ct", c.rep) == -1, "al nivel 10 no se puede mejorar más")
	o.niveles["trib"] = 5
	_comprobar(o.iniciar("trib", c) != "", "las tribunas no pasan de 5")
	## Trabajadores.
	var t := Trabajadores.de(c, "cocina")
	_comprobar(String(t["puesto"]) == "Chef del club" and Trabajadores.de(c, "cocina") == t, "cada instalación tiene su encargado, siempre el mismo")
	for k: String in Instalaciones.CATALOGO:
		o.niveles[k] = mini(3, o.maximo(k))
	var eventos := 0
	for sem in 104:
		eventos += m.trabajadores.semana(c, o, 2026, sem, m.prensa).size()
	_comprobar(eventos > 3 and eventos < 80, "en las instalaciones pasan cosas, pero no cada semana (%d en 2 años)" % eventos)
	## El equipo de cada instalación (26-9-2026): gente con estado, efecto y
	## asuntos con decisión.
	var tr := m.trabajadores
	_comprobar(tr.equipo(c, o, "cocina").size() == 2, "con nivel 3 la cocina tiene dos personas")
	var f_ct: float = o.factor_personal.get("ct", 1.0)
	_comprobar(f_ct >= 0.75 and f_ct <= 1.15, "el personal mueve el rendimiento de la instalación (%.2f)" % f_ct)
	tr.equipos["ct"][0]["hab"] = 99
	tr.equipos["ct"][0]["moral"] = 99
	var f_bueno := tr.factor("ct")
	tr.equipos["ct"][0]["hab"] = 30
	tr.equipos["ct"][0]["moral"] = 20
	_comprobar(f_bueno > tr.factor("ct"), "gente buena y contenta rinde más (%.2f > %.2f)" % [f_bueno, tr.factor("ct")])
	var hubo_asunto := false
	for sem2 in 400:
		tr.semana(c, o, 2030, sem2, m.prensa)
		if not tr.pendiente.is_empty():
			hubo_asunto = true
			break
	_comprobar(hubo_asunto, "el personal trae asuntos para decidir")
	if hubo_asunto:
		var res_p := tr.resolver("b", c, o, m.prensa)
		_comprobar(not res_p.is_empty() and tr.pendiente.is_empty(), "el asunto del personal se resuelve: %s" % String(res_p.get("titulo", "")))
	var tr2 := Trabajadores.new()
	tr2.desde_dic(tr.a_dic())
	_comprobar(tr2.equipos.size() == tr.equipos.size(), "el personal se guarda con la partida")
	## REPUTACIÓN (26-9-2026): niveles del club y fama por facetas.
	var rp := m.roles.reputacion
	_comprobar(rp.valor("honesto") == 50, "la fama arranca neutra")
	rp.registrar("honesto", 30, "prueba")
	_comprobar(rp.mult_compras() < 1.0, "con fama de honesto te piden menos (%.2f)" % rp.mult_compras())
	rp.registrar("mediatico", 40, "prueba")
	_comprobar(rp.mult_marcas() > 1.0 and not rp.historial.is_empty(), "la fama mediática sube las marcas y queda anotada")
	_comprobar(Reputacion.nombre_nivel(20).contains("Local") and Reputacion.nombre_nivel(95).contains("Leyenda"), "los niveles del club van de Local a Leyenda")
	_comprobar(Reputacion.tope_instalaciones(20) < Reputacion.tope_instalaciones(90), "más reputación, instalaciones más altas")
	var rep_antes := c.rep
	c.rep = 20
	o.niveles["museo"] = Reputacion.tope_instalaciones(20)
	o.obras.erase("museo")
	_comprobar(o.iniciar("museo", c).contains("reputación"), "un club local no pasa del tope de su nivel")
	c.rep = rep_antes
	var rp2 := Reputacion.new()
	rp2.desde_dic(rp.a_dic())
	_comprobar(rp2.valor("honesto") == rp.valor("honesto") and rp2.historial.size() == rp.historial.size(), "la reputación se guarda con la partida")
	## MODOS (26-9-2026): los cinco retos se montan y se juzgan; fundar con colores.
	for r: Array in Retos.LISTA:
		var mr := Mundo.new()
		mr.generar(["CHI"], 11)
		var cr := Retos.montar(mr, String(r[0]))
		_comprobar(cr != null and mr.mi_club_id == cr.id and String(mr.reto["id"]) == String(r[0]), "el reto «%s» elige y prepara su club" % String(r[2]))
		if String(r[0]) == "deuda" and cr != null:
			_comprobar(cr.saldo < 0, "el club en ruinas arranca con deuda")
			var jr := Retos.juzgar(mr, 5, false, false)
			_comprobar(not bool(jr["cumplido"]) and Retos.juzgar(mr, 5, false, false).is_empty(), "el reto se juzga una sola vez")
		if String(r[0]) == "titulo" and cr != null:
			var jt := Retos.juzgar(mr, 1, false, false)
			_comprobar(bool(jt["cumplido"]), "salir campeón cumple «Obligados a ganar»")
	var mf := Mundo.new()
	mf.generar(["CHI"], 12)
	var cf := mf.fundar_club("Club Nuevo", "CHI", "#112233", "#ddeeff", "La Cancha")
	_comprobar(cf != null and cf.color1 == "#112233" and cf.estadio_nombre == "La Cancha", "fundar un club con sus colores y su estadio")
	## TU CASA (28-9-2026): las noticias se vuelven publicaciones y la escena se
	## monta con cada vivienda (casa, auto y DT con el móvil).
	## LAS REDES (Tribuna): cuentas, noticias, publicar, responder, guardar.
	var rd := mf.redes
	_comprobar(rd != null and String(rd.cuentas["club"]["usuario"]).ends_with("_oficial") and int(rd.cuentas["club"]["seguidores"]) > 0, "el club tiene su cuenta oficial (%s)" % String(rd.cuentas["club"]["usuario"]))
	var n_antes := rd.publicaciones.size()
	rd.desde_noticia(mf, "✅ Victoria de visita", "2-1 en el clásico")
	_comprobar(rd.publicaciones.size() == n_antes + 2 and String(rd.publicaciones[1]["cuenta"]) == "club", "una victoria la publica el club y la comenta un hincha")
	var pub := rd.publicar(mf, "hinchada", ["#Hinchada", rd.tendencia])
	_comprobar(not pub.has("error") and int(pub["likes"]) > 0 and (pub["comentarios"] as Array).size() >= 3, "publicar un mensaje a la hinchada trae me gusta y comentarios (%d)" % int(pub.get("likes", 0)))
	var pend_antes := rd.pendientes()
	var resp := rd.responder(mf, int(pub["id"]), 0, "agradecer")
	_comprobar(resp != "" and rd.pendientes() == pend_antes - 1 and rd.responder(mf, int(pub["id"]), 0, "broma") == "ya le respondiste", "responder un comentario, una sola vez")
	rd.publicar(mf, "entreno", [])
	_comprobar(rd.publicar(mf, "familia", []).has("error"), "no más de %d publicaciones por semana" % Redes.MAX_PROPIAS_SEMANA)
	var gustos := int(pub["likes"])
	rd.me_gusta(int(pub["id"]))
	_comprobar(int(rd.buscar(int(pub["id"]))["likes"]) == gustos + 1, "dar me gusta suma uno")
	## Los jugadores publican y tú les comentas.
	var n_pub := rd.publicaciones.size()
	rd._publican_jugadores(mf)
	var pj: Dictionary = rd.publicaciones[0]
	_comprobar(rd.publicaciones.size() > n_pub and String(pj["cuenta"]) == "jugador" and String(pj["autor"]).begins_with("@"), "un jugador de tu plantel publica (%s)" % String(pj["autor"]))
	var jpj := mf.jugador_por_id(String(pj["jugador_id"]))
	var moral_antes := jpj.moral
	var rc := rd.comentar_jugador(mf, int(pj["id"]), "apoyo")
	_comprobar(jpj.moral > moral_antes or moral_antes == 100, "apoyarlo en redes le sube la moral (%s)" % rc)
	_comprobar(rd.comentar_jugador(mf, int(pj["id"]), "cortante") == "ya le comentaste", "a cada publicación se le comenta una vez")
	var rd2 := Redes.new()
	rd2.desde_dic(rd.a_dic())
	_comprobar(rd2.publicaciones.size() == rd.publicaciones.size() and rd2.pendientes() == rd.pendientes(), "las redes se guardan con la partida")
	## EL MÓVIL (28-9-2026): acceso a la cuenta del club, sesiones, apps.
	_comprobar(not rd.acceso_club and rd.iniciar_sesion(String(rd.cuentas["club"]["usuario"]), "x") != "", "al principio la cuenta del club no es tuya")
	for _s in Redes.SEMANAS_PARA_ACCESO:
		rd.semana(mf)
	_comprobar(rd.acceso_club and rd.clave_club != "" and mf.movil.sin_leer() >= 1, "a las %d semanas te dan la cuenta del club y la clave llega por Mensajes" % Redes.SEMANAS_PARA_ACCESO)
	rd.cerrar_sesion()
	_comprobar(rd.publicar(mf, "entreno", []).has("error"), "sin sesión no se publica")
	_comprobar(rd.iniciar_sesion(String(rd.cuentas["club"]["usuario"]), "mala") == "clave incorrecta", "con la clave mala no se entra")
	_comprobar(rd.iniciar_sesion(String(rd.cuentas["club"]["usuario"]), rd.clave_club) == "" and rd.sesion == "club", "con la clave buena se entra a la cuenta del club")
	var saldo_antes := mf.mi_club().saldo
	var pc := rd.publicar(mf, "camiseta", ["#NuevaCamiseta"])
	_comprobar(not pc.has("error") and String(pc["cuenta"]) == "club" and mf.mi_club().saldo > saldo_antes, "publicar la camiseta desde el club vende en la tienda (%s)" % _dinero(mf.mi_club().saldo - saldo_antes))
	rd.iniciar_sesion(String(rd.cuentas["dt"]["usuario"]), "")
	_comprobar(rd.sesion == "dt", "se vuelve a tu cuenta")
	mf.movil.fondo = "atardecer"
	mf.movil.funda = "c0392b"
	var mv2 := Movil.new()
	mv2.desde_dic(mf.movil.a_dic())
	_comprobar(mv2.fondo == "atardecer" and mv2.funda == "c0392b" and mv2.mensajes.size() == mf.movil.mensajes.size(), "la personalización y los mensajes del móvil se guardan")
	_comprobar(Movil.remitente_de("La directiva pierde la paciencia", "").size() == 2 and Movil.remitente_de("Gol", "").is_empty(), "las noticias de la directiva llegan como mensaje")
	_comprobar(mf.movil.textura_perfil(mf) != null, "la foto de perfil es tu retrato por defecto")
	var tel := Telefono.crear(mf, [{"titulo": "Prueba", "cuerpo": "x"}])
	for app: Array in Telefono.APPS:
		tel.abrir_app(String(app[0]))
	tel.abrir_app("inicio")
	_comprobar(tel.get("_cuerpo") != null, "el móvil abre sus %d apps" % Telefono.APPS.size())
	tel.free()
	for viv: String in VidaDT.ORDEN_VIVIENDA:
		var ce := CasaEscena3D.new()
		ce.montar(viv, "deportivo", {}, Color.RED, Color.WHITE)
		var mallas := ce.find_children("*", "MeshInstance3D", true, false).size()
		_comprobar(mallas > 20, "la escena de «%s» se monta (%d mallas)" % [viv, mallas])
		if viv == "jardin":
			var hierba := ce.find_children("*", "MultiMeshInstance3D", true, false)
			_comprobar(not hierba.is_empty() and (hierba[0] as MultiMeshInstance3D).multimesh.instance_count > 10000, "el jardín tiene césped de briznas (%d)" % ((hierba[0] as MultiMeshInstance3D).multimesh.instance_count if not hierba.is_empty() else 0))
			var farolas: Array = ce.get("_farolas")
			_comprobar(farolas.size() == 2, "hay dos farolas para el atardecer")
			ce.libre = true
			ce.acercar(100.0)
			_comprobar(is_equal_approx(float(ce.get("_dist")), 14.0), "la cámara libre no se aleja más de la cuenta")
		ce.free()
	## LOS CONTRATOS VENCEN (28-9-2026, informe externo).
	var mc := Mundo.new()
	mc.generar(["CHI"], 21)
	mc.mi_club_id = mc.ligas[0].clubes[0].id
	var jc: Jugador = mc.mi_club().plantilla[0]
	jc.anios_contrato = 1
	var jr: Jugador = mc.mi_club().plantilla[1]
	jr.anios_contrato = 3
	var libres_antes := mc.libres.size()
	mc.nueva_temporada()
	_comprobar(not mc.mi_club().plantilla.has(jc) and mc.libres.has(jc) and jc.club_id == "", "el contrato que se acaba sin renovar deja al jugador libre")
	_comprobar(mc.mi_club().plantilla.has(jr) and jr.anios_contrato == 2, "a los demás les queda un año menos")
	_comprobar(mc.libres.size() > libres_antes, "la bolsa de libres se llena con los contratos vencidos (%d)" % (mc.libres.size() - libres_antes))
	## MERCADO AVANZADO (bloques 37-38): guerra de ofertas y zonas grises.
	var ma := MercadoAvanzado.new()
	var estrella: Jugador = mf.mi_club().plantilla[0]
	estrella.ovr = 80
	var ofertante: Club = mf.ligas[0].clubes[1] if mf.ligas[0].clubes[1] != mf.mi_club() else mf.ligas[0].clubes[2]
	mf.mercado.ofertas_recibidas.append({"jugador": estrella, "club": ofertante, "monto": 1000000, "semana": 1, "clausula": false})
	for c_rico: Club in mf.clubes.values():
		c_rico.saldo = maxi(c_rico.saldo, 50000000)
	var hubo_puja := 0
	for _k in 12:
		hubo_puja += ma.guerra_de_ofertas(mf)
	var max_oferta := 0
	for o_ma: Dictionary in mf.mercado.ofertas_recibidas:
		if o_ma["jugador"] == estrella:
			max_oferta = maxi(max_oferta, int(o_ma["monto"]))
	_comprobar(hubo_puja >= 1 and hubo_puja <= MercadoAvanzado.MAX_PUJAS and max_oferta > 1000000, "guerra de ofertas: otros clubes mejoran la oferta (%d pujas, hasta %s)" % [hubo_puja, _dinero(max_oferta)])
	mf.mercado.ofertas_recibidas.clear()
	for tipo_ma: String in ["superagente", "apuestas", "transparencia"]:
		_comprobar(ma._montar(mf, tipo_ma) and not ma.pendiente.is_empty(), "zona gris «%s» se plantea" % tipo_ma)
		var res_ma := ma.resolver(mf, "a")
		_comprobar(res_ma.has("titulo") and ma.pendiente.is_empty(), "zona gris «%s» se resuelve: %s" % [tipo_ma, String(res_ma.get("titulo", ""))])
	if mf.libres.is_empty():
		mf.generar_libres()
	for l_ma: Jugador in mf.libres:
		l_ma.edad = maxi(l_ma.edad, 31)
	var conf_antes := mf.directiva.confianza
	_comprobar(ma._montar(mf, "impuesto"), "la directiva propone un fichaje")
	ma.resolver(mf, "b")
	_comprobar(mf.directiva.confianza < conf_antes, "negarte al fichaje impuesto baja la confianza (%d -> %d)" % [conf_antes, mf.directiva.confianza])
	var ma2 := MercadoAvanzado.new()
	ma._montar(mf, "transparencia")
	ma2.desde_dic(ma.a_dic())
	_comprobar(String(ma2.pendiente.get("id", "")) == "transparencia" and ma2.superagente == ma.superagente, "el mercado avanzado se guarda con la partida")
	## INSOLVENCIA (bloques 39-40): puntos, administrador, cláusula, refundación.
	var mi2 := Mundo.new()
	mi2.generar(["CHI"], 33)
	mi2.tomar_el_mando(mi2.ligas[0].clubes[3].id)
	var ci := mi2.mi_club()
	var ins := mi2.insolvencia
	var liga_i := mi2.ligas[0]
	var pts_antes := int(liga_i.tabla_puntos[ci.id]["pts"])
	for c_rico2: Club in mi2.clubes.values():
		if c_rico2 != ci:
			c_rico2.saldo = maxi(c_rico2.saldo, 90000000)
	ci.saldo = -50000000
	mi2.banco.semanas_en_rojo = Banco.SEM_MORA
	ins.semana(mi2)
	_comprobar(String(ins.pendiente.get("id", "")) == "clausula", "al entrar en mora, el DT puede activar su cláusula de salida")
	ins.resolver(mi2, "a")
	mi2.banco.semanas_en_rojo = Banco.SEM_VEEDOR
	ins.semana(mi2)
	var plantel_antes := ci.plantilla.size()
	_comprobar(int(liga_i.tabla_puntos[ci.id]["pts"]) == pts_antes - Insolvencia.PUNTOS_SANCION, "con veedor, la federación resta %d puntos" % Insolvencia.PUNTOS_SANCION)
	_comprobar(ins.tope_salarial > 0, "con veedor hay tope salarial (%s)" % _dinero(ins.tope_salarial))
	ins.tope_salarial = 1
	ins.semana(mi2)
	_comprobar(ci.plantilla.size() == plantel_antes - 1, "el administrador vende al que más cobra si se pasa del tope")
	mi2.banco.semanas_en_rojo = Banco.SEM_LIQUIDACION - 1
	ins.pendiente = {}
	ins.semana(mi2)
	_comprobar(String(ins.pendiente.get("id", "")) == "refundacion", "una semana antes de liquidar, se ofrece la refundación")
	var rep_ci := ci.rep
	ins.resolver(mi2, "a")
	_comprobar(mi2.banco.semanas_en_rojo == 0 and ci.saldo >= 0 and ci.rep < rep_ci and not mi2.banco.liquidado_ya, "refundar salva el club: deuda perdonada, caja a cero, reputación abajo")
	var ins2 := Insolvencia.new()
	ins2.desde_dic(ins.a_dic())
	_comprobar(ins2.refundado_anio == ins.refundado_anio and ins2.sancion_anio == ins.sancion_anio, "la insolvencia se guarda con la partida")
	## REGLAMENTO FINO (bloques 44-45): desempate, promoción, árbitros, corrupción.
	var mr2 := Mundo.new()
	mr2.generar(["CHI"], 44)
	mr2.tomar_el_mando(mr2.ligas[0].clubes[0].id)
	var lr := mr2.ligas[0]
	var ca: Club = lr.clubes[1]
	var cb: Club = lr.clubes[2]
	lr.tabla_puntos[ca.id]["pts"] = 30; lr.tabla_puntos[ca.id]["gf"] = 20; lr.tabla_puntos[ca.id]["gc"] = 20
	lr.tabla_puntos[cb.id]["pts"] = 30; lr.tabla_puntos[cb.id]["gf"] = 30; lr.tabla_puntos[cb.id]["gc"] = 10
	lr.h2h["%s|%s" % [ca.id, cb.id]] = 6
	lr.h2h["%s|%s" % [cb.id, ca.id]] = 0
	var pos := func(tb: Array, c0: Club) -> int:
		for i_t in tb.size():
			if tb[i_t]["club"] == c0:
				return i_t
		return -1
	var t_dif: Array = lr.tabla()
	_comprobar(pos.call(t_dif, cb) < pos.call(t_dif, ca), "sin la moción, a igualdad de puntos manda la diferencia de gol")
	Liga.desempate_directo = true
	var t_dir: Array = lr.tabla()
	_comprobar(pos.call(t_dir, ca) < pos.call(t_dir, cb), "con la moción, manda el enfrentamiento directo")
	Liga.desempate_directo = false
	var fed := mr2.federacion
	fed.anotar_arbitro("Árbitro X", "estricto", 2, 1)
	fed.anotar_arbitro("Árbitro X", "estricto", 0, 0)
	_comprobar(fed.texto_arbitro("Árbitro X") == "Con él: 2 PJ · 1G 1E 0P", "el historial por árbitro se lleva (%s)" % fed.texto_arbitro("Árbitro X"))
	var prom := mr2.jugar_promocion(lr.clubes[3], lr.clubes[4])
	_comprobar(prom["ganador"] == lr.clubes[3] or prom["ganador"] == lr.clubes[4], "la promoción se juega a ida y vuelta: %s" % String(prom["texto"]))
	fed.promocion = true
	var fed2 := Federacion.new()
	fed2.desde_dic(fed.a_dic())
	_comprobar(fed2.promocion and fed2.arbitros.has("Árbitro X"), "promoción e historial de árbitros se guardan")
	Liga.desempate_directo = false
	var mac := MercadoAvanzado.new()
	_comprobar(mac._montar(mr2, "corrupcion") and String(mac.pendiente["id"]) == "corrupcion", "aparece la corrupción federativa")
	var aliados_antes := fed.aliados
	mac.resolver(mr2, "b")
	_comprobar(fed.aliados < aliados_antes, "denunciarla te cuesta aliados en la asamblea")
	## EDITOR DE COMPETICIONES (bloque 47).
	var me := Mundo.new()
	me.generar(["CHI"], 47)
	me.tomar_el_mando(me.ligas[0].clubes[0].id)
	var ed_c := Editor.new(me)
	var l1: Liga = me.ligas[0]
	_comprobar(ed_c.renombrar_liga(l1, "Liga de Prueba") == "" and l1.nombre == "Liga de Prueba", "se renombra una liga")
	ed_c.fijar_descensos(l1, 3)
	ed_c.fijar_puntos_victoria(l1, 2)
	var d1: Dictionary = Partida._liga_a_dic(l1)
	var l1b := Partida._dic_a_liga(d1, me)
	_comprobar(l1b.plazas_descenso == 3 and l1b.puntos_victoria == 2, "descensos y puntos por victoria se guardan")
	l1.preparar()
	l1._anotar_resultado(l1.clubes[0], l1.clubes[1], 2, 0)
	_comprobar(int(l1.tabla_puntos[l1.clubes[0].id]["pts"]) == 2, "con 2 puntos por victoria, ganar da 2")
	var resumen_e := me.nueva_temporada()
	var bajan_chi := 0
	for x_b: Variant in resumen_e["bajan"]:
		if x_b is Club and (x_b as Club).pais == "CHI":
			bajan_chi += 1
	_comprobar(bajan_chi == 3, "con 3 plazas de descenso, bajan 3 (%d)" % bajan_chi)
	var sede_c: Club = me.ligas[0].clubes[0]
	ed_c.renombrar_copa("Copa Editada")
	ed_c.fijar_sede_final(sede_c)
	_comprobar(me.copa.nombre == "Copa Editada" and me.copa.sede_final_id == sede_c.id, "la copa se renombra y tiene sede fija")
	## COLORES POR SECCIÓN: cada anillo de cada tribuna, vallas y focos.
	var est_p := mf.estadio
	var claves_antes: Array = est_p.perfil(mf.mi_club()).keys()
	mf.mi_club().saldo = maxi(mf.mi_club().saldo, 100000000)
	var err_an := est_p.reformar(mf.mi_club(), {"personalizar_bandejas": true, "anillo_sur_2": "#b01e2d", "focosCol": "#1f4fa3", "vallaCol": "#1b1d22"})
	est_p.terminar_obra()
	var perf_an: Dictionary = est_p.perfil(mf.mi_club())
	_comprobar(err_an == "" and String(((perf_an["bandejas"] as Dictionary)["sur"] as Dictionary)["niveles"][1]) == "#b01e2d", "el anillo 2 de la tribuna sur tiene su color (%s)" % err_an)
	_comprobar(String(perf_an.get("focosCol", "")) == "#1f4fa3" and String(perf_an.get("vallaCol", "")) == "#1b1d22", "focos y vallas con color propio")
	var est_limpio := EstadioPropio.new()
	_comprobar(not est_limpio.perfil(mf.mi_club()).has("focosCol") and claves_antes.size() > 0, "sin elegir, el perfil no suma claves nuevas")
	## LOS BALONES (mapa de metas 19): 8 pieles, 3 dibujos de paneles de verdad.
	_comprobar(Comercial.balones().size() >= 8, "hay %d balones para elegir" % Comercial.balones().size())
	var cb_club := Comercial.color_balon("club", mf.mi_club())
	_comprobar(cb_club.size() == 3 and cb_club[0] == Color(mf.mi_club().color1) and String(cb_club[2]) == "moderno", "el balón del club lleva sus colores y su dibujo")
	var img_cl := Balon3D.textura(Color.WHITE, Color.BLACK, "clasico").get_image()
	var oscuros := 0
	for yb in range(0, img_cl.get_height(), 2):
		for xb in range(0, img_cl.get_width(), 2):
			if img_cl.get_pixel(xb, yb).get_luminance() < 0.2:
				oscuros += 1
	var frac := float(oscuros) / float(img_cl.get_width() * img_cl.get_height() / 4)
	_comprobar(frac > 0.08 and frac < 0.45, "el clásico tiene sus 12 pentágonos oscuros (%.0f %% del balón)" % (frac * 100.0))
	var t_mod := Balon3D.textura(Color.WHITE, Color.BLACK, "moderno")
	_comprobar(t_mod != Balon3D.textura(Color.WHITE, Color.BLACK, "clasico") and t_mod == Balon3D.textura(Color.WHITE, Color.BLACK, "moderno"), "cada dibujo es distinto y se guarda en caché")
	## EL CHOQUE DE CAMISETAS: la visita cambia si se parece al local.
	var cl_a: Club = mf.ligas[0].clubes[0]
	var cl_b: Club = mf.ligas[0].clubes[1]
	var c1_a := cl_a.color1
	var c2_a := cl_a.color2
	cl_b.color1 = cl_a.color1
	cl_b.color2 = cl_a.color2
	var kv := Puente3D.kit_visita(cl_a, cl_b)
	_comprobar(not Puente3D.chocan(Puente3D.kit(cl_a), kv), "si las camisetas chocan, la visita se cambia (%s vs %s)" % [String(Puente3D.kit(cl_a)["c1"]), String(kv["c1"])])
	cl_a.color1 = c1_a
	cl_a.color2 = c2_a
	## EL PASE CON LA FUERZA JUSTA: el balón raso muere 2,5 m pasado el destino.
	var v20 := MotorJugable.velocidad_para(20.0)
	_comprobar(absf(MotorJugable.distancia_rodando(v20) - 22.5) < 0.3, "un pase de 20 m sale a %.1f m/s y rueda %.1f m" % [v20, MotorJugable.distancia_rodando(v20)])
	## LA CARRERA DE JUGADOR: se crea en un club modesto y se guarda entera.
	var cj := CarreraJugador.crear(mf, "Prueba Delantero", "DC", true, 99)
	var yo := cj.jugador(mf)
	_comprobar(yo != null and yo.edad == 17 and cj.club(mf) != null, "la carrera crea un jugador de 17 años con club")
	cj.fama = 33
	cj.eventos.append({"id": "x", "titulo": "t", "texto": "", "opciones": [], "unico": false})
	var cj2 := CarreraJugador.desde_dic(cj.a_dic())
	_comprobar(cj2.jugador_id == cj.jugador_id and cj2.fama == 33 and cj2.eventos.size() == cj.eventos.size(), "la carrera se guarda y se carga")
	var ov_antes := yo.ovr
	cj.foco = "tiro"
	for _k in 30:
		cj.energia = 100
		cj.entrenar(mf)
	_comprobar(yo.ovr > ov_antes, "entrenar sube la media (%d -> %d)" % [ov_antes, yo.ovr])
	## FASE 3 DEL MEGAPLAN: eventos que salen de lo que te pasa.
	cj.pj_carrera = 1
	cj.goles_carrera = 1
	var ids_ev: Array = cj._eventos_posibles(mf, yo).map(func(e: Dictionary) -> String: return String(e["id"]))
	_comprobar(ids_ev.has("debut") and ids_ev.has("primer_gol"), "tras debutar y marcar salen los eventos de debut y primer gol")
	var edad_antes := yo.edad
	yo.edad = 33
	ids_ev = cj._eventos_posibles(mf, yo).map(func(e: Dictionary) -> String: return String(e["id"]))
	_comprobar(ids_ev.has("licencia") and ids_ev.has("retiro_%d" % mf.anio), "a los 33 te ofrecen la licencia de entrenador y pensar en el retiro")
	yo.edad = edad_antes
	## LA SELECCIÓN: con la mejor media de tu país, en fecha FIFA te convocan.
	var sem_antes := mf.semana
	var ovr_antes2 := yo.ovr
	yo.ovr = 99
	mf.semana = Selecciones.SEMANAS_FIFA[0]
	_comprobar(cj.revisar_convocatoria(mf) and String(cj.convocatoria.get("rival", "")) != "", "en fecha FIFA te convoca tu selección (vs %s)" % String(cj.convocatoria.get("rival", "")))
	var eq_sel := cj.equipos_seleccion(mf)
	_comprobar(eq_sel.size() == 2 and (eq_sel[0] as Club).plantilla.has(yo) and (eq_sel[0] as Club).plantilla.size() == 18 and (eq_sel[1] as Club).plantilla.size() == 18,
		"la selección: 18 con el jugador dentro, contra 18 rivales")
	var caps_antes := cj.caps
	cj.tras_seleccion({"goles": 1})
	_comprobar(cj.caps == caps_antes + 1 and cj.goles_sel >= 1 and cj.convocatoria.is_empty(), "el partido con la selección suma la internacionalidad y el gol")
	mf.semana = sem_antes + 1 if Selecciones.SEMANAS_FIFA.has(sem_antes) else sem_antes
	_comprobar(not cj.revisar_convocatoria(mf) or Selecciones.SEMANAS_FIFA.has(mf.semana), "fuera de fecha FIFA no hay convocatoria")
	mf.semana = sem_antes
	yo.ovr = ovr_antes2
	var cj3 := CarreraJugador.desde_dic(cj.a_dic())
	return [m, c, o, mf, cj, yo, cj3]
