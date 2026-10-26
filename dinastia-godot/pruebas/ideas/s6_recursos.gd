extends BaseIdea
## SESIÓN 6 (26-10-2026), filas 7 y 15 de la propuesta de la s4:
##  · la Casa Grande es un complejo de bloques KayKit (CC0), sin `complejo_residencial.glb`;
##  · la maqueta de respaldo del estadio ya no carga `estadio.obj`;
##  · los tres modelos 🟡 quedan fuera de las exportaciones;
##  · radares, pizarra y minimapa dibujan sus líneas con Antialiased Line2D (MIT);
##  · el contador de FPS lleva dentro el Debug Menu (MIT) con F9.

func _probar() -> void:
	_titulo("S6: RECURSOS LIBRES (KayKit, Antialiased Line2D, Debug Menu)")
	_casa_grande()
	_estadio_respaldo()
	_exportacion()
	_lineas()
	_contador()

func _mallas(n: Node, salida: Array) -> void:
	if n is MeshInstance3D:
		salida.append(n)
	for h in n.get_children():
		_mallas(h, salida)

func _casa_grande() -> void:
	var cb := CityBuilder.new()
	add_child(cb)
	## Los rótulos cuelgan de un nodo que crea `build()`; aquí se monta solo la finca.
	var rot := Node3D.new()
	cb.add_child(rot)
	cb.set("_rotulos", rot)
	cb._casa_gigante(Vector3(100, 0, 50), Vector2(120, 114))
	var casa: Node3D = cb.casa_gigante
	_comprobar(casa != null and casa.get_child_count() == CityBuilder.BLOQUES_CASA.size(), "la Casa Grande monta sus %d bloques KayKit" % CityBuilder.BLOQUES_CASA.size())
	var caja := AABB()
	var primera := true
	var rutas_ok := true
	var mallas: Array = []
	_mallas(casa, mallas)
	for mi: MeshInstance3D in mallas:
		var a := mi.global_transform * mi.get_aabb()
		caja = a if primera else caja.merge(a)
		primera = false
	for b in casa.get_children():
		rutas_ok = rutas_ok and String(b.scene_file_path).begins_with("res://assets/ciudad/kaykit/")
	_comprobar(rutas_ok, "todos los bloques salen de assets/ciudad/kaykit/ (CC0)")
	_comprobar(not mallas.is_empty() and caja.size.y > 18.0 and caja.size.y < 60.0, "alto de bloque de pisos, no una torre estirada (%.1f m)" % caja.size.y)
	_comprobar(caja.size.x < 114.0 and caja.size.z < 114.0, "cabe dentro de la finca (%.0f × %.0f m)" % [caja.size.x, caja.size.z])
	_comprobar(absf(caja.position.y - 0.05) < 1.0, "apoya en el suelo (y=%.2f)" % caja.position.y)
	_comprobar(FileAccess.file_exists("res://assets/ciudad/kaykit/LICENSE.txt"), "la licencia CC0 de KayKit viaja con los modelos")
	cb.queue_free()

func _estadio_respaldo() -> void:
	var cb := CityBuilder.new()
	add_child(cb)
	cb.datos = {"club": {"cap": 30000, "estadioNom": "Estadio de prueba"}}
	cb._estadio_maqueta()
	var mallas: Array = []
	_mallas(cb, mallas)
	var cajas := 0
	var obj := false
	for mi: MeshInstance3D in mallas:
		if mi.mesh is BoxMesh:
			cajas += 1
		if mi.mesh != null and mi.mesh.resource_path.contains("estadio.obj"):
			obj = true
	_comprobar(cajas == 4 and not obj, "la maqueta de respaldo son 4 gradas de caja, sin estadio.obj (%d cajas)" % cajas)
	_comprobar(not FileAccess.get_file_as_string("res://visor/city_builder_p1.gd").contains("farola.obj\""), "farola.obj ya no se referencia en el código")
	cb.queue_free()

