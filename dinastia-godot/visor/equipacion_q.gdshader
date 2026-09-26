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
// EL DISEÑADOR DE EQUIPACIONES (26-9-2026): la familia del diseño, sus
// parámetros y hasta 5 colores; la misma fórmula que `DisenosKit.color_en()`
// en 2D. familia >= 100 = los 12 estilos de siempre (fórmula `patron()`).
uniform int familia = -1;
uniform vec4 prm = vec4(0.0);
uniform vec4 cols[5] : source_color;
uniform int n_cols = 2;
uniform int trim = 1;
uniform int pant_dis = 0;
uniform vec4 pant_c2 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int med_dis = 0;
uniform vec4 med_c2 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int bot_dis = 0;
uniform vec4 bot_c2 : source_color = vec4(1.0);
uniform vec4 bot_c3 : source_color = vec4(0.13, 0.13, 0.13, 1.0);
// El dorsal en la espalda, en siete segmentos (0 = sin número).
uniform int dorsal = 0;
uniform vec4 color_num : source_color = vec4(1.0);
// Accesorios: alfa 0 = no lo lleva.
uniform vec4 acc_cintillo : source_color = vec4(0.0);
uniform vec4 acc_manguitos : source_color = vec4(0.0);
uniform vec4 acc_guantes : source_color = vec4(0.0);
uniform vec4 acc_munequeras : source_color = vec4(0.0);
uniform vec4 acc_brazalete : source_color = vec4(0.0);
uniform vec4 acc_cuello : source_color = vec4(0.0);
uniform vec4 acc_tobilleras : source_color = vec4(0.0);
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

float patron_de(int e, float x, float y) {
	if (e == 1) {
		return step(0.5, fract(x * 7.7 + 0.25));
	} else if (e == 2) {
		return 1.0 - step(0.07, abs(x + (y - 1.27)));
	} else if (e == 3) {
		return step(0.0, x);
	} else if (e == 4) {
		return step(1.42, y);
	} else if (e == 5) {
		return step(0.5, fract(y * 8.3));
	} else if (e == 6) {
		return 1.0 - step(0.045, abs(x - (y - 1.27)));
	} else if (e == 7) {
		return mod(floor(x * 14.0) + floor(y * 14.0), 2.0);
	} else if (e == 8) {
		return step(0.72, fract(x * 13.3 + 0.36));
	} else if (e == 9) {
		return smoothstep(1.42, 1.02, y) * 0.95;
	} else if (e == 10) {
		return 1.0 - step(0.095, abs(x + (y - 1.27)));
	} else if (e == 11) {
		return step(0.5, float((x > 0.0) != (y > 1.27)));
	}
	return 0.0;
}

float patron(float x, float y) { return patron_de(estilo, x, y); }


