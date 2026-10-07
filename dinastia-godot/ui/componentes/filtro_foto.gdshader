shader_type canvas_item;
// MODO FOTO: filtros sobre la pantalla. 0 natural, 1 club, 2 b/n, 3 sepia,
// 4 cine (contraste + verde azulado/naranja), 5 vintage (desvaído + grano).
uniform sampler2D pantalla : hint_screen_texture, filter_linear_mipmap;
uniform int modo = 0;
uniform vec4 tinte : source_color = vec4(1.0);
uniform float vineta = 0.35;

float azar(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec3 c = texture(pantalla, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	if (modo == 1) {
		c = mix(c, l * tinte.rgb * 1.35, 0.42);
	} else if (modo == 2) {
		c = vec3(smoothstep(0.05, 0.95, l));
	} else if (modo == 3) {
		c = vec3(l) * vec3(1.07, 0.9, 0.68);
	} else if (modo == 4) {
		c = (c - 0.5) * 1.18 + 0.5;
		c = mix(c, c * vec3(0.85, 1.0, 1.08), 1.0 - l);
		c = mix(c, c * vec3(1.12, 0.98, 0.82), l);
	} else if (modo == 5) {
		c = mix(c, vec3(l), 0.35) * vec3(1.05, 0.98, 0.86) * 0.9 + 0.06;
		c += (azar(SCREEN_UV * 900.0 + TIME) - 0.5) * 0.07;
	}
	vec2 d = SCREEN_UV - 0.5;
	c *= 1.0 - vineta * dot(d, d) * 2.2 * float(modo != 0);
	COLOR = vec4(c, 1.0);
}
