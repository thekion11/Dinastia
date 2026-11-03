class_name AhorroMenu
extends Node
## AHORRO EN LOS MENÚS (3-11-2026, prueba del dueño en su teléfono: el menú a 28 FPS con la GPU al 100 %).
## La pantalla central son ~400 llamadas de dibujo y se repintaba ENTERA en cada fotograma aunque nada cambiara: las
## partículas del fondo («motas», el clima elegido) obligan a redibujar sin parar. En calidad MÍNIMA, mientras no haya
## 3D a la vista (partido, ciudad, estadio): el modo de bajo consumo de Godot (solo repinta cuando algo cambia) y las
## partículas del fondo en pausa. Con 3D a la vista o en MEDIA o más, todo como siempre. Mira cada medio segundo.

const CADA := 0.5
var principal: Node = null
var _t := 0.0
var _ahorrando := false

static func toca() -> bool:
	return Calidad.elegida <= Calidad.MINIMO and DisplayServer.get_name() != "headless"

func _process(delta: float) -> void:
	_t += delta
	if _t < CADA:
		return
	_t = 0.0
	var quiero := toca() and not hay_3d(get_tree().root)
	if quiero != _ahorrando:
		_poner(quiero)

## Hay 3D a la vista si la ventana tiene cámara 3D o algún SubViewportContainer visible muestra una (el retrato
## del jugador en la ficha va en un SubViewport que no se actualiza solo: no cuenta).
static func hay_3d(raiz: Node) -> bool:
	if raiz.get_viewport() != null and raiz.get_viewport().get_camera_3d() != null:
		return true
	for c: Node in raiz.find_children("*", "SubViewportContainer", true, false):
		var svc := c as SubViewportContainer
		if not svc.is_visible_in_tree():
			continue
		for v: Node in svc.get_children():
			var sv := v as SubViewport
			if sv != null and sv.render_target_update_mode == SubViewport.UPDATE_ALWAYS and sv.get_camera_3d() != null:
				return true
	return false

func _poner(si: bool) -> void:
	_ahorrando = si
	OS.low_processor_usage_mode = si
	var clima: Variant = principal.get("_clima") if principal != null else null
	if clima is CPUParticles2D:
		var cp := clima as CPUParticles2D
		if si:
			cp.set_meta("ahorro", true)
			cp.set_meta("emitia", cp.emitting)
			cp.emitting = false
			cp.visible = false
		else:
			cp.remove_meta("ahorro")
			cp.emitting = bool(cp.get_meta("emitia", cp.emitting))
			cp.visible = true

func _exit_tree() -> void:
	if _ahorrando:
		_poner(false)
