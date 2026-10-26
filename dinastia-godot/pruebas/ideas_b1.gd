extends "res://pruebas/ideas_base_b.gd"
## Ideas del dueño (lote b, b1): hinchada y prensa.

func ejecutar() -> void:
	var m := _mb(2701)
	var c := m.mi_club()
	var h: Hinchada = m.hinchada
	## Hinchada: segmentos con ánimo (736, 737).
	_comprobar(h.segmentos.size() == 5 and h.segmentos.has("barra") and h.segmentos.has("familias"), "la hinchada tiene cinco segmentos (736)")
	Azar.sembrar(11)
	h.segmentos["nuevos"] = 20
	h.segmentos["historicos"] = 20
	h.segmentos["barra"] = 50
	for i in 40:
		h.semana(90)
	_comprobar(int(h.segmentos["nuevos"]) - 20 > int(h.segmentos["historicos"]) - 20 and int(h.segmentos["barra"]) > 50,
		"con éxito los nuevos suben más que los históricos (737): %d vs %d" % [h.segmentos["nuevos"], h.segmentos["historicos"]])
	for i in 60:
		h.semana(10)
	_comprobar(int(h.segmentos["barra"]) < 40 and int(h.segmentos["nuevos"]) < 60, "con fracaso la barra se enfada (736): %d" % h.segmentos["barra"])
	## Precio de entradas: sube en partidos grandes y la hinchada protesta (739, 750).
	_comprobar(h.precio_efectivo(10, 90) == 10 and h.castigo_por_subida(10, 10) == 0, "sin precio dinámico se cobra el base")
	h.alternar_precio_dinamico()
	_comprobar(h.precio_efectivo(10, 90) > 10 and h.precio_efectivo(10, 30) < 10, "precio dinámico: sube con rival grande y baja con flojo (750)")
	_comprobar(h.castigo_por_subida(10, h.precio_efectivo(10, 90)) > 0 and h.castigo_por_subida(10, h.precio_efectivo(10, 30)) == 0, "la hinchada protesta solo cuando SUBEN el precio (739)")
	h.alternar_precio_dinamico()
	## Abonos con planes (749).
	var ab := {}
	for plan in ["popular", "general", "premium"]:
		h.fijar_abono(plan)
		var s0 := c.saldo
		var ing := h.campana_abonos(c, 70, 0)
		ab[plan] = h.abonados
		_comprobar(ing > 0 and c.saldo - s0 == ing, "la campaña de abonos «%s» ingresa %s (749)" % [plan, _dinero(ing)])
	_comprobar(int(ab["popular"]) > int(ab["premium"]), "el plan popular llena más que el premium (749)")
	## Día del hincha y peñas (752, 753).
	var socios0 := c.socios
	var d0 := h.dias_hincha
	_comprobar(h.dia_del_hincha(c, m.prensa) == "" and h.dias_hincha == d0 + 1 and c.socios > socios0, "el día del hincha suma socios (752)")
	socios0 = c.socios
	var n_penas := h.penas.size()
	var ciudad := h.fundar_pena(c)
	_comprobar(h.penas.size() == n_penas + 1 and c.socios > socios0 and h.socios_de_penas() > 0, "fundar una peña en %s suma socios (753)" % ciudad)
	## Encuesta (755).
	h.encuesta = {}
	Azar.sembrar(5)
	for i in 400:
		h.semana(60)
		if not h.encuesta.is_empty():
			break
	_comprobar(not h.encuesta.is_empty() and (h.encuesta["opciones"] as Array).size() >= 2, "sale una encuesta a la hinchada (755)")
	var mejor: int = int(h.encuesta["mejor"])
	_comprobar(bool(h.responder_encuesta(mejor)["acerto"]) and h.encuesta.is_empty(), "seguir a la mayoría acierta y cierra la encuesta (755)")
	## Ramas deportivas (765-767, 769).
	var rep0 := c.rep
	for r in ["femenino", "futsal", "adaptado"]:
		_comprobar(h.abrir_rama(r, c) == "" and h.tiene_rama(r), "se abre la rama «%s» (765-767)" % r)
	_comprobar(c.rep >= rep0 and h.coste_ramas(c) > 0, "las ramas suben la reputación y cuestan al mes (765)")
	_comprobar(h.abrir_rama("femenino", c) != "", "no se abre dos veces la misma rama")
	h.cerrar_rama("adaptado", c)
	_comprobar(not h.tiene_rama("adaptado"), "y se puede cerrar una rama")
	var rr: Reputacion = m.roles.reputacion
	var sp0 := rr.socios_por_temporada(c)
	for i in 6:
		rr.registrar("social", 12, "prueba")
	_comprobar(rr.socios_por_temporada(c) > sp0, "la reputación social sube los socios por temporada (769)")
	## Incidentes que acaban en sanción (746).
	var ci: Ciudad = m.ciudad
	_comprobar(ci.riesgo_incidente(10, 90) > ci.riesgo_incidente(90, 0), "más funa y mal ánimo, más riesgo de incidentes (746)")
	ci.sancionar("aforo")
	_comprobar(ci.factor_aforo() == 0.4, "la sanción de aforo recorta la taquilla (746)")
	ci.sancionar("cerradas")
	_comprobar(ci.factor_aforo() == 0.0, "puertas cerradas = cero taquilla (746)")
	ci.sancion = {}
	_ideas_b_prensa(m)

