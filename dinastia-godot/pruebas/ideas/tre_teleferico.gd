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
	_probar_visual(t, b)

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

## F-4b (27-10): lo VISUAL del teleférico: cabina con ventanas y viajeros, torres de celosía, ladera con flora y rocas, estaciones con detalles.
func _probar_visual(t: Teleferico, b: CityBuilder) -> void:
	_linea("· Aspecto del teleférico")
	var cab := TelefericoCabina.montar(Color.RED)
	add_child(cab)   ## en el árbol, para que los viajeros salgan vestidos
	TelefericoCabina.poblar(cab, 5)
	_comprobar(cab.get_child_count() >= 33, "la cabina tiene %d piezas (pinza, brazo, techo, ventanas por los cuatro lados, puerta y viajeros)" % cab.get_child_count())
	var cristales := 0
	for n in cab.get_children():
		var mi := n as MeshInstance3D
		if mi != null and mi.material_override is StandardMaterial3D and (mi.material_override as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_ALPHA:
			cristales += 1
	_comprobar(cristales >= 5, "con cristal por los cuatro lados y el lucernario (%d paneles)" % cristales)
	var viajeros := 0
	for n2 in cab.get_children():
		if not (n2 is MeshInstance3D):
			viajeros += 1
	_comprobar(viajeros == TelefericoCabina.N_VIAJEROS, "los %d viajeros son personas de la ciudad (Mini3D.persona), no cápsulas (%d)" % [TelefericoCabina.N_VIAJEROS, viajeros])
	cab.free()
	var raiz := Node3D.new()
	add_child(raiz)
	var p := t.puntos[3]
	var piezas := TelefericoTorre.montar(raiz, b, p, 0.5)
	_comprobar(piezas >= 100 and raiz.get_child_count() == 3, "cada torre es de celosía (%d barras y ruedas en %d mallas)" % [piezas, raiz.get_child_count()])
	raiz.queue_free()
	_comprobar(int(t.get_meta("arbustos", 0)) >= 1000 and int(t.get_meta("caducos", 0)) >= 100, "la ladera tiene %d arbustos y %d árboles de hoja caduca" % [t.get_meta("arbustos", 0), t.get_meta("caducos", 0)])
	var paso := CityBuilder.TERRENO_LADO / float(CityBuilder.TERRENO_CELDAS)
	var x0 := -CityBuilder.TERRENO_LADO * 0.5 + 60.0 * paso
	var z0 := -CityBuilder.TERRENO_LADO * 0.5 + 100.0 * paso
	_comprobar(is_equal_approx(TelefericoFlora.altura_malla(b, x0, z0), b.altura_en(x0, z0)), "la altura de la malla coincide con el terreno en los vértices de la rejilla")
	var medio := TelefericoFlora.altura_malla(b, x0 + paso * 0.5, z0 + paso * 0.5)
	var h_a := b.altura_en(x0 + paso, z0)
	var h_b := b.altura_en(x0, z0 + paso)
	_comprobar(is_equal_approx(medio, (h_a + h_b) * 0.5), "y entre vértices sigue el triángulo de la malla (lo que se ve), no la curva")
	_comprobar(int(t.cuenta.get("detalles_estacion", 0)) >= 100, "las dos estaciones suman %d detalles (ventanas, puerta, línea amarilla, barandilla, bancos, farolas)" % int(t.cuenta.get("detalles_estacion", 0)))
