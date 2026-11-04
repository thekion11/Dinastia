extends Node
## A4 (4-11-2026): capturas con la CÁMARA REAL del partido de un estadio reformado (para revisar a ojo que nada tapa el campo).
##   PERFIL=club|todo|minimo|techo  SALIDA=<carpeta fuera del repo>  herramientas/captura.sh res://pruebas/captura_estadio_reformas.tscn
## Guarda JPG (calidad 90) de las cámaras de transmisión: Transmisión, Principal (TV), Tele Dinámica, Tribuna alta y Detrás del arco.
const CAMARAS := ["Transmis", "Principal", "Tele Din", "Tribuna", "Detras d"]
const ESPERA := 40
const ENTRE := 14

var _n := 0
var _vista: VistaEstadio
var _perfil: Dictionary
var _salida := ""
var _etiqueta := ""
var _ci := 0

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	var m := Mundo.new()
	m.generar(["CHI"], 321)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var club := m.mi_club()
	_perfil = m.perfil_estadio_de(club)
	_etiqueta = OS.get_environment("PERFIL") if OS.get_environment("PERFIL") != "" else "club"
	var techos: Array = m.estadio.opciones("techo")
	var techo := String((techos[techos.size() - 1] as Dictionary).get("clave", "")) if not techos.is_empty() else ""
	match _etiqueta:
		"todo":
			_perfil["niveles"] = 3
			_perfil["aforo"] = 90000
			_perfil["techo"] = techo
			_perfil["pista"] = true
		"minimo":
			_perfil["niveles"] = 1
			_perfil["aforo"] = 3000
		"techo":
			_perfil["techo"] = techo
	_salida = OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "/tmp"
	Azar.sembrar(4242)
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(club, 0.5, m.ligas[0].clubes[1], null, _perfil)

func _process(_d: float) -> void:
	_n += 1
	if _n < ESPERA:
		return
	var t := _n - ESPERA
	if t % ENTRE != 0:
		return
	var i := t / ENTRE
	var rig: CameraRig = _vista.get("_rig")
	if i % 2 == 0:
		var cual := _ci
		if cual >= CAMARAS.size():
			get_tree().quit()
			return
		for k in rig.camera_names.size():
			if String(rig.camera_names[k]).begins_with(CAMARAS[cual]):
				rig.switch_to(k)
				break
	else:
		var img := get_viewport().get_texture().get_image()
		var ruta := "%s/estadio_%s_%d_%s.jpg" % [_salida, _etiqueta, _ci, rig.current_name().replace(" ", "_").replace("(", "").replace(")", "")]
		img.save_jpg(ruta, 0.9)
		print("captura: %s" % ruta)
		_ci += 1
