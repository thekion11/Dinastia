class_name Animar
extends RefCounted
## MINI ANIMACIONES DE LA INTERFAZ (25-9-2026, plan maestro B11). Pedido: *"integrar
## mini animaciones para sentir vivo el juego"*. Cuatro gestos, siempre cortos
## (menos de medio segundo), para que se sientan y no estorben:
##   - `aparecer()`: entra desvaneciéndose y creciendo un 3 %.
##   - `escalonar()`: los hijos de un contenedor entran uno detrás de otro.
##   - `contar()`: una cifra sube o baja hasta su valor en vez de saltar.
##   - `pulso()`: un latido corto para llamar la atención.
## Con `reducidas` (Ajustes → "Animaciones reducidas") ninguna hace nada: el
## estado final se pone al instante.
##
## Solo tocan `modulate` y `scale`, nunca `position`: dentro de un contenedor
## la posición la recalcula el contenedor y la animación se perdería.

const RUTA := "user://ajustes.cfg"
static var _reducidas := -1

static func reducidas() -> bool:
	if _reducidas < 0:
		var cfg := ConfigFile.new()
		_reducidas = 1 if cfg.load(RUTA) == OK and bool(cfg.get_value("interfaz", "animaciones_reducidas", false)) else 0
	return _reducidas == 1

static func fijar_reducidas(si: bool) -> void:
	_reducidas = 1 if si else 0
	var cfg := ConfigFile.new()
	cfg.load(RUTA)
	cfg.set_value("interfaz", "animaciones_reducidas", si)
	cfg.save(RUTA)

static func aparecer(n: Control, retraso: float = 0.0, dur: float = 0.28) -> void:
	if n == null or not n.is_inside_tree() or reducidas():
		return
	n.modulate.a = 0.0
	n.pivot_offset = n.size * 0.5
	n.scale = Vector2(0.97, 0.97)
	var tw := n.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "modulate:a", 1.0, dur).set_delay(retraso)
	tw.tween_property(n, "scale", Vector2.ONE, dur).set_delay(retraso)

## Hasta `maximo` hijos visibles, cada uno `paso` segundos después del anterior.
## Más allá de eso entran todos juntos: una lista de 40 filas no puede tardar
## dos segundos en aparecer.
static func escalonar(contenedor: Node, paso: float = 0.035, maximo: int = 14) -> void:
	if contenedor == null or reducidas():
		return
	var i := 0
	for h in contenedor.get_children():
		if h is Control and (h as Control).visible:
			aparecer(h, float(mini(i, maximo)) * paso)
			i += 1

## `formato` recibe el valor intermedio (float) y devuelve el texto.
static func contar(l: Label, desde: float, hasta: float, formato: Callable, dur: float = 0.6) -> void:
	if l == null or not l.is_inside_tree() or reducidas() or is_equal_approx(desde, hasta):
		if l != null:
			l.text = String(formato.call(hasta))
		return
	if l.has_meta("tween_contar"):
		var viejo: Tween = l.get_meta("tween_contar")
		if viejo != null and viejo.is_valid():
			viejo.kill()
	var tw := l.create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float) -> void: l.text = String(formato.call(v)), desde, hasta, dur)
	l.set_meta("tween_contar", tw)

static func pulso(n: Control, fuerza: float = 1.08) -> void:
	if n == null or not n.is_inside_tree() or reducidas():
		return
	n.pivot_offset = n.size * 0.5
	var tw := n.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale", Vector2(fuerza, fuerza), 0.12)
	tw.tween_property(n, "scale", Vector2.ONE, 0.25)
