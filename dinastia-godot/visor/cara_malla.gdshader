shader_type spatial;
// La cara real de un jugador (`CaraMalla`): su malla con la forma de su cara y
// los píxeles EXACTOS de su foto. Solo el borde se funde (alfa por vértice)
// con la piel del modelo, que ya lleva su mismo tono.
render_mode depth_draw_always, cull_back;

uniform sampler2D foto : source_color, filter_linear_mipmap, repeat_disable;

void fragment() {
	ALBEDO = texture(foto, UV).rgb;
	ALPHA = COLOR.a;
	ROUGHNESS = 0.62;
	SPECULAR = 0.35;
	RIM = 0.15;
}
