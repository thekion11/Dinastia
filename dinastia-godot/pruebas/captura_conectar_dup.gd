extends Node
## Verifica el arreglo de duplicados en `_conectar_noticias()` (ui/principal.gd):
## `mercado`, `copa`, `roles`, `cesiones` y `eras` se crean UNA sola vez por
## partida -no los recrea `tomar_el_mando()`-, y las tres senales que van
## directo en `mundo` (`informe_de_ojeo`, `obra_lista`, `libre_estrella`)
## viven en el MISMO `mundo` durante toda la partida. `_conectar_noticias()`
## se vuelve a llamar cada vez que tomas otro club sin salir de la partida
## (`_tomar_club()`, `_al_elegir_club()`, aceptar una oferta de trabajo): sin
## candado, cada aviso se habria anotado una vez mas por cada club tomado.
##
## Se simula justo eso -llamar `_conectar_noticias()` una segunda vez sobre el
## MISMO `mundo`- y se emite una sola vez cada senal afectada, contando cuantas
## filas nuevas aparecen en `_bandeja` (que `_anotar()` llena sin filtrar
## duplicados). Con el candado puesto: una emision, una fila. Sin el: dos.
##
##   godot --headless --path . res://pruebas/captura_conectar_dup.tscn

const ESPERA := 6

var _n := 0
var _pantalla: Node
var _fallos := 0

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n != ESPERA:
		return
	var mun = _pantalla.get("mundo")
	## Segunda pasada sobre el MISMO mundo, tal como hace `_tomar_club()`.
	_pantalla.call("_conectar_noticias")

	_probar("roles.aviso", mun.roles.aviso, ["prueba", "cuerpo"])
	_probar("roles.ascenso", mun.roles.ascenso, ["capitan"])
	_probar("roles.interinato_resuelto", mun.roles.interinato_resuelto, [true])
	_probar("roles.noticia_carrera", mun.roles.noticia_carrera, ["prueba", "cuerpo"])
	_probar("eras.noticia", mun.eras.noticia, ["prueba", "cuerpo"])
	_probar("cesiones.noticia", mun.cesiones.noticia, ["prueba", "cuerpo"])
	_probar("mundo.obra_lista", mun.obra_lista, ["trib"])
	_probar("mundo.libre_estrella", mun.libre_estrella, [_jugador_de_prueba(mun)])

	print("FIN. %d fallo(s)" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)

func _jugador_de_prueba(mun) -> Jugador:
	for c: Club in mun.clubes.values():
		if not c.plantilla.is_empty():
			return c.plantilla[0]
	return null

func _probar(nombre: String, senal: Signal, args: Array) -> void:
	var antes: int = _pantalla.get("_bandeja").size()
	_emitir(senal, args)
	var despues: int = _pantalla.get("_bandeja").size()
	var filas := despues - antes
	if filas == 1:
		print("OK  %s: 1 fila (candado funciona)" % nombre)
	else:
		_fallos += 1
		print("MAL %s: %d filas (se esperaba 1 -> duplicado real)" % [nombre, filas])

func _emitir(senal: Signal, args: Array) -> void:
	match args.size():
		1: senal.emit(args[0])
		2: senal.emit(args[0], args[1])
		3: senal.emit(args[0], args[1], args[2])
		4: senal.emit(args[0], args[1], args[2], args[3])
		_: senal.emit()
