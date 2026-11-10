class_name AvanceSemana
extends RefCounted
## (fase 6, paso 7 del plan §7.1: sale de `Principal`, ui/principal_p9.gd, el 27-10-2026). `p` es la pantalla principal;
## sus miembros se usan como `p.x` y `Principal` conserva puentes de una línea con los nombres de siempre.

var p: Principal
## (9-11, orden del dueño, como PES 2020) El DÍA DE PARTIDO no se salta: si tu club juega esta semana, avanzar el calendario abre el
## MENÚ DEL PARTIDO (ahí eliges jugarlo o simularlo, a conciencia) en vez de simularlo por error. Las pruebas que recorren
## semanas a mano lo apagan.
static var partido_obliga := true
## Estado propio de esta pantalla (fase 6, paso 7: antes eran variables de `Principal`).
## Para no repetir el aviso del cierre de mercado cada vez que se repinta.
var _mercado_avisado: int = -1
var _saldo_mostrado := -1
var _dia_pintado: int = -1
var _prologo_lanzado := false; var _evento_fin_lanzado := false   ## el evento de fin de temporada ya salió en esta pantalla (se rearma al empezar otra temporada)

func _init(principal: Principal) -> void:
	p = principal

## La música según lo que pasa en la partida: las tres últimas jornadas del año, tensión («final»); si no, «menu». Antes vivía en `PantallaOpciones`, que así se compilaba al abrir el menú.
func situacion_musical() -> String:
	if p.mundo == null:
		return "menu"
	var c := p.mundo.mi_club()
	if c == null:
		return "menu"
	var liga := p._liga_de(c)
	if liga != null and liga.jornada_actual >= liga.jornadas() - 2:
		return "final"
	return "menu"

## Las opciones del desplegable «📅 Calendario» según la fecha (orden del dueño, 9-11): con la liga en curso, jugar el partido y avanzar semana; al
## terminarla, SOLO «Temporada siguiente». Al construir el menú todavía no hay mundo: se supone en curso.
static func rellenar_calendario(popup: PopupMenu, en_curso: bool) -> void:
	popup.clear()
	if en_curso:
		popup.add_item("Jugar el partido", 0)
		popup.add_item("Avanzar semana", 1)
	else:
		popup.add_item("Temporada siguiente", 3)

func actualizar_calendario() -> void:
	var mb: Variant = p._guia.nodos.get("calendario")
	if not is_instance_valid(mb) or p.mundo == null:
		return
	var pop: PopupMenu = (mb as MenuButton).get_popup()
	var en_curso := p.mundo.temporada_en_curso()
	if (pop.get_item_index(3) < 0) == en_curso and pop.item_count > 0:
		return   ## ya está como toca
	rellenar_calendario(pop, en_curso)

