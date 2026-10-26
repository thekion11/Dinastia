extends "res://pruebas/ideas_base.gd"
## Base de las pruebas de ideas del dueño (lote b): mundo con caja holgada y formato de dinero del banco.

func _mb(sem: int) -> Mundo:
	var m := _mundo_ideas(sem)
	m.mi_club().mover_saldo(900000000)
	return m

func _dinero(n: int) -> String:
	return b._dinero(n)

