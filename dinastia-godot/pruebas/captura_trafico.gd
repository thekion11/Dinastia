extends Node
## Comprueba que el trafico se MUEVE de verdad -una captura fija no lo
## demuestra- y que cada vehiculo va a su ritmo: se anotan las posiciones de
## todos al arrancar y 40 fotogramas despues, y se mide cuanto recorrio cada
## uno. Tambien saca dos fotos desde la MISMA camara para poder comparar.
##
##   godot --path . --rendering-driver opengl3 res://pruebas/captura_trafico.tscn

var _n := 0
var _vista: VistaCiudad
var _mundo: Mundo
var _antes: Array = []

func _ready() -> void:
	_mundo = Mundo.new()
	_mundo.generar(["CHI"], 4714)
	_mundo.tomar_el_mando(_mundo.ligas[0].clubes[0].id)
	for k in ["ct", "acad", "med", "gim", "park", "huerto"]:
		_mundo.obras.niveles[k] = 3
	_mundo.ciudad.terrenos = ["norte", "ribera"]
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(_mundo.mi_club(), _mundo.obras, _mundo.ciudad,
		_mundo.perfil_estadio_de(_mundo.mi_club()))
	_vista.set("_girando", false)
	_vista.set("_dist", 360.0)
	_vista.set("_alto", 95.0)
	_vista.set("_ang", 1.15)

func _moviles() -> Array:
	var ciudad: Node = _vista.get("_ciudad")
	var t := ciudad.get_node_or_null("Trafico")
	if t == null:
		return []
	var ps: Array = []
	for h in t.get_children():
		ps.append((h as Node3D).global_position)
	return ps

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		_antes = _moviles()
		print("vehiculos en movimiento: %d" % _antes.size())
		## ORIENTACION: el morro tiene que apuntar a donde va. 1.0 = perfecto,
		## -1.0 = circula marcha atras, 0 = va de lado.
		var ciudad: Node = _vista.get("_ciudad")
		var t := ciudad.get_node_or_null("Trafico")
		if t != null:
			var peor := 2.0
			var suma := 0.0
			var cuantos := 0
			for i in range(20):
				var d: Dictionary = t.call("diagnostico", i)
				if d.is_empty():
					continue
				var a: float = d["alineacion"]
				peor = minf(peor, a)
				suma += a
				cuantos += 1
			print("alineacion morro/marcha: media %.3f, peor %.3f (1.0 = perfecto, -1.0 = marcha atras)" % [
				suma / maxf(float(cuantos), 1.0), peor])
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://pruebas/trafico_a.png")
	if _n == 52:
		var ahora := _moviles()
		var quietos := 0
		var total := 0.0
		var maximo := 0.0
		for i in range(mini(_antes.size(), ahora.size())):
			var d: float = (_antes[i] as Vector3).distance_to(ahora[i] as Vector3)
			total += d
			maximo = maxf(maximo, d)
			if d < 0.05:
				quietos += 1
		print("tras 40 fotogramas: recorrido medio %.2f m, maximo %.2f m, quietos %d de %d" % [
			total / maxf(float(ahora.size()), 1.0), maximo, quietos, ahora.size()])
		var img2 := get_viewport().get_texture().get_image()
		img2.save_png("res://pruebas/trafico_b.png")
		print("capturas: trafico_a.png y trafico_b.png (misma camara)")
		get_tree().quit()
