shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
// CHARCOS DE LLUVIA (M-190): mancha oscura de borde irregular, muy lisa (refleja el cielo), con ondas pequeñas que nacen y se apagan.
varying float fase;
void vertex() {
	fase = fract(sin(dot(MODEL_MATRIX[3].xz, vec2(12.9898, 78.233))) * 43758.5453) * 6.283;
}
float azar(float n) { return fract(sin(n * 91.345 + fase) * 43758.5453); }
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float a = atan(p.y, p.x);
	float borde = 0.78 + 0.1 * sin(a * 3.0 + fase) + 0.07 * sin(a * 5.0 + fase * 2.0) + 0.04 * sin(a * 9.0 + fase * 3.0);
	float mancha = smoothstep(borde, borde - 0.3, d);
	float onda = 0.0;
	for (int i = 0; i < 3; i++) {
		float ciclo = TIME * 0.8 + float(i) * 0.37 + fase;
		float k = fract(ciclo);
		float n = floor(ciclo) * 3.0 + float(i);
		vec2 c = (vec2(azar(n), azar(n + 1.0)) - 0.5) * 0.9;
		float r = k * 0.2;
		onda += smoothstep(0.028, 0.0, abs(length(p - c) - r)) * (1.0 - k) * (1.0 - k);
	}
	ALBEDO = vec3(0.02, 0.025, 0.035) + vec3(onda * 0.25);
	ROUGHNESS = 0.02;
	SPECULAR = 1.0;
	METALLIC = 0.0;
	ALPHA = mancha * (0.72 + onda * 0.2);
}
