extends Node
## (9-11) La plantilla a la PES: abre con tres columnas, elige jugador, compara dos y la diferencia de atributos es la de los datos.
var _n := 0
var _p: Node

func _ready() -> void:
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

func _process(_d: float) -> void:
	_n += 1
	if _n < 8:
		return
	var fallos := 0
	var v: PlantillaPes = PlantillaPes.abrir(_p)
	if v == null:
		print("NO ABRIÓ"); print("FIN. 1 fallos"); get_tree().quit(); return
	var club: Club = _p.mundo.mi_club()
	var campo: Array = club.plantilla.filter(func(j: Jugador) -> bool: return j.pos != "POR")
	var por: Array = club.plantilla.filter(func(j: Jugador) -> bool: return j.pos == "POR")
	var a: Jugador = campo[0]
	var b: Jugador = campo[1]
	var ok1 := PlantillaPes.claves_de(a) == PlantillaPes.ATR_CAMPO and (por.is_empty() or PlantillaPes.claves_de(por[0]) == PlantillaPes.ATR_PORTERO)
	var ok2 := PlantillaPes.diferencia(a, b, "tir") == int(a.atributos["tir"]) - int(b.atributos["tir"]) and PlantillaPes.diferencia(a, a, "pas") == 0
	var ok3 := v._capa != null and v._centro.get_child_count() >= 7 and v._derecha.get_child_count() >= 2   ## título + 6 atributos; retrato + datos
	v._comparando = true
	v._a = a
	v._b = b
	v._pintar()
	await get_tree().process_frame
	var ok4 := v._centro.get_child_count() >= 7
	print("claves ", ok1, " diferencia ", ok2, " columnas ", ok3, " comparación ", ok4)
	fallos = int(not ok1) + int(not ok2) + int(not ok3) + int(not ok4)
	print("FIN. ", fallos, " fallos")
	get_tree().quit()