float h21(vec2 p) { return fract(sin(p.x * 127.1 + p.y * 311.7) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}
vec3 C(int i) { return cols[clamp(i, 0, 4)].rgb; }
vec3 ciclo(float id, float k) { return C(int(mod(id, max(k, 1.0)))); }
vec3 banda(float id, float k) { return C(1 + int(mod(id, max(k - 1.0, 1.0)))); }

// Espejo de `DisenosKit.color_en()`: mismo número por familia.
vec3 disenio(float u, float v, float x, float y) {
	float a = prm.x; float b = prm.y; float c = prm.z; float d = prm.w;
	int f = familia;
	if (f >= 100) { return mix(C(0), C(1), patron_de(f - 100, x, y)); }
	if (f == 1) { float s = (u + 1.0) * 0.5 * a; return fract(s) < b ? banda(floor(s), c) : C(0); }
	if (f == 2) { float s = v * a; return fract(s) < b ? banda(floor(s), c) : C(0); }
	if (f == 3) { float e = u * 0.5 - (v - 0.5) * a - c; if (abs(e) < b) return C(1);
		if (d > 0.5 && abs(e - b * 2.6) < b * 0.5) return C(2); return C(0); }
	if (f == 4) { return ciclo(floor(clamp((u + 1.0) * 0.5, 0.0, 0.999) * a), a <= 5.0 ? a : 2.0); }
	if (f == 5) { return ciclo(floor(clamp(v, 0.0, 0.999) * a), a); }
	if (f == 6) { float dv = abs(v - a); if (dv < b) return C(1); if (c > 0.5 && dv < b + 0.035) return C(2); return C(0); }
	if (f == 7) { float lim = a - u * u * b; if (v > lim) return C(1); if (c > 0.5 && v > lim - 0.04) return C(2); return C(0); }
	if (f == 8) { float cu = floor((u + 1.0) * 0.5 * a); float cv = floor(v * a);
		if (int(mod(cu + cv, 2.0)) == 1) return (b > 0.5 && int(mod(cu, 2.0)) == 1) ? C(2) : C(1); return C(0); }
	if (f == 9) { float t = a < 0.5 ? v : (a < 1.5 ? (u + 1.0) * 0.25 + v * 0.5 : (u + 1.0) * 0.5);
		return mix(C(0), C(1), a < 0.5 ? smoothstep(0.1, 0.9, 1.0 - t) : smoothstep(0.1, 0.9, t)); }
	if (f == 10) { float e2 = v - abs(u) * a * 0.5; if (c <= 1.0) return abs(e2 - 0.45) < b ? C(1) : C(0);
		return fract(e2 * c) < 0.35 ? C(1) : C(0); }
	if (f == 11) { return (abs(u - c) < a || abs(v - b) < a * 0.9) ? C(1) : C(0); }
	if (f == 12) { if (abs(u) > a) return C(1); if (c > 0.5 && abs(u) > a - 0.06) return C(2); return C(0); }
	if (f == 13) { if (abs(u) < a) return C(1); if (c > 0.5 && abs(u) < a + 0.07) return C(2); return C(0); }
	if (f == 14) { return fract((u + 1.0) * 0.5 * a) < 0.07 ? C(1) : C(0); }
	if (f == 15) { return fract((v + sin(u * a) * b) * c) < 0.5 ? C(1) : C(0); }
	if (f == 16) { return fract((v + abs(fract(u * a) - 0.5) * b) * c) < 0.5 ? C(1) : C(0); }
	if (f == 17) { float px = (u + 1.0) * 0.5 * a; float py = v * a * 1.2;
		if (length(vec2(fract(px) - 0.5, fract(py) - 0.5)) < b) return (c > 0.5 && int(mod(floor(px) + floor(py), 2.0)) == 1) ? C(2) : C(1);
		return C(0); }
	if (f == 18) { float qx = (u + 1.0) * 0.5 * a; float qy = v * a * 1.4;
		float r = abs(fract(qx) - 0.5) + abs(fract(qy) - 0.5);
		if (b > 0.5 && (abs(fract(qx + qy) - 0.5) < 0.03 || abs(fract(qx - qy) - 0.5) < 0.03)) return C(3);
		if (r < 0.5) return int(mod(floor(qx) + floor(qy), 2.0)) == 0 ? C(1) : C(2); return C(0); }
	if (f == 19) { float sx = (u + 1.0) * 0.5 * a; float sy = v * a * 1.3; float fila = floor(sy);
		float ox = sx + (int(mod(fila, 2.0)) == 1 ? 0.5 : 0.0);
		return length(vec2(fract(ox) - 0.5, fract(sy))) > 0.5 ? C(1) : C(0); }
	if (f == 20) { float ang = atan(v - 0.62, u); return int(mod(floor((ang + PI) / PI * a), 2.0)) == 1 ? C(1) : C(0); }
	if (f == 21) { return fract(length(vec2(u, (v - 0.62) * 1.2)) * a) < 0.5 ? C(1) : C(0); }
	if (f == 22) { float n = ruido(vec2((u + 3.0) * a, (v + 3.0) * a * 1.3)); int k = int(b);
		return C(clamp(int(n * float(k) * 1.15), 0, k - 1)); }
	if (f == 23) { float pos = a < 0.5 ? (u + 1.0) * 0.5 : v; return ciclo(floor(clamp(pos, 0.0, 0.999) * b), b); }
	if (f == 24) { float bo = min(1.0 - abs(u), min(v, 1.0 - v) * 1.6); if (bo < a) return C(1);
		if (b > 0.5 && bo < a + 0.05 && bo > a + 0.02) return C(2); return C(0); }
	if (f == 25) { float w = fract((u + ruido(vec2(v * a, 1.7)) * 0.5) * 2.5); return w < 0.3 ? C(1) : (w < 0.42 ? C(2) : C(0)); }
	if (f == 26) { bool vx = fract((u + 1.0) * 0.5 * a) < 0.3; bool vy = fract(v * a) < 0.3;
		if (vx && vy) return n_cols >= 4 ? C(3) : mix(C(1), C(2), 0.5); if (vx) return C(1); if (vy) return C(2); return C(0); }
	if (f == 27) { float rx = (u + v) * a * 0.5; float ry = (u - v) * a * 0.5; return int(mod(floor(rx) + floor(ry), 2.0)) == 1 ? C(1) : C(0); }
	if (f == 28) { return fract((u + 1.0) * 0.5 * a) < 0.1 + v * 0.7 ? C(1) : C(0); }
	if (f == 29) { float hh = h21(vec2(floor((u + 1.0) * 0.5 * a), floor(v * a))); return hh < 0.3 ? C(1) : (hh < 0.45 ? C(2) : C(0)); }
	return C(0);
}

// Un dígito de siete segmentos en (px, py) de 0 a 1.
float digito(int n, vec2 p) {
	if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0) return 0.0;
	int bits = n == 0 ? 63 : n == 1 ? 6 : n == 2 ? 91 : n == 3 ? 79 : n == 4 ? 102 : n == 5 ? 109 : n == 6 ? 125 : n == 7 ? 7 : n == 8 ? 127 : 111;
	float g = 0.24;
	float on = 0.0;
	// a arriba, b arriba-der, c abajo-der, d abajo, e abajo-izq, f arriba-izq, g medio
	if ((bits & 1) != 0 && p.y > 1.0 - g) on = 1.0;
	if ((bits & 2) != 0 && p.x > 1.0 - g && p.y > 0.5) on = 1.0;
	if ((bits & 4) != 0 && p.x > 1.0 - g && p.y < 0.5) on = 1.0;
	if ((bits & 8) != 0 && p.y < g) on = 1.0;
	if ((bits & 16) != 0 && p.x < g && p.y < 0.5) on = 1.0;
	if ((bits & 32) != 0 && p.x < g && p.y > 0.5) on = 1.0;
	if ((bits & 64) != 0 && abs(p.y - 0.5) < g * 0.5) on = 1.0;
	return on;
}

