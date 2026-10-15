extends Node3D
## Sonda: ¿las dos formaciones salen en espejo? (sesgo local/visita del motor).
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var a: Club = m.ligas[0].clubes[3]
	var sp := PlayerSpawner.new()
	var l := Puente3D.once(a.once())
	var loc := sp.spawn_team(self, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a))
	var vis := sp.spawn_team(self, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), false, Puente3D.kit(a), Puente3D.kit_portero(a))
	for i in loc.size():
		var bl: Vector3 = loc[i]["base_pos"]
		var bv: Vector3 = vis[i]["base_pos"]
		print("%-4s local %6.1f %6.1f   visita %6.1f %6.1f   rot %.2f / %.2f" % [String(loc[i]["slot_code"]), bl.x, bl.z, bv.x, bv.z, (loc[i]["node"] as Node3D).rotation.y, (vis[i]["node"] as Node3D).rotation.y])
	get_tree().quit()
