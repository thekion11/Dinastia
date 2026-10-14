// EL COLOR DEL CÉSPED, compartido por el campo (`cesped.gdshader`) y las capas
// de briznas que le dan volumen cerca de la cámara (`cesped_capas.gdshader`):
// así la hierba en relieve tiene EXACTAMENTE el verde, las franjas y el
// desgaste del suelo que tiene debajo.
// SIN `source_color` a propósito: en Compatibility (móvil, web) no se pasaba a
// lineal y el césped salía verde menta. La máscara se compara en sRGB (los
// valores crudos del dibujo) y los colores llegan YA en lineal desde GDScript.
uniform sampler2D dibujo : filter_linear_mipmap, repeat_disable;
uniform vec3 claro_s = vec3(0.5, 0.75, 0.55);
uniform vec3 oscuro_s = vec3(0.4, 0.65, 0.45);
uniform vec3 claro = vec3(0.21, 0.52, 0.26);
uniform vec3 oscuro = vec3(0.13, 0.39, 0.18);
uniform vec2 tam_campo = vec2(80.0, 117.0);
uniform float fuerza_franjas = 1.0;
uniform float desgaste = 1.0;
// Multiplicador general (el césped de la tele es un verde hondo, no pastel).
uniform float brillo = 0.72;

float h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) {
		s += ruido(p) * a;
		p *= 2.03;
		a *= 0.5;
	}
	return s;
}


// Máscara de la franja del dibujo (1 = la clara).
float cesped_mascara(vec2 uv) {
	vec3 d = texture(dibujo, uv).rgb;
	return step(0.5, dot(d - oscuro_s, claro_s - oscuro_s) / max(dot(claro_s - oscuro_s, claro_s - oscuro_s), 0.0001));
}

// El color del césped en el punto `w` (XZ del mundo) visto desde `cam`.
vec3 cesped_color(vec2 w, vec2 uv, vec3 mundo, vec3 cam) {
	float m = cesped_mascara(uv);
	vec3 vista = normalize(cam - mundo);
	float sentido = m * 2.0 - 1.0;
	float sheen = sentido * (0.45 + 0.55 * abs(vista.z)) * fuerza_franjas;
	vec3 base = mix(oscuro, claro, 0.5 + 0.5 * sentido * mix(0.7, 1.0, abs(vista.z)));
	base *= (1.0 + 0.1 * sheen) * brillo;
	float macro = fbm(w * 0.045);
	base *= 0.92 + 0.16 * macro;
	base = mix(base, base * vec3(1.08, 1.04, 0.82), smoothstep(0.62, 0.85, fbm(w * 0.09 + 7.0)) * 0.35);
	float gast = 0.0;
	for (int k = 0; k < 2; k++) {
		float zg = k == 0 ? 52.5 : -52.5;
		vec2 boca = vec2(0.0, zg - sign(zg) * 3.0);
		gast = max(gast, (1.0 - smoothstep(1.5, 6.5, length((w - boca) * vec2(0.55, 1.0)))));
		gast = max(gast, 0.6 * (1.0 - smoothstep(0.4, 1.6, length(w - vec2(0.0, zg - sign(zg) * 11.0)))));
	}
	gast = max(gast, 0.45 * (1.0 - smoothstep(0.5, 3.0, length(w))));
	gast *= desgaste * (0.55 + 0.45 * fbm(w * 0.7));
	base = mix(base, base * vec3(0.95, 0.78, 0.45) + vec3(0.03, 0.02, 0.0), gast * 0.55);
	return base;
}
