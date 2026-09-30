shader_type spatial;
// Las pestañas (`PeloCapas._pestanas`): una tira por párpado con pelos
// finos que se afinan hacia la punta y se curvan un poco. UV.x a lo largo del
// párpado, UV.y de la raíz (0) a la punta (1).
render_mode cull_disabled, depth_draw_opaque;

float h11(float x) { return fract(sin(x * 127.1) * 43758.5453); }

void fragment() {
	float n = 34.0;
	float x = UV.x * n + UV.y * UV.y * 0.8;
	float id = floor(x);
	float f = fract(x) - 0.5 - (h11(id) - 0.5) * 0.4;
	float largo = mix(0.55, 1.0, h11(id + 3.3));
	float grueso = 0.28 * (1.0 - UV.y / largo);
	ALPHA = step(abs(f), grueso) * step(UV.y, largo);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALBEDO = vec3(0.018, 0.014, 0.012);
	ROUGHNESS = 0.5;
	SPECULAR = 0.3;
}
