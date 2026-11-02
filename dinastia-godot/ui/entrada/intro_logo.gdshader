shader_type canvas_item;
// EL BRILLO DORADO DEL LOGO (`ui/entrada/intro.gd`): una franja de luz que cruza el logo de
// izquierda a derecha. Solo ilumina donde el logo tiene color (usa su alfa), así que no
// mancha el fondo transparente. La caja va en coordenadas de pantalla (0..1), como SCREEN_UV.

uniform vec4 caja = vec4(0.0, 0.0, 1.0, 1.0);
// Posición de la franja a lo ancho de la caja (0..1); fuera de -0.3..1.3 no se ve.
uniform float barrido = -9.0;
uniform float fuerza_barrido = 0.95;

void fragment() {
	vec4 base = COLOR;
	vec2 q = (SCREEN_UV - caja.xy) / max(caja.zw - caja.xy, vec2(0.0001));
	float diagonal = q.x + (q.y - 0.5) * 0.30;
	float franja = exp(-pow((diagonal - barrido) / 0.075, 2.0));
	float halo = exp(-pow((diagonal - barrido) / 0.22, 2.0));
	vec3 oro = vec3(1.0, 0.88, 0.50);
	vec3 col = base.rgb + oro * (franja * fuerza_barrido + halo * 0.18) * base.a;
	COLOR = vec4(col, base.a);
}
