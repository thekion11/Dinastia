shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
// CHARCOS DE LLUVIA (M-190): disco oscuro y liso con ondas que se abren desde el centro (una gota cada pocos segundos, fase por charco).
varying float fase;
void vertex() {
	fase = fract(sin(dot(MODEL_MATRIX[3].xz, vec2(12.9898, 78.233))) * 43758.5453) * 6.0;
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float borde = 1.0 - smoothstep(0.78, 1.0, d);
	float t = TIME * 0.9 + fase;
	float onda = 0.0;
	for (int i = 0; i < 2; i++) {
		float r = fract(t * 0.5 + float(i) * 0.5) * 0.9;
		onda += smoothstep(0.07, 0.0, abs(d - r)) * (1.0 - r / 0.9);
	}
	ALBEDO = vec3(0.04, 0.05, 0.07) + vec3(onda * 0.35);
	ROUGHNESS = 0.03;
	SPECULAR = 1.0;
	METALLIC = 0.0;
	ALPHA = borde * (0.62 + onda * 0.25);
}
