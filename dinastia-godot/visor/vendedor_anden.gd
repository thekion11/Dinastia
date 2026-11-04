class_name VendedorAnden
extends RefCounted
## EL VENDEDOR DEL ANDÉN (M-180, 28-10-2026): una empanada caliente por 3 € que quita algo de hambre y da algo de energía; la cartera cobra como en la expendedora.

static func usar(vida: VidaCiudad) -> bool:
	var mundo: Mundo = vida.mundo
	if mundo.roles == null or mundo.necesidades == null:
		return false
	var dia := CarteraDT.clave_dia(mundo.anio, mundo.semana, mundo.reloj.dia)
	var r := mundo.roles.cartera.cobrar(mundo.roles, 3, "Empanada del andén", dia)
	if String(r["error"]) != "":
		vida._decir(Idiomas.t("Vendedor del andén"), CarteraDT.texto_error(String(r["error"]), 3))
		return true
	mundo.necesidades.animar(6)
	mundo.necesidades.picar(25)
	vida._decir(Idiomas.t("Vendedor del andén"), Idiomas.t("Una empanada caliente por %d € (%s). «¡Buen provecho, míster!»") % [3, Idiomas.t(String(r["via"]))])
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	return true