func _ideas_b_prensa(m: Mundo) -> void:
	var c := m.mi_club()
	var pr: Prensa = m.prensa
	## Banderazo (741): con ánimo alto, tarde o temprano hay banderazo.
	var avisos: Array[String] = []
	var f := func(t: String, _cu: String) -> void: avisos.append(t)
	pr.noticia.connect(f)
	Azar.sembrar(3)
	for i in 120:
		pr.animo = 95
		pr.semana()
	pr.noticia.disconnect(f)
	var hubo := false
	for t in avisos:
		hubo = hubo or t.begins_with("Banderazo")
	_comprobar(hubo, "con la hinchada arriba hay banderazo en la práctica (741)")
	## Rueda de prensa con opciones (771, 777).
	var j0: Jugador = c.plantilla[0]
	for j in c.plantilla:
		j.moral = 50
	var e := pr.abrir_rueda(true, false)
	_comprobar(String(e["pregunta"]) != "" and (e["opciones"] as Array).size() >= 2 and pr.hay_rueda(), "la rueda de prensa plantea pregunta y opciones (771)")
	var soc0 := c.socios
	var ib := 0
	for i in (e["opciones"] as Array).size():
		if absi(int(e["opciones"][i]["moral"])) > absi(int(e["opciones"][ib]["moral"])):
			ib = i
	var r := pr.responder(ib)
	_comprobar(r.has("moral") and r.has("confianza") and r.has("socios") and String(r["titular"]) != "", "responder devuelve su efecto en moral, confianza y socios (771, 777)")
	_comprobar(not r.is_empty() and int(r["moral"]) != 0 and j0.moral != 50, "la declaración mueve la moral del plantel (777): %d" % r["moral"])
	_comprobar(c.socios != soc0 or int(r["socios"]) == 0, "y los socios (777)")
	## Periodistas con perfil y manía (772, 773).
	_comprobar(pr.periodista_de("ibarra")[3] == "crítico" and pr.periodista_de("solis")[3] == "aliado", "los periodistas tienen línea editorial: Ibarra crítico, Solís aliado (772)")
	var criticos := 0
	for i in 40:
		pr.entrevista = {"pregunta": "Prensa: p%d" % i}
		pr._poner_periodista(false, false)
		if String(pr.entrevista["periodista"]) == "ibarra":
			criticos += 1
	_comprobar(criticos >= 8, "tras una derrota el crítico Ibarra pregunta mucho más que 1 de 5: %d/40 (773)" % criticos)
	pr.entrevista = {}
	## Titulares y portadas (775, 799).
	var tg := pr.titular_prensa(true, false, false, "a")
	var tp := pr.titular_prensa(false, false, true, "b")
	_comprobar(String(tg["tit"]) != "" and String(tp["tit"]).begins_with("CLÁSICO"), "los titulares dependen del resultado y del clásico (775)")
	var np := pr.portadas.size()
	pr.guardar_portada("Titular de prueba", "cuerpo", "bien", {"img": "dt"})
	_comprobar(pr.portadas.size() == np + 1 and String(pr.portadas[0]["t"]) == "Titular de prueba", "la portada queda archivada, la más nueva primero (799)")
	## Tertulia y narrador (780, 781, 800).
	var mesa := pr.mesa_de_debate()
	_comprobar(mesa.size() == 5 and String(mesa[0]["frase"]) != "" and String(mesa[4]["frase"]) != "", "la mesa de debate tiene cinco voces que opinan de tu gestión (780, 781)")
	pr.animo = 90
	var f_alta := String(pr.mesa_de_debate()[2]["frase"])
	pr.animo = 20
	_comprobar(String(pr.mesa_de_debate()[2]["frase"]) != f_alta, "y cambian de opinión con el ánimo (781)")
	_comprobar(pr.narrador_temporada().length() > 20, "el narrador cuenta la temporada como relato (800)")
	## Vocero (787).
	c.plantilla[1].capitan = true
	pr.vocero = {}
	_comprobar(pr.nombrar_vocero(c) != "" and not pr.vocero.is_empty(), "se nombra un vocero del club (787)")
	pr.entrevista = {}
	pr.abrir_rueda(true, false)
	var rv := pr.responder(0)
	_comprobar(not rv.is_empty(), "con vocero la rueda sigue (787)")
	pr.entrevista = {}
	pr.vocero = {}
	## Documental y cámaras (789, 790).
	pr.pendiente = {"id": "docu", "pid": j0.id, "txt": "", "opcion_a": "", "opcion_b": ""}
	var sal0 := c.saldo
	pr.resolver("a")
	_comprobar(pr.hay_camaras() and c.saldo > sal0, "aceptar el documental: ingresos y cámaras en el vestuario (789)")
	var fr: Jugador = c.plantilla[2]
	fr.rasgo = "fragil"
	fr.moral = 80
	pr.semana()
	_comprobar(fr.moral < 80, "las cámaras bajan la moral de los frágiles (790)")
	## Derechos de TV (794).
	c.rep = 90
	pr.tv_individual = false
	pr.negociar_tv(true, c)
	_comprobar(pr.factor_tv() == 1.35, "TV individual con marca fuerte: +35% (794)")
	pr.tv_individual = false
	c.rep = 10
	pr.negociar_tv(true, c)
	_comprobar(pr.factor_tv() == 0.70, "TV individual con marca débil: -30% (794)")
	pr.negociar_tv(false, c)
	_comprobar(pr.factor_tv() == 1.0, "y el bloque no toca nada (794)")
	## Horarios impuestos por la televisión (795).
	m.horario = "lunes"
	_comprobar(m.factor_publico() < 1.0 and m.factor_tv_horario() > 1.0, "lunes por la noche: menos público, más TV (795)")

