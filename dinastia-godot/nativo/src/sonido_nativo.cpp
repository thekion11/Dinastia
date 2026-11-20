// LA SÍNTESIS DEL SONIDO, EN C++ (19-11-2026, orden del dueño: «reconvertir a C++ el código que no se ha tocado hace mucho»).
// Las cuatro primitivas de `nucleo/sonido_p1.gd` (`_tono_gd`, `_ruido_gd`, `_mezclar_gd`, `_a_wav_gd`), copiadas operación a operación:
// cálculo en float de 64 bits (el `float` de GDScript) y guardado en float de 32 (PackedFloat32Array), como allí. Las recetas
// (`_receta_<nombre>`) siguen en GDScript y llaman a estas. `pruebas/probar_nativo_sonido.gd` compara los 214 × 4 bancos byte a byte.
#include "dinastia_nativo.h"
#include "pcg32_nativo.h"

#include <cmath>

using namespace godot;

namespace {
constexpr double TAU_GD = 6.2831853071795864769252867666;

// `clampf`, `minf` y `lerpf` de GDScript (Math::clamp, MIN y Math::lerp del motor).
inline double clampf_gd(double v, double lo, double hi) {
	return v < lo ? lo : (v > hi ? hi : v);
}
inline double minf_gd(double a, double b) {
	return a < b ? a : b;
}
inline double lerpf_gd(double a, double b, double t) {
	return a + (b - a) * t;
}
}  // namespace

// `_tono_gd`: tono con caída exponencial. forma: 0 = seno (y cualquier otra), 1 = cuadrada, 2 = sierra.
PackedFloat32Array DinastiaNativo::son_tono(double hz, double dur, double vol, int64_t forma, int64_t frecuencia) const {
	const int64_t n = int64_t(dur * double(frecuencia));
	PackedFloat32Array m;
	if (n <= 0) {
		return m;
	}
	m.resize(n);
	float *pm = m.ptrw();
	const double paso = hz * TAU_GD / double(frecuencia);
	for (int64_t i = 0; i < n; i++) {
		const double t = double(i) / double(n);
		const double env = std::exp(-5.0 * t);
		const double f = double(i) * paso;
		double s;
		if (forma == 1) {
			s = std::sin(f) >= 0.0 ? 1.0 : -1.0;
		} else if (forma == 2) {
			s = std::fmod(f / TAU_GD, 1.0) * 2.0 - 1.0;
		} else {
			s = std::sin(f);
		}
		pm[i] = float(s * env * vol);
	}
	return m;
}

// `_ruido_gd`: ruido con barrido de un filtro paso bajo de un polo, con su generador sembrado igual que el GDScript.
PackedFloat32Array DinastiaNativo::son_ruido(double dur, double f0, double f1, double vol, int64_t frecuencia) const {
	const int64_t n = int64_t(dur * double(frecuencia));
	PackedFloat32Array m;
	if (n <= 0) {
		return m;
	}
	m.resize(n);
	float *pm = m.ptrw();
	double estado = 0.0;
	Pcg32 rng;
	rng.seed(uint64_t(int64_t(f0) * 7919 + int64_t(f1)));
	for (int64_t i = 0; i < n; i++) {
		const double t = double(i) / double(n);
		const double corte = lerpf_gd(f0, f1, t);
		const double a = clampf_gd(corte / double(frecuencia) * 6.28, 0.02, 0.95);
		estado += a * (double(rng.randf_range(-1.0f, 1.0f)) - estado);
		const double env = minf_gd(t / 0.12, 1.0) * std::exp(-3.2 * t);
		pm[i] = float(estado * env * vol);
	}
	return m;
}

// `_mezclar_gd`: devuelve `destino` con `fuente` sumada desde `retraso` segundos (alargado si la capa acaba después). El GDScript copia
// el resultado sobre su `destino` (los arreglos empaquetados se pasan por referencia en GDScript, no a través de la extensión).
PackedFloat32Array DinastiaNativo::son_mezclar(const PackedFloat32Array &destino, const PackedFloat32Array &fuente, double retraso, int64_t frecuencia) const {
	const int64_t off = int64_t(retraso * double(frecuencia));
	if (off < 0) {
		return PackedFloat32Array();   // nunca pasa (los retrasos son ≥ 0): el llamador usa entonces el GDScript
	}
	PackedFloat32Array r = destino;
	const int64_t nf = fuente.size();
	if (off + nf > r.size()) {
		r.resize(off + nf);
	}
	float *pr = r.ptrw();
	const float *pf = fuente.ptr();
	for (int64_t i = 0; i < nf; i++) {
		const int64_t k = i + off;
		pr[k] = float(clampf_gd(double(pr[k]) + double(pf[i]), -1.0, 1.0));
	}
	return r;
}

// `_a_wav_gd`: las muestras a 16 bits con signo, en little endian (`encode_s16`).
PackedByteArray DinastiaNativo::son_a_16(const PackedFloat32Array &m) const {
	const int64_t n = m.size();
	PackedByteArray datos;
	datos.resize(n * 2);
	if (n == 0) {
		return datos;
	}
	uint8_t *pd = datos.ptrw();
	const float *pm = m.ptr();
	for (int64_t i = 0; i < n; i++) {
		const int64_t v = int64_t(clampf_gd(double(pm[i]), -1.0, 1.0) * 32767.0);
		const uint16_t u = uint16_t(int16_t(v));
		pd[i * 2] = uint8_t(u & 0xff);
		pd[i * 2 + 1] = uint8_t(u >> 8);
	}
	return datos;
}
