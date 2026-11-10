class_name OcultarEstadioDentro
extends RefCounted
## DENTRO DEL EDIFICIO DEL CLUB, EL ESTADIO DE FUERA NO SE DIBUJA (10-11-2026, rendimiento en móvil). Medido con `pruebas/medir_club.tscn` (ULTRA BAJA, Compatibilidad, CHI): a pie por las plantas
## -2, -1, 1 y 2 el club pedía ~850 llamadas y 1,1 M de triángulos porque la cámara (sin oclusión) dibujaba también las gradas, la hinchada, las torres de focos y el entorno que quedan DETRÁS de las
## paredes de la sala. Sin ellos: ~340-370 llamadas y ~130 k triángulos (fotograma relativo −60 %), con la sala idéntica (capturas antes/después en el informe).
## Se ocultan los hijos de primer nivel del estadio (`_raiz3d`) que no son luces, cámara, el edificio (`TunelVestuario`), la calle (`Exterior`) ni la fachada (`Fachada`): lo único que se ve por la
## ventana trasera. Solo en las plantas distintas de la 0 (la 0 tiene el túnel y el campo a la vista). Se guarda lo que estaba visible antes y se devuelve tal cual al salir al campo o del recorrido.

const CONSERVAR := ["TunelVestuario", "Exterior", "Fachada"]
const META := "estadio_oculto_dentro"

## Llamar cada vez que se refresca la zona del recorrido (barato: solo actúa al entrar o salir).
## OCLUSIÓN POR SALA EN LA PLANTA 0 (10-11, sesión 7): el vestuario es una sala cerrada; el estadio solo se ve por la boca del túnel. Con `zona` = «Vestuario» y la
## cámara mirando a otra parte (la boca del túnel, el plano z = `datos.z_out`, fuera del cuerpo de visión), el estadio también se oculta, y vuelve en cuanto la boca
## entra en el campo de visión: no desaparece nada que se viera. `camara` y `datos` (los del explorador) son opcionales; sin ellos, como antes.
static func actualizar(explorador: Node3D, planta: int, zona := "", camara: Camera3D = null, datos: Dictionary = {}) -> void:
	var dentro := planta != 0 or (zona == "Vestuario" and camara != null and not datos.is_empty() and not boca_visible(camara, datos))
	var ocultos: Dictionary = explorador.get_meta(META, {})
	if dentro == not ocultos.is_empty():
		return
	if dentro:
		var raiz := explorador.get_parent()
		if raiz == null:
			return
		for h in raiz.get_children():
			if not (h is Node3D) or h is Light3D or h is Camera3D or h == explorador or String(h.name) in CONSERVAR:
				continue
			ocultos[h] = (h as Node3D).visible
			(h as Node3D).visible = false
		explorador.set_meta(META, ocultos)
	else:
		devolver(explorador)

## ¿Alguna parte de la boca del túnel (la abertura del vestuario hacia el campo) cae dentro del campo de visión de `camara`? Rejilla de 0,6 m sobre la abertura
## y, si la cámara está a menos de 1,5 m del plano de la boca, siempre sí (la rejilla podría quedar entre dos puntos).
static func boca_visible(camara: Camera3D, datos: Dictionary) -> bool:
	if not camara.is_inside_tree():
		return true
	var x0: float = datos["x0"]
	var z := float(datos["z_out"])
	var pos: Vector3 = camara.position
	if absf(pos.z - z) < 1.5:
		return true
	var medio := TunelMedidas.MEDIO + 0.5   ## con margen para los marcos
	var padre := camara.get_parent() as Node3D
	var x := -medio
	while x <= medio + 0.01:
		var y := 0.0
		while y <= TunelMedidas.ALTO + 0.5:
			var q := Vector3(x0 + x, y, z)
			if camara.is_position_in_frustum(padre.to_global(q) if padre != null else q):
				return true
			y += 0.6
		x += 0.6
	return false

## Deja el estadio como estaba (también al cerrar el recorrido).
static func devolver(explorador: Node3D) -> void:
	var ocultos: Dictionary = explorador.get_meta(META, {})
	for h: Variant in ocultos:
		if is_instance_valid(h):
			(h as Node3D).visible = bool(ocultos[h])
	explorador.set_meta(META, {})
