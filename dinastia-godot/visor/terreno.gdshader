shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// EL TERRENO NATURAL, CON LADERAS DE VERDAD (12-9-2026). Antes era una sola
// textura de césped estirada sobre TODO el relieve -llano, loma o ladera de
// 78 m, daba igual-, así que una pendiente empinada se veía como césped
// vertical, que ninguna colina de verdad hace. Aquí se mezcla la MISMA
// textura de césped con roca/tierra procedural según lo inclinada que esté
// la cara -`NORMAL.y` cerca de 1 es plano, cerca de 0 es una pared-, y la
// roca lleva su propio moteado para no leerse como un color plano.

uniform sampler2D textura_cesped : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 escala_cesped = vec2(20.0, 20.0);
uniform vec4 roca_clara : source_color = vec4(0.52, 0.48, 0.42, 1.0);
uniform vec4 roca_oscura : source_color = vec4(0.30, 0.28, 0.25, 1.0);
uniform vec4 tierra_color : source_color = vec4(0.36, 0.30, 0.22, 1.0);
// Bajo esta pendiente (NORMAL.y) es roca pura; por encima, césped puro; entre
// medias, la franja de tierra suelta que deja cualquier corte de ladera real.
// EL RELIEVE DE ESTE MAPA ES SUAVE A PROPÓSITO -lomas de paseo, no montañas:
// la pendiente más fuerte medida en todo el terreno ronda los 12°, NORMAL.y
// ~0,978-. Con los umbrales pensados para una montaña de verdad (0,55/0,82)
// esas lomas nunca cruzan ni el primer umbral y se quedan cesped puro en
// TODO el mapa, sin que el shader se note nunca. Subidos cerca de 1,0, hasta
// la ladera más discreta saca ya su franja de tierra.
uniform float umbral_roca : hint_range(0.0, 1.0) = 0.965;
uniform float umbral_cesped : hint_range(0.0, 1.0) = 0.994;
uniform float roughness_cesped : hint_range(0.0, 1.0) = 0.94;
uniform float roughness_roca : hint_range(0.0, 1.0) = 0.86;

// SOMBRA DE NUBE, moviéndose sola sobre el suelo (12-9-2026, pendiente que
// había quedado anotado al hacer `cielo.gdshader`). No es la sombra exacta de
// una nube del cielo -serían dos proyecciones distintas, esfera de mirada
// contra plano del suelo, y sincronizarlas de verdad pediría pasar una
// textura entre los dos shaders-. Es más barato y se nota casi igual: el
// mismo tipo de ruido, a la deriva en la misma dirección, sobre el plano XZ
// del terreno. Sin esto un mediodía despejado deja el llano entero de un
// verde perfectamente parejo, que ninguna pradera real tiene.
uniform float nubes_sombra_cantidad : hint_range(0.0, 1.0) = 0.40;
uniform float nubes_sombra_escala = 0.0032;
uniform float nubes_sombra_velocidad = 0.006;

#include "res://visor/ruido.gdshaderinc"

// CORREGIDO (26-9-2026, "no hagas eso de difuminar o rayar zonas"): en
// `fragment()` VERTEX y NORMAL están en espacio de CÁMARA, no del mundo. La
// textura del césped y la mezcla de ladera se calculaban con ellos, así que
// "nadaban" y cambiaban de tono al mover la cámara (el llano lavado y rayado
// que se veía). Ahora se pasan del mundo desde `vertex()`.
varying vec3 p_mundo;
varying vec3 n_mundo;

void vertex() {
	p_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	n_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv_mundo = p_mundo.xz / escala_cesped;
	// Dos escalas de la misma textura y una variación grande de tono: de
	// cerca se ve la hoja, de lejos manchas de pradera, nunca un papel pintado.
	vec3 cesped = texture(textura_cesped, uv_mundo).rgb * 0.6 + texture(textura_cesped, uv_mundo * 0.23 + 0.37).rgb * 0.4;
	float macro = fbm3(vec3(p_mundo.xz * 0.012, 3.0));
	cesped *= mix(0.82, 1.12, macro);
	cesped = mix(cesped, cesped * vec3(1.08, 1.02, 0.8), smoothstep(0.55, 0.8, fbm3(vec3(p_mundo.xz * 0.004, 9.0))) * 0.6);

	float moteado = fbm3(p_mundo * 0.15);
	vec3 roca = mix(roca_oscura.rgb, roca_clara.rgb, moteado);

	float ladera = clamp(n_mundo.y, 0.0, 1.0);
	// Dos tramos: roca->tierra hasta `umbral_roca`, tierra->césped hasta
	// `umbral_cesped`. Con un solo smoothstep la tierra desaparecía -pasaba
	// de roca a césped sin el tramo suelto de en medio, que es justo lo que
	// delata una ladera real desde lejos-.
	float t1 = smoothstep(0.0, umbral_roca, ladera);
	float t2 = smoothstep(umbral_roca, umbral_cesped, ladera);
	vec3 base = mix(roca, tierra_color.rgb, t1);
	base = mix(base, cesped, t2);

	vec2 deriva = vec2(1.0, 0.35) * TIME * nubes_sombra_velocidad * 40.0;
	float n_sombra = fbm3(vec3((p_mundo.xz + deriva) * nubes_sombra_escala, 0.0));
	float sombra = smoothstep(0.34, 0.60, n_sombra) * nubes_sombra_cantidad;
	base *= (1.0 - sombra);

	ALBEDO = base;
	ROUGHNESS = mix(roughness_roca, roughness_cesped, t2);
	SPECULAR = 0.15;
}
