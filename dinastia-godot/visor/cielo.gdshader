shader_type sky;

// EL CIELO DE LA CIUDAD (12-9-2026). `ProceduralSkyMaterial` no sabe dibujar
// nada que no sea un degradado liso: de noche el cielo quedaba vacío -sin una
// sola estrella- y de día era un color plano sin una nube. Este shader hace
// el mismo degradado de siempre (los mismos cuatro colores que ya calculaba
// `ciudad_vista.gd`, ahora como uniforms) y le suma dos cosas que SÍ se notan
// mirando hacia arriba: nubes que se arrastran solas con el viento, y un
// cielo de estrellas que aparece de verdad cuando cae la noche.

uniform vec4 top_color : source_color = vec4(0.20, 0.42, 0.78, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.78, 0.86, 0.94, 1.0);
uniform vec4 ground_horizon_color : source_color = vec4(0.62, 0.70, 0.62, 1.0);
uniform vec4 ground_bottom_color : source_color = vec4(0.36, 0.47, 0.36, 1.0);
uniform float energy_multiplier = 1.0;
// 0 = mediodia, 1 = noche cerrada. Una sola variable en vez de reconstruir el
// "dia"/"rasante" de fuera: el shader solo necesita saber cuanto apagar el
// azul y cuanto encender las estrellas.
uniform float noche_cantidad : hint_range(0.0, 1.0) = 0.0;
uniform float nubes_cantidad : hint_range(0.0, 1.0) = 0.5;
uniform float nubes_velocidad : hint_range(0.0, 0.02) = 0.006;

#include "res://visor/ruido.gdshaderinc"

void sky() {
	float arriba = clamp(EYEDIR.y, -1.0, 1.0);
	vec3 col;
	if (arriba > 0.0) {
		col = mix(horizon_color.rgb, top_color.rgb, pow(arriba, 0.45));

		// NUBES: solo en el hemisferio de arriba, se leen menos cerca del cenit
		// (donde la esfera se ve casi de canto) y desaparecen contra el
		// horizonte para no tapar el degradado del atardecer.
		vec3 deriva = vec3(1.0, 0.0, 0.35) * TIME * nubes_velocidad * 40.0;
		float n = fbm3(EYEDIR * 1.8 + deriva);
		float nubes = smoothstep(0.32, 0.60, n) * nubes_cantidad;
		float banda = smoothstep(0.02, 0.12, arriba) * (1.0 - smoothstep(0.70, 0.98, arriba));
		vec3 color_nube = mix(vec3(0.92, 0.93, 0.97), vec3(1.0), 0.0) * mix(1.0, 0.22, noche_cantidad);
		col = mix(col, color_nube, nubes * banda);

		// ESTRELLAS: una rejilla fina de celdas en la direccion de mirada, una
		// al azar por celda pasa el umbral y "existe". `floor()` sobre EYEDIR
		// da una celda estable por dirección -no parpadean al girar la cámara-.
		if (noche_cantidad > 0.01) {
			vec3 celda = floor(EYEDIR * 340.0);
			float azar = hash13(celda);
			float existe = step(0.9976, azar);
			float titila = 0.55 + 0.45 * sin(TIME * 2.4 + azar * 250.0);
			col += vec3(existe * titila * noche_cantidad) * (1.0 - nubes * banda);
		}

		// EL SOL, como disco y como halo: sin esto el astro que mueve las
		// sombras de toda la ciudad no se veía él mismo en el cielo.
		float sol_dot = dot(EYEDIR, -LIGHT0_DIRECTION);
		float disco = smoothstep(0.9993, 0.9998, sol_dot);
		float halo = pow(max(sol_dot, 0.0), 340.0) * 0.6;
		col += LIGHT0_COLOR * LIGHT0_ENERGY * (disco * 2.2 + halo) * (1.0 - noche_cantidad * 0.7);
	} else {
		// LA TRAMPA QUE YA HABÍA COSTADO UNA RONDA ANTES (ver `ciudad_vista.gd`):
		// el terreno real no cubre toda la esfera de mirada, así que la mayor
		// parte de lo que se ve "por debajo del horizonte" en el hueco entre el
		// complejo y el fondo es justo ESTE color, no césped de verdad. Con un
		// exponente <1 (0.4) el primer intento se iba al color OSCURO
		// (`ground_bottom_color`) casi de inmediato, y como eso cubre la mayor
		// parte del encuadre, se leía como una banda negra enorme -confirmado
		// pintándolo de un magenta de depuración: el "hueco" no es una franja
		// fina, es casi toda la mitad inferior del cielo-. Con un exponente
		// alto se queda en `ground_horizon_color` (el tono de césped) salvo
		// mirando casi derecho hacia abajo, que es lo que de verdad hace falta.
		col = mix(ground_horizon_color.rgb, ground_bottom_color.rgb, pow(-arriba, 3.2));
	}
	COLOR = col * energy_multiplier;
}