func _exportacion() -> void:
	var cfg := FileAccess.get_file_as_string("res://export_presets.cfg")
	var filas := 0
	var buenas := 0
	for l in cfg.split("\n"):
		if l.begins_with("exclude_filter="):
			filas += 1
			if l.contains("assets/ciudad/estadio.obj") and l.contains("assets/ciudad/farola.*") and l.contains("assets/ciudad/complejo_residencial*"):
				buenas += 1
	_comprobar(filas > 0 and buenas == filas, "las %d exportaciones dejan fuera estadio.obj, farola y complejo_residencial" % filas)
	_comprobar(FileAccess.file_exists("res://addons/LICENCIAS_TERCEROS.txt"), "las licencias MIT viajan en la exportación (los .md se excluyen)")

func _suaves_con_textura(n: Node) -> bool:
	for h in n.get_children():
		if h.has_meta(TrazoSuave.META) and h is Line2D and (h as Line2D).texture == null:
			return false
	return true

func _lineas() -> void:
	_comprobar(get_tree().root.get_node_or_null("AntialiasedLine2DTexture") != null, "el autoload de la textura suave existe")
	var ra := RadarAtributos.new()
	add_child(ra)
	ra.size = Vector2(160, 150)
	ra.poner(PackedStringArray(["A", "B", "C", "D", "E", "F"]), PackedFloat32Array([60, 70, 80, 50, 90, 65]), Color.GREEN)
	## 4 anillos + 6 ejes + el borde.
	_comprobar(TrazoSuave.cuantas(ra) == 11 and _suaves_con_textura(ra), "radar de atributos: 11 líneas suaves con su textura (%d)" % TrazoSuave.cuantas(ra))
	ra.poner(PackedStringArray(["A", "B", "C", "D", "E"]), PackedFloat32Array([60, 70, 80, 50, 90]), Color.GREEN)
	_comprobar(TrazoSuave.cuantas(ra) == 10, "al cambiar los valores se rehacen sin acumularse (%d)" % TrazoSuave.cuantas(ra))
	var rp := RadarPartido.new()
	add_child(rp)
	rp.setup([], null)
	rp.size = Vector2(210, 136)
	_comprobar(TrazoSuave.cuantas(rp) == 6 and _suaves_con_textura(rp), "radar del partido: fondo + 5 líneas fijas (%d)" % TrazoSuave.cuantas(rp))
	var campo := PizarraTactica.CampoDibujado.new()
	add_child(campo)
	campo.size = Vector2(300, 420)
	_comprobar(TrazoSuave.cuantas(campo) == 7 and _suaves_con_textura(campo), "pizarra: borde, medio campo, círculo y 4 áreas suaves (%d)" % TrazoSuave.cuantas(campo))
	var mm := MinimapaCiudad.new()
	add_child(mm)
	mm.size = Vector2(300, 190)
	mm.set("_ruta", PackedVector2Array([Vector2(0, 0), Vector2(50, 0), Vector2(50, 80)]))
	mm.call("_poner_ruta")
	var linea: Line2D = mm.get("_ruta_linea")
	_comprobar(linea != null and linea.visible and linea.points.size() == 3 and linea.texture != null, "minimapa: la ruta al estadio es una línea suave")
	for n: Node in [ra, rp, campo, mm]:
		n.queue_free()

func _contador() -> void:
	var c := ContadorFps.new()
	add_child(c)
	_comprobar(c.get_node_or_null("DebugMenu") != null, "el contador de FPS lleva el Debug Menu dentro")
	_comprobar(String(c.call("texto")).contains("FPS"), "y enseña los FPS («%s»)" % String(c.call("texto")))
	var f9 := InputEventKey.new()
	f9.keycode = KEY_F9
	_comprobar(InputMap.action_has_event("cycle_debug_menu", f9), "F9 cambia su modo (F3 es la táctica rápida)")
	c.queue_free()
