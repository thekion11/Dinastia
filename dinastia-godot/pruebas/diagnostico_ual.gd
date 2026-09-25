extends Node
## Inspecciona el GLB de la "Universal Animation Library" (real, bajada de
## Quaternius/itch.io, CC0): que huesos trae su esqueleto y que animaciones
## trae su AnimationPlayer, para comparar contra `FutbolistaQ.esqueleto_de()`
## antes de conectarlas. No modifica nada, solo imprime.

func _ready() -> void:
	var packed: PackedScene = load("res://assets/characters/quaternius/anims/UAL1_Standard.glb")
	if packed == null:
		print("ERROR: no cargo el glb")
		get_tree().quit(1)
		return
	var nodo: Node3D = packed.instantiate()
	add_child(nodo)

	var esq: Skeleton3D = null
	var ap: AnimationPlayer = null
	_buscar(nodo, esq, ap)

	print("--- fin ---")
	get_tree().quit(0)

func _buscar(n: Node, esq, ap) -> void:
	for hijo in n.get_children():
		if hijo is Skeleton3D:
			print("Skeleton3D encontrado: ", hijo.name, " huesos=", hijo.get_bone_count())
			for i in hijo.get_bone_count():
				print("  [%d] %s" % [i, hijo.get_bone_name(i)])
		if hijo is AnimationPlayer:
			print("AnimationPlayer encontrado: ", hijo.name)
			for lib_name in hijo.get_animation_library_list():
				var lib: AnimationLibrary = hijo.get_animation_library(lib_name)
				print("  libreria '%s': %d animaciones" % [lib_name, lib.get_animation_list().size()])
				for anim_name in lib.get_animation_list():
					print("    - ", anim_name)
		_buscar(hijo, esq, ap)
