shader_type canvas_item;
// EL BRILLO DEL LOGO DEL MENÚ DE MODOS (fase 1, etapa 2). Una franja de luz
// cálida cruza el escudo y las letras en diagonal cada `periodo` segundos y
// luego descansa: un reflejo de metal, no un cartel que parpadea.
// Solo SUMA luz donde ya hay dibujo (multiplica por el alfa): no pinta el
// hueco transparente del rectángulo ni pisa el `modulate` del fundido.

uniform float ancho = 290.0;
uniform float periodo = 6.0;
uniform float intensidad = 0.55;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	float fase = mod(TIME, periodo);
	// La franja tarda 1,3 s en cruzar; el resto del periodo, quieta fuera.
	float t = clamp(fase / 1.3, 0.0, 1.0);
	float x = mix(-90.0, ancho + 90.0, t);
	float d = abs(local.x - x + local.y * 0.65);
	float banda = smoothstep(26.0, 0.0, d) * step(fase, 1.3);
	COLOR.rgb += vec3(1.0, 0.95, 0.8) * banda * intensidad * COLOR.a;
}
