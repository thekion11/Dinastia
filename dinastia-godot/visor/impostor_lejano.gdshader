// LA SILUETA LEJANA CON SU EQUIPACIÓN (frente 2, 16-11): la cápsula de `ImpostorLejano` era de un solo color (la
// camiseta) y desde la cámara de TV de ULTRA BAJA todo el equipo se veía como pastillas. Mismos triángulos y una sola
// llamada; el color sale de la altura en la cápsula (de -0,5 a 0,5 antes de escalar): cabeza con la piel, camiseta,
// short y medias, como lee el ojo a un futbolista de 30 px. Sin texturas ni luces extra.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 c_camiseta : source_color = vec4(0.8, 0.1, 0.1, 1.0);
uniform vec4 c_short : source_color = vec4(1.0);
uniform vec4 c_medias : source_color = vec4(0.8, 0.1, 0.1, 1.0);
uniform vec4 c_piel : source_color = vec4(0.75, 0.55, 0.42, 1.0);

varying float v_h;

void vertex() {
	v_h = VERTEX.y + 0.5;   // 0 = pies, 1 = coronilla
}

void fragment() {
	float h = v_h;
	vec3 c = c_medias.rgb;
	c = mix(c, c_piel.rgb, step(0.27, h) * (1.0 - step(0.33, h)));   // rodilla
	c = mix(c, c_short.rgb, step(0.33, h));
	c = mix(c, c_camiseta.rgb, step(0.54, h));
	c = mix(c, c_piel.rgb, step(0.85, h));                           // cuello y cara
	ALBEDO = c;
	ROUGHNESS = 0.9;
}
