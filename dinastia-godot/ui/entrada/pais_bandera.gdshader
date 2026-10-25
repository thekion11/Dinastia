shader_type canvas_item;
// LA BANDERA DE FONDO de la pantalla de país: los colores de la bandera del país elegido
// como un fondo SUAVE, muy difuminado y oscurecido, que no compite con el globo ni con los
// textos (captura 25-10: la bandera nítida a pantalla completa partía el fondo con bordes
// duros detrás del globo —el cantón azul de Chile, su estrella enorme—).
//
// Cómo: `PaisFondo._difuminada` encoge la bandera a 8x6 y la reagranda (cúbica); aquí un gaussiano 7x7 fino quita las ondulaciones. Antes, un gaussiano con radio de ~1/5 de la
// bandera. Así de cualquier bandera (franjas, cruces, discos, cantones) queda un degradado
// de sus colores sin una sola arista, sea cual sea su forma o proporción. Encima se le
// quita algo de saturación y se oscurece, con un poco más de oscuridad arriba y abajo
// para que el título y el pie se lean. La «tela» se nota solo en una ondulación lenta de
// la luz.
// Requiere el filtro LINEAL en el nodo.

uniform vec2 tam_tex = vec2(96.0, 64.0);  // se mantiene por compatibilidad (ya no se usa)
uniform float oscuro = 0.42;
uniform float ola = 1.0;     // 0 = quieta (capturas de prueba y «reducir movimiento»)
uniform float zoom = 1.08;
uniform float radio = 0.08;  // radio del difuminado fino, en fracción (la textura llega ya difuminada)
uniform float desatura = 0.3;

void fragment() {
	vec2 uv = (UV - 0.5) / zoom + 0.5;
	float t = TIME * 0.9;
	float onda = sin(uv.x * 5.0 - t * 1.1 + uv.y * 2.0) * 0.6 + sin(uv.x * 9.0 - t * 1.7) * 0.4;
	uv.y += onda * 0.012 * ola;
	vec3 suma = vec3(0.0);
	float peso = 0.0;
	for (int j = -3; j <= 3; j++) {
		for (int i = -3; i <= 3; i++) {
			vec2 d = vec2(float(i), float(j)) / 3.0;
			float w = exp(-dot(d, d) * 2.0);
			// clamp: fuera de la bandera se repite su borde (nada de negro ni de bordes).
			vec2 p = clamp(uv + d * radio, vec2(0.0), vec2(1.0));
			suma += texture(TEXTURE, p).rgb * w;
			peso += w;
		}
	}
	vec3 col = suma / peso;
	float gris = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(gris), desatura);
	// Más oscuro arriba (título) y abajo (pie), sin cortes.
	float banda = 1.0 - 0.35 * pow(abs(UV.y - 0.5) * 2.0, 2.0);
	float luz = 1.0 + 0.06 * onda * ola;
	COLOR = vec4(col * luz * oscuro * banda, COLOR.a);
}
