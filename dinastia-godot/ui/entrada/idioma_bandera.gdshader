shader_type canvas_item;
// LA TELA DE LAS BANDERAS de la pantalla de idioma (25-10-2026). La bandera llega
// ya pintada en TEXTURE (un SubViewport, ver idioma_bandera.gd); aquí se ondula
// como una tela sujeta al mástil (la izquierda casi quieta, la punta ondea más),
// se le pone luz en las crestas y sombra en los valles, una trama finísima de
// tejido, un oscurecido suave en los bordes y una sombra proyectada debajo.
// `fuerza` sube en la tarjeta enfocada: la que miras es la que ondea.

uniform float fase = 0.0;
uniform float fuerza : hint_range(0.0, 1.0) = 0.25;
// Hueco alrededor de la tela, en fracción del rectángulo (lo pone el script).
uniform float margen = 0.1;

varying vec4 tinte;

void vertex() {
	// El modulate de los padres (fundidos de la pantalla) llega en COLOR: se
	// guarda para multiplicarlo al final en vez de pisarlo.
	tinte = COLOR;
}

float caja(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

void fragment() {
	vec2 uv = (UV - vec2(margen)) / (1.0 - 2.0 * margen);
	float t = TIME * (1.4 + 1.6 * fuerza) + fase;
	float k = 5.5;
	// La onda crece desde el mástil hacia la punta.
	float amp = (0.010 + 0.028 * fuerza) * (0.12 + uv.x);
	float ola = sin(uv.x * k - t) + 0.35 * sin(uv.x * k * 2.1 - t * 1.3 + 1.0);
	vec2 q = vec2(uv.x * (1.0 - 0.012 * fuerza * (1.0 + ola)), uv.y - ola * amp);
	// La luz sigue a la pendiente de la onda: crestas claras, valles oscuros.
	float pend = cos(uv.x * k - t) + 0.5 * cos(uv.x * k * 2.1 - t * 1.3 + 1.0);
	float luz = 1.0 + (0.07 + 0.13 * fuerza) * pend * (0.25 + uv.x);
	float d = caja(q - 0.5, vec2(0.5));
	float aa = max(fwidth(d), 0.0015);
	float dentro = 1.0 - smoothstep(-aa, aa, d);
	vec3 col = texture(TEXTURE, clamp(q, vec2(0.001), vec2(0.999))).rgb * luz;
	// Trama de tela: apenas se ve, pero quita el aspecto de plástico.
	col *= 0.975 + 0.025 * sin(q.y * 380.0) * sin(q.x * 560.0);
	// Bordes un pelo más oscuros (el dobladillo) y un brillo en diagonal.
	col *= mix(0.8, 1.0, smoothstep(0.0, 0.05, -d));
	col += vec3(0.06) * smoothstep(0.35, 0.0, abs(q.x - q.y * 0.6 - 0.15)) * (0.4 + fuerza);
	// Sombra proyectada abajo a la derecha, difuminada con la distancia.
	float ds = caja(q - 0.5 - vec2(0.018, 0.05), vec2(0.5));
	float sombra = (1.0 - smoothstep(-0.03, 0.09, ds)) * 0.42;
	vec4 fuera = vec4(0.0, 0.0, 0.0, sombra);
	COLOR = mix(fuera, vec4(col, 1.0), dentro) * tinte;
}
