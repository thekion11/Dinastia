extends "res://pruebas/ideas/ppru_conducir.gd"
## Mutación temporal: volante al revés y sin tope de velocidad. DEBE suspender.
class Roto extends ExploradorCiudad:
	func _conducir(e: Vector2, delta: float) -> void:
		super._conducir(Vector2(-e.x, e.y), delta)
		if e.y > 0.0:
			vel += 0.2
func _nuevo() -> ExploradorCiudad:
	return Roto.new()
