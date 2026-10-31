shader_type spatial;
// CASAS DEL BARRIO con el City Kit Suburban de Kenney (15-10-2026). El kit usa una
// sola textura de paleta y el verde menta sale en el tejado Y en los arbustos;
// la pared es blanca. Por instancia (MultiMesh):
//   COLOR            = color de la fachada (tiñe solo el blanco de la pared),
//   INSTANCE_CUSTOM  = color del tejado (sustituye al menta de arriba).
// Los arbustos (el menta de abajo) pasan a un verde de seto natural.

uniform sampler2D paleta : source_color, filter_nearest;
// Altura (en el espacio del modelo) a partir de la cual el menta es tejado.
uniform float altura_tejado = 0.3;
// (§2.5, 31-10) De noche se encienden unas ventanas (el azul del kit) y, con apagón, las del sector cortado
// se quedan a oscuras: el mismo mapa 5x5 de `fachada_torre.gdshader` (rojo = el sector tiene corriente).
uniform float noche : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D luz_sectores : filter_nearest, repeat_disable;
uniform bool usa_sectores = false;

varying vec3 tejado;
varying float alto;
varying vec3 wpos;

void vertex() {
	tejado = INSTANCE_CUSTOM.rgb;
	alto = VERTEX.y;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 c = texture(paleta, UV).rgb;
	// El menta (97, 203, 139) se reconoce por el TONO: es el único color de la
	// paleta con el verde muy por encima del rojo y del azul. Comparar el valor
	// exacto no servía (medido el 15-10-2026: llega con ±10 % de variación y sin
	// la conversión a lineal que se esperaba).
	bool es_menta = c.g > c.r * 1.6 && c.g > c.b * 1.2 && c.g > 0.25;
	if (es_menta) {
		c = alto > altura_tejado ? tejado : vec3(0.10, 0.20, 0.07);
	} else if (min(c.r, min(c.g, c.b)) > 0.5 && max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b)) < 0.3) {
		// La pared del kit es blanca o blanco azulado (208, 232, 255): se pasa a
		// gris y se tiñe con el color de la fachada, para que no salga azulada.
		c = vec3(dot(c, vec3(0.3, 0.59, 0.11))) * COLOR.rgb;
	}
	// Las ventanas: el azul cristal de la paleta (103, 148, 217).
	bool ventana = !es_menta && c.b > 0.6 && c.b > c.r * 1.6 && c.b > c.g * 1.25;
	// Unas sí y otras no: azar por ventana (cada 3 m del mundo; en un MultiMesh no hay id de casa fiable).
	float h = fract(sin(dot(floor(wpos.xz / 3.0), vec2(12.9898, 78.233))) * 43758.5453);
	float enc = (ventana && h > 0.35) ? noche : 0.0;
	if (usa_sectores) {
		ivec2 s = ivec2(round(wpos.xz / 110.0)) + ivec2(12);
		enc *= texelFetch(luz_sectores, clamp(s / 6, ivec2(0), ivec2(4)), 0).r;
	}
	ALBEDO = c;
	ROUGHNESS = 0.85;
	SPECULAR = 0.25;
	EMISSION = vec3(1.0, 0.8, 0.45) * enc * 1.4;
}
