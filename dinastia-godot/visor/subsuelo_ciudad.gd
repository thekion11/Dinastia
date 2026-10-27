class_name SubsueloCiudad
extends "res://visor/subsuelo_ciudad_p1.gd"
## (Parte 2 de 2 de `subsuelo_ciudad.gd`.)

func _galeria_electrica() -> void:
	var bandeja := _mat(Color(0.4, 0.4, 0.42), 0.5)
	var colores := [Color(0.7, 0.1, 0.1), Color(0.1, 0.1, 0.12), Color(0.8, 0.5, 0.1)]
	for sx: float in [18.6, 23.4]:
		_caja(Vector3(sx, 3.3, -18.0), Vector3(0.6, 0.08, 28.0), bandeja)
		for c in 3:
			_tubo(Vector3(sx - 0.18 + float(c) * 0.18, 3.42, -32.0), Vector3(sx - 0.18 + float(c) * 0.18, 3.42, -4.0), 0.07, _mat(colores[c], 0.5))
	for k in 5:
		_lampara(Vector3(21.0, ALTO - 0.25, -6.0 - float(k) * 6.0), k % 2 == 0)
	var cercanos: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for k in 4:
		var z := -9.0 - float(k) * 6.0
		_caja(Vector3(22.9, 1.2, z), Vector3(0.9, 2.4, 1.6), _mat(Color(0.42, 0.48, 0.44), 0.6))
		var lam := _mat(Color(0.1, 0.8, 0.2), 0.4, 1.6)
		_caja(Vector3(22.42, 2.1, z), Vector3(0.05, 0.2, 0.2), lam)
		var rot := _rotulo(Vector3(22.38, 1.5, z), "", 0.006, false, -PI * 0.5)
		_armarios.append({"cerca": cercanos[k], "lampara": lam, "rotulo": rot})
	_rotulo(Vector3(21.0, 3.0, -32.6), "⚡ ALTA TENSIÓN", 0.012, false, 0.0)

func _galeria_agua() -> void:
	var azul := _mat(Color(0.2, 0.42, 0.7), 0.4)
	var rojo := _mat(Color(0.75, 0.12, 0.1), 0.5)
	for sx: float in [30.8, 35.2]:
		_tubo(Vector3(sx, 1.3, 3.0), Vector3(sx, 1.3, 33.0), 0.7, azul)
		for k in 6:
			var z := 6.0 + float(k) * 5.0
			_tubo(Vector3(sx, 1.3, z - 0.1), Vector3(sx, 1.3, z + 0.1), 0.82, _mat(Color(0.5, 0.52, 0.55), 0.5))
			if k % 2 == 1:
				_tubo(Vector3(sx, 2.0, z), Vector3(sx, 2.6, z), 0.06, rojo)
				_caja(Vector3(sx, 2.65, z), Vector3(0.7, 0.08, 0.7), rojo)
	for k in 4:
		_lampara(Vector3(33.0, ALTO - 0.25, 7.0 + float(k) * 7.0), k % 2 == 0)
	_rotulo_agua = _rotulo(Vector3(33.0, 3.0, 31.8), "", 0.01, false, PI)

func _galeria_gas() -> void:
	var amarillo := _mat(Color(0.9, 0.72, 0.1), 0.45)
	for sx: float in [44.6, 49.4]:
		_tubo(Vector3(sx, 1.0, -32.0), Vector3(sx, 1.0, -4.0), 0.3, amarillo)
		_tubo(Vector3(sx, 3.2, -32.0), Vector3(sx, 3.2, -4.0), 0.22, amarillo)
	for k in 4:
		_lampara(Vector3(47.0, ALTO - 0.25, -6.0 - float(k) * 7.0), k % 2 == 0)
	_rotulo_gas = _rotulo(Vector3(47.0, 2.6, -32.6), "", 0.01, false, 0.0)

