shader_type canvas_item;
// El "look" de transmision de TV que le faltaba al partido 3D (comparado
// contra Open-Soccer en la investigacion del 22-9-2026): un oscurecido suave
// hacia los bordes de pantalla, como el que deja un lente de verdad. Es una
// capa 2D encima del viewport -el 3D "va directo al viewport principal, no
// dentro de un SubViewport" (ver ui/estadio.gd)-, no un efecto de Environment:
// Godot 4 no trae vineta nativa en el recurso Environment, y esto es mas
// barato que un CompositorEffect para algo puramente cosmetico.

uniform float intensidad : hint_range(0.0, 1.0) = 0.32;
uniform float radio : hint_range(0.0, 1.0) = 0.58;
uniform float suavidad : hint_range(0.05, 1.2) = 0.68;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv);
	float v = smoothstep(radio, radio + suavidad, d);
	COLOR = vec4(0.0, 0.0, 0.0, v * intensidad);
}
