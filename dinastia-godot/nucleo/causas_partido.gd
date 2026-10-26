class_name CausasPartido
extends RefCounted
## EL PORQUÉ DE UN RESULTADO (26-10-2026, sesión 5, fila 4 de la propuesta). Top Eleven carga con la fama de
## «partidos amañados» porque nadie le explica al jugador por qué perdió. Aquí, tras cada partido, salen las
## TRES causas que más pesaron, sacadas de lo que pasó de verdad (`Partido` y su `RastroPartido`), nunca
## inventadas: momentum, forma, plantilla, clima, táctica del rival, cansancio, árbitro, eficacia, lesiones
## y, si no hay nada más fuerte, la localía y la posesión.
##
## Cada candidata lleva un PESO (cuánto explica) y un SIGNO (+1 a tu favor, −1 en contra, 0 para los dos).
## Si ganaste van primero las que te ayudaron; si perdiste, las que te hundieron; en el empate, las que más
## pesaron. Una por tipo. Lo que el motor del 3D no modela (el clima, el xG fino, la localía) no se usa
## cuando el partido lo jugó ese motor: sería contar una causa que no existió.
##
##   CausasPartido.de(partido, mi_club) -> [{clave, icono, titulo, texto, signo, peso}] (3 como mucho)

const ICONOS := {"momentum": "📈", "forma": "💪", "plantilla": "📋", "clima": "🌧", "tactica": "♟",
	"cansancio": "🔋", "arbitro": "🟨", "eficacia": "🎯", "lesion": "🚑", "localia": "🏟", "posesion": "⚽"}
const TITULOS := {"momentum": "Momentum", "forma": "Forma", "plantilla": "Plantilla", "clima": "Clima",
	"tactica": "Táctica", "cansancio": "Cansancio", "arbitro": "Árbitro", "eficacia": "Eficacia",
	"lesion": "Lesión", "localia": "Localía", "posesion": "Posesión"}

static func de(p: Partido, club: Club) -> Array:
	if p == null or club == null or p.rastro == null or p.rastro.inicio.is_empty():
		return []
	var mio := 0 if p.local == club else 1
	var c := candidatas(p, mio)
	var mios := p.goles_local if mio == 0 else p.goles_visita
	var suyos := p.goles_visita if mio == 0 else p.goles_local
	var buscado := signi(mios - suyos)
	c.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		## Primero las que explican ESTE resultado; después, el peso.
		var ea := buscado != 0 and int(a["signo"]) == buscado
		var eb := buscado != 0 and int(b["signo"]) == buscado
		if ea != eb:
			return ea
		return float(a["peso"]) > float(b["peso"]))
	var r: Array = []
	var vistas := {}
	for x: Dictionary in c:
		if vistas.has(x["clave"]):
			continue
		vistas[x["clave"]] = true
		x["icono"] = ICONOS[x["clave"]]
		x["titulo"] = Idiomas.t(String(TITULOS[x["clave"]]))
		r.append(x)
		if r.size() == 3:
			break
	return r

