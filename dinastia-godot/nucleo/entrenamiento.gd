class_name Entrenamiento
extends "res://nucleo/entrenamiento_p2.gd"
## (Parte 3 de 3 de `entrenamiento.gd`.)

## El sorteo de nacimiento: con qué habilidades llega un jugador al mundo. Se
## queda aquí y no en `Jugador` porque las habilidades no viven en el jugador.
func sortear_habilidades(j: Jugador) -> Array[String]:
	var t: Variant = Datos.tabla("HAB_POR" if j.es_portero() else "HAB_CAMPO")
	var pool: Array = t if t is Array else []
	if pool.is_empty():
		return []
	var n := 0
	if j.ovr >= 85:
		n = Azar.ent(2, 4)
	elif j.ovr >= 76:
		n = Azar.ent(1, 3)
	elif j.ovr >= 66:
		n = Azar.ent(0, 2)
	else:
		n = Azar.ent(0, 1)
	var salida: Array[String] = []
	for i in n:
		var h := String(Azar.uno(pool))
		if not salida.has(h):
			salida.append(h)
	var l := _lista(j.id)
	for h in salida:
		if not l.has(h):
			l.append(h)
	return salida

func dt_coste(clave: String) -> int:
	var t := _dt_tabla()
	return int((t[clave] as Array)[4]) if t.has(clave) else 0

func dt_requisito(clave: String) -> String:
	var t := _dt_tabla()
	if not t.has(clave):
		return ""
	var r: Variant = (t[clave] as Array)[5]
	return "" if r == null else String(r)

func dt_nombre(clave: String) -> String:
	var t := _dt_tabla()
	return Nombres.limpiar(String((t[clave] as Array)[1])) if t.has(clave) else clave

func dt_icono(clave: String) -> String:
	var t := _dt_tabla()
	return String((t[clave] as Array)[2]) if t.has(clave) else ""

func dt_descripcion(clave: String) -> String:
	var t := _dt_tabla()
	return String((t[clave] as Array)[3]) if t.has(clave) else ""


## Igual que con los jugadores: el menú tiene que poder decir qué falta.
func dt_motivo(clave: String) -> String:
	var t := _dt_tabla()
	if not t.has(clave):
		return "no disponible"
	if dt_tiene(clave):
		return "ya la tienes"
	var req := dt_requisito(clave)
	if req != "" and not dt_tiene(req):
		return "antes: " + dt_nombre(req)
	var c := dt_coste(clave)
	if dt_puntos < c:
		return "te faltan %d punto(s)" % (c - dt_puntos)
	return ""

## Abre un nodo. Devuelve "" si se abrió, o el motivo por el que no.
func dt_aprender(clave: String) -> String:
	var m := dt_motivo(clave)
	if m != "":
		return m
	dt_puntos -= dt_coste(clave)
	dt_nodos[clave] = true
	dt_habilidad.emit(clave, dt_nombre(clave))
	noticia.emit("Nueva habilidad: " + dt_nombre(clave),
		dt_descripcion(clave) + ". Tu ficha de entrenador suma un punto más de prestigio.")
	return ""

func dt_sumar_puntos(n: int) -> void:
	dt_puntos = maxi(0, dt_puntos + n)
	if n > 0:
		punto_dt_ganado.emit(dt_puntos)

## Los nodos agrupados por rama, en el orden de la tabla.
func dt_ramas() -> Dictionary:
	var salida := {}
	var t := _dt_tabla()
	for k: String in t:
		var rama := String((t[k] as Array)[0])
		if not salida.has(rama):
			salida[rama] = []
		(salida[rama] as Array).append(k)
	return salida

# --- lo que el árbol del entrenador le hace al juego ------------------------
#
# Todas las puertas por las que la carrera del DT toca el motor, juntas y a la
# vista, como en `Instalaciones.efecto()`. Si mañana se abre un nodo nuevo, este
# es el sitio donde tiene que aparecer o no servirá para nada.

## Bonificación de ataque y defensa del banquillo. «Genio» REEMPLAZA a «Pizarra
## fina», no se suman: el 6% ya incluye el 3%.
##
## OJO: esto NO se escribe en `Club.bonus_ataque`/`bonus_defensa`. Esos dos
## números los vuelca `Staff.aplicar()` enteros cada vez que se contrata a
## alguien, así que escribir aquí se perdería al siguiente fichaje de staff.
## Quien monte el club combina este factor con el del cuerpo técnico.
func bonus_dt() -> float:
	if dt_tiene("genio"):
		return 1.06
	if dt_tiene("pizarra"):
		return 1.03
	return 1.0

## Techo extra de las camadas de cantera. Se suma al de `Staff.techo_cantera()`
## y al de `Instalaciones.techo_cantera()`, que miden otras cosas.
func techo_cantera_dt() -> int:
	if dt_tiene("academia"):
		return 3
	if dt_tiene("formador"):
		return 2
	return 0

## Cuánto pegan las instrucciones dadas en vivo durante el partido.
func factor_instrucciones() -> float:
	return 1.5 if dt_tiene("bloque") else 1.0

## Se ve la táctica del rival en la previa.
func ve_tactica_rival() -> bool:
	return dt_tiene("lectura")

