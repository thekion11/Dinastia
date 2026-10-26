extends RefCounted
## Base de las pruebas de ideas del dueño (lote a): reparte `_comprobar` al banco y da un mundo de prueba.

var b: Variant

func _init(banco: Variant) -> void:
	b = banco

func _comprobar(condicion: bool, que: String) -> void:
	b._comprobar(condicion, que)

func _linea(t: String) -> void:
	b._linea(t)

func _mundo_ideas(sem: int) -> Mundo:
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], sem)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	return m

## Una idea que no funciona como se creía: se informa sin hacer fallar el banco (queda en el plan).
func _avisar_hallazgo(condicion: bool, que: String) -> void:
	if condicion:
		_comprobar(true, que)
	else:
		_linea("  AVISO (hallazgo, en el plan) %s" % que)
