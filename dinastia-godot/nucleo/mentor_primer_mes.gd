class_name MentorPrimerMes
extends RefCounted
## EL TUTORIAL DE GESTIÓN DEL PRIMER MES (M-297, 27-10-2026). El tutorial del primer día enseña DÓNDE está cada
## cosa; este, QUÉ MIRAR las cuatro primeras semanas al mando. Tras cada semana, el mentor deja un consejo
## (por `Prensa.mentor_dice`, la misma voz del resto del juego) sacado del estado REAL del club: el marcador
## del partido, los que llegan sin piernas, los contratos que vencen y la caja frente a los sueldos. No tira
## de `Azar` (no mueve la partida) y no repite: cada consejo sale una vez por carrera.

const SEMANAS := 4
const FISICO_BAJO := 70          ## por debajo, llega cansado al partido
const SEMANAS_DE_CAJA := 8       ## caja menor que estas semanas de sueldos: aviso

var semana_al_mando: int = 0
var activo: bool = true
var dados: Array = []            ## ids de los consejos ya dichos

## Al tomar un club. Es una vez por CARRERA: si ya empezó (cambio de club a mitad), sigue donde iba.
func empezar() -> void:
	if semana_al_mando > 0 or not dados.is_empty():
		return
	activo = true

## Tras cada semana. `gf`/`gc`: el marcador de tu partido (-1 si no jugaste). Devuelve el id del consejo
## dicho ("" si ninguno), para las pruebas.
func tras_semana(m: Mundo, gf: int, gc: int) -> String:
	var c := m.mi_club()
	if not activo or c == null or semana_al_mando >= SEMANAS:
		return ""
	semana_al_mando += 1
	var consejo := consejo_de(semana_al_mando, c, gf, gc, m.directiva)
	if consejo.is_empty() or dados.has(consejo[0]):
		return ""
	dados.append(consejo[0])
	if m.prensa != null:
		m.prensa.mentor_dice.emit(Idiomas.t(String(consejo[1])), String(consejo[2]))
	if semana_al_mando >= SEMANAS:
		activo = false
	return String(consejo[0])

## [id, título, texto ya traducido] del consejo de la semana `n` (vacío si no toca ninguno).
static func consejo_de(n: int, c: Club, gf: int, gc: int, dir: Directiva) -> Array:
	match n:
		1:
			return ["partido", "Tu primera semana", _texto_partido(gf, gc)]
		2:
			return ["carga", "La carga de trabajo", _texto_carga(c)]
		3:
			return ["contratos", "Los contratos", _texto_contratos(c)]
		4:
			return ["caja", "La caja y la confianza", _texto_caja(c, dir)]
	return []

static func _texto_partido(gf: int, gc: int) -> String:
	var r: String
	if gf < 0:
		r = Idiomas.t("Esta semana no hubo partido: aprovéchala para conocer al grupo y ajustar la táctica.")
	elif gf > gc:
		r = Idiomas.t("Primera victoria (%d-%d). Que no se te suba: mira en el informe del partido quién sostuvo al equipo y quién no.") % [gf, gc]
	elif gf == gc:
		r = Idiomas.t("Un empate para empezar (%d-%d). El informe del partido te dice dónde se escaparon los puntos.") % [gf, gc]
	else:
		r = Idiomas.t("Se perdió el primero (%d-%d). Nadie gana la liga en la primera fecha: busca en el informe qué falló antes de cambiarlo todo.") % [gf, gc]
	return r + "\n\n" + Idiomas.t("Y cada semana tienes tres retos en tus objetivos (🎯): cumplirlos llena la caja.")

static func _texto_carga(c: Club) -> String:
	var cansados: Array = []
	for j: Jugador in c.plantilla:
		if j.lesion <= 0 and j.fisico < FISICO_BAJO:
			cansados.append(j)
	cansados.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.fisico < b.fisico)
	if cansados.is_empty():
		return Idiomas.t("El grupo está fresco. Es el momento de apretar en el entrenamiento: lo que cargues ahora se nota en marzo.")
	var nombres: Array = cansados.slice(0, 3).map(func(j: Jugador) -> String: return "%s (%d%%)" % [j.nombre, j.fisico])
	return Idiomas.t("Hay %d jugadores sin piernas: %s. Baja la carga del entrenamiento o rótalos; un cansado se lesiona.") % [cansados.size(), ", ".join(nombres)]

static func _texto_contratos(c: Club) -> String:
	var vencen: Array = []
	for j: Jugador in c.plantilla:
		if j.anios_contrato <= 1:
			vencen.append(j)
	vencen.sort_custom(func(a: Jugador, b: Jugador) -> bool: return a.ovr > b.ovr)
	if vencen.is_empty():
		return Idiomas.t("Nadie de la plantilla acaba contrato esta temporada. Aun así, revisa los sueldos: un contrato largo y caro pesa años.")
	var nombres: Array = vencen.slice(0, 3).map(func(j: Jugador) -> String: return "%s (%d)" % [j.nombre, j.ovr])
	return Idiomas.t("A %d jugadores se les acaba el contrato esta temporada; los mejores, %s. Renueva a tiempo o en verano se van gratis.") % [vencen.size(), ", ".join(nombres)]

static func _texto_caja(c: Club, dir: Directiva) -> String:
	var sueldos := maxi(c.masa_salarial(), 1)
	var semanas := int(float(c.saldo) / float(sueldos))
	var t: String
	if c.saldo < 0:
		t = Idiomas.t("La caja está en rojo (%s). Antes de fichar, vende o recorta sueldos: un club en rojo acaba con el banco en la puerta.") % Eco.dinero(c.saldo)
	elif semanas < SEMANAS_DE_CAJA:
		t = Idiomas.t("Con la caja (%s) se pagan unas %d semanas de sueldos. Es poco: cuida cada fichaje.") % [Eco.dinero(c.saldo), semanas]
	else:
		t = Idiomas.t("La caja (%s) paga unas %d semanas de sueldos. Hay margen para fichar, pero cada sueldo nuevo se paga todas las semanas.") % [Eco.dinero(c.saldo), semanas]
	if dir != null:
		t += "\n\n" + (Idiomas.t("Confianza de la directiva: %d («%s»). Si llega a %d, te despiden: mírala cada semana arriba.") % [dir.confianza, Idiomas.t(dir.humor()), Directiva.UMBRAL_DESPIDO])
	return t + "\n\n" + Idiomas.t("Con esto acaba tu primer mes. Desde aquí, el club es tuyo.")

func a_dic() -> Dictionary:
	return {"semana": semana_al_mando, "activo": activo, "dados": dados.duplicate()}

func desde_dic(d: Dictionary) -> void:
	semana_al_mando = int(d.get("semana", SEMANAS))
	activo = bool(d.get("activo", false))
	dados = (d.get("dados", []) as Array).duplicate()
