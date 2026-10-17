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

varying vec3 tejado;
varying float alto;

void vertex() {
	tejado = INSTANCE_CUSTOM.rgb;
	alto = VERTEX.y;
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
	ALBEDO = c;
	ROUGHNESS = 0.85;
	SPECULAR = 0.25;
}
