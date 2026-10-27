extends Node
## BUTACAS Y AFICIONADOS (27-10-2026): tres vistas del estadio del partido (calidad ALTO, 85 % de grada):
##   0 = desde el borde del césped a las butacas bajas (la cámara de TV pasa por aquí),
##   1 = plano alto lateral de TV, 2 = la parte alta de una tribuna (vomitorios y pasillos).
## Salen en $PREFIJO_N.png (por defecto /tmp/butacas).
##   PREFIJO=/tmp/butacas_antes xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 res://pruebas/captura_butacas.tscn
var _n := 0
var _vista: VistaEstadio
var _cam: Camera3D
const VISTAS := [[Vector3(-26, 2.4, -6), Vector3(46, 4.5, 0)], [Vector3(-60, 22, 8), Vector3(30, 4, -4)], [Vector3(14, 9, -54), Vector3(8, 10, -70)]]
const POR_VISTA := 16

func _ready() -> void:
	Calidad.elegida = Calidad.ALTO
	AjustesCiudad.guardar("tutorial_visto", true)
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
	_cam = Camera3D.new()
	_cam.far = 600.0
	add_child(_cam)

func _process(_d: float) -> void:
	_n += 1
	if _n < 20:
		return
	for cl in get_tree().root.find_children("*", "CanvasLayer", true, false):
		(cl as CanvasLayer).visible = false
	var k := (_n - 20) / POR_VISTA
	var f := (_n - 20) % POR_VISTA
	if k >= VISTAS.size():
		print("FIN. 0 fallos")
		get_tree().quit()
		return
	_cam.make_current()
	_cam.position = VISTAS[k][0]
	_cam.look_at(VISTAS[k][1], Vector3.UP)
	if f == POR_VISTA - 2:
		var pref := OS.get_environment("PREFIJO") if OS.get_environment("PREFIJO") != "" else "/tmp/butacas"
		get_viewport().get_texture().get_image().save_png("%s_%d.png" % [pref, k])
		print("FOTO ", pref, "_", k)
