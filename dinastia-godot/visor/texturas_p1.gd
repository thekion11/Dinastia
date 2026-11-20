extends "res://visor/texturas_p1_p1.gd"
## (Parte 2 de 2 de `texturas_p1.gd`.)

## Madera: bancos, tarimas. El grano tiene que ir en UNA dirección marcada
## -por eso `roughness_texture` usa una frecuencia baja en un eje y el normal
## una más alta en el otro, a diferencia de `hormigon()` o `cesped()` donde el
## ruido es igual de random en las dos direcciones-, si no se lee como piedra clara, no como tablones.
static func madera(tinte: Color, rugoso: float = 0.65) -> StandardMaterial3D:
	var clave := "mad|%s|%.2f" % [tinte.to_html(false), rugoso]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = tinte
	m.detail_enabled = true
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	m.detail_albedo = _ruido_claro(0.15, 83, 2, 0.75)
	m.normal_enabled = true
	m.normal_texture = _tex_ruido(0.4, 87, true, 3)
	m.normal_scale = 0.3
	m.roughness = rugoso
	m.roughness_texture = _tex_ruido(0.1, 89, false, 2)
	m.metallic = 0.0
	_cache[clave] = m
	return m

## Cuero: sillones y butacas premium. Mismo espiritu que `tela()` pero mas
## brillante y con menos relieve -el cuero se ve, la lona se siente.
static func cuero(tinte: Color, rugoso: float = 0.32) -> StandardMaterial3D:
	var clave := "cue|%s|%.2f" % [tinte.to_html(false), rugoso]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = tinte
	m.roughness = rugoso
	m.roughness_texture = _tex_ruido(0.5, 97, false, 2)
	m.normal_enabled = true
	m.normal_texture = _tex_ruido(0.8, 101, true, 2)
	m.normal_scale = 0.18
	m.metallic = 0.05
	m.metallic_specular = 0.4
	_cache[clave] = m
	return m

## Metal pintado, para barandillas, rejillas, farolas y equipos de cubierta.
static func metal(tinte: Color, rugoso: float = 0.35) -> StandardMaterial3D:
	var clave := "met|%s|%.2f" % [tinte.to_html(false), rugoso]
	if _cache.has(clave):
		return _cache[clave]
	var m := StandardMaterial3D.new()
	m.albedo_color = tinte
	m.metallic = 0.75
	m.metallic_specular = 0.6
	m.roughness = rugoso
	m.roughness_texture = _tex_ruido(0.3, 43, false, 2)
	m.normal_enabled = true
	m.normal_texture = _tex_ruido(0.5, 47, true, 2)
	m.normal_scale = 0.2
	_cache[clave] = m
	return m