func _refrescar() -> void:
	var c := p.mundo.mi_club()
	## Los interruptores de accesibilidad llegan también a lo que se pinta con
	## `Tema.*` (teléfono, avisos, competición...): petición 3 de la sesión 2 y
	## el contraste alto (s3).
	Tema.daltonico = p._daltonico
	Tema.escala_texto = p._escala_texto
	Tema.contraste = p._paleta == "contraste"
	## Los objetivos, fijos en el borde derecho (PanelObjetivos).
	if not is_instance_valid(p._panel_obj):
		p._panel_obj = PanelObjetivos.crear(p, p.mundo.roles.modo_actual() if p.mundo.roles != null else "dt")
		p.add_child(p._panel_obj)
	p._panel_obj.refrescar()
	## Tu personaje 3D, a mano para la banda de cualquier estadio (la vista
	## del partido no tiene el mundo delante).
	UsuarioEn3D.aspecto = p.mundo.roles.aspecto_3d()
	UsuarioEn3D.club = c.id if c != null else ""
	## El edificio del club (estadio 2.0) también necesita saber del mundo.
	PendienteClub.fijar(p.mundo, c)   ## (se aplica al entrar al edificio: no compilarlo al abrir el menú)
	## Entrenadora: si tu personaje es mujer, toda la interfaz te trata como tal (el cuerpo por defecto es «male», como `PersonajeDT.BASE`).
	Genero.fijar(String(UsuarioEn3D.aspecto.get("cuerpo", "male")) == "female")
	var liga := p._liga_de(c)
	var acento_antes := p.COL_ACENTO
	p.COL_ACENTO = p._acento_de(c)
	## El acento sale de la identidad del club y tine tambien el tema -pestana
	## activa, boton pulsado, barras-. Al cambiar de club o de colores hay que
	## rehacerlo; comparando primero, para no reconstruir un Theme entero en cada
	## refresco cuando no ha cambiado nada.
	if acento_antes != p.COL_ACENTO:
		p._aplicar_tema()
	p._cabecera.text = c.nombre
	p._limpiar(p._escudo_cabecera)
	var e := p._escudo(c, 44)
	e.set_anchors_preset(Control.PRESET_FULL_RECT)
	p._escudo_cabecera.add_child(e)
	var dir_txt := ""
	if p.mundo.directiva != null:
		dir_txt = "  ·  " + Idiomas.t("%s  ·  confianza %d") % [Idiomas.t(p.mundo.directiva.objetivo), p.mundo.directiva.confianza]
	## La plata y la fecha ya no van en el texto corrido: viven arriba a la
	## derecha, en grande. Aquí queda lo que de verdad es contexto.
	## La caja CUENTA hasta su nuevo valor (plan maestro B11): un cobro o un
	## pago se ve moverse, y late una vez.
	if _saldo_mostrado != -1 and _saldo_mostrado != c.saldo and p._lbl_caja.is_inside_tree():
		Animar.contar(p._lbl_caja, float(_saldo_mostrado), float(c.saldo), func(v: float) -> String: return p._dinero(int(v)))
		Animar.pulso(p._lbl_caja, 1.06)
	else:
		p._lbl_caja.text = p._dinero(c.saldo)
	_saldo_mostrado = c.saldo
	p._lbl_fecha.text = Idiomas.t("%s  ·  semana %d") % [p.fecha_larga(), p.mundo.semana]
	p._sub.text = Idiomas.t("%s  ·  Jornada %d de %d  ·  Sueldos %s/sem  ·  Media %.1f%s") % [
		liga.nombre, liga.jornada_actual, liga.jornadas(),
		p._dinero(c.masa_salarial()), c.media(), dir_txt]
	## M-305: qué es cada cifra de esta línea, al pasar el ratón.
	p._sub.tooltip_text = Idiomas.t("Jornada: la de la liga. Sueldos: lo que pagas por semana a la plantilla. Media: la del once. Objetivo y confianza: lo que la directiva espera y cuánto confía en ti (en 12 o menos, te pueden despedir).")
	p._sub.mouse_filter = Control.MOUSE_FILTER_PASS
	## El desafío invicto no bloquea nada por dentro -se puede seguir jugando,
	## como en el HTML-, solo avisa UNA vez de que la racha se acabó.
	if not p.mundo.fin_partida.is_empty() and not p._fin_partida_avisado:
		p._fin_partida_avisado = true
		p._escribir("[color=#e05555][b]💀 FIN DE LA PARTIDA.[/b][/color] Cayó la primera derrota y con ella el desafío del invicto (semana %d de %d). Puedes seguir jugando, pero el desafío ya está perdido." % [
			int(p.mundo.fin_partida.get("semana", 0)), int(p.mundo.fin_partida.get("anio", 0))])
	## LA TABLA, MODULARIZADA (25-9-2026, pedido explícito del usuario: "que no
	## sea tan frágil"). Las cinco funciones que pintaban esto viven ahora en
	## `ui/componentes/tabla_competicion.gd`, como clase estática -no como
	## componente de escena, ver el porqué en su propio comentario de cabecera-.
	## Los colores van YA resueltos (paleta + modo daltónico), la lección del
	## bug de coherencia visual que se encontró y arregló en `PanelMercado`
	## esa misma sesión, aplicada desde el principio esta vez.
	##
	## ROTACIÓN DE NODOS (s3, 26-10-2026): la tabla, el plantel, el mercado y el
	## inicio se repintaban en CADA refresco aunque estuvieran ocultos (dos tercios
	## de los ~111 000 nodos que creaba una vuelta por los menús, medido con
	## `pruebas/ideas/s3_rotacion_menus.gd`). Ahora van diferidos como las demás:
	## se pintan al verse, con los datos de ese momento.
	p._titulo_tabla.text = TablaCompeticion.titulo_de(p.mundo, liga, c)
	p._perezoso(p._lista_tabla, func() -> void:
		TablaCompeticion.pintar(p._lista_tabla, p.mundo, liga, c, {
			"suave":  p._pal_suave(),
			"texto":  p._pal_texto(),
			"acento": p.COL_ACENTO,
			"verde":  p._color_accesible(p.COL_VERDE),
			"rojo":   p._color_accesible(p.COL_ROJO),
			"oro":    p._color_accesible(p.COL_ORO),
			"escala": p._escala_texto,
		}))
	p._perezoso(p._lista_plantel, p._abrir_perezosa.bind("plantel", "plantel", {"club": c}))
	## El panel de mercado se actualiza con la paleta del club activo para que
	## el color de acento refleje siempre al equipo que se dirige.
	##
	## PUNTO 3, COHERENCIA VISUAL (25-9-2026): `verde`/`rojo`/`oro` viajaban
	## SIN pasar por `_color_accesible()` -el remapeo a la paleta Okabe-Ito
	## ("modo daltónico" de Ajustes) que el resto del juego sí respeta desde
	## que se centralizó "en `_texto()` en vez de en las mil llamadas"-. Con el
	## modo activado, la interfaz entera cambiaba de verde/rojo/oro a azul
	## cielo/bermellón/ámbar MENOS la pestaña Mercado -"mercado abierto",
	## "ganas de venir", si el fichaje es pagable, seguían en los colores
	## viejos-, justo la clase de incoherencia entre un componente nuevo y el
	## resto de la interfaz que el pedido de mejora señalaba.
	if p._panel_mercado != null:
		p._perezoso(p._panel_mercado, func() -> void:
			p._panel_mercado.inicializar(p.mundo, {
				"acento": p.COL_ACENTO,
				"texto":  p._pal_texto(),
				"suave":  p._pal_suave(),
				"verde":  p._color_accesible(p.COL_VERDE),
				"rojo":   p._color_accesible(p.COL_ROJO),
				"oro":    p._color_accesible(p.COL_ORO),
			}, p._negociacion_ultimo))
	p._perezoso(p._lista_copa, p._abrir_perezosa.bind("plantel", "copa", {"club": c}))
	p._perezoso(p._lista_club, p._abrir_perezosa.bind("ficha", "club", {"club": c}))
	p._perezoso(p._lista_conti, p._abrir_perezosa.bind("club_vida", "conti", {"club": c}))
	p._perezoso(p._lista_medico, p._abrir_perezosa.bind("club_vida", "medico", {"club": c}))
	p._perezoso(p._lista_logros, p._abrir_perezosa.bind("club_vida", "logros"))
	p._perezoso(p._lista_entren, p._abrir_perezosa.bind("club_vida", "entrenamiento", {"club": c}))
	p._perezoso(p._lista_fed, p._pintar_federacion.bind(c))
	p._perezoso(p._lista_estadio, p._ui_club_estadio.abrir.bind("estadio", {"club": c}))
	p._perezoso(p._lista_seleccion, p._abrir_perezosa.bind("cantera", "seleccion", {"club": c}))
	p._perezoso(p._lista_cantera, p._abrir_perezosa.bind("cantera", "cantera", {"club": c}))
	p._perezoso(p._lista_contratos, p._abrir_perezosa.bind("cantera", "contratos", {"club": c}))
	p._perezoso(p._lista_comparar, p._abrir_perezosa.bind("cantera", "comparar"))
	p._perezoso(p._lista_records, p._abrir_perezosa.bind("legado", "records"))
	p._perezoso(p._lista_legado, p._abrir_perezosa.bind("legado", "legado"))
	p._perezoso(p._lista_inicio, p._abrir_perezosa.bind("legado", "inicio", {"club": c}))
	## Las otras tres viven DENTRO de `_pintar_gente()` ahora -un chip por
	## sección, solo se pinta la que está activa- en vez de apilarse las
	## cuatro siempre, aunque solo una se vea.
	p._perezoso(p._lista_gente, p._abrir_perezosa.bind("gente", "gente"))
	p._perezoso(p._lista_finanzas, p._abrir_perezosa.bind("finanzas", "finanzas", {"club": c}))
	p._perezoso(p._lista_camarin, p._abrir_perezosa.bind("finanzas", "camarin", {"club": c}))
	p._perezoso(p._lista_ciudad, p._ui_ciudad.abrir.bind("ciudad", {"club": c}))
	p._perezoso(p._lista_editor, p._abrir_perezosa.bind("editor", "editor"))
	p._perezoso(p._lista_glosario, p._abrir_perezosa.bind("opciones", "glosario"))
	p._perezoso(p._lista_ajustes, p._ui_ajustes.abrir.bind("ajustes"))
	p._perezoso(p._lista_correo, p._abrir_perezosa.bind("gente", "correo"))
	p._perezoso(p._lista_redes, p._abrir_perezosa.bind("gente", "redes"))
	## Diferidas como las demás (etapa 1, 2.ª pasada): llamadas a pelo, con
	## la pestaña oculta no pintaban NI quedaban pendientes, y al entrar en
	## «Vida» o «Habilidades» la hoja salía vacía.
	p._perezoso(p._lista_vida, p._abrir_perezosa.bind("legado", "vida"))
	p._perezoso(p._lista_habilidades, p._abrir_perezosa.bind("legado", "habilidades"))
	p._perezoso(p._lista_libres, p._abrir_perezosa.bind("plantel", "libres", {"club": c}))
	p._perezoso(p._lista_premios, p._abrir_perezosa.bind("plantel", "premios"))
	p._perezoso(p._lista_clubes, p._pintar_clubes)
	p._perezoso(p._lista_desafios, p._abrir_perezosa.bind("plantel", "desafios"))
	p._perezoso(p._lista_tactica, p._abrir_perezosa.bind("plantel", "tactica", {"club": c}))
	p._perezoso(p._lista_partido, p._abrir_perezosa.bind("plantel", "partido", {"club": c}))
	p._perezoso(p._lista_calendario, p._abrir_perezosa.bind("plantel", "calendario", {"club": c}))
	_pintar_dias()
	p._actualizar_badges()
	p._ui_despacho.abrir("despacho")
	## La ficha, igual: si la columna no se ve (menús sin ficha), se pinta al verse.
	p._seleccionado = p._seleccionado if p._seleccionado != null else p._jugador_de_la_semana(c)
	p._perezoso(p._ficha, p._ver_ficha.bind(p._seleccionado))
	## LO ÚLTIMO DE TODO: traducir. Ver `nucleo/idiomas.gd` -la interfaz se pinta
	## siempre en castellano y se traduce al final, para no tener que marcar dos
	## mil cadenas con `tr()` en un archivo de diez mil líneas-.
	p._traducir_pantalla(p)
	## Y la música, que también depende de lo que esté pasando.
	Musica.ambientar(situacion_musical())   ## (A4 memoria) sin crear `PantallaOpciones` en cada refresco
	actualizar_calendario()   ## «Temporada siguiente» solo existe al terminar la liga
	if not _prologo_lanzado and p.mundo != null and p.mundo.prologo_pendiente and not p.mundo.prologo_visto:   ## (9-11) el prólogo animado, al empezar
		_prologo_lanzado = true
		PrologoInicio.ofrecer.call_deferred(p)
	## (9-11) EVENTO DE FIN DE TEMPORADA: al terminar la liga, el partido de despedida a pantalla completa (solo en su fecha, una vez).
	if p.mundo != null and p.mundo.temporada_en_curso():
		_evento_fin_lanzado = false
	if p.mundo != null and not p.mundo.temporada_en_curso() and not _evento_fin_lanzado:
		_evento_fin_lanzado = true
		JornadaDespedida.ofrecer.call_deferred(p)
