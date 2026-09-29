extends Node
## EL CAJÓN DE AJUSTES (25-9-2026, plan maestro B1): partido en vivo de texto y
## transmisión 3D, cada uno con el cajón cerrado y abierto.
##   godot --path . --rendering-driver opengl3 --resolution 1600x900 res://pruebas/captura_cajon_ajustes.tscn
const ESPERA := 10
var _n := 0
var _mundo: Mundo
var _vivo: PartidoVivo
var _vista: VistaEstadio
var _fallos := 0

func _ok(c: bool, t: String) -> void:
	print(("  ok    " if c else "  FALLO ") + t)
	if not c:
		_fallos += 1

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4321)
	_mundo.tomar_el_mando(_mundo.clubes.values()[0].id)

func _process(_d: float) -> void:
	_n += 1
	if _n == ESPERA:
		var par := _mundo.proximo_partido()
		_vivo = PartidoVivo.new()
		_vivo.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_vivo)
		_vivo.abrir(Partido.new(par[0], par[1]), _mundo.mi_club())
		for i in 30:
			_vivo.partido.simular_minuto()
		_vivo.call("_refrescar")
	if _n == ESPERA + 4:
		## `abrir()` pone la vista 3D encima sola: se quita para ver la de texto.
		for h in _vivo.get_children():
			if h is VistaEstadio:
				(h as VistaEstadio).cerrado.emit()
		var c: CajonAjustes = _vivo.get_node("CajonAjustes")
		c.cerrar(false)
	if _n == ESPERA + 6:
		_guardar("res://pruebas/capturas/cajon_vivo_cerrado.png")
		(_vivo.get_node("CajonAjustes") as CajonAjustes).abrir(false)
	if _n == ESPERA + 9:
		_guardar("res://pruebas/capturas/cajon_vivo_abierto.png")
		var c2: CajonAjustes = _vivo.get_node("CajonAjustes")
		c2._quieto = 0.0
		c2._process(CajonAjustes.CIERRE_SOLO + 0.1)
		_ok(not c2.abierto, "el cajón se cierra solo tras %d s sin tocarlo" % int(CajonAjustes.CIERRE_SOLO))
		_vivo.queue_free()
		var par := _mundo.proximo_partido()
		_vista = VistaEstadio.new()
		add_child(_vista)
		_vista.abrir(par[0], 0.85, par[1], Partido.new(par[0], par[1]))
	if _n == ESPERA + 40:
		(_vista.get_node("CajonAjustes") as CajonAjustes).cerrar(false)
	if _n == ESPERA + 43:
		_guardar("res://pruebas/capturas/cajon_3d_cerrado.png")
		(_vista.get_node("CajonAjustes") as CajonAjustes).abrir(false)
	if _n == ESPERA + 46:
		_guardar("res://pruebas/capturas/cajon_3d_abierto.png")
		(_vista.get_node("CajonAjustes") as CajonAjustes).cerrar(false)
		print("===== CAJÓN: %d fallos =====" % _fallos)
		get_tree().quit()

func _guardar(ruta: String) -> void:
	get_viewport().get_texture().get_image().save_png(ruta)
	print("captura: " + ruta)
