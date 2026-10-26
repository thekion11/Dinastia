shader_type canvas_item;
// EL FONDO DE LA CONFIGURACIÓN DEL CLUB (fase 1, etapa 4). Una bufanda: franjas
// diagonales anchas de los dos colores del club, muy oscurecidas para que el
// texto se lea encima, que avanzan despacio. Un halo detrás de la vista previa
// (a la izquierda) y viñeta en los bordes. Cambia de color en vivo al elegir.

uniform vec4 color_a : source_color = vec4(0.12, 0.25, 0.19, 1.0);
uniform vec4 color_b : source_color = vec4(0.79, 0.64, 0.15, 1.0);
uniform vec4 fondo : source_color = vec4(0.047, 0.082, 0.063, 1.0);
uniform float velocidad = 0.035;
uniform float aspecto = 1.777;
uniform vec2 halo = vec2(0.17, 0.55);

void fragment() {
	vec2 p = vec2(UV.x * aspecto, UV.y);
	// Franjas: dos anchos distintos para que no parezca una rejilla.
	float d = p.x * 0.9 + p.y * 1.35 - TIME * velocidad;
	float ancha = smoothstep(0.42, 0.5, abs(fract(d * 1.6) - 0.5) * 2.0);
	float fina = smoothstep(0.86, 0.9, abs(fract(d * 4.8 + 0.25) - 0.5) * 2.0);
	vec3 col = mix(fondo.rgb, color_a.rgb * 0.42, 0.55);
	col = mix(col, color_a.rgb * 0.62, ancha * 0.55);
	col = mix(col, color_b.rgb * 0.5, fina * 0.22);
	// El halo detrás de la vista previa: el escudo «se ilumina».
	float h = 1.0 - smoothstep(0.0, 0.55, length((UV - halo) * vec2(aspecto, 1.0)) * 0.9);
	col += color_b.rgb * h * 0.10 + color_a.rgb * h * 0.12;
	// Viñeta.
	float v = smoothstep(1.25, 0.35, length((UV - vec2(0.5, 0.5)) * vec2(1.25, 1.0)));
	col *= mix(0.45, 1.0, v);
	COLOR = vec4(col, 1.0);
}