## ¿Tu club tiene partido (liga, copa o continental) que aún no se ha jugado esta semana?
func _tiene_partido_pendiente() -> bool:
	return p.mundo != null and p.mundo.temporada_en_curso() and (not p.mundo.proximo_partido().is_empty()
		or not p.mundo.partido_de_copa().is_empty() or not p.mundo.partido_continental().is_empty())

func _avanzar_semana() -> void:
	if not p.mundo.temporada_en_curso():
		p._escribir("[color=#e05555]La temporada está terminada. Pulsa «Temporada siguiente».[/color]")
		return
	if partido_obliga and _tiene_partido_pendiente():
		p._escribir("[color=#d9a43a]%s[/color]" % Idiomas.t("Hay partido: se abre el menú del partido."))
		p._dirigir()
		return
	var mio := p.mundo.mi_club()
	var liga := p._liga_de(mio)
	var caja_antes := mio.saldo
	## EL CIERRE DEL MERCADO TIENE QUE NOTARSE. Un mercado que cierra en
	## silencio es un boton que un dia deja de funcionar; avisado con dos
	## semanas, es una fecha limite y cambia como se juega esa quincena.
	if p.mundo.mercado_abierto() and p.mundo.semanas_de_mercado() <= 2 and _mercado_avisado != p.mundo.semana:
		_mercado_avisado = p.mundo.semana
		var q := p.mundo.semanas_de_mercado()
		Aviso.mostrar(p, "mercado", "⏳", "El mercado cierra",
			"Queda%s %d semana%s para el cierre. Lo que no fiches ahora, no lo fichas hasta la próxima ventana." % [
				"" if q == 1 else "n", q, "" if q == 1 else "s"], "mercado_cierra")
	## ALINEACIÓN INVÁLIDA (01-11, idea 1036): si tu once elegido tiene un lesionado o un sancionado, se avisa.
	var falla_once := AvisoOnce.motivo(mio)
	if falla_once != "":
		Aviso.mostrar(p, "alerta", "⚠️", Idiomas.t("Tu once elegido no vale"), falla_once)
	## Se escucha esta jornada para contar lo que le pasó a TU club, que es lo
	## único que interesa de las 190 jornadas que se juegan en el mundo.
	var visto := {"txt": ""}
	var oyente := func(_n: int, resultados: Array) -> void:
		for r: Dictionary in resultados:
			if r["local"] == mio or r["visita"] == mio:
				var casa: bool = r["local"] == mio
				var rival: Club = r["visita"] if casa else r["local"]
				var gf: int = r["gl"] if casa else r["gv"]
				var gc: int = r["gv"] if casa else r["gl"]
				var col := "#4caf6d" if gf > gc else ("#e05555" if gf < gc else "#8ea595")
				visto["txt"] = "[color=%s]J%d  %s %d-%d %s[/color]  [color=#8ea595]%s[/color]" % [
					col, liga.jornada_actual, mio.nombre, gf, gc, rival.nombre,
					Idiomas.t("en casa" if casa else "fuera")]
	liga.jornada_terminada.connect(oyente)
	p.mundo.avanzar_semana()
	liga.jornada_terminada.disconnect(oyente)
	if visto["txt"] != "":
		p._escribir(visto["txt"])
	_clubes_seguidos()
	if p.mundo.semana % Finanzas.SEMANAS_DEL_MES == 1 and p.mundo.semana > 1:
		var delta := mio.saldo - caja_antes
		p._escribir("[color=#c9a227]Cierre de mes:[/color] la caja %s %s" % [
			"sube" if delta >= 0 else "baja", p._dinero(absi(delta))])
	p._partida.autoguardar_si_toca()
	_refrescar()
	## El partido simulado también cuenta para la racha del plan.
	load("res://ui/componentes/pregunta_plan.gd").mostrar_si_toca(p, mio)
