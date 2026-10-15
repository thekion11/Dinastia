extends Node3D
## Sonda: qué animaciones tiene un futbolista del partido.
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var a: Club = m.ligas[0].clubes[0]
	var sp := PlayerSpawner.new()
	var l := Puente3D.once(a.once())
	var lista := sp.spawn_team(self, l["xi"], l["jugadores"], Puente3D.formacion(a.tactica.formacion), true, Puente3D.kit(a), Puente3D.kit_portero(a))
	var ap: AnimationPlayer = lista[5]["anim"]
	var nombres := ap.get_animation_list()
	print("ANIMACIONES %d: %s" % [nombres.size(), ", ".join(nombres)])
	get_tree().quit()
