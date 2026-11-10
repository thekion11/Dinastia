class_name PartidoRapido
extends RefCounted
## EL PARTIDO SIMULADO DE LA IA, EN C++ (10-11-2026, paso a C++, orden del dueño «pasar todo a C++»). `Liga.jugar_jornada` simula decenas de cruces IA-IA por semana que NADIE mira
## (el objeto `Partido` se tira al acabar): sin pantalla, sin crónica leída, sin narración. `simular()` hace los 90 minutos con `simular_minuto()` (GDScript); esta ruta hace el MISMO bucle en
## C++ (`simular_90`, nativo/src/partido_90.cpp) con el mismo orden de llamadas a `Azar`, y vuelve a GDScript SOLO para los sucesos raros (gol, tarjeta, penal, lesión, cambio, plan del minuto 60),
## cuyo código vive aquí UNA vez y lo usan las dos rutas (`_chequeo_arbitral`, `_penal_en_area` e `_incidencias` de `Partido` llaman a estas mismas funciones).
## Lo que NO hace (nadie lo lee en un cruce que se tira): crónica de remates y de minutos, `RastroPartido`, `momentum_eventos` de los remates. El resultado, los jugadores (goles, tarjetas, sanciones, lesiones,
## notas, forma, partidos) y el generador de azar quedan IGUAL que con `simular()`: lo comprueba `pruebas/probar_nativo.tscn` con mundos enteros. Sin la extensión (Web, Android sin binario, `DINASTIA_SIN_NATIVO=1`), o si
## el cruce no cumple las condiciones de `_puede`, corre `simular_minuto()` de siempre.

## Como `Partido.simular()`, pero por la ruta rápida si se puede. Devuelve {local, visita}.
static func simular(p: Partido) -> Dictionary:
	var nat := Nativo.obj()
	var rapido := nat != null and nat.has_method("simular_90") and _puede(p)
	p.sin_rastro = rapido   ## el rastro (`CausasPartido`) solo se lee en el partido del jugador; un cruce de la IA que se tira no lo necesita
	p.preparar()
	if rapido:
		_nativo(p, nat)
	else:
		while not p.terminado_ya:
			p.simular_minuto()
	p._cerrar_notas()
	p.guardar_si_es_mio()
	return {"local": p.goles_local, "visita": p.goles_visita}

## Las condiciones en que la ruta nativa es EXACTAMENTE `simular_minuto()`: ningún club es el del jugador, nadie lo mira ni lo toca (motor, grada, instrucciones, prórroga), sin roles en las tácticas
## (el reparto del gol los usa), nadie más escucha los remates y el partido está recién preparado.
static func _puede(p: Partido) -> bool:
	if p.motor_externo or p._hinchada_club != null or p.instr_riesgo or p.instr_tiempo or p.prorroga_si_empate or p.terminado_ya or p.minuto != 0 or p.minutos_fin != Partido.MINUTOS:
		return false
	if p.local.id == Partido.ctx_club_id or p.visita.id == Partido.ctx_club_id:
		return false
	if not p.local.tactica.roles.is_empty() or not p.visita.tactica.roles.is_empty():
		return false
	if not (p.get_meta("lesionados", {}) as Dictionary).is_empty() or p.remate.get_connections().size() != 2:
		return false
	return true

static var _ayuda: PartidoRapido = null
static var _pcg := -1   ## -1 = sin comprobar; 1 = la extensión reproduce el generador del motor (más rápido); 0 = no (usa el del motor)

## Una sola vez: ¿el PCG32 de la extensión da las mismas tiradas que el `RandomNumberGenerator` de esta versión del motor? Si no, `simular_90` llama al del motor (mismo resultado, más lento).
static func _azar_propio(nat: Object) -> bool:
	if _pcg < 0:
		_pcg = 1 if nat.has_method("pcg_coincide") and nat.pcg_coincide() else 0
	return _pcg == 1
static var por_ruta_nativa := 0   ## cuántos cruces fueron por C++ (las pruebas comprueban que la ruta se usó de verdad)

static func _nativo(p: Partido, nat: Object) -> void:
	if _ayuda == null:
		_ayuda = PartidoRapido.new()
	var perfil := String(p.arbitro.get("perfil", ""))
	var cfg := {
		"igual": pow(Balance.REPARTO / 2.0, Balance.EXPONENTE), "base_ataque": Balance.BASE_ATAQUE, "sensib": Balance.SENSIBILIDAD, "satura": Balance.SATURA_LN,
		"bono_l": 1.0 if p.neutral else Balance.BONO_LOCAL, "bono_v": 1.0 if p.neutral else Balance.BONO_VISITA, "clima": p.clima, "clima_v": p._f_clima_visita,
		"ritmo0": p.local.tactica.ritmo == 0,
		"pc_l": Balance.P_CORNER_LOCAL, "pc_v": Balance.P_CORNER_VISITA, "pf_l": Balance.P_FALTA_LOCAL, "pf_v": Balance.P_FALTA_VISITA, "pfuera": Balance.P_FUERA,
		"k": Balance.LLEGADAS_K, "conv": Balance.CONVERSION, "r_ataj": Balance.R_ATAJADA, "r_poste": Balance.R_POSTE,
		"p_penal": Balance.P_PENAL * float(Balance.PENAL_PERFIL.get(perfil, 1.0)),
		"f_var": Partido.ctx_factor_tarjetas / Balance.LLEGADAS_K,
		"p_amarilla": Balance.P_AMARILLA * Partido.ctx_factor_tarjetas * float({"tarjetero": 1.4, "estricto": 1.15, "permisivo": 0.7}.get(perfil, 1.0)),
		"p_lesion": 0.0024 * 1.0,
		"perfil": perfil, "hay_arbitro": not p.arbitro.is_empty(), "fin": p.minutos_fin,
		"grupo_de": Datos.mapa_grupos(), "bases_gol": PartidoPonderado.BASES_GOL,
	}
	por_ruta_nativa += 1
	nat.simular_90(p, _ayuda, cfg, Azar._rng, _azar_propio(nat))
	if p.minuto >= p.minutos_fin:   ## el final de `simular_minuto()` (sin prórroga: `_puede` la descarta)
		p.terminado_ya = true
		p._devolver_tactica()
		p.terminado.emit(p.goles_local, p.goles_visita)

