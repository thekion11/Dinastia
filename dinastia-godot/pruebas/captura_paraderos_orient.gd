extends Node
## ¿Mira cada paradero a su calle? Para cada paradero («paradero_red») busca el punto más cercano de las rutas de autobús y comprueba que el
## frente (+Z local: cabecera y panel) apunta hacia la calzada y la espalda a los edificios. Imprime los que no.
var _n := 0
var _vista: VistaCiudad

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 4713)
	m.tomar_el_mando(m.ligas[0].clubes[0].id)
	_vista = VistaCiudad.new()
	add_child(_vista)
	_vista.abrir(m.mi_club(), m.obras, m.ciudad, m.perfil_estadio_de(m.mi_club()))

func _process(_d: float) -> void:
	_n += 1
	if _n < 10:
		return
	var cb := _vista.get("_ciudad") as CityBuilder
	var traf := cb.get_node_or_null("Trafico") as TraficoCiudad
	var rutas: Array[PackedVector3Array] = []
	for v: Dictionary in traf._vehiculos:
		if v.has("paradas") and not (v["paradas"] as Array).is_empty():
			var r = traf._rutas[int(v["ruta"])]
			if not rutas.has(r.puntos):
				rutas.append(r.puntos)
	var mal := 0
	var total := 0
	for n: Node3D in get_tree().get_nodes_in_group("paradero_red"):
		var p := n.global_position
		var mejor := 1e9
		var hacia := Vector3.ZERO
		for pts: PackedVector3Array in rutas:
			for i in pts.size() - 1:
				var a := pts[i]
				var b := pts[i + 1]
				var ab := b - a
				var t := clampf(((p - a).dot(ab)) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
				var q := a + ab * t
				var d := Vector2(q.x - p.x, q.z - p.z).length()
				if d < mejor:
					mejor = d
					hacia = Vector3(q.x - p.x, 0, q.z - p.z)
		total += 1
		var frente := n.global_transform.basis.z
		frente.y = 0
		var ok := mejor > 40.0 or hacia.normalized().dot(frente.normalized()) > 0.5
		if not ok:
			mal += 1
			print("MAL ", n.get_meta("codigo_red", "?"), " en ", p, " giro ", int(rad_to_deg(n.global_rotation.y)), " calle a ", int(mejor), " m, dot ", hacia.normalized().dot(frente.normalized()))
	print("paraderos: ", total, " mal orientados: ", mal)
	get_tree().quit()
