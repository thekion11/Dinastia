shader_type spatial;
render_mode cull_disabled;
// BANDERAS GRANDES DE LA HINCHADA EN EL GOL (26-10-2026, `BanderasGrada`).
// Un plano subdividido que ondea entero en el vértice (sin texturas): franjas
// verticales con los dos colores del club. Son 3-4 por gol: el doble cara no pesa.
uniform vec3 color1 : source_color = vec3(0.1, 0.35, 0.2);
uniform vec3 color2 : source_color = vec3(0.95);
uniform float franjas = 3.0;
// 0 = recogida (bajo la grada), 1 = desplegada arriba.
uniform float subida = 0.0;
uniform float fase = 0.0;

void vertex() {
	// El mástil va en el borde izquierdo (UV.x = 0): ahí no se mueve.
	float suelta = UV.x;
	float t = TIME * 3.4 + fase;
	VERTEX.z += (sin(VERTEX.x * 0.9 - t) * 0.45 + sin(VERTEX.y * 1.3 - t * 1.4) * 0.18) * suelta;
	VERTEX.y += sin(VERTEX.x * 0.7 - t) * 0.12 * suelta;
	// Al subir: crece desde abajo.
	VERTEX.y = mix(-2.0, VERTEX.y, subida);
}

void fragment() {
	float f = step(0.5, fract(UV.x * franjas * 0.5));
	vec3 c = mix(color1, color2, f);
	// Sombra en los pliegues: más oscuro donde la tela mira de lado.
	ALBEDO = c * mix(0.62, 1.0, abs(NORMAL.z));
	ROUGHNESS = 0.9;
	SPECULAR = 0.1;
}
