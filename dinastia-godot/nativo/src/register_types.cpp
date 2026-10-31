// Registro de la extensión nativa de Dinastía (30-10-2026).
#include "dinastia_nativo.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

static void iniciar(ModuleInitializationLevel nivel) {
	if (nivel != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(DinastiaNativo);
}

static void terminar(ModuleInitializationLevel nivel) {
}

extern "C" {
GDExtensionBool GDE_EXPORT dinastia_nativo_iniciar(GDExtensionInterfaceGetProcAddress p_get_proc_address,
		GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(iniciar);
	init_obj.register_terminator(terminar);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_obj.init();
}
}
