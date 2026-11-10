extends Node
## Herramienta (no es prueba): imprime la FIRMA del uniforme base de todos los clubes (diseño, color 1 y 2 de la camiseta, pantalón y medias) con su liga, para
## `herramientas/aspecto_unicos_kit.py` y la prueba «ningún uniforme repetido en la misma liga». REAL=1 → nombres del pack real (las filas de aspecto se llaman así).
func _ready() -> void:
	Datos.usar_base_real(OS.get_environment("REAL") == "1")
	var m := Mundo.new()
	m.generar([] as Array[String], 5962)   ## todas las ligas, también las segundas
	for c: Club in m.clubes.values():
		var k: Dictionary = DisenosKit.kit_de_club(c)
		var cols: Array = k["cols"]
		print("KIT|%s%d|%s|%s|%s|%s|%s|%s" % [c.pais, c.division, k["dis"], String(cols[0]).to_lower().trim_prefix("#"), String(cols[1]).to_lower().trim_prefix("#"),
			String(k["pant"]["c1"]).to_lower().trim_prefix("#"), String(k["med"]["c1"]).to_lower().trim_prefix("#"), Nombres.limpiar(c.nombre)])
	get_tree().quit()
