shader_type canvas_item;
// EL FONDO DE LA INTRO DE MARCA (`ui/entrada/intro.gd`). Negro verdoso con un halo esmeralda
// que nace detrás del escudo, unos rayos dorados muy lentos y el destello del final. Todo
// en un solo pase y sin texturas: cuesta lo mismo en un móvil que en un PC.
// El grano final no es un adorno: sin él, un degradado tan oscuro se ve a escalones en
// pantallas de 8 bits por canal.

uniform float tiempo = 0.0;
// 0 = negro absoluto; 1 = el halo entero.
uniform float aparicion : hint_range(0.0, 1.0) = 0.0;
// Intensidad de los rayos (suben al formarse la marca y se disparan con el destello).
uniform float rayos : hint_range(0.0, 2.0) = 0.0;
// El golpe de luz cuando se completa la palabra.
uniform float destello : hint_range(0.0, 2.0) = 0.0;
// Centros en UV (0..1) del rectángulo: el halo y los rayos, en el escudo; el destello, en la palabra.
uniform vec2 centro_rayos = vec2(0.5, 0.38);
uniform vec2 centro_destello = vec2(0.5, 0.6);
// ancho / alto, para que los círculos sean círculos en cualquier pantalla.
uniform float aspecto = 1.7778;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 a = vec2(aspecto, 1.0);
	vec2 dr = (UV - centro_rayos) * a;
	vec2 dd = (UV - centro_destello) * a;
	float r = length(dr);
	float rd = length(dd);

	vec3 negro = vec3(0.010, 0.018, 0.013);
	vec3 esmeralda = vec3(0.040, 0.120, 0.078);
	vec3 col = mix(negro, esmeralda, exp(-r * r * 2.6) * aparicion);

	// Rayos: dos abanicos que giran en sentidos contrarios, muy despacio. Las potencias
	// los afinan para que sean haces y no franjas.
	float ang = atan(dr.y, dr.x);
	float h1 = pow(sin(ang * 7.0 + tiempo * 0.30) * 0.5 + 0.5, 7.0);
	float h2 = pow(sin(ang * 19.0 - tiempo * 0.18 + 1.7) * 0.5 + 0.5, 12.0);
	float caida = exp(-r * 1.7) * smoothstep(0.03, 0.30, r);
	col += vec3(0.80, 0.58, 0.20) * (h1 * 0.7 + h2 * 0.3) * caida * rayos * 0.20;

	// El destello: un velo cálido ancho y un núcleo casi blanco.
	col += vec3(1.00, 0.80, 0.45) * exp(-rd * rd * 7.0) * destello * 0.45;
	col += vec3(1.00, 0.95, 0.82) * exp(-rd * rd * 55.0) * destello * 0.55;

	// Viñeta: las esquinas se hunden y el ojo va al centro.
	float v = length((UV - 0.5) * vec2(aspecto * 0.62, 1.0));
	col *= mix(0.45, 1.0, smoothstep(1.05, 0.20, v));

	col += (azar(UV * 997.0 + fract(tiempo * 3.7) * 53.0) - 0.5) * 0.010;
	COLOR = vec4(max(col, vec3(0.0)), 1.0);
}
