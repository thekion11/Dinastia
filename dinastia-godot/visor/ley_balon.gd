class_name LeyBalon
## (16-11, informe M6-06) LAS DOS LEYES CON QUE RUEDA EL BALÓN SUELTO, en un solo sitio, para que quien PREDICE el balón
## (velocidad de un pase, punto de recepción, compensación del aire) use la misma ley que lo MUEVE:
##   · la de siempre (`MotorJugable`, capa 4):  dv/dt = −(k·v + c)·roce_clima, k = Balance.ROCE_SUELO, c = Balance.ROCE_FIJO;
##   · la de League (`LeagueNucleo.fuerzas_balon`, la de C4): dv/dt = −(a + r·moja)·v² − c_l·moja con a = arrastre,
##     r = roce, c_l = roce_lineal y moja = 1 − humedad/2 (el clima ya va dentro de `cfg`, ver `GestoTecnico.fijar_clima`).
## Antes C4 movía el balón con la segunda y calculaba los pases con la primera: un pase manual de 12 m rodaba 8 m.

## LA DE SIEMPRE. Cuánto rueda un balón raso que sale a `v0`: x = v0/k − c/k²·ln(1 + k·v0/c).
static func rodando_siempre(v0: float) -> float:
	var k := Balance.ROCE_SUELO
	var c := Balance.ROCE_FIJO
	return v0 / k - c / (k * k) * log(1.0 + k * v0 / c)

## La velocidad para que un pase raso muera `sobra` metros después del destino (bisección; la de siempre).
static func velocidad_siempre(dist: float, sobra := 2.5) -> float:
	var lo := 1.0
	var hi := 40.0
	for _i in 24:
		var mid := (lo + hi) * 0.5
		if rodando_siempre(mid) < dist + sobra:
			lo = mid
		else:
			hi = mid
	return hi

## LA DE LEAGUE. Los dos coeficientes en el césped: [k (1/m), c (m/s²)].
static func coef_league(cfg: Dictionary) -> Vector2:
	var moja := 1.0 - clampf(float(cfg.get("humedad", 0.0)), 0.0, 1.0) * 0.5
	return Vector2(float(cfg["arrastre"]) + float(cfg["roce"]) * moja, float(cfg["roce_lineal"]) * moja)

## Cuánto rueda con la ley de League: v·dv/dx = −(k·v² + c)  →  x = ln(1 + k·v0²/c) / 2k (la misma de `MotorLeague._mover_balon`).
static func rodando_league(v0: float, cfg: Dictionary) -> float:
	var kc := coef_league(cfg)
	return log(1.0 + kc.x * v0 * v0 / kc.y) / (2.0 * kc.x)

## La velocidad para que ruede `x` metros con la ley de League: v0 = √((e^{2kx} − 1)·c/k).
static func velocidad_league(x: float, cfg: Dictionary) -> float:
	var kc := coef_league(cfg)
	return sqrt((exp(2.0 * kc.x * maxf(x, 0.0)) - 1.0) * kc.y / kc.x)

## Lo que recorre en `tau` segundos (o hasta pararse) con la ley de League: v(t) = √(c/k)·tan(θ0 − √(kc)·t),
## θ0 = atan(v0·√(k/c)); x(t) = ln(cos(θ0 − √(kc)·t) / cos θ0) / k.
static func recorrido_league(v0: float, tau: float, cfg: Dictionary) -> float:
	var kc := coef_league(cfg)
	var th0 := atan(v0 * sqrt(kc.x / kc.y))
	var th := maxf(th0 - sqrt(kc.x * kc.y) * tau, 0.0)
	return log(cos(th) / cos(th0)) / kc.x
