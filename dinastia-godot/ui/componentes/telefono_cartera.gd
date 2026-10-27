class_name TelefonoCartera
extends RefCounted
## LAS FILAS DE LA CARTERA en la app «Banco» del móvil (27-10-2026, pieza A de `PLAN_DEL_LUNES.md` §2.2h): efectivo del bolsillo, estado de la tarjeta
## y los últimos movimientos. Cada fila es [texto, valor, color] como las de `Telefono._banco`. Aparte para no pasar de 450 líneas en `telefono.gd`.
const ULTIMOS := 4

static func filas(m: Mundo) -> Array:
	var r: Array = []
	if m.roles == null:
		return r
	var c: CarteraDT = m.roles.cartera
	r.append(["👛 Efectivo en el bolsillo", Eco.dinero_euros(float(c.efectivo)), Tema.TEXTO])
	if c.bloqueada:
		r.append(["💳 Tarjeta", Idiomas.t("bloqueada: pasa por el banco"), Color("e5534b")])
	else:
		var queda := maxi(0, CarteraDT.LIMITE_TARJETA - c.gastado_dia)
		r.append(["💳 Tarjeta", Idiomas.t("activa · te quedan %s hoy") % Eco.dinero_euros(float(queda)), Tema.BIEN])
	if c.pin_inicial:
		r.append(["🔐 PIN", Idiomas.t("es el de fábrica (0000): cámbialo en un cajero"), Tema.ORO])
	## Los últimos movimientos, el más nuevo arriba.
	for i in range(c.movimientos.size() - 1, maxi(-1, c.movimientos.size() - 1 - ULTIMOS), -1):
		var mv: Dictionary = c.movimientos[i]
		var importe := int(mv["importe"])
		r.append(["🧾 " + Idiomas.t(String(mv["concepto"])), ("+" if importe > 0 else "") + Eco.dinero_euros(float(importe)), Tema.BIEN if importe > 0 else Tema.SUAVE])
	## El álbum de peluches de las recreativas y sus logros.
	var pe: Peluches = m.roles.peluches
	r.append(["🧸 " + Idiomas.t("Álbum de peluches"), Idiomas.t("%d de %d") % [pe.distintos(), Peluches.PELUCHES.size()], Tema.TEXTO])
	for l: String in pe.logros:
		r.append(["🏆 " + Peluches.nombre_logro(l), "", Tema.ORO])
	return r
