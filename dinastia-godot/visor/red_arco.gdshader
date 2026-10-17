shader_type spatial;
// LA RED QUE SE ONDULA AL GOL (17-10-2026, M-149). La misma red de siempre
// (textura de cordel con huecos, sin culling) pero con la malla subdividida y
// un desplazamiento de vértice: una onda que sale del punto donde entró el
// balón, se abomba hacia fuera y se apaga en un par de segundos. Sin física:
// solo dos uniforms que pone `RedArco` durante la onda (`edad` sube de 0 a
// ~2,4 s; fuera de ese rato `fuerza` = 0 y la red queda rígida como antes).
render_mode cull_disabled, depth_prepass_alpha;

uniform sampler2D textura : source_color, filter_linear_mipmap;
uniform vec2 escala_uv = vec2(32.0, 14.0);
uniform vec2 impacto = vec2(0.0, 0.0);    // en el plano del paño (metros, local)
uniform float edad = 0.0;
uniform float fuerza = 0.0;               // metros de abombado máximo (signo = hacia fuera)
uniform vec2 medio_tam = vec2(3.66, 1.3); // la mitad del paño, para atar los bordes

void vertex() {
	vec2 p = VERTEX.xy;
	float d = distance(p, impacto);
	// La onda: bulto principal donde pegó + anillos que se alejan.
	float bulto = exp(-d * d / 0.9) * exp(-edad * 2.2);
	float anillo = sin(d * 4.5 - edad * 11.0) * exp(-d * 0.55) * exp(-edad * 1.8) * 0.35;
	// Atada al marco: nada en los bordes del paño.
	vec2 borde = clamp((medio_tam - abs(p)) / 0.45, 0.0, 1.0);
	float atado = borde.x * borde.y;
	VERTEX.z += fuerza * (bulto + anillo * smoothstep(0.0, 0.15, edad)) * atado;
}

void fragment() {
	vec4 c = texture(textura, UV * escala_uv);
	ALBEDO = c.rgb;
	ALPHA = c.a;
	ROUGHNESS = 0.95;
}
