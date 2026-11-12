shader_type spatial;
render_mode unshaded;
// LA CABINA DEL ASCENSOR DEL CLUB (12-11-2026). El ascensor está en la fachada de atrás: detrás de la pared no hay sitio para una cabina de
// verdad. Esto dibuja una cabina CON FONDO en un solo plano («interior mapping»): por cada píxel se lanza el rayo de la mirada dentro de una
// caja imaginaria de `hueco` × `fondo` m y se pinta la cara donde choca: espejo al fondo, paneles de acero cepillado a los lados, plafón de
// luz en el techo y suelo oscuro con una franja del color del club. Al moverse el jugador, la perspectiva cambia como en una cabina real.
// Coste: 2 triángulos y ninguna textura. Todo en espacio de la tangente, así da igual dónde y cómo esté girado el plano.
uniform vec2 hueco = vec2(1.9, 2.3);
uniform float fondo = 1.5;
uniform vec4 acento : source_color = vec4(0.1, 0.3, 0.7, 1.0);

float banda(float x, float centro, float medio) {
	return 1.0 - smoothstep(medio * 0.7, medio, abs(x - centro));
}

// Pared lateral o de fondo: zócalo oscuro, panel de acero con juntas verticales y pasamanos cromado a 0,95 m.
vec3 pared(float u, float y, bool espejo) {
	vec3 acero = vec3(0.5, 0.52, 0.56) * (0.96 + 0.04 * sin(y * 40.0));   // el cepillado
	vec3 c = acero;
	if (espejo && y > 1.05) {
		// El espejo: refleja el plafón (claro arriba) y la puerta (oscuro al centro).
		float r = smoothstep(1.05, hueco.y, y);
		c = mix(vec3(0.42, 0.47, 0.52), vec3(0.86, 0.88, 0.9), r * r);
		c *= 1.0 - 0.25 * banda(u, 0.5, 0.16);
	}
	float junta = min(fract(u * 3.0), 1.0 - fract(u * 3.0));
	c *= 0.72 + 0.28 * smoothstep(0.0, 0.025, junta);
	c = mix(c, vec3(0.13, 0.13, 0.15), 1.0 - smoothstep(0.1, 0.12, y));   // zócalo
	float mano = banda(y, 0.95, 0.045);
	vec3 cromo = mix(vec3(0.25, 0.26, 0.28), vec3(0.98, 0.98, 1.0), smoothstep(0.93, 0.975, y));
	return mix(c, cromo, mano);
}

void fragment() {
	// El rayo de la mirada en el espacio del plano: x a lo ancho, y hacia arriba, z hacia fuera.
	vec3 v = normalize(vec3(dot(VIEW, TANGENT), dot(VIEW, BINORMAL), dot(VIEW, NORMAL)));
	vec3 d = -v;
	d.z = min(d.z, -0.02);
	vec3 o = vec3(UV.x * hueco.x, (1.0 - UV.y) * hueco.y, 0.0);
	float tx = abs(d.x) < 1e-4 ? 1e6 : ((d.x > 0.0 ? hueco.x - o.x : -o.x) / d.x);
	float ty = abs(d.y) < 1e-4 ? 1e6 : ((d.y > 0.0 ? hueco.y - o.y : -o.y) / d.y);
	float tz = -fondo / d.z;
	float t = min(tx, min(ty, tz));
	vec3 p = o + d * t;
	float prof = clamp(-p.z / fondo, 0.0, 1.0);
	vec3 c;
	if (tz <= tx && tz <= ty) {
		c = pared(p.x / hueco.x, p.y, true);
	} else if (tx <= ty) {
		c = pared(prof, p.y, false) * 0.86;
	} else if (d.y > 0.0) {
		// Techo: plafón de luz cálida con marco.
		vec2 q = abs(vec2(p.x / hueco.x, prof) - 0.5);
		float luz = 1.0 - smoothstep(0.3, 0.34, max(q.x, q.y));
		c = mix(vec3(0.3, 0.31, 0.33), vec3(1.0, 0.96, 0.84) * 1.25, luz);
	} else {
		// Suelo: piedra oscura con la franja del club y el reflejo del plafón.
		c = vec3(0.16, 0.16, 0.18) * (0.9 + 0.1 * step(0.5, fract(p.x * 2.0 + floor(prof * 3.0) * 0.5)));
		c = mix(c, acento.rgb, banda(prof, 0.12, 0.05) * 0.9);
		vec2 q = abs(vec2(p.x / hueco.x, prof) - 0.5);
		c += vec3(0.1, 0.095, 0.08) * (1.0 - smoothstep(0.1, 0.45, length(q)));
	}
	// Luz que cae del techo y sombra en las aristas (oclusión de mentira).
	float arista = min(min(p.x, hueco.x - p.x), min(p.y, hueco.y - p.y));
	if (!(tz <= tx && tz <= ty)) {
		arista = min(arista + (tx <= ty ? 1.0 : 0.0) * 0.0, fondo * (1.0 - prof));
	}
	c *= 0.62 + 0.38 * smoothstep(0.0, 0.3, arista);
	c *= 0.8 + 0.2 * smoothstep(0.0, hueco.y, p.y);
	ALBEDO = c;
}