## Avanza UN día. Si con eso se pasa del domingo, la semana del motor corre de
## verdad -es el único punto donde esto toca la simulación-.
func _avanzar_dia() -> void:
	if p.mundo == null or not p.mundo.temporada_en_curso():
		p._escribir("[color=#e05555]La temporada está terminada. Pulsa «Temporada siguiente».[/color]")
		return
	## (9-11) El sábado de partido no se pasa de largo: se abre el menú del partido (como PES 2020).
	if partido_obliga and p._dia_semana >= 5 and _tiene_partido_pendiente():
		p._dirigir()
		return
	if p._dia_semana >= 6:
		p._dia_semana = 0
		_avanzar_semana()
		return
	p._dia_semana += 1
	## LA PORTADA DEL DÍA SIGUIENTE (B5): la frase de la rueda, citada.
	if p.mundo.prensa != null and not p.mundo.prensa.titular_pendiente.is_empty():
		var tit := p.mundo.prensa.publicar_titular_pendiente()
		Aviso.mostrar(p, "prensa", "🗞️", "La portada de hoy", tit)
	p._partida.autoguardar_si_toca()   ## (3-11) también al pasar cada día (la semana entera ya lo hace en `_avanzar_semana`)
	_refrescar()
	## Llega el sábado y juegas: el menú del partido se abre solo.
	if partido_obliga and p._dia_semana == 5 and _tiene_partido_pendiente():
		p._dirigir.call_deferred()
