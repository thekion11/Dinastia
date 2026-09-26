shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// EL PELAJE DE LA MASCOTA (26-9-2026). "Mejorar las mascotas": las cabezas
// eran esferas de color plano, de plástico. Un traje de mascota de verdad es
// peluche: mechones que cambian de tono, un borde que se aclara a contraluz
// (la pelusa que se ve contra el cielo) y nada de brillo. Todo sale de la
// posición LOCAL de la pieza, así el dibujo va pegado a ella y no "nada"
// cuando la mascota se mueve.

uniform vec4 color : source_color = vec4(0.6, 0.45, 0.3, 1.0);
// Color de las puntas y de las manchas grandes.
uniform vec4 color_puntas : source_color = vec4(0.8, 0.7, 0.55, 1.0);
// Rayas (tigre) o manchas (0 = liso).
uniform float rayas : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color_rayas : source_color = vec4(0.08, 0.06, 0.05, 1.0);
uniform float escala = 38.0;
// Escamas (dragón, cocodrilo): en vez de mechones, placas.
uniform float escamas : hint_range(0.0, 1.0) = 0.0;

#include "res://visor/ruido.gdshaderinc"

varying vec3 p_local;

void vertex() {
	p_local = VERTEX;
}

void fragment() {
	// Mechones: ruido estirado en vertical (el pelo "cae") más grano fino.
	vec3 q = p_local * escala;
	float mechon = fbm3(vec3(q.x, q.y * 0.35, q.z));
	float grano = ruido3(q * 3.1);
	vec3 c = mix(color.rgb * 0.72, color.rgb * 1.1, mechon);
	c *= mix(0.9, 1.06, grano);
	float manchas = fbm3(p_local * escala * 0.18 + 11.0);
	c = mix(c, color_puntas.rgb, smoothstep(0.58, 0.85, manchas) * 0.35);
	if (rayas > 0.0) {
		float r = sin(p_local.y * 34.0 + fbm3(p_local * 6.0) * 5.0);
		c = mix(c, color_rayas.rgb, smoothstep(0.55, 0.8, r) * rayas);
	}
	if (escamas > 0.0) {
		vec2 cel = fract(p_local.xy * 26.0 + vec2(floor(p_local.y * 26.0) * 0.5, 0.0)) - 0.5;
		float borde = smoothstep(0.32, 0.48, length(cel));
		c = mix(c, c * 0.6, borde * escamas);
	}
	ALBEDO = c;
	ROUGHNESS = mix(1.0, 0.55, escamas);
	SPECULAR = mix(0.08, 0.4, escamas);
	// La pelusa del borde: se aclara donde la cara se pone de canto.
	float canto = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	RIM = mix(0.75, 0.2, escamas);
	RIM_TINT = 0.6;
	BACKLIGHT = color.rgb * 0.18 * (1.0 - escamas);
	ALBEDO += color_puntas.rgb * pow(canto, 3.0) * 0.18 * (1.0 - escamas);
}
