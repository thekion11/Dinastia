shader_type spatial;
// LA PINTURA DE LOS COCHES (27-10-2026). Los coches de Kenney llevan una paleta de colores planos y chillones («de juguete»).
// Este shader usa la misma paleta pero la apaga a color de coche de verdad (menos saturado y más oscuro, con brillo metálico) y
// detecta el celeste claro de los cristales para dejarlos oscuros y reflectantes.
uniform sampler2D paleta : source_color, filter_linear_mipmap;
uniform float saturacion = 0.62;
uniform float valor = 0.84;

void fragment() {
	vec3 c = texture(paleta, UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float vidrio = step(0.55, l) * step(0.10, c.b - c.r);
	vec3 pintura = mix(vec3(l), c, saturacion) * valor;
	ALBEDO = mix(pintura, vec3(0.025, 0.03, 0.04), vidrio);
	METALLIC = mix(0.35, 0.75, vidrio);
	ROUGHNESS = mix(0.34, 0.06, vidrio);
	SPECULAR = 0.6;
}