func _sala_control() -> void:
	for k in 4:
		_lampara(Vector3(64.0 + float(k) * 5.0, ALTO - 0.25, 0), k % 2 == 0)
	_caja(Vector3(71.0, 2.8, -9.75), Vector3(14.0, 3.6, 0.2), _mat(Color(0.05, 0.1, 0.12), 0.3, 0.5))
	_pantalla = _rotulo(Vector3(71.0, 2.8, -9.6), "", 0.0085, false, 0.0)
	_pantalla.modulate = Color(0.5, 1.0, 0.7)
	## Armarios de servidores contra la pared oeste y mesa de mapas en el centro.
	var rack := _mat(Color(0.16, 0.17, 0.19), 0.5)
	for k in 6:
		var z := -8.0 + float(k) * 2.2
		_caja(Vector3(61.0, 1.1, z), Vector3(0.9, 2.2, 1.6), rack)
		for l in 3:
			_caja(Vector3(61.5, 0.6 + float(l) * 0.6, z), Vector3(0.04, 0.12, 1.2), _mat(Color(0.1, 0.8, 0.3) if (k + l) % 3 else Color(0.9, 0.6, 0.1), 0.4, 1.5))
	_caja(Vector3(71.0, 0.5, 0.0), Vector3(6.0, 1.0, 2.6), _mat(Color(0.3, 0.26, 0.2), 0.7))
	_caja(Vector3(71.0, 1.02, 0.0), Vector3(5.6, 0.04, 2.2), _mat(Color(0.2, 0.4, 0.5), 0.5, 0.6))
	for c in [[64.0, Color(0.1, 0.75, 0.25), "sub_reparar", "REPARAR AVERÍAS"], [76.0, Color(0.85, 0.12, 0.1), "sub_cortar", "PALANCA: CORTAR LA LUZ DEL SECTOR"]]:
		var x: float = c[0]
		_caja(Vector3(x, 0.55, 8.2), Vector3(3.0, 1.1, 1.0), _mat(Color(0.3, 0.32, 0.34), 0.5))
		_caja(Vector3(x, 1.2, 8.0), Vector3(0.6, 0.2, 0.6), _mat(c[1], 0.4, 1.8))
		_rotulo(Vector3(x, 2.1, 8.2), String(c[3]), 0.008)
		puntos.append({"pos": Vector2(x, 6.8), "k": c[2], "n": ("Reparar todas las averías" if c[2] == "sub_reparar" else "Palanca roja: cortar la luz del sector"), "radio": 2.2})

func _cuarto_olvidado() -> void:
	var l := OmniLight3D.new()
	l.omni_range = 11.0
	l.light_color = Color(0.5, 0.65, 1.0)
	l.light_energy = 1.8
	l.position = Vector3(104.0, 2.4, 0)
	add_child(l)
	_rotulo(Vector3(90.0, 2.4, 0), "¿QUÉ HACES AQUÍ ABAJO?", 0.01, false, PI * 0.5 + PI)
	_caja(Vector3(102.0, 0.4, 3.6), Vector3(3.0, 0.8, 1.0), _mat(Color(0.5, 0.2, 0.2), 0.9))
	_caja(Vector3(106.0, 0.8, -3.4), Vector3(1.6, 1.6, 1.0), _mat(Color(0.35, 0.28, 0.2), 0.8))
	_caja(Vector3(108.4, 1.3, 0), Vector3(0.8, 0.9, 1.2), _mat(Color(0.2, 0.2, 0.22), 0.5))
	_caja(Vector3(108.0, 1.3, 0), Vector3(0.05, 0.7, 1.0), _mat(Color(0.5, 0.8, 1.0), 0.3, 2.0))
	_rotulo(Vector3(107.9, 2.2, 0), "DINASTÍA FC · SIEMPRE", 0.007, false, -PI * 0.5)
	puntos.append({"pos": Vector2(106.4, 0), "k": "sub_secreto", "n": "Mirar la tele vieja", "radio": 2.4})
