extends BaseIdea
## S6 · LLUVIA EN LA CIUDAD (27-10-2026): emisores que siguen la cámara, con tope de partículas por calidad, y suelo mojado.

func _probar() -> void:
	_titulo("S6 · LLUVIA EN LA CIUDAD CON TOPE DE PARTÍCULAS Y SUELO MOJADO")
	_comprobar(PrecipitacionCiudad.montar(self, "despejado") == null and PrecipitacionCiudad.montar(self, "nieve") == null, "solo llueve con lluvia o tormenta")
	var previas := -1
	for nivel in [Calidad.MEDIO, Calidad.ALTO, Calidad.ULTRA]:
		var cont := PrecipitacionCiudad.montar(self, "lluvia", nivel)
		var n := PrecipitacionCiudad.particulas(cont)
		_comprobar(n <= PrecipitacionCiudad.tope(nivel) and n > 0, "calidad %d: %d partículas (tope %d)" % [nivel, n, PrecipitacionCiudad.tope(nivel)])
		_comprobar(n >= previas, "más calidad, no menos lluvia")
		previas = n
		cont.queue_free()
	var t := PrecipitacionCiudad.montar(self, "tormenta", Calidad.ALTO)
	_comprobar(t.get_node_or_null("Relampagos") != null and PrecipitacionCiudad.particulas(t) <= PrecipitacionCiudad.TOPE_ALTO, "la tormenta lleva relámpagos y respeta el tope")
	var alto := PrecipitacionCiudad.particulas(PrecipitacionCiudad.montar(self, "lluvia", Calidad.ALTO))
	_comprobar(alto <= 4200 and alto < 15000, "bastante menos que la lluvia del partido (15 000): %d" % alto)
	## Suelo mojado.
	var m := CityBuilder.asfalto_mate(Texturas.asfalto(Color(0.4, 0.4, 0.415)).duplicate(), 0.8)
	var antes := m.albedo_color
	CityBuilder.mojar(true)
	_comprobar(m.roughness < 0.4 and m.albedo_color.r < antes.r and m.metallic_specular > 0.5, "con lluvia el asfalto es más liso y más oscuro")
	CityBuilder.mojar(false)
	_comprobar(is_equal_approx(m.roughness, 0.8) and m.albedo_color.is_equal_approx(antes), "al escampar vuelve a como estaba")
	## El clima llega al cielo y al sol.
	var sol := DirectionalLight3D.new()
	sol.light_energy = 1.15
	var env := Environment.new()
	env.fog_enabled = true
	env.fog_density = 0.0002
	env.ambient_light_energy = 1.0
	var cielo := ShaderMaterial.new()
	cielo.shader = load("res://visor/cielo.gdshader")
	cielo.set_shader_parameter("top_color", Color(0.20, 0.42, 0.78))
	cielo.set_shader_parameter("horizon_color", Color(0.78, 0.86, 0.94))
	cielo.set_shader_parameter("halo_escala", 1.0)
	ClimaCiudad.aplicar("despejado", sol, env, cielo, 1.0)
	_comprobar(is_equal_approx(sol.light_energy, 1.15) and is_equal_approx(env.fog_density, 0.0002), "con tiempo despejado no cambia nada")
	ClimaCiudad.aplicar("lluvia", sol, env, cielo, 1.0)
	var top: Color = cielo.get_shader_parameter("top_color")
	_comprobar(sol.light_energy < 0.8 and sol.shadow_blur > 2.0, "con lluvia el sol es más débil y difuso (%.2f)" % sol.light_energy)
	_comprobar(top.b < 0.78 and top.r > 0.2 and float(cielo.get_shader_parameter("halo_escala")) < 0.5, "el cielo pasa a gris y sin disco solar (azul %.2f)" % top.b)
	_comprobar(env.fog_density > 0.0007 and env.ambient_light_energy > 1.1, "más niebla y algo más de ambiente")
	var noche := ShaderMaterial.new()
	noche.shader = cielo.shader
	noche.set_shader_parameter("top_color", Color(0.04, 0.06, 0.16))
	noche.set_shader_parameter("horizon_color", Color(0.11, 0.14, 0.26))
	noche.set_shader_parameter("halo_escala", 1.0)
	ClimaCiudad.aplicar("lluvia", DirectionalLight3D.new(), Environment.new(), noche, 0.0)
	var tn: Color = noche.get_shader_parameter("top_color")
	_comprobar(tn.is_equal_approx(Color(0.04, 0.06, 0.16)), "de noche el cielo no se aclara a gris")

