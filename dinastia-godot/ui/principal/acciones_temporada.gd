class_name AccionesTemporada
extends RefCounted
## (fase 6, paso 7 del plan §7.1: sale de `Principal`, ui/principal_p13.gd, el 27-10-2026). `p` es la pantalla principal;
## sus miembros se usan como `p.x` y `Principal` conserva puentes de una línea con los nombres de siempre.

var p: Principal

func _init(principal: Principal) -> void:
	p = principal

func _nueva_temporada() -> void:
	if p.mundo.temporada_en_curso():
		p._escribir("[color=#e05555]Todavía queda calendario por jugar.[/color]")
		return
	## EL DOCUMENTAL (fase 5): se arma ANTES del cierre, que reinicia la tabla
	## y las estadísticas; se proyecta al final del cierre.
	var guion_doc := DocumentalTemporada.guion(p.mundo)
	if p.mundo.mercado != null:
		p.mundo.mercado.fichajes_temporada.clear()
	var resumen := p.mundo.nueva_temporada()
	if not guion_doc.is_empty():
		(func() -> void: DocumentalTemporada.abrir(p, guion_doc, p._retrato)).call_deferred()
	## `mundo.nueva_temporada()` resortea los continentales por dentro
	## (`_sortear_continentales()`, instancias NUEVAS cada vez): sin esta llamada,
	## el sorteo y el aviso de campeón/ronda de Champions-Libertadores solo
	## funcionaban en la primera temporada de la partida. Ver el comentario de
	## `_conectar_sorteos()`.
	p._conectar_sorteos()
	p._seleccionado = null
	## El cierre de temporada es el momento más importante del año y tiene que
	## contarse entero: quién ganó, quién sube y quién baja. Sin esto la
	## temporada acababa y no pasaba nada.
	for c: Dictionary in resumen["campeones"]:
		var l: Liga = c["liga"]
		var club: Club = c["club"]
		if l.division() == 1 and l.pais == p.mundo.mi_club().pais:
			p._escribir("[color=#c9a227]CAMPEÓN de %s: [b]%s[/b].[/color]  Premio %s" % [
				l.nombre, club.nombre, p._dinero(Mundo.PREMIO_LIGA)])
	if not resumen["suben"].is_empty():
		p._escribir("[color=#4caf6d]Ascienden:[/color] %s" % p._nombres(resumen["suben"]))
		if (resumen["suben"] as Array).has(p.mundo.mi_club()):
			Sonido.toca("ascenso")
			Aviso.mostrar(p, "titulo", "⬆️", "¡ASCENSO!",
				"Subes de categoría. Otra liga, otros rivales y otros derechos de televisión.")
	if not resumen["bajan"].is_empty():
		p._escribir("[color=#e05555]Descienden:[/color] %s  [color=#8ea595](la televisión les pasa de 300.000 a 58.000)[/color]" % p._nombres(resumen["bajan"]))
		if (resumen["bajan"] as Array).has(p.mundo.mi_club()):
			Sonido.toca("descenso")
			Aviso.mostrar(p, "alerta", "⬇️", "DESCENSO",
				"Bajas de categoría. La televisión pasa de 300.000 a 58.000 y habrá que rehacer el plantel.")
	## El veredicto de la directiva. Es lo unico del cierre que puede acabar con
	## la partida, asi que va lo ultimo y con su propio color.
	var v: Dictionary = resumen.get("directiva", {})
	if not v.is_empty():
		if v["cumplido"]:
			p._escribir("[color=#4caf6d]Objetivo CUMPLIDO:[/color] %s. Acabaste %d.º (te pedían %d.º). Confianza %d." % [
				v["objetivo"], v["puesto"], v["meta"], v["confianza"]])
		else:
			p._escribir("[color=#e05555]Objetivo FALLADO:[/color] %s. Acabaste %d.º y te pedían %d.º. Confianza %d." % [
				v["objetivo"], v["puesto"], v["meta"], v["confianza"]])
		if v["despedido"]:
			p._escribir("[color=#e05555][b]ESTÁS DESPEDIDO.[/b][/color] Elige otro club en la lista de arriba para empezar de nuevo.")
	if resumen.get("trotamundos", false):
		p._escribir("[color=#c9a227][b]🧳 Toca hacer las maletas.[/b][/color] Dos temporadas cumplidas: el desafío trotamundos te obliga a cambiar de club. Elige tu próximo destino en la lista de arriba.")
	p._escribir("[color=#8ea595]Empieza la %d. Todos cumplen un año, algunos se retiran y sube gente de la cantera.[/color]" % p.mundo.anio)
	## LOS CONTRATOS QUE VENCEN. Es el aviso más útil de todo el cierre de
	## temporada y el que más fácil se pasa por alto: un contrato que se acaba y
	## no se renueva es un jugador que se pierde gratis. Se avisa aquí, con la
	## pretemporada por delante para hacer algo al respecto.
	var acaban: Array[Jugador] = []
	for j: Jugador in p.mundo.mi_club().plantilla:
		if j.anios_contrato <= 1:
			acaban.append(j)
	if not acaban.is_empty():
		acaban.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
		var cuerpo_c := "%s%s. Renuévalos en Contratos o los pierdes gratis." % [
			acaban[0].nombre,
			" y %d más" % (acaban.size() - 1) if acaban.size() > 1 else ""]
		Aviso.mostrar(p, "contrato", "📄", "Terminan contrato: %d" % acaban.size(), cuerpo_c, "contrato_vence")
		p._escribir("[color=#c9a227][b]📄 Terminan contrato %d jugador(es):[/b][/color] %s." % [
			acaban.size(), p._nombres_jugadores(acaban)])
		p._anotar("📄 Terminan contrato: %d" % acaban.size(), cuerpo_c)
	p._partida.autoguardar_si_toca()
	p._refrescar()
