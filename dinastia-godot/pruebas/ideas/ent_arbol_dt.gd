extends BaseIdea
## EL ÁRBOL DE HABILIDADES DEL ENTRENADOR (`Entrenamiento`, pista B punto 10, 6-11): sube la cobertura de `nucleo/entrenamiento.gd` (10 de 27 funciones nombradas).
## Cada nodo de la tabla tiene nombre, icono, descripción, coste y un requisito que existe; el motivo de «no se puede» es el correcto en cada estado; abrir un
## nodo gasta sus puntos y emite sus señales; los factores que toca el árbol valen lo que dicen y «Genio» reemplaza a «Pizarra fina»; todo sobrevive a guardar.

func _probar() -> void:
	_titulo("ÁRBOL DEL DT: la tabla es coherente")
	var e := Entrenamiento.new()
	var ramas := e.dt_ramas()
	var claves: Array[String] = []
	for r: String in ramas:
		for k: String in ramas[r]:
			claves.append(k)
	_comprobar(claves.size() >= 12 and ramas.size() >= 3, "hay ramas y nodos (%d ramas, %d nodos)" % [ramas.size(), claves.size()])
	var raros: Array[String] = []
	for k in claves:
		var req := e.dt_requisito(k)
		if e.dt_nombre(k) == "" or e.dt_nombre(k) == k or e.dt_icono(k) == "" or e.dt_descripcion(k) == "" or e.dt_coste(k) < 1 or (req != "" and not claves.has(req)):
			raros.append(k)
	_comprobar(raros.is_empty(), "todo nodo tiene nombre, icono, descripción, coste ≥ 1 y un requisito que existe %s" % str(raros))
	_comprobar(e.dt_coste("no_existe") == 0 and e.dt_requisito("no_existe") == "" and e.dt_icono("no_existe") == "" and e.dt_nombre("no_existe") == "no_existe", "una clave que no existe no rompe nada")
	_comprobar(e.dt_motivo("no_existe") == "no disponible", "y su motivo es «no disponible»")

	_titulo("ÁRBOL DEL DT: abrir nodos")
	var senal := [0, ""]
	e.dt_habilidad.connect(func(_c: String, n: String) -> void:
		senal[0] += 1
		senal[1] = n)
	var con_req := ""
	var sin_req := ""
	for k in claves:
		if e.dt_requisito(k) != "" and con_req == "":
			con_req = k
		if e.dt_requisito(k) == "" and sin_req == "":
			sin_req = k
	e.dt_puntos = 0
	_comprobar(e.dt_motivo(sin_req).begins_with("te faltan"), "sin puntos: «%s»" % e.dt_motivo(sin_req))
	_comprobar(e.dt_aprender(sin_req) != "" and not e.dt_tiene(sin_req), "no se abre sin puntos")
	e.dt_sumar_puntos(50)
	_comprobar(e.dt_puntos == 50, "se suman los puntos (%d)" % e.dt_puntos)
	e.dt_sumar_puntos(-500)
	_comprobar(e.dt_puntos == 0, "y nunca bajan de 0 (%d)" % e.dt_puntos)
	e.dt_sumar_puntos(50)
	_comprobar(e.dt_motivo(con_req).begins_with("antes:"), "con requisito sin abrir: «%s»" % e.dt_motivo(con_req))
	var antes := e.dt_puntos
	_comprobar(e.dt_aprender(sin_req) == "" and e.dt_tiene(sin_req), "con puntos se abre un nodo sin requisito (%s)" % sin_req)
	_comprobar(e.dt_puntos == antes - e.dt_coste(sin_req), "y gasta su coste (%d → %d)" % [antes, e.dt_puntos])
	_comprobar(senal[0] == 1 and senal[1] == e.dt_nombre(sin_req), "emite `dt_habilidad` con su nombre (%s)" % str(senal[1]))
	_comprobar(e.dt_motivo(sin_req) == "ya la tienes" and e.dt_aprender(sin_req) == "ya la tienes", "abrirlo otra vez dice «ya la tienes»")
	if e.dt_requisito(con_req) == sin_req:
		_comprobar(e.dt_motivo(con_req) == "" , "con el requisito abierto ya se puede (%s)" % con_req)

	_titulo("ÁRBOL DEL DT: lo que le hace al juego")
	var v := Entrenamiento.new()
	_comprobar(v.bonus_dt() == 1.0 and v.techo_cantera_dt() == 0 and v.factor_instrucciones() == 1.0 and not v.ve_tactica_rival(), "sin nada abierto, todo neutro")
	_comprobar(v.factor_sueldo_dt() == 1.0 and v.factor_sueldo_staff() == 1.0 and v.factor_calma() == 1.0 and v.bono_mediacion() == 0.0 and v.bono_fichajes() == 0.0, "y los factores de sueldo, calma y fichajes también")
	v.dt_nodos["pizarra"] = true
	_comprobar(is_equal_approx(v.bonus_dt(), 1.03), "Pizarra fina: +3 %% (%.2f)" % v.bonus_dt())
	v.dt_nodos["genio"] = true
	_comprobar(is_equal_approx(v.bonus_dt(), 1.06), "Genio REEMPLAZA a Pizarra fina (%.2f, esperado 1.06; sumarlos daría 1.09)" % v.bonus_dt())
	v.dt_nodos["formador"] = true
	_comprobar(v.techo_cantera_dt() == 2, "Formador: +2 de techo de cantera")
	v.dt_nodos["academia"] = true
	_comprobar(v.techo_cantera_dt() == 3, "Academia: +3 (no se suma a Formador)")
	v.dt_nodos["carisma"] = true
	v.dt_nodos["contable"] = true
	v.dt_nodos["psicologo"] = true
	v.dt_nodos["mediador"] = true
	v.dt_nodos["bloque"] = true
	v.dt_nodos["lectura"] = true
	_comprobar(is_equal_approx(v.factor_sueldo_dt(), 1.15) and is_equal_approx(v.factor_sueldo_staff(), 0.85) and v.factor_calma() == 2.0, "carisma, contable y psicólogo")
	_comprobar(is_equal_approx(v.bono_mediacion(), 0.18) and v.factor_instrucciones() == 1.5 and v.ve_tactica_rival(), "mediador, bloque y lectura")
	v.dt_nodos["icono"] = true
	v.dt_nodos["negociador"] = true
	_comprobar(is_equal_approx(v.bono_fichajes(), 0.16), "fichajes: icono 10 %% + negociador 6 %% = %.2f" % v.bono_fichajes())

	_titulo("ÁRBOL DEL DT: sobrevive a guardar")
	v.dt_puntos = 7
	var d := v.a_dic()
	var w := Entrenamiento.new()
	w.desde_dic(JSON.parse_string(JSON.stringify(d)))
	_comprobar(w.dt_puntos == 7 and w.dt_tiene("genio") and w.dt_tiene("icono") and is_equal_approx(w.bonus_dt(), 1.06), "puntos y nodos tras guardar y cargar")
	_comprobar(w.a_dic()["dt_nodos"].size() == v.dt_nodos.size(), "y el mismo número de nodos (%d)" % v.dt_nodos.size())