## ¿Hoy es sábado y tu club tiene el partido sin jugar? (los avances de varios días paran aquí)
func _hay_partido_hoy() -> bool:
	return partido_obliga and p._dia_semana == 5 and _tiene_partido_pendiente()

## EL PRÓXIMO HITO del calendario (idea del PES 2020: el avance se detiene en lo importante): {"dia": 0-6, "icono", "texto", "tipo"}.
## Lo calcula `EventosFecha.hito`: tu partido de liga, de copa o continental, el cierre y la apertura del mercado, el fin de temporada.
func proximo_hito() -> Dictionary:
	return EventosFecha.hito(p.mundo, p._dia_semana)

## «Hasta el próximo hito»: avanza día a día y se detiene al llegar al sábado de partido (abre su menú) o al cambiar de semana.
func _avanzar_hasta_hito() -> void:
	if p.mundo == null or not p.mundo.temporada_en_curso():
		return
	var objetivo := int(proximo_hito()["dia"])
	var sem0 := p.mundo.semana
	var tope := 8
	while tope > 0 and p.mundo.semana == sem0 and p.mundo.temporada_en_curso():
		tope -= 1
		_avanzar_dia()
		if _hay_partido_hoy() or p._dia_semana >= objetivo:
			break

## Los siete días con el de hoy encendido. El sábado lleva el balón porque es
## cuando cae la jornada: sin esa marca, la tira sería un adorno.
func _pintar_dias() -> void:
	if p._fila_dias == null:
		return
	p._limpiar(p._fila_dias)
	var fila_prox: Variant = p._guia.nodos.get("fila_proximos")
	if is_instance_valid(fila_prox) and p.mundo != null:
		FilaProximos.pintar(p.mundo, fila_prox as HBoxContainer, p._dia_semana)
	var boton_hito: Variant = p._guia.nodos.get("hito")
	if is_instance_valid(boton_hito) and p.mundo != null:
		var h := proximo_hito()
		(boton_hito as Button).tooltip_text = "%s %s · %s" % [h["icono"], Idiomas.t("Avanzar hasta el próximo hito:"), h["texto"]]
	var hay_partido := p.mundo != null and (not p.mundo.proximo_partido().is_empty()
		or not p.mundo.partido_de_copa().is_empty())
	for i in Principal.DIAS_CORTOS.size():
		var es_hoy := i == p._dia_semana
		var dia_de_partido := i == 5 and hay_partido
		## C13: el día nacional, de memoria o festivo, con su icono y el nombre
		## al pasar el ratón.
		var fechas_dia := Calendario.del_dia(p.mundo.mi_club().pais if p.mundo != null and p.mundo.mi_club() != null else "CHI",
			p.mundo.anio if p.mundo != null else 2026, p.mundo.semana if p.mundo != null else 1, i)
		var marca := ""
		for fd: Dictionary in fechas_dia:
			marca += " " + Calendario.icono(String(fd["tipo"]))
		var b := p._pildora("%s %d%s%s" % [Principal.DIAS_LARGOS[i], int(p.fecha_del_dia(i).get("day", 1)), marca, "  ⚽" if dia_de_partido else ""], 11, 26)
		if not fechas_dia.is_empty():
			b.tooltip_text = "\n".join(fechas_dia.map(func(fd: Dictionary) -> String: return Idiomas.t(String(fd["nombre"]))))
		b.button_pressed = es_hoy
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if es_hoy and _dia_pintado != p._dia_semana:
			_dia_pintado = p._dia_semana
			(func() -> void: Animar.pulso(b, 1.1)).call_deferred()
		if dia_de_partido and not es_hoy:
			b.add_theme_color_override("font_color", p._color_de_paleta(p.COL_ORO))
		## Tocar un día futuro avanza hasta ahí; uno pasado no hace nada -el
		## tiempo no vuelve atrás, y un botón que miente es peor que uno que
		## no está-.
		var destino := i
		b.disabled = destino <= p._dia_semana
		b.pressed.connect(func() -> void:
			while p._dia_semana < destino and not _hay_partido_hoy():
				_avanzar_dia())
		p._fila_dias.add_child(b)

