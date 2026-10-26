extends BaseIdea
## PULIDO DE LA CALLE (pciu, 26-10-2026): farolas, charcos de luz, haz y asfalto.
## Comprueba lo que se arregló tras mirar el paseo de día y de noche con la
## cámara real: el haz no se ve desde dentro, el charco se concentra bajo el
## farol, los postes no son azul lavanda y el asfalto de calle no hace espejo.

func _probar() -> void:
	_titulo("CIUDAD · LUCES DE CALLE Y ASFALTO (pciu)")
	_probar_asfalto()
	_probar_haz()
	_probar_farolas()
	_probar_ventanas_kit()

func _probar_asfalto() -> void:
	_linea("· Asfalto mate")
	var base := Texturas.asfalto(Color(0.44, 0.435, 0.43))
	var m := CityBuilder.asfalto_mate(base.duplicate(), 0.85)
	_comprobar(base.roughness_texture != m.roughness_texture, "el material compartido de `Texturas` no se toca (solo la copia)")
	var t := m.roughness_texture as NoiseTexture2D
	_comprobar(t != null and t.color_ramp != null, "la rugosidad de la calle lleva rampa propia")
	if t != null and t.color_ramp != null:
		var bajo := t.color_ramp.sample(0.0).r
		## Rugosidad mínima real = 0,85 · rampa(0): por encima de 0,6 no hay espejo.
		_comprobar(m.roughness * bajo >= 0.6, "rugosidad mínima %.2f ≥ 0,6 (antes ~0)" % (m.roughness * bajo))
	_comprobar(CityBuilder.asfalto_mate(base.duplicate()).roughness_texture == t, "una sola textura de rugosidad para todas las calles")

func _probar_haz() -> void:
	_linea("· Haz de la farola")
	var sh := load("res://visor/cono_farola.gdshader") as Shader
	_comprobar(sh != null, "el shader del haz carga")
	if sh == null:
		return
	var codigo := sh.code
	## Guarda contra una regresión: el haz se apaga con la cámara dentro.
	_comprobar(codigo.contains("CAMERA_POSITION_WORLD") and codigo.contains("* v_fuera;"), "el haz se apaga con la cámara dentro del cono")
	var param := false
	for u: Dictionary in sh.get_shader_uniform_list():
		param = param or String(u["name"]) == "fuerza"
	_comprobar(param, "conserva el parámetro `fuerza` que pone `encender`")

func _probar_farolas() -> void:
	_linea("· Farolas, charcos y encendido")
	var b := CityBuilder.new()
	var ex := CiudadExpansion.new(b)
	ex.armar_red()
	ex._farolas()
	var kf: Dictionary = ex._malla_kit("res://assets/ciudad/kenney_roads/light-curved.glb")
	var poste: MultiMeshInstance3D = null
	for h: Node in b.get_children():
		if h is MultiMeshInstance3D and not kf.is_empty() and (h as MultiMeshInstance3D).multimesh.mesh == kf["malla"]:
			poste = h
	_comprobar(poste != null and poste.multimesh.instance_count > 50, "farolas de Kenney repartidas (%d)" % (poste.multimesh.instance_count if poste != null else 0))
	if poste != null:
		var mp := poste.material_override as StandardMaterial3D
		_comprobar(mp != null and mp.albedo_color.get_luminance() < 0.4, "poste gris grafito, no azul lavanda")
		_comprobar(mp != null and mp.albedo_texture != null, "conserva la paleta del modelo (brazo y luminaria distintos)")
	var img := ex._textura_charco().get_image()
	var centro := img.get_pixel(32, 32).a
	var mitad := img.get_pixel(48, 32).a
	_comprobar(centro > 0.9, "el charco brilla de lleno bajo el farol (%.2f)" % centro)
	_comprobar(mitad < 0.16, "a medio radio ya casi no tiñe (%.2f; antes 0,25)" % mitad)
	ex.encender(1.0)
	_comprobar(is_equal_approx(ex._farola_charco.albedo_color.a, 0.62), "de noche el charco llega a 0,62")
	_comprobar(float(ex._farola_cono.get_shader_parameter("fuerza")) > 0.1, "de noche el haz se ve")
	ex.encender(0.0)
	_comprobar(ex._farola_charco.albedo_color.a == 0.0 and float(ex._farola_cono.get_shader_parameter("fuerza")) == 0.0, "de día ni charco ni haz")
	ex._kenney_calles()
	var carteles := 0
	var grafito := 0
	for h: Node in b.get_children():
		if String(h.name).begins_with("road-sign-empty-hanging") or (h.scene_file_path.ends_with("road-sign-empty-hanging.glb")):
			carteles += 1
			for mi in h.find_children("*", "MeshInstance3D", true, false):
				var mo := (mi as MeshInstance3D).material_override as StandardMaterial3D
				if mo != null and mo.albedo_color.get_luminance() < 0.4:
					grafito += 1
					break
	_comprobar(carteles > 0 and grafito == carteles, "los carteles colgantes de los cruces, en grafito (%d de %d)" % [grafito, carteles])
	b.free()

func _probar_ventanas_kit() -> void:
	_linea("· Ventanas del kit comercial de noche")
	var b := CityBuilder.new()
	var e := load(CityBuilder.RUTAS_COMERCIAL[0]) as PackedScene
	var n: Node3D = e.instantiate()
	b.tenir(n, 3)
	var mi := n.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var sm := mi.get_surface_override_material(0) as ShaderMaterial
	_comprobar(sm != null and sm.shader.resource_path.ends_with("ventanas_kit.gdshader"), "el edificio comercial lleva el material de ventanas")
	if sm != null:
		var orig := mi.mesh.surface_get_material(0) as StandardMaterial3D
		_comprobar(sm.get_shader_parameter("paleta") == orig.albedo_texture, "conserva la paleta de Kenney")
		var tin: Color = sm.get_shader_parameter("tinte")
		_comprobar(tin.is_equal_approx(orig.albedo_color * CityBuilder.TINTES[3]), "y el tinte de su fachada")
		var codigo := sm.shader.code
		_comprobar(codigo.contains("0.6875") and codigo.contains("MODEL_MATRIX[3]"), "cristal por la columna azul de la paleta y variación por edificio (también en MultiMesh)")
		b.encender_luces(1.0)
		_comprobar(float(sm.get_shader_parameter("noche")) == 1.0, "de noche se encienden")
		b.encender_luces(0.0)
		_comprobar(float(sm.get_shader_parameter("noche")) == 0.0, "de día, apagadas")
	## El cristal de verdad cae en esa columna: se mide en la malla.
	var img := (mi.mesh.surface_get_material(0) as StandardMaterial3D).albedo_texture.get_image()
	if img.is_compressed():
		img.decompress()
	var arr := mi.mesh.surface_get_arrays(0)
	var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
	var azules := 0
	for u in uv:
		if u.x >= 0.6875 and u.x <= 0.75 and u.y >= 0.25 and u.y <= 0.5:
			var c := img.get_pixel(clampi(int(u.x * img.get_width()), 0, img.get_width() - 1), clampi(int(u.y * img.get_height()), 0, img.get_height() - 1))
			if c.b > c.r + 0.2:
				azules += 1
	_comprobar(azules >= 8, "el modelo tiene cristal azul en esa columna (%d vértices)" % azules)
	## Otros kits (suburbano) siguen con su copia teñida.
	var otro := StandardMaterial3D.new()
	_comprobar(CityBuilder.ventanas_kit(otro, Color.WHITE) == null, "otros materiales no cambian")
	n.free()
	b.free()
