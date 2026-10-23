class_name Cantera
extends "res://nucleo/cantera_p3.gd"
## (Parte 4 de 4 de `cantera.gd`.)

## Responde al representante. `op` es "a" o "b". Devuelve {titulo, cuerpo}.
##
## No hay opción neutra: las dos ramas mueven algo. Decirle que no a un agente
## con media plantilla en la cartera tiene precio, y decirle que sí también.
##
## `f` (fase 4, mini-juego de la mesa, ver `MesaAgente`): la parte de la
## exigencia que se pactó, 0..1. `se_fue`: se levantó de la mesa sin trato,
## que es un no con una pizca más de rencor.
func resolver_agente(op: String, f: float = 1.0, se_fue: bool = false) -> Dictionary:
	var m := _mundo()
	if exigencia.is_empty() or m == null or m.mi_club() == null:
		exigencia = {}
		return {}
	var mio := m.mi_club()
	var acepta := op == "a"
	var nombre := String(exigencia.get("agente", ""))
	var tipo := String(exigencia.get("tipo", ""))
	var cuerpo := ""
	f = clampf(f, 0.0, 1.0)
	if se_fue:
		_mover_confianza(nombre, -1)
	match tipo:
		"canterano":
			if acepta and mio.plantilla.size() >= TOPE_PLANTEL:
				## Aceptar sin sitio dejaría al agente contento y al chico en
				## ninguna parte. Se dice que no cabe y se paga como un no.
				_mover_confianza(nombre, -1)
				cuerpo = "Le dijiste que sí, pero el plantel tiene %d fichas y no cabe nadie más. %s se lo tomó como una excusa." % [
					mio.plantilla.size(), nombre]
			elif acepta:
				var grupo := String(Azar.uno(["DEF", "MED", "DEL"]))
				var jov := m.crear_jugador(mio, grupo, demarcacion_de(grupo),
					Azar.ent(17, 19), mio.rep - 16 + Azar.ent(0, 8))
				_ficha(jov.id)["camada"] = m.anio
				jov.dorsal = _dorsal_libre(mio)
				mio.plantilla.append(jov)
				if f < 1.0:
					jov.sueldo = maxi(1, int(round(float(jov.sueldo) * f)))
				_mover_confianza(nombre, 2 if f >= 0.8 else 1)
				cuerpo = "Fichaste a %s (%d años, media %d, proyección %d). %s ahora te debe una." % [
					jov.nombre, jov.edad, jov.ovr, jov.pot, nombre]
			else:
				_mover_confianza(nombre, -2)
				_castigar_clientes(m, Azar.ent(4, 10))
				cuerpo = "Le dijiste que no. Sus representados amanecieron con la moral por el piso."
		"mejora":
			var j := _jugador(mio, String(exigencia.get("pid", "")))
			if acepta and j != null:
				j.sueldo = int(round(float(j.sueldo) * (1.0 + 0.3 * f)))
				j.cambiar_moral(int(round(14.0 * f)), "Cantera")
				j.anios_contrato = maxi(j.anios_contrato, 3)
				_mover_confianza(nombre, 1 if f >= 0.6 else 0)
				## El resto del vestuario mira de reojo la escala salarial: no es
				## un castigo aleatorio, es lo que pasa cuando uno cobra más y los
				## de su nivel se enteran.
				for x in mio.plantilla:
					if f > 0.6 and x.id != j.id and x.ovr >= j.ovr - 3:
						x.cambiar_moral(-(Azar.ent(1, 5)), "Cantera")
				cuerpo = "%s firma la mejora. El resto del vestuario mira de reojo la escala salarial." % j.nombre
			else:
				_mover_confianza(nombre, -2)
				_castigar_clientes(m, Azar.ent(5, 12))
				cuerpo = "Aguantaste. Sus representados rinden con desgana y la prensa ya habla de la interna."
		"comision":
			if acepta:
				var coste := int(round(float(Eco.escalar(float(mio.rep) * 2200.0, float(mio.rep))) * f))
				mio.mover_saldo(-coste)
				movimiento.emit("Gastos de intermediación (sin detalle)", -coste)
				_mover_confianza(nombre, maxi(1, int(round(3.0 * f))))
				turbio += 1
				cuerpo = "Pagaste. %s te abre la puerta grande… y ahora sabe algo de ti." % nombre
				## Tres pagos turbios y la cosa se filtra. No es seguro: es una
				## moneda al aire cada vez, que es lo que hace que se siga jugando.
				if turbio >= 3 and Azar.suerte(0.5):
					if m.directiva != null:
						m.directiva.mover_confianza(-14, "pagos irregulares a representantes")
					cuerpo += " Alguien filtró los pagos: se abrió una investigación federativa."
			else:
				_mover_confianza(nombre, -3)
				if m.roles != null:
					m.roles.sumar_prestigio(3)
				cuerpo = "Lo denunciaste ante el directorio. Tu reputación limpia sube, pero %s te va a cerrar puertas." % nombre
		_:
			if acepta:
				_mover_confianza(nombre, maxi(1, int(round(4.0 * f))))
				exclusiva = nombre
				cuerpo = "Trato cerrado con %s. Verás primero a sus jugadores en el mercado." % nombre
			else:
				_mover_confianza(nombre, -1)
				if exclusiva == nombre:
					exclusiva = ""
				cuerpo = "Prefieres moverte libre. %s se lo tomó con deportividad… por ahora." % nombre
	var titulo := "Representantes: %s" % nombre
	if acepta and f < 1.0:
		cuerpo = "Negociado en la mesa al %d %% de lo que pedía. %s" % [int(round(f * 100.0)), cuerpo]
	elif se_fue:
		cuerpo = "%s se levantó de la mesa. %s" % [nombre, cuerpo]
	exigencia = {}
	noticia.emit(titulo, cuerpo)
	return {"titulo": titulo, "cuerpo": cuerpo}

