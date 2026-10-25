shader_type canvas_item;
// EL FONDO DE LA PANTALLA DE IDIOMA (25-10-2026). Un cielo de noche con una
// aurora y, abajo, el borde de un planeta enorme con su retícula de meridianos y
// paralelos girando despacio, luces de ciudades que parpadean en los cruces y la
// atmósfera brillando en el horizonte: el mundo entero, al que vas a hablarle.
// Los dos tintes salen de la bandera del idioma enfocado (los cambia el script
// con un fundido), así cada idioma tiñe la pantalla con sus colores.

uniform vec4 tinte_a : source_color = vec4(0.67, 0.08, 0.1, 1.0);
uniform vec4 tinte_b : source_color = vec4(0.95, 0.75, 0.0, 1.0);
uniform vec2 aspecto = vec2(1.7778, 1.0);

varying vec4 modula;

void vertex() {
	modula = COLOR;
}

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

void fragment() {
	vec2 p = UV * aspecto;
	float t = TIME;
	vec3 col = mix(vec3(0.030, 0.038, 0.066), vec3(0.010, 0.013, 0.026), UV.y);
	// Tinte de fondo muy tenue: la pantalla entera «huele» al idioma.
	col += tinte_a.rgb * 0.035 * (1.0 - UV.y);
	// Estrellas: pocas, finas y parpadeando cada una a su ritmo.
	vec2 ce = floor(p * 140.0);
	float e = step(0.9965, h1(ce));
	float brillo = 0.5 + 0.5 * sin(t * (1.0 + 2.0 * h1(ce + 4.0)) + h1(ce) * 40.0);
	vec2 fe = fract(p * 140.0) - 0.5;
	col += vec3(0.75, 0.8, 0.95) * e * brillo * smoothstep(0.32, 0.0, length(fe)) * (1.0 - UV.y) * 0.8;
	// Aurora: dos cintas que respiran, teñidas con los colores del idioma.
	float n = fbm(vec2(p.x * 1.2 + t * 0.025, p.y * 2.0 - t * 0.015));
	float y1 = 0.24 + 0.10 * sin(p.x * 1.3 + t * 0.05) + 0.12 * (n - 0.5);
	float y2 = 0.40 + 0.08 * sin(p.x * 0.9 - t * 0.04 + 2.0) + 0.10 * (n - 0.5);
	float c1 = exp(-pow((UV.y - y1) * 6.5, 2.0));
	float c2 = exp(-pow((UV.y - y2) * 9.0, 2.0));
	col += tinte_a.rgb * c1 * 0.20 * (0.5 + n);
	col += tinte_b.rgb * c2 * 0.08 * (0.4 + n);
	// El planeta: centro muy por debajo de la pantalla, solo asoma su borde.
	float R = 1.5;
	vec2 cp = vec2(aspecto.x * 0.5, 1.0 + R * 0.78);
	vec2 d = (p - cp) / R;
	float r = length(d);
	if (r < 1.0) {
		float z = sqrt(1.0 - r * r);
		vec3 nr = vec3(d.x, d.y, z);
		float inc = 0.55;
		nr = vec3(nr.x, nr.y * cos(inc) - nr.z * sin(inc), nr.y * sin(inc) + nr.z * cos(inc));
		float lon = atan(nr.x, nr.z) + t * 0.02;
		float lat = asin(clamp(-nr.y, -1.0, 1.0));
		float paso = 3.14159265 / 14.0;
		vec2 celda = vec2(lon, lat) / paso;
		vec2 g = abs(fract(celda + 0.5) - 0.5);
		float ancho = 0.022 / max(z, 0.25);
		float reticula = max(1.0 - smoothstep(0.0, ancho, g.x), 1.0 - smoothstep(0.0, ancho, g.y));
		vec3 cuerpo = vec3(0.016, 0.022, 0.04) + tinte_a.rgb * 0.035 * z;
		cuerpo += mix(tinte_b.rgb, vec3(0.8, 0.85, 1.0), 0.5) * reticula * 0.16 * z;
		// Luces de ciudades en algunos cruces de la retícula.
		vec2 id = floor(celda + 0.5);
		float hay = step(0.72, h1(id + 9.0));
		float lat_luz = 0.6 + 0.4 * sin(t * (0.6 + h1(id) * 1.5) + h1(id) * 30.0);
		cuerpo += tinte_b.rgb * hay * lat_luz * smoothstep(0.09, 0.0, length(g)) * 0.9 * z;
		// Borde iluminado por dentro (la luz rasante del horizonte).
		cuerpo += mix(tinte_b.rgb, vec3(1.0), 0.35) * pow(smoothstep(0.82, 1.0, r), 3.0) * 0.45;
		col = mix(col, cuerpo, smoothstep(1.0, 0.996, r));
	}
	// La atmósfera: un halo fuera del borde.
	float fuera = max(r - 1.0, 0.0) * R;
	col += mix(tinte_b.rgb, vec3(0.75, 0.85, 1.0), 0.45) * exp(-fuera * 9.0) * 0.38 * step(1.0, r);
	col += tinte_a.rgb * exp(-fuera * 2.5) * 0.10 * step(1.0, r);
	// Viñeta y un grano muy fino para que los degradados no hagan bandas.
	vec2 v = UV - 0.5;
	col *= 1.0 - 0.55 * dot(v, v);
	col += (h1(UV * 913.0 + fract(t)) - 0.5) * 0.012;
	COLOR = vec4(col, 1.0) * modula;
}
