extends "res://visor/trafico_ciudad_p1.gd"
## [Capa intermedia de `trafico_ciudad.gd`] (18-11-2026, ciudad a C++) El `_process` del tráfico elige entre la extensión nativa (`DinastiaNativo.trafico_paso`,
## nativo/src/trafico_nativo.cpp: traducción literal de `_paso_gd`) y la versión GDScript (`_paso_gd`, en `trafico_ciudad.gd`: respaldo de Android/Web y referencia
## de `pruebas/probar_nativo_ciudad.tscn`). Lo que la extensión no hace (animación, gestos, mirada) lo llama de vuelta con los `_cb_*` de abajo.

## Sirenas encendidas (las registra `ServiciosVida`) y a qué distancia hacen parar al tráfico: a 55 m, frenando a FRENADA, da tiempo de parar a 14 m/s.
static var sirenas: Array[Node3D] = []
## Falso = fuerza la versión GDScript (pruebas de igualdad).
var usar_nativo := true
## Lo que la extensión necesita para hacer sola la comprobación de `libre_fn` (lo rellena el explorador; vacío = usa `libre_fn`).
var libre_ctx := {}
## (18-11, estado de los móviles en C++) `lod`, `dt` y `alto` de cada móvil viven en la extensión mientras corre `trafico_paso`; los diccionarios de `_vehiculos` no
## los llevan al día. `volcar_estado_nativo()` los escribe en ellos (pruebas, o al volver a la versión GDScript); subir `_ver_estado` obliga a la extensión a releerlos.
var _ver_estado := 0
var _nativo_sucio := false

func volcar_estado_nativo() -> void:
	var nat := Nativo.obj()
	if nat != null and nat.has_method("trafico_volcar"):
		nat.trafico_volcar(self)

func _paso_gd(_delta_real: float) -> void:
	pass   ## lo implementa `trafico_ciudad.gd`

func _process(delta_real: float) -> void:
	var nat := Nativo.obj() if usar_nativo else null
	if nat == null or not nat.has_method("trafico_paso"):
		if _nativo_sucio:   ## venía de la extensión: los diccionarios aún no tienen su `lod` y `dt`
			volcar_estado_nativo()
			_ver_estado += 1
			_nativo_sucio = false
		_paso_gd(delta_real)
		return
	_nativo_sucio = true
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var hay_jugador := jugador != null and is_instance_valid(jugador)
	nat.trafico_paso(self, delta_real, cam != null, cam.global_position if cam != null else Vector3.ZERO,
			-cam.global_transform.basis.z if cam != null else Vector3.ZERO, hay_jugador,
			jugador.global_position if hay_jugador else Vector3.ZERO, sirenas)

## Llamadas de vuelta desde C++.
func _cb_peaton_reanuda(v: Dictionary) -> void:
	PeatonVida.movil(v, false)
	_animar(v, "caminar")

func _cb_peaton_espera(v: Dictionary, azar: float) -> void:
	PeatonVida.esperar(self, v, azar)

func _cb_mirada(v: Dictionary, dist2: float, delta: float) -> void:
	MovimientoNatural.mirada(v, jugador, dist2, delta)

func _cb_mn_clip(v: Dictionary, nombre: String, k: float) -> void:
	MovimientoNatural._clip(v, nombre, k)

func _cb_mn_vel(v: Dictionary, vel: float) -> void:
	MovimientoNatural._velocidad(v, vel)
