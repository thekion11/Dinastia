class_name JornadaPartido
extends RefCounted
## LA JORNADA DE PARTIDO (fase 6, paso 7 del plan §7.1; sale de `Principal`, capa 12, el 27-10-2026):
## el modo de simulación por competición, dirigir el partido de la semana en directo, apuntarlo por si
## se cierra el juego a medias, cerrarlo con el resultado que se vio y jugar la temporada entera.
## `pr` es la pantalla principal (no `p`: aquí `p` es el partido, como en el código original).

var pr: Principal

func _init(principal: Principal) -> void:
	pr = principal

## El modo elegido para una competición (se guarda por separado: la copa en 3D
## y la liga en resumen, por ejemplo). Por defecto, 3D completo, que es lo que
## hacía "Dirigir" hasta hoy.
func _modo_simulacion(comp: String) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(CajonAjustes.RUTA) != OK:
		return "completo"
	return String(cfg.get_value(Principal.SECCION_SIMULACION, comp, "completo"))

## La competición del partido de esta semana, con el mismo orden que
## `_dirigir()`: copa, después continental, después liga.
func _competicion_de_la_semana() -> String:
	if not pr.mundo.partido_de_copa().is_empty():
		return "copa"
	if pr.mundo.mi_continental() != null and not pr.mundo.partido_continental().is_empty():
		return "conti"
	return "liga"

## Apunta el partido dirigido y lo pone al día (goles y cada 5'): si se cierra
## el juego a medias, al cargar se completa desde ahí (`PartidoPendiente`).
func _apuntar_partido_en_curso(p: Partido) -> void:
	PartidoPendiente.abrir(pr.mundo, p)
	p.gol.connect(func(_c: Club, _a: Jugador, _m: int, _s: Jugador) -> void: PartidoPendiente.actualizar(pr.mundo, p))
	p.minuto_jugado.connect(func(mi: int) -> void:
		if mi % 5 == 0:
			PartidoPendiente.actualizar(pr.mundo, p))

func _seguir_tras_partido(p: Partido) -> void:
	PartidoPendiente.cerrar()
	pr.mundo.avanzar_semana(p)
	pr._escribir("[color=#3fa06a]J%d  %s %d-%d %s[/color]" % [
		pr.mundo.liga_de(pr.mundo.mi_club()).jornada_actual,
		p.local.nombre, p.goles_local, p.goles_visita, p.visita.nombre])
	## (17-10: tras un partido dirigido no se autoguardaba; ahora sí, como al
	## avanzar la semana sin jugarlo.)
	pr._partida.autoguardar_si_toca()
	pr._refrescar()
	## Seis partidos seguidos con el mismo cambio del plan: se pregunta.
	PreguntaPlan.mostrar_si_toca(pr, pr.mundo.mi_club())

## Se avanza la semana con el partido ya jugado en la mano. Si se avanzara sin
## él, la jornada se volvería a simular por dentro y en la tabla aparecería un
## marcador distinto del que se acaba de ver. Lo usan todos los modos.
func _cerrar_partido_dirigido(p: Partido) -> void:
	PartidoPendiente.actualizar(pr.mundo, p)
	## A PIE DE CAMPO (B5): antes de volver al despacho, una pregunta con el
	## partido todavía caliente. No en "instantáneo": quien lo eligió quiere el
	## resultado y nada más.
	if pr.mundo.prensa != null and _modo_simulacion(_competicion_de_la_semana()) != "instantaneo":
		var mio := pr.mundo.mi_club()
		var local := p.local == mio
		var gf := p.goles_local if local else p.goles_visita
		var gc := p.goles_visita if local else p.goles_local
		var pie := PieDeCampo.mostrar(pr, pr.mundo.prensa, gf > gc, gf == gc, gf, gc)
		pie.cerrado.connect(func() -> void: _seguir_tras_partido(p))
		return
	_seguir_tras_partido(p)

## El estadio del local, con el cielo del día (no el que se eligió en el
## diseñador: el clima lo pone la ciudad).
func _perfil_con_clima(p: Partido) -> Dictionary:
	var perfil := pr.mundo.perfil_estadio_de(p.local).duplicate()
	if not p.clima_info.is_empty():
		perfil["clima"] = String(p.clima_info["clave"])
	return perfil

