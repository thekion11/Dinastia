shader_type spatial;
render_mode unshaded, cull_back;
// LA CINTA LED DEL FRENTE DE LA BANDEJA (21-10-2026). En los estadios de varias
// bandejas el peto de la de arriba lleva una cinta de LED con anuncios y los
// colores del club: aquí era una franja gris lisa de 3 m. Un plano por tramo,
// con paneles que se desplazan: colores del club con franjas, blanco con
// cheurones y uno oscuro con «texto» de puntos. Sin texturas.
uniform vec4 c1 : source_color = vec4(0.1, 0.4, 0.2, 1.0);
uniform vec4 c2 : source_color = vec4(1.0);
uniform float largo = 60.0;      // metros del tramo (UV.x 0..1)
uniform float vel = 0.6;         // metros por segundo
uniform float brillo = 1.6;

float h(float x) { return fract(sin(x * 91.7) * 43758.5); }

void fragment() {
	float x = UV.x * largo + TIME * vel;
	float y = UV.y;
	float panel = floor(x / 8.0);
	float px = fract(x / 8.0) * 8.0;
	float tipo = floor(h(panel) * 3.0);
	vec3 col;
	if (tipo < 1.0) {
		// Colores del club con dos franjas finas.
		col = c1.rgb;
		float f = step(0.28, y) * step(y, 0.36) + step(0.64, y) * step(y, 0.72);
		col = mix(col, c2.rgb, f);
	} else if (tipo < 2.0) {
		// Blanco (o el segundo color) con cheurones del primero.
		col = c2.rgb;
		float ch = step(0.5, fract((px + abs(y - 0.5) * 2.0) * 0.6));
		col = mix(col, c1.rgb, ch * 0.85);
	} else {
		// Fondo oscuro con «letras» de puntos (una matriz de LED).
		col = vec3(0.02);
		vec2 celda = vec2(floor(px * 9.0), floor(y * 7.0));
		float on = step(0.45, h(celda.x * 1.3 + celda.y * 7.1 + panel * 13.0));
		on *= step(0.15, y) * step(y, 0.85) * step(0.4, px) * step(px, 7.6);
		vec2 g = fract(vec2(px * 9.0, y * 7.0)) - 0.5;
		float punto = 1.0 - smoothstep(0.25, 0.42, length(g));
		col = mix(col, mix(c2.rgb, vec3(1.0), 0.4), on * punto);
	}
	// Separación entre paneles y un borde oscuro arriba y abajo.
	col *= step(0.12, px) * step(px, 7.88) * step(0.04, y) * step(y, 0.96) * 0.85 + 0.15;
	ALBEDO = col * brillo;
}
