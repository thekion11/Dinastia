extends "res://ui/principal_p6.gd"
## (Parte 7 de 18 de `principal.gd`.)

## Mismo motivo y mismo arreglo que `_ver_estadio_propio()`: `VistaCiudad`
## tampoco trae fondo opaco -para que el 3D se vea de verdad-, así que hay
## que esconder el resto de la pantalla mientras está abierta.
## El ídolo del club para la estatua de la ciudad: la última leyenda retirada
## del club; si no hay, el capitán; si no, el de más media.
func _idolo_del_club(c: Club) -> String:
	if mundo.cantera != null:
		for k in range(mundo.cantera.leyendas.size() - 1, -1, -1):
			var L: Dictionary = mundo.cantera.leyendas[k]
			if String(L.get("club_id", "")) == c.id:
				return String(L.get("nombre", ""))
	var mejor: Jugador = null
	for j: Jugador in c.plantilla:
		if j.capitan:
			return j.nombre
		if mejor == null or j.ovr > mejor.ovr:
			mejor = j
	return mejor.nombre if mejor != null else ""

func _ir_a_pestana(titulo: String) -> void:
	for i in _pestanas.get_tab_count():
		if _pestanas.get_tab_title(i) == titulo:
			_pestanas.current_tab = i
			return

func _ver_ciudad_propia() -> void:
	_fundido_entrada()
	var c := mundo.mi_club()
	if c == null or mundo.obras == null:
		return
	var ocultados: Array = []
	for h in get_children():
		if h is CanvasItem and (h as CanvasItem).visible:
			(h as CanvasItem).visible = false
			ocultados.append(h)
	var vista := VistaCiudad.new()
	add_child(vista)
	vista.construir = _ui_club_vida._empezar_obra
	var prox := mundo.proximo_partido()
	vista.dia_partido = not prox.is_empty() and prox[0] == c
	vista.animo = CiudadAnimo.de(mundo, c)
	vista.idolo = _idolo_del_club(c)
	vista.abrir(c, mundo.obras, mundo.ciudad, mundo.perfil_estadio_de(c))
	vista.cerrado.connect(func() -> void:
		vista.queue_free()
		for h in ocultados:
			if is_instance_valid(h):
				(h as CanvasItem).visible = true
		(self as Principal)._refrescar())
	## Clic en el estadio, o el botón "Editar mi estadio": mismo cierre que
	## "Volver" -devuelve la pestaña de Club, que quedaba oculta- y además
	## salta directo a Estadio con el diseñador ya pintado, en vez de dejar al
	## jugador en la pestaña en la que estaba antes de entrar a la ciudad.
	vista.editar_estadio_pedido.connect(func() -> void:
		vista.queue_free()
		for h in ocultados:
			if is_instance_valid(h):
				(h as CanvasItem).visible = true
		_ir_a_pestana("Estadio")
		_pintar_estadio(c))

func _ver_ciudad_con_carga() -> void:
	PantallaCarga.club = mundo.mi_club() if mundo != null else null
	var carga := PantallaCarga.mostrar(self, Idiomas.t("Construyendo la ciudad…"))
	await get_tree().process_frame
	await get_tree().process_frame
	_ver_ciudad_propia()
	## Si algo la cerró mientras se esperaba (otra pantalla encima, o el
	## recorrido de pantallas), llamarla aquí tumbaba el juego (señal 11).
	if is_instance_valid(carga):
		carga.cerrar()