## Abre el partido de esta jornada en directo. Al terminar, el resultado que
## salga en la pantalla es el que va a la tabla: el pr.mundo simula el resto de la
## jornada pero NO vuelve a jugar el tuyo.
func _dirigir() -> void:
	if not pr.mundo.temporada_en_curso():
		pr._escribir("[color=#e05555]La temporada está terminada.[/color]")
		return
	## Si esta semana hay copa, manda la copa: es la que se juega a un solo
	## partido y la que se puede perder para siempre.
	var par := pr.mundo.partido_de_copa()
	var es_copa := not par.is_empty()
	## SI NO HAY COPA, ¿HAY CONTINENTAL? Hasta esta tanda `_dirigir()` nunca
	## miraba esto: `partido_continental()` no existía, así que un partido de
	## Libertadores/Champions/etc. jamás se podía dirigir en vivo -se
	## auto-simulaba solo, sin que el jugador se enterara de que existía esa
	## fecha-. El motor de abajo (`Continental.jugar_ronda(ya_jugado)`) ya
	## sabía recibirlo; solo faltaba esta puerta.
	var conti: Continental = null
	if not es_copa:
		conti = pr.mundo.mi_continental()
		par = pr.mundo.partido_continental()
		if par.is_empty():
			conti = null
	if conti == null and not es_copa:
		par = pr.mundo.proximo_partido()
	if par.is_empty():
		pr._escribir("[color=#8ea595]Tu club descansa esta jornada.[/color]")
		return
	## La eliminatoria -penales, sin revancha- es la copa siempre, y el
	## continental solo cuando ya salió de la fase de grupos.
	var es_eliminatoria := es_copa or (conti != null and not conti.en_fase_de_grupos())
	if es_copa:
		pr._escribir("[color=#c9a227]%s — %s.[/color]" % [pr.mundo.copa.nombre, pr.mundo.copa.nombre_de_ronda()])
	elif conti != null:
		pr._escribir("[color=#c9a227]%s — %s.[/color]" % [Continental.nombre_conti(conti.clave), conti.nombre_de_ronda()])
	var p := Partido.new(par[0], par[1])
	## EL TIEMPO DE LA CIUDAD (plan maestro C1): el mismo que se juega y el
	## mismo cielo que se ve. Sale del país del local y la época del año.
	var info_clima := Clima.del_partido(p.local.pais, pr.mundo.semana, pr.mundo.anio, p.local.id + p.visita.id)
	p.fijar_clima(info_clima)
	pr._escribir("[color=#8ea595]%s Parte del tiempo: %s.[/color]" % [Clima.icono(info_clima), String(info_clima["texto"])])
	var consejo := Clima.consejo(info_clima, p.local == pr.mundo.mi_club())
	if consejo != "":
		MentorVoz.decir(pr, pr.mundo, "%s %s" % [Clima.icono(info_clima), String(info_clima["texto"])], consejo)
	## El nodo «Bloque» del arbol hace que lo que dices desde el banquillo pegue
	## un 50% mas. En este motor eso es la arenga.
	if pr.mundo.entrenamiento != null:
		p._factor_arenga = pr.mundo.entrenamiento.factor_instrucciones()
	## CÓMO SE MIRA (25-9-2026, plan maestro B2). Los cinco modos juegan el
	## MISMO `Partido` con los mismos `simular_minuto()`: solo cambia la vista.
	var modo := _modo_simulacion(_competicion_de_la_semana())
	if modo == "instantaneo" or modo == "resumen":
		p.preparar()
		p.fijar_hinchada(pr.mundo.mi_club(), pr.mundo.prensa.animo if pr.mundo.prensa != null else 60)
		_apuntar_partido_en_curso(p)
		var res := ResumenPartido.mostrar(pr, p, pr.mundo.mi_club(), es_eliminatoria, modo == "resumen")
		res.cerrado.connect(func() -> void:
			res.queue_free()
			_cerrar_partido_dirigido(p))
		return
	## EL INFORME DEL RIVAL (17-10-2026) antes de salir a jugar, como en FM/FC.
	## Sin pantalla (banco) o con SIN_INFORME_RIVAL no se enseña.
	if InformeRival.activo and DisplayServer.get_name() != "headless" and OS.get_environment("SIN_INFORME_RIVAL") == "":
		var inf := InformeRival.mostrar(pr, p, pr.mundo.mi_club(), pr.mundo.liga_de(p.visita if p.local == pr.mundo.mi_club() else p.local), pr.mundo)
		await inf.cerrado
		inf.queue_free()
	_apuntar_partido_en_curso(p)
	var vivo := PartidoVivo.new()
	vivo.con_3d = modo != "vivo"
	vivo.destacados = modo == "destacados"
	vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
	pr.add_child(vivo)
	## El perfil del ESTADIO LOCAL -que puede ser el tuyo o el del rival, según
	## quién juegue en casa-, no siempre "el tuyo": `perfil_estadio_de()` ya
	## decide sola cuándo corresponde tu diseño y cuándo el genérico por hash.
	## El BALÓN sí es siempre el tuyo -`Comercial` es tu departamento comercial,
	## el rival no tiene uno propio en este juego-.
	## Lo de la PANTALLA GIGANTE va antes de `abrir()`: `PartidoVivo` abre el
	## visor 3D de entrada, así que asignarlo después llegaría tarde.
	vivo.datos_pantalla = pr._datos_pantalla_estadio(p.local, "copa" if es_copa else ("conti" if conti != null else "liga"))
	pr._fundido_entrada()
	vivo.abrir(p, pr.mundo.mi_club(), pr.mundo.vestuario, es_eliminatoria, pr.mundo.roles,
		pr._velocidad_partido, _perfil_con_clima(p),
		Comercial.color_balon(pr.mundo.comercial.balon, pr.mundo.mi_club()))
	vivo.cerrado.connect(func() -> void:
		vivo.queue_free()
		_cerrar_partido_dirigido(p))

func _jugar_temporada() -> void:
	if not pr.mundo.temporada_en_curso():
		pr._escribir("[color=#e05555]La temporada ya está terminada.[/color]")
		return
	var t0 := Time.get_ticks_msec()
	pr.mundo.jugar_temporada()
	var t := pr._liga_de(pr.mundo.mi_club()).tabla()
	var puesto := 1
	for fila: Dictionary in t:
		if fila["club"] == pr.mundo.mi_club():
			break
		puesto += 1
	pr._escribir("[color=#3fa06a]Temporada %d completa en %d ms.[/color] Campeón: [b]%s[/b]. Acabas [b]%d.º[/b]." % [
		pr.mundo.anio, Time.get_ticks_msec() - t0, t[0]["club"].nombre, puesto])
	pr._partida.autoguardar_si_toca()
	pr._refrescar()
