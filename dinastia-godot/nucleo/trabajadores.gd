class_name Trabajadores
extends "res://nucleo/trabajadores_p1.gd"
## (Parte 2 de 2 de `trabajadores.gd`.)

## Texto corto del equipo entero (fichas de instalación).
func texto_equipo(c: Club, obras: Instalaciones, clave: String) -> String:
	var partes: Array[String] = []
	for t: Dictionary in equipo(c, obras, clave):
		partes.append("%s · %s (%s, hab. %d, ánimo %d)" % [String(t["puesto"]), String(t["nombre"]),
			String(CARACTERES[String(t["caracter"])][0]).to_lower(), int(t["hab"]), int(t["moral"])])
	if int(averias.get(clave, 0)) > 0:
		partes.append("⚠ Avería: %d semanas" % int(averias[clave]))
	return "\n".join(partes)

func a_dic() -> Dictionary:
	return {"equipos": equipos.duplicate(true), "averias": averias.duplicate(), "pendiente": pendiente.duplicate(), "sig": _sig}

func desde_dic(d: Dictionary) -> void:
	equipos = (d.get("equipos", {}) as Dictionary).duplicate(true)
	averias = (d.get("averias", {}) as Dictionary).duplicate()
	pendiente = (d.get("pendiente", {}) as Dictionary).duplicate()
	_sig = int(d.get("sig", 0))
