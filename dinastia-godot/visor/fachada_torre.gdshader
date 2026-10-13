shader_type spatial;
// FACHADA DE TORRE (etapa 6, 13-10-2026). Sustituye la textura del kit (cuadros
// azules borrosos) por una rejilla de ventanas con marco y bandas de planta,
// en coordenadas del MUNDO (da igual la escala del modelo): ventanas de 3 x 3,6 m
// con reflejo distinto cada una, y de noche se encienden unas cuantas.
uniform vec4 pared : source_color = vec4(0.80, 0.82, 0.86, 1.0);
uniform vec4 vidrio : source_color = vec4(0.22, 0.36, 0.5, 1.0);
uniform vec2 celda = vec2(3.0, 3.6);
uniform bool pared_de_instancia = false;   // el color de pared lo trae cada instancia del MultiMesh
uniform float noche : hint_range(0.0, 1.0) = 0.0;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 n = abs(wnorm);
	if (n.y > 0.8) {
		ALBEDO = (pared_de_instancia ? COLOR.rgb : pared.rgb) * 0.85;
		ROUGHNESS = 0.95;
	} else {
		float u = (n.x > n.z) ? wpos.z : wpos.x;
		vec2 c = vec2(u / celda.x, wpos.y / celda.y);
		vec2 id = floor(c);
		vec2 f = fract(c);
		// Antialias: se difumina el borde según lo que cambia el patrón por píxel.
		vec2 w = fwidth(c) * 1.5;
		float vx = smoothstep(0.16 - w.x, 0.16 + w.x, f.x) * (1.0 - smoothstep(0.84 - w.x, 0.84 + w.x, f.x));
		float vy = smoothstep(0.2 - w.y, 0.2 + w.y, f.y) * (1.0 - smoothstep(0.82 - w.y, 0.82 + w.y, f.y));
		float v = vx * vy;
		float mx = smoothstep(0.1 - w.x, 0.1 + w.x, f.x) * (1.0 - smoothstep(0.9 - w.x, 0.9 + w.x, f.x));
		float my = smoothstep(0.14 - w.y, 0.14 + w.y, f.y) * (1.0 - smoothstep(0.88 - w.y, 0.88 + w.y, f.y));
		float marco = clamp(mx * my - v, 0.0, 1.0);
		float h = azar(id + floor(wpos.x * 0.0 + 1.0));
		vec3 col = pared_de_instancia ? COLOR.rgb : pared.rgb;
		col *= 1.0 - 0.18 * (1.0 - smoothstep(0.0, 0.1 + w.y, f.y));   // banda de forjado
		col = mix(col, vec3(0.1, 0.11, 0.12), marco);
		// Cada ventana con su tono: unas con la persiana a media altura, otras
		// con cortina clara o reflejo más oscuro (13-10-2026: todas iguales y muy
		// pulidas devolvían el azul del cielo en una sola mancha).
		vec3 g = vidrio.rgb * mix(0.7, 1.25, h);
		float persiana = step(0.72, h) * step(1.0 - mix(0.25, 0.7, fract(h * 7.3)), f.y);
		g = mix(g, pared_de_instancia ? COLOR.rgb * 0.85 : vec3(0.78, 0.76, 0.72), persiana * 0.8);
		col = mix(col, g, v);
		ALBEDO = col;
		ROUGHNESS = mix(0.85, 0.32, v);
		METALLIC = v * 0.25;
		float enc = step(0.6, h) * v * noche;
		EMISSION = vec3(1.0, 0.82, 0.5) * enc * 1.0;
	}
}
