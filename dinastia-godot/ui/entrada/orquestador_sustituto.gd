extends Control
## SUSTITUTO de una etapa de la entrada (25-10-2026) mientras su pantalla de verdad no
## exista o no cargue (ver `OrquestadorEntrada.crear_pantalla`). Cumple el mismo
## contrato que las pantallas reales para que el flujo funcione siempre: a pantalla
## completa, dice qué etapa es y que se usarán los valores por defecto, y espera la
## confirmación (las etapas son obligatorias y con confirmación, no se saltan solas).
## La intro es la excepción: sin animación de marca no hay nada que enseñar y pasa sola.

signal terminado(datos: Dictionary)
signal volver()

var clave := ""
var titulo := ""
var por_defecto: Dictionary = {}
var _estado: Dictionary = {}

func configurar(estado: Dictionary) -> void:
	_estado = estado

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if clave == "intro":
		## Diferido y por nombre de método: si el orquestador ya la quitó, no se llama.
		call_deferred("confirmar")
		return
	var fondo := ColorRect.new()
	fondo.color = Tema.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", Tema.caja(Tema.PANEL, Tema.RADIO_GRANDE, Tema.BORDE))
	caja.custom_minimum_size = Vector2(560, 0)
	centro.add_child(caja)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	caja.add_child(v)
	var paso := OrquestadorEntrada.ETAPAS.map(func(e: Dictionary) -> String: return String(e["clave"])).find(clave)
	v.add_child(Tema.etiqueta(Tema.TAM_ROTULO, Tema.SUAVE, Idiomas.t("NUEVO JUEGO · PASO %d") % paso))
	v.add_child(Tema.etiqueta(Tema.TAM_TITULO + 6, Tema.ORO, Idiomas.t(titulo)))
	var nota := Tema.etiqueta(Tema.TAM_ROTULO, Tema.TEXTO, Idiomas.t("Esta pantalla todavía está en construcción: se usarán los valores por defecto."))
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nota)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	fila.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(fila)
	var bv := Button.new()
	bv.text = Idiomas.t("Volver")
	bv.custom_minimum_size = Vector2(130, 40)
	bv.pressed.connect(func() -> void: volver.emit())
	fila.add_child(bv)
	var bc := Button.new()
	bc.text = Idiomas.t("Continuar ▶")
	bc.custom_minimum_size = Vector2(160, 40)
	bc.pressed.connect(confirmar)
	fila.add_child(bc)
	## Diferido y solo si sigue en pantalla (el orquestador puede haberla quitado ya).
	(func() -> void:
		if is_instance_valid(bc) and bc.is_inside_tree():
			bc.grab_focus()).call_deferred()

## Lo que haría el botón «Continuar» (las pruebas lo llaman directo).
func confirmar() -> void:
	terminado.emit(por_defecto.duplicate(true))

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		volver.emit()
