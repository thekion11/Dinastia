class_name DatoTarjeta
extends RefCounted
## M-290 (28-10-2026): EL DATO VIVO DE CADA TARJETA DEL MENÚ (la línea de color bajo la descripción). Antes lo tenían
## ocho tarjetas, en castellano siempre, y el «Correo» contaba todo como sin leer (miraba «leido» y la bandeja guarda
## «leida»). Ahora lo tienen las de gestión que tienen una cifra que decir, y sale traducido. "" = la tarjeta no lleva dato.

## (12-11) POR SITIO, no por nombre: la tarjeta que abre una pantalla concreta (`tab.secc`) toma su dato de aquí aunque le cambien el rótulo
## (al renombrar «Finanzas» y «Mercado» sus tarjetas se quedaron sin dato y nadie lo vio). Las demás siguen por su rótulo.
const POR_SITIO := {"Finanzas.cuentas": "finanzas", "Finanzas.taquilla": "taquilla", "Finanzas.banco": "banco", "Mercado": "mercado",
	"Táctica.pizarra": "táctica", "Partido.previa": "próximo partido", "Clubes.tablas": "ligas y clubes", "Clubes.goleadores": "goleadores",
	"Club.staff": "personal del club", "Gente.personas": "la gente del club", "Redes.redes": "feed de redes", "Enfermería": "enfermería",
	"Libres": "jugadores libres", "Contratos": "contratos", "Calendario": "calendario", "Club.infra": "infra", "Vida.bienestar": "bienestar", "Vida.familia": "familia", "Camarín": "camarín", "Correo": "correo"}

static func de_sub(p: Principal, sub: Dictionary) -> String:
	var sitio := String(sub.get("tab", ""))
	if sub.has("secc"):
		sitio += "." + String(sub["secc"])
	return de(p, String(POR_SITIO.get(sitio, sub.get("label", ""))))

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
		"camarín":
			return Idiomas.t("%d jugadores") % c.plantilla.size()
		"personal del club":   ## (12-11) decía «25 jugadores»: el personal son los puestos del cuerpo técnico, no el plantel
			if m.staff == null:
				return ""
			var con := 0
			for k: String in m.staff.niveles:
				con += 1 if int(m.staff.niveles[k]) > 0 else 0
			return Idiomas.t("%d de %d puestos cubiertos") % [con, m.staff.niveles.size()]
		"mi plantel":
			return Idiomas.t("%d jugadores · media %d") % [c.plantilla.size(), roundi(c.media())]
		"táctica", "pizarra y dibujo":
			return c.tactica.formacion
		"finanzas", "cuentas del club":
			return p._dinero(c.saldo)
		"mercado", "mercado de fichajes":
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
		## (12-11) Más tarjetas con dato: al partir los menús en pantallas, varias quedaron sin su línea de color.
		"taquilla":
			return Idiomas.t("Entrada: %s") % Eco.dinero_euros(c.precio_entrada)
		"banco":
			var deuda := 0
			for pr: Dictionary in (m.banco.prestamos if m.banco != null else []):
				deuda += int(pr.get("deuda", 0))
			return Idiomas.t("Deuda: %s") % p._dinero(deuda) if deuda > 0 else Idiomas.t("sin deuda")
		"bienestar":
			return Idiomas.t("Estrés: %d de 100") % m.vida.estres if m.vida != null else ""
		"familia":
			return Idiomas.t("Familia: %d de 100") % m.vida.familia if m.vida != null else ""
		"infra":
			var hechas := m.obras.construido() if m.obras != null else 0
			return Idiomas.t("%d obras hechas") % hechas if hechas > 0 else Idiomas.t("Sin obras todavía")
		"la gente del club":
			return Idiomas.t("Confianza media: %d") % m.gente.confianza_media() if m.gente != null else ""
		"enfermería":
			var fuera := c.plantilla.filter(func(j: Jugador) -> bool: return j.lesion > 0).size()
			return Idiomas.t("%d lesionados") % fuera if fuera > 0 else Idiomas.t("Nadie en la camilla")
		"jugadores libres":
			return Idiomas.t("%d sin club") % m.libres.size() if not m.libres.is_empty() else ""
		"ligas y clubes":
			var liga := m.liga_de(c)
			return Idiomas.t("%d.º de %d") % [EventosClub.puesto_de(liga, c), liga.clubes.size()] if liga != null else ""
		"próximo partido":
			var cruce := m.proximo_partido()
			if cruce.size() < 2:
				return Idiomas.t("Sin partido esta semana")
			var rival: Club = cruce[1] if cruce[0] == c else cruce[0]
			return (Idiomas.t("En casa: %s") if cruce[0] == c else Idiomas.t("Fuera: %s")) % rival.nombre
		"goleadores":
			var mejor: Jugador = null
			for j: Jugador in c.plantilla:
				if j.goles > 0 and (mejor == null or j.goles > mejor.goles):
					mejor = j
			return Idiomas.t("%s · %d goles") % [mejor.nombre, mejor.goles] if mejor != null else ""
	return ""
