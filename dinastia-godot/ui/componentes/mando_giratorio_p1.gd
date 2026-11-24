extends "res://ui/componentes/mando_giratorio_p1_p1.gd"
## (Parte 2 de 2 de `mando_giratorio_p1.gd`.)

func _construir(disp: String) -> void:
	_dispositivo_montado = disp
	for h in _pivote.get_children():
		h.queue_free()
	_piezas.clear()
	_modelo = Node3D.new()
	_pivote.add_child(_modelo)
	var ps := disp == "ps"
	var c_cuerpo := Color("e6e8ee") if ps else Color("2b2f37")
	var c_mando := Color("1b1d22") if ps else Color("15171b")
	var c_tapa := Color("20232a") if ps else Color("3c414c")
	var m_cuerpo := _material(c_cuerpo, 0.5, 0.0)
	m_cuerpo.vertex_color_use_as_albedo = true
	var m_negro := _material(c_mando, 0.5, 0.2)
	## Cuerpo y empuñaduras: una sola malla suave.
	_malla_cuerpo(m_cuerpo)
	if ps:
		## Panel táctil y barra de luz.
		_malla(_modelo, _esfera(), m_negro, Vector3(0, _y_cuerpo(0, -1.5) - 0.05, -1.5), Vector3(2.9, 0.32, 1.5))
		_malla(_modelo, _esfera(), _material(Color("5aa0ff"), 0.3), Vector3(0, 0.15, -4.75), Vector3(2.4, 0.16, 0.14), Vector3(-15, 0, 0))
	else:
		## El botón de guía de Xbox.
		_malla(_modelo, _cilindro(0.55, 0.2), _material(Color("e9ecf0"), 0.3, 0.3), Vector3(0, _y_cuerpo(0, -2.4) + 0.05, -2.4))
	## Gatillos y bumpers: en el borde de delante, asentados en el cuerpo.
	var pos_t := _posiciones(disp)
	for lado: Array in [["L", -1.0], ["R", 1.0]]:
		var s: float = lado[1]
		var nb: String = String(lado[0]) + "B"
		var nt: String = String(lado[0]) + "T"
		var bump := _material(c_tapa, 0.45, 0.1)
		var trig := _material(c_mando, 0.55, 0.1)
		var yb := _y_cuerpo(s * 5.0, -3.3) + 0.1
		var mb := _malla(_modelo, _esfera(), bump, Vector3(s * 5.0, yb, -3.95), Vector3(1.9, 0.3, 0.62), Vector3(-10, -s * 8.0, 0))
		_registrar(nb, mb, [bump], Vector3(s * 5.0, yb + 0.4, -3.95), Vector3(0, 0.3, -0.95).normalized())
		_tira(mb, Vector3(0, 0.55, -0.35), Vector3(1.5, 0.12, 0.1), ControlFC.color_pieza(nb, disp))
		var mt := _malla(_modelo, _esfera(), trig, Vector3(s * 5.0, yb - 0.3, -4.55), Vector3(1.7, 0.5, 0.6), Vector3(-26, -s * 8.0, 0))
		_registrar(nt, mt, [trig], Vector3(s * 5.0, yb - 0.05, -4.95), Vector3(0, -0.05, -1).normalized())
		_tira(mt, Vector3(0, 0.1, -0.9), Vector3(1.3, 0.22, 0.08), ControlFC.color_pieza(nt, disp))
		_icono_sobre(nb, Vector3(s * 5.0, yb + 0.31, -3.92), 1.2, disp, Vector3(-10, 0, 0))
		_icono_sobre(nt, Vector3(s * 5.0, yb - 0.1, -4.85), 1.1, disp, Vector3(-26, 0, 0))
	## Sticks: base hundida, vástago y capuchón, con un aro de su color.
	for k: String in ["LS", "RS"]:
		var p: Vector3 = pos_t[k]
		var y := _y_cuerpo(p.x, p.z)
		var base := _material(Color("0f1013"), 0.7, 0.0)
		var tapa := _material(Color("30333b") if not ps else Color("43474f"), 0.8, 0.0)
		var raiz := Node3D.new()
		raiz.position = Vector3(p.x, y, p.z)
		_modelo.add_child(raiz)
		_malla(raiz, _cilindro(1.0, 0.16), base, Vector3(0, -0.02, 0))
		_aro(raiz, Vector3(0, 0.07, 0), 1.0, ControlFC.color_pieza(k, disp))
		_malla(raiz, _cilindro(0.34, 0.5), tapa, Vector3(0, 0.25, 0))
		_malla(raiz, _cilindro(0.78, 0.3), tapa, Vector3(0, 0.55, 0))
		var rodete := TorusMesh.new()
		rodete.inner_radius = 0.62
		rodete.outer_radius = 0.78
		_malla(raiz, rodete, base, Vector3(0, 0.7, 0), Vector3(1, 0.45, 1))
		_registrar(k, raiz, [tapa, base], Vector3(p.x, y + 1.5, p.z), Vector3.UP)
		_icono_sobre(k, Vector3(p.x, y + 0.71, p.z), 1.15, disp)
	## Cruceta: una cruz baja sobre un disco de su color.
	var pd: Vector3 = pos_t["DPAD"]
	var yd := _y_cuerpo(pd.x, pd.z)
	var m_dp := _material(Color("14161a"), 0.6, 0.0)
	var dp := Node3D.new()
	dp.position = Vector3(pd.x, yd, pd.z)
	_modelo.add_child(dp)
	_aro(dp, Vector3(0, 0.04, 0), 1.45, ControlFC.color_pieza("DPAD", disp))
	_malla(dp, BoxMesh.new(), m_dp, Vector3(0, 0.12, 0), Vector3(2.1, 0.26, 0.7))
	_malla(dp, BoxMesh.new(), m_dp, Vector3(0, 0.12, 0), Vector3(0.7, 0.26, 2.1))
	_registrar("DPAD", dp, [m_dp], Vector3(pd.x, yd + 1.0, pd.z), Vector3.UP)
	## Los cuatro botones: discos bajos con el aro del color de su mando.
	for k: String in ["A", "B", "X", "Y"]:
		var p2: Vector3 = pos_t[k]
		var y2 := _y_cuerpo(p2.x, p2.z)
		var mb2 := _material(Color("1a1c21"), 0.5, 0.0)
		_hueco(Vector3(p2.x, y2 + 0.005, p2.z), 0.78)
		var bt := _malla(_modelo, _cilindro(0.56, 0.22), mb2, Vector3(p2.x, y2 + 0.02, p2.z))
		_aro(_modelo, Vector3(p2.x, y2 + 0.1, p2.z), 0.6, ControlFC.color_pieza(k, disp))
		_registrar(k, bt, [mb2], Vector3(p2.x, y2 + 0.8, p2.z), Vector3.UP)
		_icono_sobre(k, Vector3(p2.x, y2 + 0.14, p2.z), 1.05, disp)
	## Menú y Vista (o Options y Create).
	for k: String in ["START", "BACK"]:
		var p3: Vector3 = pos_t[k]
		var y3 := _y_cuerpo(p3.x, p3.z)
		var m3 := _material(Color("3a3e47") if not ps else Color("aeb2be"), 0.5, 0.0)
		_hueco(Vector3(p3.x, y3 + 0.005, p3.z), 0.46)
		var b3 := _malla(_modelo, _cilindro(0.3, 0.14), m3, Vector3(p3.x, y3 + 0.0, p3.z))
		_aro(_modelo, Vector3(p3.x, y3 + 0.07, p3.z), 0.3, ControlFC.color_pieza(k, disp))
		_registrar(k, b3, [m3], Vector3(p3.x, y3 + 0.7, p3.z), Vector3.UP)
		_icono_sobre(k, Vector3(p3.x, y3 + 0.1, p3.z), 0.62, disp)
	_aplicar_rotacion()
