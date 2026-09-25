shader_type spatial;
// LA EQUIPACIÓN PINTADA SOBRE EL CUERPO QUATERNIUS (25-9-2026).
//
// Sustituye a las cuatro piezas de ropa "Peasant" tintadas, que dejaban a los
// jugadores casi negros y con la piel asomando por los desgarros de la ropa
// medieval. Aquí la camiseta, el pantalón, las medias y los botines se pintan
// DIRECTAMENTE sobre la textura del cuerpo, con una máscara que dice qué píxel
// es cada prenda (`equipacion_mascara.png`) y las coordenadas de la pose de
// reposo de cada píxel (`equipacion_coords.png`), las dos generadas desde la
// geometría del propio modelo por `herramientas/mascara_equipacion.py`.
//
// Los estilos son los mismos 12 de `Jersey.svg_de()` -la camiseta 2D de la
// ficha-, para que lo que se ve en el partido coincida con lo que se ve en el
// menú.

uniform sampler2D piel_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_disable;
uniform bool usa_normal = false;
uniform sampler2D mascara : hint_default_black, filter_linear_mipmap, repeat_disable;
uniform sampler2D coords : hint_default_black, filter_linear_mipmap, repeat_disable;

uniform vec4 color1 : source_color = vec4(0.17, 0.42, 0.27, 1.0);
uniform vec4 color2 : source_color = vec4(1.0);
uniform vec4 color_pantalon : source_color = vec4(1.0);
uniform vec4 color_medias : source_color = vec4(0.17, 0.42, 0.27, 1.0);
uniform vec4 color_botines : source_color = vec4(0.07, 0.07, 0.08, 1.0);
// Índice en la tabla KITS: 0 liso, 1 franjas, 2 banda, 3 mitad, 4 hombros,
// 5 aros, 6 diagonal, 7 cuadros, 8 vertical3, 9 degrade, 10 sash, 11 arlequin.
uniform int estilo = 0;
// Tono de piel del jugador sobre el tono medio de la textura original.
uniform vec3 tinte_piel = vec3(1.0);
// Borde de luz: separa al jugador del césped desde la cámara alta.
uniform float borde = 0.45;
// Manga y pantalón largos (el presentador del sorteo, el cuerpo técnico): las
// zonas extra -antebrazo, rodilla y pantorrilla- salen de las coordenadas de
// reposo, no de la máscara, que solo marca la equipación de juego.
uniform bool largo = false;

// Deshace la normalización de `mascara_equipacion.py`.
const float X_MIN = -0.95;
const float X_MAX = 0.95;
const float Y_MAX = 1.85;

float patron(float x, float y) {
	if (estilo == 1) {
		return step(0.5, fract(x * 7.7 + 0.25));
	} else if (estilo == 2) {
		return 1.0 - step(0.07, abs(x + (y - 1.27)));
	} else if (estilo == 3) {
		return step(0.0, x);
	} else if (estilo == 4) {
		return step(1.42, y);
	} else if (estilo == 5) {
		return step(0.5, fract(y * 8.3));
	} else if (estilo == 6) {
		return 1.0 - step(0.045, abs(x - (y - 1.27)));
	} else if (estilo == 7) {
		return mod(floor(x * 14.0) + floor(y * 14.0), 2.0);
	} else if (estilo == 8) {
		return step(0.72, fract(x * 13.3 + 0.36));
	} else if (estilo == 9) {
		return smoothstep(1.42, 1.02, y) * 0.95;
	} else if (estilo == 10) {
		return 1.0 - step(0.095, abs(x + (y - 1.27)));
	} else if (estilo == 11) {
		return step(0.5, float((x > 0.0) != (y > 1.27)));
	}
	return 0.0;
}

void fragment() {
	vec3 piel = texture(piel_tex, UV).rgb;
	vec4 m = texture(mascara, UV);
	vec3 c = texture(coords, UV).rgb;
	float x = mix(X_MIN, X_MAX, c.r);
	float y = c.g * Y_MAX;

	// Los pliegues de la tela: la luminancia de la textura original (músculo,
	// sombras de la piel) modula un poco la prenda, para que no parezca un
	// muñeco de plástico pintado de un solo color.
	float lum = dot(piel, vec3(0.299, 0.587, 0.114));
	float pliegue = clamp(0.78 + lum * 0.45, 0.8, 1.12);

	bool manga = abs(x) > 0.215 && y > 1.22;
	float p = manga ? ((estilo == 4 || (estilo == 3 && x > 0.0)) ? 1.0 : 0.0) : patron(x, y);
	vec3 camiseta = mix(color1.rgb, color2.rgb, p);
	// Cuello y puños del color secundario, como `Jersey.svg_de()`.
	if ((!manga && y > 1.505) || (manga && abs(x) > 0.405)) {
		camiseta = color2.rgb;
	}

	if (largo) {
		bool cubierto = c.r + c.g + c.b > 0.001;
		bool antebrazo = manga && abs(x) < 0.755;
		bool pierna = !manga && y >= 0.085 && y < 1.0;
		m.r = max(m.r, (cubierto && antebrazo) ? 1.0 : 0.0);
		m.g = max(m.g, (cubierto && pierna) ? 1.0 : 0.0);
		m.b = 0.0;
		camiseta = manga ? color1.rgb : camiseta;
	}

	vec3 albedo = piel * tinte_piel;
	albedo = mix(albedo, camiseta * pliegue, m.r);
	albedo = mix(albedo, color_pantalon.rgb * pliegue, m.g);
	albedo = mix(albedo, color_medias.rgb * pliegue, m.b);
	albedo = mix(albedo, color_botines.rgb, m.a);
	ALBEDO = albedo;

	float tela = clamp(m.r + m.g + m.b, 0.0, 1.0);
	ROUGHNESS = mix(0.62, 0.82, tela);
	SPECULAR = mix(0.45, 0.25, tela);
	if (usa_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = mix(1.0, 0.35, tela);
	}
	RIM = borde;
	RIM_TINT = 0.35;
}
