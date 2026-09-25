extends Node
## Inspecciona el esqueleto y las animaciones del pack real de futbol
## (Anderson Rohr, version UE5/Manny) para comparar contra el esqueleto de
## FutbolistaQ antes de conectarlo.

func _ready() -> void:
	var packed: PackedScene = load("res://assets/characters/quaternius/anims_futbol/08_Side_Foot_Kick_ue5.fbx")
	if packed == null:
		print("ERROR: no cargo el fbx")
		get_tree().quit(1)
		return
	var nodo: Node3D = packed.instantiate()
	add_child(nodo)
	_buscar(nodo)
	print("--- fin ---")
	get_tree().quit(0)

func _buscar(n: Node) -> void:
	if n is Skeleton3D:
		var esq := n as Skeleton3D
		print("Skeleton3D: ", esq.name, " huesos=", esq.get_bone_count())
		for i in esq.get_bone_count():
			print("  [%d] %s" % [i, esq.get_bone_name(i)])
	if n is AnimationPlayer:
		var ap := n as AnimationPlayer
		for lib_name in ap.get_animation_library_list():
			var lib: AnimationLibrary = ap.get_animation_library(lib_name)
			for anim_name in lib.get_animation_list():
				var anim: Animation = lib.get_animation(anim_name)
				print("ANIM '%s' dur=%.2f pistas=%d primera_ruta=%s" % [anim_name, anim.length, anim.get_track_count(), anim.track_get_path(0) if anim.get_track_count() > 0 else "?"])
	for c in n.get_children():
		_buscar(c)
