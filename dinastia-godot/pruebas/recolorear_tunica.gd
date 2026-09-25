extends Node
## Retine la tunica "Peasant" hacia un color de club, conservando el
## sombreado -mismo algoritmo que ya usa `Vestidor._retenir()` para la piel:
## desplazar cada pixel por la razon color_objetivo/color_referencia en vez de
## pintar plano, para no perder los pliegues de la tela.
##
## RONDA 2 (a pedido del usuario, "aun se puede ver mejor"): antes solo se
## retenia la tela clara -el cuero oscuro (cinturon, ribetes) quedaba cafe,
## que es justo lo que mas se leia como "disfraz medieval". Ahora TODO el
## pixel se retine, pero hacia dos objetivos distintos segun su luminosidad
## original -la tela clara va al color primario, el cuero oscuro va a una
## sombra del MISMO color en vez de quedar cafe-: el cinturon pasa a leerse
## como un detalle de la misma prenda, no como un material ajeno.

## Cada tanda: [nombre, color primario, color de sombra/ribete]
const TANDAS := [
	["blanco", Vector3(0.90, 0.90, 0.92), Vector3(0.18, 0.18, 0.20)],
	["azul", Vector3(0.06, 0.20, 0.62), Vector3(0.03, 0.09, 0.28)],
]

func _ready() -> void:
	var original := Image.load_from_file("res://assets/characters/quaternius/ropa_temp/T_Peasant_BaseColor.png")
	if original == null:
		print("ERROR: no cargo la imagen")
		get_tree().quit(1)
		return
	original.clear_mipmaps()
	original.convert(Image.FORMAT_RGBA8)
	var w := original.get_width()
	var h := original.get_height()

	## Dos referencias: tela clara (para el color primario) y cuero oscuro
	## (para la sombra/ribete) -mismo criterio de muestreo que antes, ahora
	## por partida doble.
	var datos_ref := original.get_data()
	var suma_clara := Vector3.ZERO
	var cuenta_clara := 0
	var suma_oscura := Vector3.ZERO
	var cuenta_oscura := 0
	for i in range(0, datos_ref.size(), 4 * 17):
		var cr := datos_ref[i] / 255.0
		var cg := datos_ref[i + 1] / 255.0
		var cb := datos_ref[i + 2] / 255.0
		var l: float = 0.2126 * cr + 0.7152 * cg + 0.0722 * cb
		if l > 0.45:
			suma_clara += Vector3(cr, cg, cb)
			cuenta_clara += 1
		elif l > 0.08 and l < 0.35:
			suma_oscura += Vector3(cr, cg, cb)
			cuenta_oscura += 1
	if cuenta_clara == 0 or cuenta_oscura == 0:
		print("ERROR: no encontro las dos referencias (clara=%d oscura=%d)" % [cuenta_clara, cuenta_oscura])
		get_tree().quit(1)
		return
	var ref_clara: Vector3 = suma_clara / float(cuenta_clara)
	var ref_oscura: Vector3 = suma_oscura / float(cuenta_oscura)
	print("referencia clara: ", ref_clara, " oscura: ", ref_oscura)

	for tanda in TANDAS:
		var nombre: String = tanda[0]
		var objetivo: Vector3 = tanda[1]
		var objetivo_sombra: Vector3 = tanda[2]
		var kr: float = objetivo.x / maxf(ref_clara.x, 0.02)
		var kg: float = objetivo.y / maxf(ref_clara.y, 0.02)
		var kb: float = objetivo.z / maxf(ref_clara.z, 0.02)
		var kr2: float = objetivo_sombra.x / maxf(ref_oscura.x, 0.02)
		var kg2: float = objetivo_sombra.y / maxf(ref_oscura.y, 0.02)
		var kb2: float = objetivo_sombra.z / maxf(ref_oscura.z, 0.02)

		var datos := original.get_data()
		for i in range(0, datos.size(), 4):
			var cr := datos[i] / 255.0
			var cg := datos[i + 1] / 255.0
			var cb := datos[i + 2] / 255.0
			var l: float = 0.2126 * cr + 0.7152 * cg + 0.0722 * cb
			if l > 0.30:
				datos[i] = int(clampf(cr * kr, 0.0, 1.0) * 255.0)
				datos[i + 1] = int(clampf(cg * kg, 0.0, 1.0) * 255.0)
				datos[i + 2] = int(clampf(cb * kb, 0.0, 1.0) * 255.0)
			else:
				## El cuero (cinturon, ribetes, hebilla metalica) ya no queda
				## cafe: se retine a una sombra del MISMO color primario.
				datos[i] = int(clampf(cr * kr2, 0.0, 1.0) * 255.0)
				datos[i + 1] = int(clampf(cg * kg2, 0.0, 1.0) * 255.0)
				datos[i + 2] = int(clampf(cb * kb2, 0.0, 1.0) * 255.0)

		var nueva := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, datos)
		nueva.save_png("res://assets/characters/quaternius/ropa_temp/T_Peasant_recoloreada_%s.png" % nombre)
		print("guardada variante: ", nombre)

	print("FIN. 0 fallos")
	get_tree().quit(0)
