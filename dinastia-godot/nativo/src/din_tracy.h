// TRACY OPCIONAL (5-11-2026). Sin `tracy=yes` en la compilación (lo normal, y TODAS las builds públicas) todo esto
// son macros vacías: cero coste en las zonas (el binario crece unos KB solo por los 4 métodos `tracy_*` de la clase, que no hacen nada). Con `tracy=yes` (herramientas/compilar_nativo.sh tracy)
// cada función nativa abre una zona de Tracy y el cliente Tracy va DENTRO de la biblioteca de la extensión.
// Documento y pasos: docs/04_auditorias/tracy_2026-11-05.md. Las zonas NO cambian ningún resultado.
#pragma once

#ifdef DIN_TRACY
#include <tracy/Tracy.hpp>
#include <tracy/TracyC.h>
#define DIN_ZONA(nombre) ZoneScopedN(nombre)
#define DIN_TRACY_ACTIVO true
#else
#define DIN_ZONA(nombre) ((void)0)
#define DIN_TRACY_ACTIVO false
#endif
