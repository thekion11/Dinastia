shader_type spatial;
// ARRUGAS POR EDAD (26-10-2026, opción A): una pasada ENCIMA de la piel (material_overlay)
// que solo multiplica: donde no hay surco deja 1 (el color de piel base no cambia).
// `posiciones`: para cada UV de la piel, el punto del modelo en reposo (lo hornea
// `PersonajeVida._mapa`); con él se dibujan los surcos en metros, alrededor de los ojos.
render_mode blend_mul, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform sampler2D posiciones : filter_linear, repeat_disable;
uniform float edad = 0.0;      // 0..1
uniform float ojos_y = 1.699;  // altura de los ojos (modelo)
uniform float ojos_x = 0.033;  // media distancia entre ojos

float linea(float d, float ancho) {
	return 1.0 - smoothstep(0.0, ancho, abs(d));
}

float segmento(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float h = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
	return length(p - a - ab * h);
}

void fragment() {
	vec4 m = texture(posiciones, UV);
	float oscuro = 0.0;
	if (m.a > 0.5 && edad > 0.0) {
		vec3 p = m.rgb;
		float x = abs(p.x);
		float y = p.y - ojos_y;
		bool delante = p.z > 0.035;
		if (delante) {
			// Frente: tres o cuatro surcos horizontales, algo curvados, que se borran a los lados.
			float fr = smoothstep(0.03, 0.04, y) * (1.0 - smoothstep(0.068, 0.078, y)) * (1.0 - smoothstep(0.035, 0.055, x));
			float ondas = y - 0.0018 * sin(x * 70.0) + x * x * 1.2;
			float surcos = linea(fract(ondas / 0.0105) - 0.5, 0.09);
			oscuro += fr * surcos * 0.55 * smoothstep(0.0, 0.6, edad);
			// Entrecejo: dos rayitas verticales.
			float ec = (1.0 - smoothstep(0.004, 0.012, abs(y - 0.022))) * linea(x - 0.007, 0.0016);
			oscuro += ec * 0.45 * smoothstep(0.25, 0.9, edad);
			// Patas de gallo: rayas que salen en abanico del rabillo del ojo.
			vec2 rab = vec2(ojos_x + 0.021, 0.0);
			vec2 q = vec2(x, y) - rab;
			float r = length(q);
			float ang = atan(q.y, q.x);
			float abanico = linea(fract(ang / 0.33) - 0.5, 0.16);
			float zona = smoothstep(0.002, 0.006, r) * (1.0 - smoothstep(0.012, 0.02, r)) * step(0.0, q.x + 0.004);
			oscuro += zona * abanico * 0.6 * smoothstep(0.1, 0.8, edad);
			// Ojeras: media luna suave bajo cada ojo.
			vec2 o = vec2(x - ojos_x, y + 0.016);
			float ojera = 1.0 - smoothstep(0.0, 1.0, length(o * vec2(1.0 / 0.016, 1.0 / 0.006)));
			oscuro += ojera * 0.3 * edad;
			// Surcos nasogenianos: de la aleta de la nariz a la comisura.
			float ng = segmento(vec2(x, y), vec2(0.016, -0.045), vec2(0.028, -0.085));
			oscuro += linea(ng, 0.0028) * 0.6 * smoothstep(0.0, 0.7, edad);
			// Marioneta, ya mayor: de la comisura hacia la barbilla.
			float mr = segmento(vec2(x, y), vec2(0.027, -0.09), vec2(0.024, -0.11));
			oscuro += linea(mr, 0.0022) * 0.4 * smoothstep(0.5, 1.0, edad);
		}
		oscuro = clamp(oscuro, 0.0, 1.0) * (0.25 + 0.3 * edad);
	}
	// Tono del surco: sombra cálida, no gris.
	ALBEDO = mix(vec3(1.0), vec3(0.62, 0.48, 0.42), oscuro);
}
