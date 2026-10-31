class_name PedidoPartida
extends RefCounted
## Lo que las pantallas previas (inicio, modo, elección de club, prólogo) le dejan pedido a la
## pantalla principal antes de cambiar de escena. Antes eran variables estáticas de `Principal`;
## salen aquí en la fase 6, paso 7 del plan §7.1 (27-10-2026).

## La pantalla de inicio deja aquí la partida cargada antes de cambiar de
## escena -no hay otra forma de pasarle un argumento a una escena que arranca
## sola por `run/main_scene`-. Si sigue vacía, se entra con mundo nuevo.
static var mundo_a_cargar: Mundo = null
## Lo mismo, pero para el modo de carrera elegido en la pantalla previa
## (`ui/seleccion_modo.gd`). Vacío = el DT clásico de siempre, para que abrir
## `principal.tscn` directo -como sigue haciendo el banco de capturas- no
## dependa de haber pasado por esa pantalla.
static var modo_elegido: String = ""
## La tarjeta "Tutorial" del menú: la próxima carrera arranca con el recorrido
## guiado aunque ya se haya visto (ver `ui/componentes/tutorial.gd`).
static var tutorial_pedido: bool = false
## "Crear tu Club" desde el menú: la elección de club abre con el panel de
## fundar arriba y destacado (26-9-2026).
static var fundar_pedido: bool = false
## El reto elegido en el menú (`Retos`): la elección de club lo monta sola.
static var reto_pedido: String = ""
static var dt_nombre_elegido: String = "Míster"
static var dificultad_elegida: String = "normal"
## Del asistente completo (`ui/eleccion_club.gd`): el mundo YA generado -las 24
## ligas- y con `tomar_el_mando()` ya hecho sobre el club que se eligió a mano.
## A esto solo le falta aplicar dificultad y modo, que es lo que hace
## `_arrancar_con()`. Se comprueba ANTES que `mundo_a_cargar` en `_ready()`
## porque son mutuamente excluyentes -nunca deberían venir los dos a la vez-
## y da igual el orden real; se listan así porque es el camino más nuevo.
static var mundo_pregenerado: Mundo = null
## Los desafíos marcados en `ui/eleccion_club.gd`, paso 5 del asistente del
## HTML. Vacío = partida normal, igual que los demás canales.
static var desafios_elegidos: Array[String] = []

## (Fase 0 §7.2, 31-10) El mundo al que ya se le aplicó lo pedido (para no aplicarlo dos veces:
## el orquestador lo aplica antes de autoguardar y `Principal` lo encuentra hecho).
static var aplicado_a := 0   ## `get_instance_id()` (no se retiene el mundo)

## Aplica a un mundo recién generado lo pedido en las pantallas previas: dificultad (escala la caja
## inicial, «plata» del HTML), desafíos (después: «pobreza» pisa la caja de la dificultad), modo de
## carrera y nombre del DT (y la caja propia del fondo de inversión). Antes vivía en
## `CicloPartida.arrancar_con`; sale aquí para que el orquestador pueda guardar la partida completa.
static func aplicar(m: Mundo) -> void:
	if m == null or aplicado_a == m.get_instance_id():
		return
	aplicado_a = m.get_instance_id()
	m.dificultad = dificultad_elegida
	var dif: Variant = Datos.tabla("DIF")
	if dif is Dictionary and (dif as Dictionary).has(dificultad_elegida) and m.mi_club() != null:
		var plata := float((dif as Dictionary)[dificultad_elegida].get("plata", 1.0))
		m.mi_club().saldo = int(round(float(m.mi_club().saldo) * plata))
	if not desafios_elegidos.is_empty():
		m.desafios = desafios_elegidos.duplicate()
		m.aplicar_desafios()
		desafios_elegidos = []
	## Vacío = se abrió `principal.tscn` directo (bancos, capturas): el DT clásico de siempre.
	if modo_elegido != "":
		m.roles.arrancar(modo_elegido, dt_nombre_elegido)
		if modo_elegido == "fondo" and m.mi_club() != null:
			m.fondo = FondoInversion.new()
			m.fondo.caja = int(round(Eco.ref_caja(70.0) * 2.5))
		modo_elegido = ""
