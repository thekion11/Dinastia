extends Node
## EL HUD Y LA CÁMARA DEL PARTIDO EN EL MÓVIL (4-11-2026, orden del dueño por la líder): MIDE. Simula un teléfono de 400 ppp con 2400×1080 píxeles (lienzo 1600×720 con el escalado del proyecto) con los controles
## táctiles puestos y comprueba: la letra del HUD (≥ 2,5 mm las estadísticas, ≥ 3,2 mm el marcador), que ninguna pieza del HUD tape el stick ni los botones, y la cámara (más cerca del jugador, el jugador ≥ 11 % de la altura
## de la pantalla, el balón dentro de cuadro y la vuelta a la distancia de siempre con el balón lejos). Sin pantalla también corre (no hace capturas).
##   godot --headless --path . res://pruebas/ideas/tac_hud.tscn
var _n := 0
var _ui: CarreraJugadorUI
var _pj: PartidoJugable
var _ct: ControlesTactiles
var _fallos := 0
var _lejos := false
const LIENZO := Vector2(1600, 720)
const VENTANA := Vector2i(2400, 1080)

func _ready() -> void:
	PartidoJugable.con_ceremonia = false
	ControlesTactiles.forzar = true
	ControlesTactiles.dpi_forzado = 400.0
	ControlesTactiles.ventana_forzada = VENTANA
	ControlesTactiles.lienzo_forzado = LIENZO
	AjustesTactil.restaurar()
	CarreraJugadorUI.mundo = null
	_ui = load("res://escenas/carrera_jugador.tscn").instantiate()
	add_child(_ui)

func _comprobar(ok: bool, texto: String) -> void:
	print(("  ok     " if ok else "  FALLO  ") + texto)
	if not ok:
		_fallos += 1

func _rect_de(c: Control) -> Rect2:
	return Rect2(c.global_position, c.size * c.scale)

func _fin() -> void:
	ControlesTactiles.forzar = false
	ControlesTactiles.dpi_forzado = 0.0
	ControlesTactiles.ventana_forzada = Vector2i.ZERO
	ControlesTactiles.lienzo_forzado = Vector2.ZERO
	AjustesTactil.restaurar()
	print("===== FIN. %d fallos =====" % _fallos)
	get_tree().quit(0 if _fallos == 0 else 1)

