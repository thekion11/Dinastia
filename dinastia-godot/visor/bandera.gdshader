shader_type spatial;
render_mode cull_disabled;
// BANDERA QUE ONDEA (25-9-2026, plan maestro B11). Un plano subdividido que se
// mueve con el viento: la ola avanza desde el asta (x = 0, quieta) hacia la
// punta libre (x = 1), donde la amplitud es máxima, y cada bandera lleva su
// propia fase para que no ondeen todas a la vez como un solo trapo.
uniform vec4 color : source_color = vec4(0.2, 0.4, 0.8, 1.0);
uniform sampler2D tela : source_color, hint_default_white;
uniform float ancho = 1.3;
uniform float fase = 0.0;
uniform float viento = 1.0;   // 0 = calma, 1 = normal, 2 = temporal
// El dibujo de una bandera nacional (`Banderas.textura`): si está, manda él y
// `color` queda como tinte blanco (MEGAPLAN fase 4, banderas del estudio).
uniform sampler2D dibujo : source_color, hint_default_white;
uniform bool usa_dibujo = false;
// Las banderas giradas 180° (asta a la derecha) se ven por detrás: el dibujo
// se lee al revés si no se refleja.
uniform bool espejo = false;

void vertex() {
	float x = UV.x;                         // 0 en el asta, 1 en la punta
	float t = TIME * (2.4 + viento * 1.6) + fase;
	float ola = sin(t - x * 6.0) * 0.5 + sin(t * 1.7 - x * 11.0) * 0.18;
	VERTEX.z += ola * x * (0.16 + 0.20 * viento) * ancho;
	VERTEX.y -= x * x * 0.05 * ancho * (1.2 - viento * 0.4);   // la punta cae un poco
	NORMAL = normalize(NORMAL + vec3(0.0, 0.0, -cos(t - x * 6.0) * x * 0.6));
}

void fragment() {
	// La trama se mezcla suave: multiplicada entera oscurecía el color del club.
	vec2 uv_d = espejo ? vec2(1.0 - UV.x, UV.y) : UV;
	vec3 tinte = usa_dibujo ? texture(dibujo, uv_d).rgb : color.rgb;
	vec3 base = tinte * mix(vec3(1.0), texture(tela, UV * vec2(3.0, 2.0)).rgb, 0.35);
	// Los pliegues se oscurecen un poco: se lee como tela, no como chapa.
	float pliegue = 0.9 + 0.1 * sin(TIME * 3.0 + fase - UV.x * 6.0);
	ALBEDO = base * pliegue;
	ROUGHNESS = 0.9;
}
