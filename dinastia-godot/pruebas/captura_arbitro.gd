extends Node
## EL ÁRBITRO EN EL PARTIDO DE VERDAD (26-9-2026): su cámara subjetiva, un
## gesto (ventaja) y la revisión VAR disparada por una decisión arbitral.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_arbitro.tscn
var _mundo: Mundo
var _vista: VistaEstadio
var _n := 0

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	var par := _mundo.proximo_partido()
	var p := Partido.new(par[0], par[1])
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(par[0], 0.85, par[1], p)

func _process(_d: float) -> void:
	_n += 1
	var rig: CameraRig = _vista.get("_rig")
	var juego: MatchPlayback = _vista.get("_juego")
	if rig == null or juego == null:
		return
	if _n == 40:
		var repe: Node = _vista.get("_repe")
		if repe != null and repe.has_method("cortar"):
			repe.call("cortar")
	if _n == 260:
		rig.switch_to(rig.camera_names.find("Árbitro (POV)"))
	if _n == 300:
		get_viewport().get_texture().get_image().save_png("res://pruebas/arbitro_pov.png")
		rig.switch_to(rig.camera_names.find("A ras de campo"))
		var arb = juego.players_by_id.get("arbitro")
		if arb != null:
			rig.objetivo_seguimiento = arb.get("node")
			juego._ejecutar_accion(arb, "arbitro_ventaja", 3.0)
	if _n == 320:
		get_viewport().get_texture().get_image().save_png("res://pruebas/arbitro_gesto.png")
		juego.suceso({"min": 55, "t": "arbitro", "tx": "El árbitro va a revisar la jugada en el VAR"})
	if _n > 322 and _vista.get("_sala_var") != null and (_vista.get("_sala_var") as Node).get("_t") > 2.5:
		get_viewport().get_texture().get_image().save_png("res://pruebas/arbitro_var.png")
		get_tree().quit()
	if _n > 1200:
		get_tree().quit()