## Todas las causas con datos detrás, sin ordenar. `mio`: 0 si tu club era el local, 1 si el visitante.
static func candidatas(p: Partido, mio: int) -> Array:
	var r := p.rastro
	var suyo := 1 - mio
	var c: Array = []
	var gm := p.goles_local if mio == 0 else p.goles_visita
	var gs := p.goles_visita if mio == 0 else p.goles_local
	var lado := 1 if mio == 0 else -1   ## para leer el momentum (positivo = local)
	## MOMENTUM: el cuarto de hora en que uno empujó más, y los goles que cayeron ahí.
	var t := r.tramo_dominante(15)
	var neto := int(t["neto"]) * lado
	if absi(neto) >= 3:
		var desde := int(t["desde"])
		var hasta := int(t["hasta"])
		var dentro := [0, 0]
		for e: Dictionary in p.cronica:
			if String(e.get("tipo", "")) == "gol" and int(e["min"]) >= desde and int(e["min"]) < hasta:
				dentro[0 if String(e["club"]) == (p.local.id if mio == 0 else p.visita.id) else 1] += 1
		var a_favor := neto > 0
		var goles_tramo: int = dentro[0] if a_favor else dentro[1]
		var txt := ""
		if a_favor:
			txt = Idiomas.t("Entre el %d' y el %d' apretamos (%d llegadas netas) y ahí marcamos %d.") % [desde, hasta, neto, goles_tramo] \
				if goles_tramo > 0 else Idiomas.t("Entre el %d' y el %d' apretamos (%d llegadas netas), pero no la metimos.") % [desde, hasta, neto]
		else:
			txt = Idiomas.t("Entre el %d' y el %d' el rival nos encerró (%d llegadas netas) y nos hizo %d.") % [desde, hasta, -neto, goles_tramo] \
				if goles_tramo > 0 else Idiomas.t("Entre el %d' y el %d' el rival nos encerró (%d llegadas netas) y aguantamos.") % [desde, hasta, -neto]
		## Un tramo con goles explica más que uno sin ellos.
		c.append(_c("momentum", (1 if a_favor else -1) if goles_tramo > 0 else 0, absf(neto) / 7.0 + 0.35 * goles_tramo, txt))
	## FORMA y PLANTILLA: cómo llegaban los dos onces.
	var fm := int(r.inicio["forma"][mio])
	var fs := int(r.inicio["forma"][suyo])
	if absi(fm - fs) >= 5:
		c.append(_c("forma", signi(fm - fs), absf(fm - fs) / 14.0,
			(Idiomas.t("Llegábamos en mejor forma (media %d frente a %d).") if fm > fs else Idiomas.t("El rival llegaba en mejor forma (media %d frente a %d).")) % [fm, fs]))
	var om := int(r.inicio["ovr"][mio])
	var os := int(r.inicio["ovr"][suyo])
	if absi(om - os) >= 3:
		c.append(_c("plantilla", signi(om - os), absf(om - os) / 9.0,
			(Idiomas.t("Sobre el papel éramos mejores (media del once %d frente a %d).") if om > os else Idiomas.t("Sobre el papel su once era mejor (media %d frente a %d).")) % [om, os]))
	## CLIMA (solo sin el motor del 3D, que no lo modela).
	if not r.con_motor:
		if p.clima < 0.97 and not p.clima_info.is_empty():
			c.append(_c("clima", 0, (1.0 - p.clima) * 4.0,
				Idiomas.t("%s: partido trabado, un %d %% menos de llegadas para los dos.") % [Idiomas.t(String(p.clima_info.get("texto", ""))), int(round((1.0 - p.clima) * 100.0))]))
		if p._f_clima_visita < 0.97:
			var sufre_yo := mio == 1
			c.append(_c("clima", -1 if sufre_yo else 1, (1.0 - p._f_clima_visita) * 5.0,
				(Idiomas.t("No estamos hechos a este clima: un %d %% menos de llegadas.") if sufre_yo else Idiomas.t("Al rival le pesó un clima al que no está hecho: un %d %% menos de llegadas.")) % int(round((1.0 - p._f_clima_visita) * 100.0))))
	## TÁCTICA: la pizarra de salida de cada uno y el plan del minuto 60.
	## La pizarra del rival no «gana» en neto (sus perillas restan atrás lo que suman delante, `Tactica`):
	## lo que hace es ABRIR o CERRAR el partido. Se mide cuánto cambian las llegadas de cada uno
	## (exponente de `Partido._probabilidad`) y si le salió por cómo acabó.
	var sus_lleg := pow(float(r.inicio["tac_ata"][suyo]) / float(r.inicio["tac_def"][mio]), Partido.SENSIBILIDAD)
	var mis_lleg := pow(float(r.inicio["tac_ata"][mio]) / float(r.inicio["tac_def"][suyo]), Partido.SENSIBILIDAD)
	var su_ment := clampi(int(r.inicio["mentalidad"][suyo]), 0, 2)
	if su_ment != Tactica.Mentalidad.EQUILIBRADA and (absf(sus_lleg - 1.0) >= 0.08 or absf(mis_lleg - 1.0) >= 0.08):
		var abre := su_ment == Tactica.Mentalidad.OFENSIVA
		var sig := signi(gm - gs) if abre else (1 if gm > gs else -1)
		var dibujo := String(r.inicio["formacion"][suyo])
		c.append(_c("tactica", sig, 0.25 + absf(log(sus_lleg)) + absf(log(mis_lleg)) * 0.5,
			(Idiomas.t("El rival salió a por todas (%s ofensivo): partido abierto, %+d %% de llegadas suyas y %+d %% de las nuestras.") if abre
			else Idiomas.t("El rival se encerró (%s defensivo): %+d %% de llegadas suyas y %+d %% de las nuestras.")) % [dibujo,
			int(round((sus_lleg - 1.0) * 100.0)), int(round((mis_lleg - 1.0) * 100.0))]))
	var rival_id := p.visita.id if mio == 0 else p.local.id
	var plan := String(p.plan_activado.get(rival_id, ""))
	if plan != "":
		var tras_60 := [0, 0]
		for e: Dictionary in p.cronica:
			if String(e.get("tipo", "")) == "gol" and int(e["min"]) > 60:
				tras_60[1 if String(e["club"]) == rival_id else 0] += 1
		var cerrojo := plan.ends_with("cerrojo")
		## Le salió si cerrando no encajó, o yendo con todo marcó.
		var le_salio: bool = tras_60[0] == 0 if cerrojo else tras_60[1] > 0
		c.append(_c("tactica", -1 if le_salio else 1, 0.45 + 0.25 * float(tras_60[0] + tras_60[1]),
			(Idiomas.t("Desde el 60' el rival se encerró atrás y le salió.") if le_salio else Idiomas.t("Desde el 60' el rival se encerró atrás, pero le marcamos igual.")) if cerrojo else
			(Idiomas.t("Desde el 60' el rival se fue con todo arriba y le salió.") if le_salio else Idiomas.t("Desde el 60' el rival se fue con todo arriba y lo pagó."))))
	## CANSANCIO: el físico con el que llegaban y lo que pasó al final.
	var fim := int(r.inicio["fisico"][mio])
	var fis := int(r.inicio["fisico"][suyo])
	if absi(fim - fis) >= 6:
		c.append(_c("cansancio", signi(fim - fis), absf(fim - fis) / 16.0,
			(Idiomas.t("Llegamos más frescos (físico %d frente a %d).") if fim > fis else Idiomas.t("Llegamos cansados (físico %d frente a %d).")) % [fim, fis]))
	var cambios := p.cambios_local if mio == 0 else p.cambios_visita
	var tarde_contra := 0
	for e: Dictionary in p.cronica:
		if String(e.get("tipo", "")) == "gol" and int(e["min"]) >= 75 and String(e["club"]) == rival_id:
			tarde_contra += 1
	if cambios == 0 and tarde_contra > 0:
		c.append(_c("cansancio", -1, 0.5 + 0.3 * tarde_contra,
			Idiomas.t("Sin cambios, el once acabó fundido y encajamos %d después del 75'.") % tarde_contra))
	## ÁRBITRO: las rojas y lo que decidió por su cuenta.
	for ro: Dictionary in r.rojas:
		var mia := bool(ro["local"]) == (mio == 0)
		c.append(_c("arbitro", -1 if mia else 1, 0.75 + clampf(float(90 - int(ro["min"])) / 120.0, 0.0, 0.6),
			(Idiomas.t("Roja a %s en el %d': jugamos con uno menos.") if mia else Idiomas.t("Roja a %s (rival) en el %d': jugaron con uno menos.")) % [String(ro["nombre"]), int(ro["min"])]))
	var contra := 0
	var favor := 0
	for d: Dictionary in r.arbitraje:
		if bool(d["contra_local"]) == (mio == 0):
			contra += 2 if String(d["tipo"]) == "penal" else 1
		else:
			favor += 2 if String(d["tipo"]) == "penal" else 1
	if contra != favor:
		var nombre := String(p.arbitro.get("nombre", Idiomas.t("El árbitro")))
		var balance := absi(contra - favor)
		c.append(_c("arbitro", 1 if favor > contra else -1, 0.3 * balance,
			(Idiomas.t("%s decidió por su cuenta contra nosotros (%d a %d en tarjetas y penales).") if contra > favor else Idiomas.t("%s decidió por su cuenta a nuestro favor (%d a %d en tarjetas y penales).")) % [nombre, maxi(contra, favor), mini(contra, favor)]))
	## EFICACIA: lo que se generó frente a lo que se metió (el xG del motor del 3D es grueso: ahí no).
	if not r.con_motor:
		var xm: float = p.xg_local if mio == 0 else p.xg_visita
		var xs: float = p.xg_visita if mio == 0 else p.xg_local
		if absf(float(gm) - xm) >= 0.9:
			c.append(_c("eficacia", signi(int(round(float(gm) - xm))), absf(float(gm) - xm) / 1.6,
				(Idiomas.t("Pegada: metimos %d con ocasiones para %.1f.") if float(gm) > xm else Idiomas.t("Falta puntería: ocasiones para %.1f y metimos %d.")) % ([gm, xm] if float(gm) > xm else [xm, gm])))
		if absf(float(gs) - xs) >= 0.9:
			c.append(_c("eficacia", signi(int(round(xs - float(gs)))), absf(float(gs) - xs) / 1.6,
				(Idiomas.t("Nos hicieron %d con ocasiones para solo %.1f.") if float(gs) > xs else Idiomas.t("Nuestro portero los paró: tuvieron para %.1f y nos hicieron %d.")) % ([gs, xs] if float(gs) > xs else [xs, gs])))
	## LESIONES de los nuestros durante el partido.
	for le: Dictionary in r.lesiones:
		if bool(le["local"]) == (mio == 0):
			c.append(_c("lesion", -1, 0.35, Idiomas.t("Perdimos a %s por lesión en el %d'.") % [String(le["nombre"]), int(le["min"])]))
	## Y si no hubo nada más fuerte: la localía (del modelo: +8 % en casa, −6 % fuera) y la posesión.
	if not r.con_motor and not p.neutral:
		c.append(_c("localia", 1 if mio == 0 else -1, 0.15,
			Idiomas.t("Jugar en casa: un 8 % más de llegadas.") if mio == 0 else Idiomas.t("Jugar fuera: un 6 % menos de llegadas.")))
	var pos := int(round(p.posesion_local)) if mio == 0 else 100 - int(round(p.posesion_local))
	## La posesión es relleno: nunca le gana a algo que pasó de verdad (una lesión pesa 0,35).
	c.append(_c("posesion", signi(pos - 50) if absi(pos - 50) >= 8 else 0, 0.05 + absf(pos - 50) / 200.0,
		Idiomas.t("Tuvimos el balón el %d %% del partido.") % pos))
	return c

static func _c(clave: String, signo: int, peso: float, texto: String) -> Dictionary:
	return {"clave": clave, "signo": signo, "peso": peso, "texto": texto}
