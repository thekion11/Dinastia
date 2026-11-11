extends Node3D
## HOJA DE CAPTURAS DE AVATARES (sesión 12, 11-11): todos los modelos de persona del proyecto en fila,
## con su etiqueta, para decidir cuáles son realistas. Lote por variable LOTE (0..N-1).
##   LOTE=0 herramientas/captura.sh res://pruebas/captura_avatares.tscn
const LOTES := [
	[["Superhero M (cuerpo base)", "res://assets/characters/quaternius/Superhero_Male_FullBody.gltf"],
	["Superhero F (cuerpo base)", "res://assets/characters/quaternius/Superhero_Female_FullBody.gltf"],
	["JUEGO: jugador vestido M", "@vestido_m"], ["JUEGO: jugadora vestida F", "@vestido_f"],
	["Campesino M (Peasant)", "res://assets/characters/outfits/Male_Peasant.gltf"],
	["Campesina F", "res://assets/characters/outfits/Female_Peasant.gltf"],
	["Explorador M (Ranger)", "res://assets/characters/outfits/Male_Ranger.gltf"],
	["Exploradora F", "res://assets/characters/outfits/Female_Ranger.gltf"],
	["AVATAR REGALO", "res://assets/characters/avatar_regalo/avatar_regalo.fbx"],
	["persona_realista (escaneo)", "res://assets/personas/persona_realista.glb"]],
	[["KK Barbarian", "res://assets/characters/kaykit/Barbarian.glb"], ["KK Knight", "res://assets/characters/kaykit/Knight.glb"],
	["KK Mage", "res://assets/characters/kaykit/Mage.glb"], ["KK Rogue", "res://assets/characters/kaykit/Rogue.glb"],
	["KK Rogue_Hooded", "res://assets/characters/kaykit/Rogue_Hooded.glb"], ["KK Skel Warrior", "res://assets/characters/kaykit/Skeleton_Warrior.glb"],
	["KK Skel Mage", "res://assets/characters/kaykit/Skeleton_Mage.glb"], ["KK Skel Rogue", "res://assets/characters/kaykit/Skeleton_Rogue.glb"],
	["KK Skel Minion", "res://assets/characters/kaykit/Skeleton_Minion.glb"],
	["VRM Starter", "res://assets/characters/vrm/Starter01.glb"], ["VRM Arla", "res://assets/characters/vrm/Arla.glb"]],
	[["H Adventurer", "res://assets/characters/modular/men/Adventurer.glb"], ["H Beach", "res://assets/characters/modular/men/Beach.glb"],
	["H Casual", "res://assets/characters/modular/men/Casual.glb"], ["H Casual2", "res://assets/characters/modular/men/Casual2.glb"],
	["H Farmer", "res://assets/characters/modular/men/Farmer.glb"], ["H King", "res://assets/characters/modular/men/King.glb"],
	["H Punk", "res://assets/characters/modular/men/Punk.glb"], ["H Spacesuit", "res://assets/characters/modular/men/Spacesuit.glb"],
	["H Suit", "res://assets/characters/modular/men/Suit.glb"], ["H Swat", "res://assets/characters/modular/men/Swat.glb"],
	["H Worker", "res://assets/characters/modular/men/Worker.glb"]],
	[["M Adventurer", "res://assets/characters/modular/women/Adventurer.glb"], ["M Casual", "res://assets/characters/modular/women/Casual.glb"],
	["M Formal", "res://assets/characters/modular/women/Formal.glb"], ["M Medieval", "res://assets/characters/modular/women/Medieval.glb"],
	["M Punk", "res://assets/characters/modular/women/Punk.glb"], ["M SciFi", "res://assets/characters/modular/women/SciFi.glb"],
	["M Soldier", "res://assets/characters/modular/women/Soldier.glb"], ["M Suit", "res://assets/characters/modular/women/Suit.glb"],
	["M Witch", "res://assets/characters/modular/women/Witch.glb"], ["M Worker", "res://assets/characters/modular/women/Worker.glb"]],
	[["H Swat", "res://assets/characters/modular/men/Swat.glb"], ["M Soldier", "res://assets/characters/modular/women/Soldier.glb"],
	["H Punk", "res://assets/characters/modular/men/Punk.glb"], ["M Punk", "res://assets/characters/modular/women/Punk.glb"],
	["AVATAR REGALO", "res://assets/characters/avatar_regalo/avatar_regalo.fbx"]],
]
var _n := 0

func _ready() -> void:
	var lote := int(OS.get_environment("LOTE")) if OS.get_environment("LOTE") != "" else 0
	var cam := Camera3D.new()
	var items: Array = LOTES[lote]
	var cols := 5
	var filas := int(ceil(items.size() / float(cols)))
	var sep := 2.1
	add_child(cam)
	cam.position = Vector3((cols - 1) * sep * 0.5, filas * 1.0 + 0.2, filas * 2.4 + 5.0)
	cam.look_at(Vector3((cols - 1) * sep * 0.5, filas * 1.0 - 0.3, 0.0))
	cam.fov = 48
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, 25, 0)
	add_child(luz)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.22, 0.24, 0.26)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.85)
	env.environment.ambient_light_energy = 0.6
	add_child(env)
	for i in items.size():
		var f: Array = items[i]
		var pos := Vector3((i % cols) * sep, -(i / cols) * 2.4 + (filas - 1) * 2.4 * 0.0 + 1.4 * (filas - 1) * 0.0, 0)
		pos.y = (filas - 1 - i / cols) * 2.3
		var nodo: Node3D = null
		if String(f[1]).begins_with("@"):
			nodo = Node3D.new()
			add_child(nodo)
			var d := PersonajeDT.crear(nodo, {"cuerpo": "female" if f[1] == "@vestido_f" else "male"}, Color("1f5fa8"), Color.WHITE)
			print("juego ", f[1], " ", d.keys())
			nodo.position = pos
		else:
			var ps = load(String(f[1]))
			if ps == null:
				print("NO CARGA ", f[1])
				continue
			nodo = ps.instantiate()
			add_child(nodo)
			## Todas las animaciones, en la pose de reposo; altura de 1,8 m para compararlas.
			var ymin := 1e9
			var ymax := -1e9
			for mi in nodo.find_children("*", "MeshInstance3D", true, false):
				var m := mi as MeshInstance3D
				if m.mesh == null:
					continue
				var bb := m.global_transform * m.get_aabb()
				ymin = minf(ymin, bb.position.y)
				ymax = maxf(ymax, bb.end.y)
			var h := ymax - ymin
			if h > 0.05:
				nodo.scale = Vector3.ONE * (1.8 / h)
				nodo.position = pos + Vector3(0, -ymin * 1.8 / h, 0)
		var et := Label3D.new()
		et.text = String(f[0])
		et.font_size = 30
		et.pixel_size = 0.0045
		et.position = pos + Vector3(0, -0.12, 0.2)
		et.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		et.no_depth_test = true
		add_child(et)

func _process(_d: float) -> void:
	_n += 1
	if _n == 30:
		var lote := OS.get_environment("LOTE") if OS.get_environment("LOTE") != "" else "0"
		var ruta := "res://pruebas/capturas/avatares_lote%s.png" % lote
		get_viewport().get_texture().get_image().save_png(ruta)
		get_tree().quit()