func _ficha_vacia(x: Dictionary) -> bool:
	return (x.get("linaje", {}) as Dictionary).is_empty() \
		and (x.get("etiqueta", {}) as Dictionary).is_empty() \
		and String(x.get("origen", "")) == "" \
		and not bool(x.get("beca", false)) \
		and String(x.get("hermano", "")) == "" \
		and int(x.get("promesa_compa", 0)) == 0 \
		and not x.has("camada")


# ===========================================================================
#  GUARDADO
# ===========================================================================

## Solo se guardan las fichas que dicen algo. Con 8.448 jugadores en el mundo,
## escribir una ficha vacía por cada uno son cientos de kilobytes de nada en cada
## partida guardada. Es la misma criba que hace `Medico.a_dic()`.
func a_dic() -> Dictionary:
	var f := {}
	for id: String in _fichas:
		var x: Dictionary = _fichas[id]
		if _ficha_vacia(x):
			continue
		f[id] = x
	return {
		"leyendas": leyendas,
		"fichas": f,
		"ultima_camada": ultima_camada,
		"confianza_agentes": confianza_agentes,
		"exclusiva": exclusiva,
		"turbio": turbio,
		"exigencia": exigencia,
	}

func desde_dic(d: Dictionary) -> void:
	leyendas.clear()
	for L: Dictionary in d.get("leyendas", []):
		leyendas.append({
			"nombre": String(L.get("nombre", "")),
			"club_id": String(L.get("club_id", "")),
			"pos": String(L.get("pos", "MED")),
			"nivel": int(L.get("nivel", 80)),
			"anio_hijo": int(L.get("anio_hijo", 0)),
			"usado": bool(L.get("usado", false)),
			"propio": bool(L.get("propio", false)),
		})
	_fichas.clear()
	var f: Dictionary = d.get("fichas", {})
	for id: String in f:
		var x: Dictionary = f[id]
		var ficha := {
			"linaje": (x.get("linaje", {}) as Dictionary).duplicate(true),
			"origen": String(x.get("origen", "")),
			"etiqueta": (x.get("etiqueta", {}) as Dictionary).duplicate(true),
			"beca": bool(x.get("beca", false)),
			"hermano": String(x.get("hermano", "")),
			"gemelo": bool(x.get("gemelo", false)),
			"promesa_compa": int(x.get("promesa_compa", 0)),
		}
		## `camada` solo existe si el chico salió de la academia: es lo que
		## distingue a un canterano de un fichaje, y ponerlo por defecto
		## convertiría a la plantilla entera en gente de la casa al cargar.
		if x.has("camada"):
			ficha["camada"] = int(x["camada"])
		_fichas[id] = ficha
	ultima_camada.clear()
	for id in d.get("ultima_camada", []):
		ultima_camada.append(String(id))
	confianza_agentes = (d.get("confianza_agentes", {}) as Dictionary).duplicate()
	exclusiva = String(d.get("exclusiva", ""))
	turbio = int(d.get("turbio", 0))
	exigencia = (d.get("exigencia", {}) as Dictionary).duplicate(true)

## `rankingCanteras()` del HTML: quién está formando de verdad. No es "cuántos
## juveniles tienes" sino cantidad Y techo juntos, porque veinte chicos del
## montón no son una cantera y tres joyas tampoco.
##
## La nota mezcla las dos cosas: la proyección media más un punto y medio por
## cabeza. Así un club con seis chicos de 80 de techo gana a uno con quince de
## 60, pero uno con dos de 90 no gana a nadie.
func ranking_canteras() -> Array[Dictionary]:
	var m := _mundo()
	if m == null:
		return []
	var salida: Array[Dictionary] = []
	for c: Club in m.clubes.values():
		if c.division <= 0:
			continue
		var n := 0
		var pot := 0
		for j in c.plantilla:
			if j.edad <= 21:
				n += 1
				pot += j.pot
		if n == 0:
			continue
		var nota := int(round(float(pot) / float(n) + float(n) * 1.6))
		## La academia propia suma: es la instalación que sube el techo de los
		## que suben, así que tener nivel cinco tiene que verse en este ranking.
		if c.id == m.mi_club_id and m.obras != null:
			nota += m.obras.nivel("acad") * 3
		salida.append({"club": c, "juveniles": n, "nota": nota})
	salida.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["nota"]) > int(b["nota"]))
	return salida
