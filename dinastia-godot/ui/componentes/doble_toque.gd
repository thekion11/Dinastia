class_name DobleToque
extends RefCounted
## CONFIRMAR LO QUE NO TIENE VUELTA CON UN SEGUNDO TOQUE (M-299, 27-10-2026). Rescindir ya pedía dos pulsaciones;
## vender un jugador aceptando una oferta o cesar al embajador se hacían al primer clic. Ahora todos usan este
## gesto: el primer toque ARMA el botón (cambia su texto por el aviso y se tiñe de rojo) y el segundo, dentro de
## `ESPERA` segundos, ejecuta. Si no llega, el botón vuelve solo a como estaba. Sin ventanas emergentes: el aviso
## sale donde está el dedo.

const ESPERA := 4.0
const ROJO := Color(1.0, 0.55, 0.5)

## Conecta `accion` a `boton` con doble toque. `aviso`: el texto del botón armado (ya traducido).
static func conectar(boton: Button, aviso: String, accion: Callable) -> void:
	boton.pressed.connect(func() -> void: pulsar(boton, aviso, accion))

## Lo que hace cada pulsación (público para las pruebas). Devuelve true si ejecutó la acción.
static func pulsar(boton: Button, aviso: String, accion: Callable) -> bool:
	if not is_instance_valid(boton):
		return false
	var ahora := Time.get_ticks_msec() / 1000.0
	if boton.has_meta("doble_hasta") and float(boton.get_meta("doble_hasta")) >= ahora:
		desarmar(boton)
		accion.call()
		return true
	boton.set_meta("doble_texto", boton.text)
	boton.set_meta("doble_hasta", ahora + ESPERA)
	boton.text = aviso
	boton.modulate = ROJO
	if boton.is_inside_tree():
		boton.get_tree().create_timer(ESPERA).timeout.connect(func() -> void:
			if is_instance_valid(boton) and boton.has_meta("doble_hasta") and float(boton.get_meta("doble_hasta")) <= Time.get_ticks_msec() / 1000.0 + 0.05:
				desarmar(boton))
	return false

static func armado(boton: Button) -> bool:
	return boton.has_meta("doble_hasta") and float(boton.get_meta("doble_hasta")) >= Time.get_ticks_msec() / 1000.0

static func desarmar(boton: Button) -> void:
	if boton.has_meta("doble_texto"):
		boton.text = String(boton.get_meta("doble_texto"))
		boton.remove_meta("doble_texto")
	if boton.has_meta("doble_hasta"):
		boton.remove_meta("doble_hasta")
	boton.modulate = Color.WHITE
