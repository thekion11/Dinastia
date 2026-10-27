extends BaseIdea
## EL CERRO Y SU TELEFÉRICO (27-10-2026): montaña en las afueras, estaciones, torres, dos cabinas y el mirador de la cima.

func _probar() -> void:
	_titulo("CIUDAD · CERRO Y TELEFÉRICO")
	var b := CityBuilder.new()
	add_child(b)
	for m in b._terreno():
		b.add_child(m)
	var cima_xz := Vector2(Teleferico.CIMA_XZ)
	_comprobar(b.altura_en(cima_xz.x, cima_xz.y) > 180.0, "el cerro se levanta %.0f m sobre el llano en la cima del teleférico" % b.altura_en(cima_xz.x, cima_xz.y))
	_comprobar(absf(b.altura_en(0.0, 0.0)) < 0.01 and absf(b.altura_en(1000.0, 1000.0)) < 0.01, "y el centro de la ciudad sigue plano")
	var t := Teleferico.montar(b)
	_comprobar(t.puntos.size() == Teleferico.N_TORRES + 2 and t.cabinas.size() == 2, "cable con %d puntos (torres incluidas) y dos cabinas" % t.puntos.size())
	_comprobar(t.cima.y > t.base.y + 150.0 and absf(t.base.y) < 3.0, "la estación de abajo está en el llano (%.1f m) y la de arriba a %.0f m" % [t.base.y, t.cima.y])
	var sobre_terreno := true
	for p: Vector3 in t.puntos:
		sobre_terreno = sobre_terreno and p.y > b.altura_en(p.x, p.z) + 8.0
	_comprobar(sobre_terreno, "el cable nunca roza el terreno (siempre 8 m por encima)")
	_comprobar(Teleferico.avance(0.0) == 0.0 and is_equal_approx(Teleferico.avance(Teleferico.VIAJE), 1.0) and is_equal_approx(Teleferico.avance(Teleferico.VIAJE + Teleferico.ESPERA + Teleferico.VIAJE), 0.0), "ciclo: sube, espera arriba, baja y espera abajo")
	t._poner_cabinas(Teleferico.VIAJE * 0.5)
	var a: Vector3 = t.cabinas[0].position
	var c: Vector3 = t.cabinas[1].position
	_comprobar(Vector2(a.x, a.z).distance_to(Vector2(c.x, c.z)) < 6.0, "a mitad de camino las dos cabinas se cruzan (a %.1f m)" % Vector2(a.x, a.z).distance_to(Vector2(c.x, c.z)))
	var tele_base := 0
	for pc: Dictionary in b.puntos_clic:
		if String(pc["k"]) == "tele_base":
			tele_base += 1
	_comprobar(tele_base == 1, "la estación de abajo es un punto de E")
	var m := t.mirador
	_comprobar(m.libre(Vector2(t.cima.x, t.cima.z + 15.0)) and not m.libre(Vector2(t.cima.x, t.cima.z)) and not m.libre(Vector2(t.cima.x + 60.0, t.cima.z)), "en el mirador se anda por la plataforma: no por la estación ni fuera de la barandilla")
	_comprobar(m.puntos.size() == 2 and t.datos()["nombre"] == "Teleférico del Cerro", "dos interacciones arriba (bajar y telescopio) y datos para el mapa")
	_comprobar(int(t.get_meta("pinos", 0)) >= 600 and int(t.get_meta("rocas", 0)) >= 50 and int(t.get_meta("camino", 0)) >= 80, "paisaje del cerro: %d pinos, %d rocas y un camino en zigzag de %d tramos" % [t.get_meta("pinos", 0), t.get_meta("rocas", 0), t.get_meta("camino", 0)])
	_comprobar(Teleferico.N_TORRES >= 8 and t.cabinas[0].scale.x > 1.5, "ocho torres en A y cabinas grandes (se ven desde la ciudad)")
	_probar_suavidad(t)

## F-4: perfil suave (aceleración nula en los extremos, sin saltos) y cabinas que se balancean sin pasarse.
func _probar_suavidad(t: Teleferico) -> void:
	_linea("· Movimiento del teleférico")
	var dt := 0.1
	var largo: float = t._largos[t._largos.size() - 1]
	var v_max := 0.0
	var a_max := 0.0
	var tiron := 0.0
	var f_ant := Teleferico.avance(0.0)
	var v_ant := 0.0
	var a_ant := 0.0
	var x := dt
	while x < Teleferico.CICLO:
		var f := Teleferico.avance(x)
		var v := (f - f_ant) / dt * largo
		var a := (v - v_ant) / dt
		v_max = maxf(v_max, absf(v))
		a_max = maxf(a_max, absf(a))
		tiron = maxf(tiron, absf(a - a_ant) / dt)
		f_ant = f
		v_ant = v
		a_ant = a
		x += dt
	_comprobar(v_max > 8.0 and v_max < 25.0, "la cabina llega a %.1f m/s (%.0f km/h) y no más" % [v_max, v_max * 3.6])
	_comprobar(a_max < 0.5, "acelera como mucho a %.3f m/s²" % a_max)
	_comprobar(tiron < 0.06, "con tirón máximo de %.4f m/s³ (sin saltos al salir ni al llegar)" % tiron)
	_comprobar(absf(Teleferico.avance_acel(0.0)) < 1e-9 and absf(Teleferico.avance_acel(Teleferico.VIAJE)) < 1e-9, "la aceleración es cero al salir y al llegar")
	var th_max := 0.0
	var tiempo := 0.0
	while tiempo < Teleferico.CICLO:
		tiempo += 0.05
		t._t = tiempo
		t._poner_cabinas(tiempo)
		t._balancear(tiempo, 0.05)
		th_max = maxf(th_max, absf((t.cabinas[0] as Node3D).rotation.z))
	_comprobar(th_max > 0.002 and th_max <= Teleferico.LIMITE_BALANCEO + 1e-6, "las cabinas se balancean (hasta %.3f rad) sin pasarse del límite" % th_max)
	_comprobar(absf((t.cabinas[0] as Node3D).rotation.z) < 0.03, "y al acabar el ciclo están casi quietas (%.4f rad)" % absf((t.cabinas[0] as Node3D).rotation.z))
