extends Node
## (10-11) EL HOMENAJE EN 3D EN EL CAMPO (`HomenajeCampo3D`): monta los homenajeados (el modelo que juega) con su camiseta retirada. Necesita pantalla:
## xvfb-run -a godot --path . --rendering-driver opengl3 res://pruebas/prueba_homenaje3d.tscn   (CAPTURAR=<carpeta> guarda homenaje3d.jpg)
var _n := 0
var _h: HomenajeCampo3D

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 7)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var club := m.mi_club()
	var filas: Array = [{"j": club.plantilla[3], "dorsal": 10}, {"j": club.plantilla[5], "dorsal": 7}]
	_h = HomenajeCampo3D.montar(filas, Color(club.color1), Color(club.color2))
	if _h == null:
		print("sin pantalla: no se monta"); print("FIN. 1 fallos"); get_tree().quit(); return
	_h.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_h)

func _process(_d: float) -> void:
	_n += 1
	if _n == 40:
		var ok := _h.figuras == 2
		print("se montan los 2 homenajeados en 3D (%d): %s" % [_h.figuras, ok])
		var dir := OS.get_environment("CAPTURAR")
		if dir != "":
			get_viewport().get_texture().get_image().save_jpg(dir.path_join("homenaje3d.jpg"), 0.9)
		print("FIN. %d fallos" % (0 if ok else 1))
		get_tree().quit()
