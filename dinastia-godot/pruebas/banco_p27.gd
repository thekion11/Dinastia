extends "res://pruebas/banco_p26.gd"
## [Capa 29/30 de `banco.gd`] Auditoría de ideas del dueño, lote b (24-10): cada sección comprueba de verdad que la idea existe y funciona.
## El cuerpo de cada sección vive en `pruebas/ideas_b1.gd` … `ideas_b4.gd` (extienden `ideas_base_b.gd`) para no pasar de 450 líneas.

const _IDEAS_B1 := preload("res://pruebas/ideas_b1.gd")
const _IDEAS_B2 := preload("res://pruebas/ideas_b2.gd")
const _IDEAS_B3 := preload("res://pruebas/ideas_b3.gd")
const _IDEAS_B4 := preload("res://pruebas/ideas_b4.gd")

func _probar_ideas_lote_b1() -> void:
	_titulo("IDEAS DEL DUEÑO: lote b1, hinchada y prensa (736-800)")
	_IDEAS_B1.new(self).ejecutar()

func _probar_ideas_lote_b2() -> void:
	_titulo("IDEAS DEL DUEÑO: lote b2, árbitros, disciplina y federación (801-837)")
	_IDEAS_B2.new(self).ejecutar()

func _probar_ideas_lote_b3() -> void:
	_titulo("IDEAS DEL DUEÑO: lote b3, selecciones y competencias (844-908)")
	_IDEAS_B3.new(self).ejecutar()

func _probar_ideas_lote_b4() -> void:
	_titulo("IDEAS DEL DUEÑO: lote b4, editor, modos de juego, progresión, interfaz y audio (911-1097)")
	_IDEAS_B4.new(self).ejecutar()
