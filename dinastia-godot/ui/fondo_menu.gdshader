shader_type canvas_item;
// LOS FONDOS DE LOS MENÚS A PANTALLA COMPLETA (29-9-2026, mapa de metas 23).
// Un fondo propio y animado para cada menú del panel lateral. Todos salen de
// este shader: `estilo` elige el dibujo y los tres colores lo tiñen.
//   0 historia   rayos de luz sepia, polvo y grano de película
//   1 gente      bokeh cálido que flota
//   2 carrera    ondas doradas en diagonal
//   3 operac.    cuadrícula de datos con barrido y puntos
//   4 vida       atardecer con motas de luz
//   5 editar     plano azul con cuadrícula y cruz de cursor
//   6 ajustes    anillos concéntricos que giran, como engranajes
//   7 ciudad     siluetas de edificios con ventanas encendidas
//   8 estadio    haces de focos que barren sobre el césped a rayas

uniform int estilo = 0;
uniform vec4 c1 : source_color = vec4(0.05, 0.06, 0.08, 1.0);
uniform vec4 c2 : source_color = vec4(0.12, 0.14, 0.18, 1.0);
uniform vec4 c3 : source_color = vec4(0.9, 0.7, 0.3, 1.0);
uniform vec2 aspecto = vec2(1.777, 1.0);

