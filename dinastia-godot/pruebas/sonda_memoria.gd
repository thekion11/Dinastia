extends Node
## SONDA DE MEMORIA DEL GUARDADO (M-400, 27-10-2026). Solo mide; no cambia nada.
##   godot --headless --path . res://pruebas/sonda_memoria.tscn   (MEM_TEMP=10 por defecto)
## Simula temporadas sin tocar nada y, tras cada una, imprime el tamaño (JSON) de la instantánea y de sus
## 12 claves más grandes, y las listas que más crecen dentro de ellas: así se ve qué historial no tiene tope.

func _peso(v: Variant) -> int:
	return JSON.stringify(v).length()

func _listas(v: Variant, ruta: String, sal: Dictionary) -> void:
	if v is Array:
		if (v as Array).size() >= 50:
			sal[ruta] = (v as Array).size()
		var i := 0
		for x in v:
			if i > 3: break
			_listas(x, ruta + "[]", sal)
			i += 1
	elif v is Dictionary:
		for k in v:
			_listas(v[k], ruta + "." + str(k), sal)

func _ready() -> void:
	await get_tree().process_frame
	var temporadas := int(OS.get_environment("MEM_TEMP")) if OS.get_environment("MEM_TEMP") != "" else 10
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], 4242)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	var antes := {}
	for t in temporadas + 1:
		if t > 0:
			m.jugar_temporada()
			m.nueva_temporada()
		var ins: Dictionary = Partida.instantanea(m)
		var pesos := []
		for k in ins:
			pesos.append([_peso(ins[k]), k])
		pesos.sort()
		pesos.reverse()
		print("\n=== temporada %d · instantánea %.2f MB" % [t, _peso(ins) / 1048576.0])
		for p in pesos.slice(0, 12):
			print("  %-28s %8.1f KB" % [p[1], p[0] / 1024.0])
		if t == temporadas or t == 0:
			var ls := {}
			_listas(ins, "", ls)
			var orden := []
			for r in ls:
				orden.append([ls[r], r])
			orden.sort()
			orden.reverse()
			for o in orden.slice(0, 15):
				print("    lista %-60s %6d" % [o[1], o[0]])
	get_tree().quit()
