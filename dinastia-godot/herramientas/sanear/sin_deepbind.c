// Para herramientas/sanear_nativo.sh (17-11-2026): Godot abre las extensiones con RTLD_DEEPBIND, que el runtime de ASan no admite
// (https://github.com/google/sanitizers/issues/611). Esta capa, precargada ANTES de libasan, quita esa bandera y sigue con el dlopen de siempre.
#define _GNU_SOURCE
#include <dlfcn.h>

void *dlopen(const char *archivo, int banderas) {
	static void *(*real)(const char *, int) = 0;
	if (!real) {
		real = (void *(*)(const char *, int))dlsym(RTLD_NEXT, "dlopen");
	}
	return real(archivo, banderas & ~RTLD_DEEPBIND);
}
