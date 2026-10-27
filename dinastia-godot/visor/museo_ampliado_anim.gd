class_name MuseoAmpliadoAnim
extends Node3D
## LA ANIMACIÓN DE LA PLANTA NUEVA DEL MUSEO (27-10-2026). La primera vez que la cámara entra en la sala de la planta 3 tras terminar
## la obra, aparece el rótulo «Museo ampliado · N títulos» y las copas se iluminan una a una (`PASO` s cada una). Las veces siguientes
## la sala ya sale encendida. Lo visto se guarda por nivel de museo en los ajustes (`AjustesCiudad`, `museo_ampliado_visto`).
const PASO := 0.15
var copas: Array = []
var sala := Rect2()
var y0 := 0.0
var nivel := 0
var titulos := 0
var _hecho := false

func _ready() -> void:
	if int(AjustesCiudad.valor("museo_ampliado_visto", 0)) >= nivel:
		_encender(copas.size())
		_hecho = true

func _process(_d: float) -> void:
	if _hecho:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var p := to_local(cam.global_position)
	if absf(p.y - y0 - 1.6) < 1.8 and sala.grow(0.1).has_point(Vector2(p.x, p.z)):
		_hecho = true
		AjustesCiudad.guardar("museo_ampliado_visto", nivel)
		_animar()

func _encender(hasta: int) -> void:
	for i in mini(hasta, copas.size()):
		_luz(i, 0.7)

func _luz(i: int, valor: float) -> void:
	var mi := copas[i] as MeshInstance3D
	if is_instance_valid(mi) and mi.material_override is StandardMaterial3D:
		(mi.material_override as StandardMaterial3D).emission_energy_multiplier = valor

func _animar() -> void:
	var cartel := Label3D.new()
	cartel.text = Idiomas.t("Museo ampliado · %d títulos") % titulos
	cartel.font_size = 64
	cartel.pixel_size = 0.004
	cartel.modulate = Color(1.0, 0.86, 0.45, 0.0)
	cartel.no_depth_test = true
	cartel.position = Vector3(sala.get_center().x, y0 + 2.3, sala.get_center().y)
	add_child(cartel)
	var tw := create_tween()
	tw.tween_property(cartel, "modulate:a", 1.0, 0.5)
	for i in copas.size():
		tw.tween_callback(_luz.bind(i, 1.6))
		tw.tween_interval(PASO)
		tw.tween_callback(_luz.bind(i, 0.7))
	tw.tween_interval(1.5)
	tw.tween_property(cartel, "modulate:a", 0.0, 0.8)
	tw.tween_callback(cartel.queue_free)
