extends Node
## SONDA (borrar al acabar): la rueda en cada contexto. MODO=liga|copa|titulo
## (por Principal) o general|previa (el plató solo, sin interfaz).
var _n := 0
var _pantalla: Node
var _esc: Node
var _modo := OS.get_environment("MODO")

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	var mundo: Mundo = _pantalla.get("mundo")
	if _n == 14:
		var mio := mundo.mi_club()
		if _modo in ["general", "previa"]:
			var vc := SubViewportContainer.new()
			vc.stretch = true
			vc.set_anchors_preset(Control.PRESET_FULL_RECT)
			var capa := CanvasLayer.new()
			capa.layer = 50
			add_child(capa)
			capa.add_child(vc)
			var vp := SubViewport.new()
			vp.own_world_3d = true
			vc.add_child(vp)
			_esc = RuedaPrensaEscena3D.new()
			vp.add_child(_esc)
			var rival: Club = mundo.liga_de(mio).clubes[1]
			_esc.montar(mio, Color(0.3, 0.6, 0.4), Calidad.ALTO, {}, [], {"tipo": _modo, "rival": rival})
		else:
			mundo.prensa.competicion_rueda = "liga" if _modo == "liga" else "copa"
			if _modo != "liga":
				if mundo.copa == null:
					mundo.call("_montar_copa")
				if _modo == "titulo":
					mundo.copa.campeon = mio
			mundo.prensa.abrir_rueda(true, false)
			_pantalla.call("_abrir_rueda_pantalla_completa", mundo.prensa.entrevista)
			_esc = _pantalla.get("_rueda_pop").get("_escena")
	if _n > 14 and _n <= 60 and _esc != null:
		if _pantalla.get("_rueda_pop") != null:
			_pantalla.set("_rueda_desde", Time.get_ticks_msec() - 4000)
		_esc.set("_t", 1.0)
		_esc.set("_t_foco", 0.0)
	if _n == 60:
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/rp_ctx_%s.png" % _modo)
		get_tree().quit()
