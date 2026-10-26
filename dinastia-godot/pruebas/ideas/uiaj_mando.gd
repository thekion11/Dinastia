extends BaseIdea
## uiaj · EL MANDO DE LA PANTALLA DE CONTROLES SE REPINTA SOLO CUANDO CAMBIA ALGO.
## Antes `DibujoMando` copiaba sus datos al mando 3D en cada `_process` y el mando 3D
## pedía `queue_redraw()` (y renderizaba su SubViewport) en todos los fotogramas,
## aunque nadie lo tocara. Ahora van por setters: se cuenta la señal `draw` de cada
## lienzo con el mando quieto (0) y al cambiar etiquetas, vista o teclas (≥ 1).

var _n_dibujo := 0
var _n_capa := 0

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
	_titulo("uiaj: el mando dibujado se repinta solo al cambiar")
	var raiz := Control.new()
	raiz.size = Vector2(460, 420)
	add_child(raiz)
	var d := DibujoMando.new()
	d.size = Vector2(460, 420)
	raiz.add_child(d)
	d.dispositivo = "xbox"
	d.etiquetas = {"A": "Pase", "B": "Tiro", "LS": "Moverse"}
	await _frames(6)
	var g: MandoGiratorio = d._giratorio
	_comprobar(g != null and g._capa != null, "el mando 3D tiene su capa de etiquetas encima del 3D")
	if g == null or g._capa == null:
		return
	_comprobar(g._capa.get_index() > g.get_child(1).get_index(), "la capa de etiquetas va después (encima) del SubViewportContainer")
	d.draw.connect(func() -> void: _n_dibujo += 1)
	g._capa.draw.connect(func() -> void: _n_capa += 1)
	_comprobar(not d.is_processing(), "con el mando (no teclado) DibujoMando no procesa cada fotograma")

	## 1) Quieto y sin nada elegido: ni un repintado en 10 fotogramas.
	_n_dibujo = 0
	_n_capa = 0
	await _frames(10)
	_comprobar(_n_capa == 0 and _n_dibujo == 0, "quieto no se repinta (capa %d, dibujo %d en 10 fotogramas)" % [_n_capa, _n_dibujo])
	_comprobar(g._vp.render_target_update_mode != SubViewport.UPDATE_ALWAYS, "el 3D del mando no se renderiza en cada fotograma")

	## 2) Cambian las etiquetas: se repinta.
	_n_capa = 0
	d.etiquetas = {"A": "Pase raso", "B": "Tiro", "LS": "Moverse"}
	await _frames(3)
	_comprobar(_n_capa >= 1, "al cambiar las etiquetas se repinta (%d)" % _n_capa)
	_n_capa = 0
	await _frames(6)
	_comprobar(_n_capa == 0, "y después vuelve a estar quieto (%d)" % _n_capa)

	## 3) Se ilumina una pieza: el 3D late (si las animaciones no van reducidas),
	## pero las etiquetas no se repintan en cada fotograma.
	d.iluminadas = ["A"]
	await _frames(2)
	var mats: Array = g._piezas["A"]["mats"] if g._piezas.has("A") else []
	_comprobar(not mats.is_empty() and (mats[0] as StandardMaterial3D).emission_energy_multiplier > 0.0, "la pieza elegida se enciende")
	_n_capa = 0
	var e0 := (mats[0] as StandardMaterial3D).emission_energy_multiplier if not mats.is_empty() else 0.0
	await _frames(8)
	var e1 := (mats[0] as StandardMaterial3D).emission_energy_multiplier if not mats.is_empty() else 0.0
	if Animar.reducidas():
		_comprobar(is_equal_approx(e0, e1), "con animaciones reducidas la pieza no late")
	else:
		_comprobar(not is_equal_approx(e0, e1), "la pieza late (%.3f → %.3f)" % [e0, e1])
	_comprobar(_n_capa == 0, "el latido no repinta las etiquetas (%d)" % _n_capa)
	d.iluminadas = []
	await _frames(2)
	_comprobar(not mats.is_empty() and is_zero_approx((mats[0] as StandardMaterial3D).emission_energy_multiplier), "al quitarla se apaga")

	## 4) Girar el mando sí repinta las etiquetas (siguen a cada botón).
	_n_capa = 0
	g.mirar(PI, 0.3)
	await _frames(6)
	_comprobar(_n_capa >= 3, "al girarlo las etiquetas lo siguen (%d repintados)" % _n_capa)

	## 5) El teclado: se pinta al cambiar y late solo con teclas elegidas.
	d.dispositivo = "teclado"
	await _frames(2)
	_comprobar(not g.visible, "en modo teclado el mando 3D se oculta")
	_n_dibujo = 0
	await _frames(8)
	_comprobar(_n_dibujo == 0, "el teclado sin teclas elegidas no se repinta (%d)" % _n_dibujo)
	d.etiquetas = {str(KEY_W): "Moverse"}
	await _frames(2)
	_comprobar(_n_dibujo >= 1, "al cambiar sus etiquetas se repinta solo, sin que quien llama tenga que pedir queue_redraw()")
	_n_dibujo = 0
	d.teclas_iluminadas = [KEY_W]
	await _frames(6)
	if Animar.reducidas():
		_comprobar(_n_dibujo >= 1 and _n_dibujo <= 2, "con animaciones reducidas la tecla elegida no late (%d)" % _n_dibujo)
	else:
		_comprobar(_n_dibujo >= 5, "la tecla elegida late: se repinta cada fotograma (%d)" % _n_dibujo)
	d.teclas_iluminadas = []
	await _frames(2)
	_n_dibujo = 0
	await _frames(6)
	_comprobar(_n_dibujo == 0, "sin teclas elegidas deja de repintarse (%d)" % _n_dibujo)

	## 6) Los nombres de las teclas, legibles y no en inglés.
	_comprobar(Mando.nombre_tecla(KEY_UP) == "↑" and Mando.nombre_tecla(KEY_LEFT) == "←", "las flechas se escriben como flechas, no «Up»/«Left»")
	_comprobar(Mando.nombre_tecla(KEY_SPACE) == Idiomas.t("Espacio") and Mando.nombre_tecla(KEY_SPACE) != "Space", "el espacio se traduce")
	_comprobar(DibujoMando.nombre_tecla(KEY_KP_8, true) == "8" and DibujoMando.nombre_tecla(KEY_KP_8, false) == "Num 8", "el teclado numérico: «8» en la tecla, «Num 8» en la leyenda")
	raiz.queue_free()
