shader_type spatial;
// PELO POR CAPAS (30-9-2026): cuero cabelludo, barba y cejas de los jugadores
// reales. La malla trae N copias de la superficie; cada copia (`CUSTOM0.x`,
// de 0 a 1) se separa un poco más de la piel. En cada capa solo quedan los
// puntos de las hebras que llegan a esa altura: juntas forman pelos con
// volumen de verdad, que la luz ilumina desde el costado y dejan ver la piel
// entre medio (el rapado, la barba de días) -la técnica de pelo corto de los
// juegos de deporte-. `COLOR.r` = densidad en ese punto (nacimiento del pelo,
// barba rala), UV2 = coordenadas de las hebras en centímetros.
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D foto : filter_linear_mipmap, repeat_disable;
// Barba y cejas toman el color de la FOTO en ese punto (exacto, con sus
// canas y su mancha); el cuero cabelludo, el color medido del pelo.
uniform bool usa_foto = false;
uniform vec3 color_punta = vec3(0.05, 0.035, 0.025);
uniform vec3 color_raiz = vec3(0.02, 0.015, 0.012);
uniform float oscurecer_foto = 0.8;
uniform vec3 balance = vec3(1.0);
// Largo del pelo (m) y cuánto cae hacia abajo al crecer.
uniform float grosor = 0.01;
uniform float caida = 0.25;
// Hebras por centímetro y su grueso (fracción de la celda).
uniform float hebras_cm = 3.0;
uniform float radio = 0.32;
// Estirar las celdas en x (cejas: pelos tumbados hacia la sien).
uniform float estirar = 1.0;
// 0 liso, 1 muy rizado (las hebras se enroscan al subir).
uniform float rizo = 0.0;
// La capa 0 tapa la piel (el cuero cabelludo bajo el pelo) si se pide.
uniform bool base_opaca = false;
// Núcleo macizo (fracción del largo): la masa del pelo es tupida y solo la
// parte de fuera se abre en hebras; sin núcleo, de perfil parecía un erizo.
uniform float nucleo = 0.0;
// Cuánto se oscurece la hebra cerca de la piel (1 = nada).
uniform float sombra_raiz = 0.72;

varying float v_capa;
varying float v_dens;

float h11(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 h22(vec2 p) { return vec2(h11(p), h11(p + 19.19)); }
vec3 a_lineal(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
	v_capa = CUSTOM0.x;
	v_dens = COLOR.r;
	vec3 dir = normalize(NORMAL + vec3(0.0, -caida, 0.0) * v_capa);
	// COLOR.g = cuánto crece aquí (lados rapados más cortos); y todo un pelín
	// por fuera de la piel para no pelearse con ella.
	VERTEX += dir * grosor * v_capa * COLOR.g + NORMAL * 0.0012;
}

void fragment() {
	vec2 p = UV2 * hebras_cm * vec2(1.0 / estirar, 1.0);
	// El rizo enrosca la hebra al subir de capa.
	p += rizo * 0.35 * vec2(sin(v_capa * 9.0 + p.y), cos(v_capa * 9.0 + p.x));
	vec2 cel = floor(p);
	vec2 f = fract(p) - 0.5 - (h22(cel) - 0.5) * 0.5;
	float largo = mix(0.35, 1.0, h11(cel + 7.1));
	float r = radio * (1.0 - v_capa * 0.65);
	float hebra = step(length(f), r) * step(v_capa, largo * v_dens + 0.001);
	// Menos hebras donde la densidad es baja (el nacimiento, la barba rala).
	hebra *= step(h11(cel + 3.7), v_dens * 1.15);
	if (v_capa > 0.001 && v_capa < nucleo * v_dens) {
		hebra = 1.0;
	}
	if (v_capa < 0.001) {
		// La base tapa la piel solo donde el pelo es tupido; en el
		// nacimiento, hebras sueltas (sin un borde recortado).
		hebra = base_opaca ? step(0.6 + 0.35 * h11(cel + 5.5), v_dens) : 0.0;
	}
	ALPHA = hebra;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	vec3 c;
	if (usa_foto) {
		c = a_lineal(texture(foto, UV).rgb) * balance * oscurecer_foto;
	} else {
		c = mix(color_raiz, color_punta, clamp(v_capa * 1.3, 0.0, 1.0));
	}
	// Cada hebra algo distinta, y más oscura cerca de la piel (sombra).
	c *= (0.85 + 0.3 * h11(cel + 11.3)) * mix(sombra_raiz, 1.0, v_capa);
	ALBEDO = c;
	ROUGHNESS = 0.55;
	SPECULAR = 0.35;
}
