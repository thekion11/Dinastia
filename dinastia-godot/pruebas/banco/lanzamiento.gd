extends "res://pruebas/banco/base.gd"
## [Banco · grupo «lanzamiento»] Las filas «verificar jugando» de LANZAMIENTO de
## `docs/04_auditorias/clasificacion_ideas_2026-10-27.md` que se pueden probar SIN GPU (2-11-2026): existían en
## el código y les faltaba su prueba. Cada sección dice la fila (número del plan) que cierra.

## 385-392: las ocho perillas tácticas (altura de la línea, presión, ritmo, amplitud, salida, criterio de remate,
## marcaje y trampa del fuera de juego) existen en la pizarra, se copian al duplicar y MUEVEN la fuerza del equipo
## en el sentido que dice su nombre.
func _probar_lanzamiento_tactica() -> void:
	_titulo("LANZAMIENTO · LAS PERILLAS TÁCTICAS (385-392)")
	var base := Tactica.new()
	var ata0 := base.multiplicador_ataque()
	var def0 := base.multiplicador_defensa()
	_comprobar(is_equal_approx(ata0, 1.0) and is_equal_approx(def0, 1.0), "con todo en «medio» la táctica no cambia nada (%.3f / %.3f)" % [ata0, def0])
	var t := Tactica.new()
	t.linea = Tactica.Nivel.ALTO
	_comprobar(t.multiplicador_ataque() > ata0 and t.multiplicador_defensa() < def0, "385 línea adelantada: más ataque, defensa más expuesta")
	t = Tactica.new()
	t.presion = Tactica.Nivel.ALTO
	_comprobar(t.multiplicador_ataque() > ata0, "386 presión alta: más ataque")
	t = Tactica.new()
	t.ritmo = Tactica.Nivel.ALTO
	_comprobar(t.multiplicador_ataque() > ata0 and t.multiplicador_defensa() < def0, "387 ritmo alto: más ataque, más desgaste atrás")
	t = Tactica.new()
	t.amplitud = Tactica.Nivel.ALTO
	_comprobar(t.multiplicador_ataque() > ata0 and t.multiplicador_defensa() < def0, "388 ataque abierto: más ataque, menos solidez")
	t = Tactica.new()
	t.salida_corta = true
	_comprobar(t.multiplicador_ataque() > ata0, "389 salida jugada desde atrás: más ataque")
	t = Tactica.new()
	t.tiro_lejano = true
	_comprobar(t.multiplicador_ataque() > ata0, "390 criterio de remate (tiro de lejos): más ataque")
	t = Tactica.new()
	t.marca_al_hombre = true
	_comprobar(t.multiplicador_defensa() > def0, "391 marca al hombre: más defensa")
	t = Tactica.new()
	t.fuera_de_juego = true
	_comprobar(t.multiplicador_defensa() > def0, "392 trampa del fuera de juego: más defensa")
	## Se copian todas al duplicar y la pizarra ofrece las diez perillas.
	t = Tactica.new()
	t.linea = Tactica.Nivel.ALTO
	t.presion = Tactica.Nivel.ALTO
	t.ritmo = Tactica.Nivel.BAJO
	t.amplitud = Tactica.Nivel.ALTO
	t.salida_corta = true
	t.tiro_lejano = true
	t.marca_al_hombre = true
	t.fuera_de_juego = true
	var d := t.duplicar()
	_comprobar(d.linea == t.linea and d.presion == t.presion and d.ritmo == t.ritmo and d.amplitud == t.amplitud and d.salida_corta and d.tiro_lejano \
		and d.marca_al_hombre and d.fuera_de_juego, "duplicar() conserva las ocho perillas")
	_comprobar(is_equal_approx(d.multiplicador_ataque(), t.multiplicador_ataque()) and is_equal_approx(d.multiplicador_defensa(), t.multiplicador_defensa()), "y la copia rinde igual")
	var claves: Array = []
	for p: Array in t.perillas_con_balon() + t.perillas_sin_balon():
		claves.append(String(p[0]))
	for k: String in ["linea", "presion", "ritmo", "amplitud", "salida_corta", "tiro_lejano", "marca_al_hombre", "fuera_de_juego", "verticalidad", "tras_perdida"]:
		_comprobar(claves.has(k), "la pizarra ofrece la perilla «%s»" % k)

## 1024-1025: escalado de texto y paleta para daltonismo (accesibilidad de la fila «lanzable»), más el contraste alto (M-302).
func _probar_lanzamiento_accesibilidad() -> void:
	_titulo("LANZAMIENTO · TEXTO ESCALABLE, DALTONISMO Y CONTRASTE (1024, 1025, M-302)")
	var esc0 := Tema.escala_texto
	var dalt0 := Tema.daltonico
	var con0 := Tema.contraste
	Tema.escala_texto = 1.0
	_comprobar(Tema.letra(14) == 14, "escala 1,0: la letra no cambia")
	Tema.escala_texto = 1.5
	_comprobar(Tema.letra(14) == 21 and Tema.letra(10) == 15, "escala 1,5: 14 → 21 y 10 → 15 (%d, %d)" % [Tema.letra(14), Tema.letra(10)])
	Tema.escala_texto = 9.0
	_comprobar(Tema.letra(10) == 16, "la escala se acota a 1,6 (10 → %d)" % Tema.letra(10))
	Tema.escala_texto = 0.1
	_comprobar(Tema.letra(10) == 8 and Tema.letra(30) >= 21, "y a 0,7, sin bajar nunca de 8 px (10 → %d, 30 → %d)" % [Tema.letra(10), Tema.letra(30)])
	Tema.escala_texto = esc0
	Tema.daltonico = false
	_comprobar(Tema.accesible(Tema.BIEN) == Tema.BIEN and Tema.accesible(Tema.MAL) == Tema.MAL and Tema.accesible(Tema.ORO) == Tema.ORO, "sin modo daltónico los colores pasan tal cual")
	Tema.daltonico = true
	_comprobar(Tema.accesible(Tema.BIEN) == Tema.BIEN_DALT and Tema.accesible(Tema.MAL) == Tema.MAL_DALT and Tema.accesible(Tema.ORO) == Tema.ORO_DALT, "con modo daltónico bien/mal/oro cambian al par seguro")
	_comprobar(Tema.accesible(Tema.BIEN_DALT) != Tema.accesible(Tema.MAL_DALT), "el «bien» y el «mal» daltónicos se distinguen entre sí")
	var medio := Color(Tema.BIEN, 0.5)
	_comprobar(is_equal_approx(Tema.accesible(medio).a, 0.5) and Color(Tema.accesible(medio), 1.0) == Tema.BIEN_DALT, "se conserva el alfa al cambiar el color")
	_comprobar(Tema.accesible(Color(0.3, 0.2, 0.9)) == Color(0.3, 0.2, 0.9), "los demás colores no se tocan")
	Tema.daltonico = dalt0
	Tema.contraste = true
	_comprobar(Color(Tema.accesible(Tema.TEXTO), 1.0) == Color.WHITE and Color(Tema.accesible(Tema.SUAVE), 1.0) == Tema.SUAVE_CONTRASTE, "contraste alto: el texto va a blanco y el suave se aclara")
	Tema.contraste = con0
