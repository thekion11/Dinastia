shader_type spatial;

// LA HINCHADA, VIVA (23-9-2026).
//
// El usuario, viendo las capturas de la grada ya corregida: "el público aún no
// lo veo malo, ¿hay formas de que se vean más reales?". Sí, y las tres más
// baratas están aquí dentro -ninguna añade un solo vértice ni una sola llamada
// de dibujo, porque todo el público de una tribuna es UN `MultiMesh`-:
//
//   1. SE MUEVEN. Es el delator número uno de un estadio de videojuego: una
//      multitud perfectamente congelada. Cada hincha se balancea con su propia
//      fase -sacada de su posición en el mundo, así que es estable entre
//      cuadros y distinta para cada uno-, y de vez en cuando pega un salto.
//      Los pies no se mueven: el peso del desplazamiento crece con la altura
//      del vértice, o sea que la cadera queda quieta y los hombros oscilan.
//   2. LA CABEZA ES PIEL, NO CAMISETA. Hasta hoy cada hincha era una cápsula de
//      UN SOLO COLOR -el de su ropa-, cabeza incluida: de cerca se leían como
//      pastillas de colores. El color de instancia (`set_instance_color`) sigue
//      siendo la ropa; de la altura del cuello hacia arriba se mezcla a un tono
//      de piel, elegido con la misma fase, así que la grada tiene tonos de piel
//      variados sin gastar ni un dato más por instancia.
//   3. Sin `cull_disabled` ni transparencia: esto se dibuja miles de veces por
//      cuadro en una Intel UHD y no puede permitirse ninguna de las dos.

// Cuánto se balancean los hombros, en metros.
uniform float amplitud = 0.045;
uniform float velocidad = 1.9;
// La altura (en el espacio del propio modelo) donde acaba el cuello. El torso
// es una cápsula de 0,55 m centrada en 0,28 y la cabeza una esfera en 0,61.
uniform float cuello_desde = 0.50;
uniform float cuello_hasta = 0.57;
uniform vec3 piel_clara : source_color = vec3(0.88, 0.71, 0.56);
uniform vec3 piel_oscura : source_color = vec3(0.40, 0.27, 0.19);

varying float v_alto;
varying float v_azar;

// Ruido de un solo valor, estable: la misma entrada da siempre la misma salida,
// así que un hincha no cambia de tono de piel de un cuadro a otro.
float azar(float x) {
	return fract(sin(x * 12.9898) * 43758.5453);
}

void vertex() {
	// La posición de ESTA instancia en el mundo. En un `MultiMesh`,
	// `MODEL_MATRIX` ya trae la transformación de la instancia.
	vec3 origen = MODEL_MATRIX[3].xyz;
	float fase = origen.x * 1.73 + origen.z * 2.31 + origen.y * 0.9;
	v_azar = azar(fase);
	v_alto = VERTEX.y;
	float t = TIME * velocidad + fase;
	// 0 en los pies, 1 de los hombros para arriba.
	float peso = clamp(VERTEX.y / 0.7, 0.0, 1.0);
	VERTEX.x += sin(t) * amplitud * peso;
	VERTEX.z += cos(t * 0.73) * amplitud * 0.55 * peso;
	// El salto: casi todo el tiempo vale 0 y de vez en cuando levanta unos
	// centímetros. Con `max(0, sin(...) - 0.86)` solo el 11% del ciclo queda
	// por encima del umbral, así que salta una minoría en cada momento -que es
	// lo que pasa en una grada de verdad, no una ola perfecta.
	VERTEX.y += max(0.0, sin(t * 0.41 + v_azar * 6.28) - 0.86) * 1.1 * peso;
}

void fragment() {
	vec3 ropa = COLOR.rgb;
	vec3 piel = mix(piel_clara, piel_oscura, v_azar);
	ALBEDO = mix(ropa, piel, smoothstep(cuello_desde, cuello_hasta, v_alto));
	ROUGHNESS = 0.85;
	SPECULAR = 0.15;
}
