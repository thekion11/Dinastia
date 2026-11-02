class_name CalidadAuto
extends RefCounted
## PERFIL «LIGERO» AUTOMÁTICO (2-11-2026, orden: 120 FPS en equipos modestos).
## La primera vez que se abre el juego en una máquina (no hay `user://grafica.cfg`) se mira el hardware; si es modesto
## (gráfica integrada antigua o por software, 4 GB de RAM o menos, 2 hilos o menos) se parte de calidad MEDIO con la
## calidad adaptativa encendida y, en PC, el motor de compatibilidad (OpenGL). Es solo el PUNTO DE PARTIDA: el jugador lo
## cambia en Ajustes y su elección manda (en cuanto existe el archivo no se vuelve a tocar). No quita nada sin decirlo:
## `ajustes` devuelve el motivo y quien llama lo muestra/registra.

const GPU_DEBIL := ["hd graphics", "uhd graphics", "gma", "llvmpipe", "swiftshader", "software", "mali-4", "mali-t", "adreno (tm) 3", "adreno (tm) 4", "powervr", "vivante"]
const RAM_DEBIL_MB := 4608   ## «4 GB» reales reportan algo menos de 4096
const HILOS_DEBIL := 2

## Describe la máquina y si es modesta. `motivos` dice por qué.
static func detectar(gpu: String = "", ram_mb: int = -1, hilos: int = -1) -> Dictionary:
	if gpu == "":
		gpu = RenderingServer.get_video_adapter_name()
	if ram_mb < 0:
		ram_mb = int(OS.get_memory_info().get("physical", 0)) / 1048576
	if hilos < 0:
		hilos = OS.get_processor_count()
	var motivos: Array[String] = []
	var g := gpu.to_lower()
	for k: String in GPU_DEBIL:
		if g.contains(k):
			motivos.append("gráfica «%s»" % gpu)
			break
	if ram_mb > 0 and ram_mb <= RAM_DEBIL_MB:
		motivos.append("%d MB de RAM" % ram_mb)
	if hilos <= HILOS_DEBIL:
		motivos.append("%d hilos de CPU" % hilos)
	return {"gpu": gpu, "ram_mb": ram_mb, "hilos": hilos, "debil": not motivos.is_empty(), "motivos": motivos}

## Llamado desde `Calidad.cargar()` cuando aún no hay archivo. Devuelve el perfil aplicado ({} si no hizo nada).
static func aplicar_si_primera_vez(info: Dictionary = {}) -> Dictionary:
	if FileAccess.file_exists(Calidad.ARCHIVO) or OS.get_environment("DINASTIA_SIN_AUTO") != "":
		return {}
	if info.is_empty():
		info = detectar()
	if not info["debil"]:
		return {}
	Calidad.elegida = Calidad.MEDIO
	Calidad.adaptativa = true
	Calidad.motor_ligero = Calidad.puede_relanzar() and not Calidad.es_compatibilidad()
	Calidad.guardar()
	print("CALIDAD AUTO: equipo modesto (%s) → MEDIO, adaptativa, motor ligero=%s" % [", ".join(info["motivos"]), Calidad.motor_ligero])
	return info
