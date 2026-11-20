class_name ProbarNativoNuevas
extends RefCounted
## (20-11-2026) Agregador de las pruebas de los portes a C++ del 19-11 (cada una compara la extensión con su gemela GDScript, byte a byte). Devuelve {fallos, textos} juntos.
static func probar(nat: Object) -> Dictionary:
	var fallos: Array = []
	var textos: Array = []
	for r: Dictionary in [ProbarNativoCarrera.probar(nat), ProbarNativoRopa.probar(nat), ProbarNativoCara.probar(nat), ProbarNativoPelo.probar(nat), ProbarNativoEspejo.probar(nat),
			ProbarNativoAsfalto.probar(nat), ProbarNativoTexturas.probar(nat), ProbarNativoKit.probar(nat), ProbarNativoPublico.probar(nat), ProbarNativoDtMapa.probar(nat)]:
		fallos.append_array(r["fallos"])
		textos.append_array(r["textos"])
	return {"fallos": fallos, "textos": textos}
