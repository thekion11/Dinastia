shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

// EL HAZ DE LOS FOCOS DEL ESTADIO (M-014, 26-10-2026, «sin haces de los focos»).
// Antes había un cono por torre con alfa 0: no se veía nada. Ahora, como el haz
// de las farolas de la ciudad (`cono_farola.gdshader`), una luz falsa: brilla junto
// al bastidor y se apaga hacia el césped, sin contorno (se desvanece donde el cono
// se ve de canto) y se apaga entero si la cámara está dentro o rozándolo.
// La malla es un cilindro de 1 m de alto centrado en 0 (abajo el césped, arriba
// el foco) con radio RADIO_PIE abajo y RADIO_CIMA arriba; el nodo lo escala.
instance uniform vec3 color : source_color = vec3(1.0, 0.95, 0.85);   // la luz de los focos del club
instance uniform float aire = 1.0;   // niebla, lluvia o nieve: el aire enseña más el haz (`_haces`)
uniform float fuerza = 0.0;   // la pone `StadiumBuilder.encender_conos` (0 de día)
const float RADIO_PIE = 0.5;
const float RADIO_CIMA = 0.09;

varying float v_h;
varying float v_fuera;

void vertex() {
	v_h = clamp(VERTEX.y + 0.5, 0.0, 1.0);
	// Dónde está la cámara en el espacio del cono: dentro (o casi) -> apagado.
	vec3 cam = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	float radio = mix(RADIO_PIE, RADIO_CIMA, clamp(cam.y + 0.5, 0.0, 1.0));
	float q = length(cam.xz) / radio;
	float dentro_alto = step(-0.5, cam.y) * step(cam.y, 0.5);
	v_fuera = mix(1.0, smoothstep(1.1, 1.8, q), dentro_alto);
}

void fragment() {
	float frente = abs(dot(normalize(NORMAL), normalize(VIEW)));
	// El centro manda y los bordes se funden: sin silueta.
	float borde = pow(smoothstep(0.05, 1.0, frente), 2.5);
	// Fuerte junto al foco, casi nada al llegar al césped (no lava la cancha).
	float alto = mix(0.0, 1.0, v_h * v_h);
	// De muy cerca no es más que una niebla rara.
	float cerca = smoothstep(4.0, 25.0, length(VERTEX));
	ALBEDO = color;
	ALPHA = fuerza * aire * borde * alto * cerca * v_fuera;
}
