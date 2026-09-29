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
// Patrocinadores (`SponsorKit`): logo + palabra en el pecho y la espalda, solo
// logo en la manga y el pantalón.
uniform bool hay_sp_pecho = false;
uniform sampler2D sp_pecho : source_color, filter_linear_mipmap, repeat_disable;
uniform bool hay_sp_manga = false;
uniform sampler2D sp_manga : source_color, filter_linear_mipmap, repeat_disable;
uniform bool hay_sp_espalda = false;
uniform sampler2D sp_espalda : source_color, filter_linear_mipmap, repeat_disable;
uniform bool hay_sp_short = false;
uniform sampler2D sp_short : source_color, filter_linear_mipmap, repeat_disable;
uniform float sp_asp_pecho = 4.0;
// El corte del cuello: 0 pico, 1 redondo, 2 polo con tapeta, 3 mao (alto).
uniform int cuello = 1;
// ROPA APARTE (`RopaSeparada`): esta malla ES una prenda (1 camiseta, 2
// pantalón, 3 medias) y se pinta entera como tal. 0 = el cuerpo.
uniform int prenda = 0;
// ROPA DE CALLE (peatones, hinchas): sin escudo, marca, patrocinadores ni dorsal.
uniform bool civil = false;
uniform float sp_asp_espalda = 4.0;
// Borde de luz: separa al jugador del césped desde la cámara alta.
uniform float borde = 0.45;
// Manga y pantalón largos (el presentador del sorteo, el cuerpo técnico): las
// zonas extra -antebrazo, rodilla y pantorrilla- salen de las coordenadas de
// reposo, no de la máscara, que solo marca la equipación de juego.
uniform bool largo = false;

// LA CARA 2D MOLDEADA SOBRE EL MODELO 3D (29-9-2026): los rasgos del retrato
// de la ficha (`Cara.svg_rasgos`) o la foto real, proyectados de frente con la
// pose de reposo. Ojos del retrato (26,33)/(38,33) = centro de los globos
// oculares (x = ±0,0338 m, y = 1,6986 m); boca (32, 44,5) = boca (y = 1,622 m).
uniform bool hay_cara = false;
uniform sampler2D cara_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D barba_tex : hint_default_transparent, filter_linear_mipmap, repeat_disable;
uniform vec4 barba_color : source_color = vec4(0.1, 0.07, 0.05, 1.0);
// Menos fuerza cuando encima va la barba 3D (la pintada solo rellena debajo).
uniform float barba_fuerza = 0.0;
uniform bool hay_foto = false;
uniform sampler2D foto_tex : source_color, filter_linear_mipmap, repeat_disable;
// Del espacio del retrato (0-64) a la foto (0-1): u = dot(foto_u, (sx, sy, 1)).
uniform vec3 foto_u = vec3(0.0);
uniform vec3 foto_v = vec3(0.0);
uniform vec3 foto_tono = vec3(1.0);
// -1: usar la mitad izquierda de la foto (en espejo) para toda la cara; 1: la
// derecha; 0: la foto entera (de frente).
uniform int foto_espejo = 0;

// La pose de reposo exacta, escrita en la malla por `VestidorQ._con_reposo()`.
uniform bool usa_reposo = false;
// Cuánto se separa la tela del cuerpo, en metros (0 = pintada sobre la piel).
uniform float holgura = 0.02;
// Cuánto tapa la tela los músculos (0 = pintada sobre la piel, 1 = superficie
// alisada del todo). Ropa de calle más; camisetas de juego menos.
uniform float alisar = 0.0;
varying vec3 v_reposo;

