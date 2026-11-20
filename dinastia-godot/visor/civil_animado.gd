class_name CivilAnimado
## LOS CIVILES DEL PERSONAL, ANIMADOS (20-11). Orden del dueño: los civiles (obrero, traje, casual…) son SOLO del personal del club y
## los realistas, solo del jugador. Los civiles no traen clips (solo un reposo procedural): con su modelo el personal «patinaba» al
## caminar y no hacía los gestos de su oficio. Como el avatar regalo: debajo va el cuerpo Quaternius del juego con sus mallas ocultas
## (anima caminar, parado y la librería «banda»), y el civil copia sus rotaciones con `AvatarRegaloRetarget` y este mapa de huesos.
## Devuelve el mismo diccionario que `FutbolistaQ.crear()` (+ "avatar"), así `PersonalEstadio` lo trata como a cualquiera.

## Grados que se abren los brazos para que las manos no atraviesen la ropa (medido el 20-11 en las 3 hojas del personal): mujeres con falda o pantalón.
const ABRIR_MUJER := 12.0
const ABRIR_HOMBRE := 3.0

## Quaternius (origen) → esqueleto de los civiles modulares (49 huesos). Padres antes que hijos.
const MAPA := {
	"pelvis": "Hips", "spine_01": "Abdomen", "spine_02": "Torso", "spine_03": "Chest", "neck_01": "Neck", "Head": "Head",
	"clavicle_l": "Shoulder.L", "upperarm_l": "UpperArm.L", "lowerarm_l": "LowerArm.L", "hand_l": "Hand.L",
	"clavicle_r": "Shoulder.R", "upperarm_r": "UpperArm.R", "lowerarm_r": "LowerArm.R", "hand_r": "Hand.R",
	"thigh_l": "UpperLeg.L", "calf_l": "LowerLeg.L", "foot_l": "Foot.L",
	"thigh_r": "UpperLeg.R", "calf_r": "LowerLeg.R", "foot_r": "Foot.R",
	"index_01_l": "Index2.L", "index_02_l": "Index3.L", "index_03_l": "Index4.L",
	"middle_01_l": "Middle2.L", "middle_02_l": "Middle3.L", "middle_03_l": "Middle4.L",
	"ring_01_l": "Ring2.L", "ring_02_l": "Ring3.L", "ring_03_l": "Ring4.L",
	"pinky_01_l": "Pinky2.L", "pinky_02_l": "Pinky3.L", "pinky_03_l": "Pinky4.L",
	"thumb_01_l": "Thumb2.L", "thumb_02_l": "Thumb3.L",
	"index_01_r": "Index2.R", "index_02_r": "Index3.R", "index_03_r": "Index4.R",
	"middle_01_r": "Middle2.R", "middle_02_r": "Middle3.R", "middle_03_r": "Middle4.R",
	"ring_01_r": "Ring2.R", "ring_02_r": "Ring3.R", "ring_03_r": "Ring4.R",
	"pinky_01_r": "Pinky2.R", "pinky_02_r": "Pinky3.R", "pinky_03_r": "Pinky4.R",
	"thumb_01_r": "Thumb2.R", "thumb_02_r": "Thumb3.R",
}

## Los hombres civiles numeran los dedos 2-4 (pulgar 2-3) y las mujeres 1-3 (pulgar 1-3): el mapa se ajusta al esqueleto.
static func mapa_para(esq: Skeleton3D) -> Dictionary:
	if esq.find_bone("Index4.L") >= 0:
		return MAPA
	var m := {}
	for k: String in MAPA:
		var v := String(MAPA[k])
		for dedo: String in ["Index", "Middle", "Ring", "Pinky", "Thumb"]:
			for n in [2, 3, 4]:
				if v.begins_with("%s%d." % [dedo, n]):
					v = v.replace("%s%d." % [dedo, n], "%s%d." % [dedo, n - 1])
					break
		m[k] = v
	if esq.find_bone("Thumb3.L") >= 0:
		m["thumb_03_l"] = "Thumb3.L"
		m["thumb_03_r"] = "Thumb3.R"
	return m

## `padre` ya en el árbol. `clave` de `FutbolistaQ.civiles()` o `FutbolistaQ.PERSONAL`. {} si no se puede.
static func crear(padre: Node3D, clave: String, altura: float, piel := Color(0, 0, 0, 0), pelo := Color(0, 0, 0, 0), variante := 0) -> Dictionary:
	if not FutbolistaQ.ajeno_disponible(clave):
		return {}
	var fila: Array = FutbolistaQ.PERSONAL[clave] if FutbolistaQ.PERSONAL.has(clave) else FutbolistaQ.civiles()[clave]
	var d := FutbolistaQ.crear(altura, "male")   ## el motor de huesos: mismas animaciones para todos (solo se copian rotaciones)
	if d.is_empty():
		return {}
	padre.add_child(d["nodo"])
	FutbolistaQ.terminar(d, false)
	for mi in (d["modelo"] as Node).find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visible = false
	var da := FutbolistaQ.ajeno(d["nodo"], clave, altura, piel, pelo, variante)
	if da.is_empty():
		return d
	## Su reposo procedural pelearía con el retarget: lo manda el cuerpo del juego.
	for ip in (da["nodo"] as Node).find_children("*", "IdleProcedural", true, false):
		ip.queue_free()
	for n in (da["nodo"] as Node).get_children():
		if n is IdleProcedural:
			n.queue_free()
	var esq_c := FutbolistaQ.esqueleto_de(da["modelo"])
	if esq_c != null:
		var rt := AvatarRegaloRetarget.new()
		rt.name = "CivilRetarget"
		esq_c.add_child(rt)
		rt.abrir_brazos = ABRIR_MUJER if String(fila[2]) == "female" else ABRIR_HOMBRE
		rt.configurar(d["esqueleto"] as Skeleton3D, mapa_para(esq_c))
		rt.active = true
	d["avatar"] = da["nodo"]
	d["ajeno"] = false
	## El «parado» normal, no el de persona (`parado_persona` junta los brazos al cuerpo del atleta y, con falda o pantalón ancho, las manos atravesaban la ropa).
	if (d["anim"] as AnimationPlayer).has_animation("parado"):
		(d["anim"] as AnimationPlayer).play("parado")
	return d
