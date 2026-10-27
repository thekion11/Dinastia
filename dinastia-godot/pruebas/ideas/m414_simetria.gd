extends BaseIdea
## M-414 (27-10-2026): la sonda de simetría (`pruebas/sonda_simetria_formacion.gd`) solo imprimía. Ahora, con
## umbral y en TODAS las formaciones de la tabla `FORMS`: el visitante sale en el espejo exacto del local
## (simetría respecto al centro del campo, mirando al otro arco), los once dentro del campo y sin dos
## jugadores encima (a más de 4 m). Un sesgo local/visita del motor empezaba siempre aquí.

const TOLERANCIA := 0.05
const SEPARACION := 4.0
const MEDIO_ANCHO := 34.0
const MEDIO_LARGO := 52.5

func _probar() -> void:
	_titulo("M-414: LAS FORMACIONES SALEN EN ESPEJO (LOCAL Y VISITA)")
	var m := Mundo.new()
	m.generar(["CHI"], 777)
	var a: Club = m.ligas[0].clubes[3]
	var l := Puente3D.once(a.once())
	var forms: Dictionary = Datos.tabla("FORMS")
	_comprobar(forms.size() >= 5, "hay formaciones en la tabla (%d)" % forms.size())
	var mal_espejo: Array[String] = []
	var mal_dentro: Array[String] = []
	var mal_juntos: Array[String] = []
	var raiz := Node3D.new()
	add_child(raiz)
	for nombre: String in forms:
		var sp := PlayerSpawner.new()
		var f := Puente3D.formacion(nombre)
		var loc: Array = sp.spawn_team(raiz, l["xi"], l["jugadores"], f, true, Puente3D.kit(a), Puente3D.kit_portero(a))
		var vis: Array = sp.spawn_team(raiz, l["xi"], l["jugadores"], f, false, Puente3D.kit(a), Puente3D.kit_portero(a))
		for i in loc.size():
			var bl: Vector3 = loc[i]["base_pos"]
			var bv: Vector3 = vis[i]["base_pos"]
			var giro := absf(wrapf((vis[i]["node"] as Node3D).rotation.y - (loc[i]["node"] as Node3D).rotation.y, -PI, PI))
			if (bl + bv).length() > TOLERANCIA or absf(giro - PI) > TOLERANCIA:
				mal_espejo.append("%s %s" % [nombre, loc[i]["slot_code"]])
			if absf(bl.x) > MEDIO_ANCHO or absf(bl.z) > MEDIO_LARGO:
				mal_dentro.append("%s %s (%.1f, %.1f)" % [nombre, loc[i]["slot_code"], bl.x, bl.z])
			for k in range(i + 1, loc.size()):
				var otro: Vector3 = loc[k]["base_pos"]
				if Vector2(bl.x - otro.x, bl.z - otro.z).length() < SEPARACION:
					mal_juntos.append("%s %s-%s" % [nombre, loc[i]["slot_code"], loc[k]["slot_code"]])
		_comprobar(loc.size() == 11 and vis.size() == 11, "%s: once por lado" % nombre)
		for h: Node in raiz.get_children():
			h.free()
	_comprobar(mal_espejo.is_empty(), "el visitante es el espejo exacto del local, mirando al otro arco %s" % ("" if mal_espejo.is_empty() else str(mal_espejo.slice(0, 6))))
	_comprobar(mal_dentro.is_empty(), "todos dentro del campo %s" % ("" if mal_dentro.is_empty() else str(mal_dentro.slice(0, 6))))
	_comprobar(mal_juntos.is_empty(), "nadie a menos de %.0f m de un compañero %s" % [SEPARACION, "" if mal_juntos.is_empty() else str(mal_juntos.slice(0, 6))])
	raiz.free()
