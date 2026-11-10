extends Node
## (10-11, «solo club») La casa del personaje a pie SIN ciudad: Menú → «casa» abre `CasaRecorrido` (no la ciudad), se camina de
## verdad (el cuerpo se mueve y las paredes lo frenan), se recorren todas las habitaciones con captura JPG (CASA_CAPTURAS = carpeta; con
## pantalla: xvfb-run + opengl3, 1920x1080) y Esc / E en la puerta de la calle lo cierran.
var _p: Node
var _fallos := 0

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)
	_correr()

func _ok(cond: bool, texto: String) -> void:
	if not cond:
		_fallos += 1
		print("FALLO: ", texto)

func _casa() -> Control:
	for h in _p.get_children():
		var sc := h.get_script() as Script
		if sc != null and String(sc.get_global_name()) == "CasaRecorrido":
			return h
	return null

func _foto(nombre: String) -> void:
	var dir := OS.get_environment("CASA_CAPTURAS")
	if dir == "" or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(dir)
	var img := get_viewport().get_texture().get_image()
	img.save_jpg("%s/%s.jpg" % [dir, nombre], 0.9)

func _correr() -> void:
	for _i in 6:
		await get_tree().process_frame
	_ok(not InterruptorCiudad.activa, "la ciudad debería estar apagada")
	MenuLateral.ejecutar(_p, "casa")
	for _i in 8:
		await get_tree().process_frame
	var c := _casa()
	_ok(c != null, "el menú no abrió la casa a pie")
	if c == null:
		_fin()
		return
	_ok(CasaPlano.sala_en(c.pos2) == "Sala", "se empieza en la sala")
	## Caminar: adelante 1 s avanza.
	var antes: Vector2 = c.pos2
	for _i in 30:
		c.paso(Vector2(0, 1), false, 0.033)
	_ok((c.pos2 - antes).length() > 0.8, "el cuerpo no avanzó caminando")
	## Contra una pared: nunca se llega a atravesarla (la del pasillo, z = 4,8, no tiene hueco en x = 2).
	c.pos2 = Vector2(2.0, 4.0)
	c.rumbo = 0.0
	for _i in 60:
		c.paso(Vector2(0, 1), true, 0.033)
	_ok(c.pos2.y < 4.8 - CasaPlano.RADIO + 0.01, "atravesó la pared de la sala")
	## Las habitaciones, con captura.
	var vistas := [
		["01_sala_entrada", Vector2(1.6, 2.4), PI / 2.0], ["02_sala_tele", Vector2(2.3, 2.0), 1.1],
		["03_cocina", Vector2(8.6, 4.2), PI], ["04_pasillo", Vector2(1.2, 5.5), PI / 2.0],
		["05_dormitorio", Vector2(2.3, 6.9), 0.0], ["06_bano", Vector2(6.5, 6.9), 0.0],
		["07_estudio", Vector2(9.5, 7.0), PI / 2.0], ["08_sala_sofa", Vector2(4.2, 1.2), 0.0],
	]
	for v: Array in vistas:
		c.pos2 = v[1]
		c.rumbo = v[2]
		c.vel = 0.0
		c.paso(Vector2.ZERO, false, 0.0)
		c._colocar_camara(1.0)
		c._rotulos()
		for _i in 6:
			await get_tree().process_frame
		_foto(String(v[0]))
	c.primera_persona = true
	c.pos2 = Vector2(8.6, 4.2)
	c.rumbo = PI
	c.paso(Vector2.ZERO, false, 0.0)
	c._colocar_camara(1.0)
	for _i in 6:
		await get_tree().process_frame
	_foto("09_cocina_primera_persona")
	c.primera_persona = false
	## E junto a la puerta de la calle cierra; lejos no.
	c.pos2 = Vector2(5.0, 2.0)
	c.usar()
	_ok(not c.is_queued_for_deletion(), "E lejos de la puerta no debía salir")
	c.pos2 = Vector2(0.9, 2.4)
	c.usar()
	for _i in 4:
		await get_tree().process_frame
	_ok(_casa() == null, "E junto a la puerta debía cerrar la casa")
	_fin()

func _fin() -> void:
	print("FIN. ", _fallos, " fallos")
	get_tree().quit()
