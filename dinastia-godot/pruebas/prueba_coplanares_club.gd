extends Node
## CARAS COPLANARES DEL EDIFICIO DEL CLUB (10-11, sesión 7, «solo club» paso 2): la causa del parpadeo (z-fighting) del suelo.
## Monta el edificio sin fundir mallas y, para todas las cajas (`BoxMesh`) alineadas con los ejes, busca pares de caras que miran al mismo
## lado, están en el MISMO plano (±1 mm) y se solapan: dos superficies así se pelean por el z-buffer y parpadean al mover la cámara.
## Solo cuentan las visibles: con color distinto o con una cara oculta en el interior de un sólido no importa, y se ignora si una está
## totalmente tapada por una tercera caja (no se comprueba: se listan todas para decidir). Falla si hay pares con distinto material.
##   godot --headless --path . res://pruebas/prueba_coplanares_club.tscn     (INFORME=1 lista todos los pares)
var _n := 0
var _fallos := 0
var _vista: VistaEstadio

func _ready() -> void:
	var m := Mundo.new()
	m.generar(["CHI"], 77)
	var club: Club = m.ligas[0].clubes[0]
	PersonajeDT.club_usuario = club.id
	_vista = VistaEstadio.new()
	add_child(_vista)
	var perfil := EstadioPropio.new().perfil(club)
	perfil["niveles"] = 2
	_vista.abrir(club, 0.85, null, null, perfil)

func _process(_d: float) -> void:
	_n += 1
	if _n == 8:
		_vista.recorrer()
	if _n == 20:
		_correr(_vista._explorador)
		print("===== FIN. %d fallos" % _fallos)
		get_tree().quit(1 if _fallos > 0 else 0)

func _correr(ex: ExploradorEstadio) -> void:
	var d: Dictionary = ex._datos
	var raiz := Node3D.new()
	add_child(raiz)
	var horm := StandardMaterial3D.new()
	horm.albedo_color = Color(0.5, 0.5, 0.5)
	EdificioClub.montar(raiz, d["x0"], d["z_out"], d["z_fin"], Color(0.7, 0.1, 0.1), Color(0.9, 0.9, 0.9), horm, horm, "Club Ficticio")
	var cajas: Array = []   ## [AABB, material]
	for mi: MeshInstance3D in raiz.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh is BoxMesh and mi.visible and is_equal_approx(absf(mi.global_transform.basis.x.normalized().x), 1.0) \
				and is_equal_approx(absf(mi.global_transform.basis.y.normalized().y), 1.0):
			cajas.append([mi.global_transform * mi.get_aabb(), mi.material_override, mi])
	print("cajas alineadas: ", cajas.size())
	var pares := 0
	for i in cajas.size():
		for j in range(i + 1, cajas.size()):
			var a: AABB = cajas[i][0]
			var b: AABB = cajas[j][0]
			for eje in 3:
				for lado in 2:   ## 0 = cara inferior/trasera (−), 1 = superior/delantera (+)
					if eje == 1 and lado == 0:
						continue   ## las caras de abajo solo se ven desde el techo de la planta inferior
					var ca: float = a.position[eje] if lado == 0 else a.end[eje]
					var cb: float = b.position[eje] if lado == 0 else b.end[eje]
					if absf(ca - cb) > 0.001:
						continue
					var e1 := (eje + 1) % 3
					var e2 := (eje + 2) % 3
					var s1 := minf(a.end[e1], b.end[e1]) - maxf(a.position[e1], b.position[e1])
					var s2 := minf(a.end[e2], b.end[e2]) - maxf(a.position[e2], b.position[e2])
					if s1 <= 0.01 or s2 <= 0.01 or s1 * s2 < 0.005:
						continue   ## solapes minúsculos (cantos de 1-2 cm) no se ven
					## Oculta: un punto 1 cm hacia fuera del centro del solape cae dentro de otra caja (la cara da a un muro macizo).
					var sitio := a.intersection(b).get_center()
					sitio[eje] = ca + (0.01 if lado == 1 else -0.01)
					var tapada := false
					for k in cajas.size():
						if k != i and k != j and (cajas[k][0] as AABB).has_point(sitio):
							tapada = true
							break
					if tapada:
						continue
					pares += 1
					var ma: Material = cajas[i][1]
					var mb: Material = cajas[j][1]
					var distinto := ma != mb
					var txt := "eje %s %s plano %.3f solape %.2f×%.2f m  (centro %s)  %s" % ["xyz"[eje], "−" if lado == 0 else "+", ca, s1, s2,
						((a.intersection(b)).get_center()).snapped(Vector3(0.01, 0.01, 0.01)), "MATERIALES DISTINTOS" if distinto else "mismo material"]
					if distinto:
						_fallos += 1
						print("  FALLO ", txt)
					elif OS.get_environment("INFORME") == "1":
						print("  (igual) ", txt)
	print("pares coplanares: ", pares)
	raiz.queue_free()
