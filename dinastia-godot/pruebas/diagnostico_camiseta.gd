extends Node
## Diagnostico aislado (18-9-2026): por que Colo-Colo sale amarillo/azul en 3D
## en vez de blanco/negro. Recorta el torso de colo_colo_1.png con la MISMA
## funcion que usa el visor y lo guarda, sin partido ni modelo de por medio.
##
##   godot --headless --path . res://pruebas/diagnostico_camiseta.tscn

func _ready() -> void:
	var torso: Image = KitTextureFactory._torso_de_camiseta("colo_colo_1.png")
	if torso == null:
		print("torso salio NULL -no encontro el archivo o la caja de recorte fallo")
		get_tree().quit(1)
		return
	torso.save_png("res://pruebas/torso_colo_colo.png")
	print("torso recortado guardado, tamano: ", torso.get_size())

	var dom := KitTextureFactory._color_dominante(torso, Rect2i(Vector2i.ZERO, torso.get_size()))
	print("color dominante del torso recortado: ", dom.to_html(false))

	# Ahora la ruta completa: pegar en el atlas y sacar el color dominante como
	# lo hace get_material().
	var kit_factory := KitTextureFactory.new()
	var mat := kit_factory.get_material(Color("#000000"), Color("#ffffff"), "liso", 9, 0, "colo_colo_1.png")
	var tex: Texture2D = mat.albedo_texture
	var img := tex.get_image()
	img.save_png("res://pruebas/atlas_colo_colo.png")
	print("atlas completo guardado, tamano: ", img.get_size())
	print("FIN. 0 fallos")
	get_tree().quit(0)
