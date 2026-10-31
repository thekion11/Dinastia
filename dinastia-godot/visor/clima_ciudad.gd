class_name ClimaCiudad
extends RefCounted
## EL TIEMPO SE VE EN LA CIUDAD (S6, 27-10-2026). `_aplicar_hora` solo conocía la hora: con lluvia seguía el cielo azul y el sol de mediodía.
## Aquí el clima de la semana (`Mundo.clima()`) oscurece y apaga lo que ya dejó la hora: cielo gris, sol más débil y difuso (sombras suaves,
## sin disco solar), el ambiente sube un poco para no apagar la calle y la niebla espesa. Usa las mismas cifras que el partido
## (`Ambience.CLIMA_PARTIDO`: oscuro y niebla por clima). Se llama al FINAL de `_aplicar_hora`, sobre lo que acaba de poner la hora.

const GRIS_CIELO := Color(0.46, 0.50, 0.55)

static func cifras(clima: String) -> Dictionary:
	return Ambience.CLIMA_PARTIDO.get(clima, Ambience.CLIMA_PARTIDO["despejado"])

## `dia`: 0 de noche, 1 a pleno día (el cielo solo se aplana de día: de noche ya es oscuro).
static func aplicar(clima: String, sol: DirectionalLight3D, env: Environment, cielo: ShaderMaterial, dia: float) -> void:
	var c := cifras(clima)
	var oscuro: float = float(c["oscuro"])
	var niebla: float = float(c["niebla"])
	if oscuro <= 0.0 and niebla <= 0.0:
		return
	if sol != null:
		sol.light_energy *= lerpf(1.0, 0.45, clampf(oscuro / 0.62, 0.0, 1.0))
		sol.light_color = sol.light_color.lerp(Color(0.80, 0.84, 0.90), clampf(oscuro, 0.0, 1.0) * dia)
		sol.light_angular_distance = 0.5 + oscuro * 3.0   ## sombras difusas: el sol tapado por nubes
		sol.shadow_blur = 1.0 + oscuro * 2.5
	if cielo != null:
		var gris := GRIS_CIELO.darkened(oscuro * 0.45)
		for par: Array in [["top_color", 0.8], ["horizon_color", 0.9]]:
			var antes: Color = cielo.get_shader_parameter(String(par[0]))
			cielo.set_shader_parameter(String(par[0]), antes.lerp(gris, clampf(oscuro * 1.5, 0.0, 1.0) * float(par[1]) * dia))
		var halo: float = float(cielo.get_shader_parameter("halo_escala"))
		cielo.set_shader_parameter("halo_escala", halo * (1.0 - clampf(oscuro * 1.6, 0.0, 0.95)))
		cielo.set_shader_parameter("nubes_cantidad", clampf(0.5 + oscuro, 0.0, 1.0))
	if env != null:
		env.ambient_light_energy += oscuro * 0.35 * dia
		if env.fog_enabled:
			env.fog_density += niebla * 0.0022
			env.fog_light_color = env.fog_light_color.lerp(GRIS_CIELO, clampf(niebla, 0.0, 1.0) * dia)
		if env.volumetric_fog_enabled:
			env.volumetric_fog_density += niebla * 0.004
			env.volumetric_fog_albedo = env.volumetric_fog_albedo.lerp(GRIS_CIELO, clampf(niebla, 0.0, 1.0) * dia)
