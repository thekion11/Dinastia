extends BaseIdea
## FALLOS DE «CREAR PERSONAJE / CREAR PARTIDA» (2-11-2026, informe del dueño en Windows).
## Se pulsan los botones de verdad (señal `pressed` de cada chip), no se llama a `cambiar` a mano.

func _ready() -> void:
	await get_tree().process_frame
	_titulo("CREAR PARTIDA: elegir modelo de personaje varias veces")
	await _elegir_varias_veces()
	_titulo("CREAR PARTIDA: la cola de la mascota sigue al cuerpo")
	await _cola_mascota()
	_titulo("CREAR PARTIDA: el escudo propio sale en la camiseta 2D")
	_escudo_en_camiseta()
	_titulo("CREAR PARTIDA: vestir dos veces cambia el uniforme del 3D")
	await _vestir_dos_veces()
	_titulo("CREAR PARTIDA: modelos base extra")
	await _modelos_base()
	_titulo("PRÓLOGO: el mentor no aparece dentro de arbustos ni setos")
	await _mentor_sin_solape()
	_titulo("CREAR PARTIDA: símbolo del escudo horneado")
	_simbolo_horneado()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

func _esperar_s(s: float) -> void:
	await get_tree().create_timer(s).timeout
	await get_tree().process_frame

## Los botones (chips) de una hoja cuyo texto sea `texto`.
func _chip(raiz: Node, texto: String) -> Button:
	for n in raiz.find_children("*", "Button", true, false):
		var b := n as Button
		if b.text == texto and b.is_visible_in_tree():
			return b
	return null

func _elegir_varias_veces() -> void:
	var m := _mundo(777)
	var raiz := Control.new()
	raiz.size = Vector2(1600, 900)
	add_child(raiz)
	var pp := PantallaPersonaje.new()
	pp.configurar({"pais": "ARG", "club": m.mi_club(), "paso": 6})
	raiz.add_child(pp)
	await _esperar_s(0.5)
	var hojas: HojasPersonaje = pp.get("_hojas")
	var est: EstudioPersonaje = pp.get("_estudio")
	for ronda in 3:
		for par: Array in [["Mujer", "female"], ["Hombre", "male"]]:
			var b := _chip(hojas, Idiomas.t(String(par[0])))
			_comprobar(b != null, "ronda %d: existe el botón «%s»" % [ronda, par[0]])
			if b == null:
				continue
			b.pressed.emit()
			await _esperar_s(0.5)
			_comprobar(String(hojas.asp["cuerpo"]) == String(par[1]), "ronda %d: elegir %s cambia el aspecto" % [ronda, par[0]])
			_comprobar(String(est.modelo().get("cuerpo", "")) == String(par[1]), "ronda %d: el 3D muestra %s" % [ronda, par[0]])
	raiz.queue_free()
	await _esperar_s(0.2)

## La cola cuelga de la pelvis: tras gesticular y pasear, sigue a menos de 35 cm de ella (antes se quedaba
## flotando en el sitio donde nació).
func _cola_mascota() -> void:
	var m := _mundo(778)
	var raiz := Node3D.new()
	add_child(raiz)
	var club := m.mi_club()
	for animal: String in MascotaQ.ANIMALES:
		var masc := MascotaQ.crear(raiz, club, animal, Vector3.ZERO, 0.0)
		_comprobar(masc != null, "%s: se arma" % animal)
		if masc == null:
			continue
		var ctl := masc.get_node("Animador") as MascotaQ
		var esq := ctl._esq
		var peor := 0.0
		for i in 400:
			ctl._process(0.1)
			await get_tree().process_frame
			ctl._process(0.0)
			var pelvis := (esq.global_transform * esq.get_bone_global_pose(ctl._i_pelvis)).origin
			peor = maxf(peor, (masc.get_node("ColaSoporte") as Node3D).global_position.distance_to(pelvis))
		_comprobar(peor < 0.35, "%s: la cola no se separa de la pelvis (máx. %.2f m)" % [animal, peor])
		masc.queue_free()
	raiz.queue_free()

## La camiseta 2D lleva el escudo del club (antes solo un escudete genérico).
func _escudo_en_camiseta() -> void:
	var c := _mundo(779).mi_club()
	var kit := DisenosKit.kit_de_club(c)
	kit["sp"] = {}
	var con := DisenosKit.textura_completa(kit, false, 200).get_image()
	var sin_kit := kit.duplicate()
	sin_kit.erase("escudo_tex")
	var sin := DisenosKit.textura_completa(sin_kit, false, 200).get_image()
	_comprobar(kit.get("escudo_tex") is Texture2D, "el kit del club trae su escudo")
	_comprobar(con.get_data() != sin.get_data(), "la camiseta de frente cambia con el escudo puesto")
	var kit_e := kit.duplicate()
	var esp_con := DisenosKit.textura_completa(kit_e, true, 200).get_image()
	var esp_sin := DisenosKit.textura_completa(sin_kit, true, 200).get_image()
	_comprobar(esp_con.get_data() == esp_sin.get_data(), "y de espaldas no lleva escudo")

