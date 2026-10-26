shader_type spatial;
render_mode cull_disabled;
// VENTANAS DEL KIT COMERCIAL DE NOCHE (26-10-2026, pciu). Los edificios bajos de
// Kenney (`kenney_comercial*`) quedaban casi negros a pie de calle: sus ventanas
// no se encendían nunca, y solo brillaban las torres (`fachada_torre.gdshader`).
// Es el mismo material de antes (paleta × tinte, mate) y, de noche, emite en el
// cristal. El cristal se reconoce por la UV: en la paleta del kit es la columna
// 11 de 16 de la banda azul (u 0,6875-0,75, v 0,25-0,5); se midió en los 20
// modelos que usa la ciudad y es el único azul de sus fachadas.
// Variación sin luces reales ni materiales de más:
//   - por EDIFICIO: el origen de la instancia (también dentro de un MultiMesh
//     de `Optimizar.agrupar`) decide qué parte de sus ventanas se enciende;
//   - por PLANTA y FACHADA: las plantas del kit miden 0,4 de alto en el espacio
//     del modelo; cada planta de cada cara se enciende o no por su cuenta (un
//     piso con gente, otro vacío), con brillo y tono propios (casi todas cálidas,
//     alguna blanca fría de pantalla);
//   - la planta baja (escaparates y portales) se enciende más a menudo.
uniform sampler2D paleta : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tinte : source_color = vec4(1.0);
uniform float noche : hint_range(0.0, 1.0) = 0.0;
uniform float energia = 0.85;

varying vec3 v_local;
varying vec3 v_nlocal;
varying vec3 v_origen;

void vertex() {
	v_local = VERTEX;
	v_nlocal = NORMAL;
	v_origen = MODEL_MATRIX[3].xyz;
}

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 t = texture(paleta, UV);
	ALBEDO = t.rgb * tinte.rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.5;
	float vidrio = step(0.6875, UV.x) * step(UV.x, 0.75) * step(0.25, UV.y) * step(UV.y, 0.5);
	if (vidrio > 0.0 && noche > 0.0) {
		vec2 nh = v_nlocal.xz;
		float cara = abs(nh.x) > abs(nh.y) ? (nh.x > 0.0 ? 1.0 : 3.0) : (nh.y > 0.0 ? 0.0 : 2.0);
		float planta = floor(v_local.y / 0.4);
		float edificio = azar(floor(v_origen.xz * 0.5) * 0.731);
		float h = azar(floor(v_origen.xz * 0.5) * 0.137 + vec2(planta * 3.17, cara * 7.71));
		// Entre un 30 % y un 75 % de plantas con luz según el edificio; la baja, más.
		float umbral = mix(0.25, 0.70, edificio) - (planta < 1.0 ? 0.25 : 0.0);
		float encendida = step(umbral, h);
		// Cada planta se enciende a su hora: la primera al anochecer, la última
		// con la noche cerrada (no todo el barrio de golpe).
		float hora = smoothstep(fract(h * 3.7) * 0.5, fract(h * 3.7) * 0.5 + 0.35, noche);
		vec3 tono = fract(h * 13.7) > 0.82 ? vec3(0.78, 0.86, 1.0) : vec3(1.0, 0.78, 0.46);
		float brillo = mix(0.55, 1.0, fract(h * 5.3));
		EMISSION = tono * encendida * hora * brillo * energia;
		// Cristal encendido: sin el reflejo oscuro de día.
		ALBEDO = mix(ALBEDO, ALBEDO * 0.4, encendida * hora);
	}
}
