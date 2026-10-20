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
// Desde qué altura la cabeza es pelo (29-9-2026, malla de las primeras filas).
// 9.0 = sin pelo, que es lo que usa la malla barata.
uniform float pelo_desde = 9.0;
// Las mallas HORNEADAS de personas reales (herramientas/hornear_publico.gd) tienen
// brazos que suben por encima del cuello: piel y pelo solo valen cerca del eje de
// la cabeza. 9.0 = sin límite (las mallas de mentira).
uniform float lado_max = 9.0;

// LA OLA Y LA ONDA (20-10-2026, M-036/044). Las pone `OlaGrada` mientras duran
// (fuera de ese rato valen -1 y no cuestan nada):
//   ola: la ola de toda la vida, que da la vuelta al estadio; cada hincha se
//        pone de pie y levanta los brazos cuando le pasa el frente.
//   onda: en un gol, la grada salta en un anillo que se abre desde un punto.
uniform float ola_edad = -1.0;
uniform float ola_vel = 0.55;       // radianes por segundo (≈11 s la vuelta)
uniform float ola_ancho = 0.42;     // radianes de grada en pie a la vez
uniform float ola_inicio = 0.0;     // ángulo donde arranca
uniform float ola_vueltas = 2.0;
uniform float onda_edad = -1.0;
uniform vec3 onda_centro = vec3(0.0);
uniform float onda_vel = 24.0;      // metros por segundo
uniform float onda_ancho = 7.0;

varying float v_alto;
varying float v_azar;
varying float v_lado;

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
	v_lado = abs(VERTEX.x);
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
	// No todos se suman (uno de cada ocho se queda sentado).
	float se_suma = step(0.12, fract(v_azar * 3.7));
	if (ola_edad >= 0.0) {
		float ang = atan(origen.x, origen.z);
		float d = mod(ang - ola_inicio, 6.2832);
		float recorrido = ola_edad * ola_vel;
		float k = recorrido - d + (v_azar - 0.5) * 0.12;
		if (k >= 0.0 && recorrido < ola_vueltas * 6.2832 + d) {
			float km = mod(k, 6.2832);
			float h = km < ola_ancho ? sin(km / ola_ancho * 3.1416) : 0.0;
			// De pie (todo el cuerpo sube) y los brazos/hombros, más.
			VERTEX.y += h * se_suma * (0.5 + 0.6 * peso);
		}
	}
	if (onda_edad >= 0.0) {
		float r = length(origen.xz - onda_centro.xz);
		float x = onda_edad * onda_vel - r;
		// Saltan cuando les llega el frente y siguen saltando un rato detrás.
		if (x > 0.0 && x < onda_ancho * 3.0) {
			float apaga = 1.0 - x / (onda_ancho * 3.0);
			float salto = abs(sin((onda_edad * 7.0) + v_azar * 6.28));
			VERTEX.y += salto * apaga * se_suma * (0.25 + 0.2 * peso);
		}
	}
}

void fragment() {
	vec3 ropa = COLOR.rgb;
	vec3 piel = mix(piel_clara, piel_oscura, v_azar);
	float cab = step(v_lado, lado_max);
	vec3 color = mix(ropa, piel, smoothstep(cuello_desde, cuello_hasta, v_alto) * cab);
	// Pelo: negro, castaño, rubio o canoso, según el mismo azar del hincha;
	// uno de cada seis, calvo o con gorro del color de la ropa.
	float r = fract(v_azar * 7.31);
	vec3 pelo = r < 0.35 ? vec3(0.05, 0.04, 0.035) : (r < 0.65 ? vec3(0.22, 0.13, 0.07) : (r < 0.8 ? vec3(0.72, 0.58, 0.32) : (r < 0.86 ? vec3(0.62, 0.62, 0.6) : ropa * 0.9)));
	if (r < 0.94) {
		color = mix(color, pelo, smoothstep(pelo_desde, pelo_desde + 0.01, v_alto) * cab);
	}
	ALBEDO = color;
	ROUGHNESS = 0.85;
	SPECULAR = 0.15;
}
