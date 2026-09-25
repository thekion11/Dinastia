class_name Previa
extends RefCounted
## Lo que se sabe ANTES de que ruede la pelota: quién pita, quién dirige
## enfrente, cómo se miden las dos plantillas y qué dicen las casas de
## apuestas. `vPrevia()` del HTML.
##
## Todo lo de aquí es DERIVADO: no guarda estado, no se guarda en la partida y
## no cambia nada del mundo. Dos llamadas con los mismos datos dan lo mismo,
## que es justo lo que se espera de una previa -si el árbitro cambiara cada vez
## que repintas la pantalla, no sería un árbitro, sería un sorteo.

## El árbitro del partido. Sale del hash de (semana, rival), no de un sorteo:
## así es el mismo durante toda la semana por mucho que se repinte, pero cambia
## de una jornada a la siguiente. `arbitroDe(P)` del HTML.
static func arbitro_de(rival_id: String, semana: int) -> Dictionary:
	var lista: Array = Datos.tabla("ARBITROS")
	var descripciones: Dictionary = Datos.tabla("ARB_D")
	if lista == null or lista.is_empty():
		return {"nombre": "el árbitro", "perfil": "", "descripcion": ""}
	var suma := 0
	for i in rival_id.length():
		suma += rival_id.unicode_at(i)
	var h: int = (semana * 31 + suma) & 0x7FFFFFFF
	var fila: Array = lista[h % lista.size()]
	var perfil := String(fila[1])
	return {
		"nombre": Nombres.de_tabla(String(fila[0])),
		"perfil": perfil,
		"descripcion": String(descripciones.get(perfil, "")) if descripciones != null else "",
	}

## El entrenador rival. Sale del hash de SU id -no de la semana-, así que un
## club tiene siempre el mismo DT: es parte de su identidad, como su escudo.
## `dtDe(clubId)` del HTML.
static func dt_de(c: Club) -> Dictionary:
	var estilos: Dictionary = Datos.tabla("DT_ESTILOS")
	if c == null or estilos == null or estilos.is_empty():
		return {"nombre": "su entrenador", "estilo": "", "descripcion": ""}
	var h := 5
	for i in c.id.length():
		h = (h * 23 + c.id.unicode_at(i)) & 0x7FFFFFFF
	var claves: Array = estilos.keys()
	var estilo := String(claves[h % claves.size()])
	## Los nombres salen de las mismas bolsas por país que usa el generador de
	## futbolistas: un DT italiano no puede llamarse como un chileno.
	var pools: Dictionary = Datos.tabla("POOLS_EU")
	var nombres: Array = []
	var apellidos: Array = []
	if pools != null and pools.has(c.pais):
		var par: Array = pools[c.pais]
		nombres = par[0]
		apellidos = par[1]
	elif c.pais == "BRA":
		nombres = Datos.tabla("NOMBRES_BRA")
		apellidos = Datos.tabla("APELLIDOS_BRA")
	else:
		nombres = Datos.tabla("NOMBRES_EXT")
		apellidos = Datos.tabla("APELLIDOS_EXT")
	if nombres == null or nombres.is_empty() or apellidos == null or apellidos.is_empty():
		return {"nombre": "su entrenador", "estilo": estilo, "descripcion": String(estilos.get(estilo, ""))}
	var inicial := String(nombres[h % nombres.size()]).substr(0, 1)
	var apellido := Nombres.limpiar(String(apellidos[(h >> 3) % apellidos.size()]))
	return {
		"nombre": "%s. %s" % [inicial, apellido],
		"estilo": estilo,
		"descripcion": String(estilos.get(estilo, "")),
	}

## Las cuotas de la casa de apuestas. `cuotasPartido()` del HTML: dos Poisson
## -una por equipo- sobre los goles esperados, y de ahí la probabilidad de cada
## resultado.
##
## Los goles esperados salen de la MISMA fórmula que usa el motor para decidir
## si hay llegada (`Partido._probabilidad()`, con sus mismas constantes): si se
## calcularan aparte, las cuotas dirían una cosa y el partido haría otra.
static func cuotas(f_mi: Dictionary, f_rival: Dictionary, de_local: bool) -> Dictionary:
	var bono_mi := 1.08 if de_local else 0.94
	var bono_rival := 0.94 if de_local else 1.08
	var lam_mi := _goles_esperados(float(f_mi["ata"]), float(f_rival["def"]), bono_mi)
	var lam_rival := _goles_esperados(float(f_rival["ata"]), float(f_mi["def"]), bono_rival)
	var d_mi := _poisson(lam_mi)
	var d_rival := _poisson(lam_rival)
	var p_gano := 0.0
	var p_empate := 0.0
	var p_pierdo := 0.0
	for a in d_mi.size():
		for b in d_rival.size():
			var p: float = d_mi[a] * d_rival[b]
			if a > b:
				p_gano += p
			elif a == b:
				p_empate += p
			else:
				p_pierdo += p
	var total := maxf(p_gano + p_empate + p_pierdo, 0.0001)
	p_gano /= total
	p_empate /= total
	p_pierdo /= total
	return {
		"p_gano": p_gano, "p_empate": p_empate, "p_pierdo": p_pierdo,
		"cuota_gano": _cuota(p_gano), "cuota_empate": _cuota(p_empate), "cuota_pierdo": _cuota(p_pierdo),
	}

## OJO CON ESTO, que es la trampa nº1 del proyecto reapareciendo en sitio
## nuevo: `BASE_ATAQUE * (ata/reparto)^EXPONENTE` NO da goles, da **llegadas al
## área**. Solo el 30% termina dentro (`Partido.CONVERSION`). El HTML calcula
## sus cuotas sin ese 30% -y por eso le salen mal-: con dos equipos decentes
## los dos lambdas se iban por encima del tope de 5,5, se quedaban los dos
## clavados ahí, y las probabilidades se aplastaban hacia el 50-50. Medido:
## un rep 88 contra un rep 67 daba 49% contra 50% a favor del PEOR.
##
## Multiplicando por la conversión, lambda pasa a ser goles esperados de
## verdad -los mismos ~1,3 por equipo que produce el motor- y las cuotas
## vuelven a decir lo que el partido va a hacer.
static func _goles_esperados(ata: float, def_rival: float, bono: float) -> float:
	var reparto: float = maxf((ata + def_rival) / Partido.REPARTO, 0.001)
	var llegadas := float(Partido.MINUTOS) * Partido.BASE_ATAQUE * pow(ata / reparto, Partido.EXPONENTE) * bono
	return clampf(llegadas * Partido.CONVERSION, 0.05, 5.5)

## La distribución de Poisson hasta 8 goles, que es de sobra: la novena
## posibilidad pesa menos que la centésima parte de un punto porcentual.
static func _poisson(lam: float) -> Array[float]:
	var p: Array[float] = [exp(-lam)]
	for k in range(1, 9):
		p.append(p[k - 1] * lam / float(k))
	return p

## El margen de la casa: 1.07 en vez de 1.00, que es de donde sale su ganancia.
static func _cuota(p: float) -> float:
	return maxf(1.03, 1.07 / maxf(p, 0.01))
