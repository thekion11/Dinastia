class_name GloboShaders
extends RefCounted
## LOS SHADERS DEL GLOBO de la pantalla de país (sacados de `Globo3D` el 15-11-2026, que llegaba a 450 líneas, y mejorados a pedido del dueño:
## «hacer más bonito el globo terráqueo, y más rentable»).
## Lo nuevo frente a los de siempre:
##   · BRILLO DEL SOL EN EL MAR: el reflejo especular solo sobre el agua (la máscara de tierra ya existía para el relieve) y un azul más
##     profundo en el océano; la tierra no brilla.
##   · BORDE DE ATMÓSFERA EN EL LADO DE DÍA (Fresnel): el planeta se funde con el halo en vez de cortarse en seco.
##   · LUCES DE NOCHE CÁLIDAS (sodio) en vez de blancas.
##   · ATMÓSFERA con el atardecer: el halo se vuelve anaranjado donde pasa el terminador.
##   · El relieve (4 lecturas extra de la textura por píxel) se puede apagar con `relieve = false`; el globo se dibuja a 600×300 y
##     solo al cambiar, así que se deja encendido en todas las calidades (sin él se veía plano).

## `relieve`: con el relieve sacado de la foto (calidad MEDIA o más).
static func tierra(relieve: bool) -> Shader:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D tex_dia : source_color, filter_linear_mipmap;
uniform sampler2D tex_noche : source_color, filter_linear_mipmap;
uniform sampler2D tex_fronteras : hint_default_transparent, filter_linear_mipmap;
// La luz va EN ESPACIO DE VISTA (C14): el país elegido queda siempre de día y el terminador cruza el borde derecho.
uniform vec3 luz_vista = vec3(-0.62, 0.40, 0.68);
float es_tierra(vec3 c){
	return smoothstep(0.02, 0.12, c.r + c.g * 0.5 - c.b * 0.9);
}
""" + ("""
float altura(vec2 uv){
	vec3 c = texture(tex_dia, uv).rgb;
	return es_tierra(c) * (0.35 + dot(c, vec3(0.3, 0.5, 0.2)));
}
""" if relieve else "") + """
void fragment(){
	vec3 n = normalize(NORMAL);
	vec3 dia = texture(tex_dia, UV).rgb;
	float tierra = es_tierra(dia);
""" + ("""
	vec2 e = vec2(1.0 / 4096.0, 1.0 / 2048.0) * 2.0;
	float dx = altura(UV + vec2(e.x, 0.0)) - altura(UV - vec2(e.x, 0.0));
	float dy = altura(UV + vec2(0.0, e.y)) - altura(UV - vec2(0.0, e.y));
	n = normalize(n - (normalize(TANGENT) * dx + normalize(BINORMAL) * dy) * 2.2);
""" if relieve else "") + """
	vec3 l = normalize(luz_vista);
	float cara = dot(n, l);
	float t_dia = smoothstep(-0.14, 0.30, cara);
	vec3 noche = texture(tex_noche, UV).rgb * vec3(1.15, 0.86, 0.55);
	float frontera = texture(tex_fronteras, UV).a;
	// El océano, un poco más profundo; la tierra como en la foto.
	dia = mix(dia * vec3(0.72, 0.86, 1.06), dia, tierra);
	dia = mix(dia, vec3(1.0, 0.93, 0.7), frontera * 0.55);
	vec3 lado_dia = dia * (0.30 + 0.95 * max(cara, 0.0));
	// El sol reflejado en el agua (solo de día y solo en el mar).
	float brillo = pow(max(dot(reflect(-l, n), VIEW), 0.0), 90.0) * (1.0 - tierra) * t_dia;
	lado_dia += vec3(1.0, 0.95, 0.82) * brillo * 0.45;
	// Borde de atmósfera del lado de día.
	float borde = pow(1.0 - max(dot(n, VIEW), 0.0), 3.0);
	lado_dia = mix(lado_dia, vec3(0.45, 0.68, 1.0), borde * 0.30 * t_dia);
	ALBEDO = mix(noche * 1.2 + vec3(0.01, 0.02, 0.05) + vec3(frontera * 0.10), lado_dia, t_dia);
}
"""
	return sh

static func nubes() -> Shader:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_back, blend_mix;
uniform sampler2D tex_nubes : hint_default_white, filter_linear_mipmap;
uniform vec3 luz_vista = vec3(-0.62, 0.40, 0.68);
void fragment(){
	float nub = texture(tex_nubes, UV).r;
	float dif = max(dot(normalize(NORMAL), normalize(luz_vista)), 0.0);
	ALBEDO = vec3(0.22 + 0.70 * dif);
	ALPHA = smoothstep(0.35, 0.9, nub) * 0.7 * smoothstep(-0.25, 0.25, dot(normalize(NORMAL), normalize(luz_vista)) + 0.2);
}
"""
	return sh

static func atmosfera() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_front, blend_add, unshaded, depth_draw_never;
uniform vec3 luz_vista = vec3(-0.62, 0.40, 0.68);
void fragment(){
	float borde = pow(1.0 - abs(dot(NORMAL, VIEW)), 3.0);
	float sol = dot(-NORMAL, normalize(luz_vista));
	vec3 azul = vec3(0.35, 0.58, 0.95);
	vec3 ocaso = vec3(1.0, 0.55, 0.25);
	ALBEDO = mix(azul, ocaso, smoothstep(0.25, 0.0, abs(sol)) * 0.6);
	ALPHA = borde * 0.55 * (0.35 + 0.65 * smoothstep(-0.3, 0.4, sol));
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m
