shader_type spatial;
// La cara real de un jugador (`CaraMalla`): su malla con la forma de su cara y
// los píxeles EXACTOS de su foto. Solo el borde se funde (alfa por vértice)
// con la piel del modelo, que ya lleva su mismo tono.
render_mode depth_draw_always, cull_back;

// SIN `source_color`, a propósito: la foto es una ImageTexture hecha en el
// juego y en Compatibility (móvil, web) el aviso no la pasaba a lineal -la cara
// salía más clara y lavada que el cuello del mismo color-. Se convierte aquí,
// igual en todos los renderizadores.
uniform sampler2D foto : filter_linear_mipmap, repeat_disable;
// Luminancia media de su piel (lineal), para quitar la luz de la foto.
uniform float lum_media = 0.3;
// Balance de blancos de la foto (por canal, lineal): quita el tinte de la luz
// con que se sacó (amarillo, verde, azul). Ver `caras_reales_malla.py`, "wb".
uniform vec3 balance = vec3(1.0);
// Su piel media (lineal): el color al que van los brillos de la foto.
uniform vec3 piel_lin = vec3(0.4, 0.25, 0.18);
// Cuánto se quita de la luz de la foto (0 = foto tal cual, 1 = toda la luz la
// pone el estadio). La foto trae medio rostro en sombra, o el flash de frente;
// si se deja, la cara parece un cromo pegado: la sombra no se mueve con el sol.
uniform float quitar_luz = 0.7;
// El mapeo de tonos del juego (ACES) satura los medios: la piel salía
// anaranjada al lado de la foto. Se compensa un poco (igual en el cuerpo, ver
// `VestidorQ.SATURACION_PIEL`).
uniform float saturacion = 1.0;
// Ver `VestidorQ.COMPENSAR_PIEL` (el mismo número para el cuerpo).
uniform float compensar = 1.6;
uniform float relleno = 0.3;
// La cámara de la foto expone para la cara; la luz del estadio no. Sin esto la
// piel salía mucho más oscura que en la foto (sobre todo la piel oscura).
// El cuerpo lleva la misma (`VestidorQ.EXPOSICION_PIEL`).
// NORMALIZA LA EXPOSICIÓN DE CADA FOTO: la claridad de su piel se lleva a una
// banda de piel real (0,55 * lum^0,6): una foto oscura (piel oscura con poca
// luz: salía negra en el juego) sube hasta x3; una quemada por el flash baja
// un poco. El orden entre jugadores se mantiene (más clara sigue más clara). La cuenta está repetida en `VestidorQ.exposicion_piel`.

float lum(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }
vec3 a_lineal(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void fragment() {
	vec3 c = a_lineal(texture(foto, UV).rgb) * balance;
	// La luz de la foto es lo que cambia despacio (mip 4 del recorte de 384:
	// ~24 px, más grande que un ojo); los rasgos (ojos, cejas, labios, barba)
	// son el detalle fino y se quedan.
	float baja = lum(a_lineal(textureLod(foto, UV, 4.0).rgb) * balance);
	float k = clamp(lum_media / max(baja, 0.004), 0.6, 1.8);
	c *= mix(1.0, k, quitar_luz);
	// Brillos de la foto (el flash en la nariz y la frente): se comprimen, el
	// brillo lo pone la luz del estadio.
	float l = lum(c);
	float tope = lum_media * 1.2;
	if (l > tope) {
		// Los brillos de flash son blancos: además de bajarlos, se llevan al
		// color de SU piel (si no, quedaban manchas grises en nariz y frente).
		float ln = tope + (l - tope) * 0.08;
		vec3 tono = piel_lin / max(lum(piel_lin), 0.001);
		c = mix(c * ln / l, tono * ln, smoothstep(tope, tope * 1.8, l));
	}
	// Solo SUBE las fotos oscuras; a una piel clara no se la oscurece (con
	// tope 0,75 las pieles claras salían bronceadas: auditoría de lotes 30-9).
	float exposicion = clamp(0.55 * pow(lum_media, 0.6) / max(lum_media, 0.001), 1.0, 3.0);
	// Al subir mucho la exposición (fotos oscuras) el color también se
	// dispara (pieles rojizas): se quita saturación en proporción.
	// COMPENSAR EL "PIE" DEL MAPEO DE TONOS: la caída de la luz y el mapeo
	// hunden más los canales oscuros de un color (medido: lo que se ve sale
	// como el color elevado a ~1,7 respecto de su gris) -una piel clara
	// (177,123,107) se veía (162,85,69), roja-. Se aplica la inversa en torno a
	// su gris: en pantalla queda el tono medido.
	float g = max(lum(c), 1e-4);
	c = g * pow(max(c / g, vec3(0.0)), vec3(1.0 / compensar));
	c = mix(vec3(lum(c)), c, saturacion) * exposicion;
	// Lo que en la foto tapaba la cara (una mano, un brazo): su piel.
	c = mix(c, piel_lin * exposicion, COLOR.g);
	ALBEDO = c;
	// Relleno: la luz que rebota de la grada y el césped levanta un poco las
	// sombras de la cara (el mismo relleno lleva la piel del cuerpo,
	// `equipacion_q.gdshader`, para que no se note la unión).
	// Relleno de cámara (como el reflector de las transmisiones): más en lo
	// que mira a la cámara. Sin él, una piel oscura en sombra quedaba negra.
	EMISSION = c * relleno * (0.35 + 0.65 * clamp(dot(NORMAL, VIEW), 0.0, 1.0));
	ALPHA = COLOR.a;
	// La misma luz que la piel del cuerpo (`equipacion_q.gdshader`): sin esto
	// la cara y el cuello no empataban aunque tuvieran el mismo color.
	// Mate: con menos, el cielo se reflejaba azul en la nariz y la frente.
	ROUGHNESS = 0.78;
	SPECULAR = 0.05;
	// Poco borde de luz: en la arista de la nariz dejaba un brillo azulado.
	RIM = 0.08;
	RIM_TINT = 0.6;
}

// LUZ DE PIEL: la piel deja pasar la luz y sus sombras son suaves (la luz
// "envuelve" la cara). Con la luz dura de siempre, el sol del estadio dejaba
// las cuencas de los ojos y medio rostro en negro. `envolver` = cuánto pasa
// la luz al lado en sombra; la sombra se tiñe un poco de rojo (sangre bajo la
// piel), apenas.
uniform float envolver = 0.45;

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float w = clamp((ndl + envolver) / (1.0 + envolver), 0.0, 1.0);
	// (Con un rojo fuerte en la sombra, media cara en sombra quedaba roja:
	// «el color de piel no es adecuado». Solo un matiz.)
	vec3 sangre = mix(vec3(1.0, 0.94, 0.91), vec3(1.0), clamp(ndl * 2.0, 0.0, 1.0));
	DIFFUSE_LIGHT += w * sangre * ATTENUATION * LIGHT_COLOR / PI;
	// Brillo especular (Blinn), suave: piel, no plástico.
	vec3 h = normalize(LIGHT + VIEW);
	float esp = pow(max(dot(NORMAL, h), 0.0), 24.0) * 0.035 * clamp(ndl, 0.0, 1.0);
	SPECULAR_LIGHT += esp * ATTENUATION * LIGHT_COLOR;
}
