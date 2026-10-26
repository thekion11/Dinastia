class_name PcOficina
extends Node
## EL PC DE TU OFICINA (fase 2 del plan del lunes, 26-10-2026): «un PC funcional
## en tu oficina: ahí está el menú central; una tecla lo cierra».
##
## Qué hace: pone un punto de uso delante del escritorio de la «Oficina del DT»
## (un aro que respira en el suelo y el aviso «E: encender el PC»), y al usarlo
## ENCIENDE el menú central de siempre (`escenas/principal.tscn`) como una CAPA
## encima del mundo 3D. El mundo no se destruye: se esconde y se congela (así el
## estadio sigue siendo EL MISMO al levantarte), y la capa lleva un botón
## «Levantarse» y Esc (si Principal no tiene nada modal abierto) para apagarlo.
##
## Principal no sabe que es una capa: arranca con `Principal.mundo_pregenerado`
## como cuando era la escena entera. Por eso el prólogo NO borra esa estática.

signal encendido
signal apagado

const RADIO_USO := 1.6
const CAPA := 50

## La partida que el PC lleva (la de Principal; si dentro se carga otra, esta).
var mundo: Mundo
var mundo_3d: Node            ## lo que se esconde al encender (la vista de la ciudad)
var explorador: Node3D        ## quien se mueve; se congela mientras el PC está encendido
var punto := Vector3.ZERO     ## dónde hay que estar (coordenadas del mundo)
var planta := 1
var abierto := false
var _capa: CanvasLayer
var _principal: Control
var _aro: MeshInstance3D
var _t := 0.0
var _aviso_puesto := false

## `padre3d`: dónde colgar el aro (el mismo padre que el explorador).
func montar(padre3d: Node3D, punto_uso: Vector3, planta_: int) -> void:
	punto = punto_uso
	planta = planta_
	_aro = crear_aro(padre3d, Color(0.35, 0.85, 1.0))
	_aro.position = punto + Vector3(0, 0.04, 0)

## Un aro que respira en el suelo (lo usa también el prólogo para marcar adónde ir).
static func crear_aro(padre3d: Node3D, color: Color) -> MeshInstance3D:
	var aro := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.5
	tm.rings = 32
	aro.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color, 0.75)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aro.material_override = mat
	aro.scale = Vector3(1, 0.06, 1)
	aro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre3d.add_child(aro)
	return aro

## ¿Estás sobre el punto de uso (y en la planta de la oficina)?
func cerca() -> bool:
	if explorador == null or not is_instance_valid(explorador) or abierto:
		return false
	var cuerpo: Node3D = explorador.get("cuerpo")
	if cuerpo == null or int(explorador.get("_planta")) != planta or String(explorador.get("estado")) != "estadio":
		return false
	return Vector2(cuerpo.position.x - punto.x, cuerpo.position.z - punto.z).length() < RADIO_USO

func _process(delta: float) -> void:
	_t += delta
	if is_instance_valid(_aro):
		var k := 1.0 + 0.08 * sin(_t * 3.0)
		_aro.scale = Vector3(k, 0.06, k)
		_aro.visible = not abierto
	## El aviso de la E lo escribe el explorador cada cuadro con lo que tiene
	## delante; cuando no hay nada (texto vacío) y estás sobre el aro, se pone el nuestro.
	if explorador != null and is_instance_valid(explorador):
		var aviso: Label = explorador.get("_aviso")
		if aviso != null:
			if cerca() and aviso.text == "":
				aviso.text = Idiomas.t("E: encender el PC")
				_aviso_puesto = true
			elif _aviso_puesto and not cerca() and aviso.text == Idiomas.t("E: encender el PC"):
				aviso.text = ""
				_aviso_puesto = false

func _unhandled_input(ev: InputEvent) -> void:
	if abierto:
		## Esc apaga el PC solo si el menú central no tiene una capa modal encima
		## (el móvil, un diálogo…): esas se cierran con su propio Esc.
		if ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_ESCAPE \
				and is_instance_valid(_principal) and _principal.has_method("_capa_modal_encima") \
				and not bool(_principal.call("_capa_modal_encima")):
			get_viewport().set_input_as_handled()
			apagar()
		return
	if not cerca():
		return
	var usar := (ev is InputEventKey and (ev as InputEventKey).pressed and not (ev as InputEventKey).echo and (ev as InputEventKey).keycode == KEY_E) \
		or (ev is InputEventJoypadButton and (ev as InputEventJoypadButton).pressed and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_X)
	if usar:
		get_viewport().set_input_as_handled()
		encender()

## Enciende el PC: el menú central como capa; el mundo 3D se esconde y se congela.
## El menú se crea UNA vez y luego solo se enseña o se esconde: así conserva la
## pestaña en la que estabas y no vuelve a «adoptar» la partida (las noticias del
## mundo se conectan una sola vez; una segunda Principal las duplicaría).
func encender() -> void:
	if abierto:
		return
	abierto = true
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	if explorador != null and is_instance_valid(explorador):
		explorador.process_mode = Node.PROCESS_MODE_DISABLED
	if mundo_3d != null and is_instance_valid(mundo_3d):
		mundo_3d.process_mode = Node.PROCESS_MODE_DISABLED
		if mundo_3d is CanvasItem:
			(mundo_3d as CanvasItem).visible = false
	if is_instance_valid(_capa):
		_capa.visible = true
		_capa.process_mode = Node.PROCESS_MODE_INHERIT
		encendido.emit()
		return
	_capa = CanvasLayer.new()
	_capa.layer = CAPA
	add_child(_capa)
	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.03, 0.03)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa.add_child(fondo)
	_principal = (load("res://escenas/principal.tscn") as PackedScene).instantiate() as Control
	_capa.add_child(_principal)
	_principal.set_anchors_preset(Control.PRESET_FULL_RECT)
	## El botón para levantarse, arriba a la derecha, por encima del menú.
	var b := Button.new()
	b.text = Idiomas.t("🚪 Levantarse del PC")
	b.add_theme_font_size_override("font_size", 12)
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = -190
	b.offset_right = -10
	b.offset_top = 6
	b.offset_bottom = 34
	b.tooltip_text = Idiomas.t("Apaga el ordenador y vuelve a la oficina (también Esc).")
	b.pressed.connect(apagar)
	_capa.add_child(b)
	encendido.emit()

## Apaga el PC: el menú central se esconde y se congela (sigue vivo: Principal
## guarda con las reglas de siempre, autoguardado al avanzar la semana) y
## vuelves a la oficina.
func apagar() -> void:
	if not abierto:
		return
	abierto = false
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	## Si dentro se cargó otra partida, al levantarte sigues con esa.
	if is_instance_valid(_principal) and _principal.get("mundo") is Mundo:
		mundo = _principal.get("mundo")
	if is_instance_valid(_capa):
		_capa.visible = false
		_capa.process_mode = Node.PROCESS_MODE_DISABLED
	if mundo_3d != null and is_instance_valid(mundo_3d):
		mundo_3d.process_mode = Node.PROCESS_MODE_INHERIT
		if mundo_3d is CanvasItem:
			(mundo_3d as CanvasItem).visible = true
	if explorador != null and is_instance_valid(explorador):
		explorador.process_mode = Node.PROCESS_MODE_INHERIT
	apagado.emit()

## El menú central encendido (o null): para las pruebas y para quien quiera
## pedirle algo (p. ej. guardar antes de salir del juego).
func principal() -> Control:
	return _principal if abierto and is_instance_valid(_principal) else null
