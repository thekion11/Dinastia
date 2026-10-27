extends Node
## f6c · AUDITORÍA DE LA CIUDAD (26-10-2026): una toma aérea y otra a pie por cada tipo de manzana
## de `CiudadExpansion` (plaza mayor, ayuntamiento, estación, mercado, cine, hospital…, y un
## ejemplar de cada barrio y distrito). Solo fotografía: no cambia la ciudad.
##   herramientas/captura.sh res://pruebas/ideas/f6c_captura_ciudad.tscn     (Forward+)
##   LADO=sur  la toma a pie desde el sur · ZONAS=cine,hospital   solo esas · HORA=11 · SALIDA=ciudad_26_10 (carpeta de pruebas/capturas)
## Sin pantalla (headless) no hace nada y termina en «FIN. 0 fallos»: `ideas.sh todo` lo salta.
const ESPERA_AEREA := 50   ## fotogramas para que la cámara orbital llegue (se mueve con suavizado)
const ESPERA_PIE := 14     ## y la del paseo
const ALTURA_AEREA := 120.0
const DIST_AEREA := 70.0
const DIST_PIE := 16.0     ## del borde de la manzana al fotógrafo: en mitad de la calle de enfrente
var _p: Node
var _v: VistaCiudad
var _e: ExploradorCiudad
var _n := 0
var _tomas: Array = []     ## {nombre, rect}
var _aerea := true
var _k := 0
var _t := 0
var _carpeta := ""

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		print("f6c: sin pantalla no se captura nada")
		print("===== FIN. 0 fallos =====")
		get_tree().quit()
		return
	AjustesCiudad.guardar("tutorial_visto", true)
	var sal := OS.get_environment("SALIDA") if OS.get_environment("SALIDA") != "" else "ciudad_26_10"
	_carpeta = "res://pruebas/capturas/" + sal
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_carpeta))
	_p = load("res://escenas/principal.tscn").instantiate()
	add_child(_p)

## DIST=9 acerca al fotógrafo (por defecto `DIST_PIE`).
func _dist_pie() -> float:
	return float(OS.get_environment("DIST")) if OS.get_environment("DIST") != "" else DIST_PIE

func _process(_d: float) -> void:
	if _p == null:
		return
	_n += 1
	if _n == 6:
		_p.call("_ver_ciudad_propia")
		for h in _p.get_children():
			if h is VistaCiudad:
				_v = h
		_v.set("_girando", false)
		_v.set("_ciclo_activo", false)
		_v.set("_hora", float(OS.get_environment("HORA")) if OS.get_environment("HORA") != "" else 11.0)
		_v.call("_aplicar_hora")
		_elegir_tomas()
		print("f6c: %d zonas" % _tomas.size())
		if OS.get_environment("SOLO") == "pie":   ## repetir solo las tomas a pie
			_aerea = false
			_v.explorar("pie")
			_e = _v.get("_explorador")
			_e.primera_persona = true
		if OS.get_environment("DEPURAR") != "":
			var ex := (_v.get("_ciudad") as CityBuilder).expansion
			for t: Dictionary in _tomas:
				print("ZONA ", t["nombre"], " celda=", t["celda"], " zona=", t["zona"], " rect=", t["rect"])
			for ro: Dictionary in ex.rotulos:
				if String(ro.get("texto", "")).contains("Centro") or String(ro.get("texto", "")).contains("Comercial"):
					print("ROTULO ", ro)
		return
	if _n < 8 or _tomas.is_empty():
		return
	if _k >= _tomas.size():
		if _aerea:
			## Segunda vuelta: a pie, con el paseo de siempre.
			_aerea = false
			_k = 0
			_v.explorar("pie")
			_e = _v.get("_explorador")
			_e.primera_persona = true   ## sin el cuerpo delante de la fachada
		else:
			get_tree().quit()
			return
	var z: Dictionary = _tomas[_k]
	var r: Rect2 = z["rect"]
	var centro := Vector3(r.get_center().x, 0.0, r.get_center().y)
	if _t == 0:
		if _aerea:
			_v.set("_objetivo", Vector3(centro.x, 8.0, centro.z))
			_v.set("_objetivo_deseado", Vector3(centro.x, 8.0, centro.z))
			_v.set("_dist", DIST_AEREA)
			_v.set("_alto", ALTURA_AEREA)
			_v.set("_ang", 0.6)
		else:
			## Frente al lado de la manzana que mira hacia fuera de la ciudad (el eje dominante),
			## en mitad de la calle de enfrente y mirando de frente a la fachada.
			var fuera := Vector2(r.get_center().x, r.get_center().y)
			var dir := fuera.normalized() if fuera.length() > 1.0 else Vector2(0, 1)
			var normal := Vector2(signf(dir.x), 0.0) if absf(dir.x) > absf(dir.y) else Vector2(0.0, signf(dir.y))
			if OS.get_environment("LADO") == "sur":   ## LADO=sur: el frente de la manzana que da al sur (+Z)
				normal = Vector2(0.0, 1.0)
			var pos := Vector3(r.get_center().x + normal.x * (r.size.x * 0.5 + _dist_pie()), 0.0, r.get_center().y + normal.y * (r.size.y * 0.5 + _dist_pie()))
			var rumbo := atan2(-normal.x, -normal.y)   ## forward = (sin, cos): mirando hacia la manzana
			_e.cuerpo.position = pos
			_e.cuerpo.position.y = _e.altura_suelo(pos.x, pos.z)
			_e.set("rumbo", rumbo)
			_e.cuerpo.rotation.y = rumbo
			_e.trafico.reciclar_peatones(_e.cuerpo.position, Vector3.ZERO, 70.0, 22, 28, true)
	if _aerea:
		_v.call("_mover_camara")
	else:
		_e.call("_colocar_camara", 1.0)
	_t += 1
	if _t >= (ESPERA_AEREA if _aerea else ESPERA_PIE):
		var ruta := "%s/%s_%s.png" % [_carpeta, z["nombre"], "aerea" if _aerea else "pie"]
		get_viewport().get_texture().get_image().save_png(ruta)
		print("FOTO ", ruta)
		_t = 0
		_k += 1

## Un ejemplar de cada tipo de manzana: los usos especiales por su nombre y los corrientes
## por zona + uso (un «casas» del norte y otro del sur no son lo mismo).
func _elegir_tomas() -> void:
	var cb := _v.get("_ciudad") as CityBuilder
	var filtro: Array = OS.get_environment("ZONAS").split(",", false)
	var visto := {}
	var especiales: Array = CiudadExpansion.ESPECIALES.values()
	for bl: Dictionary in cb.expansion.bloques:
		var uso := String(bl["uso"])
		if uso in ["rio", "lejano", ""]:
			continue
		var clave := uso if uso in especiales else "barrio_%s_%s" % [bl["zona"], uso]   ## «barrio_» evita choques con los especiales
		if visto.has(clave) or (not filtro.is_empty() and not (clave in filtro)):
			continue
		var rect: Rect2 = CiudadExpansion.FINCA_GRANDE if uso == "casa_grande" else bl["rect"]
		if rect.size.x < 20.0 or rect.size.y < 20.0:
			continue
		visto[clave] = true
		_tomas.append({"nombre": clave, "rect": rect, "celda": bl["celda"], "zona": bl["zona"]})
