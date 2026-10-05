extends Node
## Verifica al presentador del sorteo con el modelo humano real (14-9-2026,
## pedido "estéticamente deja qué desear el presentador y la animación").
## Captura la pose de pie y el gesto de sacar la bola, en el plano de cámara
## que deja al presentador en primer término (PLANOS[2]).
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##         res://pruebas/captura_sorteo_presentador.tscn

var _n := 0
var _pantalla: Node
var _sorteo: Sorteo
var _escena: SorteoEscena3D

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		var mun = _pantalla.get("mundo")
		var mio: Club = mun.mi_club()
		var liga = mun.liga_de(mio)
		var rival: Club = mio
		for c: Club in liga.clubes:
			if c != mio:
				rival = c
				break
		_sorteo = Sorteo.new()
		_sorteo.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_sorteo)
		_sorteo.abrir_eliminatoria("lib", "CUARTOS DE FINAL", [[mio, rival]], mio)
	if _n == 16:
		## `_sorteo._escena` es el SorteoEscena3D montado en `_construir()`.
		_escena = _sorteo.get("_escena")
		if _escena != null:
			_escena.cortar_plano(2)
	if _n == 30:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/sorteo_presentador_de_pie.png")
		print("de pie capturado, presentador realista: ", _escena.get("_presentador_real") != null)
		if _escena != null:
			_escena.gesto_sacar()
	if _n == 44:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/capturas/sorteo_presentador_gesto.png")
		print("capturado el gesto")
		## Cuántas bolas siguen dentro del cuenco (MEGAPLAN fase 1).
		if _escena != null:
			var bombo: Node3D = _escena.get("_bombo")
			var dentro := 0
			var bolas: Array = _escena.get("_bolas")
			for b: Node3D in bolas:
				var d := b.global_position - bombo.global_position
				if Vector2(d.x, d.z).length() < SorteoEscena3D.RADIO_BOMBO + 0.05 and d.y > -SorteoEscena3D.RADIO_BOMBO - 0.1:
					dentro += 1
			print("BOLAS dentro: %d de %d" % [dentro, bolas.size()])
			for b2: Node3D in bolas.slice(0, 6):
				print("  bola ", b2.global_position - bombo.global_position, " visible=", b2.visible)
		get_tree().quit()
