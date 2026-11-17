// EL COLOR DEL CÉSPED, compartido por el campo (`cesped.gdshader`) y las capas
// de briznas que le dan volumen cerca de la cámara (`cesped_capas.gdshader`):
// así la hierba en relieve tiene EXACTAMENTE el verde, las franjas y el
// desgaste del suelo que tiene debajo.
// SIN `source_color` a propósito: en Compatibility (móvil, web) no se pasaba a
// lineal y el césped salía verde menta. La máscara se compara en sRGB (los
// valores crudos del dibujo) y los colores llegan YA en lineal desde GDScript.
// Sin mipmaps (14-10-2026): de lejos se promediaban las franjas a un gris medio
// y las ~20 franjas de corte se fundían en dos bloques enormes.
// LINEAL, NO «NEAREST» (25-10-2026, «sin bloques»): el dibujo es de 256 × 256 en
// 80 × 117 m, o sea un texel de 31 × 46 cm, y con el filtro más cercano los
// dibujos diagonales, circulares, de rombos o de abanico salían en ESCALERA de
// bloques de medio metro (de lejos, dientes de sierra en cada franja). Con el
// filtro lineal y el umbral de abajo el borde de la franja es la curva de nivel
// del dibujo: una línea limpia. Las rayas rectas quedan exactamente donde estaban.
uniform sampler2D dibujo : filter_linear, repeat_disable;
uniform vec3 claro_s = vec3(0.5, 0.75, 0.55);
uniform vec3 oscuro_s = vec3(0.4, 0.65, 0.45);
uniform vec3 claro = vec3(0.21, 0.52, 0.26);
uniform vec3 oscuro = vec3(0.13, 0.39, 0.18);
uniform vec2 tam_campo = vec2(80.0, 117.0);
uniform float fuerza_franjas = 1.0;
uniform float desgaste = 1.0;
// Multiplicador general (el césped de la tele es un verde hondo, no pastel).
uniform float brillo = 0.64;
// EL VERDE NATURAL (16-11, referencia de FC Mobile): algo apagado y tirando a amarillo, no el verde saturado
// de antes (saturación 1,15 y sin tinte). Mismo coste: solo cambian constantes.
uniform float saturacion = 0.68;   // (17-11: 0,74 → 0,68, «sigue leyéndose verde saturado»)
uniform vec3 tinte = vec3(1.04, 0.95, 0.64);
// Cuánto se marcan las franjas de corte (antes el brillo de la franja era ±10 %).
uniform float marca_franjas = 0.30;
// EL SENTIDO DEL CORTE (17-11): la cortadora pasa A LO LARGO de cada franja, y la franja cambia de tono cuando se mira en ese
// sentido. «rayas» (franjas que se suceden a lo largo del campo) se corta de banda a banda: eje X del mundo, justo hacia donde mira
// la cámara de TV. Antes el brillo se tomaba siempre de la vista en Z, y desde la TV (que mira en X) las franjas salían a medio gas.
// Lo pone `StadiumBuilder` según el dibujo del club; los dibujos mixtos (damero, círculos…) van en diagonal.
uniform vec2 eje_corte = vec2(1.0, 0.0);

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
	vec3 d = textureLod(dibujo, uv, 0.0).rgb;
	float t = dot(d - oscuro_s, claro_s - oscuro_s) / max(dot(claro_s - oscuro_s, claro_s - oscuro_s), 0.0001);
	// CUATRO NIVELES con borde de ~3 cm (no un salto seco: sin dientes al moverse
	// la cámara): 0 y 1 son las dos franjas de siempre; 0,3 y 0,7, las franjas
	// suaves («liso» y las de dentro de cada mitad en «mitades»).
	return 0.3 * smoothstep(0.1, 0.2, t) + 0.4 * smoothstep(0.45, 0.55, t) + 0.3 * smoothstep(0.8, 0.9, t);
}

