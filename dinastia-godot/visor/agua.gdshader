shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

// AGUA DEL RÍO. Hasta ahora el río era un `PlaneMesh` con un azul liso y
// `metallic` alto: de lejos pasaba, pero no se movía y no reflejaba la hora
// del día, así que al caer la noche seguía siendo la misma mancha azul.
//
// QUÉ HACE ESTE SHADER, y por qué cada parte:
//  1. OLEAJE: desplaza los vértices con dos senos cruzados de distinta
//     frecuencia. Dos y no uno, porque una sola onda se lee como una chapa
//     ondulada perfecta; dos que no son múltiplos entre sí nunca repiten el
//     mismo patrón a la vista.
//  2. NORMALES CALCULADAS DEL PROPIO OLEAJE: si solo se mueve el vértice pero
//     la normal sigue apuntando hacia arriba, la luz no cambia y el agua se ve
//     como un plástico ondulado. La derivada analítica del seno sale gratis.
//  3. FRESNEL: el agua vista de frente es casi transparente y vista de canto
//     es un espejo. Sin esto el río tiene el mismo color desde cualquier
//     ángulo, que es lo que más delata a un plano azul.
//  4. ESPUMA en las crestas, con `smoothstep` sobre la altura de la ola.
//
// El color no está fijado en el shader: lo pasa la escena (`color_hondo` y
// `color_orilla`), para que el ciclo del sol pueda oscurecer el río de noche.

uniform vec3 color_hondo : source_color = vec3(0.06, 0.16, 0.24);
uniform vec3 color_orilla : source_color = vec3(0.18, 0.38, 0.44);
uniform vec3 color_espuma : source_color = vec3(0.85, 0.92, 0.95);
uniform float velocidad = 0.45;
uniform float altura_ola = 0.55;
uniform float escala_ola = 0.055;
uniform float brillo = 1.0;

varying float v_ola;

float onda(vec2 p, float t) {
	float a = sin(p.x * escala_ola + t * 1.7);
	float b = sin(p.y * escala_ola * 0.63 + t * 1.1 + 1.7);
	return a * 0.6 + b * 0.4;
}

void vertex() {
	float t = TIME * velocidad;
	vec2 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	float h = onda(p, t);
	VERTEX.y += h * altura_ola;
	v_ola = h;

	// Normal a partir de la pendiente de la propia ola: se deriva el seno en
	// las dos direcciones. Sin esto la superficie recibe la luz como si fuese
	// plana por mucho que los vértices suban y bajen.
	float dx = cos(p.x * escala_ola + t * 1.7) * escala_ola * 0.6;
	float dz = cos(p.y * escala_ola * 0.63 + t * 1.1 + 1.7) * escala_ola * 0.63 * 0.4;
	NORMAL = normalize(vec3(-dx * altura_ola, 1.0, -dz * altura_ola));
}

void fragment() {
	// Fresnel: 0 mirando de frente, 1 a ras de superficie.
	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.5);
	vec3 col = mix(color_hondo, color_orilla, fres);

	// Espuma solo en lo alto de la cresta.
	float espuma = smoothstep(0.62, 0.95, v_ola);
	col = mix(col, color_espuma, espuma * 0.55);

	ALBEDO = col * brillo;
	// Muy liso y bastante metálico: es lo que hace que el cielo se vea dentro
	// del agua. Con rugosidad alta el río queda como cemento azul.
	ROUGHNESS = mix(0.02, 0.18, espuma);
	METALLIC = 0.55;
	SPECULAR = 0.9;
}
