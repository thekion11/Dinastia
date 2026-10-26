shader_type canvas_item;
// EL ORO DE LA MARCA (`ui/entrada/intro.gd`). Lo que se pinta en blanco en esta capa sale
// como metal: claro arriba, oscuro por debajo de la mitad y un rebote de luz abajo (el
// degradado clásico de un rótulo dorado), más una franja de brillo que barre en diagonal.
// El degradado va por la caja de la marca y NO por cada letra: así toda la palabra parece
// una sola pieza de metal y no ocho piezas sueltas.
// La caja va en coordenadas de pantalla (0..1, origen arriba a la izquierda), las mismas de
// SCREEN_UV, y la calcula el script en cada fotograma.

uniform vec4 caja = vec4(0.0, 0.0, 1.0, 1.0);
// Posición de la franja de brillo a lo ancho de la caja (0..1); fuera de -0.3..1.3 no se ve.
uniform float barrido = -9.0;
uniform float fuerza_barrido = 0.85;

void fragment() {
	vec4 base = COLOR;
	vec2 q = (SCREEN_UV - caja.xy) / max(caja.zw - caja.xy, vec2(0.0001));
	float y = clamp(q.y, 0.0, 1.0);
	vec3 alto = vec3(1.00, 0.93, 0.70);
	vec3 medio = vec3(0.88, 0.66, 0.26);
	vec3 bajo = vec3(0.56, 0.37, 0.11);
	vec3 rebote = vec3(0.95, 0.78, 0.42);
	vec3 oro = mix(alto, medio, smoothstep(0.0, 0.52, y));
	oro = mix(oro, bajo, smoothstep(0.50, 0.80, y));
	oro = mix(oro, rebote, smoothstep(0.80, 1.0, y));
	float diagonal = q.x + (q.y - 0.5) * 0.30;
	float franja = exp(-pow((diagonal - barrido) / 0.055, 2.0));
	vec3 col = oro * base.rgb + vec3(1.0, 0.97, 0.88) * franja * fuerza_barrido * base.a;
	COLOR = vec4(col, base.a);
}
