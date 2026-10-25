extends Node
## Capturas de la pantalla de ENTRADA AL CAMPEONATO (Forward+):
##   herramientas/captura.sh res://pruebas/ideas/_f1e_captura.tscn  (con «_»: `ideas.sh todo` no la corre)
## Saca cuatro: opción A, opción B, la confirmación y la opción B en inglés (textos largos).

var _n := 0
var _p: PantallaEntradaCampeonato
var _m: Mundo

func _ready() -> void:
	_m = Mundo.new()
	_m.generar(["CHI"], 2026)
	_montar()

func _montar() -> void:
	if _p != null:
		_p.queue_free()
	_p = PantallaEntradaCampeonato.new()
	_p.configurar({"mundo": _m, "pais": "CHI",
		"config": {"nombre_club": "Atlético Fénix", "color1": "#8a1c2b", "color2": "#f2d16b", "estadio": "La Forja"}})
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	match _n:
		30:
			_guardar("f1e_entrada_a")
			_p.elegir_modo(EntradaCampeonato.MODO_CONFEDERACION)
		45:
			_guardar("f1e_entrada_b")
			_p._pedir_confirmacion()
		60:
			_guardar("f1e_entrada_confirmar")
			Idiomas.idioma = "en"
			_montar()
			_p.elegir_modo(EntradaCampeonato.MODO_CONFEDERACION)
		80:
			_guardar("f1e_entrada_b_en")
			get_tree().quit()

func _guardar(nombre: String) -> void:
	var img := get_viewport().get_texture().get_image()
	var ruta := "res://pruebas/capturas/%s.png" % nombre
	img.save_png(ruta)
	print("captura guardada: %s (%dx%d)" % [ruta, img.get_width(), img.get_height()])