## `vCiudad()`: EL CLUB Y SU BARRIO.
##
## Es la parte del juego que ocurre fuera del campo y de la caja. Todo lo demás
## escala con ganar partidos; esto no: los negocios anexos ingresan TODAS las
## semanas del año, jueguen o no, y tienen un freno que no es dinero —el permiso
## municipal y la relación con los vecinos—, así que no basta con tener caja.
func _pintar_ciudad(c: Club) -> void:
	var ci := mundo.ciudad
	if ci == null:
		return
	_limpiar(_lista_ciudad)
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("🏙️ EL CLUB Y SU CIUDAD")
	_lista_ciudad.add_child(t)
	## EL VISOR 3D DE LA CIUDAD DEPORTIVA, por fin alcanzable desde el juego
	## (12-9-2026): `CityBuilder` llevaba desde el 2-09-2026 viviendo solo en
	## el proyecto viejo, nunca portado. Mismo patrón que el botón de estadio.
	var ver3d := Button.new()
	ver3d.text = Idiomas.t("🏙️ Ver la ciudad en 3D")
	ver3d.add_theme_font_size_override("font_size", 11)
	ver3d.pressed.connect(_ver_ciudad_con_carga)
	_lista_ciudad.add_child(ver3d)
	_ui_ciudad._pintar_luces_ciudad(ci)

	var n_neg := 0
	for k: String in ci.negocios:
		if bool(ci.negocios[k]):
			n_neg += 1
	_dato("Negocios abiertos", "%d de %d" % [n_neg, Ciudad.lista_negocios().size()],
		COL_TEXTO, _lista_ciudad)
	_dato("Ingreso semanal", _dinero(ci.renta_negocios(c, mundo.prensa.animo if mundo.prensa else 60)),
		COL_VERDE, _lista_ciudad)
	_dato("Relación con los vecinos", "%d de 100" % ci.vecinos,
		COL_ROJO if ci.vecinos < 35 else (COL_VERDE if ci.vecinos > 70 else COL_ORO), _lista_ciudad)
	_dato("Estado del césped", "%d de 100" % ci.cesped,
		COL_ROJO if ci.cesped < Ciudad.CESPED_MINIMO_CONCIERTO else COL_VERDE, _lista_ciudad)
	if not ci.sancion.is_empty():
		var av := _texto(12, COL_ROJO)
		av.text = Idiomas.t("🚫 Próximo partido a puertas cerradas.") if String(ci.sancion["tipo"]) == "cerradas" \
			else "🚧 Aforo reducido al 40%% durante %d semana(s)." % int(ci.sancion["semanas"])
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista_ciudad.add_child(av)
	if not ci.permiso.is_empty():
		_dato("Permiso en trámite", "resolución en %d semana(s)  ·  %d%% estimado" % [
			int(ci.permiso["semanas"]), int(round(float(ci.permiso["prob"]) * 100.0))],
			COL_ORO, _lista_ciudad)

	_ui_ciudad._pintar_terrenos(ci, c)
	_ui_ciudad._pintar_negocios(ci, c)
	_ui_ciudad._pintar_conciertos(ci, c)
	_ui_ciudad._pintar_municipalidad(ci, c)
	_ui_ciudad._pintar_sostenibilidad(ci, c)
	_ui_ciudad._pintar_seguridad(ci, c)

func _celda(g: GridContainer, texto: String, color: Color, derecha: bool = false, tam: int = 12) -> Label:
	var l := _texto(tam, color)
	l.text = texto
	if derecha:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(l)
	return l

