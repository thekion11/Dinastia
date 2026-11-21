class_name ProgresoJugador
extends RefCounted
## LA CURVA DE PROGRESO DE LOS FUTBOLISTAS (25-10-2026, paquete cant). Junta en un sitio las dos mitades que antes
## vivían separadas y se pisaban: la ANUAL (`Mundo.nueva_temporada()`) y la SEMANAL del resto del mundo
## (`Entrenamiento.procesar_ajeno()`). Por separado parecían prudentes; sumadas, un chico de 17 con 56 llegaba a 81
## a los 21, en cinco temporadas había diez 80+ con menos de 23, la edad media bajaba de 26,9 a 25,1 y el valor
## medio del mundo se multiplicaba por 2,6 con la media casi plana. Ahora:
##  - crecer es más lento cuanto más mayor (la mayor parte del salto es a los 17-20);
##  - el TECHO SE GASTA: de los 19 a los 26, si no lo alcanza, pierde 0-2 puntos por año (la mayoría de las
##    promesas no llega a lo que se esperaba de ellas; antes el potencial era una garantía);
##  - los veteranos empiezan a bajar a los 30.
## Lo mide `pruebas/ideas/cant_estabilidad.gd` (pirámide estable en cinco temporadas).

## El factor por edad del freno (única fuente: lo dibuja también `FichaPorque.ritmo_por_edad`).
static func por_edad(edad: int) -> float:
	var nat := Nativo.de("nuc_por_edad")
	if nat != null:
		return nat.nuc_por_edad(edad)
	return por_edad_gd(edad)

## Gemela GDScript de `nuc_por_edad` (extensión C++, orden 63): respaldo sin binario y comparación en `pruebas/probar_nativo_puras.gd`.
static func por_edad_gd(edad: int) -> float:
	return 0.8 if edad <= 20 else (0.4 if edad <= 22 else 0.25)

## El freno común a toda subida semanal (la tuya y la del resto): con la edad y al acercarse al techo. Los últimos
## puntos hasta el potencial cuestan más que los primeros; con el 0,10 plano un chico de tu academia pasaba de 70 a
## 88 entre los 17 y los 20. Lo usan `prob_semanal()` y `Entrenamiento._sesion_general()/_plan_por_dias()`.
static func freno(j: Jugador) -> float:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("prog_freno"):   ## (19-11) en C++ (`nativo/src/carrera_nativo.cpp`); la versión de abajo es su gemela
		return nat.prog_freno(j.edad, j.ovr, j.pot)
	return _freno_gd(j)

static func _freno_gd(j: Jugador) -> float:
	if j.ovr >= j.pot or j.edad >= 24:
		return 0.0
	return por_edad(j.edad) * clampf(float(j.pot - j.ovr) / 8.0, 0.35, 1.0)

## Prob. semanal de +1 para quien NO es tuyo (unas 30 semanas de liga al año). Tu plantel va por su plan.
static func prob_semanal(j: Jugador) -> float:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("prog_prob_semanal"):   ## (19-11) en C++; gemela: `_prob_semanal_gd`
		return nat.prog_prob_semanal(j.edad, j.ovr, j.pot, j.rasgo == "motor")
	return _prob_semanal_gd(j)

static func _prob_semanal_gd(j: Jugador) -> float:
	var p := 0.10 * _freno_gd(j)
	if j.rasgo == "motor":
		p *= 1.5
	return p

## El salto del cumpleaños, para todo el mundo (también tu plantel).
static func anual(j: Jugador) -> void:
	if j.edad <= 24 and j.ovr < j.pot:
		## Hasta su techo, no más (la prueba larga encontró chicos dos puntos por encima de su potencial).
		j.ajustar_media(mini(Azar.ent(0, 2) if j.edad <= 20 else Azar.ent(0, 1), j.pot - j.ovr))
	elif j.edad >= 31:
		j.ajustar_media(-Azar.ent(0, 3))
	elif j.edad == 30 and Azar.suerte(0.5):
		j.ajustar_media(-1)
	if j.edad >= 19 and j.edad <= 26 and j.pot > j.ovr:
		j.pot = maxi(j.ovr, j.pot - Azar.ent(0, 2))
		j.tasar()
