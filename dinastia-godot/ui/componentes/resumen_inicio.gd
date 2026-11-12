class_name ResumenInicio
extends RefCounted
## LO QUE EL MENÚ CENTRAL DEL PES 2020 TIENE Y EL NUESTRO NO (12-11-2026, referencia del dueño: foto de la Master League en su Drive,
## `PLAN_GENERAL.md` punto 14). Comparado con la pantalla real: la FILA DE ESCUDOS de los próximos partidos ya existía (`FilaProximos`)
## y la TABLA de la liga ya está entera en la columna izquierda (una tabla corta en el centro la repetía: se quitó el mismo día).
## Lo que faltaba de verdad es el contador de SEGUIDORES (en nuestro juego, los socios), que va en la línea de la cabecera.
## Solo usa `Club` (nada de la ciudad ni del estadio: regla de la memoria del menú).

## «  ·  20.187 socios» para la cabecera, o vacío si el club no tiene socios.
static func socios_txt(c: Club) -> String:
	if c == null or c.socios <= 0:
		return ""
	return "  ·  " + Idiomas.t("%s socios") % miles(c.socios)

static func miles(x: int) -> String:
	var s := str(absi(x))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if x < 0 else "") + s + out
