extends Node
## Verifica a ojo la pantalla con contenido de verdad (22-9-2026, pedido
## directo del usuario: "esa pantalla azul puede mejorarse"). Antes era un
## rectangulo de un solo color liso; ahora trae un degradado con los colores
## del club + el escudo centrado.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_pantalla_estadio.tscn

var _vista: VistaEstadio
var _mundo: Mundo
var _frame := 0
var _cam2: Camera3D

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4711)
	_mundo.mi_club_id = _mundo.ligas[0].clubes[0].id
	var mio := _mundo.mi_club()
	_vista = VistaEstadio.new()
	add_child(_vista)
	_vista.abrir(mio, 0.85)
	print("club: %s (colores %s/%s)" % [mio.nombre, mio.color1, mio.color2])

	## La pantalla vive en `Vector3(0, alto-1.0, dz-6.0)` -ver `_pantallas()`-,
	## con dz=68 (cuenco) y alto~19.5 (3 niveles). Camara desde la cancha,
	## mirando hacia arriba y al frente de la pantalla.
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 55.0
	cam.position = Vector3(6.0, 6.0, 30.0)
	cam.look_at(Vector3(0.0, 17.5, 62.0), Vector3.UP)
	cam.current = true

	## Segunda camara, pegada a la pantalla misma -para confirmar que el
	## escudo realmente esta ahi, no solo el degradado (que es lo unico que
	## se distingue a distancia de camara de partido).
	_cam2 = Camera3D.new()
	add_child(_cam2)
	_cam2.fov = 35.0
	_cam2.position = Vector3(0.0, 17.5, 40.0)
	_cam2.look_at(Vector3(0.0, 17.5, 62.4), Vector3.UP)

func _process(_d: float) -> void:
	_frame += 1
	if _frame == 5:
		## Extraer la textura real del material ya aplicado en la escena viva,
		## para descartar si el problema esta en como se genera o en como se
		## aplica/renderiza despues.
		var raiz: Node3D = _vista.get("_raiz3d")
		if raiz != null:
			_volcar_pantallas(raiz)
	if _frame == 25:
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/capturas/pantalla_estadio_contenido.png")
		print("captura guardada: pantalla_estadio_contenido.png (%dx%d)" % [img.get_width(), img.get_height()])
		_cam2.current = true
	if _frame == 27:
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/capturas/pantalla_estadio_contenido_cerca.png")
		print("captura guardada: pantalla_estadio_contenido_cerca.png (%dx%d)" % [img2.get_width(), img2.get_height()])
		print("FIN. 0 fallos")
		get_tree().quit()

func _volcar_pantallas(n: Node, n_encontradas: Array = [0]) -> void:
	if n is MeshInstance3D:
		var mi: MeshInstance3D = n
		var mat := mi.material_override
		if mat is StandardMaterial3D and (mat as StandardMaterial3D).emission_texture != null:
			var t: Texture2D = (mat as StandardMaterial3D).emission_texture
			var img := t.get_image()
			if img != null:
				n_encontradas[0] += 1
				var ruta := "res://pruebas/capturas/diag_pantalla_viva_%d.png" % n_encontradas[0]
				img.save_png(ruta)
				print("volcada textura real de '%s' -> %s (%s)  pos_global=%s" % [
					n.name, ruta, img.get_size(), (n as MeshInstance3D).global_position])
	for c in n.get_children():
		_volcar_pantallas(c, n_encontradas)
