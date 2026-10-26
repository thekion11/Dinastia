extends BaseIdea
## SESIÓN 6 (26-10-2026), fila 7: `PersonaRealista` usa el humano de MakeHuman (CC0,
## `PersonaMH`) si sus .glb están en `assets/personas/`, y si no, el escaneo de
## siempre. Los .glb no están en el repositorio (van por LFS, los sube el dueño):
## esta prueba comprueba la rama que toque.

func _probar() -> void:
	_titulo("S6: PERSONA REALISTA DE MAKEHUMAN (fila 7)")
	var asp := PersonaRealista.aspecto("prueba", {"ropa": "burdeos", "pelo": "canoso", "piel": "oscura", "alto": 1.80})
	var p := PersonaRealista.crear(asp)
	if not PersonaMH.disponible():
		_comprobar(p != null and p.name == "PersonaRealista", "sin los .glb de MakeHuman sigue el escaneo de siempre")
		if p != null:
			p.free()
		return
	_comprobar(p != null and p.name == "PersonaMH", "con los .glb de MakeHuman se usa el humano CC0")
	var esq := p.get_node("Modelo/Armature/Skeleton3D") as Skeleton3D
	_comprobar(esq != null and esq.get_bone_count() == 65, "con el esqueleto Quaternius de 65 huesos")
	var ap := p.get_node("Anim") as AnimationPlayer
	_comprobar(ap != null and ap.has_animation("idle") and ap.autoplay == "idle", "respira con el «Idle» de la UAL")
	var visibles := {}
	for mi in esq.find_children("*", "MeshInstance3D", false, false):
		if (mi as MeshInstance3D).visible:
			visibles[String(mi.name)] = mi
	_comprobar(visibles.has("Tr_Chaqueta") and visibles.has("Tr_Pantalon") and not visibles.has("Tr_Abrigo") and not visibles.has("Cuerpo_Torso"),
		"vestido de traje, sin abrigo y sin la piel que tapa la ropa")
	_comprobar(visibles.has("Pelo_canoso") and not visibles.has("Pelo_corto"), "el pelo canoso elige su malla")
	var chaqueta := (visibles["Tr_Chaqueta"] as MeshInstance3D).material_override as StandardMaterial3D
	_comprobar(chaqueta != null and chaqueta.albedo_color.is_equal_approx(PersonaRealista.ROPAS["burdeos"]), "la chaqueta toma el color del aspecto")
	var ojos := (visibles["Ojos"] as MeshInstance3D).material_override as StandardMaterial3D
	_comprobar(ojos != null and ojos.vertex_color_use_as_albedo, "los ojos con su iris (color por vértice)")
	var caja := AABB()
	var primera := true
	for mi2 in visibles.values():
		var a: AABB = (mi2 as MeshInstance3D).global_transform * (mi2 as MeshInstance3D).get_aabb() if (mi2 as MeshInstance3D).is_inside_tree() else (p.get_node("Modelo") as Node3D).transform * (mi2 as MeshInstance3D).get_aabb()
		caja = a if primera else caja.merge(a)
		primera = false
	_comprobar(absf(caja.size.y - 1.80) < 0.12 and absf(caja.position.y) < 0.1, "mide lo pedido (%.2f m) y pisa el suelo (%.2f)" % [caja.size.y, caja.position.y])
	p.free()
