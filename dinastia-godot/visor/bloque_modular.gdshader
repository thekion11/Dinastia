shader_type spatial;
// BLOQUES DE PISOS con el kit Modular Buildings de Kenney (16-10-2026). El kit
// usa una sola textura de paleta: pared crema, remates salmón (zócalo, cornisas,
// marcos), toldos verde menta y cristal azul cielo. Por instancia (MultiMesh):
//   COLOR                 = color de la pared (en lineal),
//   INSTANCE_CUSTOM.rgb   = color de los remates (en lineal),
//   INSTANCE_CUSTOM.a     = qué toldo (0, 0,25 … 1 → TOLDOS[0..4]).
// La paleta se lee SIN `source_color` (valores sRGB tal cual, comparables con
// los de la imagen) y se pasa a lineal a mano: así la clasificación por color
// no depende de la conversión (el problema que se vio con las casas el 15-10).

uniform sampler2D paleta : filter_nearest;

varying vec4 extra;
varying vec3 mundo;

// DESGASTE de la fachada (S5, 27-10-2026): ruido de valor barato en espacio de mundo.
float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1.0, 0.0)), f.x), mix(h2(i + vec2(0.0, 1.0)), h2(i + vec2(1.0, 1.0)), f.x), f.y);
}

const vec3 TOLDOS[5] = vec3[](vec3(0.45, 0.03, 0.025), vec3(0.02, 0.12, 0.05), vec3(0.02, 0.04, 0.17),
	vec3(0.68, 0.32, 0.02), vec3(0.08, 0.08, 0.09));

void vertex() {
	extra = INSTANCE_CUSTOM;
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 s = texture(paleta, UV).rgb;          // sRGB
	vec3 c = pow(s, vec3(2.2));                // lineal
	float rug = 0.85;
	float esp = 0.25;
	float met = 0.0;
	float lum = dot(s, vec3(0.3, 0.59, 0.11));
	bool menta = s.g > s.r * 1.6 && s.g > s.b * 1.2;
	bool cristal = s.b > s.r * 1.5 && s.b > s.g * 1.25;
	if (menta) {
		int k = clamp(int(round(extra.a * 4.0)), 0, 4);
		c = TOLDOS[k] * (lum / 0.6);
	} else if (cristal) {
		// Cristal oscuro con reflejo, no azul cielo.
		c = vec3(0.035, 0.05, 0.065) + pow(s, vec3(2.2)) * 0.04;
		rug = 0.12;
		esp = 0.7;
		met = 0.2;
	} else if (s.r > 0.8 && s.r >= s.g - 0.02 && s.g >= s.b - 0.02) {
		if (s.b > s.r * 0.55) {
			// Pared: el kit la pinta con un degradado de blanco a crema y
			// melocotón; se tiñe toda con el color del bloque y se conserva solo
			// la mitad del degradado (si no, cada piso salía a franjas).
			c = COLOR.rgb * mix(1.0, lum / 0.908, 0.5);
			// Desgaste: suciedad de acera en la base, churretes de lluvia y moteado de pintura vieja.
			float costado = mundo.x + mundo.z;
			float base = (1.0 - smoothstep(0.2, 3.2, mundo.y)) * (0.55 + 0.45 * ruido(vec2(costado * 0.8, mundo.y * 2.0)));
			float churrete = smoothstep(0.62, 0.95, ruido(vec2(costado * 2.3, mundo.y * 0.07))) * smoothstep(1.5, 12.0, mundo.y);
			float mota = ruido(vec2(costado * 0.9 + mundo.y * 0.3, mundo.y * 0.9)) - 0.5;
			c *= 1.0 - 0.36 * base - 0.16 * churrete + 0.10 * mota;
			c = mix(c, c * vec3(0.9, 0.86, 0.8), 0.35 * base);
		} else {
			// Remates: cornisas, zócalo, marcos (salmón y melocotón).
			c = extra.rgb * mix(1.0, lum / 0.79, 0.6);
		}
	}
	ALBEDO = c;
	ROUGHNESS = rug;
	SPECULAR = esp;
	METALLIC = met;
}
