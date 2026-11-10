extends Node
## Graba el PRÓLOGO ANIMADO entero (para enseñárselo al dueño), FUERA del repo:
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 --write-movie /ruta/prologo.avi --fixed-fps 30 res://pruebas/grabar_prologo.tscn
## Un club de la base ficticia; se cierra solo al terminar los 6 planos.
func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var anim := PrologoAnimado.new()
	anim._club = m.mi_club()
	anim._montar_base(self)
	anim._armar(null)
	set_meta("mundo", m)
	await anim.terminado
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