void vertex() {
	v_reposo = vec3(UV2.x, UV2.y, COLOR.r);
	// LA ROPA SUELTA (26-9-2026, pedido: "están muy pegadas al cuerpo"): los
	// vértices de la camiseta y el pantalón se separan del cuerpo por su
	// normal -la tela no se pega a cada músculo-, y la manga y el pantalón se
	// abren hacia el borde como en una equipación de verdad.
	if (usa_reposo) {
		float ax = abs(v_reposo.x);
		float y = v_reposo.y;
		float brazo = smoothstep(0.2, 0.235, ax) * smoothstep(1.19, 1.24, y);
		float torso = (1.0 - brazo) * smoothstep(0.96, 1.02, y) * (1.0 - smoothstep(1.47, 1.53, y));
		float manga = brazo * (1.0 - smoothstep(0.41, 0.45, ax));
		float pant = (1.0 - brazo) * smoothstep(0.58, 0.63, y) * (1.0 - smoothstep(1.0, 1.04, y));
		float inflar = torso * holgura * (0.8 + 0.4 * smoothstep(1.35, 1.05, y))
			+ manga * holgura * (0.5 + 1.1 * smoothstep(0.25, 0.43, ax))
			+ pant * holgura * (0.75 + 0.85 * smoothstep(0.85, 0.63, y));
		// Pantalón y manga largos (ropa de calle, cuerpo técnico): la tela
		// cae suelta hasta el tobillo y la muñeca, no como unas calzas.
		if (largo) {
			float pierna_baja = (1.0 - brazo) * smoothstep(0.1, 0.16, y) * (1.0 - smoothstep(0.58, 0.63, y));
			float antebrazo = brazo * smoothstep(0.41, 0.45, ax) * (1.0 - smoothstep(0.66, 0.7, ax));
			inflar += pierna_baja * holgura * (1.2 + 0.4 * smoothstep(0.5, 0.2, y)) + antebrazo * holgura * 0.9;
			// Pantalón de calle: la pierna se rellena hasta un tubo recto
			// alrededor de su eje (la tela cuelga, no dibuja gemelo ni
			// cuádriceps). Solo hacia fuera: nunca se mete dentro del cuerpo.
			if (civil) {
				vec2 rel = vec2(ax - 0.112, (v_reposo.z * 0.5 - 0.25) + 0.04);
				float r = length(rel);
				float objetivo = mix(0.085, 0.102, smoothstep(0.25, 0.85, y));
				float pierna = (1.0 - brazo) * smoothstep(0.1, 0.16, y) * (1.0 - smoothstep(0.88, 0.94, y));
				inflar += pierna * max(objetivo - r, 0.0);
				// Y la manga, igual alrededor del brazo (eje a la altura del hombro).
				vec2 rb = vec2(y - 1.455, (v_reposo.z * 0.5 - 0.25) + 0.068);
				float manga_c = brazo * (1.0 - smoothstep(0.66, 0.7, ax));
				inflar += manga_c * max(mix(0.058, 0.046, smoothstep(0.3, 0.66, ax)) - length(rb), 0.0);
			}
		}
		// LA TELA TAPA LOS MÚSCULOS (26-9-2026): donde hay ropa, la superficie
		// se acerca a la versión ALISADA del cuerpo (`VestidorQ._alisado`):
		// se rellenan los surcos entre músculos y la luz cae como sobre tela,
		// no como sobre abdominales pintados. La normal alisada está en la pose
		// de reposo; se lleva a la pose actual con el mismo giro que llevó la
		// normal de reposo a la animada.
		if (alisar > 0.0 && dot(CUSTOM1.xyz, CUSTOM1.xyz) > 0.25) {
			float largas = largo ? 1.0 : 0.0;
			float manga_l = brazo * (1.0 - smoothstep(mix(0.41, 0.66, largas), mix(0.45, 0.70, largas), ax));
			float pant_l = (1.0 - brazo) * smoothstep(mix(0.58, 0.12, largas), mix(0.63, 0.16, largas), y) * (1.0 - smoothstep(1.0, 1.04, y));
			// Ropa de calle: el zapato tampoco marca los dedos del pie.
			float zapato = (civil && largo) ? (1.0 - brazo) * (1.0 - smoothstep(0.1, 0.13, y)) : 0.0;
			float ropa = max(max(torso, zapato), max(manga_l, pant_l)) * alisar;
			VERTEX += NORMAL * zapato * 0.008;
			vec3 a = normalize(CUSTOM1.xyz);
			vec3 b = normalize(NORMAL);
			vec3 v = cross(a, b);
			float c = dot(a, b);
			vec3 x = CUSTOM0.xyz;
			vec3 xr = x * c + cross(v, x) + v * (dot(v, x) / (1.0 + c + 0.0001));
			VERTEX += NORMAL * CUSTOM0.w * ropa;
			NORMAL = normalize(mix(NORMAL, normalize(xr), ropa));
		}
	}
}

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

