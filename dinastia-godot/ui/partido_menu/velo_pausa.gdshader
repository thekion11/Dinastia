shader_type canvas_item;
// EL VELO DE LA PAUSA (17-11): el partido congelado detrás, desenfocado (13 muestras en dos anillos) y oscurecido.
uniform sampler2D pantalla : hint_screen_texture, filter_linear;
uniform float radio = 6.0;
uniform float oscuro = 0.42;
void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * radio;
	vec3 c = texture(pantalla, SCREEN_UV).rgb;
	for (int i = 0; i < 6; i++) {
		float a = float(i) * 1.0472;
		vec2 d = vec2(cos(a), sin(a));
		c += texture(pantalla, SCREEN_UV + d * px).rgb;
		c += texture(pantalla, SCREEN_UV + d * px * 2.2).rgb;
	}
	c /= 13.0;
	COLOR = vec4(c * oscuro + vec3(0.01, 0.015, 0.04), 1.0);
}