## Cuatro pantallas del HTML en una sola pestaña, porque son la misma pregunta
## hecha a distinta profundidad -"¿qué hay ahí fuera?"-: `vLigas()` (la tabla de
## cualquier liga del mundo), `vClubes()` (el directorio de clubes),
## `vFichaClub()` (el plantel de uno concreto) y `vGoleadores()` (los artilleros
## de esa liga). Hasta hoy solo se veía TU liga y ningún plantel ajeno.
##
## No hace falta ni un dato nuevo: todo sale de `mundo.ligas` y de las
## plantillas que ya existen.
func _pintar_clubes() -> void:
	_limpiar(_lista_clubes)
	if _clubes_pais == "":
		_clubes_pais = mundo.mi_club().pais
	_ui_plantel._pintar_rivalidades()

	var paises: Array[String] = []
	for l in mundo.ligas:
		if not paises.has(l.pais):
			paises.append(l.pais)
	paises.sort()
	var t := _texto(11, COL_SUAVE)
	t.text = Idiomas.t("LIGAS DEL MUNDO")
	_lista_clubes.add_child(t)
	## Los países no caben en una fila: se reparten en filas de ocho.
	var fila_pais: HBoxContainer = null
	for i in paises.size():
		if i % 8 == 0:
			fila_pais = HBoxContainer.new()
			fila_pais.add_theme_constant_override("separation", 4)
			_lista_clubes.add_child(fila_pais)
		var pais := paises[i]
		var bp := Button.new()
		bp.text = pais
		bp.toggle_mode = true
		bp.button_pressed = pais == _clubes_pais
		bp.add_theme_font_size_override("font_size", 11)
		bp.pressed.connect(func() -> void:
			_clubes_pais = pais
			_clubes_ficha = null
			_pintar_clubes())
		fila_pais.add_child(bp)
	_lista_clubes.add_child(HSeparator.new())

	for l in mundo.ligas:
		if l.pais != _clubes_pais:
			continue
		var tl := _texto(12, COL_ORO)
		tl.text = l.nombre
		_lista_clubes.add_child(tl)
		var g := GridContainer.new()
		g.columns = 7
		g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_theme_constant_override("h_separation", 10)
		_lista_clubes.add_child(g)
		for enc in ["#", "CLUB", "PJ", "G", "E", "P", "PTS"]:
			_celda(g, enc, COL_SUAVE, enc != "CLUB" and enc != "#", 11)
		var puesto := 1
		for fila: Dictionary in l.tabla():
			var club: Club = fila["club"]
			_celda(g, str(puesto), COL_SUAVE, false, 11)
			## El nombre es un botón: pulsarlo abre su plantel abajo. Eso es
			## `vFichaClub()`, que en el HTML es una pantalla aparte.
			var b := Button.new()
			b.text = club.nombre
			b.flat = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 12)
			b.add_theme_color_override("font_color", _color_de_paleta(COL_ACENTO if club == mundo.mi_club() else COL_TEXTO))
			b.pressed.connect(func() -> void:
				_clubes_ficha = null if _clubes_ficha == club else club
				_pintar_clubes())
			g.add_child(b)
			for clave in ["pj", "g", "e", "p", "pts"]:
				var txt := str(int(fila.get(clave, 0)))
				## Los puntos quitados por sanción, a la vista (−3 en rojo).
				if clave == "pts" and int(fila.get("sancion", 0)) > 0:
					txt += " (−%d)" % int(fila["sancion"])
				_celda(g, txt, COL_TEXTO if clave == "pts" else COL_SUAVE, true, 11)
			puesto += 1
		_lista_clubes.add_child(HSeparator.new())

	if _clubes_ficha != null:
		_ui_plantel._pintar_ficha_club(_clubes_ficha)
	_ui_plantel._pintar_goleadores(_clubes_pais)

## La barra de cinco -un botón por grupo, con el mismo icono que `#tabs` del
## HTML-. Se toca una sola vez; el submenú de abajo cambia solo.
## CUÁNTO HAY SIN RESOLVER EN CADA BLOQUE. Todo sale de datos que el motor ya
## lleva -no hay contador nuevo que mantener-, y por eso no puede
## desincronizarse: si el correo tiene tres sin leer, es porque `_bandeja`
## tiene tres sin leer.
func _pendientes_de_grupo(gid: String) -> int:
	if mundo == null:
		return 0
	var n := 0
	match gid:
		"central":
			for m: Dictionary in _bandeja:
				if not bool(m.get("leido", false)):
					n += 1
		"gente":
			if mundo.cantera != null and mundo.cantera.hay_exigencia():
				n += 1
		"operaciones":
			if mundo.prensa != null and mundo.prensa.hay_rueda():
				n += 1
			if mundo.mercado != null:
				n += mundo.mercado.ofertas_recibidas.size()
	return n

## Repinta SOLO los rótulos de los seis bloques, para que el punto de aviso
## aparezca y desaparezca al avanzar la semana. Se hace aparte de
## `_reconstruir_grupos()` porque eso reconstruye botones enteros y esto
## corre en cada repintado: cambiar seis textos es gratis, recrear seis
## botones con sus estilos no.
func _actualizar_badges() -> void:
	if _fila_grupos == null:
		return
	for i in mini(_fila_grupos.get_child_count(), GRUPOS.size()):
		var b := _fila_grupos.get_child(i) as Button
		if b == null:
			continue
		var g: Dictionary = GRUPOS[i]
		var rotulo := String(g["icono"]) if _estilo_menu == "compacto" \
			else "%s  %s" % [String(g["icono"]), String(g["nombre"])]
		if _pendientes_de_grupo(String(g["id"])) > 0:
			rotulo += "  ●"
		b.text = rotulo

