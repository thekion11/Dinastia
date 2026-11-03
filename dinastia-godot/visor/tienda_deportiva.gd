class_name TiendaDeportiva
extends RefCounted
## LA TIENDA DEPORTIVA DE LA PLAZA (M-188, 3-11-2026): un puesto bajo los soportales, junto al banco, donde el DT compra ropa y balones con su cartera (efectivo, tarjeta o PIN,
## como en la gasolinera) y lo comprado se guarda en su ropero (`RoperoDT`, dentro de `Roles`). E ante el mostrador abre la caja (`PanelTienda`); las prendas ya compradas salen con ✔.
static func montar(ex: CiudadExpansion, x: float, y: float, z_pared: float) -> void:
	var b := ex.b
	var madera := b._mat_simple(Color(0.5, 0.34, 0.2), 0.6)
	var verde := b._mat_simple(Color(0.12, 0.45, 0.25), 0.5)
	var blanco := b._mat_simple(Color(0.95, 0.95, 0.93), 0.5)
	b._caja_en(Vector3(x, y + 0.55, z_pared + 3.0), Vector3(3.2, 1.1, 0.8), madera)             ## mostrador
	b._caja_en(Vector3(x, y + 1.5, z_pared + 2.6), Vector3(3.0, 0.9, 0.5), blanco)              ## camisetas dobladas
	b._caja_en(Vector3(x, y + 3.35, z_pared + 1.75), Vector3(5.4, 1.2, 0.25), verde)             ## panel del rótulo
	CartelFachada.poner(b, Vector3(x, y + 3.35, z_pared + 1.95), "DEPORTES", Color(1, 1, 1), 22)
	b.puntos_clic.append({"k": "deportes_%d" % (absi(hash(Vector2(x, z_pared))) % 100000), "n": Idiomas.t("Tienda deportiva"),
		"pos": Vector3(x, 0.0, z_pared + 4.6), "estado": "ciudad", "radio": 9.0, "alcance": 2.5})

## El gancho de la E (lo llama `ComercioCiudad`).
static func servicio(e, k: String) -> bool:
	if not k.begins_with("deportes_"):
		return false
	return e.vida != null and abrir(e.vida, k)

static func abrir(vc: VidaCiudad, k: String) -> bool:
	if vc.mundo.roles == null:
		return false
	if is_instance_valid(vc._panel_cajero):
		return true
	var pos := vc.expl.cuerpo.position
	for pc: Dictionary in vc.expl.cb.puntos_clic:
		if String(pc.get("k", "")) == k:
			pos = pc["pos"]
	var roles = vc.mundo.roles
	var saldo := func() -> String:
		var r := RoperoDT.resumen(roles.ropero)
		return Idiomas.t("En el bolsillo") + ": " + Eco.dinero_euros(float(roles.cartera.efectivo)) + ("  ·  " + Idiomas.t("Tu ropero") + ": " + r if r != "" else "")
	var comprar := func(it: Dictionary) -> String:
		if not RoperoDT.puede(roles.ropero, String(it["inv"])):
			return Idiomas.t("Ya tienes %s.") % Idiomas.t(String(RoperoDT.articulo(String(it["inv"]))["nombre"]))
		return PagoCiudad.comprar(vc, it)
	vc._panel_cajero = PanelTienda.abrir(vc.expl._capa, Idiomas.t("Tienda deportiva"), RoperoDT.surtido(roles.ropero), comprar, saldo, pos, vc.expl.cuerpo)
	return true