# --- Los sucesos raros: el código de siempre, una sola vez (lo llaman `Partido` y la extensión). `p` = el partido. ---

func atender(p: Partido) -> void:
	PartidoLesiones.atender(p)

static func hit_tarjetero(p: Partido) -> void:
	var arr := p.once_local if Azar.suerte(0.5) else p.once_visita
	p._tarjeta_arbitral(arr, "🟨 %s saca otra amarilla: %s", String(p.arbitro.get("nombre", "")))

static func hit_casero(p: Partido) -> void:
	## Siempre contra el que visita: es lo que hace "casero" casero.
	p._tarjeta_arbitral(p.once_visita, "🟨 %s cobra para la casa: amarilla a %s", String(p.arbitro.get("nombre", "")))

static func hit_estricto(p: Partido) -> void:
	var nombre := String(p.arbitro.get("nombre", ""))
	## 55%/45% a tu favor cuando el partido es tuyo -"_favMi" del HTML-; sin nadie a quien favorecer -un cruce entre dos clubes de la IA- se reparte parejo.
	var prob_local := 0.5
	if p.local.id == Partido.ctx_club_id:
		prob_local = 0.55
	elif p.visita.id == Partido.ctx_club_id:
		prob_local = 0.45
	if Azar.suerte(prob_local):
		## (Antes «penal cobrado en contra» salía según el lado, no según tu club.)
		p.decision_arbitral.emit(Idiomas.t("⚽ Penal para %s: %s no dudó en cobrarlo.") % [p.local.nombre, nombre], p.minuto)
		p._contar_penal(true)
		p._anotar(p.local, p.once_local, true)
	else:
		p.decision_arbitral.emit(Idiomas.t("⚽ Penal para %s: con %s no se toca a nadie.") % [p.visita.nombre, nombre], p.minuto)
		p._contar_penal(false)
		p._anotar(p.visita, p.once_visita, false)

static func hit_figura(p: Partido) -> void:
	p.decision_arbitral.emit(
		Idiomas.t("⚖️ %s anula un gol por milímetros. Protestas en las dos bancas.") % String(p.arbitro.get("nombre", "")), p.minuto)

## El resto de `_penal_en_area` una vez que la tirada de «falta en el área» salió.
static func hit_penal(p: Partido, c: Club, once: Array[Jugador], es_local: bool) -> void:
	var nombre := String(p.arbitro.get("nombre", Idiomas.t("El árbitro")))
	p.decision_arbitral.emit(Idiomas.t("⚽ Penal para %s: %s no dudó en cobrarlo.") % [c.nombre, nombre], p.minuto)
	p._contar_penal(es_local)
	if Azar.suerte(Balance.CONVERSION_PENAL):
		p._anotar(c, once, es_local)
	else:
		p.remate.emit(c, p._elegir_goleador(once), "atajada", p.minuto)

## La amarilla de `_incidencias` una vez que la tirada salió.
static func hit_amarilla(p: Partido, casero: bool) -> void:
	var l := p._alguien(p.once_visita if casero and Azar.suerte(0.35) else p.once_local + p.once_visita)
	if l != null:
		p._amonestar(l)

## La lesión de `_incidencias` una vez que la tirada salió.
## LA LESION LA DIAGNOSTICA `Medico`, no un numero suelto: antes se sorteaban de una a ocho semanas aqui mismo y no se pasaba por el parte medico (sin nombre, sin historial);
## ahora la lesion del campo es la misma que la del parte (`severidad_en_partido()`). Los clubes de la IA, sin medico, sortean 1-8 semanas (+1-3 si es fragil).
static func hit_lesion(p: Partido) -> void:
	var h := p._alguien(p.once_local + p.once_visita)   ## A4-PAR-L01: se lesiona alguien que está jugando
	if h != null:
		var semanas := 0
		if Partido.ctx_medico != null and h.club_id == Partido.ctx_club_id:
			semanas = Partido.ctx_medico.lesionar(h, Partido.ctx_medico.severidad_en_partido(), "lesión en partido", Partido.ctx_anio, Partido.ctx_semana)
		else:
			semanas = Azar.ent(1, 8)
			if h.rasgo == "fragil":
				semanas += Azar.ent(1, 3)
			h.lesionar(semanas)
		p.lesion.emit(h, semanas, p.minuto); PartidoLesiones.nueva(p, h)
