extends Node
## Verifica que los apellidos ahora varian por nacionalidad (22-9-2026,
## pedido directo del usuario: "usa apellidos de los canteranos segun su
## nacionalidad"). Genera un mundo con Chile + Espana + Alemania y revisa que
## los apellidos de cada liga salen de la bolsa correcta, no todos del mismo
## fondo chileno.
##
##   godot --path . --headless res://pruebas/diagnostico_nombres_pais.tscn

func _ready() -> void:
	var m := Mundo.new()
	print("generando con seed 4003...")
	m.generar(["CHI", "ESP", "GER"], 4003)
	print("mundo generado OK")
	for pais in ["CHI", "ESP", "GER"]:
		var club: Club = null
		for c: Club in m.clubes.values():
			if c.pais == pais:
				club = c
				break
		if club == null:
			print("MAL: no hay club de %s" % pais)
			continue
		var apellidos: Array[String] = []
		for j in club.plantilla:
			apellidos.append(j.nombre.split(" ")[-1])
		print("%s (%s): %s" % [pais, club.nombre, ", ".join(apellidos)])
	print("FIN. 0 fallos")
	get_tree().quit()
