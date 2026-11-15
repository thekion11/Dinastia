shader_type spatial;
render_mode unshaded, cull_disabled;

// EL PÚBLICO 2D (15-11-2026, prototipo): cada hincha es UN cuadro plano (2 triángulos) que enseña un sprite de un atlas horneado
// con nuestras propias figuras 3D (`herramientas/hornear_publico_2d.gd`). Todo el público de una grada sigue siendo un MultiMesh, pero
// con 2 triángulos por persona en vez de 80-658. Los nombres de los parámetros de reacción son los de `hinchada.gdshader`, así que
// `OlaGrada`, `FestejoGrada` y compañía lo mueven sin cambios (ola, onda de gol, protesta, «¡uy!», nervios).
// Atlas: columnas = clip (6) x cuadro (3); filas = variante de hincha (12). Máscara: R = ropa, G = bufanda/raya 1, B = bufanda/raya 2.
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D mascara : filter_linear_mipmap, repeat_disable;
uniform vec3 bufanda1 : source_color = vec3(0.1, 0.35, 0.2);
uniform vec3 bufanda2 : source_color = vec3(0.95);
uniform float luz = 0.92;           // ajuste de brillo al ambiente del estadio (día/noche)
uniform float ola_edad = -1.0;
uniform float ola_vel = 0.55;
uniform float ola_ancho = 0.42;
uniform float ola_inicio = 0.0;
uniform float ola_vueltas = 2.0;
uniform float onda_edad = -1.0;
uniform vec3 onda_centro = vec3(0.0);
uniform float onda_vel = 24.0;
uniform float onda_ancho = 7.0;
uniform float protesta_edad = -1.0;
uniform float onda_bando = 0.0;
uniform float protesta_bando = 0.0;
uniform float ocasion_edad = -1.0;
uniform float ocasion_bando = 0.0;
uniform float nervios = 0.0;

const float COLS = 18.0;
const float FILAS = 12.0;
const float CUADROS = 3.0;
const float SALTO_MAX = 0.55;

varying flat float v_azar;
varying flat float v_c0;
varying flat float v_c1;
varying flat float v_mezcla;
varying flat float v_fila;

float azar(float x) {
	return fract(sin(x * 12.9898) * 43758.5453);
}

void vertex() {
	vec3 origen = MODEL_MATRIX[3].xyz;
	float fase = origen.x * 1.73 + origen.z * 2.31 + origen.y * 0.9;
	v_azar = azar(fase);
	float vis = step(COLOR.a, 0.75);
	float suma = step(0.12, fract(v_azar * 3.7));
	// Reposo: 40 % sentado, 35 % charla, 25 % aplaude; con nervios, manos a la cabeza.
	float r0 = fract(v_azar * 5.3);
	float slot = r0 < 0.4 ? 0.0 : (r0 < 0.75 ? 1.0 : 2.0);
	float vel = slot < 0.5 ? 0.3 : (slot < 1.5 ? 0.7 : 2.2);
	if (nervios > 0.0 && fract(v_azar * 2.9) < nervios) {
		slot = 3.0;
		vel = 0.9;
	}
	float ev_w = 0.0;
	float ev_slot = 0.0;
	float alza = 0.0;
	if (ola_edad >= 0.0) {
		float d = mod(atan(origen.x, origen.z) - ola_inicio, 6.2832);
		float k = ola_edad * ola_vel - d;
		if (k >= -0.3 && ola_edad * ola_vel < ola_vueltas * 6.2832 + d) {
			float km = mod(k + 0.3, 6.2832);
			float h = km < ola_ancho + 0.6 ? sin(km / (ola_ancho + 0.6) * 3.1416) : 0.0;
			if (h * suma > ev_w) { ev_w = h * suma; ev_slot = 4.0; alza = h * 0.25; }
		}
	}
	if (ocasion_edad >= 0.0) {
		float t_o = ocasion_edad - v_azar * 0.3;
		float env = smoothstep(0.0, 0.22, t_o) * (1.0 - smoothstep(1.6, 2.6, t_o)) * (1.0 - abs(ocasion_bando - vis));
		if (env * suma > ev_w) { ev_w = env * suma; ev_slot = 3.0; alza = 0.0; }
	}
	if (protesta_edad >= 0.0) {
		float env = smoothstep(0.0, 0.4, protesta_edad) * (1.0 - smoothstep(2.6, 3.4, protesta_edad)) * (1.0 - abs(protesta_bando - vis));
		if (env * suma > ev_w) { ev_w = env * suma; ev_slot = 5.0; alza = 0.0; }
	}
	if (onda_edad >= 0.0) {
		float x = onda_edad * onda_vel - length(origen.xz - onda_centro.xz);
		float g = smoothstep(0.0, 4.0, x) * (1.0 - smoothstep(4.6, 6.0, onda_edad)) * (1.0 - abs(onda_bando - vis)) * suma;
		if (g > ev_w) {
			ev_w = g;
			ev_slot = 4.0;
			float zona = floor(origen.x / 9.0) * 1.7 + floor(origen.z / 9.0) * 2.3 + floor(origen.y / 6.0);
			alza = g * SALTO_MAX * max(0.0, sin(onda_edad * 6.5 + zona));
		}
	}
	if (ev_w > 0.5) {
		slot = ev_slot;
		vel = 1.6;
	}
	float fr = fract(TIME * vel * 0.5 + v_azar * 9.0) * CUADROS;
	float f0 = floor(fr);
	v_c0 = slot * CUADROS + f0;
	v_c1 = slot * CUADROS + mod(f0 + 1.0, CUADROS);
	v_mezcla = smoothstep(0.0, 1.0, fract(fr));
	v_fila = floor(fract(v_azar * 7.13) * FILAS);
	VERTEX.y += alza;
}

void fragment() {
	vec2 q = clamp(UV, vec2(0.008, 0.008), vec2(0.992, 0.992));
	vec2 u0 = vec2((v_c0 + q.x) / COLS, (v_fila + q.y) / FILAS);
	vec2 u1 = vec2((v_c1 + q.x) / COLS, (v_fila + q.y) / FILAS);
	vec4 a = mix(texture(atlas, u0), texture(atlas, u1), v_mezcla);
	vec3 m = mix(texture(mascara, u0).rgb, texture(mascara, u1).rgb, v_mezcla);
	vec3 ropa = clamp(COLOR.rgb, vec3(0.06), vec3(0.86)) * (0.86 + 0.24 * fract(v_azar * 13.7));
	vec3 c = a.rgb;
	c = mix(c, a.rgb * ropa * 1.16, m.r);
	c = mix(c, a.rgb * bufanda1 * 1.16, m.g);
	c = mix(c, a.rgb * bufanda2 * 1.16, m.b);
	ALBEDO = c * luz;
	ALPHA = a.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