## Guarda el estado ANTES de hacer algo. `motivo` es lo que se le enseña al
## jugador cuando lo deshaga.
func _apuntar_deshacer(motivo: String) -> void:
	if mundo == null:
		return
	_pila_deshacer.append({"motivo": motivo, "estado": Partida.instantanea(mundo)})
	while _pila_deshacer.size() > DESHACER_MAX:
		_pila_deshacer.pop_front()


func _reconvertir(j: Jugador, pe: String) -> void:
	var posd: Dictionary = (Datos.tabla("POSD") as Dictionary).get(pe, {})
	var r := j.reconvertir(pe)
	if r.is_empty():
		return
	_apuntar_deshacer("reconvertir a %s de %s" % [j.nombre, pe])
	var d := int(r["despues"]) - int(r["antes"])
	_escribir("[color=#c9a227]🔁 Reconversión:[/color] %s pasa a jugar de %s. Su media queda en %d (%s%d). Necesita %d semana(s) para asentarse en el puesto." % [
		j.nombre, String(posd.get("n", pe)).to_lower(), r["despues"], "+" if d >= 0 else "", d, int(r["semanas"])])
	(self as Principal)._refrescar()
	(self as Principal)._ver_ficha(j)

func _listar_transferible(j: Jugador) -> void:
	mundo.mercado.listar_transferible(j)
	_escribir("[color=#c9a227]En venta:[/color] %s queda listado como transferible. Se lo tomó mal, pero a partir de ahora van a llegar ofertas por él." % j.nombre)
	(self as Principal)._refrescar()

## Doble toque: la primera pulsación solo arma la confirmación y repinta el
## botón con la advertencia -"vista.confResc" del HTML-. La segunda, con el
## mismo jugador todavía armado, ejecuta de verdad.
func _rescindir(j: Jugador, total: int) -> void:
	if _confirmar_rescision_id != j.id:
		_confirmar_rescision_id = j.id
		(self as Principal)._ver_ficha(j)
		return
	_confirmar_rescision_id = ""
	var mio := mundo.mi_club()
	if mio == null or total > mio.saldo:
		return
	_apuntar_deshacer("rescindir a %s" % j.nombre)
	## Y queda apuntado que fue tuyo: si lo ficha un rival, el dia que se crucen
	## juega con la cuenta pendiente encima.
	Partido.marcar_ex(j, mio.id)
	## El golpe de moral a la plantilla, con más peso si era capitán -HTML añade
	## también "ídolo" (`j.idolo>=62`), que Godot no tiene portado todavía; el
	## capitanazgo solo es una aproximación honesta, no el mismo cálculo-. Se
	## mide ANTES de soltarlo: una vez fuera del club ya no es capitán de nadie.
	var pesado := j.capitan
	mio.mover_saldo(-total)
	mio.soltar(j)
	j.club_id = ""
	j.transferible = false
	j.capitan = false
	var golpe := Azar.ent(7, 13) if pesado else Azar.ent(1, 4)
	var clan: Dictionary = mundo.vestuario.clan_de(j) if mundo.vestuario != null else {}
	var miembros: Array = clan.get("miembros", [])
	for x in mio.plantilla:
		var cerca: bool = miembros.has(x.id)
		x.moral = clampi(x.moral - golpe * (2 if cerca else 1), 10, 99)
	if not clan.is_empty():
		clan["humor"] = clampi(int(clan.get("humor", 0)) - Azar.ent(10, 25), -100, 100)
	## El agente no olvida quién le rompió un contrato: la misma confianza que
	## `Cantera` ya consulta al ofertar por cualquiera de sus representados.
	if mundo.cantera != null:
		var nombre_agente := String(mundo.cantera.agente_de(j).get("nombre", ""))
		if nombre_agente != "":
			mundo.cantera.confianza_agentes[nombre_agente] = mundo.cantera.confianza_de(nombre_agente) - 2
	if mundo.prensa != null:
		mundo.prensa.animo = clampi(mundo.prensa.animo - (Azar.ent(8, 16) if pesado else Azar.ent(1, 4)), 0, 100)
		if pesado:
			mundo.prensa.funa = clampi(mundo.prensa.funa + Azar.ent(10, 20), 0, 100)
	_escribir("[color=#e05555][b]Rescindido:[/b][/color] %s deja el club. Finiquito y comisión: %s." % [j.nombre, _dinero(total)])
	_seleccionado = null
	(self as Principal)._refrescar()

