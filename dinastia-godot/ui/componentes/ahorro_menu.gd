class_name AhorroMenu
extends Node
## AHORRO EN LOS MENÚS (3-11-2026, prueba del dueño en su teléfono: el menú a 28 FPS con la GPU al 100 %).
## La pantalla central son ~400 llamadas de dibujo y se repintaba ENTERA en cada fotograma aunque nada cambiara: las
## partículas del fondo («motas», el clima elegido) obligan a redibujar sin parar. En calidad MÍNIMA (y desde el 10-11 BAJA y MEDIA BAJA), mientras no haya
## 3D a la vista (partido, ciudad, estadio): el modo de bajo consumo de Godot (solo repinta cuando algo cambia) y las
## partículas del fondo en pausa. Con 3D a la vista o en MEDIA o más, todo como siempre. Mira cada medio segundo.

const CADA := 0.5
var principal: Node = null
var _t := 0.0
var _ahorrando := false

## (10-11, informe `rendimiento_movil_2026-11-10.md`) Medido con 3 clubes de 3 países: el menú de BAJA se repintaba entero en cada fotograma (46-51 en 3 s, ~400 llamadas cada uno) y solo ULTRA BAJA ahorraba (1 en 3 s);
## el ahorro vale ahora también en BAJA y MEDIA BAJA (los niveles «ligeros»); MEDIA y superiores siguen como siempre (decisión de diseño de arriba; el dueño decide si MEDIA en móvil también).
static func toca() -> bool:
	return Calidad.elegida <= Calidad.MEDIA_BAJA and DisplayServer.get_name() != "headless"

## ¿Los fondos de los menús van quietos? Con el motor ligero y, desde el 3-11, también en MÍNIMA: un shader con `TIME` (los fondos de pantalla completa, las banderas que ondean, el
## reflejo del logo) obliga a redibujar la pantalla en cada fotograma aunque `low_processor_usage_mode` esté puesto (medido: 92 fotogramas en 3 s con el menú quieto). Quien monta uno
## pregunta aquí y, si toca, pone un color fijo o nada en vez del shader.
static func fondo_estatico() -> bool:
	return Calidad.motor_ligero or toca()

func _process(delta: float) -> void:
	_t += delta
	if _t < CADA:
		return
	_t = 0.0
	var quiero := toca() and not hay_3d(get_tree().root)
	if quiero != _ahorrando:
		_poner(quiero)
	elif quiero:
		_pausar_motas(true)   ## las que se hayan montado después (otra pantalla)

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

static var _quietos: Dictionary = {}
static var _re_tiempo: RegEx = null

## El mismo shader pero congelado (3-11): con `TIME` cambiado por un valor fijo, el shader deja de usar el tiempo y de pedir un repintado por fotograma. Los uniformes son los mismos, así
## que quien le pone parámetros o los anima con un tween no cambia nada. Con los fondos en movimiento (`fondo_estatico()` falso) devuelve el shader tal cual.
static func shader(s: Shader) -> Shader:
	if s == null or not fondo_estatico() or not s.code.contains("TIME"):
		return s
	if not _quietos.has(s):
		if _re_tiempo == null:
			_re_tiempo = RegEx.create_from_string("\\bTIME\\b")
		var q := Shader.new()
		q.code = _re_tiempo.sub(s.code, "(7.3)", true)
		_quietos[s] = q
	return _quietos[s]

## Las motas y el bokeh de las portadas (`FondoParticulas`, grupo «fondo_particulas»): quietas y ocultas mientras se ahorra, como el clima.
func _pausar_motas(si: bool) -> void:
	for n: Node in get_tree().get_nodes_in_group("fondo_particulas"):
		var cp := n as CPUParticles2D
		if cp == null:
			continue
		if si and not cp.has_meta("ahorro"):
			cp.set_meta("ahorro", true)
			cp.set_meta("emitia", cp.emitting)
			cp.emitting = false
			cp.visible = false
		elif not si and cp.has_meta("ahorro"):
			cp.remove_meta("ahorro")
			cp.emitting = bool(cp.get_meta("emitia", cp.emitting))
			cp.visible = true

func _poner(si: bool) -> void:
	_ahorrando = si
	OS.low_processor_usage_mode = si
	_pausar_motas(si)
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
