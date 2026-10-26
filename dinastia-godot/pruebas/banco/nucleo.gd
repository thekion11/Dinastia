extends Node
## NÚCLEO DEL BANCO (26-10-2026): lo mínimo que comparten el corredor (`pruebas/banco.gd`) y
## los nodos de grupo (`pruebas/banco/<grupo>.gd`): anotar líneas, títulos y comprobaciones.
##
## El registro es ESTÁTICO a propósito: cada grupo es un nodo aparte, pero todos escriben en
## la misma lista de fallos y líneas, como cuando el banco era un solo nodo de 27 capas.

static var _fallos: Array[String] = []
static var _lineas: Array[String] = []

func _linea(t: String) -> void:
	_lineas.append(t)
	print(t)

func _titulo(t: String) -> void:
	_linea("")
	_linea("===== %s =====" % t)

func _comprobar(condicion: bool, que: String) -> void:
	if condicion:
		_linea("  ok    %s" % que)
	else:
		_fallos.append(que)
		_linea("  FALLO %s" % que)
