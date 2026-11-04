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
var _respaldo_user := {}   ## (4-11) `user://*.cfg` tal como estaba: lo recuperan las pruebas que tocan preferencias (`_respaldar_user` / `_restaurar_user`)

func _ready() -> void:
	await get_tree().process_frame
	await _probar()   ## (01-11: las pruebas asíncronas, como la del minijuego, esperan a terminar)
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

## Guarda los `.cfg` de `user://` (ajustes, controles, entrada…) para devolverlos al terminar: una prueba que pulsa botones o cambia idioma o escala
## ensucia las preferencias del JUGADOR (misiones del tutorial «hechas», capas de ayuda vistas…) y las pruebas siguientes ven otra pantalla.
func _respaldar_user() -> void:
	_respaldo_user.clear()
	var d := DirAccess.open("user://")
	if d == null:
		return
	for f: String in d.get_files():
		if f.ends_with(".cfg"):
			_respaldo_user[f] = FileAccess.get_file_as_bytes("user://" + f)
	_respaldo_user["__ya"] = true

## (4-11, A4) Pone el idioma de la prueba Y lo guarda en las preferencias: `Principal` carga `user://preferencias.cfg` al abrir y
## el idioma guardado manda sobre el que se puso antes (con un guardado en castellano la vuelta «de» se medía en castellano: la
## prueba pasaba en local y no medía nada). Llamar a `_respaldar_user()` antes; `_restaurar_user()` devuelve el guardado del jugador.
func _fijar_idioma(idi: String) -> void:
	Idiomas.idioma = idi
	var cf := ConfigFile.new()
	cf.load("user://preferencias.cfg")
	cf.set_value("juego", "idioma", idi)
	cf.save("user://preferencias.cfg")

func _restaurar_user() -> void:
	if not _respaldo_user.has("__ya"):
		return
	var d := DirAccess.open("user://")
	for f: String in d.get_files():
		if f.ends_with(".cfg") and not _respaldo_user.has(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + f))
	for f: String in _respaldo_user:
		if f != "__ya":
			var a := FileAccess.open("user://" + f, FileAccess.WRITE)
			a.store_buffer(_respaldo_user[f])
	_respaldo_user.clear()