// Un sponsor encajado sin deformar en su zona: `st` de 0 a 1 (x a la derecha,
// y hacia abajo), `zona` y `img` son las proporciones ancho/alto.
vec4 sp_encajado(sampler2D t, vec2 st, float zona, float img) {
	if (img > zona) { st.y = (st.y - 0.5) * img / zona + 0.5; }
	else { st.x = (st.x - 0.5) * zona / img + 0.5; }
	if (st.x < 0.0 || st.x > 1.0 || st.y < 0.0 || st.y > 1.0) return vec4(0.0);
	return texture(t, st);
}

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
	if (f == 30) { float gx = (u + 1.0) * 0.5 * a; float gy = v * a * 1.2; float rr = b * clamp(1.0 - v, 0.0, 1.0);
		return length(vec2(fract(gx) - 0.5, fract(gy) - 0.5)) < rr ? C(1) : C(0); }
	if (f == 31) { return fract(ruido(vec2(u * a + 5.0, v * a + 5.0)) * b) < 0.14 ? C(1) : C(0); }
	if (f == 32) { float vena = abs(sin((u + ruido(vec2(u * 2.0 + 1.0, v * 3.0)) * 1.6) * a));
		return vena < 0.07 ? C(1) : mix(C(0), C(2), 0.35 * ruido(vec2(u * 3.0, v * 3.0 + 4.0))); }
	if (f == 33) { float fx = (u + v * 0.6) * a; float fy = (v - u * 0.4) * a; float tri = fract(fx) > fract(fy) ? 1.0 : 0.0;
		float hf = h21(vec2(floor(fx) + tri * 7.0, floor(fy))); return hf < 0.33 ? C(1) : (hf < 0.55 ? C(2) : C(0)); }
	if (f == 34) { if (abs(u) > 1.01) return C(1); if (a > 0.5 && v > 0.86) return C(1); if (abs(v - 0.86) < 0.02 && a > 0.5) return C(2); return C(0); }
	if (f == 35) { float e3 = u * a * 0.5 + (v - 0.5); if (abs(e3) < 0.025) return C(2); return e3 > 0.0 ? C(1) : C(0); }
	if (f == 36) { return abs(v - 0.6 - (abs(fract(u * a) - 0.5) - 0.25) * b) < 0.05 ? C(1) : C(0); }
	if (f == 37) { return (fract((u + 1.0) * 0.5 * a) < 0.06 || fract(v * a * 1.2) < 0.06) ? C(1) : C(0); }
	if (f == 38) { vec2 dv2 = vec2(fract((u + 1.0) * 0.5 * a) - 0.5, fract(v * a * 1.2) - 0.5); float th = atan(dv2.y, dv2.x);
		return length(dv2) < b * (0.55 + 0.45 * cos(5.0 * th)) ? C(1) : C(0); }
	if (f == 39) { return fract((u + 1.0) * 0.5 * a) < b ? mix(C(1), C(2), v) : C(0); }
	if (f == 40) { if (abs(v - a) < b) return fract((u + 1.0) * 6.0) < 0.15 ? C(2) : C(1); return C(0); }
	if (f == 41) { return mix(C(0), C(1), smoothstep(0.1, 1.1, length(vec2(u, (v - 0.62) * 1.3)))); }
	if (f == 42) { float hx = (u + 1.0) * 0.5 * a; float hy = v * a * 1.2;
		float rd = b * clamp((u + 1.0) * 0.5 * 0.6 + (1.0 - v) * 0.6, 0.0, 1.0);
		return length(vec2(fract(hx) - 0.5, fract(hy) - 0.5)) < rd ? C(1) : C(0); }
	vec3 A = d > 0.5 ? C(2) : C(1);
	if (f == 43) { float e = v - (0.98 - abs(u) * a); if (abs(e) < b) return C(1); return abs(e) < b + 0.035 ? A : C(0); }
	if (f == 44) { float t = 0.5 + (1.0 - abs(u)) * a; if (abs(v - t) < 0.025) return A; return v > t ? C(1) : C(0); }
	if (f == 45) { if (abs(v - a) < b) return C(1); return abs(v - a + 0.2) < b ? A : C(0); }
	if (f == 46) { if (abs(u) < 0.03) return A; if (u < 0.0) return fract((u + 1.0) * a) < 0.5 ? C(1) : C(0); return C(0); }
	if (f == 47) { float z = a + (abs(fract(u * b) - 0.5) - 0.25) * 0.12; if (v > z + 0.02) return C(1); return v > z - 0.02 ? A : C(0); }
	if (f == 48) { vec2 p = vec2(u * a, v * a * 1.15); vec2 r = vec2(1.0, 1.732);
		vec2 aa = mod(p, r) - r * 0.5; vec2 bb = mod(p - r * 0.5, r) - r * 0.5;
		vec2 g = dot(aa, aa) < dot(bb, bb) ? aa : bb;
		float dh = max(abs(g.x), abs(g.x) * 0.5 + abs(g.y) * 0.866);
		if (dh > 0.45) return C(1);
		vec2 cc = p - g; return h21(vec2(floor(cc.x * 2.0), floor(cc.y * 2.0))) < 0.22 ? A : C(0); }
	if (f == 49) { float tx = (u + 1.0) * 0.5 * a; float ty = v * a; float fil = mod(floor(ty), 2.0);
		float tri = fract(tx + fil * 0.5);
		if (fract(ty) < 1.0 - abs(tri - 0.5) * 2.0) return mod(floor(tx + fil * 0.5) + floor(ty), 2.0) < 0.5 ? C(1) : A;
		return C(0); }
	if (f == 50) { float s = (u + sin(v * b) * 0.06) * a * 0.5; if (fract(s) < 0.5) return mod(floor(s), 2.0) < 0.5 ? C(1) : A; return C(0); }
	if (f == 51) { float z = sin(u * a * 3.0 + ruido(vec2(u * 2.0 + 3.0, v * 2.5)) * b + v * 2.0);
		if (z > 0.3) return C(1); return (z > 0.1 && d > 0.5) ? A : C(0); }
	if (f == 52) { float s = fract((u + v * a) * b); if (s < 0.35) return C(1); return (s < 0.45 && d > 0.5) ? A : C(0); }
	if (f == 53) { float cx = (u + 1.0) * 0.5 * a; if (fract(cx) < 0.06) return d > 0.5 ? A : C(1);
		float sg = mod(floor(cx), 2.0) < 0.5 ? 1.0 : -1.0;
		return fract(v * a * 1.2 + sg * fract(cx)) < 0.5 ? C(1) : C(0); }
	if (f == 54) { float dv = abs(v - a); if (abs(dv - 0.12) < 0.012) return A;
		if (dv < 0.12) return h21(vec2(floor((u + 1.0) * 40.0), 3.0)) < 0.5 ? C(1) : C(0); return C(0); }
	if (f == 55) { float r = length(vec2(u, (v - 0.6) * 1.2)); if (abs(r - a) < b) return C(1); return abs(r - a - b * 2.2) < b * 0.5 ? A : C(0); }
	if (f == 56) { float e = v - (0.72 + abs(u) * a); if (abs(e) < b) return C(1); return abs(e + 0.1) < b * 0.6 ? A : C(0); }
	if (f == 57) { if (abs(u) > a) { if (fract(v * b) < 0.5) return C(1); return d > 0.5 ? C(2) : C(0); } return C(0); }
	if (f == 58) { float fl = a + ruido(vec2(u * 4.0, v * 2.0 + 7.0)) * 0.25 + sin(u * b) * 0.05; if (v < fl) return C(1); return v < fl + 0.05 ? A : C(0); }
	if (f == 59) { float mx = (u + 1.0) * 0.5 * a; float my = v * a * 1.2; float md = 9.0; float mh = 0.0;
		for (int oy = -1; oy <= 1; oy++) { for (int ox = -1; ox <= 1; ox++) {
			float cx = floor(mx) + float(ox); float cy = floor(my) + float(oy);
			float px = cx + 0.5 + (h21(vec2(cx, cy)) - 0.5) * 0.7; float py = cy + 0.5 + (h21(vec2(cy + 3.1, cx)) - 0.5) * 0.7;
			float dm = length(vec2(mx - px, my - py)); if (dm < md) { md = dm; mh = h21(vec2(cx + 9.0, cy + 9.0)); } } }
		if (mh < 0.35) return C(1); return mh < 0.55 ? A : C(0); }
	if (f == 60) { float dd = abs(u) + abs(v - 0.58) * 1.3; if (dd < a) return C(1); return abs(dd - a - 0.06) < 0.02 ? A : C(0); }
	if (f == 61) { bool sx = fract((u + 1.0) * 0.5 * a) < 0.5; bool sy = fract(v * a * 1.2) < 0.5;
		if (sx && sy) return C(1); if (sx || sy) return d > 0.5 ? C(2) : C(0); return C(0); }
	if (f == 62) { float w = fract((v - u * a * 0.3) * b); float an = 0.12 * (u + 1.0); if (w < an) return C(1); return w < an + 0.03 ? A : C(0); }
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
	if (usa_reposo) {
		// Coordenadas exactas y cortes de prenda suaves (mismas zonas que
		// `mascara_equipacion.py::zonas()`), con medio centímetro de borde.
		x = v_reposo.x;
		y = v_reposo.y;
		z = v_reposo.z;
		cubierta = true;
		float ax = abs(x);
		float w = 0.004;
		float brazo = smoothstep(0.215 - w, 0.215 + w, ax) * smoothstep(1.22 - w, 1.22 + w, y);
		float torso = smoothstep(1.0 - w, 1.0 + w, y) * (1.0 - smoothstep(1.535 - w, 1.535 + w, y));
		m.r = max(brazo * (1.0 - smoothstep(0.43 - w, 0.43 + w, ax)), (1.0 - brazo) * torso);
		m.g = (1.0 - brazo) * smoothstep(0.62 - w, 0.62 + w, y) * (1.0 - smoothstep(1.0 - w, 1.0 + w, y));
		m.b = (1.0 - brazo) * smoothstep(0.085 - w, 0.085 + w, y) * (1.0 - smoothstep(0.47 - w, 0.47 + w, y));
		m.a = (1.0 - brazo) * (1.0 - smoothstep(0.085 - w, 0.085 + w, y));
	}
	if (prenda == 1) { m = vec4(1.0, 0.0, 0.0, 0.0); cubierta = true; }
	else if (prenda == 2) { m = vec4(0.0, 1.0, 0.0, 0.0); cubierta = true; }
	else if (prenda == 3) { m = vec4(0.0, 0.0, 1.0, 0.0); cubierta = true; }

	float lum = dot(piel, vec3(0.299, 0.587, 0.114));
	float pliegue = clamp(0.78 + lum * 0.45, 0.8, 1.12);
	if (usa_reposo) {
		// La tela no se pega al músculo como la piel: menos relieve del cuerpo
		// y, en cambio, arrugas suaves de tela (más en costados y cintura) y
		// sombra bajo el brazo y en el borde del pantalón.
		float arruga = ruido(vec2(x * 16.0 + 3.0, y * 5.0)) * 0.6 + ruido(vec2(x * 34.0, y * 11.0 + 7.0)) * 0.4;
		float lado_t = smoothstep(0.1, 0.2, abs(x)) * step(abs(x), 0.215);
		pliegue = clamp(0.93 + lum * 0.12, 0.92, 1.05) * (1.0 - (arruga - 0.45) * (0.08 + lado_t * 0.1));
		pliegue *= 1.0 - 0.18 * (1.0 - smoothstep(0.0, 0.05, abs(y - 1.26))) * smoothstep(0.17, 0.215, abs(x)) * step(abs(x), 0.25);
		pliegue *= 1.0 - 0.12 * (1.0 - smoothstep(0.0, 0.025, abs(y - 1.0)));
	}

	bool manga = abs(x) > 0.215 && y > 1.22;
	float u = clamp(x / 0.215, -1.0, 1.0);
	float v = clamp((y - 1.0) / 0.52, 0.0, 1.0);
	vec3 camiseta;
	vec3 trim_col;
	if (familia >= 0) {
		// La manga sigue el dibujo desde el borde del torso.
		// REALISMO (26-9-2026): el dibujo se promedia en cuatro puntos del
		// tamaño de un píxel, así los bordes de las franjas no salen en
		// escalera (los estampados de verdad están sublimados, no recortados).
		float uu = manga ? sign(x) * 1.05 : u;
		vec2 du = vec2(dFdx(uu), dFdy(uu)) * 0.5;
		vec2 dv = vec2(dFdx(v), dFdy(v)) * 0.5;
		float xx = manga ? sign(x) * 0.215 : x;
		camiseta = (disenio(uu + du.x + du.y, v + dv.x + dv.y, xx, y) + disenio(uu - du.x - du.y, v - dv.x - dv.y, xx, y)
			+ disenio(uu + du.x - du.y, v + dv.x - dv.y, xx, y) + disenio(uu - du.x + du.y, v - dv.x + dv.y, xx, y)) * 0.25;
		trim_col = C(trim);
	} else {
		float p = manga ? ((estilo == 4 || (estilo == 3 && x > 0.0)) ? 1.0 : 0.0) : patron(x, y);
		camiseta = mix(color1.rgb, color2.rgb, p);
		trim_col = color2.rgb;
	}
	// Cuello y puños del color de ribete.
	// En ropa de calle (civil) no hay cuello acanalado de fútbol: la franja
	// ancha sobre los hombros delataba una camiseta de juego.
	if ((!manga && y > 1.505 && !civil) || (manga && abs(x) > 0.405)) {
		camiseta = trim_col;
	}
	// DETALLES DE CONFECCIÓN (realismo): cuello y puños acanalados, costuras
	// laterales y de hombro un poco más oscuras, escudo del club (izquierda
	// del pecho) y una marca de ropa inventada (derecha).
	bool frente = z > 0.55;
	if ((!manga && y > 1.505 && !civil) || (manga && abs(x) > 0.405)) {
		camiseta *= 0.9 + 0.1 * step(0.5, fract((manga ? abs(x) : y) * 180.0));
	}
	if (familia >= 0 && !manga && frente) {
		if (cuello == 0 && y > 1.44 && y < 1.51) {
			float borde_v = (y - 1.44) * 0.77;
			// Civil (traje): dentro de la V asoma la camisa (color 3).
			if (abs(x) < borde_v - 0.007) camiseta = civil ? C(2) : C(0) * 0.55;
			else if (abs(abs(x) - borde_v) < 0.007) camiseta = trim_col;
		} else if (cuello == 2 && abs(x) < 0.011 && y > 1.43 && y < 1.51) {
			camiseta = trim_col;
			if (abs(x) < 0.004 && (abs(y - 1.46) < 0.004 || abs(y - 1.485) < 0.004)) camiseta = C(0) * 0.7;
		}
	}
	if (familia >= 0 && !manga && cuello == 3 && y > 1.485) camiseta = trim_col;
	if (!manga && abs(abs(x) - 0.205) < 0.006 && y < 1.40) camiseta *= 0.8;
	if (manga && abs(abs(x) - 0.222) < 0.005) camiseta *= 0.82;
	if (!manga && y > 1.005 && y < 1.02) camiseta *= 0.85;
	if (familia >= 0 && frente && !manga && !civil) {
		// Escudo: un escudete con borde del color de ribete.
		vec2 e = vec2((x - 0.095) / 0.042, (y - 1.405) / 0.05);
		// Escudete: arriba recto, abajo en punta redondeada.
		float ancho_e = e.y > 0.0 ? 1.0 : sqrt(max(0.0, 1.0 - e.y * e.y));
		float cuerpo_e = (1.0 - smoothstep(ancho_e - 0.08, ancho_e, abs(e.x))) * step(-1.0, e.y) * (1.0 - smoothstep(0.92, 1.0, e.y));
		float borde_e = cuerpo_e * smoothstep(ancho_e - 0.3, ancho_e - 0.2, abs(e.x) + max(0.0, e.y - 0.7) * 0.8);
		camiseta = mix(camiseta, C(1), cuerpo_e);
		camiseta = mix(camiseta, trim_col, borde_e);
		// Marca: una curva tipo "ala" en el color de ribete.
		vec2 mk = vec2((x + 0.095) / 0.045, (y - 1.41) / 0.03);
		float ala = step(abs(mk.x), 1.0) * step(abs(mk.y - (mk.x * mk.x * 0.6 - 0.2)), 0.22 - mk.x * 0.08);
		camiseta = mix(camiseta, trim_col, ala);
	}
	// PATROCINADORES. Pecho: entre el escudo y la cintura. Espalda: debajo
	// del cuello, encima del número. Manga: el logo en la izquierda del jugador.
	if (familia >= 0 && !manga && !civil) {
		if (hay_sp_pecho && frente && abs(x) < 0.13 && y > 1.2 && y < 1.37) {
			vec4 sp = sp_encajado(sp_pecho, vec2((x + 0.13) / 0.26, 1.0 - (y - 1.2) / 0.17), 0.26 / 0.17, sp_asp_pecho);
			camiseta = mix(camiseta, sp.rgb, sp.a * 0.96);
		}
		if (hay_sp_espalda && z < 0.45 && abs(x) < 0.12 && y > 1.415 && y < 1.48) {
			vec4 sp = sp_encajado(sp_espalda, vec2((-x + 0.12) / 0.24, 1.0 - (y - 1.415) / 0.065), 0.24 / 0.065, sp_asp_espalda);
			camiseta = mix(camiseta, sp.rgb, sp.a * 0.96);
		}
	}
	if (familia >= 0 && manga && hay_sp_manga && x > 0.25 && x < 0.33 && y > 1.36 && z > 0.45) {
		vec4 sp = texture(sp_manga, vec2((x - 0.25) / 0.08, 1.0 - clamp((y - 1.36) / 0.08, 0.0, 1.0)));
		camiseta = mix(camiseta, sp.rgb, sp.a * 0.96);
	}
	// El dorsal, en la espalda (z < 0,5), entre los omóplatos y la cintura.
	if (dorsal > 0 && !civil && !manga && z < 0.45 && y > 1.11 && y < 1.41 && abs(x) < 0.13) {
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
	// El logo del patrocinador del pantalón, en la pernera izquierda, delante.
	if (hay_sp_short && z > 0.5 && x > 0.06 && x < 0.12 && y > 0.82 && y < 0.88) {
		vec4 sp = texture(sp_short, vec2((x - 0.06) / 0.06, 1.0 - (y - 0.82) / 0.06));
		pant = mix(pant, sp.rgb, sp.a * 0.96);
	}
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

	if (hay_cara && usa_reposo) {
		float sx = 32.0 + x / 0.00563;
		float sy = 33.0 + (1.6986 - y) / 0.00666;
		// Solo la cara de frente: se apaga hacia los costados de la cabeza y
		// por debajo del mentón.
		float peso = smoothstep(0.555, 0.60, z) * smoothstep(1.552, 1.572, y) * (1.0 - tela);
		if (peso > 0.0 && sx > 0.0 && sx < 64.0 && sy > 0.0 && sy < 64.0) {
			if (hay_foto) {
				// Foto de tres cuartos: la mitad lejana sale aplastada y en
				// sombra; se usa la mitad que mira a la cámara, en espejo.
				float fx = (foto_espejo != 0 && sign(sx - 32.0) != float(foto_espejo)) ? 64.0 - sx : sx;
				vec3 q = vec3(fx, sy, 1.0);
				vec2 fuv = vec2(dot(foto_u, q), dot(foto_v, q));
				// Óvalo de la frente (cejas incluidas) al mentón.
				vec2 ov = vec2((sx - 32.0) / 10.5, (sy - 37.5) / 15.0);
				float mas = 1.0 - smoothstep(0.55, 1.0, length(ov));
				if (fuv.x > 0.0 && fuv.x < 1.0 && fuv.y > 0.0 && fuv.y < 1.0) {
					// La foto, llevada al tono de la piel del modelo (que ya se
					// tiñó con el de la foto): no queda una máscara pegada.
					albedo = mix(albedo, texture(foto_tex, fuv).rgb * foto_tono, mas * peso);
				}
			} else {
				vec2 st = vec2(sx, sy) / 64.0;
				// Capa de rasgos: multiplica la piel (vale para cualquier tono).
				vec4 r = texture(cara_tex, st);
				albedo = mix(albedo, albedo * r.rgb, r.a * peso);
				if (barba_fuerza > 0.0) {
					// Pelo corto: ruido fino (cada pelo) sobre ruido medio (la
					// densidad), más ralo hacia el borde de la barba.
					float bb = texture(barba_tex, st).a;
					float n = ruido(vec2(sx, sy) * 9.0) * 0.55 + ruido(vec2(sx * 3.1, sy * 2.3)) * 0.45;
					float a = bb * smoothstep(0.3, 0.7, n + (bb - 0.5) * 0.6) * barba_fuerza;
					albedo = mix(albedo, barba_color.rgb * (0.75 + 0.5 * n), a * peso);
				}
			}
		}
	}

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

	// LA TELA: punto fino de poliéster (una malla de puntitos que se ve de
	// cerca y hace brillar la camiseta como las de verdad), algo más mate en
	// las medias y brillante en los botines.
	float punto = sin(UV.x * 2600.0) * sin(UV.y * 2600.0);
	float es_camiseta = m.r * (1.0 - m.g);
	ALBEDO *= 1.0 + punto * 0.035 * tela;
	float rugo = mix(0.62, 0.5, es_camiseta);
	rugo = mix(rugo, 0.55, m.g);
	rugo = mix(rugo, 0.88, m.b);
	rugo = mix(rugo, 0.28, m.a);
	ROUGHNESS = rugo + punto * 0.05 * tela;
	SPECULAR = mix(0.45, 0.55, clamp(es_camiseta + m.g + m.a, 0.0, 1.0));
	vec3 nm = usa_normal ? texture(normal_tex, UV).rgb : vec3(0.5, 0.5, 1.0);
	// Micro relieve del tejido sobre el relieve del cuerpo.
	nm.xy += vec2(cos(UV.x * 2600.0), cos(UV.y * 2600.0)) * 0.045 * tela;
	NORMAL_MAP = nm;
	// Ropa de calle: casi nada del relieve muscular de la piel atraviesa la tela.
	NORMAL_MAP_DEPTH = usa_normal ? mix(1.0, usa_reposo ? (civil ? 0.06 : 0.22) : 0.45, tela) : 0.6 * tela;
	RIM = borde;
	RIM_TINT = 0.35;
}
