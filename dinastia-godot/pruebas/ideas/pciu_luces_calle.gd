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
	b.free()
