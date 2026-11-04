class_name PrologoDT
extends "res://visor/prologo_p1.gd"
## (Parte 2 de 2 de `prologo.gd`.)

## La primera vez que enciendes el PC el prólogo queda hecho y la partida se guarda.
func _al_encender_pc() -> void:
	if _guardado_al_encender:
		return
	_guardado_al_encender = true
	mundo.prologo_visto = true
	var pr := pc.principal()
	if pr != null and pr.get("_partida") != null:
		pr.get("_partida").guardar_en("partida")
	terminado.emit()

# ----------------------------------------------------------------- salir

func _saltar() -> void:
	if mundo != null:
		mundo.prologo_visto = true
	_a_principal()

func _a_principal() -> void:
	if not is_inside_tree():
		return
	get_tree().change_scene_to_file(ESCENA_PRINCIPAL)
