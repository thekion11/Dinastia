extends "res://pruebas/banco/nucleo.gd"
## [Banco · base: utilidades comunes] Generado al partir el banco por grupos (26-10).

## NO SE ATRAVIESAN PAREDES (17-10-2026, caza de bugs): con un coche del
## tráfico encima, antes se podía entrar caminando en un edificio.
class _ExpPared extends ExploradorCiudad:
	var pared_x := 5.0
	var movil_encima := false
	func libre_obst(p: Vector3, radio: float) -> bool:
		return p.x + radio < pared_x
	func _choca_moviles(_p: Vector3, _radio: float) -> bool:
		return movil_encima
	func _choca_circulos(_p: Vector3, _radio: float) -> bool:
		return false

func _dinero(n: int) -> String:
	var euros := float(n) * Eco.ECO
	if euros >= 1000000.0:
		return "%.1fM EUR" % (euros / 1000000.0)
	return "%dk EUR" % int(euros / 1000.0)
