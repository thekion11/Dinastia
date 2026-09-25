shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// VIENTO EN EL FOLLAJE (13-9-2026). Antes las copas de los árboles eran
// completamente rígidas -una ciudad de cientos de árboles clavados es de lo
// primero que delata que nada ahí está vivo-. Cada árbol se mece con una
// fase PROPIA -sacada de su posición en el mundo, no de un contador global-,
// para que no se muevan todos al unísono como un solo bloque de gelatina, y
// el balanceo crece hacia arriba: la base de la copa, pegada al tronco, casi
// no se mueve; la parte alta sí -así se dobla una rama de verdad, no un
// poste-.
//
// Se aplica sobre un `MultiMeshInstance3D` (cientos de copas en una sola
// malla): el vértice ya trae su posición LOCAL a la esfera de la copa, y
// `MODEL_MATRIX` lo distingue de instancia a instancia, así que no hace
// falta ningún dato extra por árbol.

uniform vec4 tinte_base : source_color = vec4(0.30, 0.46, 0.22, 1.0);
uniform float roughness_val : hint_range(0.0, 1.0) = 0.88;
uniform float metallic_specular_val : hint_range(0.0, 1.0) = 0.15;
uniform float viento_velocidad = 1.5;
uniform float viento_fuerza = 0.30;

void vertex() {
	vec3 centro_mundo = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float fase = dot(centro_mundo.xz, vec2(0.35, 0.53)) * 6.2831853;
	// Cuanto mas alto el vertice dentro de la copa (en espacio LOCAL, antes
	// de escalar), mas se mece.
	float peso = clamp(VERTEX.y / 3.4 + 0.5, 0.0, 1.0);
	float t = TIME * viento_velocidad + fase;
	VERTEX.x += sin(t) * viento_fuerza * peso;
	VERTEX.z += cos(t * 0.8) * viento_fuerza * peso;
}

void fragment() {
	// Mismo comportamiento que `vertex_color_use_as_albedo` de
	// `StandardMaterial3D`: el color por instancia (un verde distinto por
	// árbol, para que el bosque no se lea como papel pintado) modula el
	// tinte base.
	ALBEDO = tinte_base.rgb * COLOR.rgb;
	ROUGHNESS = roughness_val;
	SPECULAR = metallic_specular_val;
}
