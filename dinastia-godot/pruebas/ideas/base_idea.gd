class_name BaseIdea
extends Node
## BASE DE LAS PRUEBAS DE IDEAS (24-10-2026). Cada archivo de `pruebas/ideas/` es una prueba INDEPENDIENTE
## (no forma parte de la cadena del banco): un error de sintaxis aquí solo rompe esa prueba.
## Se hereda así:
##   extends BaseIdea
##   func _probar() -> void:
##       _titulo("IDEAS DEL DUEÑO (n, m): …")
##       var m := Mundo.new(); m.generar(["CHI", "ARG"], 777); m.tomar_el_mando(m.ligas[0].clubes[0].id)
##       _comprobar(cond, "texto (idea n)")
## y una escena `.tscn` de dos líneas con el script. Se ejecuta con `herramientas/ideas.sh <nombre>`.
## Termina con «===== FIN. N fallos =====» y código de salida 0/1.

var _fallos: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	_probar()
	print("")
	print("===== FIN. %d fallos =====" % _fallos.size())
	get_tree().quit(0 if _fallos.is_empty() else 1)

## Lo que implementa cada prueba.
func _probar() -> void:
	pass

func _titulo(t: String) -> void:
	print("")
	print("===== %s =====" % t)

func _linea(t: String) -> void:
	print(t)

func _comprobar(condicion: bool, que: String) -> void:
	if condicion:
		print("  ok    %s" % que)
	else:
		_fallos.append(que)
		print("  FALLO %s" % que)

func _dinero(n: int) -> String:
	return Cesiones.dinero(n)

## Un mundo listo para probar: dos países, tú al mando del primer club de la primera liga, con caja de sobra.
func _mundo(semilla: int, caja: int = 300000000) -> Mundo:
	var m := Mundo.new()
	m.generar(["CHI", "ARG"], semilla)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	m.mi_club().mover_saldo(caja)
	return m