## Cuánto sube el sueldo del entrenador por su fama.
func factor_sueldo_dt() -> float:
	return 1.15 if dt_tiene("carisma") else 1.0

## Los sueldos del cuerpo técnico con el descuento del contable.
func factor_sueldo_staff() -> float:
	return 0.85 if dt_tiene("contable") else 1.0

## Cuánto más rápido se apaga una funa en la prensa.
func factor_apagar_funa() -> float:
	return 2.0 if dt_tiene("mediatico") else 1.0

## Cuánto más rápido baja la ansiedad del vestuario cada semana.
func factor_calma() -> float:
	return 2.0 if dt_tiene("psicologo") else 1.0

## Lo que se le suma a la probabilidad de mediar con éxito entre camarillas.
func bono_mediacion() -> float:
	return 0.18 if dt_tiene("mediador") else 0.0

## Multas y normas internas rinden el doble.
func multas_dobles() -> bool:
	return dt_tiene("duro")

## Inmune a las rebeliones de vestuario.
func vestuario_de_hierro() -> bool:
	return dt_tiene("lider")

## Puede comprar acciones de clubes filiales.
func puede_comprar_filiales() -> bool:
	return dt_tiene("magnate")

## Lo que se le suma a la probabilidad de que un jugador acepte venir. Son los
## dos bonos que el HTML sumaba en la puerta de fichajes.
func bono_fichajes() -> float:
	var b := 0.0
	if dt_tiene("icono"):
		b += 0.10
	if dt_tiene("negociador"):
		b += 0.06
	return b

## Y lo que se le suma a la negociación con agentes, que en el HTML pesaba
## distinto: aquí el negociador manda y el ícono acompaña.
func bono_agentes() -> float:
	var b := 0.0
	if dt_tiene("negociador"):
		b += 0.08
	if dt_tiene("icono"):
		b += 0.06
	return b

## Informes de ojeo mucho más precisos.
func ojeo_preciso() -> bool:
	return dt_tiene("cazador")

# ---------------------------------------------------------------------------
#  GUARDAR
# ---------------------------------------------------------------------------

## Solo se guardan los jugadores que tienen algo que guardar. En un mundo de
## once mil futbolistas la inmensa mayoría no ha aprendido nada ni tiene puntos,
## y escribir once mil diccionarios vacíos engorda la partida sin decir nada: el
## guardado de este juego ya costó una depuración entera por tamaño.
func a_dic() -> Dictionary:
	var jug := {}
	for id: String in _habs:
		var l: Array = _habs[id]
		if not l.is_empty():
			jug[id] = {"habs": l.duplicate()}
	for id: String in _puntos:
		if int(_puntos[id]) > 0:
			if not jug.has(id):
				jug[id] = {}
			jug[id]["pts"] = int(_puntos[id])
	for id: String in _subidas:
		if int(_subidas[id]) > 0:
			if not jug.has(id):
				jug[id] = {}
			jug[id]["sub"] = int(_subidas[id])
	return {
		"mentorias": mentorias.duplicate(true),
		"foco": foco,
		"intensidad": intensidad,
		"dias": dias.duplicate(),
		"individual": individual.duplicate(true),
		"prioritarios": prioritarios.duplicate(),
		"concentracion": concentracion,
		"pretemporada": pretemporada,
		"semanas": semanas_trabajadas,
		"dt_puntos": dt_puntos,
		"dt_nodos": dt_nodos.duplicate(),
		"jugadores": jug,
	}

func desde_dic(d: Dictionary) -> void:
	mentorias.clear()
	for m in d.get("mentorias", []):
		mentorias.append({
			"maestro": String(m.get("maestro", "")), "pupilo": String(m.get("pupilo", "")),
			"semanas": int(m.get("semanas", 0)), "subidas": int(m.get("subidas", 0)),
		})
	foco = String(d.get("foco", "tactico"))
	intensidad = String(d.get("intensidad", "media"))
	var ds: Array = d.get("dias", [])
	dias.clear()
	for x in ds:
		dias.append(String(x))
	if dias.size() != PLAN_POR_DEFECTO.size():
		dias.assign(PLAN_POR_DEFECTO)
	individual = (d.get("individual", {}) as Dictionary).duplicate(true)
	prioritarios.clear()
	for x in (d.get("prioritarios", []) as Array):
		prioritarios.append(String(x))
	concentracion = bool(d.get("concentracion", false))
	pretemporada = String(d.get("pretemporada", ""))
	semanas_trabajadas = int(d.get("semanas", 0))
	dt_puntos = int(d.get("dt_puntos", DT_PUNTOS_INICIALES))
	dt_nodos = (d.get("dt_nodos", {}) as Dictionary).duplicate()
	_habs.clear()
	_puntos.clear()
	_subidas.clear()
	var jug: Dictionary = d.get("jugadores", {})
	for id: String in jug:
		var f: Dictionary = jug[id]
		var l: Array = f.get("habs", [])
		if not l.is_empty():
			var limpia: Array = []
			for h in l:
				limpia.append(String(h))
			_habs[id] = limpia
		if int(f.get("pts", 0)) > 0:
			_puntos[id] = int(f["pts"])
		if int(f.get("sub", 0)) > 0:
			_subidas[id] = int(f["sub"])
