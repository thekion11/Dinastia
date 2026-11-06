class_name MuroCivico
extends RefCounted
## MUROS CON VENTANAS PARA LOS EDIFICIOS DE SERVICIOS (4-11-2026, pasada visual de la ciudad). El ayuntamiento, el hospital, la comisaría, el cine y los edificios «claros»
## eran cajas lisas: solo su cara sur llevaba la piel de `FachadaModular`, y desde atrás o de lado parecían bloques de plastilina. Aquí se les pone el shader de fachada de
## las torres (`fachada_torre.gdshader`: ventanas por piso, azotea lisa y ventanas encendidas de noche) con el color de pared del propio edificio.
## Misma malla, UN material por color: no suma llamadas de dibujo en ninguna calidad. Los materiales se anotan en `_mats_torre` para que la noche los encienda.
static func vestir(b: CityBuilder, mi: MeshInstance3D, pared: Color) -> void:
	var clave := "muro_%s" % pared.to_html(false)
	for m in b._mats_torre:
		if m.has_meta("muro") and String(m.get_meta("muro")) == clave:
			mi.material_override = m
			return
	var m := ShaderMaterial.new()
	m.shader = load("res://visor/fachada_torre.gdshader") as Shader
	m.set_shader_parameter("pared", pared)
	m.set_shader_parameter("vidrio", Color(0.2, 0.32, 0.46))
	m.set_shader_parameter("celda", Vector2(3.6, 3.6))
	m.set_meta("muro", clave)
	b._mats_torre.append(m)
	mi.material_override = m
