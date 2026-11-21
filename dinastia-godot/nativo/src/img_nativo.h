// AYUDANTES PARA LAS IMÁGENES RGB8 EN C++ (19-11-2026): las mismas conversiones que `Image.get_pixel` / `set_pixel` del motor (byte entre 255; 255 por el canal, truncado y acotado).
// Los usan las funciones de texturas procedimentales (`*_nativo.cpp`), cada una con su gemela GDScript.
#pragma once

#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>

#include <cstdint>

namespace godot {

// Un lienzo RGB8 de ancho × alto, en un buffer de bytes (Image.FORMAT_RGB8).
struct LienzoRGB {
	int64_t ancho;
	int64_t alto;
	PackedByteArray datos;
	LienzoRGB(int64_t a, int64_t h) :
			ancho(a), alto(h) {
		datos.resize(a * h * 3);
		datos.fill(0);
	}
	static uint8_t a_byte(float canal) {
		double v = double(canal) * 255.0;
		v = v < 0.0 ? 0.0 : (v > 255.0 ? 255.0 : v);
		return uint8_t(v);
	}
	// `Image.set_pixel(x, y, c)`.
	void poner(int64_t x, int64_t y, const Color &c) {
		uint8_t *q = datos.ptrw() + (y * ancho + x) * 3;
		q[0] = a_byte(c.r);
		q[1] = a_byte(c.g);
		q[2] = a_byte(c.b);
	}
	// `Image.get_pixel(x, y)` (alfa 1).
	Color leer(int64_t x, int64_t y) const {
		const uint8_t *q = datos.ptr() + (y * ancho + x) * 3;
		return Color(float(double(q[0]) / 255.0), float(double(q[1]) / 255.0), float(double(q[2]) / 255.0), 1.0f);
	}
	// `Image.fill(c)`.
	void llenar(const Color &c) {
		for (int64_t y = 0; y < alto; y++) {
			for (int64_t x = 0; x < ancho; x++) {
				poner(x, y, c);
			}
		}
	}
	// `Image.fill_rect(Rect2i(x0, y0, w, h), c)` (recortado a la imagen).
	void rellenar(int64_t x0, int64_t y0, int64_t w, int64_t h, const Color &c) {
		const int64_t xa = x0 < 0 ? 0 : x0, ya = y0 < 0 ? 0 : y0;
		const int64_t xb = x0 + w > ancho ? ancho : x0 + w, yb = y0 + h > alto ? alto : y0 + h;
		for (int64_t y = ya; y < yb; y++) {
			for (int64_t x = xa; x < xb; x++) {
				poner(x, y, c);
			}
		}
	}
	Ref<Image> imagen() const {
		return Image::create_from_data(ancho, alto, false, Image::FORMAT_RGB8, datos);
	}
};

}  // namespace godot