## El menú "📅 Calendario" -antes cuatro botones sueltos que ya no entraban en
## la fila-. `match` dentro de un lambda pasado como argumento le rompía el
## parser a `principal.gd` entero -"Expected expression for match pattern",
## y de ahí en cascada TODAS las demás llamadas de la pantalla fallaban con
## "Nonexistent function"-, así que el manejador vive aquí, con nombre propio.
func _al_elegir_calendario(id: int) -> void:
	match id:
		0: p._dirigir()
		1: p._avanzar_semana()
		2: p._jugar_temporada()
		3: _nueva_temporada()

# --- acciones ---------------------------------------------------------------
func _buscar_global(texto: String) -> void:
	## Se compara limpio por los dos lados: con la cubierta activa "Fernand0"
	## tiene que salir buscando "fernando" (y también buscando "fernand0").
	var q := Nombres.limpiar(texto.strip_edges()).to_lower()
	if q.length() < 2:
		return
	var mejor: Jugador = null
	var mejor_empieza := false
	for c: Club in p.mundo.clubes.values():
		for j in c.plantilla:
			var n := Nombres.limpiar(j.nombre).to_lower()
			if not n.contains(q):
				continue
			var empieza := n.begins_with(q)
			if mejor == null or (empieza and not mejor_empieza) or (empieza == mejor_empieza and j.ovr > mejor.ovr):
				mejor = j
				mejor_empieza = empieza
	if mejor != null:
		p._escribir("[color=#3fa06a]Encontrado:[/color] %s, de %s." % [
			mejor.nombre, (p.mundo.clubes.get(mejor.club_id) as Club).nombre if p.mundo.clubes.has(mejor.club_id) else "sin club"])
		p._ver_ficha(mejor)
		p._buscador.text = ""
		return
	for c2: Club in p.mundo.clubes.values():
		if Nombres.limpiar(c2.nombre).to_lower().contains(q):
			p._clubes_ficha = c2
			p._ir_a_pestana("Clubes")
			p._refrescar()
			p._buscador.text = ""
			return
	p._escribir("[color=#8ea595]No hay ningún jugador ni club que se llame así.[/color]")
## Responde a una oferta de compra RECIBIDA (otro club quiere a uno de los
## tuyos). Nombre distinto al de la negociación saliente para no colisionar
## con la firma de `_abrir_negociacion()`.
func _responder_oferta_mercado(indice: int, aceptar: bool) -> void:
	if p.mundo == null:
		return
	if indice < 0 or indice >= p.mundo.mercado.ofertas_recibidas.size():
		return
	var o: Dictionary = p.mundo.mercado.ofertas_recibidas[indice]
	var j: Jugador    = o["jugador"]
	var co: Club      = o.get("club")
	if aceptar:
		## `responder_oferta()`: `aceptar_oferta()` no existió nunca y el botón
		## del panel de mercado rompía (lo encontró el recorrido de pantallas).
		p.mundo.mercado.responder_oferta(indice, true)
		p._escribir("[color=#4caf6d]Venta cerrada:[/color] %s a %s por %s." % [
			j.nombre,
			co.nombre if co else "?",
			p._dinero(int(o["monto"]))])
	else:
		p.mundo.mercado.responder_oferta(indice, false)
		p._escribir("Oferta por %s rechazada." % j.nombre)
	p._refrescar()
