extends Node
## LAS TEXTURAS DE RUIDO EN SEGUNDO PLANO SON LAS DE SIEMPRE (30-10-2026): cada clave de
## `datos/ruidos_previstos.json` generada por `RuidosFondo.imagen` (en hilos, al arrancar) tiene
## que dar los MISMOS bytes, mipmaps incluidos, que la `NoiseTexture2D` que haría `Texturas`.
##   godot --headless --path . res://pruebas/probar_ruidos_fondo.tscn   (≈1 min; en especiales.sh)
var _a: Array = []
var _n := 0
func _ready() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RuidosFondo.LISTA))
	for c: Array in d["claves"]:
		var p := RuidosFondo.normalizar(c)
		var t: NoiseTexture2D = Texturas._nuevo_claro(p[1], p[2], p[3], p[4]) if p[0] is String \
			else Texturas._nuevo_ruido(p[0], p[1], p[2], p[3], p[4])
		_a.append([p, t])
func _process(_d: float) -> void:
	_n += 1
	if _n < 3:
		return
	var fallos := 0
	for par: Array in _a:
		var p: Array = par[0]
		var mia := RuidosFondo.imagen(p, RuidosFondo._lut(float(p[4])) if p[0] is String else PackedByteArray())
		var suya: Image = (par[1] as NoiseTexture2D).get_image()
		if suya == null or mia.get_format() != suya.get_format() or mia.get_data() != suya.get_data():
			fallos += 1
			print("FALLO ruido distinto: ", str(p))
	print("Ruidos comparados: %d" % _a.size())
	print("FIN. %d fallos" % fallos)
	get_tree().quit()
