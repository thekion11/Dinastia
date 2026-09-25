extends Node
## LA COLUMNA MISTERIOSA, EN SUS CONDICIONES EXACTAS (25-9-2026).
##
##   godot --path . --rendering-method gl_compatibility --resolution 1600x900 \
##         res://pruebas/captura_columna_noche.tscn
##
## El LEEME (18-9) la describe así: burbujas translúcidas quietas cerca del
## círculo central, SOLO de noche y en el renderizador Compatibility (web y
## móvil). Aquí se abre un partido de noche y se fotografía con la cámara de
## TV y la cenital, que es la que la pista 2 del LEEME pedía.

var _n := 0
var _vista: VistaEstadio
const CAMARAS := [0, 7]

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4711)
	m.mi_club_id = m.ligas[0].clubes[0].id
	var par := m.proximo_partido()
	var p := Partido.new(par[0], par[1])
	var perfil: Dictionary = (par[0] as Club).perfil_estadio()
	perfil["clima"] = "noche"
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.9, par[1], p, perfil)

func _process(_d: float) -> void:
	_n += 1
	var rig: CameraRig = _vista.get("_rig")
	for k in CAMARAS.size():
		if _n == 20 + k * 20:
			rig.switch_to(CAMARAS[k])
		elif _n == 30 + k * 20:
			get_viewport().get_texture().get_image().save_png("res://pruebas/columna_noche_%d.png" % k)
			print("captura %d (%s)" % [k, rig.current_name()])
	if _n == 30 + CAMARAS.size() * 20:
		get_tree().quit()
