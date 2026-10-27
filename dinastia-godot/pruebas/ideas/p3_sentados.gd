extends BaseIdea
## p3 · GENTE SENTADA Y SENTARSE DE VERDAD (calidad visual P3, pasada 2, 27-10-2026): la
## ciudad registra asientos (bancos de acera y de parada); con la vida enganchada, cerca de
## un banco hay gente sentada con el clip «sentado» y la raíz a la altura del asiento, que se
## va al alejarte; y el DT, al sentarse en el sofá, encadena «sentarse» → «sentado» y se queda
## así hasta dar un paso.

var _m: Mundo
var _vista: VistaCiudad
var _e: ExploradorCiudad
var _v: VidaCiudad

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
	_titulo("p3: gente sentada y sentarse de verdad")
	_m = _mundo(4242)
	_m.reloj.sincronizar(_m.anio, _m.semana)
	var club := _m.mi_club()
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.animo = CiudadAnimo.de(_m, club)
	_vista.abrir(club, _m.obras, _m.ciudad, _m.perfil_estadio_de(club))
	_vista.explorar("pie", Vector3(0, 0, -440))
	_e = _vista._explorador
	await _frames(2)
	var asientos: Array = _e.cb.asientos
	_comprobar(asientos.size() >= 20, "la ciudad registra asientos públicos (%d)" % asientos.size())
	Partida.cargada_de_respaldo = true   ## como si se hubiera recuperado la copia de un guardado dañado
	_v = VidaCiudad.enganchar(_e, _vista, _m)
	_comprobar(not Partida.cargada_de_respaldo and _v != null and _v._cuadro != null, "copia recuperada: el arranque 3D lo avisa en pantalla")
	var gs := _v.sentados if _v != null else null
	_comprobar(gs != null, "la vida monta la gente sentada")
	if gs == null or asientos.is_empty():
		return
	## Junto a un banco con alguien a esta hora.
	var i_ok := -1
	for i in asientos.size():
		if gs.ocupado(i):
			i_ok = i
			break
	_comprobar(i_ok >= 0, "a esta hora hay asientos ocupados")
	if i_ok < 0:
		return
	var p: Vector3 = asientos[i_ok]["p"]
	_e.cuerpo.position = p + Vector3(3.0, -0.79, 0)
	gs.revisar()
	await _frames(2)
	_comprobar(gs.cuerpos.has(i_ok) and gs.cuerpos.size() <= GenteSentada.MAXIMO, "cerca del banco se sienta gente (%d, tope %d)" % [gs.cuerpos.size(), GenteSentada.MAXIMO])
	if gs.cuerpos.has(i_ok):
		var d: Dictionary = gs.cuerpos[i_ok]["d"]
		var n: Node3D = d["nodo"]
		_comprobar((d["anim"] as AnimationPlayer).current_animation == "sentado", "con el clip «sentado»")
		_comprobar(n.position.y < p.y - 0.3 and n.position.y > p.y - 1.2, "con la cadera a la altura del asiento (raíz a %.2f bajo el asiento)" % (p.y - n.position.y))
	var en_banco := Vector3(p.x, p.y - 0.79, p.z)
	_comprobar(not _e.libre_total(en_banco, 0.3) if _e.has_method("libre_total") else _e._choca_circulos(en_banco, 0.3), "el banco es sólido: no se atraviesa andando")
	_e.cuerpo.position = p + Vector3(200.0, 0, 0)
	gs.revisar()
	_comprobar(not gs.cuerpos.has(i_ok), "al alejarte, se va")
	## Quien llega MIENTRAS miras (el asiento estaba libre y ahora no) viene andando, se vuelve y se sienta; no aparece sentado de golpe.
	_e.cuerpo.position = p + Vector3(8.0, -0.79, 0)
	gs._visto[i_ok] = false
	gs.revisar()
	_comprobar(gs.cuerpos.has(i_ok) and gs._llegando.size() == 1, "quien llega mientras miras viene andando hasta el banco")
	if gs._llegando.size() == 1:
		var dl: Dictionary = (gs._llegando[0] as Dictionary)["d"]
		var nl: Node3D = dl["nodo"]
		_comprobar(nl.position.distance_to(Vector3(p.x, nl.position.y, p.z)) > 2.5 and (dl["anim"] as AnimationPlayer).current_animation == "caminar", "empieza a unos 3 m del asiento, andando")
		gs._llegadas(4.0)
		_comprobar(int((gs._llegando[0] as Dictionary)["fase"]) == 1 and nl.position.distance_to(Vector3(p.x, nl.position.y, p.z)) < 0.3, "llega al asiento")
		_comprobar((dl["anim"] as AnimationPlayer).current_animation in ["sentarse", "sentado"], "y se sienta (clip «%s»)" % (dl["anim"] as AnimationPlayer).current_animation)
		gs._llegadas(3.0)
		_comprobar(gs._llegando.is_empty(), "al terminar queda como el resto de sentados")
		## Cuando deja el asiento a la vista, se levanta («levantarse») y se va andando, no desaparece de golpe.
		for v in 12:
			if not gs.ocupado(i_ok):
				break
			gs._eventos.append(p)   ## un autobús que para cerca cambia quién está sentado (hash)
		if not gs.ocupado(i_ok):
			gs.revisar()
			_comprobar(gs._saliendo.size() >= 1 and not gs.cuerpos.has(i_ok), "al quedar libre el asiento a la vista, el ocupante se levanta (saliendo %d, cuerpos %s, estado %s)" % [gs._saliendo.size(), str(gs.cuerpos.has(i_ok)), str(_e.estado)])
			if gs._saliendo.size() >= 1:
				var ds: Dictionary = (gs._saliendo[0] as Dictionary)["d"]
				_comprobar((ds["anim"] as AnimationPlayer).current_animation == "levantarse", "con el clip «levantarse»")
				_comprobar(absf(GenteSentada.raiz_levantarse(0.0, 1.0, 0.2) - 1.45) < 0.001 and absf(GenteSentada.raiz_levantarse(1.0, 1.0, 0.2) - 0.2) < 0.001, "la raíz compensa el clip: sube 0,45 m al empezar y acaba en el suelo")
				gs._salidas(1.1)
				_comprobar((ds["anim"] as AnimationPlayer).current_animation == "caminar", "y echa a andar")
				gs._salidas(12.0)
				_comprobar(gs._saliendo.is_empty(), "se aleja por la acera y desaparece")
	_e.cuerpo.position = p + Vector3(200.0, 0, 0)
	gs.revisar()
	## Esperar con vida (P3, pasada 3): tres variantes y el móvil en la mano.
	_comprobar(PeatonVida.variante(0.1) == 0 and PeatonVida.variante(0.6) == 1 and PeatonVida.variante(0.9) == 2, "la espera tiene tres variantes (móvil, llamada, quieto)")
	var rng_p := RandomNumberGenerator.new()
	rng_p.seed = 5
	var dp := PeatonQ.crear(rng_p)
	if not dp.is_empty():
		add_child(dp["nodo"])
		PeatonQ.terminar(dp)
		var vv := {"nodo": dp["nodo"]}
		PeatonVida.movil(vv, true)
		var esqp: Skeleton3D = FutbolistaQ.esqueleto_de(dp["nodo"])
		_comprobar(esqp != null and esqp.find_child("Movil", false, false) != null, "el móvil cuelga de la mano derecha")
		PeatonVida.movil(vv, true)
		_comprobar(esqp.find_children("Movil", "", false, false).size() == 1, "y no se duplica")
		PeatonVida.movil(vv, false)
		await _frames(1)
		_comprobar(esqp.find_child("Movil", false, false) == null, "al reanudar la marcha se guarda")
		_comprobar(AnimExtra.asegurar(dp["anim"], esqp, "mirar_movil"), "el clip de mirar el móvil existe en el pack")
	## El DT en el sofá: sentarse y quedarse sentado.
	_e._gesto_propio("sentarse", "sentado")
	_comprobar(_e._anim != null and _e._anim.current_animation == "sentarse" and _e._anim.get_queue().has("sentado"), "«sentarse» encadena «sentado»")
	_comprobar(_e._anim != null and _e._anim.get_animation("sentarse").loop_mode == Animation.LOOP_NONE, "y el clip de sentarse no se repite")
	_comprobar(_e._t_gesto_propio > 1000.0, "el gesto dura hasta que te muevas")
	_e._gesto_propio("saludo_mano")
	_comprobar(_e._t_gesto_propio <= 3.0, "un gesto suelto sigue durando lo que su clip")
	PedidoPartida.mundo_pregenerado = null
	PedidoPartida.mundo_a_cargar = null
