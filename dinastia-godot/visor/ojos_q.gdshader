shader_type spatial;
// LOS OJOS DEL JUGADOR 3D (29-9-2026). Las texturas de ojos del pack no
// vinieron; antes eran una bola marrón lisa ("mirada de maniquí"). Aquí se
// dibujan con la pose de reposo (UV2 = x,y), en capas:
//   1. esclerótica: blanco roto, rosada hacia los lagrimales, con venitas;
//   2. iris: fibras radiales, anillo oscuro en el borde (limbo) y el centro
//      más claro alrededor de la pupila;
//   3. pupila;
//   4. sombra del párpado sobre el globo (el ojo nunca es blanco puro arriba);
//   5. párpados en almendra (piel del jugador), pestañas arriba, más densas
//      hacia fuera, y la línea húmeda de abajo;
//   6. brillo de la córnea (reflejo pequeño y fijo) + rugosidad baja.
// Globos: centro x = ±0,0338 m, y = 1,6986 m, radio 0,015 m.
uniform vec4 iris : source_color = vec4(0.23, 0.16, 0.09, 1.0);
uniform vec4 piel : source_color = vec4(0.78, 0.55, 0.4, 1.0);
// Con foto real: ojos algo menos abiertos y blanco menos brillante, para que
// no miren fijo al lado de la cara fotografiada.
uniform float apertura = 1.0;
uniform float blanco = 1.0;
varying vec2 v_r;

void vertex() {
	v_r = UV2;
}

float h21(vec2 p) { return fract(sin(p.x * 127.1 + p.y * 311.7) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float lado = v_r.x < 0.0 ? -1.0 : 1.0;
	// dx > 0 = hacia la sien, en los dos ojos.
	vec2 d = v_r - vec2(lado * 0.0338, 1.6986);
	float dx = d.x * lado;
	float r = length(d);
	float ang = atan(d.y, d.x);

	// 1. Esclerótica.
	vec3 col = vec3(0.84, 0.81, 0.77) * blanco;
	float rincon = smoothstep(0.005, 0.014, abs(dx));
	col = mix(col, vec3(0.78, 0.55, 0.5), rincon * (dx < 0.0 ? 0.55 : 0.3));
	float venas = smoothstep(0.93, 1.0, ruido(vec2(ang * 9.0, r * 900.0))) * smoothstep(0.008, 0.013, r);
	col = mix(col, vec3(0.7, 0.3, 0.28), venas * 0.35);

	// 2. Iris.
	float R = 0.0072;
	float en_iris = 1.0 - smoothstep(R - 0.0005, R + 0.0003, r);
	float fibras = ruido(vec2(ang * 22.0, r * 1400.0)) * 0.6 + ruido(vec2(ang * 57.0, r * 300.0)) * 0.4;
	vec3 ir = iris.rgb * (0.65 + 0.7 * fibras);
	ir = mix(ir, iris.rgb * 1.7 + vec3(0.04, 0.03, 0.0), (1.0 - smoothstep(0.0028, 0.0045, r)) * 0.6);
	ir *= 1.0 - 0.6 * smoothstep(R - 0.0016, R, r);
	col = mix(col, ir, en_iris);
	// 3. Pupila.
	col = mix(col, vec3(0.01), 1.0 - smoothstep(0.0024, 0.0029, r));

	// Párpados en almendra: más abiertos al centro, se cierran hacia los rincones.
	float borde_sup = (0.0060 - dx * dx * 22.0 + dx * 0.05) * apertura;
	float borde_inf = (-0.0078 + dx * dx * 26.0) * mix(1.0, apertura, 0.6);
	// 4. Sombra del párpado de arriba sobre el globo.
	col *= 1.0 - 0.45 * smoothstep(borde_sup - 0.004, borde_sup, d.y);
	col *= 1.0 - 0.18 * smoothstep(borde_inf + 0.002, borde_inf, d.y);
	// 6. Brillo de la córnea.
	col += vec3(0.55) * (1.0 - smoothstep(0.0004, 0.0011, length(d - vec2(0.0021, 0.0022))));

	// 5. Párpados, pestañas y línea húmeda.
	float sup = smoothstep(borde_sup, borde_sup + 0.0008, d.y);
	float inf = smoothstep(borde_inf, borde_inf - 0.0008, d.y);
	float parpado = max(sup, inf);
	vec3 p_col = piel.rgb * mix(0.72, 0.9, smoothstep(borde_sup, borde_sup + 0.004, d.y));
	col = mix(col, p_col, parpado);
	float denso = 0.75 + 0.25 * smoothstep(-0.004, 0.01, dx);
	float pest = (1.0 - smoothstep(0.0003, 0.0012 * denso, abs(d.y - borde_sup - 0.0002))) * smoothstep(0.016, 0.012, abs(dx));
	pest = max(pest, step(0.55, ruido(vec2(dx * 2600.0, 0.0))) * step(borde_sup, d.y) * step(d.y, borde_sup + 0.0018 * denso) * smoothstep(0.015, 0.01, abs(dx)));
	col = mix(col, vec3(0.03, 0.02, 0.015), pest * 0.9);
	float humeda = (1.0 - smoothstep(0.0, 0.0006, abs(d.y - borde_inf))) * smoothstep(0.014, 0.008, abs(dx));
	col = mix(col, vec3(0.75, 0.5, 0.46), humeda * 0.6);

	ALBEDO = col;
	ROUGHNESS = mix(0.08, 0.6, parpado);
	SPECULAR = mix(0.7, 0.4, parpado);
	CLEARCOAT = 1.0 - parpado;
	CLEARCOAT_ROUGHNESS = 0.05;
}
