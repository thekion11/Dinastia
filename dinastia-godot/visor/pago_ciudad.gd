class_name PagoCiudad
## LOS COBROS DEL COMERCIO DE LA CIUDAD (tienda, gasolinera, expendedora) con la cartera del DT (U6, 3-11): efectivo y, si no alcanza, tarjeta sin contacto
## hasta `CarteraDT.SIN_PIN` €; por encima la tarjeta pide el PIN y aquí se abre `PanelPagoPin` (el mismo teclado del cajero) en vez de negarse. Las reglas
## siguen en `CarteraDT`; esto solo une cartera, panel y efectos del producto. Sin azar.

## Cobra `importe`. Con `pin` ya validado paga con la tarjeta (`pagar_tarjeta`); sin él, `CarteraDT.cobrar`. {error, via}.
static func cobrar(vc: VidaCiudad, importe: int, concepto: String, dia: int, pin := "") -> Dictionary:
	var c := vc.mundo.roles.cartera
	if pin == "":
		return c.cobrar(vc.mundo.roles, importe, concepto, dia)
	var e := c.pagar_tarjeta(vc.mundo.roles, importe, concepto, pin, dia)
	if e == "":
		c.pago_con_tarjeta.emit(importe, concepto)
	return {"error": e, "via": "tarjeta" if e == "" else ""}

## Abre el teclado del PIN para pagar `importe` (`concepto`); con el PIN bueno llama a `al_pin(pin)`. Devuelve el aviso para la caja.
static func pedir_pin(vc: VidaCiudad, importe: int, concepto: String, al_pin: Callable) -> String:
	if is_instance_valid(vc._panel_pin):
		return ""
	vc._panel_pin = PanelPagoPin.abrir(vc.expl._capa, vc.mundo.roles.cartera, importe, concepto, al_pin, vc.expl.cuerpo.position, vc.expl.cuerpo)
	return Idiomas.t("Son %d €: teclea el PIN de la tarjeta.") % importe

## Un artículo (tienda o expendedora): lo cobra y, si va bien, baja el hambre y sube la energía. Devuelve el mensaje traducido; si pide PIN, lo abre y el producto llega al validarlo.
static func comprar(vc: VidaCiudad, it: Dictionary, pin := "") -> String:
	var dia := CarteraDT.clave_dia(vc.mundo.anio, vc.mundo.semana, vc.mundo.reloj.dia)
	var importe := int(it["precio"])
	var r: Dictionary
	if bool(it.get("con_pin", false)) and pin == "":   ## «Pagar con tarjeta y PIN» en la caja de la tienda: se mira que la tarjeta pueda y se pide el PIN
		r = {"error": vc.mundo.roles.cartera.puede_cobrar_con_pin(vc.mundo.roles, importe, dia), "via": ""}
		if String(r["error"]) == "":
			r["error"] = "pin"
	else:
		r = cobrar(vc, importe, String(it["nombre"]), dia, pin)
	if String(r["error"]) == "pin":
		return pedir_pin(vc, importe, String(it["nombre"]), func(p: String) -> void: vc._decir(Idiomas.t("Pago con tarjeta"), comprar(vc, it, p)))
	if String(r["error"]) != "":
		return CarteraDT.texto_error(String(r["error"]), importe)
	if it.has("inv"):
		RoperoDT.agregar(vc.mundo.roles.ropero, String(it["inv"]))   ## M-188: lo comprado va al ropero (se guarda con la partida)
	if vc.mundo.necesidades != null:
		vc.mundo.necesidades.picar(int(it.get("hambre", 0)))
		vc.mundo.necesidades.animar(int(it.get("energia", 0)))
	Sonido.toca("clic", Sonido.Bus.EFECTOS)
	return Idiomas.t("%s por %d € (%s).") % [Idiomas.t(String(it["nombre"])), importe, Idiomas.t(String(r["via"]))]
