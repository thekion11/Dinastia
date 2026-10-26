extends BaseIdea
## EL PERSONAL DEL CLUB TRABAJA EN SU PUESTO (26-10-2026, paquete pint).
## Antes, al llegar a su puesto cada persona se quedaba «parado» 22-40 s: una
## estatua. Ahora hace de vez en cuando un gesto de su oficio (librería
## «banda» de `PersonajeDT`), uno distinto cada vez, y luego sigue su ronda.

func _probar() -> void:
	_titulo("PERSONAL CON RUTINA: GESTOS DE OFICIO EN EL PUESTO")
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var perfil := EstadioPropio.new().perfil(m.ligas[0].clubes[0])
	perfil["forma"] = "cuenco"
	perfil["tunel"] = "central"
	PersonajeDT.club_usuario = ""
	PersonalEstadio.hora = -1.0
	var raiz := Node3D.new()
	add_child(raiz)
	TunelVestuario.montar(raiz, perfil, 2, null)
	var pe := raiz.find_children("*", "PersonalEstadio", true, false)[0] as PersonalEstadio
	_comprobar(pe.gente.size() >= 10, "hay personal en el club (%d)" % pe.gente.size())
	var gestos := {}
	var distintos := {}
	var movidos := {}
	var inicio := {}
	for g: Dictionary in pe.gente:
		inicio[g["clave"]] = (g["nodo"] as Node3D).position
	## 90 s de juego a pasos de 0,1 s.
	for i in 900:
		pe._process(0.1)
		for g: Dictionary in pe.gente:
			var a := g.get("anim") as AnimationPlayer
			var k := String(g["clave"])
			if a != null and a.current_animation.begins_with("banda/"):
				gestos[k] = int(gestos.get(k, 0)) + 1
				var dk: Dictionary = distintos.get(k, {})
				dk[a.current_animation] = true
				distintos[k] = dk
			if (g["nodo"] as Node3D).position.distance_to(inicio[k]) > 0.5:
				movidos[k] = true
	_comprobar(gestos.size() >= pe.gente.size() - 2, "casi todos hacen gestos de su oficio en el puesto (%d de %d)" % [gestos.size(), pe.gente.size()])
	var con_dos := distintos.values().filter(func(d: Dictionary) -> bool: return d.size() >= 2).size()
	_comprobar(con_dos >= 5, "y no siempre el mismo: %d alternan dos gestos" % con_dos)
	_comprobar(movidos.size() >= pe.gente.size() - 2, "y siguen haciendo su ronda (%d se han movido)" % movidos.size())
	raiz.queue_free()
