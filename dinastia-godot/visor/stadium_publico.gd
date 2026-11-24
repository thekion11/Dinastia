class_name StadiumPublico
extends RefCounted
## La gente de la grada (texturas de los hinchas): una columna de hinchas y cada hincha. Sacado de
## `stadium_builder_p4_p1.gd` para no pasar de 450 líneas; las funciones son las mismas.

## Una columna de hinchas de la grada (`x0`): el escalón de la fila y, en cada hueco libre, un hincha.
static func _publico_fila(img: Image, x0: int, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var w: int = ctx["w"]
	var h: int = ctx["h"]
	var alto_persona: int = ctx["alto"]
	var piel_persona: int = ctx["piel_n"]
	var paso_fila: int = ctx["paso"]
	var lleno_c: float = ctx["lleno"]
	var escaleras: Array[int] = ctx["escal"]
	var ancho_escalera: int = ctx["ancho_esc"]
	var ropa: Array = ctx["ropa"]
	var piel: Array = ctx["piel"]
	## El escalon entre fila y fila: una linea mas oscura del propio color
	## del asiento, no un gris inventado.
	for y in range(h):
		img.set_pixel(x0, y, img.get_pixel(x0, y).darkened(0.42))
	var y_asiento := rng.randi_range(0, alto_persona - 1)
	while y_asiento < h:
		var en_escalera := false
		for e in escaleras:
			if absi(y_asiento - e) < ancho_escalera + alto_persona / 2:
				en_escalera = true
				break
		if not en_escalera and rng.randf() < lleno_c:
			var col_ropa: Color = ropa[rng.randi_range(0, ropa.size() - 1)]
			var col_piel: Color = piel[rng.randi_range(0, piel.size() - 1)]
			_publico_persona(img, x0, y_asiento, col_piel, col_ropa, piel_persona, alto_persona, paso_fila, w, h)
		y_asiento += alto_persona


## Dibuja un hincha (piel y ropa) en el hueco `y_asiento`. Deja el ultimo texel sin cubrir: es el respaldo
## de la butaca, y es lo que mantiene visible el patron de colores del club incluso con la grada llena.
static func _publico_persona(img: Image, x0: int, y_asiento: int, col_piel: Color, col_ropa: Color,
		piel_persona: int, alto_persona: int, paso_fila: int, w: int, h: int) -> void:
	for dy in range(alto_persona - 1):
		var yy := y_asiento + dy
		if yy >= h:
			break
		var col: Color = col_piel if dy < piel_persona else col_ropa
		for dx in range(1, maxi(2, paso_fila - 1)):
			img.set_pixel(mini(x0 + dx, w - 1), yy, col)