## "" si se puede fichar/ceder a `j`, o el motivo exacto por el que no -el rol
## primero (ver `Roles.motivo_bloqueo`), y si el rol deja, los desafíos
## activos: "cantera" lo cierra del todo, "local" solo si `j` es extranjero.
## Un solo sitio para las tres puertas -ficha, clausulazo, ceder- que antes
## repetían la misma condición cada una a su manera.
func _motivo_fichaje_bloqueado(j: Jugador) -> String:
	## LA VENTANA DE MERCADO, la primera puerta de todas. Va aqui porque este es
	## el unico punto por el que pasan la ficha, el clausulazo y las cesiones: si
	## se comprobara en cada pantalla, tarde o temprano una se quedaria sin
	## comprobar y se ficharia en marzo.
	## EL EXPEDIENTE DE FAIR PLAY cierra el mercado de PAGO, no el mercado
	## entero: se puede seguir fichando libres, que es exactamente lo que hace un
	## club sancionado de verdad.
	if mundo.federacion != null and not mundo.federacion.puede_pagar_traspaso() and j != null and j.club_id != "":
		return "Sancionado por fair play financiero: esta ventana solo puedes fichar agentes libres."
	## EN MORA CON EL BANCO. `Banco.estado()` ya prometía "Fichajes inhibidos"
	## a partir de la cuarta semana en rojo, y nada lo hacía cumplir: se podía
	## fichar con normalidad con un veedor concursal encima. Misma frontera
	## que el fair play de arriba -bloquea el mercado de PAGO, no los libres-.
	if mundo.banco != null and mundo.banco.en_mora() and j != null and j.club_id != "":
		return "En mora con el banco (%d semanas en rojo): esta ventana solo puedes fichar agentes libres." % mundo.banco.semanas_en_rojo
	if not mundo.mercado_abierto():
		return "Mercado cerrado. Vuelve a abrir en %d semanas: hasta entonces, la plantilla es la que hay." % mundo.semanas_hasta_mercado()
	if mundo.roles != null and not mundo.roles.puede_fichar():
		return String(mundo.roles.motivo_bloqueo("fichar"))
	if mundo.tiene_desafio("cantera"):
		return "Desafío «solo canteranos»: el mercado te queda vetado. Todo refuerzo tiene que salir de tu academia."
	if mundo.tiene_desafio("local") and j != null and j.pais != mundo.mi_club().pais:
		return "Desafío «un solo país»: no puedes fichar extranjeros."
	return ""

## El intento de fichaje pasa por las tres puertas en orden y cuenta cuál se
## cerró. Decir solo "no se pudo" sería inútil: lo que hace que la siguiente
## oferta sea mejor es saber si falló el precio, la ficha o las ganas.
func _intentar_fichar(j: Jugador, monto: int, sueldo: int) -> void:
	var mio := mundo.mi_club()
	if monto > mio.saldo:
		_escribir("[color=#e05555]No hay caja: piden %s y tienes %s.[/color]" % [_dinero(monto), _dinero(mio.saldo)])
		return
	if not mundo.mercado.club_acepta(j, monto):
		_escribir("[color=#e05555]%s rechaza los %s por %s.[/color]" % [
			mundo.clubes[j.club_id].nombre, _dinero(monto), j.nombre])
		return
	if not mundo.mercado.jugador_firma(j, mio, sueldo):
		_escribir("[color=#c9a227]%s no firma: el club aceptó, pero él no se ve aquí.[/color]" % j.nombre)
		return
	mundo.mercado.fichar(j, mio, monto, sueldo, 3)
	Sonido.toca("fichaje")
	_escribir("[color=#4caf6d]FICHADO: %s por %s (%s/semana).[/color]" % [
		j.nombre, _dinero(monto), _dinero(sueldo)])
	(self as Principal)._refrescar()


func _pedir_informe_medico(j: Jugador) -> void:
	var mio := mundo.mi_club()
	var problema := mundo.medico.informe(j, mio, mundo.anio)
	if problema != "":
		_escribir("[color=#e05555]No se pudo pedir el informe: %s.[/color]" % problema)
		return
	(self as Principal)._refrescar()
	(self as Principal)._ver_ficha(j)
