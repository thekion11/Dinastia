// El núcleo del público de la textura de grada (`publico_nativo.cpp`), compartido con `grada_nativo.cpp`.
#pragma once

#include "img_nativo.h"
#include "pcg32_nativo.h"

namespace godot {
void pintar_publico_interno(LienzoRGB &lz, int64_t w, int64_t h, const Color &a1, const Color &a2, double lleno, Pcg32 &rng);
}
