// EL CÉSPED CON VOLUMEN (14-10-2026, «el césped no debería ser plano, ¿no?»).
// Capas apiladas a pocos milímetros (shell texturing): en cada capa solo
// quedan los píxeles que caen dentro de una brizna, y la brizna se afina al
// subir, así que de cerca se ve hierba de verdad -con altura, raíz oscura y
// punta clara- en vez de una foto pegada al suelo. Las briznas se TUMBAN hacia
// el sentido del corte de su franja (por eso las franjas cambian de tono). Solo
// cerca de la cámara: la malla la sigue (`CespedCapas`) y se apaga a 18 m.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, cull_back;

#include "res://visor/cesped_comun.gdshaderinc"

uniform vec2 tam_plano = vec2(80.0, 117.0);
uniform float altura = 0.032;
uniform float densidad = 70.0;
uniform float lejos = 18.0;

varying vec3 v_mundo;
varying float v_capa;

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_capa = clamp(VERTEX.y / altura, 0.0, 1.0);
}

void fragment() {
	vec2 w = v_mundo.xz;
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float dist = length(cam - v_mundo);
	float cerca = 1.0 - smoothstep(lejos * 0.55, lejos, dist);
	vec2 uv = (w + tam_plano * 0.5) / tam_plano;
	if (cerca <= 0.0 || uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		discard;
	}
	float sentido = cesped_mascara(uv) * 2.0 - 1.0;
	// Tumbadas con el corte, y un poco al azar (el viento, las pisadas).
	vec2 wl = w - vec2(0.0, sentido) * v_capa * 0.011 + (vec2(ruido(w * 3.0), ruido(w * 3.0 + 9.0)) - 0.5) * v_capa * 0.008;
	vec2 celda = floor(wl * densidad);
	vec2 f = fract(wl * densidad) - 0.5;
	float h = mix(0.4, 1.0, h21(celda)) * cerca;
	vec2 centro = (vec2(h21(celda + 3.1), h21(celda + 7.7)) - 0.5) * 0.45;
	float r = 0.44 * (1.0 - v_capa / max(h, 0.001));
	if (v_capa > h || length(f - centro) > r) {
		discard;
	}
	vec3 base = cesped_color(w, uv, v_mundo, cam);
	// Raíz en sombra, punta que coge luz (y algo más amarilla).
	// (Se funde con la distancia: si no, cerca de la cámara el suelo se veía
	// más oscuro y se notaba el borde del parche.)
	base *= mix(1.0, mix(0.72, 1.12, v_capa), cerca);
	base = mix(base, base * vec3(1.06, 1.05, 0.85), v_capa * 0.4 * cerca);
	ALBEDO = base;
	ROUGHNESS = 0.94;
	SPECULAR = 0.06;
}
