extends "res://pruebas/banco_p25.gd"
## [Capa 28/29 de `banco.gd`] Auditoría de ideas del dueño, lote a (24-10): cada sección comprueba de verdad que la idea existe y funciona.
## El cuerpo de cada sección vive en `pruebas/ideas_a1.gd` … `ideas_a4.gd` (extienden `ideas_base.gd`) para no pasar de 450 líneas.

const _IDEAS_A1 := preload("res://pruebas/ideas_a1.gd")
const _IDEAS_A2 := preload("res://pruebas/ideas_a2.gd")
const _IDEAS_A3 := preload("res://pruebas/ideas_a3.gd")
const _IDEAS_A4 := preload("res://pruebas/ideas_a4.gd")

func _probar_ideas_lote_a1() -> void:
	_titulo("IDEAS DEL DUEÑO: lote a1 (partido en vivo y pizarra táctica)")
	_IDEAS_A1.new(self).ejecutar()

func _probar_ideas_lote_a2() -> void:
	_titulo("IDEAS DEL DUEÑO: lote a2 (entrenamiento, ojeo y cantera)")
	_IDEAS_A2.new(self).ejecutar()

func _probar_ideas_lote_a3() -> void:
	_titulo("IDEAS DEL DUEÑO: lote a3 (medicina, vestuario, mercado y agentes)")
	_IDEAS_A3.new(self).ejecutar()

func _probar_ideas_lote_a4() -> void:
	_titulo("IDEAS DEL DUEÑO: lote a4 (finanzas, directorio, carrera y ciudad)")
	_IDEAS_A4.new(self).ejecutar()