float h1(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float ruido(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h1(i), h1(i + vec2(1, 0)), f.x), mix(h1(i + vec2(0, 1)), h1(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * ruido(p); p *= 2.03; a *= 0.5; }
	return v;
}
// Campo de bokeh: círculos suaves que suben despacio.
float bokeh(vec2 uv, float escala, float t, float tam) {
	vec2 g = uv * escala + vec2(0.0, -t);
	vec2 id = floor(g); vec2 f = fract(g) - 0.5;
	float r = h1(id);
	vec2 off = vec2(h1(id + 3.1), h1(id + 7.7)) - 0.5;
	float s = tam * (0.4 + 0.6 * r);
	// El círculo cabe SIEMPRE en su celda (radio + desplazamiento <= 0,5): si
	// se salía, el borde de la celda lo cortaba y se veían cuadrados (etapa 1).
	float d = length(f - off * max(0.0, 1.0 - 2.0 * s));
	return smoothstep(s, s * 0.55, d) * step(0.45, r);
}

void fragment() {
	vec2 uv = UV;
	vec2 p = uv * aspecto;
	float t = TIME;
	vec3 col = mix(c1.rgb, c2.rgb, uv.y);
	if (estilo == 0) {
		col = mix(c2.rgb, c1.rgb, uv.y);
		float rayos = 0.0;
		for (int i = 0; i < 4; i++) {
			float fi = float(i);
			float x = 0.15 + fi * 0.24 + 0.04 * sin(t * 0.2 + fi);
			rayos += smoothstep(0.09, 0.0, abs(uv.x - x - (uv.y - 0.0) * 0.35)) * (1.0 - uv.y);
		}
		col += c3.rgb * rayos * 0.22;
		col += c3.rgb * bokeh(uv * vec2(aspecto.x, 1.0), 26.0, t * 0.03, 0.08) * 0.35;
		col *= 0.92 + 0.08 * h1(uv * 800.0 + fract(t * 7.0));
	} else if (estilo == 1) {
		col += c3.rgb * bokeh(p, 5.0, t * 0.05, 0.42) * 0.22;
		col += mix(c3.rgb, c2.rgb, 0.5) * bokeh(p + 3.7, 9.0, t * 0.08, 0.36) * 0.16;
		col += c3.rgb * bokeh(p + 9.1, 16.0, t * 0.12, 0.3) * 0.1;
	} else if (estilo == 2) {
		// Hilos de luz (etapa 1, 2.ª pasada): antes eran ondas anchas
		// deformadas con ruido que se veían como manchas de pintura. Ahora,
		// cinco trayectorias finas que suben en diagonal y ondulan despacio,
		// con un halo suave: «tu camino», no un borrón.
		for (int i = 0; i < 5; i++) {
			float fi = float(i);
			float base = 0.15 + fi * 0.19;
			float y = base + (aspecto.x - p.x) * 0.32 + 0.05 * sin(p.x * (2.2 + fi * 0.4) + t * (0.25 + fi * 0.05) + fi * 1.7);
			float d = abs(p.y - y);
			float ancho = 0.0025 + 0.0015 * fi;
			col += c3.rgb * (smoothstep(ancho * 2.0, 0.0, d) * (0.28 - fi * 0.03) + exp(-d * 38.0) * 0.06);
		}
		col += c3.rgb * 0.05 * smoothstep(1.2, 0.0, length(p - vec2(aspecto.x * 0.85, 0.9)));
	} else if (estilo == 3) {
		vec2 g = fract(p * 14.0);
		float lin = max(smoothstep(0.96, 1.0, g.x), smoothstep(0.96, 1.0, g.y));
		col += c3.rgb * lin * 0.08;
		float barrido = smoothstep(0.03, 0.0, abs(uv.y - fract(t * 0.08)));
		col += c3.rgb * barrido * 0.25;
		vec2 id = floor(p * 14.0);
		float punto = step(0.93, h1(id + floor(t * 1.5)));
		col += c3.rgb * punto * smoothstep(0.35, 0.0, length(g - 0.5)) * 0.5;
	} else if (estilo == 4) {
		col = mix(c3.rgb * 0.55, c1.rgb, smoothstep(0.0, 0.85, uv.y));
		col = mix(col, c2.rgb, smoothstep(0.55, 1.0, uv.y));
		float sol = smoothstep(0.35, 0.0, length((uv - vec2(0.7, 0.62)) * aspecto));
		col += c3.rgb * sol * 0.35;
		col += vec3(1.0, 0.9, 0.7) * bokeh(p, 12.0, t * 0.04, 0.2) * 0.18;
	} else if (estilo == 5) {
		vec2 g1 = fract(p * 8.0); vec2 g2 = fract(p * 40.0);
		float mayor = max(smoothstep(0.97, 1.0, g1.x), smoothstep(0.97, 1.0, g1.y));
		float menor = max(smoothstep(0.93, 1.0, g2.x), smoothstep(0.93, 1.0, g2.y));
		col += c3.rgb * (mayor * 0.22 + menor * 0.05);
		vec2 cur = vec2(0.5 + 0.3 * sin(t * 0.21), 0.5 + 0.25 * cos(t * 0.17)) * aspecto;
		float cruz = smoothstep(0.004, 0.0, min(abs(p.x - cur.x), abs(p.y - cur.y))) * smoothstep(0.25, 0.0, length(p - cur));
		col += c3.rgb * cruz * 0.6;
	} else if (estilo == 6) {
		vec2 q = p - vec2(aspecto.x * 0.78, 0.55);
		float r = length(q); float a = atan(q.y, q.x);
		for (int i = 0; i < 5; i++) {
			float fi = float(i);
			float radio = 0.15 + fi * 0.13;
			float dientes = step(0.5, fract(a * (6.0 + fi * 4.0) / 6.2832 + t * (0.03 + fi * 0.01) * (mod(fi, 2.0) * 2.0 - 1.0)));
			col += c3.rgb * smoothstep(0.012, 0.0, abs(r - radio)) * (0.25 + 0.2 * dientes);
		}
		col += c3.rgb * 0.06 * smoothstep(0.9, 0.0, r);
	} else if (estilo == 7) {
		// CIUDAD AL ANOCHECER (14-10-2026, «el fondo de ciudad 3D podría ser
		// mejor»): cielo con degradado, estrellas que titilan y luna; tres capas
		// de edificios con parallax lento (las lejanas, más claras y con bruma),
		// antenas con luz roja, ventanas que se encienden y apagan, y una avenida
		// al pie con faros blancos y rojos que pasan.
		vec3 horizonte = c3.rgb * 0.5 + c2.rgb * 0.7;
		col = mix(c1.rgb * 0.7, horizonte, smoothstep(0.0, 0.78, uv.y));
		float zona = step(uv.y, 0.55);
		vec2 ge = floor(uv * vec2(170.0, 95.0));
		float estrella = step(0.992, h1(ge)) * (0.5 + 0.5 * sin(t * 2.2 + h1(ge + 4.0) * 40.0));
		col += vec3(1.0, 0.97, 0.88) * estrella * zona * (1.0 - uv.y * 1.6);
		vec2 luna = (uv - vec2(0.84, 0.17)) * aspecto;
		float dl = length(luna);
		col += vec3(1.0, 0.93, 0.75) * (smoothstep(0.055, 0.05, dl) * 0.9 + smoothstep(0.22, 0.0, dl) * 0.18);
		for (int i = 0; i < 3; i++) {
			float fi = float(i);
			float dens = 11.0 + fi * 8.0;
			float x = uv.x * dens + t * (0.03 + fi * 0.045);
			float celda = floor(x);
			float semilla = celda + fi * 31.7;
			float base = 0.30 - fi * 0.09;
			float altura = base + (0.10 + 0.14 * (2.0 - fi) * 0.5) * h1(vec2(semilla, 2.0)) + (h1(vec2(semilla, 9.0)) > 0.8 ? 0.12 : 0.0);
			float ancho = 0.62 + 0.3 * h1(vec2(semilla, 5.0));
			float dentro = step(abs(fract(x) - 0.5), ancho * 0.5);
			float techo = 1.0 - altura;
			float edificio = step(techo, uv.y) * dentro;
			float bruma = 0.55 - fi * 0.22;
			vec3 muro = mix(c1.rgb * (0.55 + fi * 0.18), horizonte, bruma * 0.5);
			// Un destello de borde en el lado de la luna.
			muro += vec3(0.05) * step(0.46, fract(x)) * (1.0 - fi * 0.3);
			col = mix(col, muro, edificio);
			// Antena con luz roja parpadeante.
			float antena = step(abs(fract(x) - 0.5), 0.02) * step(techo - 0.05, uv.y) * step(uv.y, techo) * step(0.78, h1(vec2(semilla, 13.0)));
			col = mix(col, c1.rgb * 0.6, antena);
			float punta = step(length(vec2((fract(x) - 0.5) * 3.0, (uv.y - (techo - 0.05)) * 10.0)), 0.1) * step(0.78, h1(vec2(semilla, 13.0)));
			col += vec3(1.0, 0.15, 0.1) * punta * (0.5 + 0.5 * sin(t * 3.0 + semilla));
			// Ventanas.
			vec2 w = vec2(fract(x * 4.0), fract((uv.y - techo) * (70.0 - fi * 14.0)));
			vec2 wid = vec2(floor(x * 4.0), floor((uv.y - techo) * (70.0 - fi * 14.0)));
			float ventana = step(0.22, w.x) * step(w.x, 0.78) * step(0.25, w.y) * step(w.y, 0.8);
			float enc = step(0.55, h1(wid + semilla + floor(t * 0.25 + h1(wid) * 9.0)));
			vec3 luz = mix(c3.rgb, vec3(0.75, 0.9, 1.0), step(0.85, h1(wid + 3.3)));
			col += luz * ventana * enc * edificio * (0.65 - fi * 0.15) * step(0.04, uv.y - techo);
		}
		// Avenida al pie con tráfico.
		float calle = smoothstep(0.88, 0.9, uv.y);
		col = mix(col, c1.rgb * 0.45, calle);
		float carril1 = smoothstep(0.012, 0.0, abs(uv.y - 0.925));
		float carril2 = smoothstep(0.012, 0.0, abs(uv.y - 0.965));
		float faro1 = smoothstep(0.88, 1.0, fract(uv.x * 3.0 - t * 0.12 + h1(vec2(floor(uv.x * 3.0 - t * 0.12), 1.0)) * 0.6));
		float faro2 = smoothstep(0.88, 1.0, fract(uv.x * 2.4 + t * 0.09 + h1(vec2(floor(uv.x * 2.4 + t * 0.09), 2.0)) * 0.6));
		col += vec3(1.0, 0.95, 0.8) * carril1 * faro1 * 1.2 + vec3(1.0, 0.2, 0.15) * carril2 * faro2 * 1.1;
		col += c3.rgb * 0.05 * calle;
	} else if (estilo == 8) {
		float cesped = step(0.72, uv.y);
		float franjas = step(0.5, fract(uv.x * 10.0 + (uv.y - 0.72) * 3.0));
		col = mix(col, mix(c2.rgb, c2.rgb * 1.25, franjas), cesped);
		for (int i = 0; i < 4; i++) {
			float fi = float(i);
			vec2 foco = vec2(0.1 + fi * 0.27, 0.02);
			float ang = 0.5 * sin(t * 0.25 + fi * 1.7);
			vec2 d = uv - foco;
			vec2 dir = vec2(sin(ang), cos(ang));
			float a = acos(clamp(dot(normalize(d * aspecto), dir), -1.0, 1.0));
			col += c3.rgb * smoothstep(0.16, 0.0, a) * (1.0 - uv.y) * 0.22;
			col += vec3(1.0) * smoothstep(0.02, 0.0, length((uv - foco) * aspecto)) * 0.8;
		}
	}
	// Viñeta para que el contenido se lea en el centro.
	float v = smoothstep(1.25, 0.35, length((uv - 0.5) * vec2(1.3, 1.0)));
	col *= mix(0.72, 1.0, v);
	COLOR = vec4(col, 1.0);
}
