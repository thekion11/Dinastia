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

const vec3 TOLDOS[5] = vec3[](vec3(0.45, 0.03, 0.025), vec3(0.02, 0.12, 0.05), vec3(0.02, 0.04, 0.17),
	vec3(0.68, 0.32, 0.02), vec3(0.08, 0.08, 0.09));

void vertex() {
	extra = INSTANCE_CUSTOM;
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