// EL DESGASTE (17-11, referencia de FC Mobile): dónde está pisado el césped, de 0 (sano) a 1 (tierra). Solo formas (sin ruido):
// la boca de cada arco (el área chica, donde el portero se tira y se pelean los córners), el punto de penal con su halo y el
// centro del campo. Coste: aritmética; el grano del borde lo pone `cesped_grano`.
float cesped_desgaste(vec2 w) {
	float g = 0.0;
	for (int k = 0; k < 2; k++) {
		float zg = k == 0 ? 52.5 : -52.5;
		float s = sign(zg);
		// La boca: un óvalo de ~11 × 6 m pegado a la línea, más gastado en el centro (los primeros 2-3 m delante del arco).
		vec2 b = (w - vec2(0.0, zg - s * 2.4)) / vec2(5.6, 3.1);
		g = max(g, 1.0 - smoothstep(0.25, 1.05, length(b)));
		// El punto de penal: tierra en el punto (el que patea pisa ahí) y un halo pisado de ~2,5 m.
		float dp = length(w - vec2(0.0, zg - s * 11.0));
		g = max(g, 0.85 * (1.0 - smoothstep(0.35, 1.0, dp)));
		g = max(g, 0.4 * (1.0 - smoothstep(1.0, 2.8, dp)));
	}
	float dc = length(w);
	g = max(g, 0.75 * (1.0 - smoothstep(0.5, 1.6, dc)));
	g = max(g, 0.42 * (1.0 - smoothstep(1.6, 4.5, dc)));
	return g * desgaste;
}

// El grano del desgaste (dos ruidos, menos que el `fbm` de cuatro que había): el borde roto de la calva y las matas que quedan.
float cesped_grano(vec2 w) {
	return 0.6 * ruido(w * 0.9) + 0.4 * ruido(w * 3.7);
}

// El color del césped en el punto `w` (XZ del mundo) visto desde `cam`.
vec3 cesped_color(vec2 w, vec2 uv, vec3 mundo, vec3 cam) {
	float m = cesped_mascara(uv);
	vec3 vista = normalize(cam - mundo);
	float sentido = m * 2.0 - 1.0;
	// Cuánto se mira en el sentido del corte (1 = de frente a la pasada de la cortadora).
	float frente = abs(dot(vista.xz, eje_corte));
	float sheen = sentido * (0.4 + 0.6 * frente) * fuerza_franjas;
	vec3 base = mix(oscuro, claro, 0.5 + 0.5 * sentido * mix(0.65, 1.0, frente));
	base *= (1.0 + marca_franjas * sheen) * brillo;
	// Variación de tono a gran escala (~20 m): zonas más secas o más verdes, sin cambiar el número de `fbm`.
	float macro = fbm(w * 0.045);
	base *= 0.84 + 0.32 * macro;
	base = mix(base, base * vec3(1.06, 1.0, 0.78), smoothstep(0.35, 0.7, macro) * 0.6);
	base = mix(base, base * vec3(1.08, 1.04, 0.82), smoothstep(0.62, 0.85, fbm(w * 0.09 + 7.0)) * 0.35);
	// Desgaste (17-11): primero césped pisado (más seco y amarillo), y en el centro de la calva, tierra con matas sueltas.
	float gast = cesped_desgaste(w);
	if (gast > 0.0) {
		float gr = cesped_grano(w);
		float pisado = smoothstep(0.0, 0.55, gast * (0.7 + 0.6 * gr));
		float lum = dot(base, vec3(0.30, 0.59, 0.11));
		base = mix(base, base * vec3(1.12, 0.95, 0.55), pisado * 0.7);
		float tierra = smoothstep(0.55, 0.85, gast * (0.55 + 0.9 * gr));
		base = mix(base, vec3(lum) * vec3(1.75, 1.3, 0.78), tierra * 0.85);
	}
	// Verde natural (16-11): un poco menos saturado y hacia el amarillo (antes 1,15 y vec3(0.94, 0.99, 0.92)).
	float gris = dot(base, vec3(0.30, 0.59, 0.11));
	base = mix(vec3(gris), base, saturacion);
	base *= tinte;
	return base;
}