## A quién enseña la ficha cuando no has elegido a nadie.
##
## Antes se quedaba vacía o clavada en el mismo jugador semana tras semana, y un
## plantel de veinticuatro se convertía en uno. Rotar por rotar tampoco sirve:
## lo que se enseña es a quien tiene ALGO que contar esta semana, y solo si no
## hay nadie así se pasa el turno por la plantilla.
func _jugador_de_la_semana(c: Club) -> Jugador:
	if c.plantilla.is_empty():
		return null
	## 1 · El que está roto: es lo primero que uno querría saber al abrir.
	for j in c.plantilla:
		if j.lesion > 0:
			return j
	## 2 · El que está en racha: mejor nota media de las tres últimas, y solo si
	## de verdad ha jugado.
	var mejor: Jugador = null
	var mejor_nota := 6.8
	for j in c.plantilla:
		if j.notas.size() < 3:
			continue
		var ultimas := j.notas.slice(maxi(0, j.notas.size() - 3))
		var s := 0.0
		for x in ultimas:
			s += float(x)
		var media := s / float(ultimas.size())
		if media > mejor_nota:
			mejor_nota = media
			mejor = j
	if mejor != null:
		return mejor
	## 3 · Y si no hay noticia, el turno rota con la semana: cada una le toca a
	## uno distinto, y en un año pasan todos por la ficha.
	return c.plantilla[(p.mundo.semana + p.mundo.anio) % c.plantilla.size()]

