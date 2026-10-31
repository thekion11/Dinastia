shader_type spatial;
// LOS DAÑOS DEL COCHE (31-10-2026, mejora C): una capa (material_overlay) sobre la carrocería del coche del
// jugador. Con `danio` (0..1) aparecen manchas oscuras de golpes (pintura saltada) y rayas claras de
// arañazos. Coordenadas del objeto: los daños no «nadan» al moverse el coche. (Sin hundir la superficie:
// una capa superpuesta que se hunde queda detrás de la carrocería y no se ve.)
render_mode blend_mix, depth_draw_never, cull_back;

uniform float danio : hint_range(0.0, 1.0) = 0.0;

varying vec3 lp;

float h3(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float ruido(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float n = ruido(lp * 3.0);
	float corte = 1.0 - danio * 0.6;   // con el coche destrozado, golpes en la mitad de la carrocería (no «quemado»)
	float golpe = smoothstep(corte, corte + 0.06, n);
	// Arañazos: rayas finas a lo largo del coche.
	float raya = step(0.93, ruido(vec3(lp.x * 2.0, lp.y * 60.0, lp.z * 2.0))) * step(0.55, ruido(lp * 1.5 + 7.0)) * danio;
	vec3 col = mix(vec3(0.12, 0.1, 0.09), vec3(0.85, 0.85, 0.82), raya);
	ALBEDO = col;
	ROUGHNESS = 0.9;
	ALPHA = clamp(golpe * 0.75 + raya, 0.0, 1.0) * step(0.001, danio);
}
