extends BaseIdea
## FALLOS DE «CREAR PERSONAJE / CREAR PARTIDA» (2-11-2026, informe del dueño en Windows).
## Se pulsan los botones de verdad (señal `pressed` de cada chip), no se llama a `cambiar` a mano.

func _ready() -> void:
	await get_tree().process_frame
	_titulo("CREAR PARTIDA: elegir modelo de personaje varias veces")
	await _elegir_varias_veces()
	_titulo("CREAR PARTIDA: la cola de la mascota sigue al cuerpo")
	await _cola_mascota()
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