func _process(_d: float) -> void:
	_n += 1
	if _n == 10:
		_ui._crear()
	if _n == 20:
		var club := _ui.carrera.club(CarreraJugadorUI.mundo)
		var par := _ui._partido_de_la_semana(club)
		_pj = PartidoJugable.abrir(_ui, CarreraJugadorUI.mundo, _ui.carrera, par[0], par[1], 120.0)
		_ct = _pj.get_node_or_null("ControlesTactiles") as ControlesTactiles
		_comprobar(_ct != null, "el partido monta los controles táctiles")
		_pj.size = LIENZO
		_ct.size = LIENZO
	if _n == 40:
		var pmm := HudTactil.px_por_mm(_pj)
		_comprobar(absf(pmm - 10.5) < 0.3, "a 400 ppp y 2400×1080 el lienzo tiene %.1f px por mm (esperado 10,5)" % pmm)
		var fs_stats := _pj._mis_stats.get_theme_font_size("font_size")
		var fs_marc := _pj._marcador.get_theme_font_size("font_size")
		_comprobar(float(fs_stats) / pmm >= 2.5, "la letra de las estadísticas mide %.2f mm (≥ 2,5)" % (float(fs_stats) / pmm))
		_comprobar(float(fs_marc) / pmm >= 3.2, "la letra del marcador mide %.2f mm (≥ 3,2)" % (float(fs_marc) / pmm))
		var nom := (_pj._aguante.get_parent() as VBoxContainer).get_child(0) as Label
		_comprobar(float(nom.get_theme_font_size("font_size")) / pmm >= 2.5, "la letra del nombre del jugador mide %.2f mm (≥ 2,5)" % (float(nom.get_theme_font_size("font_size")) / pmm))
		## Nada del HUD tapa el stick en reposo ni los botones.
		var piezas: Array[Rect2] = []
		for c: Control in _pj._hud:
			if c is PanelContainer:
				piezas.append(_rect_de(c))
		_comprobar(piezas.size() == 3, "el HUD tiene tres cajas (marcador, estadísticas, ficha): %d" % piezas.size())
		var libre := true
		var r_stick := Rect2(_ct.centro_reposo() - Vector2(1, 1) * _ct.radio_stick(), Vector2(2, 2) * _ct.radio_stick())
		for r: Rect2 in piezas:
			if r.intersects(r_stick):
				libre = false
			for nombre: String in ControlesTactiles.BOTONES:
				var cr := _ct.centro_de(nombre)
				var rb := Rect2(cr - Vector2(1, 1) * _ct.radio_de(nombre), Vector2(2, 2) * _ct.radio_de(nombre))
				if r.intersects(rb):
					libre = false
					print("    la caja %s pisa el botón %s" % [r, nombre])
		_comprobar(libre, "ninguna caja del HUD pisa el stick en reposo ni los botones")
		for r: Rect2 in piezas:
			_comprobar(Rect2(Vector2.ZERO, LIENZO).encloses(r), "la caja %s cabe en el lienzo" % r)
	if _n == 130:
		## El jugador que llevas, a 6 m del balón (lo normal en juego: el cambio automático te da al más cercano).
		var m0: MotorJugable = _pj.motor
		(m0.usuario["node"] as Node3D).position = m0.balon.position + Vector3(0, 0, -6.0) * m0.dir_ataque(_pj._es_local_usuario)
		(m0.usuario["node"] as Node3D).position.y = 0.0
	if _n == 220:
		var motor: MotorJugable = _pj.motor
		var yo := motor.pos(motor.usuario)
		var cam: Camera3D = _pj._cam
		var dist := cam.global_position.distance_to(yo)
		_comprobar(CamaraTactil.cercana(_pj), "con controles táctiles la cámara cercana va encendida (auto)")
		_comprobar(dist <= 15.0, "la cámara está a %.1f m del jugador (≤ 15; la de siempre, ≈19,5)" % dist)
		var alto := absf(cam.unproject_position(yo + Vector3(0, 1.8, 0)).y - cam.unproject_position(yo).y)
		var vp3d: Viewport = _pj._vp if _pj._vp != null else _pj.get_viewport()   ## el 3D se dibuja en su propio SubViewport: la altura de la pantalla es la suya
		var alto_pantalla := float(vp3d.size.y) if vp3d is SubViewport else vp3d.get_visible_rect().size.y
		_comprobar(alto / alto_pantalla >= 0.11, "el jugador mide el %.1f %% de la altura de la pantalla (≥ 11 %%)" % (100.0 * alto / alto_pantalla))
		_comprobar(yo.distance_to(motor.balon.position) < 10.0, "el jugador está a %.1f m del balón" % yo.distance_to(motor.balon.position))
		_comprobar(cam.is_position_in_frustum(motor.balon.position), "el balón está dentro de cuadro")
		_comprobar(CamaraTactil.zoom(_pj, motor) < 0.7 and CamaraTactil.peso_balon(_pj, motor) < 0.3, "con el balón cerca la cámara va tensa sobre el jugador (zoom %.2f, peso %.2f)" % [CamaraTactil.zoom(_pj, motor), CamaraTactil.peso_balon(_pj, motor)])
		## Balón LEJOS (33 m, a la espalda del jugador): la cámara sigue al balón y se ve el balón.
		var m1: MotorJugable = _pj.motor
		(m1.usuario["node"] as Node3D).position = m1.balon.position + Vector3(0, 0, -33.0) * m1.dir_ataque(_pj._es_local_usuario)
		(m1.usuario["node"] as Node3D).position.y = 0.0
		_lejos = true
	if _n == 330:
		var m2: MotorJugable = _pj.motor
		var cam2: Camera3D = _pj._cam
		_comprobar(CamaraTactil.lejania(m2) > 0.7, "con el balón lejos la lejanía es %.2f (> 0,7)" % CamaraTactil.lejania(m2))
		_comprobar(cam2.is_position_in_frustum(m2.balon.position), "con el balón lejos del jugador el balón SIGUE dentro de cuadro")
		print("    (el jugador está a %.1f m del balón; en cuadro: %s)" % [m2.pos(m2.usuario).distance_to(m2.balon.position), cam2.is_position_in_frustum(m2.pos(m2.usuario) + Vector3(0, 1.0, 0))])
		## Ajustes: «Nunca» deja la cámara de siempre; «Siempre» la acerca aunque no haya controles.
		_pj.remove_meta("_cam_cercana")
		AjustesTactil.poner_camara("no")
		_comprobar(not CamaraTactil.cercana(_pj), "con la cámara en «Nunca» no se acerca")
		_pj.remove_meta("_cam_cercana")
		AjustesTactil.poner_camara("auto")
		_comprobar(AjustesTactil.camara_cercana(true) and not AjustesTactil.camara_cercana(false), "«Automático»: cercana solo con controles táctiles")
		AjustesTactil.poner_camara("si")
		_comprobar(AjustesTactil.camara_cercana(false), "«Siempre»: cercana aunque no haya controles")
		_fin()
