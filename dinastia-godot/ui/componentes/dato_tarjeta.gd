class_name DatoTarjeta
extends RefCounted
## M-290 (28-10-2026): EL DATO VIVO DE CADA TARJETA DEL MENÚ (la línea de color bajo la descripción). Antes lo tenían
## ocho tarjetas, en castellano siempre, y el «Correo» contaba todo como sin leer (miraba «leido» y la bandeja guarda
## «leida»). Ahora lo tienen las de gestión que tienen una cifra que decir, y sale traducido. "" = la tarjeta no lleva dato.

static func de(p: Principal, etiqueta: String) -> String:
	var m := p.mundo
	if m == null or m.mi_club() == null:
		return ""
	var c := m.mi_club()
	var lg := m.logros
	match etiqueta.to_lower():
		"correo":
			var n := 0
			for x: Dictionary in p.get("_bandeja"):
				if not bool(x.get("leida", false)):
					n += 1
			return Idiomas.t("%d sin leer") % n if n > 0 else Idiomas.t("Al día")
		"vitrina", "historia del club":
			return Idiomas.t("%d títulos") % (m.roles.trofeos.size() if m.roles != null else 0)
		"hinchada y socios":
			return Idiomas.t("%s socios") % p._miles(c.socios if c.socios > 0 else c.estadio_aforo)
		"diseño del estadio", "estadio", "infraestructura":
			return Idiomas.t("%s butacas") % p._miles(c.estadio_aforo)
		"camarín", "personal del club":
			return Idiomas.t("%d jugadores") % c.plantilla.size()
		"mi plantel":
			return Idiomas.t("%d jugadores · media %d") % [c.plantilla.size(), roundi(c.media())]
		"táctica":
			return c.tactica.formacion
		"finanzas":
			return p._dinero(c.saldo)
		"mercado":
			var tr := 0
			for j: Jugador in c.plantilla:
				if j.transferible:
					tr += 1
			return Idiomas.t("%d en venta") % tr if tr > 0 else Idiomas.t("Caja: %s") % p._dinero(c.saldo)
		"contratos":
			var acaban := 0
			for j: Jugador in c.plantilla:
				if j.anios_contrato <= 1:
					acaban += 1
			return Idiomas.t("%d acaban este año") % acaban
		"calendario":
			return Idiomas.t("Semana %d · %d") % [m.semana, m.anio]
		"feed de redes":
			return Idiomas.t("%s seguidores") % p._miles(m.prensa.seguidores) if m.prensa != null else ""
		"mi carrera":
			return Idiomas.t(m.roles.nombre) if m.roles != null else ""
		"logros":
			return Idiomas.t("%d conseguidos") % lg.desbloqueados.size() if lg != null else ""
		"récords":
			return Idiomas.t("Invicto máximo: %d") % int(lg.rachas.get("invicto_max", 0)) if lg != null else ""
		"rivales":
			return Idiomas.t("%d rivales enfrentados") % lg.h2h.size() if lg != null else ""
		"premios":
			return Idiomas.t("%d galas") % lg.premios.size() if lg != null else ""
	return ""
