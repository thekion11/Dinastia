extends RefCounted
## [Capa base de `mercado.gd`, bajo `mercado_p1.gd`] _ajuste_por_liga: el ajuste de la probabilidad por la liga del destino (20-11, orden 63: partido para no pasar de 450 líneas).

## El ajuste de la probabilidad por la liga y la división del club de destino (en el mismo orden de sumas que antes).
func _ajuste_por_liga(destino: Club, suyo: Club, p: float, razones: Array[Dictionary]) -> float:
	if destino.pais == suyo.pais:
		if destino.division > suyo.division:
			p -= 0.30
			razones.append({"bien": false, "txt": Idiomas.t("Bajaría de división")})
		elif destino.division < suyo.division:
			p += 0.16
			razones.append({"bien": true, "txt": Idiomas.t("Subiría de división")})
	else:
		var t := Eco.tier_pais(destino.pais) - Eco.tier_pais(suyo.pais)
		p += clampf(t * 0.35, -0.24, 0.18)
		if t < -0.12:
			razones.append({"bien": false, "txt": Idiomas.t("Cambiar de país para ir a una liga menor no le seduce")})
		elif t > 0.12:
			razones.append({"bien": true, "txt": Idiomas.t("Daría el salto a una liga más fuerte")})
	return p