void fragment() {
	vec3 piel = texture(piel_tex, UV).rgb;
	vec4 m = texture(mascara, UV);
	vec3 c = texture(coords, UV).rgb;
	float x = mix(X_MIN, X_MAX, c.r);
	float y = c.g * Y_MAX;
	float z = c.b; // 0 atrás, 1 adelante (normalizada de -0,25 a 0,25 m)
	bool cubierta = c.r + c.g + c.b > 0.001;

	float lum = dot(piel, vec3(0.299, 0.587, 0.114));
	float pliegue = clamp(0.78 + lum * 0.45, 0.8, 1.12);

	bool manga = abs(x) > 0.215 && y > 1.22;
	float u = clamp(x / 0.215, -1.0, 1.0);
	float v = clamp((y - 1.0) / 0.52, 0.0, 1.0);
	vec3 camiseta;
	vec3 trim_col;
	if (familia >= 0) {
		// La manga sigue el dibujo desde el borde del torso.
		camiseta = disenio(manga ? sign(x) : u, v, manga ? sign(x) * 0.215 : x, y);
		trim_col = C(trim);
	} else {
		float p = manga ? ((estilo == 4 || (estilo == 3 && x > 0.0)) ? 1.0 : 0.0) : patron(x, y);
		camiseta = mix(color1.rgb, color2.rgb, p);
		trim_col = color2.rgb;
	}
	// Cuello y puños del color de ribete.
	if ((!manga && y > 1.505) || (manga && abs(x) > 0.405)) {
		camiseta = trim_col;
	}
	// El dorsal, en la espalda (z < 0,5), entre los omóplatos y la cintura.
	if (dorsal > 0 && !manga && z < 0.45 && y > 1.11 && y < 1.41 && abs(x) < 0.13) {
		// Vista desde atrás: la x va al revés (si no, el 12 se lee 21 y en espejo).
		float xn = -x;
		float dy = (y - 1.11) / 0.30;
		float on = 0.0;
		if (dorsal < 10) {
			on = digito(dorsal, vec2((xn + 0.055) / 0.11, dy));
		} else {
			on = max(digito(dorsal / 10, vec2((xn + 0.12) / 0.105, dy)), digito(dorsal % 10, vec2((xn - 0.015) / 0.105, dy)));
		}
		camiseta = mix(camiseta, color_num.rgb, on);
	}

	if (largo) {
		bool antebrazo = manga && abs(x) < 0.755;
		bool pierna = !manga && y >= 0.085 && y < 1.0;
		m.r = max(m.r, (cubierta && antebrazo) ? 1.0 : 0.0);
		m.g = max(m.g, (cubierta && pierna) ? 1.0 : 0.0);
		m.b = 0.0;
		camiseta = manga ? (familia >= 0 ? C(0) : color1.rgb) : camiseta;
	}

	// LOS PIES CALZADOS (C2): botín por debajo del tobillo, media hasta la
	// rodilla.
	if (cubierta && !manga && y < 0.115) {
		m.a = 1.0;
		m.b = 0.0;
	} else if (cubierta && !manga && y < 0.50 && m.g < 0.5 && !largo) {
		m.b = max(m.b, 1.0 - m.a);
	}

	// Pantalón con su diseño.
	vec3 pant = color_pantalon.rgb;
	float ex = clamp((abs(x) - 0.02) / 0.16, 0.0, 1.0);
	if (pant_dis == 1) pant = ex > 0.82 ? pant_c2.rgb : pant;
	else if (pant_dis == 2) pant = y < 0.67 ? pant_c2.rgb : pant;
	else if (pant_dis == 3) pant = x > 0.0 ? pant_c2.rgb : pant;
	else if (pant_dis == 4) pant = mix(pant, pant_c2.rgb, smoothstep(0.95, 0.65, y));
	else if (pant_dis == 5) pant = ((ex > 0.74 && ex < 0.8) || ex > 0.88) ? pant_c2.rgb : pant;
	// Medias con su diseño (t de 0 arriba a 1 abajo).
	vec3 med = color_medias.rgb;
	float tm = clamp((0.47 - y) / 0.38, 0.0, 1.0);
	if (med_dis == 1) med = fract(tm * 8.0) < 0.4 ? med_c2.rgb : med;
	else if (med_dis == 2) med = tm < 0.18 ? med_c2.rgb : med;
	else if (med_dis == 3) med = ((tm > 0.05 && tm < 0.12) || (tm > 0.17 && tm < 0.24)) ? med_c2.rgb : med;
	else if (med_dis == 4) med = tm > 0.55 ? med_c2.rgb : med;
	else if (med_dis == 5) med = (abs(fract(tm * 6.0) - 0.5) + abs(fract(x * 25.0) - 0.5) < 0.35) ? med_c2.rgb : med;
	// Botines: dibujo del modelo, suela y cuello.
	float bz = clamp((z - 0.22) / 0.53, 0.0, 1.0);
	float balto = clamp(y / 0.115, 0.0, 1.0);
	vec3 botin = color_botines.rgb;
	if (bot_dis == 1) botin = bz > 0.72 ? bot_c2.rgb : botin;
	else if (bot_dis == 2) botin = bz < 0.25 ? bot_c2.rgb : botin;
	else if (bot_dis == 3) botin = abs(balto - 0.5) < 0.14 ? bot_c2.rgb : botin;
	else if (bot_dis == 4) botin = mix(botin, bot_c2.rgb, bz);
	else if (bot_dis == 5) botin = fract(bz * 6.0) < 0.3 ? bot_c2.rgb : botin;
	else if (bot_dis == 6) botin = ruido(vec2(bz * 5.0, balto * 3.0 + x * 20.0)) > 0.55 ? bot_c2.rgb : botin;
	else if (bot_dis == 7) botin = balto > 0.5 ? bot_c2.rgb : botin;
	else if (bot_dis == 8) botin = abs(balto - 0.45 - sin(bz * 6.0) * 0.18) < 0.1 ? bot_c2.rgb : botin;
	if (y < 0.018) botin = bot_c3.rgb;
	if (y > 0.085 && y < 0.115) botin = mix(botin, familia >= 0 ? bot_c2.rgb : color2.rgb, 0.55);

	vec3 albedo = piel * tinte_piel;
	albedo = mix(albedo, camiseta * pliegue, m.r);
	albedo = mix(albedo, pant * pliegue, m.g);
	albedo = mix(albedo, med * pliegue, m.b);
	albedo = mix(albedo, botin, m.a);
	float tela = clamp(m.r + m.g + m.b, 0.0, 1.0);

	// ACCESORIOS, sobre la piel o sobre la ropa, por zonas de la pose de
	// reposo (brazos en T desde |x|=0,2; mano desde 0,75; cabeza hasta 1,8).
	if (cubierta) {
		bool brazo = abs(x) > 0.215 && y > 1.22;
		if (acc_manguitos.a > 0.5 && brazo && abs(x) >= 0.43 && abs(x) < 0.72) { albedo = acc_manguitos.rgb * pliegue; tela = 1.0; }
		if (acc_munequeras.a > 0.5 && brazo && abs(x) >= 0.70 && abs(x) < 0.755) { albedo = acc_munequeras.rgb * pliegue; tela = 1.0; }
		if (acc_guantes.a > 0.5 && brazo && abs(x) >= 0.755) { albedo = acc_guantes.rgb; tela = 1.0; }
		if (acc_brazalete.a > 0.5 && brazo && x > 0.30 && x < 0.36) { albedo = acc_brazalete.rgb; tela = 1.0; }
		if (acc_cintillo.a > 0.5 && !brazo && abs(x) < 0.13 && y > 1.745 && y < 1.78) { albedo = acc_cintillo.rgb; tela = 1.0; }
		if (acc_cuello.a > 0.5 && !brazo && abs(x) < 0.11 && y > 1.52 && y < 1.60) { albedo = acc_cuello.rgb * pliegue; tela = 1.0; }
		if (acc_tobilleras.a > 0.5 && !brazo && y > 0.10 && y < 0.15) { albedo = acc_tobilleras.rgb; tela = 1.0; }
	}
	ALBEDO = albedo;

	ROUGHNESS = mix(0.62, 0.82, tela);
	SPECULAR = mix(0.45, 0.25, tela);
	if (usa_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = mix(1.0, 0.35, tela);
	}
	RIM = borde;
	RIM_TINT = 0.35;
}
