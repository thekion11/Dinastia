class_name AscensorViaje
extends RefCounted
## EL VIAJE DEL ASCENSOR (9-11, fallo del vídeo del dueño: «el ascensor sin animaciones de subida/bajada»). Antes `ir_a_planta` teletransportaba al
## jugador: ahora el cuerpo SUBE o BAJA suave (un segundo por planta, con arranque y frenada), con un clic al salir y otro al llegar. Los
## exploradores (estadio y ciudad) paran el movimiento mientras dura (`en_viaje`) y fijan la planta al llegar.
const SEG_POR_PLANTA := 1.0
const SEG_MINIMO := 0.9

static func duracion(desde: int, hasta: int) -> float:
	return maxf(SEG_MINIMO, absf(float(hasta - desde)) * SEG_POR_PLANTA)

## Mueve `cuerpo` de la altura de `desde` a la de `hasta`; `al_llegar` se llama al final. Devuelve el Tween (o null si ya está ahí).
static func viajar(cuerpo: Node3D, desde: int, hasta: int, al_llegar: Callable) -> Tween:
	if cuerpo == null or desde == hasta:
		if al_llegar.is_valid():
			al_llegar.call()
		return null
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	var tw := cuerpo.create_tween()
	tw.tween_property(cuerpo, "position:y", RecorridoClub.y_de(hasta), duracion(desde, hasta)) \
		.from(RecorridoClub.y_de(desde)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		Sonido.toca("clic", Sonido.Bus.EFECTOS)
		if al_llegar.is_valid():
			al_llegar.call())
	return tw
