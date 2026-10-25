shader_type canvas_item;
// LA BANDERA DE FONDO de la pantalla de país: la bandera del país elegido, de tela,
// ondeando despacio a pantalla completa y oscurecida para que el globo y los textos
// se lean encima.
//
// NITIDEZ SIN ESCALONES. Las banderas de `Banderas` son de 96x64 (se dibujan en código):
// estiradas a 1920 px, el filtro lineal las deja borrosas y el «nearest» (o un bilineal
// nítido) enseña los escalones de 20 px del disco de Japón o de la estrella de Chile
// (captura 25-10). Aquí se hace lo que haría un vectorizado:
//   1. se difumina un poco (cuatro muestras lineales a medio texel): el contorno de esa
//      mancha difusa a mitad de camino entre dos colores es una curva SUAVE;
//   2. se «encaja» el resultado en el más parecido de los cuatro colores ORIGINALES que
//      rodean el punto: el borde queda nítido otra vez, pero siguiendo la curva suave.
// Requiere el filtro LINEAL en el nodo (para el difuminado del paso 1).

uniform vec2 tam_tex = vec2(96.0, 64.0);
uniform float oscuro = 0.5;
uniform float ola = 1.0;     // 0 = quieta (capturas de prueba y «reducir movimiento»)
uniform float zoom = 1.08;   // un poco de margen para que la onda no enseñe el borde

float dist2(vec3 a, vec3 b) {
	vec3 d = a - b;
	return dot(d, d);
}

void fragment() {
	vec2 uv = (UV - 0.5) / zoom + 0.5;
	float t = TIME * 0.9;
	float onda = sin(uv.x * 6.5 - t * 1.2 + uv.y * 2.2) * 0.6 + sin(uv.x * 11.0 - t * 1.9) * 0.4;
	uv.y += onda * 0.010 * ola;
	uv.x += sin(uv.y * 4.0 + t * 0.6) * 0.004 * ola;
	vec2 texel = 1.0 / tam_tex;
	vec3 difusa = (texture(TEXTURE, uv + texel * vec2(-0.5, -0.5)).rgb
		+ texture(TEXTURE, uv + texel * vec2(0.5, -0.5)).rgb
		+ texture(TEXTURE, uv + texel * vec2(-0.5, 0.5)).rgb
		+ texture(TEXTURE, uv + texel * vec2(0.5, 0.5)).rgb) * 0.25;
	ivec2 base = ivec2(floor(uv * tam_tex - 0.5));
	ivec2 lim = ivec2(tam_tex) - 1;
	vec3 c[4];
	c[0] = texelFetch(TEXTURE, clamp(base, ivec2(0), lim), 0).rgb;
	c[1] = texelFetch(TEXTURE, clamp(base + ivec2(1, 0), ivec2(0), lim), 0).rgb;
	c[2] = texelFetch(TEXTURE, clamp(base + ivec2(0, 1), ivec2(0), lim), 0).rgb;
	c[3] = texelFetch(TEXTURE, clamp(base + ivec2(1, 1), ivec2(0), lim), 0).rgb;
	// El mejor y el segundo mejor color (distintos) para la mezcla del borde.
	int i1 = 0;
	float d1 = dist2(difusa, c[0]);
	for (int i = 1; i < 4; i++) {
		float d = dist2(difusa, c[i]);
		if (d < d1) { d1 = d; i1 = i; }
	}
	// Sin mezcla entre el mejor y el segundo: se probó (captura 25-10) y en el borde de
	// cada texel el «segundo» cambia de golpe y dibujaba rayitas finas. Encajado seco: el
	// borde tiene escalón de 1 píxel de pantalla, que la onda de la tela ya disimula.
	vec3 col = c[i1];
	// Los pliegues: la tela que mira a la luz se aclara y la que se aparta se oscurece.
	float luz = 1.0 + 0.16 * onda * ola;
	COLOR = vec4(col * luz * oscuro, COLOR.a);
}
