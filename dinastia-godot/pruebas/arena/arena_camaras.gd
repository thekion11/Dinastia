class_name ArenaCamaras
extends Control
## LAS CUATRO CÁMARAS DE LA ARENA (3-11): tele, cenital, lateral y a ras de suelo, en una cuadrícula 2×2 sobre EL MISMO mundo 3D
## (cada SubViewport comparte el `World3D` del primero). Teclas: 1-4 = una cámara a pantalla completa, 0 = la cuadrícula.
## `escala` acerca las cuatro (piezas pequeñas: un jugador, el árbitro, el balón).

const NOMBRES := ["TELE", "CENITAL", "LATERAL", "A RAS DE SUELO"]

var viewports: Array[SubViewport] = []
var camaras: Array[Camera3D] = []
var contenedores: Array[SubViewportContainer] = []
var escala := 1.0
var foco := Callable()   ## () -> Vector3: lo que miran
var _rejilla: GridContainer

func montar(cuantas: int, nivel_calidad: int) -> Node3D:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rejilla = GridContainer.new()
	_rejilla.columns = 2
	_rejilla.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rejilla.add_theme_constant_override("h_separation", 2)
	_rejilla.add_theme_constant_override("v_separation", 2)
	add_child(_rejilla)
	var mundo := World3D.new()
	var raiz: Node3D = null
	for i in 4:
		var cont := SubViewportContainer.new()
		cont.stretch = true
		cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cont.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_rejilla.add_child(cont)
		var vp := SubViewport.new()
		vp.world_3d = mundo
		Calidad.aplicar_viewport(vp, nivel_calidad)
		cont.add_child(vp)
		var cam := Camera3D.new()
		cam.far = 700.0
		vp.add_child(cam)
		cam.current = true
		var rotulo := Label.new()
		rotulo.text = NOMBRES[i]
		rotulo.add_theme_font_size_override("font_size", 14)
		rotulo.position = Vector2(8, 4)
		cont.add_child(rotulo)
		viewports.append(vp)
		camaras.append(cam)
		contenedores.append(cont)
		cont.visible = i < cuantas
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if i < cuantas else SubViewport.UPDATE_DISABLED
		if i == 0:
			raiz = Node3D.new()
			vp.add_child(raiz)
	return raiz

func _process(_d: float) -> void:
	var f := foco.call() as Vector3 if foco.is_valid() else Vector3.ZERO
	var k := escala
	## TELE: detrás de la banda, alta, como la cámara de transmisión.
	_poner(0, f + Vector3(0, 22.0 * k + 3.0, -46.0 * k - 4.0), f, 48.0)
	## CENITAL: encima, mirando recto abajo (el «arriba» de la imagen es +Z).
	_poner(1, f + Vector3(0, 70.0 * k + 6.0, 0.01), f, 50.0, Vector3.FORWARD)
	## LATERAL: desde la banda, a media altura.
	_poner(2, f + Vector3(52.0 * k + 5.0, 6.0 * k + 1.5, 0), f + Vector3(0, 1.0, 0), 40.0)
	## A RAS: a la altura de las rodillas, mirando a lo largo del campo.
	_poner(3, f + Vector3(0.0, 0.45, -16.0 * k - 2.0), f + Vector3(0, 0.9, 0), 55.0)

func _poner(i: int, pos: Vector3, mira: Vector3, fov: float, arriba := Vector3.UP) -> void:
	var c := camaras[i]
	c.fov = fov
	c.position = pos
	if pos.distance_to(mira) > 0.05:
		c.look_at(mira, arriba)

func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed):
		return
	var tecla := (e as InputEventKey).keycode
	if tecla == KEY_0:
		_mostrar([0, 1, 2, 3])
	elif tecla >= KEY_1 and tecla <= KEY_4:
		_mostrar([tecla - KEY_1])

func _mostrar(cuales: Array) -> void:
	for i in 4:
		contenedores[i].visible = cuales.has(i)
		viewports[i].render_target_update_mode = SubViewport.UPDATE_ALWAYS if cuales.has(i) else SubViewport.UPDATE_DISABLED
	_rejilla.columns = 2 if cuales.size() > 1 else 1
