shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

// EL HAZ DE LUZ DE LA FAROLA (21-10-2026). Antes era un cono de color plano
// con transparencia fija: de noche se veía como un triángulo amarillo de bordes
// duros en cada farola (vídeo de gameplay). Ahora es un haz de verdad: brilla
// junto al farol y se apaga hacia el suelo, y se desvanece en los bordes de la
// silueta (donde el cono se ve de canto), así que no tiene contorno.
uniform vec3 color : source_color = vec3(1.0, 0.8, 0.5);
uniform float fuerza = 0.0;   // la pone `CiudadExpansion.encender` (0 de día)

varying float v_h;

void vertex() {
	// El cilindro mide 1 de alto centrado en 0: 0 en el suelo, 1 en el farol.
	v_h = clamp(VERTEX.y + 0.5, 0.0, 1.0);
}

void fragment() {
	float frente = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float borde = smoothstep(0.05, 0.75, frente);
	float alto = mix(0.06, 1.0, v_h * v_h);
	ALBEDO = color;
	ALPHA = fuerza * borde * borde * alto;
}
