extends Node
## HOJA DE FUTBOLISTAS CON LA CÁMARA REAL DEL PARTIDO (sesión 12, 11-11). Un partido por ejecución:
##   PAIS=ESP CLUB=5 NIVEL=minimo herramientas/captura.sh res://pruebas/captura_futbolistas.tscn
## Saca la cámara de TV (la real) y, además, dos planos más cercanos de los mismos jugadores para ver
## proporciones, pelo, piel y uniforme. Salida: pruebas/capturas/futbolistas_<PAIS>_<CLUB>_<NIVEL>_<plano>.png
const CALENTAR := 60
var _vista: VistaEstadio
var _n := 0
var _pais := "CHI"
var _club := 0
var _nivel := "alto"

func _ready() -> void:
	_pais = OS.get_environment("PAIS") if OS.get_environment("PAIS") != "" else "CHI"
	_club = int(OS.get_environment("CLUB")) if OS.get_environment("CLUB") != "" else 0
	_nivel = OS.get_environment("NIVEL") if OS.get_environment("NIVEL") != "" else "alto"
	Calidad.elegida = Calidad.ULTRA_BAJA if _nivel == "minimo" else Calidad.ALTA
	var mundo := Mundo.new()
	mundo.generar([_pais], 4711)
	mundo.mi_club_id = mundo.ligas[0].clubes[_club % mundo.ligas[0].clubes.size()].id
	var par := mundo.proximo_partido()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))

func _guardar(plano: String) -> void:
	var ruta := "res://pruebas/capturas/futbolistas_%s_%d_%s_%s.png" % [_pais, _club, _nivel, plano]
	get_viewport().get_texture().get_image().save_png(ruta)

func _process(_d: float) -> void:
	var intro: Variant = _vista.get("_intro")
	if intro != null and is_instance_valid(intro) and intro.activa:
		intro.terminar()
		return
	var cer: Variant = _vista.get("_ceremonia")
	if cer != null and is_instance_valid(cer) and cer.activa:
		cer.terminar()
		return
	_n += 1
	var rig := _vista.get("_rig") as CameraRig
	if _n == 5:
		rig.switch_to(0)
	elif _n == CALENTAR:
		_guardar("tv")
		rig.switch_to(1)
	elif _n == CALENTAR + 20:
		_guardar("cam1")
		rig.switch_to(2)
	elif _n == CALENTAR + 40:
		_guardar("cam2")
		get_tree().quit()
