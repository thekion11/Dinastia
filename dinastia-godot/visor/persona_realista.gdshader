shader_type spatial;
// LA PERSONA REALISTA, PERSONALIZABLE (25-9-2026).
//
// El modelo es un escaneo fotogramétrico (`assets/personas/persona_realista.glb`):
// una sola textura con retazos de piel, pelo y ropa mezclados. No hay máscaras
// por prenda, así que cada zona se reconoce por dos pistas a la vez:
//   * el COLOR del píxel -la piel es el único tono anaranjado con saturación-,
//   * la ALTURA del punto en el cuerpo -el pelo está arriba de la frente, el
//     pantalón entre la cintura y los tobillos, los zapatos abajo del todo-.
// Cada zona se retiñe conservando la luz del escaneo (arrugas, pliegues,
// sombras), que es lo que hace que siga pareciendo una persona y no un muñeco.

render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform sampler2D orm_tex : hint_default_white, filter_linear_mipmap;
uniform vec2 uv_escala = vec2(1.0);
uniform vec2 uv_desplaza = vec2(0.0);
// De la malla cuantizada a metros del modelo (-0.95 pies .. 0.95 coronilla).
uniform float escala_malla = 1.0;
uniform vec3 origen_malla = vec3(0.0);

uniform bool personalizar = false;
uniform vec3 color_arriba : source_color = vec3(0.13, 0.16, 0.24);
uniform vec3 color_abajo : source_color = vec3(0.10, 0.17, 0.30);
uniform vec3 color_pelo : source_color = vec3(0.07, 0.06, 0.05);
uniform vec3 color_zapatos : source_color = vec3(0.05, 0.05, 0.06);
// Multiplicador del tono de piel (1,1,1 = el del escaneo).
uniform vec3 tinte_piel = vec3(1.0);
uniform float brillo = 0.06;

const float Y_PELO = 0.80;
const float Y_CINTURA = 0.05;
// La cara, del cuello a la frente: se respeta tal cual (ojos, cejas, labios,
// barba), solo se le cambia el tono de piel.
const float Y_CUELLO = 0.66;
const float Y_ZAPATO = -0.84;

varying vec3 pos_m;

void vertex() {
	pos_m = VERTEX * escala_malla + origen_malla;
}

vec3 hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

vec3 retenir(vec3 original, vec3 destino, float ref) {
	// La luz del escaneo sobre el color nuevo: ref es la luminancia media que
	// tenía esa prenda, así el tono medio sale igual al elegido.
	// Con un 25% de color plano: sin eso, en tonos claros (camel, blanco) los
	// brillos del escaneo se quemaban.
	return clamp(destino * mix(1.0, lum(original) / ref, 0.75), 0.0, 1.0);
}

void fragment() {
	vec2 uv = UV * uv_escala + uv_desplaza;
	vec3 base = texture(albedo_tex, uv).rgb;
	vec3 c = base;
	if (personalizar) {
		vec3 h = hsv(base);
		// Piel: tono entre rojo y amarillo, con color y con luz.
		float piel = smoothstep(0.0, 0.03, h.x) * (1.0 - smoothstep(0.10, 0.14, h.x))
			* smoothstep(0.18, 0.30, h.y) * smoothstep(0.20, 0.35, h.z);
		float no_piel = 1.0 - piel;
		float pelo = step(Y_PELO, pos_m.y) * no_piel;
		float zapatos = (1.0 - step(Y_ZAPATO, pos_m.y)) * no_piel;
		// Las mangas bajan por debajo de la cintura: lo que está lejos del
		// eje del cuerpo (los brazos) sigue siendo chaqueta hasta la muñeca.
		float brazo = step(0.16, abs(pos_m.x)) * step(-0.10, pos_m.y);
		// Y el cuello de la chaqueta sube por los lados y por detrás de la
		// nuca: fuera del cilindro del cuello, también es chaqueta.
		// Solo por los lados y por detrás: por delante, a esa altura, están los
		// labios y la barbilla.
		float cuello_chaqueta = step(Y_CUELLO, pos_m.y) * (1.0 - step(0.78, pos_m.y))
			* clamp(step(0.085, length(pos_m.xz)) * (1.0 - step(0.02, pos_m.z))
				+ step(0.075, abs(pos_m.x)), 0.0, 1.0);
		float en_tronco = step(Y_CINTURA, pos_m.y) * (1.0 - step(Y_CUELLO, pos_m.y));
		float arriba = clamp(en_tronco + brazo * (1.0 - step(Y_CUELLO, pos_m.y)) + cuello_chaqueta, 0.0, 1.0) * no_piel;
		float abajo = step(Y_ZAPATO, pos_m.y) * (1.0 - step(Y_CINTURA, pos_m.y)) * (1.0 - brazo) * no_piel;
		c = mix(c, retenir(base, color_arriba, 0.085), arriba);
		c = mix(c, retenir(base, color_abajo, 0.11), abajo);
		// El pelo del escaneo es casi negro: se retiñe con menos ganancia para
	// que un rubio o un canoso no salgan blancos quemados.
	c = mix(c, clamp(color_pelo * (0.55 + 0.9 * lum(base) / 0.08), 0.0, 1.0) * 0.8, pelo);
		c = mix(c, retenir(base, color_zapatos, 0.06), zapatos);
		c = mix(c, clamp(base * tinte_piel, 0.0, 1.0), piel);
	}
	ALBEDO = c;
	vec3 orm = texture(orm_tex, uv).rgb;
	ROUGHNESS = clamp(orm.g, 0.35, 1.0);
	METALLIC = 0.0;
	NORMAL_MAP = texture(normal_tex, uv).rgb;
	NORMAL_MAP_DEPTH = 0.8;
	// Un poco de luz propia: el escaneo ya trae horneada la iluminación suave
	// del estudio donde se capturó, y sin esto las sombras quedan dobles.
	EMISSION = c * brillo;
}
