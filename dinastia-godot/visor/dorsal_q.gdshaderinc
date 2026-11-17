// EL DORSAL Y EL NOMBRE EN LA ESPALDA (17-11-2026, punto 7 de `COMPARACION_REFERENCIAS_PARTIDO_2026-11-16.md`). Lo incluye
// `equipacion_q.gdshader`. Antes: siete segmentos de bordes duros (parpadeaban de lejos y se leían como un reloj digital) y sin nombre.
//  · NÚMEROS: tipografía deportiva hecha con distancias con signo (segmentos, arcos y anillos, trazo redondeado) en una caja de
//    0,75 × 1,6 unidades; el borde se suaviza con el tamaño del píxel en la tela (`px`, en las mismas unidades), así que de lejos
//    se funde en vez de parpadear. Ribete de contraste alrededor (`color_num_borde`, alfa = grosor).
//  · NOMBRE: letras de 5 × 7 (A-Z, punto, guion y apóstrofo; las tildes y la Ñ llegan ya pasadas a su letra base desde
//    `DisenosKit.letras_nombre`). Cuando la celda mide menos que un píxel, el nombre se funde en un tono medio (sin ruido).
// Solo ALU en los píxeles de la espalda: ninguna textura ni llamada de dibujo nueva.

const float DQ_TRAZO = 0.095;   // medio grosor del trazo del número (unidades de la caja)

float dq_seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// Arco de radio r desde el ángulo a0 (rad) recorriendo `barrido` en sentido antihorario.
float dq_arco(vec2 p, vec2 c, float r, float a0, float barrido) {
	vec2 q = p - c;
	float t = mod(atan(q.y, q.x) - a0, 6.2831853);
	if (t <= barrido) {
		return abs(length(q) - r);
	}
	vec2 e0 = c + r * vec2(cos(a0), sin(a0));
	vec2 e1 = c + r * vec2(cos(a0 + barrido), sin(a0 + barrido));
	return min(length(p - e0), length(p - e1));
}

float dq_anillo(vec2 p, vec2 c, float r) {
	return abs(length(p - c) - r);
}

float dq_caja(vec2 p, vec2 c, vec2 b, float r) {
	vec2 q = abs(p - c) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// Distancia al trazo del dígito n (0-9); p en la caja (x 0..0,75, y 0..1,6 desde abajo).
float dq_digito(int n, vec2 p) {
	if (n == 0) return abs(dq_caja(p, vec2(0.375, 0.8), vec2(0.265, 0.69), 0.25));
	if (n == 1) return min(dq_seg(p, vec2(0.44, 0.11), vec2(0.44, 1.49)), dq_seg(p, vec2(0.44, 1.49), vec2(0.17, 1.25)));
	if (n == 2) {
		return min(dq_arco(p, vec2(0.375, 1.2), 0.265, -0.7, 3.58),
			min(dq_seg(p, vec2(0.578, 1.03), vec2(0.11, 0.11)), dq_seg(p, vec2(0.11, 0.11), vec2(0.64, 0.11))));
	}
	if (n == 3) {
		return min(min(dq_arco(p, vec2(0.375, 1.22), 0.27, -1.5708, 4.189), dq_arco(p, vec2(0.375, 0.41), 0.30, -2.618, 4.189)),
			dq_seg(p, vec2(0.24, 0.83), vec2(0.375, 0.83)));
	}
	if (n == 4) {
		return min(dq_seg(p, vec2(0.5, 0.11), vec2(0.5, 1.49)),
			min(dq_seg(p, vec2(0.5, 1.49), vec2(0.08, 0.55)), dq_seg(p, vec2(0.08, 0.55), vec2(0.68, 0.55))));
	}
	if (n == 5) {
		return min(min(dq_seg(p, vec2(0.64, 1.49), vec2(0.17, 1.49)), dq_seg(p, vec2(0.17, 1.49), vec2(0.161, 0.676))),
			dq_arco(p, vec2(0.36, 0.44), 0.31, -2.44, 4.71));
	}
	if (n == 6) return min(dq_anillo(p, vec2(0.375, 0.44), 0.27), dq_seg(p, vec2(0.105, 0.5), vec2(0.5, 1.49)));
	if (n == 7) return min(dq_seg(p, vec2(0.11, 1.49), vec2(0.64, 1.49)), dq_seg(p, vec2(0.64, 1.49), vec2(0.25, 0.11)));
	if (n == 8) return min(dq_anillo(p, vec2(0.375, 1.21), 0.22), dq_anillo(p, vec2(0.375, 0.43), 0.27));
	return min(dq_anillo(p, vec2(0.375, 1.16), 0.27), dq_seg(p, vec2(0.645, 1.1), vec2(0.25, 0.11)));
}

// Distancia al número entero (uno o dos dígitos), con la caja centrada en x = 0 y la base en y = 0.
float dq_numero(int n, vec2 p) {
	if (n < 10) {
		return dq_digito(n, p + vec2(0.375, 0.0));
	}
	return min(dq_digito((n / 10) % 10, p + vec2(0.8, 0.0)), dq_digito(n % 10, p - vec2(0.05, 0.0)));
}

// Letras de 5 × 7: una fila por entero (bit 4 = columna izquierda), de arriba abajo. Orden: A-Z, «.», «-», «'».
const int DQ_FUENTE[203] = int[](
	14, 17, 17, 31, 17, 17, 17,   30, 17, 17, 30, 17, 17, 30,   14, 17, 16, 16, 16, 17, 14,   30, 17, 17, 17, 17, 17, 30,
	31, 16, 16, 30, 16, 16, 31,   31, 16, 16, 30, 16, 16, 16,   14, 17, 16, 23, 17, 17, 15,   17, 17, 17, 31, 17, 17, 17,
	14, 4, 4, 4, 4, 4, 14,        7, 2, 2, 2, 2, 18, 12,        17, 18, 20, 24, 20, 18, 17,   16, 16, 16, 16, 16, 16, 31,
	17, 27, 21, 21, 17, 17, 17,   17, 17, 25, 21, 19, 17, 17,   14, 17, 17, 17, 17, 17, 14,   30, 17, 17, 30, 16, 16, 16,
	14, 17, 17, 17, 21, 18, 13,   30, 17, 17, 30, 20, 18, 17,   15, 16, 16, 14, 1, 1, 30,     31, 4, 4, 4, 4, 4, 4,
	17, 17, 17, 17, 17, 17, 14,   17, 17, 17, 17, 17, 10, 4,    17, 17, 17, 21, 21, 21, 10,   17, 17, 10, 4, 10, 17, 17,
	17, 17, 10, 4, 4, 4, 4,       31, 1, 2, 4, 8, 16, 31,       0, 0, 0, 0, 0, 12, 12,        0, 0, 0, 14, 0, 0, 0,
	4, 4, 8, 0, 0, 0, 0
);

// ¿Está encendida la celda (cx 0..4, fila 0..6 desde arriba) de la letra g (1..29; 0 = espacio)?
float dq_letra(int g, int cx, int fila) {
	if (g <= 0 || g > 29 || cx < 0 || cx > 4 || fila < 0 || fila > 6) {
		return 0.0;
	}
	return float((DQ_FUENTE[(g - 1) * 7 + fila] >> (4 - cx)) & 1);
}
