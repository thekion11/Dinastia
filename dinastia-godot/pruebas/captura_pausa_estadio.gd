extends Node
## LA PAUSA DEL PARTIDO, DENTRO DEL ESTADIO REAL (17-11, pedido de «Auditoría de sesiones»): el partido congelado detrás, desenfocado y oscurecido,
## con la cámara real. PAIS=ESP (por defecto CHI). Salida: pruebas/capturas/pausa_estadio_<país>.png (JPG con captura.sh).
##   RESOLUCION=1600x900 herramientas/captura.sh res://pruebas/captura_pausa_estadio.tscn
var _vista: VistaEstadio
var _n := 0
var _pais := "CHI"

func _ready() -> void:
	Calidad.elegida = Calidad.MEDIO
	_pais = OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	var cfg := ConfigFile.new()
	cfg.load(CajonAjustes.RUTA)
	cfg.set_value(CajonAjustes.SECCION, "ceremonia", false)
	cfg.set_value(CajonAjustes.SECCION, "intro", false)
	cfg.save(CajonAjustes.RUTA)
	var m := Mundo.new()
	m.generar([_pais], 5300 + _pais.hash() % 100)
	m.mi_club_id = m.ligas[0].clubes[3].id
	Partido.ctx_club_id = m.mi_club_id
	var par := m.proximo_partido()
	var partido := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], partido)

func _process(_d: float) -> void:
	if _vista.get("_motor") == null:
		return
	_n += 1
	if _n == 120:
		var p: Partido = _vista.partido
		p.minuto = 58
		_vista.abrir_pausa()
	elif _n == 132:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://pruebas/capturas"))
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://pruebas/capturas/pausa_estadio_%s.png" % _pais))
		print("FOTO pausa_estadio_%s · pausa abierta: %s" % [_pais, str(_vista.get("_pausa_menu") != null)])
		get_tree().quit()
