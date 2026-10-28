class_name PrecipitacionCiudad
extends RefCounted
## LLUVIA EN LA CIUDAD (S6, 27-10-2026). `Precipitacion` cubre un campo de juego de ~60 m; la ciudad mide 5 km, así que aquí NO hay capa
## lejana: dos emisores que SIGUEN a la cámara (uno junto a ella, de gotas finas, y otro de 80 × 80 m a su alrededor) con un TOPE de
## partículas por calidad (la lluvia del partido llegaba a 15 000; en una ciudad con cientos de luces esa memoria no sobra). Y el suelo
## se moja: `CityBuilder.mojar()` baja la rugosidad del asfalto y lo oscurece.

## Partículas máximas por nivel de calidad (cerca + alrededor).
const TOPE_MEDIO := 1800
const TOPE_ALTO := 4200
const TOPE_ULTRA := 5200

static func tope(nivel: int) -> int:
	if nivel >= Calidad.ULTRA:
		return TOPE_ULTRA
	if nivel >= Calidad.ALTO:
		return TOPE_ALTO
	return TOPE_MEDIO

static func montar(padre: Node, clima: String, nivel: int = Calidad.elegida) -> Node3D:
	if clima not in ["lluvia", "tormenta"]:
		return null
	var cont := Node3D.new()
	cont.name = "LluviaCiudad"
	padre.add_child(cont)
	var presupuesto := tope(nivel)
	var cerca := Precipitacion._emisor(clima, Vector3(14.0, 6.0, 14.0), 1.0, true)
	var alrededor := Precipitacion._emisor(clima, Vector3(40.0, 10.0, 40.0), 1.0, false)
	## El reparto: un tercio junto a la cámara (lo que pasa por delante del objetivo) y el resto alrededor.
	cerca.amount = clampi(cerca.amount, 200, presupuesto / 3)
	alrededor.amount = clampi(alrededor.amount, 300, presupuesto - cerca.amount)
	_resaltar(cerca, true)
	_resaltar(alrededor, false)
	cerca.position = Vector3(0, 2.0, 0)
	cerca.visibility_aabb = AABB(Vector3(-20, -30, -20), Vector3(40, 40, 40))
	alrededor.position = Vector3(0, 9.0, 0)
	alrededor.visibility_aabb = AABB(Vector3(-45, -30, -45), Vector3(90, 60, 90))
	var sigue := Precipitacion.SigueCamara.new()
	sigue.name = "SigueCamara"
	sigue.add_child(cerca)
	sigue.add_child(alrededor)
	cont.add_child(sigue)
	CharcosLluvia.montar(cont)
	if clima == "tormenta":
		cont.add_child(Precipitacion.Relampagos.new())
	return cont

## Las partículas que lleva montadas (para medir y para las pruebas).
static func particulas(cont: Node) -> int:
	var n := 0
	for p: GPUParticles3D in cont.find_children("*", "GPUParticles3D", true, false):
		n += p.amount
	return n

## Gotas más largas y claras que en el partido (sin subir el tope): en una calle ancha la lluvia fina no se leía.
static func _resaltar(p: GPUParticles3D, cerca: bool) -> void:
	var malla := p.draw_pass_1 as QuadMesh
	malla.size = Vector2(0.02, 1.0) if cerca else Vector2(0.06, 2.2)
	var mat := malla.material as StandardMaterial3D
	mat.albedo_color = Color(0.90, 0.94, 1.0, 0.5 if cerca else 0.75)
