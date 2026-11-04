class_name RoperoCasa
extends RefCounted
## EL RINCÓN DEPORTIVO DE TU CASA (M-188, 3-11-2026): lo que el DT compró en la tienda deportiva se ve en la vivienda, junto a la cama: los balones en el suelo (uno por cada uno
## comprado, hasta seis), los botines en un par, la camiseta del club en un maniquí con sus colores y la bufanda colgada. Sin nada comprado no se pone nada.
const BASE := Vector3(-3.6, 0, 3.2)   ## junto a la cama (`CasaDT.POS_CAMA` = (-4.6, 0, 3.45)), hacia el centro de la sala

static func montar(padre: Node3D, ropero: Dictionary, club: Club) -> int:
	var n := 0
	var c1 := Color(club.color1) if club != null else Color(0.12, 0.37, 0.66)
	var c2 := Color(club.color2) if club != null else Color.WHITE
	var balones := mini(int(ropero.get("balon", 0)) + int(ropero.get("balon_playa", 0)), 6)
	for i in balones:
		var esf := SphereMesh.new()
		esf.radius = 0.11
		esf.height = 0.22
		var m := Mini3D.mat(Color(0.95, 0.95, 0.95) if i < int(ropero.get("balon", 0)) else Color(0.95, 0.55, 0.2), 0.5)
		var b := MeshInstance3D.new()
		b.mesh = esf
		b.material_override = m
		b.position = BASE + Vector3(0.28 * float(i % 3), 0.11, 0.3 * float(i / 3))
		padre.add_child(b)
		n += 1
	if int(ropero.get("botines", 0)) > 0:
		for lado: float in [-1.0, 1.0]:
			Mini3D.caja(padre, BASE + Vector3(-0.75 + lado * 0.1, 0.05, 0.2), Vector3(0.12, 0.1, 0.3), Mini3D.mat(Color(0.1, 0.1, 0.12), 0.5))
		n += 1
	if int(ropero.get("camiseta_club", 0)) > 0:
		var mat := Mini3D.mat(c1, 0.7)
		Mini3D.caja(padre, BASE + Vector3(-0.8, 0.5, -0.6), Vector3(0.03, 1.0, 0.03), Mini3D.mat(Color(0.35, 0.35, 0.37), 0.4))     ## el pie del maniquí
		Mini3D.caja(padre, BASE + Vector3(-0.8, 1.15, -0.6), Vector3(0.5, 0.62, 0.22), mat)                                        ## el cuerpo de la camiseta
		for lado: float in [-1.0, 1.0]:
			Mini3D.caja(padre, BASE + Vector3(-0.8 + lado * 0.3, 1.32, -0.6), Vector3(0.14, 0.2, 0.2), mat)                      ## las mangas
		Mini3D.caja(padre, BASE + Vector3(-0.8, 1.2, -0.485), Vector3(0.5, 0.08, 0.02), Mini3D.mat(c2, 0.7))                        ## la franja
		n += 1
	if int(ropero.get("bufanda_club", 0)) > 0:
		Mini3D.caja(padre, BASE + Vector3(-0.8, 1.45, -0.6), Vector3(0.34, 0.07, 0.26), Mini3D.mat(c2, 0.8))
		n += 1
	return n
