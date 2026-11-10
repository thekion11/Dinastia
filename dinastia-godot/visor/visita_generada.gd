class_name VisitaGenerada
extends RefCounted
## EL SEGUNDO UNIFORME PROPIO de los clubes que no lo traen archivado en `AspectoClub` (10-11, orden del líder): determinista (hash del id, no el azar del juego),
## a partir de los colores y el diseño del primero. Mismo formato que `AspectoClub.visita` ({c1, c2, camiseta, pant, med}, hex con #).
##   · primero claro → la visita va de oscuro (su secundario si es oscuro, si no casi negro); primero oscuro → blanco (o los colores invertidos, a la mitad).
##   · el diseño del primero se conserva con los colores cambiados; si el local es liso, la visita lleva uno de ALTERNATIVOS (franjas, aros, diagonal…).
## Quien ya tiene el segundo archivado lo conserva (se mira antes), y `Puente3D.kit_visita` sigue descartándolo si choca con el local.
const ALTERNATIVOS := ["franjas", "aros", "diagonal", "hombros", "mitad", "banda"]
const OSCURO := "#1b1f26"
const BLANCO := "#f4f4f4"

static func _hex(c: Color) -> String:
	return "#" + c.to_html(false)

## ¿Es el segundo uniforme «mínimo» que deduce `herramientas/aspecto_clubes.py` (liso, pantalón y medias del color de la camiseta)? Ese se completa.
static func es_basica(v: Dictionary) -> bool:
	return v.is_empty() or (String(v.get("camiseta", "liso")) == "liso" and v.get("pant", v.get("c1")) == v.get("c1") and v.get("med", v.get("c1")) == v.get("c1"))

## El segundo uniforme del club: el archivado si es de verdad (diseño propio), si es el mínimo se queda con sus colores y gana diseño, pantalón y medias.
static func para(c: Club) -> Dictionary:
	var v := AspectoClub.visita(c)
	if not es_basica(v):
		return v
	var g := de(c)
	if v.is_empty():
		return g
	var out := {"c1": String(v["c1"]), "c2": String(v["c2"]), "camiseta": g["camiseta"]}
	out["pant"] = out["c2"] if Puente3D.distancia_color(Color(out["c1"]), Color(out["c2"])) > 0.3 else out["c1"]
	out["med"] = out["c1"]
	return out

static func de(c: Club) -> Dictionary:
	var k1 := Color(c.color_kit1())
	var k2 := Color(c.color_kit2())
	var h := absi(hash(c.id + "visita2"))
	var invertir := Puente3D.distancia_color(k1, k2) > 0.45 and h % 2 == 0
	var c1: String
	var c2 := _hex(k1)
	if invertir:
		c1 = _hex(k2)
		c2 = _hex(k1)
	elif k1.get_luminance() > 0.55:
		c1 = _hex(k2) if k2.get_luminance() < 0.3 else OSCURO
	else:
		c1 = BLANCO
	var dis: String = String(DisenosKit._diseno_de(c))
	if dis == "liso":
		dis = String(ALTERNATIVOS[(h / 2) % ALTERNATIVOS.size()])
	var pant := c2 if Puente3D.distancia_color(Color(c1), Color(c2)) > 0.3 else c1
	return {"c1": c1, "c2": c2, "camiseta": dis, "pant": pant, "med": c1}
