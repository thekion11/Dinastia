class_name Movil
extends RefCounted
## TU MÓVIL (28-9-2026, pedido: "deben haber más aplicaciones del teléfono,
## poder personalizar el teléfono" y "la cara que sea del personaje o que los
## jugadores puedan poner una de su galería").
##
## Lo que es del teléfono y no de una red: cómo se ve (fondo de pantalla,
## funda, tamaño de letra), tu foto de perfil (tu retrato del creador de
## personaje o una imagen de tu galería) y la app de Mensajes, donde escriben
## la directiva, tu familia, el community manager del club... Las apps que
## muestran datos del juego (Noticias, Banco, Calendario) los leen del mundo;
## aquí solo vive lo que el jugador elige o recibe.

## clave -> [nombre, color de arriba, color de abajo] ("club"/"club2" = los
## colores de tu club).
const FONDOS := {
	"noche": ["Noche", "1b2140", "0b0e1a"],
	"atardecer": ["Atardecer", "f08a4b", "6a2c70"],
	"cesped": ["Césped", "3f8f4a", "143d1c"],
	"oceano": ["Océano", "2f80c0", "0b2a4a"],
	"club": ["Colores del club", "club", "club2"],
	"grafito": ["Grafito", "4a4f57", "17191d"],
}
## [nombre, color]; "club" = el color principal de tu club.
const FUNDAS := [["Negra", "1a1a1a"], ["Blanca", "eeeeee"], ["Roja", "c0392b"], ["Azul", "1f5fa8"],
	["Verde", "2e8b57"], ["Dorada", "d4a92a"], ["Violeta", "8e44ad"], ["De tu club", "club"]]
## [nombre, factor]
const LETRAS := [["Pequeña", 0.9], ["Normal", 1.0], ["Grande", 1.15]]
const RUTA_FOTO := "user://foto_perfil.png"
const MAX_MENSAJES := 60

var fondo := "noche"
var funda := "1a1a1a"
var letra := 1
var foto_perfil := "retrato"   ## "retrato" (tu personaje) o "galeria"
var mensajes: Array[Dictionary] = []   ## {de, icono, texto, anio, semana, leido}

func recibir(de: String, icono: String, texto: String, anio: int, semana: int) -> void:
	mensajes.push_front({"de": de, "icono": icono, "texto": texto, "anio": anio, "semana": semana, "leido": false})
	if mensajes.size() > MAX_MENSAJES:
		mensajes.resize(MAX_MENSAJES)

## Algunas noticias también te llegan como mensaje de alguien: [de, icono], o
## vacío si no es cosa de nadie en concreto.
static func remitente_de(titulo: String, cuerpo: String) -> Array:
	var t := (titulo + " " + cuerpo).to_lower()
	for par: Array in [
			[["directiva", "confianza", "junta", "despedido", "presidente"], "Directiva", "🏛️"],
			[["casa", "familia", "hijo", "pareja", "mascota"], "Familia", "🏠"],
			[["oferta", "representante", "agente", "renovación", "contrato"], "Tu representante", "🦈"],
			[["lesión", "lesion", "médico", "medico"], "Cuerpo médico", "🩺"]]:
		for palabra: String in par[0]:
			if t.contains(palabra):
				return [par[1], par[2]]
	return []

func sin_leer() -> int:
	var n := 0
	for msj: Dictionary in mensajes:
		if not bool(msj["leido"]):
			n += 1
	return n

func leer_todo() -> void:
	for msj: Dictionary in mensajes:
		msj["leido"] = true

## Los chats: un remitente por fila, con su último mensaje y los no leídos.
func chats() -> Array[Dictionary]:
	var por := {}
	var orden: Array[String] = []
	for msj: Dictionary in mensajes:
		var de := String(msj["de"])
		if not por.has(de):
			por[de] = {"de": de, "icono": msj["icono"], "ultimo": msj["texto"], "sin_leer": 0, "mensajes": []}
			orden.append(de)
		(por[de]["mensajes"] as Array).append(msj)
		if not bool(msj["leido"]):
			por[de]["sin_leer"] = int(por[de]["sin_leer"]) + 1
	var out: Array[Dictionary] = []
	for de in orden:
		out.append(por[de])
	return out

## Un color del móvil: resuelve "club"/"club2" con los colores de tu club.
static func color(clave: String, c: Club) -> Color:
	if clave == "club":
		return Color(c.color1) if c != null else Color("1f5fa8")
	if clave == "club2":
		return Color(c.color2).darkened(0.35) if c != null else Color("0b2a4a")
	return Color(clave)

func color_funda(c: Club) -> Color:
	return color(funda, c)

func factor_letra() -> float:
	return float(LETRAS[clampi(letra, 0, LETRAS.size() - 1)][1])

## TU FOTO DE PERFIL: la de tu galería si la elegiste (y sigue ahí), si no tu
## retrato, el mismo de la ficha del DT.
func textura_perfil(m: Mundo) -> Texture2D:
	if foto_perfil == "galeria" and FileAccess.file_exists(RUTA_FOTO):
		var img := Image.load_from_file(RUTA_FOTO)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	if m != null and m.roles != null:
		return CaraDT.textura(m.roles.look_efectivo(), 128)
	return null

## Copia una imagen de la galería como foto de perfil: recorta el cuadrado del
## centro y la deja en 256×256. Devuelve "" o el motivo del fallo.
func usar_foto_de_galeria(ruta: String) -> String:
	var img := Image.load_from_file(ruta)
	if img == null or img.is_empty():
		return "no se pudo abrir esa imagen"
	var lado := mini(img.get_width(), img.get_height())
	var recorte := img.get_region(Rect2i((img.get_width() - lado) / 2, (img.get_height() - lado) / 2, lado, lado))
	recorte.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	if recorte.save_png(RUTA_FOTO) != OK:
		return "no se pudo guardar la foto"
	foto_perfil = "galeria"
	return ""

func a_dic() -> Dictionary:
	return {"fondo": fondo, "funda": funda, "letra": letra, "foto": foto_perfil, "msj": mensajes.duplicate(true)}

func desde_dic(d: Dictionary) -> void:
	if d.is_empty():
		return
	fondo = String(d.get("fondo", fondo))
	funda = String(d.get("funda", funda))
	letra = int(d.get("letra", letra))
	foto_perfil = String(d.get("foto", foto_perfil))
	mensajes.clear()
	for msj: Variant in d.get("msj", []):
		mensajes.append((msj as Dictionary).duplicate(true))
