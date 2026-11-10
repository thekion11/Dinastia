class_name MuseoPresentacion
extends RefCounted
## PRESENTACIÓN DEL MUSEO (10-11, sesión 7, orden 14 del dueño: «mejorar el museo»). A cada vitrina de `SalasClub.museo` se le suma, sin materiales
## nuevos (todo va en el `Lote` de la sala con los materiales que ya tiene, así que no sube las llamadas de dibujo en ULTRA BAJA):
##   · una placa dorada en la peana, de cara al pasillo;
##   · un charco de luz en el suelo (la tira emisiva de la vitrina) que marca dónde acercarse con E;
##   · un cartel con el título y el año (Label3D) en la peana, solo desde BAJA hacia arriba (cada rótulo es una llamada de dibujo).
## Y a lo largo de las dos paredes laterales un zócalo con el color del club.

## `lado`: −1 si la vitrina está pegada a la pared izquierda (el pasillo queda a +x), +1 a la derecha. `p`: suelo bajo la vitrina.
static func vitrina(lote, nodo: Node3D, m: Dictionary, p: Vector3, lado: float, hito: Dictionary, con_cartel := true) -> void:
	if OS.get_environment("SIN_PRESENTACION_MUSEO") != "":   ## para medir antes/después
		return
	var hacia := -lado   ## el lado del pasillo
	lote.caja(m["placa"], SalasClub._en(Vector3(p.x + hacia * 0.355, p.y + 0.55, p.z)), Vector3(0.02, 0.16, 0.38))
	lote.caja(m["tira"], SalasClub._en(Vector3(p.x + hacia * 0.62, p.y + 0.045, p.z)), Vector3(0.5, 0.004, 0.6))
	if not con_cartel or Calidad.elegida <= Calidad.MINIMO or hito.is_empty():
		return
	var anio := int(hito.get("anio", 0))
	var texto := Idiomas.t(String(hito.get("titulo", "")))
	if anio > 0:
		texto += " · " + str(anio)
	## Ajustado al ancho de la peana (0,62 m): letra grande y, si no cabe, se encoge.
	PiezasObra._rotulo_ajustado(nodo, texto, Vector3(p.x + hacia * 0.375, p.y + 0.5, p.z), hacia * PI / 2.0, 26, Color(0.96, 0.84, 0.45), 0.62)

## Zócalo de color de club en las dos paredes laterales de la sala.
static func zocalo(lote, m: Dictionary, caja: Rect2, y0: float) -> void:
	if OS.get_environment("SIN_PRESENTACION_MUSEO") != "":
		return
	for x: float in [caja.position.x - 0.05, caja.end.x + 0.05]:
		lote.caja(m["cam1"], SalasClub._en(Vector3(x, y0 + 0.2, caja.get_center().y)), Vector3(0.03, 0.22, caja.size.y))

## Gallardetes del club colgados de las dos paredes laterales, sobre las vitrinas (a y0 + 2,55): uno por vitrina, alternando los dos colores. Mismos materiales del lote.
static func gallardetes(lote, m: Dictionary, caja: Rect2, y0: float, zs: Array) -> void:
	if OS.get_environment("SIN_PRESENTACION_MUSEO") != "":
		return
	var k := 0
	for z: float in zs:
		for x: float in [caja.position.x - 0.07, caja.end.x + 0.07]:
			lote.caja(m["cam1"] if k % 2 == 0 else m["cam2"], SalasClub._en(Vector3(x, y0 + 2.7, z)), Vector3(0.03, 0.7, 0.45))
			lote.caja(m["metal"], SalasClub._en(Vector3(x, y0 + 3.08, z)), Vector3(0.05, 0.04, 0.55))
		k += 1
