class_name CaraEdad
extends RefCounted
## LA EDAD EN LA CARA 2D DEL JUGADOR (10-11, brecha de caras frente al PES 2020): canas, entradas, calvicie y arrugas que siguen a `j.edad`.
## Se aplica a todos los que NO llevan el color medido de una foto real (inventados, cara típica por país, malla): determinista por el id.
## El 3D ya envejece por su lado (`PersonajeDtVida.arrugas_de/canas_de/entradas_de`); aquí es solo la ficha/retrato.

## Arrugas 0 (hasta ~30 años) .. 1 (unos 45): se dibujan en `Cara` con la clave `arrugas`.
static func arrugas_de(edad: int) -> float:
	return clampf(float(edad - 30) / 15.0, 0.0, 1.0)

static func _h(j: Jugador, sal: String) -> int:
	return absi((j.id + sal).hash())

## Canas (gris a partir de los 32, a uno de cada cuatro casi nada), entradas (desde los 33 cambia el corte a «entradas» a uno de cada tres)
## y calvicie (desde los 36 a ~1 de cada 8, más con los años). No toca el pelo de quien ya es calvo ni de las mujeres de pelo largo.
static func aplicar(base: Dictionary, j: Jugador) -> void:
	if OS.get_environment("SIN_EDAD_CARA") != "":   ## (para las capturas antes/después)
		return
	base["arrugas"] = arrugas_de(j.edad)
	if j.edad < 32 or not base.has("peloC"):
		return
	var vel := 0.25 if _h(j, "canas") % 4 == 0 else 1.0
	var k := clampf(float(j.edad - 31) / 14.0 * vel, 0.0, 0.6)
	base["peloC"] = "#" + Color(String(base["peloC"])).lerp(Color("#a3a19c"), k).to_html(false)
	var corte := String(base.get("pelo", ""))
	if corte in ["calvo", "afro", "melena", "melena_rizada", "mohicano", "samurai", "coleta"]:
		return
	if j.edad >= 36 and _h(j, "calvicie") % 100 < 8 + (j.edad - 36) * 2:
		base["pelo"] = "calvo"
	elif j.edad >= 33 and _h(j, "entradas") % 3 == 0:
		base["pelo"] = "entradas"

## Líneas de expresión: patas de gallo y surco de la frente según el grado (0..1). Vacío si es joven.
static func arrugas_svg(k: float) -> String:
	if k < 0.12:
		return ""
	var o := 0.12 + 0.28 * k
	var s := '<g stroke="#3a2418" stroke-opacity="%.2f" stroke-width=".5" fill="none" stroke-linecap="round">' % o
	s += '<path d="M21.5 33.5l-2-.8M21.7 35l-2 .3M42.5 33.5l2-.8M42.3 35l2 .3"/>'
	if k > 0.35:
		s += '<path d="M25 25.6q7-1.4 14 0"/>'
	if k > 0.65:
		s += '<path d="M26 28.2q6-1 12 0M29.4 38.6q-1.4 3-.8 6M34.6 38.6q1.4 3 .8 6"/>'
	return s + "</g>"
