extends BaseIdea
## f2p · EL PRÓLOGO 3D (fase 2): de la entrada a tu primer día, sin pantalla.
## Recorre los 8 pasos del guion moviendo al personaje por código: llegada,
## puerta, vestuario, campo, enfermería, directiva (pregunta y confianza),
## prensa (tres respuestas y relación con los medios) y la oficina, donde el PC
## enciende el menú central de siempre y lo apaga sin dejar nada colgado.
## Comprueba además que cada sala del recorrido es alcanzable con el cuerpo
## entero (`ColisionClub.cabe`), que el guion está traducido, que la marca
## `prologo_visto` sobrevive a guardar y cargar, y qué modos entran al prólogo.

var _p: PrologoDT
var _e: ExploradorCiudad
var _m: Mundo
var _saludos: Array[String] = []   ## el personal que saludó al llegar a su sala

func _ready() -> void:
	await get_tree().process_frame
	await _probar_async()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _probar_async() -> void:
	_titulo("f2p: el prólogo 3D, paso a paso")
	## --- qué modos entran al prólogo ------------------------------------------------
	OrquestadorMundo.sin_prologo = false
	_comprobar(OrquestadorMundo.con_prologo("dt") and OrquestadorMundo.con_prologo("creador") and OrquestadorMundo.con_prologo("jeque"),
		"los modos con club empiezan con el prólogo")
	_comprobar(not OrquestadorMundo.con_prologo("tutorial") and not OrquestadorMundo.con_prologo("retos") and not OrquestadorMundo.con_prologo("carrera-m"),
		"tutorial, retos y Carrera de Jugador no pasan por el prólogo")
	OrquestadorMundo.sin_prologo = true
	_comprobar(not OrquestadorMundo.con_prologo("dt"), "las pruebas pueden apagarlo")
	OrquestadorMundo.sin_prologo = false
	## --- el guion ------------------------------------------------------------------
	_comprobar(PrologoPasos.PASOS.size() == 12 and PrologoPasos.indice("oficina") == 11, "el guion tiene 12 pasos y termina en tu oficina")
	var sin_traducir: Array[String] = []
	var idioma_antes: String = Idiomas.idioma
	Idiomas.idioma = "en"
	for paso: Dictionary in PrologoPasos.PASOS:
		for f: String in (paso["frases"] as Array) + ([paso["saludo"]] if paso.has("saludo") else []):
			if Idiomas.t(f) == f:
				sin_traducir.append(f.left(30))
	Idiomas.idioma = idioma_antes
	_comprobar(sin_traducir.is_empty(), "todas las frases del mentor están traducidas %s" % [sin_traducir])
	## --- el mundo y la escena --------------------------------------------------------
	_m = _mundo(4242)
	PedidoPartida.mundo_pregenerado = _m
	PedidoPartida.modo_elegido = "dt"
	PedidoPartida.dt_nombre_elegido = "Míster Prueba"
	PrologoDT.rapido = true
	_p = (load("res://escenas/prologo.tscn") as PackedScene).instantiate()
	add_child(_p)
	for i in 240:
		await get_tree().process_frame
		if _p._listo:
			break
	_comprobar(_p._listo and _p.explorador != null, "el prólogo construye la ciudad y arranca el paseo")
	if not _p._listo:
		return
	_e = _p.explorador
	_comprobar(_p.mentor != null and _p.mentor.nombre != "" and _p.mentor.visible, "el mentor está en la puerta con nombre (%s)" % _p.mentor.nombre)
	_comprobar(_e.cuerpo.position.distance_to(_p.puerta) < 9.0 and String(_e.estado) == "calle", "apareces en la acera frente a la puerta del club")
	## Paso 0: habla al momento.
	_comprobar(_p.paso_i == 0 and _p.dialogo.visible and _p.frase_i == 0, "el mentor te recibe hablando (llegada)")
	_terminar_charla()
	_comprobar(_p.esperando_llegada and not _p.dialogo.visible, "tras hablar espera a que te acerques")
	## Cada sala del recorrido se puede pisar con el cuerpo entero.
	var inalcanzables: Array[String] = []
	for paso: Dictionary in PrologoPasos.PASOS:
		if bool(paso.get("fuera", false)):
			continue
		var c := _p._centro_zona(String(paso["zona"]), int(paso["planta"]))
		if not ColisionClub.cabe(_p.est["zonas"], c - CityBuilder.ESTADIO_EN, int(paso["planta"])):
			inalcanzables.append(String(paso["zona"]))
	_comprobar(inalcanzables.is_empty(), "el centro de cada sala del recorrido cabe el cuerpo entero %s" % [inalcanzables])
	## Llegar al mentor → paso 1 (puerta); hablar → espera a que entres.
	_e.cuerpo.position = _p.mentor.position + Vector3(0, 0, 0.8)
	await _frames(2)
	_comprobar(_p.paso_i == 1 and _p.esperando_llegada, "acercarte al mentor pasa al paso de la puerta")
	_e.cuerpo.position = _p.destino
	await _frames(2)
	_comprobar(_p.dialogo.visible, "en la puerta el mentor explica el portero")
	_terminar_charla()
	_comprobar(_p.esperando_entrada, "y espera a que entres al estadio")
	_e._entrar_al_estadio()
	await _frames(2)
	_comprobar(_p.paso_i == 2 and String(_e.estado) == "estadio", "al cruzar la puerta empieza el recorrido (vestuario)")
	## Las salas, una tras otra.
	for clave: String in ["vestuario", "tunel", "campo", "utileria", "enfermeria"]:
		var ok := await _llegar_y_escuchar(clave)
		_comprobar(ok, "sala «%s»: el mentor espera allí y habla al llegar" % clave)
	_comprobar(_saludos.has("utilero") and _saludos.has("medico"), "en la utilería y la enfermería el personal saluda antes que el mentor %s" % [_saludos])
	## Directiva.
	var ok_pres := await _llegar_y_escuchar("presidente", false)
	_comprobar(ok_pres and is_instance_valid(_p.hud._directiva), "en el despacho se abre la pregunta de la directiva")
	var conf0 := _m.directiva.confianza
	_p._responder_directiva(0)
	await _frames(1)
	_comprobar(_m.directiva.confianza == clampi(conf0 + 3, 0, 100), "la respuesta ambiciosa suma 3 de confianza")
	_comprobar(_p.dialogo.visible and _p._directivos.size() == 2, "el presidente contesta y hay dos directivos de cuerpo presente")
	_p._hablar()
	await _frames(2)
	var ok_video := await _llegar_y_escuchar("video")
	_comprobar(ok_video and _saludos.has("ojeador"), "sala de vídeo: el ojeador saluda y el mentor la explica")
	## Prensa.
	var ok_prensa := await _llegar_y_escuchar("prensa", false)
	_comprobar(ok_prensa and is_instance_valid(_p.prensa), "en la sala de prensa se abre la presentación")
	var rel0 := _m.prensa.relacion_media()
	var gestos_ok := true
	for t: Dictionary in PrologoPasos.TONOS:
		gestos_ok = gestos_ok and AnimExtra.GESTO_TONO.has(String(t["clave"])) and AnimExtra.new().has_method(String(AnimExtra.GESTO_TONO[t["clave"]]))
	for i in 3:
		_p.prensa._responder("seguro", 2)
		if i == 0:
			gestos_ok = gestos_ok and _p.prensa._escena.tono_dt == "seguro"
	_comprobar(gestos_ok, "cada tono tiene su gesto en el plató y responder se lo pasa al DT (seguro = manos abiertas)")
	_comprobar(_m.prensa.relacion_media() == clampi(rel0 + 6, 0, 100), "tres respuestas seguras suben la relación con la prensa")
	for b: Button in _p.prensa._botones.get_children():
		b.pressed.emit()
	await _frames(2)
	_comprobar(_p.paso_i == PrologoPasos.indice("comedor") and _p.prensa == null, "al salir de la sala de prensa toca el comedor")
	var ok_com := await _llegar_y_escuchar("comedor")
	_comprobar(ok_com and _saludos.has("cocinera"), "comedor del plantel: la cocinera saluda")
	## La oficina y el PC.
	var ok_of := await _llegar_y_escuchar("oficina", false)
	_comprobar(ok_of and _p.pc != null, "en la oficina aparece el PC")
	_e.cuerpo.position = _p.pc.punto
	await _frames(1)
	_comprobar(_p.pc.cerca(), "delante del escritorio el PC se puede usar")
	_p.pc.encender()
	await _frames(4)
	var pr := _p.pc.principal()
	_comprobar(pr != null and pr is Principal and (pr as Principal).mundo == _m, "E enciende el menú central con TU partida")
	_comprobar(not _p.vista.visible and _p.explorador.process_mode == Node.PROCESS_MODE_DISABLED, "mientras el PC está encendido el mundo 3D se esconde y se congela")
	_comprobar(_m.prologo_visto, "la primera vez que enciendes el PC el prólogo queda hecho")
	_comprobar(_m.logros != null and _m.logros.largos.has("primer_dia"), "y cae el logro «Primer día»")
	## §2.5-1: desde el PC, «Pasear» y «Ver la ciudad» te levantan (no abren otra ciudad dentro del menú).
	await (pr as Principal)._ver_ciudad_explorando("pie")
	await _frames(2)
	_comprobar(not _p.pc.abierto and pr.find_children("*", "VistaCiudad", true, false).is_empty() and _p.vista.visible,
		"desde el PC, «Pasear» te levanta en vez de abrir otra ciudad dentro del menú")
	_p.pc.encender()
	await _frames(2)
	await (pr as Principal)._ver_ciudad_con_carga()
	await _frames(2)
	_comprobar(not _p.pc.abierto and pr.find_children("*", "VistaCiudad", true, false).is_empty(),
		"desde el PC, «Ver la ciudad en 3D» también te levanta")
	_p.pc.encender()
	await _frames(2)
	_p.pc.apagar()
	await _frames(3)
	_comprobar(_p.pc.principal() == null and _p.vista.visible and _p.explorador.process_mode == Node.PROCESS_MODE_INHERIT, "levantarte apaga el PC y devuelve el mundo")
	## Volver a encenderlo retoma la MISMA partida (no una nueva ni la caja escalada otra vez).
	var saldo := _m.mi_club().saldo
	_p.pc.encender()
	await _frames(4)
	var pr2 := _p.pc.principal()
	_comprobar(pr2 != null and (pr2 as Principal).mundo == _m and _m.mi_club().saldo == saldo, "volver a encender el PC retoma la misma partida con la misma caja (y la misma pantalla)")
	_p.pc.apagar()
	await _frames(2)
	## Guardar y cargar conservan la marca.
	var datos := Partida.instantanea(_m)
	_comprobar(bool(datos.get("prologo_visto", false)), "la instantánea guarda prologo_visto")
	## Fase 0 §7.2 (31-10): lo pedido en la entrada se aplica UNA vez (el orquestador antes de autoguardar,
	## y Principal lo encuentra hecho), y una partida guardada con el prólogo pendiente vuelve al prólogo.
	var mf := _mundo(4243)
	var dif0 := PedidoPartida.dificultad_elegida
	PedidoPartida.dificultad_elegida = "facil"
	var s0 := mf.mi_club().saldo
	PedidoPartida.aplicar(mf)
	var s1 := mf.mi_club().saldo
	PedidoPartida.aplicar(mf)
	PedidoPartida.dificultad_elegida = dif0
	_comprobar(s1 == int(round(float(s0) * 1.6)) and mf.mi_club().saldo == s1 and mf.dificultad == "facil",
		"la dificultad elegida se aplica una sola vez aunque la pidan el orquestador y Principal")
	mf.prologo_visto = false
	mf.prologo_pendiente = true
	Partida.guardar(mf, "zz_prueba_orquestador")
	var mc := Partida.cargar("zz_prueba_orquestador")
	_comprobar(mc != null and mc.prologo_pendiente and VidaCiudad.arranque_3d(mc) == "prologo" and mc.mi_club().saldo == s1,
		"guardada al salir de la entrada, «Continuar» vuelve al prólogo con la caja ya ajustada")
	Partida.borrar("zz_prueba_orquestador")
	PedidoPartida.mundo_pregenerado = null
	PedidoPartida.mundo_a_cargar = null
	PedidoPartida.modo_elegido = ""
	PrologoDT.rapido = false

## Avanza el cuadro de diálogo hasta que el mentor termina (como pulsar E).
func _terminar_charla() -> void:
	for i in 12:
		if not _p.dialogo.visible:
			return
		_p._hablar()

## Teletransporta al personaje a la sala del paso `clave` (misma planta), deja
## que el prólogo lo vea y, si `cerrar`, escucha al mentor hasta el final.
func _llegar_y_escuchar(clave: String, cerrar: bool = true) -> bool:
	var i := PrologoPasos.indice(clave)
	if _p.paso_i != i:
		return false
	var paso: Dictionary = PrologoPasos.PASOS[i]
	_e._planta = int(paso["planta"])
	_e.cuerpo.position = _p.destino
	await _frames(3)
	var mentor_alli := _p.mentor.visible and _p.mentor.position.distance_to(_p.destino) < 0.6
	var habla := _p.dialogo.visible
	if _p.frase_i == 0 and not _p.hablantes.is_empty() and _p.hablantes[0] != "":
		_saludos.append(_p.hablantes[0])
	if cerrar:
		_terminar_charla()
		await _frames(2)
	else:
		_terminar_charla()
		await _frames(2)
	return mentor_alli and habla
