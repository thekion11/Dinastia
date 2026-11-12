extends "res://nucleo/mundo_p7_p1.gd"
## (Parte 2 de 2 de `mundo_p7.gd`.)

# ---------------------------------------------------------------------------
#  EL INFORME DE GESTIÓN
# ---------------------------------------------------------------------------
#
# «Resumen semanal tipo informe de gestión» (idea 245). Es una pantalla que no
# añade ninguna mecánica: junta en un sitio las seis cosas que hay que mirar
# cada lunes y que hoy están repartidas por ocho pestañas.
#
# POR QUÉ HACE FALTA. Este juego tiene dieciocho pestañas. Un jugador nuevo no
# sabe cuáles mirar y uno veterano se olvida de una. El informe no decide nada:
# dice qué está mal esta semana y a qué pestaña ir.

func informe_de_gestion() -> Array[Dictionary]:
	var salida: Array[Dictionary] = []
	var mio := mi_club()
	if mio == null:
		return salida

	## 1. La caja, que es lo único que puede acabar la partida sin jugar.
	var caja_ref := Eco.ref_caja(float(mio.rep))
	if mio.saldo < 0:
		salida.append({"grave": true, "txt": "La caja está en rojo (%s). Cada semana así cuesta intereses." % Cesiones.dinero(mio.saldo), "tab": "Finanzas", "secc": "cuentas"})
	elif float(mio.saldo) < caja_ref * 0.25:
		salida.append({"grave": false, "txt": "La caja está justa: %s. Cuidado con el próximo fichaje." % Cesiones.dinero(mio.saldo), "tab": "Finanzas", "secc": "cuentas"})

	## 2. Quién no puede jugar el domingo.
	var fuera := 0
	for j: Jugador in mio.plantilla:
		if j.lesion > 0 or j.suspension > 0:
			fuera += 1
	if fuera > 0:
		salida.append({"grave": fuera >= 4, "txt": "%d jugador%s no está%s disponible%s." % [
			fuera, "es" if fuera > 1 else "", "n" if fuera > 1 else "", "s" if fuera > 1 else ""], "tab": "Enfermería"})

	## 3. Los contratos que se acaban: es el aviso que más caro sale ignorar.
	var acaban := 0
	for j2: Jugador in mio.plantilla:
		if j2.anios_contrato <= 1:
			acaban += 1
	if acaban > 0:
		salida.append({"grave": acaban >= 4, "txt": "%d contrato%s termina%s este año. Sin renovar, se van gratis." % [
			acaban, "s" if acaban > 1 else "", "n" if acaban > 1 else ""], "tab": "Contratos"})

	## 4. El vestuario.
	var descontentos := 0
	for j3: Jugador in mio.plantilla:
		if j3.moral < 40 or j3.pide_salir:
			descontentos += 1
	if descontentos > 0:
		salida.append({"grave": descontentos >= 5, "txt": "%d jugador%s con la moral por los suelos o pidiendo salir." % [
			descontentos, "es" if descontentos > 1 else ""], "tab": "Camarín"})

	## 5. La calle y el despacho.
	if prensa != null and prensa.funa >= 55:
		salida.append({"grave": prensa.funa >= 75, "txt": "El ruido en redes está en %d. La directiva lo lee." % prensa.funa, "tab": "Redes"})
	if directiva != null and directiva.confianza < 40:
		salida.append({"grave": directiva.confianza < 25, "txt": "La confianza del directorio está en %d. Estás en la cuerda floja." % directiva.confianza, "tab": "Club"})

	## 6. Lo que se puede hacer y no se está haciendo.
	if mercado_abierto() and semanas_de_mercado() <= 2:
		salida.append({"grave": false, "txt": "El mercado cierra en %d semana(s)." % semanas_de_mercado(), "tab": "Mercado"})
	if entrenamiento != null and entrenamiento.dt_puntos > 0:
		salida.append({"grave": false, "txt": "Tienes %d punto(s) de entrenador sin gastar." % entrenamiento.dt_puntos, "tab": "Legado"})
	if not amistoso_hecho and semana <= 3:
		salida.append({"grave": false, "txt": "Todavía no has jugado la pretemporada: el plantel llega frío.", "tab": "Entrenar", "secc": "pretemporada"})
	if auspicio != null and auspicio.contrato.is_empty() and not auspicio.ofertas.is_empty():
		salida.append({"grave": false, "txt": "Hay %d marcas esperando respuesta por la camiseta." % auspicio.ofertas.size(), "tab": "Finanzas", "secc": "patrocinio"})

	if salida.is_empty():
		salida.append({"grave": false, "txt": "Todo en orden: sin lesionados largos, sin contratos en el aire y con la caja sana.", "tab": ""})
	return salida
## LA IA RENUEVA UN AÑO ANTES (25-10; antes 60% del mundo en su último año; 26-10: 0,65/0,30, con 0,8 bajaba al 11%). Tu club no.
func _vence_contrato(j: Jugador, c: Club) -> bool:
	c = clubes.get(String(cesiones.cesion_de(j.id).get("de", "")), c) if cesiones != null else c   ## A4-GES-009: decide su DUEÑO, no quien lo tiene cedido
	var h := absi(hash("%s|%d|anticipada" % [j.id, anio]))
	if c.id != mi_club_id and j.anios_contrato == 2 and float(h % 1000) / 1000.0 < (0.3 if j.edad >= 32 else 0.65):
		j.anios_contrato = Contratos.ajustar_anios(j, 1 + (h / 1000) % 2 if j.edad >= 32 else 2 + (h / 1000) % 3)
		return false
	var antes := j.anios_contrato
	var se_va := super(j, c)
	if not se_va and antes == 1 and c.id != mi_club_id and j.edad < 32:
		j.anios_contrato = maxi(j.anios_contrato, 2)   ## la renovación a cero tampoco vuelve al último año
	return se_va
