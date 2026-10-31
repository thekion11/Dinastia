extends BaseIdea
## ESCALERAS CON GENTE (27-10-2026): suben y bajan peldaño a peldaño, con el ciclo de paso ajustado; las bocas del metro, la
## escalinata del ayuntamiento y la estación del teleférico registran sus escaleras.

func _probar() -> void:
	_titulo("ESCALERAS · PASOS SINCRONIZADOS CON LOS PELDAÑOS")
	## Altura escalonada: dentro de cada peldaño se queda plana y luego sube.
	var h0 := 0.0
	var h1 := 1.2
	_comprobar(is_equal_approx(EscaleraVida.altura(0.0, 6, h0, h1), 0.0) and is_equal_approx(EscaleraVida.altura(1.0, 6, h0, h1), 1.2), "empieza abajo y acaba arriba")
	_comprobar(EscaleraVida.altura(0.02, 6, h0, h1) < 0.01 and EscaleraVida.altura(0.1, 6, h0, h1) > 0.15, "plana al inicio de cada peldaño, sube a mitad")
	var prev := -1.0
	var mono := true
	for k in 101:
		var h := EscaleraVida.altura(float(k) / 100.0, 6, h0, h1)
		if h < prev - 0.0001:
			mono = false
		prev = h
	_comprobar(mono, "nunca baja al subir")
	var b := CityBuilder.new()
	add_child(b)
	var ex := ExploradorCiudad.new()
	ex.cb = b
	add_child(ex)
	var ev := EscaleraVida.new()
	ev.expl = ex
	add_child(ev)
	EscaleraVida.registrar(b, Vector3(0, -1.8, 3), Vector3(0, 0, -2.5), 6)
	ev.iniciar(0, false)   ## baja
	var nodo: Node3D = (ev._activas[0]["fig"] as Dictionary)["nodo"]
	_comprobar(absf(nodo.position.y) < 0.01, "el que baja empieza arriba")
	ev._mover(0.5 * 6.0 * EscaleraVida.V_PASO)
	_comprobar(nodo.position.y < -0.7 and nodo.position.y > -1.1, "a mitad de camino va a media altura (%.2f)" % nodo.position.y)
	var ap: AnimationPlayer = (ev._activas[0]["fig"] as Dictionary)["anim"]
	_comprobar(ap.speed_scale > 0.0 and ap.current_animation == "caminar", "camina con el ciclo ajustado (vel %.2f)" % ap.speed_scale)
	ev._mover(10.0)
	_comprobar(ev._activas.is_empty(), "al llegar abajo desaparece")
	ev.iniciar(0, true)   ## sube
	_comprobar(absf((ev._activas[0]["fig"] as Dictionary)["nodo"].position.y + 1.8) < 0.01, "el que sube empieza abajo")
	ev._mover(10.0)
	_comprobar(ev._activas.is_empty(), "y al llegar arriba desaparece")
