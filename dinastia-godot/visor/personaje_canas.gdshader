shader_type spatial;
// CANAS Y ENTRADAS POR EDAD (26-10-2026, opción A): el mismo pelo del pack (textura de
// mechones recortados por alfa y su color) con hebras grises mezcladas, más en las sienes,
// y, en un hombre mayor, las entradas: el pelo de la frente se recorta en «M» por encima de
// la línea de nacimiento y deja ver la cabeza. `a_modelo` lleva la malla al espacio del
// modelo en reposo (metros, y arriba, z delante).
render_mode cull_disabled;

uniform sampler2D textura : source_color, filter_linear_mipmap;
uniform vec4 color : source_color = vec4(1.0);
uniform mat4 a_modelo;
uniform float ojos_y = 1.699;
uniform float canas = 0.0;     // 0..1
uniform float entradas = 0.0;  // 0..1

varying vec3 pm;

float ruido(vec3 p) {
	return fract(sin(dot(floor(p), vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

void vertex() {
	pm = (a_modelo * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 t = texture(textura, UV);
	vec3 c = t.rgb * color.rgb;
	float x = abs(pm.x);
	float y = pm.y - ojos_y;
	// Las sienes y la nuca encanecen antes que la coronilla.
	float sien = smoothstep(0.045, 0.075, x) * (1.0 - smoothstep(0.06, 0.11, y));
	float local = clamp(canas * (0.75 + 0.6 * sien), 0.0, 1.0);
	// Hebras: ruido fino a lo largo del mechón (más estirado en vertical).
	// Las canas siguen los mechones de la propia textura: encanecen primero las hebras
	// claras y, con más edad, también las oscuras; una pizca de ruido fino rompe el patrón.
	float l = dot(t.rgb, vec3(0.3, 0.59, 0.11));
	float h = clamp(l * 1.15 + (ruido(pm * vec3(700.0, 180.0, 700.0)) - 0.5) * 0.25, 0.0, 1.0);
	float gris = smoothstep(1.0 - local - 0.12, 1.0 - local + 0.12, h);
	vec3 cana = vec3(0.76, 0.75, 0.73) * (0.65 + 0.45 * l);
	c = mix(c, cana, clamp(gris * 0.7 + local * 0.18, 0.0, 1.0));
	float alfa = t.a;
	// Entradas: por delante, la línea del pelo sube hacia las sienes.
	if (entradas > 0.0 && pm.z > 0.045) {
		// Solo las esquinas de la frente (no el centro): una «M» que crece con la edad.
		float m = smoothstep(0.022, 0.05, x) * (1.0 - smoothstep(0.07, 0.085, x));
		float linea_pelo = 0.04 + entradas * 0.04 * m;
		if (y < linea_pelo && y > 0.04) {
			alfa = 0.0;
		}
	}
	ALBEDO = c;
	ALPHA = alfa;
	ALPHA_SCISSOR_THRESHOLD = 0.4;
	ROUGHNESS = 0.75;
}
