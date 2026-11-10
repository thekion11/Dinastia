class_name CalidadRes3D
extends RefCounted
## RESOLUCIÓN 3D AUTOMÁTICA (10-11, informe `rendimiento_movil_2026-11-10.md`, P1): el partido está limitado por píxeles (a ¼ de píxeles el fotograma baja 40-43 %) y un móvil dibuja el 3D a su pantalla
## entera (2400×1080 = 2,8 veces 720p). Con `Calidad.res3d_auto` activo, de ULTRA BAJA a MEDIA el 3D no pasa de `ALTURA_3D_MAX` píxeles de alto (escala = min(la del nivel, 720 / alto de la ventana));
## la interfaz sigue a resolución nativa y ALTA/ULTRA no se tocan. Encendida por defecto solo en móvil (Android/iOS/Web táctil); en escritorio se enciende en Ajustes.
const ALTURA_3D_MAX := 720.0

static func es_movil_tactil() -> bool:
	return OS.has_feature("mobile") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available())

## Alto de la ventana en píxeles (RES3D_ALTO lo simula en las pruebas y las capturas).
static func alto_pantalla() -> float:
	if OS.get_environment("RES3D_ALTO") != "":
		return float(OS.get_environment("RES3D_ALTO"))
	return float(DisplayServer.window_get_size().y)

## El tope de escala que impone la altura máxima (1.0 si la ventana ya cabe; nunca por debajo del mínimo posible).
static func tope_escala(alto_px: float) -> float:
	return 1.0 if alto_px <= ALTURA_3D_MAX else maxf(ALTURA_3D_MAX / alto_px, Calidad.ESCALA_MIN_POSIBLE)

## Para las vistas 3D SECUNDARIAS a pantalla completa (casa, sorteo, rueda de prensa del prólogo): el mismo tope de altura que el partido, si la resolución automática está activa.
static func limitar(vp: Viewport) -> void:
	if Calidad.res3d_auto and Calidad.elegida <= Calidad.MEDIO and vp != null:
		vp.scaling_3d_scale = minf(vp.scaling_3d_scale, tope_escala(alto_pantalla()))
