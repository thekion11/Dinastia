extends Node
## Prueba aislada de la ventana de fichaje de emergencia (`Roles.abrir_emergencia`,
## conectada esta sesión desde `principal.gd`): sin pasar por `_avanzar_semana()`
## en bloque -que esta sesión enganchó un sorteo de copa fuera de tiempo y se
## quedó colgado-, ni por el azar de qué lesión toca: se simula la señal
## directamente con los parámetros exactos que debían destrabar la ventana.

var _n := 0
var _pantalla: Node

func _ready() -> void:
	_pantalla = load("res://escenas/principal.tscn").instantiate()
	add_child(_pantalla)

func _process(_d: float) -> void:
	_n += 1
	if _n == 12:
		var mundo: Mundo = _pantalla.get("mundo")
		mundo.semana = 10   ## entre la ventana de verano (6) y la de invierno (18): cerrado
		var mio: Club = mundo.mi_club()
		var titular: Jugador = mio.once()[0]
		print("mercado_abierto antes = %s" % mundo.mercado_abierto())
		print("emergencia_activa antes = %s" % mundo.roles.emergencia_activa())
		mundo.medico.lesion_nueva.emit(titular, 14, "Rotura de ligamento", "en el entrenamiento")
		print("emergencia_activa despues = %s" % mundo.roles.emergencia_activa())
		print("emergencia dict = %s" % [mundo.roles.emergencia])

		print("--- despido ---")
		print("sin_club antes = %s" % mundo.roles.sin_club)
		mundo.directiva.despedido.emit("una mala racha de prueba")
		print("sin_club despues = %s" % mundo.roles.sin_club)
		print("ofertas de trabajo = %d" % mundo.roles.ofertas_trabajo().size())
		get_tree().quit()
