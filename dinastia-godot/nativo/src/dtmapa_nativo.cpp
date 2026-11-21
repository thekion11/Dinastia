// EL MAPA DE LA CABEZA DEL DT, EN C++ (19-11-2026, orden del dueño: «convertir a C++ lo escrito hace mucho»). `PersonajeDtVida._mapa` con `_triangulo` y `_dilatar` (visor/personaje_dt_vida.gd,
// 26-10-2026): rasteriza en el espacio UV de la piel los triángulos de la cabeza (punto del modelo en RGB, alfa 1) y dilata dos pasadas los bordes. Operación a operación: la geometría de
// cada texel en float de 32 (Vector2, Vector3) y los pesos baricéntricos en 64, como GDScript. Imagen RGBAF de 256×256. Gemela GDScript: `_mapa_gd`. `pruebas/probar_nativo_dtmapa.gd` compara los bytes.
#include "dinastia_nativo.h"

#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <cmath>
#include <cstring>
#include <vector>

using namespace godot;

namespace {
constexpr int LADO = 256;

inline void guardar(std::vector<float> &img, int x, int y, float r, float g, float b, float a) {
	float *q = &img[(size_t(y) * LADO + x) * 4];
	q[0] = r;
	q[1] = g;
	q[2] = b;
	q[3] = a;
}

// `_triangulo`.
void triangulo(std::vector<float> &img, const Vector2 &ua, const Vector2 &ub, const Vector2 &uc, const Vector3 &pa, const Vector3 &pb, const Vector3 &pc) {
	const real_t n = real_t(double(LADO));
	const Vector2 a = ua * n, b = ub * n, c = uc * n;
	const real_t area = (b - a).cross(c - a);
	if (std::fabs(double(area)) < 1e-6) {
		return;
	}
	auto acota = [](double v) { return v < 0.0 ? 0 : (v > double(LADO - 1) ? LADO - 1 : int(v)); };
	const double mnx = std::fmin(double(a.x), std::fmin(double(b.x), double(c.x)));
	const double mxx = std::fmax(double(a.x), std::fmax(double(b.x), double(c.x)));
	const double mny = std::fmin(double(a.y), std::fmin(double(b.y), double(c.y)));
	const double mxy = std::fmax(double(a.y), std::fmax(double(b.y), double(c.y)));
	const int x0 = acota(std::floor(mnx)), x1 = acota(std::ceil(mxx));
	const int y0 = acota(std::floor(mny)), y1 = acota(std::ceil(mxy));
	for (int y = y0; y <= y1; y++) {
		for (int x = x0; x <= x1; x++) {
			const Vector2 p(real_t(double(x) + 0.5), real_t(double(y) + 0.5));
			const double w0 = double((b - p).cross(c - p)) / double(area);
			const double w1 = double((c - p).cross(a - p)) / double(area);
			const double w2 = 1.0 - w0 - w1;
			if (w0 < -0.02 || w1 < -0.02 || w2 < -0.02) {
				continue;
			}
			const Vector3 q = pa * real_t(w0) + pb * real_t(w1) + pc * real_t(w2);
			guardar(img, x, y, q.x, q.y, q.z, 1.0f);
		}
	}
}
}  // namespace

// `superficies` = [[vértices, uv, índices], …] de cada superficie de la malla. Devuelve la imagen RGBAF de 256×256, o null si ningún triángulo cuenta (la gemela devuelve null).
Ref<Image> DinastiaNativo::dt_mapa(const Array &superficies) const {
	std::vector<float> img(size_t(LADO) * LADO * 4, 0.0f);
	bool hay = false;
	for (int64_t s = 0; s < superficies.size(); s++) {
		const Array sup = superficies[s];
		const PackedVector3Array v = sup[0];
		const PackedVector2Array uv = sup[1];
		const PackedInt32Array idx = sup[2];
		if (uv.size() != v.size() || idx.is_empty()) {
			continue;
		}
		for (int64_t t = 0; t + 2 < idx.size(); t += 3) {
			const int32_t a = idx[t], b = idx[t + 1], c = idx[t + 2];
			const double my = std::fmin(double(v[a].y), std::fmin(double(v[b].y), double(v[c].y)));
			if (my < 1.5) {
				continue;
			}
			triangulo(img, uv[a], uv[b], uv[c], v[a], v[b], v[c]);
			hay = true;
		}
	}
	Ref<Image> nada;
	if (!hay) {
		return nada;
	}
	// `_dilatar`: dos pasadas de vecinos.
	const int dx4[4] = { 1, -1, 0, 0 };
	const int dy4[4] = { 0, 0, 1, -1 };
	for (int pasada = 0; pasada < 2; pasada++) {
		const std::vector<float> copia = img;
		for (int y = 0; y < LADO; y++) {
			for (int x = 0; x < LADO; x++) {
				if (double(copia[(size_t(y) * LADO + x) * 4 + 3]) > 0.5) {
					continue;
				}
				for (int o = 0; o < 4; o++) {
					const int qx = x + dx4[o], qy = y + dy4[o];
					if (qx < 0 || qy < 0 || qx >= LADO || qy >= LADO) {
						continue;
					}
					const float *c = &copia[(size_t(qy) * LADO + qx) * 4];
					if (double(c[3]) > 0.5) {
						guardar(img, x, y, c[0], c[1], c[2], 0.6f);
						break;
					}
				}
			}
		}
	}
	PackedByteArray bytes;
	bytes.resize(int64_t(img.size() * sizeof(float)));
	std::memcpy(bytes.ptrw(), img.data(), img.size() * sizeof(float));
	return Image::create_from_data(LADO, LADO, false, Image::FORMAT_RGBAF, bytes);
}