func _anotar(titulo: String, cuerpo: String) -> void:
	## Con el nombre de competición que se ve (correo, Tribuna y móvil lo heredan).
	titulo = CompeticionInfo.visibles_en(titulo)
	cuerpo = CompeticionInfo.visibles_en(cuerpo)
	p._bandeja.push_front({"titulo": titulo, "cuerpo": cuerpo, "semana": p.mundo.semana, "anio": p.mundo.anio, "leida": false})
	## Lo que pasa también se comenta en Tribuna (las redes del móvil).
	if p.mundo.redes != null:
		p.mundo.redes.desde_noticia(p.mundo, titulo, cuerpo)
	## Y si es cosa de alguien (la directiva, la familia...), te escribe.
	if p.mundo.movil != null:
		var de := Movil.remitente_de(titulo, cuerpo)
		if not de.is_empty():
			p.mundo.movil.recibir(String(de[0]), String(de[1]), "%s %s", p.mundo.anio, p.mundo.semana, [titulo, cuerpo], true)
	if p._bandeja.size() > Principal.BANDEJA_MAX:
		p._bandeja.resize(Principal.BANDEJA_MAX)

## M-292 (2-11): el último resultado de cada club que sigues, una vez por jornada jugada, a la bandeja.
var _seguido_jornada := {}
func _clubes_seguidos() -> void:
	if p.mundo.ojeadores == null:
		return
	for cid: String in p.mundo.ojeadores.clubes_seguidos:
		var c: Club = p.mundo.clubes.get(cid)
		if c == null:
			continue
		var l := p._liga_de(c)
		if l.historial.is_empty() or int(_seguido_jornada.get(cid, -1)) == l.jornada_actual:
			continue
		_seguido_jornada[cid] = l.jornada_actual
		for r: Dictionary in l.historial[-1]:
			if r["local"] == c or r["visita"] == c:
				_anotar(Idiomas.t("📌 Club seguido: %s") % c.nombre, Idiomas.t("Jornada %d: %s %d-%d %s.") % [
					l.jornada_actual, (r["local"] as Club).nombre, int(r["gl"]), int(r["gv"]), (r["visita"] as Club).nombre])
