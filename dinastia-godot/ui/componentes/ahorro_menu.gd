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
	return (nivel_ahorra(Calidad.elegida, Calidad.ahorro_menu_media) or EstiloMundo.suave) and DisplayServer.get_name() != "headless"   ## (15-11) el Mundo suave ahorra en todas las calidades

## (10-11) De MEDIA BAJA hacia abajo siempre; MEDIA solo si el jugador lo pide en Ajustes (`ahorro_menu_media`); ALTA y superiores nunca.
static func nivel_ahorra(nivel: int, media_pedida: bool) -> bool:
	return nivel <= Calidad.MEDIA_BAJA or (media_pedida and nivel <= Calidad.MEDIO)

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
	## (15-11, meta del dueño: «máximo 2 dibujados con la pantalla quieta, salvo que el usuario haga algo») En el Mundo clásico, tras
	## `REPOSO_S` sin tocar nada, también se ahorra: partículas en pausa y shaders con TIME congelados en su instante (sin salto).
	var quieto := (Time.get_ticks_msec() - _ultima_entrada) / 1000.0 > REPOSO_S and DisplayServer.get_name() != "headless"
	var quiero := (toca() or quieto) and not hay_3d(get_tree().root)
	if quiero != _ahorrando:
		_poner(quiero)
	elif quiero:
		_pausar_motas(true)   ## las que se hayan montado después (otra pantalla)
		_congelar_shaders(not fondo_estatico())   ## y los shaders de lo que se abrió después (15-11)

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
		_pausar_una(n as CPUParticles2D, si)

## (15-11) En el reposo del Mundo clásico las partículas se QUEDAN QUIETAS donde están (proceso apagado: sin moverse ni pedir dibujo);
## en el ahorro de siempre (calidad ligera, Mundo suave) se apagan y se ocultan, como hasta ahora.
func _pausar_una(cp: CPUParticles2D, si: bool) -> void:
	if cp == null or si == cp.has_meta("ahorro"):
		return
	if si:
		cp.set_meta("ahorro", true)
		if toca():
			cp.set_meta("emitia", cp.emitting)
			cp.emitting = false
			cp.visible = false
		else:
			cp.set_meta("modo_proceso", cp.process_mode)
			cp.process_mode = Node.PROCESS_MODE_DISABLED
		return
	cp.remove_meta("ahorro")
	if cp.has_meta("modo_proceso"):
		cp.process_mode = cp.get_meta("modo_proceso")
		cp.remove_meta("modo_proceso")
	else:
		cp.emitting = bool(cp.get_meta("emitia", cp.emitting))
		cp.visible = true

const REPOSO_S := 3.0
var _ultima_entrada := 0
var _congelados: Array = []   ## [material, shader original] de los que se congelaron por reposo

## Cualquier tecla, botón, toque o movimiento del ratón: vuelve el movimiento al momento (si el ahorro era por reposo).
func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion or e is InputEventMouseButton or e is InputEventKey or e is InputEventScreenTouch or e is InputEventScreenDrag or e is InputEventJoypadButton:
		_ultima_entrada = Time.get_ticks_msec()
		if _ahorrando and not toca():
			_poner(false)

## Congela (o devuelve) los shaders con TIME de lo que se ve: el congelado lee un uniforme fijado al instante actual, así no salta.
func _congelar_shaders(si: bool) -> void:
	if not si or not _ahorrando:
		for par: Array in _congelados:
			if is_instance_valid(par[0]):
				(par[0] as ShaderMaterial).shader = par[1]
		_congelados.clear()
		return
	var t := fmod(Time.get_ticks_msec() / 1000.0, float(ProjectSettings.get_setting("rendering/limits/time/time_rollover_secs", 3600)))
	for c in get_tree().root.find_children("*", "CanvasItem", true, false):
		var m := (c as CanvasItem).material as ShaderMaterial
		if m == null or m.shader == null or not (c as CanvasItem).is_visible_in_tree() or not m.shader.code.contains("TIME") or _quietos_t.values().has(m.shader) or m.has_meta("no_congelar"):
			continue
		var q := _quieto_en(m.shader)
		if q == null:
			continue
		_congelados.append([m, m.shader])
		m.shader = q
		m.set_shader_parameter("_t_quieto", t)

static var _quietos_t: Dictionary = {}
static func _quieto_en(s: Shader) -> Shader:
	if not _quietos_t.has(s):
		if _re_tiempo == null:
			_re_tiempo = RegEx.create_from_string("\\bTIME\\b")
		var codigo := _re_tiempo.sub(s.code, "_t_quieto", true)
		var fin := codigo.find(";")
		if fin < 0:
			return null
		var q := Shader.new()
		q.code = codigo.substr(0, fin + 1) + "\nuniform float _t_quieto;\n" + codigo.substr(fin + 1)
		_quietos_t[s] = q
	return _quietos_t[s]

func _poner(si: bool) -> void:
	_ahorrando = si
	OS.low_processor_usage_mode = si
	_pausar_motas(si)
	_congelar_shaders(si and not fondo_estatico())
	var clima: Variant = principal.get("_clima") if principal != null else null
	if clima is CPUParticles2D:
		_pausar_una(clima as CPUParticles2D, si)

func _exit_tree() -> void:
	_congelar_shaders(false)
	if _ahorrando:
		_poner(false)
