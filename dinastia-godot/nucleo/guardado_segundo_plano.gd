class_name GuardadoSegundoPlano
extends RefCounted
## EL AUTOGUARDADO SIN CONGELAR EL MENÚ (3-11-2026, rediseño del menú central, etapa 4). Guardar un mundo grande (todas las ligas: ~470 clubes, 5,6 MB de JSON,
## 0,7 MB comprimido) costaba ~1,2 s en el hilo principal: instantánea 0,2 s, JSON 0,4-0,8 s, empaquetar y escribir 0,3 s. Ahora el hilo principal solo hace la
## instantánea y una copia profunda de ella (~0,4 s en el mundo entero, ~0,05 s en cuatro países: así el hilo que escribe no comparte NADA con el juego, que sigue
## cambiando) y el JSON, la compresión, la huella y el disco van a un hilo aparte. El guardado de siempre (`Partida.guardar`) sigue existiendo para los botones
## de las ranuras y el cierre.
##
## - Si se pide otro guardado mientras uno se escribe, no se apila: se anota y, al terminar, se hace UNO más con el estado de ese momento.
## - `esperar()` bloquea hasta que termine el que esté en curso: lo llaman cargar y salir.
## - `PartidaArchivo.escribir` lleva su cerrojo: este hilo y un guardado normal nunca tocan el mismo archivo a la vez.

static var _tarea := -1
static var _id := 0                  ## número del guardado en curso (el aviso diferido de uno viejo no cierra el siguiente)
static var _resultado := [false, 0]  ## lo escribe el hilo y se lee tras esperarlo: [salió bien, ms totales]
static var _repetir := false
static var _mundo: WeakRef = null
static var _nombre := ""
static var _al_acabar := Callable()
## Lo que el último guardado costó en el hilo principal y en total (ms), y si salió bien; las lee la prueba y la medición.
static var ms_principal := 0
static var ms_total := 0
static var ultimo_ok := true

static func en_curso() -> bool:
	return _tarea >= 0

## Pide guardar `m` en la ranura `nombre`. `al_acabar(ok: bool)` se llama en el hilo principal cuando el archivo ya está en disco.
static func iniciar(m: Mundo, nombre: String, al_acabar := Callable()) -> void:
	_mundo = weakref(m)
	_nombre = nombre
	_al_acabar = al_acabar
	if _tarea >= 0:
		_repetir = true
		return
	var t0 := Time.get_ticks_msec()
	var ruta := Partida.ruta_de(Partida.ranura_para(m, nombre))
	var datos := Partida.instantanea(m).duplicate(true)
	Partida._cabeceras.erase(ruta)   ## (la caché de cabeceras es del hilo principal: se invalida aquí y no en el hilo)
	ms_principal = Time.get_ticks_msec() - t0
	_id += 1
	_tarea = WorkerThreadPool.add_task(_escribir.bind(datos, ruta, t0, _id), false, "Guardado")

static func _escribir(datos: Dictionary, ruta: String, t0: int, id: int) -> void:
	var ok := PartidaArchivo.escribir(ruta, JSON.stringify(datos, "", false, true).to_utf8_buffer(), false)
	_resultado = [ok, Time.get_ticks_msec() - t0]
	_terminado.call_deferred(id)

static func _terminado(id: int) -> void:
	if id == _id:
		_cerrar(true)

## Recoge el guardado en curso: espera a su hilo, anota el resultado y avisa. `repetir`: si se pidió otro mientras tanto, hace UNO más con el estado de ahora.
static func _cerrar(repetir: bool) -> void:
	if _tarea < 0:
		return
	var t := _tarea
	_tarea = -1
	WorkerThreadPool.wait_for_task_completion(t)
	ultimo_ok = bool(_resultado[0])
	ms_total = int(_resultado[1])
	var quiere_repetir := _repetir
	_repetir = false
	var m := _mundo.get_ref() as Mundo if _mundo != null else null
	if quiere_repetir and repetir and m != null:
		iniciar(m, _nombre, _al_acabar)
		return
	if _al_acabar.is_valid():
		_al_acabar.call(ultimo_ok)

## Espera a que termine el guardado en curso (si lo hay) y lo cierra. Seguro desde el hilo principal; lo llaman cargar, guardar a mano y salir.
static func esperar() -> void:
	_cerrar(false)
