extends Node
## Cámara de transmisión del partido real, para revisar las equipaciones.
##   SUFIJO=antes herramientas/captura.sh res://pruebas/captura_camisetas_tv.tscn
var _n := 0
var _vista: VistaEstadio
var _fotos := 0

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
	cfg.save(CajonAjustes.RUTA)
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)

func _process(_d: float) -> void:
	_n += 1
	if _n in [80, 160]:
		_fotos += 1
		var rig: CameraRig = _vista.get("_rig")
		get_viewport().get_texture().get_image().save_png("res://pruebas/capturas/camisetas_tv_%s_%d.png" % [OS.get_environment("SUFIJO"), _fotos])
		print("FOTO ", _fotos, " cámara ", rig.current_name())
	if _n > 170:
		var cfg := ConfigFile.new()
		cfg.load(CajonAjustes.RUTA)
		cfg.set_value(CajonAjustes.SECCION, "ceremonia", true)
		cfg.set_value(CajonAjustes.SECCION, "intro", true)
		cfg.save(CajonAjustes.RUTA)
		get_tree().quit()
