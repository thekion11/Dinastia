class_name Conexion
## Conectar una señal UNA sola vez (ruido de registros, 3-11). `Signal.connect` con el mismo `Callable` ya conectado no hace daño (Godot no lo duplica) pero escribe
## un ERROR en el registro cada vez; quien reconecta al rehacer una pantalla (`Noticias.conectar`, otra `Principal` sobre el mismo `Mundo`) pregunta aquí primero.
static func una_vez(senal: Signal, cb: Callable, flags := 0) -> void:
	if not senal.is_connected(cb):
		senal.connect(cb, flags)
