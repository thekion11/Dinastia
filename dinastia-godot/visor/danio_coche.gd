class_name DanioCoche
extends RefCounted
## LOS DAÑOS DEL COCHE (31-10-2026, mejora C; `docs/04_auditorias/coches_31_10.md`). Cada golpe del coche del
## jugador (el explorador anota la hora en `_t_golpe` y la fuerza en `_sacudida_golpe`) suma daño en
## `VidaDT.danio` (0-100): unos 2 puntos por m/s del golpe. Se ve en la carrocería (`coche_danio.gdshader`,
## una capa de abolladuras y arañazos) y, con `VidaDT.DANIO_TALLER` o más, el coche va al taller esa semana
## y vuelve reparado la siguiente (`VidaDT.semana`).

const PUNTOS_POR_MS := 2.0
static var _mat: ShaderMaterial

## Cada fotograma en coche (desde `VidaCiudad.gasolina_tick`): ¿hubo un golpe nuevo?
static func tick(vida: VidaCiudad) -> void:
	var e := vida.expl
	var vd := vida.mundo.vida
	if vd == null or e == null:
		return
	if not vida.has_meta("t_golpe"):
		vida.set_meta("t_golpe", e._t_golpe)
		pintar(e, vd.danio)
		return
	if float(vida.get_meta("t_golpe")) == e._t_golpe:
		return
	vida.set_meta("t_golpe", e._t_golpe)
	var antes := vd.danio
	vd.danio = clampi(vd.danio + roundi(e._sacudida_golpe * 18.0 * PUNTOS_POR_MS), 0, 100)
	pintar(e, vd.danio)
	if antes < VidaDT.DANIO_TALLER and vd.danio >= VidaDT.DANIO_TALLER:
		vida._notificar(Idiomas.t("🔧 El coche está muy golpeado: la próxima vez que salgas irá al taller esta semana."))

## Pone la capa de daños en la carrocería del coche (todas sus mallas).
static func pintar(e: ExploradorCiudad, danio: int) -> void:
	if e == null or e.cuerpo == null or String(e.modo) != "coche":
		return
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://visor/coche_danio.gdshader")
	_mat.set_shader_parameter("danio", clampf(float(danio) / 100.0, 0.0, 1.0))
	for mi: MeshInstance3D in e.cuerpo.find_children("*", "MeshInstance3D", true, false):
		mi.material_overlay = _mat if danio > 0 else null
