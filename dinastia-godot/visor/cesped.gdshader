// EL CÉSPED DE TRANSMISIÓN (14-10-2026, comparado con el vídeo de FC 26).
// El material estándar daba dos verdes planos que, desde la cámara alta de la
// tele, se fundían en uno. En un estadio de verdad las franjas de corte se ven
// porque la hierba está tumbada en sentidos opuestos: la que apunta hacia la
// cámara se ve oscura y la que apunta lejos, clara, y eso cambia según desde
// dónde se mira. Aquí:
//   - el DIBUJO de corte del club sale de la textura de siempre (máscara);
//   - el BRILLO de cada franja depende del ángulo de la cámara (sheen);
//   - BRIZNA fina, manchas de verde a gran escala y algo de amarillo;
//   - DESGASTE en las áreas chicas, el punto de penal y el círculo central.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

#include "res://visor/cesped_comun.gdshaderinc"

varying vec3 v_mundo;

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 w = v_mundo.xz;
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 base = cesped_color(w, UV, v_mundo, cam);
	// Brizna fina (cerca) + MECHONES de tamaño medio (30-60 cm) que SÍ se ven desde
	// la cámara de transmisión (14-10-2026, «el césped sigue plano»): antes todo el
	// detalle se apagaba a 25-70 m, justo donde está la cámara de la tele.
	float dist = length(cam - v_mundo);
	float cerca_f = 1.0 - smoothstep(25.0, 70.0, dist);
	float fino = mix(0.5, ruido(w * 31.0) * 0.5 + ruido(w * 67.0) * 0.3 + ruido(w * 9.0) * 0.2, cerca_f);
	float mechon = fbm(w * 2.6 + 3.0);
	float parche = fbm(w * 0.55 + 11.0);
	base *= (0.92 + 0.16 * fino) * (0.86 + 0.28 * mechon) * (0.93 + 0.14 * parche);
	ALBEDO = base;
	ROUGHNESS = 0.96 - 0.06 * fino;
	SPECULAR = 0.08;
	// Relieve: brizna fina cerca y mechones a media y larga distancia (sin apagarse).
	float e = 0.008;
	float hx = ruido((w + vec2(e, 0.0)) * 55.0) - ruido(w * 55.0);
	float hz = ruido((w + vec2(0.0, e)) * 55.0) - ruido(w * 55.0);
	float e2 = 0.06;
	float mx = fbm((w + vec2(e2, 0.0)) * 2.6 + 3.0) - mechon;
	float mz = fbm((w + vec2(0.0, e2)) * 2.6 + 3.0) - mechon;
	vec2 g = vec2(hx, hz) * 3.0 * cerca_f + vec2(mx, mz) * 5.0;
	NORMAL_MAP = normalize(vec3(-g.x, -g.y, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.6;
}