## Antes, tras el primer vestido el cuerpo ya no se reconocía (su material activo era el del shader) y el
## diseñador no repintaba el uniforme ni los botines del jugador 3D.
func _vestir_dos_veces() -> void:
	var raiz := Node3D.new()
	add_child(raiz)
	var d := FutbolistaQ.crear(1.8, "male")
	raiz.add_child(d["nodo"])
	FutbolistaQ.terminar(d, true)
	var kit1 := DisenosKit.kit_de_club(_mundo(780).mi_club()).duplicate(true)
	var kit2 := kit1.duplicate(true)
	kit2["cols"] = ["ff00ff", "00ffff", "123456", "ffffff", "111111"]
	_comprobar(VestidorQ.vestir_equipacion(d, Color("ff0000"), Color("0000ff"), "liso", Color("c68d68"), Color(0.1, 0.1, 0.1), Color(0, 0, 0, 0), Color(0, 0, 0, 0), false, kit1, 10), "primer vestido")
	_comprobar(VestidorQ.vestir_equipacion(d, Color("ff00ff"), Color("00ffff"), "liso", Color("c68d68"), Color(0.1, 0.1, 0.1), Color(0, 0, 0, 0), Color(0, 0, 0, 0), false, kit2, 10), "segundo vestido (otro uniforme)")
	raiz.queue_free()

func _simbolo_horneado() -> void:
	var c := _mundo(781).mi_club()
	c.esc_simbolo = ""
	var sin := EscudoTexto.textura(c, 64)
	c.esc_simbolo = "⭐"
	var con := EscudoTexto.textura(c, 64)
	_comprobar(sin != null and con != null and con.get_image().get_data() != sin.get_image().get_data(), "con símbolo el escudo cambia (queda pintado en la imagen)")

## Los modelos base elegibles (solo realistas: civiles modulares y, si está, el avatar regalo) cargan y están vivos.
## Los quitados (fantasía, anime) ya no se ofrecen y una partida vieja con uno cae al atleta.
func _modelos_base() -> void:
	var raiz := Node3D.new()
	add_child(raiz)
	for quitado: String in ["campesino", "explorador", "kk_barbaro", "kk_mago", "vrm_arla", "mh_farmer", "mm_witch"]:
		_comprobar(not FutbolistaQ.modelo_valido(quitado), "%s: ya no es un modelo válido" % quitado)
		_comprobar(String(PersonajeDT.aspecto({"modelo": quitado})["modelo"]) == "", "%s: una partida vieja cae al atleta" % quitado)
	if AvatarRegalo.disponible():
		var dr := PersonajeDT.crear(raiz, {"modelo": AvatarRegalo.CLAVE, "altura": 1.8})
		_comprobar(not dr.is_empty() and dr.has("avatar") and dr.has("anim"), "avatar regalo: se arma con el motor de animación del juego")
		if not dr.is_empty():
			(dr["nodo"] as Node).queue_free()
	for k: String in FutbolistaQ.todos_ajenos():
		_comprobar(FutbolistaQ.ajeno_disponible(k), "%s: está en el juego" % k)
		var da := PersonajeDT.crear(raiz, {"modelo": k, "altura": 1.8})
		var ap: AnimationPlayer = da.get("anim")
		var vivo := ap != null and ap.current_animation != ""
		if not vivo and not da.is_empty():
			vivo = (da["nodo"] as Node).find_children("*", "Node", true, false).any(func(n: Node) -> bool: return n is IdleProcedural)
		_comprobar(not da.is_empty() and vivo, "%s: se arma y está vivo (clip o reposo procedural)" % k)
		if not da.is_empty():
			(da["nodo"] as Node).queue_free()
	raiz.queue_free()

## Geometría pura (sin GPU): se construye el prólogo y se comprueba que el mentor, tras colocarse en la
## puerta y en cada sala, no queda dentro de ninguna caja de seto, jardinera o arbusto.
func _mentor_sin_solape() -> void:
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4242)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	PedidoPartida.mundo_pregenerado = m
	PedidoPartida.modo_elegido = "dt"
	PrologoDT.rapido = true
	var p: PrologoDT = (load("res://escenas/prologo.tscn") as PackedScene).instantiate()
	add_child(p)
	for i in 600:
		await get_tree().process_frame
		if p._listo:
			break
	_comprobar(p._listo, "el prólogo se construyó")
	var cajas := PrologoMentor.obstaculos
	print("  obstáculos blandos cerca de la puerta: ", cajas.size())
	var puntos: Array[Vector3] = [p.puerta + Vector3(0.8, 0.02, 3.0), p.puerta + Vector3(0, 0, 7.0), p.puerta + Vector3(-0.8, 0.02, 3.0), p.puerta + Vector3(2.5, 0.02, 2.0)]
	for pt: Vector3 in puntos:
		var q := PrologoMentor.fuera_de_obstaculos(pt)
		var dentro := false
		for a: AABB in cajas:
			var b := a.grow(0.2)
			if q.x > b.position.x and q.x < b.end.x and q.z > b.position.z and q.z < b.end.z and q.y + 1.8 > b.position.y and q.y < b.end.y:
				dentro = true
		_comprobar(not dentro, "punto %s queda fuera de los obstáculos blandos" % str(pt))
	var mp := p.mentor.position
	_comprobar(PrologoMentor.fuera_de_obstaculos(mp).is_equal_approx(mp), "el mentor ya está colocado fuera de todo obstáculo")
	p.queue_free()
	PrologoDT.rapido = false
	await get_tree().process_frame
