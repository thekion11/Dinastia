class_name JornadaDespedida
extends RefCounted
## LA INTERFAZ DEL PARTIDO DE DESPEDIDA (9-11): AL LLEGAR EL FIN DE LA TEMPORADA (la liga termina; lo dispara `AvanceSemana`, nunca un menú), a PANTALLA COMPLETA (`EventoDespedida`), se ofrece el partido de gala contra las Leyendas
## (los que se retiran esta temporada): JUGARLO en directo, SIMULARLO o dejarlo. La lógica (quién se retira, taquilla, ánimo, restaurar a tus jugadores) está
## en `PartidoDespedida`. Sin pantalla (banco) no se ofrece. Después el cierre de temporada sigue como siempre y respeta quién se retira.

## Pregunta (jugar / simular / no) y, según se elija, lo juega. Termina cuando el partido (o la decisión) ha terminado.
static func ofrecer(pr: Principal) -> void:
	if DisplayServer.get_name() == "headless" or pr.mundo == null or pr.mundo.mi_club() == null:
		return
	## (10-11) FIN DE LIGA → primero se cierran y ANUNCIAN la copa y el continental que quedaban a medias (`CierreTorneos`), luego la despedida.
	for c: Dictionary in CierreTorneos.cerrar_pendientes(pr.mundo):
		Aviso.mostrar(pr, "titulo", "🏆", String(c["torneo"]), "%s %s%s" % [Idiomas.t("Campeón:"), (c["campeon"] as Club).nombre,
			" · " + Idiomas.t("¡Es tu club!") if bool(c["mio"]) else ""])
	if pr.mundo.prensa != null and (pr.mundo.prensa.despedida_anio == pr.mundo.anio or pr.mundo.prensa.despedida_ofrecida_anio == pr.mundo.anio):
		return   ## ya se jugó o ya se ofreció esta temporada (el evento sale una sola vez, también tras guardar y cargar)
	var leyendas := PartidoDespedida.preparar(pr.mundo)
	if leyendas == null:
		PartidoDespedida.limpiar(pr.mundo)   ## sin once con portero: no hay partido y el cierre sortea los retiros como siempre
		return
	pr.mundo.prensa.despedida_ofrecida_anio = pr.mundo.anio
	var op := await _preguntar(pr, leyendas)
	if op == "no":
		return   ## los retiros ya decididos se respetan igual: solo falta el partido
	var mio := pr.mundo.mi_club()
	var foto := PartidoDespedida.foto(mio)
	var p := Partido.new(mio, leyendas)
	p.fijar_clima(Clima.del_partido(mio.pais, pr.mundo.semana, pr.mundo.anio, mio.id + leyendas.id))
	if op == "simular":
		p.simular()
	else:
		await _jugar_en_directo(pr, p)
	var res := PartidoDespedida.cerrar(pr.mundo, p, leyendas, foto)
	if DisplayServer.get_name() != "headless":
		var cer := CeremoniaDespedida.mostrar(pr, res["homenajeados"], leyendas)
		await cer.terminado
		cer.queue_free()
	Aviso.mostrar(pr, "vida", "🎖️", Idiomas.t("Partido de despedida"),
		"%s %d-%d · %s %d" % [Idiomas.t("Resultado:"), int(res["gf"]), int(res["gc"]), Idiomas.t("taquilla"), int(res["ingreso"])])

## El modo de mirar un partido de liga elegido en Ajustes ("completo" por defecto = con el estadio en 3D).
static func modo_elegido() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(CajonAjustes.RUTA) != OK:
		return "completo"
	return String(cfg.get_value(Principal.SECCION_SIMULACION, "liga", "completo"))

static func _jugar_en_directo(pr: Principal, p: Partido) -> void:
	var vivo := PartidoVivo.new()
	var modo := modo_elegido()   ## como un partido de liga: el modo de mirar que tengas puesto (vivo en texto, destacados o 3D)
	vivo.con_3d = modo != "vivo"
	vivo.destacados = modo == "destacados"
	vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
	pr.add_child(vivo)
	vivo.datos_pantalla = pr._datos_pantalla_estadio(p.local, "liga")
	pr._fundido_entrada()
	var perfil := pr.mundo.perfil_estadio_de(p.local).duplicate()
	vivo.abrir(p, pr.mundo.mi_club(), pr.mundo.vestuario, false, pr.mundo.roles, pr._velocidad_partido, perfil,
		Comercial.color_balon(pr.mundo.comercial.balon, pr.mundo.mi_club()))
	await vivo.cerrado
	vivo.queue_free()

static func _preguntar(pr: Principal, leyendas: Club) -> String:
	var ev := EventoDespedida.mostrar(pr, leyendas)
	var elegida: String = await ev.elegido
	ev.queue_free()
	return elegida
