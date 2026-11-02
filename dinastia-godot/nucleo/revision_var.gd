class_name RevisionVAR
## LA DECISIÓN DEL VAR (2-11-2026, auditoría del 28-10: «VAR decidido con Azar solo en la vista 3D»). Antes la
## regla vivía dentro de `estadio_p5.gd` y gastaba números del azar de la PARTIDA; ahora es una función del
## núcleo, probada en el banco, con su propio generador (semilla = la jugada), así que revisar un gol no
## mueve la secuencia del mundo ni depende de que haya vista 3D.
##
## `margen`: cuánto estaba el goleador por delante de la línea en el pase (m; ≤ 0 = en juego, > 0 = adelantado).
## `factor_tarjetas`: < 1,0 solo cuando la liga tiene VAR (`Federacion.factor_tarjetas`).
## Devuelve {revisa, ajustado, anula}.
##  - Fuera de juego AJUSTADO (margen ≤ 0,3 m y > −1 m; entre −1,8 y −1 m, una de cada tres): se revisa siempre y
##    se anula si de verdad estaba adelantado (margen > 0).
##  - Si no: con VAR, uno de cada doce goles se revisa por «posible falta previa» y uno de cada cuatro de ésos se anula.

static func decidir(margen: float, factor_tarjetas: float, semilla: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var ajustado := margen <= 0.3 and (margen > -1.0 or (margen > -1.8 and rng.randf() < 0.35))
	var revisa := factor_tarjetas < 1.0 and (ajustado or rng.randf() < 0.08)
	var anula := false
	if revisa:
		anula = margen > 0.0 if ajustado else rng.randf() < 0.25
	return {"revisa": revisa, "ajustado": ajustado, "anula": anula}
