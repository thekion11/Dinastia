class_name Cara
extends "res://ui/cara_p1.gd"
## (Parte 2 de 2 de `cara.gd`.)

# --- el retrato completo ----------------------------------------------------

static func svg_de(j: Jugador, k1: String = "#2b6b45", k2: String = "#ffffff") -> String:
	var lk := look_de(j)
	var cara := int(lk["cara"])
	var rx: float = CARAS_RX[cara]
	var ry: float = CARAS_RY[cara]
	var top: float = 33.5 - ry - 1.0
	var pc := String(lk["peloC"])
	var piel := String(lk["piel"])
	var pelos := _pelo(String(lk["pelo"]), pc, rx, top, k1, k2)
	var barba := _barba(int(lk["barba"]), pc, rx)
	var acc := _accesorio(String(lk["acc"]), rx, top, k1, k2)
	var oreja: float = OREJAS[int(lk["orejas"])]
	var iris: String = IRIS[int(lk["ojos"])]
	var ceja := int(lk["ceja"])

	var mentones := [
		"M%.1f 44q%.1f 8 %.1f 0" % [32.0 - rx * 0.62, rx * 0.62, rx * 1.24],
		"M%.1f 43l%.1f 8 %.1f -8" % [32.0 - rx * 0.58, rx * 0.58, rx * 0.58],
		"M%.1f 43h%.1fl-2 7h-%.1fz" % [32.0 - rx * 0.66, rx * 1.32, rx * 1.32 - 4.0],
	]
	var narices := [
		"M32 35.5l-2 4.2h4z",
		"M32 36l-1.6 3.6q1.6 1 3.2 0z",
		"M31.4 35l-2.6 4.6q3.2 1.2 6 0L32 35z",
		"M32 35.8l-2.2 3.8h4.4z",
	]
	var b := int(lk["boca"])
	var bocas := [
		"M27.5 %.1fq4.5 2.6 9 0" % (43.5 + float(b)),
		"M27.5 %.1fh9" % (43.5 + float(b)),
		"M27.5 %.1fq4.5 -2.4 9 0" % (44.0 + float(b)),
	]

	var pecas := ""
	if bool(lk["pecas"]):
		pecas = '<g fill="#8a5a3a" opacity=".45">'
		for i in 6:
			pecas += '<circle cx="%d" cy="%d" r=".7"/>' % [25 + ((i * 7) % 14), 37 + ((i * 5) % 4)]
		for i in 4:
			pecas += '<circle cx="%d" cy="%d" r=".7"/>' % [35 + ((i * 5) % 10), 37 + ((i * 3) % 4)]
		pecas += "</g>"

	var extras := ""
	if bool(lk["cicatriz"]):
		extras += '<path d="M%.1f 27l2.4 5.4" stroke="#a8756a" stroke-width="1" opacity=".7"/>' % (32.0 + rx * 0.5)
	if bool(lk["lunar"]):
		extras += '<circle cx="%.1f" cy="41.6" r=".85" fill="#5a3a2a" opacity=".72"/>' % (32.0 - rx * 0.62)

	var alto_ojo := 1.5 if int(lk["ojos"]) == 3 else 2.3
	return """<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
<defs>
<linearGradient id="pl" x1="0.15" y1="0" x2="0.9" y2="1">
<stop offset="0" stop-color="#ffffff" stop-opacity=".22"/>
<stop offset="0.45" stop-color="#ffffff" stop-opacity="0"/>
<stop offset="1" stop-color="#000000" stop-opacity=".34"/></linearGradient>
<linearGradient id="fd" x1="0" y1="0" x2="0" y2="1">
<stop offset="0" stop-color="%s" stop-opacity=".38"/>
<stop offset="1" stop-color="%s" stop-opacity=".10"/></linearGradient>
<radialGradient id="mej" cx="0.5" cy="0.5" r="0.5">
<stop offset="0" stop-color="#d4665a" stop-opacity=".22"/><stop offset="1" stop-color="#d4665a" stop-opacity="0"/></radialGradient>
</defs>
<rect width="64" height="64" rx="12" fill="url(#fd)"/>
<circle cx="32" cy="30" r="21" fill="#ffffff" opacity=".05"/>
<path d="M11 64c2-13 10-17 21-17s19 4 21 17z" fill="%s" stroke="%s" stroke-width="1.3"/>
<path d="M26 47l6 7 6-7-6-2.6z" fill="%s" opacity=".85"/>
<rect x="%.1f" y="41" width="%.1f" height="9" fill="%s"/>
<path d="M%.1f 44q%.1f 3 %.1f 0v6h-%.1fz" fill="#00000022"/>
%s
<ellipse cx="%.1f" cy="35" rx="%.1f" ry="%.1f" fill="%s"/>
<ellipse cx="%.1f" cy="35" rx="%.1f" ry="%.1f" fill="%s"/>
<ellipse cx="%.1f" cy="35" rx="%.1f" ry="%.1f" fill="#00000022"/>
<ellipse cx="%.1f" cy="35" rx="%.1f" ry="%.1f" fill="#00000022"/>
<ellipse cx="32" cy="33.5" rx="%.1f" ry="%.1f" fill="%s"/>
<path d="%s" fill="%s"/>
<ellipse cx="32" cy="33.5" rx="%.1f" ry="%.1f" fill="url(#pl)"/>
<ellipse cx="%.1f" cy="38" rx="4" ry="3" fill="url(#mej)"/>
<ellipse cx="%.1f" cy="38" rx="4" ry="3" fill="url(#mej)"/>
%s
%s%s
<ellipse cx="26" cy="33" rx="3.1" ry="%.1f" fill="#f6f7f4"/>
<circle cx="26" cy="33" r="1.5" fill="%s"/><circle cx="26" cy="33" r=".65" fill="#0d0d0d"/>
<circle cx="26.7" cy="32.3" r=".42" fill="#ffffff" opacity=".9"/>
<path d="M22.9 32.6q3.1 -2.4 6.2 0" stroke="#00000055" stroke-width="1.1" fill="none" stroke-linecap="round"/>
<ellipse cx="38" cy="33" rx="3.1" ry="%.1f" fill="#f6f7f4"/>
<circle cx="38" cy="33" r="1.5" fill="%s"/><circle cx="38" cy="33" r=".65" fill="#0d0d0d"/>
<circle cx="38.7" cy="32.3" r=".42" fill="#ffffff" opacity=".9"/>
<path d="M34.9 32.6q3.1 -2.4 6.2 0" stroke="#00000055" stroke-width="1.1" fill="none" stroke-linecap="round"/>
<path d="M22.3 %.1fq3.7 -2.1 7.4 0" stroke="%s" stroke-width="%.2f" fill="none" stroke-linecap="round"/>
<path d="M34.3 %.1fq3.7 -2.1 7.4 0" stroke="%s" stroke-width="%.2f" fill="none" stroke-linecap="round"/>
<path d="%s" fill="#00000026"/>
<path d="M32 34.4v4.4" stroke="#00000018" stroke-width="1" stroke-linecap="round"/>
<path d="%s" stroke="#8a453b" stroke-width="1.7" fill="none" stroke-linecap="round"/>
%s
%s
</svg>""" % [
		k1, k1,
		k1, k2,
		k2,
		32.0 - rx * 0.34, rx * 0.68, piel,
		32.0 - rx * 0.34, rx * 0.34, rx * 0.68, rx * 0.68,
		pelos[1],
		32.0 - rx - 1.0, oreja, oreja * 1.5, piel,
		32.0 + rx + 1.0, oreja, oreja * 1.5, piel,
		32.0 - rx - 1.0, oreja * 0.45, oreja * 0.8,
		32.0 + rx + 1.0, oreja * 0.45, oreja * 0.8,
		rx, ry, piel,
		mentones[int(lk["menton"])], piel,
		rx, ry,
		32.0 - rx * 0.55, 32.0 + rx * 0.55,
		pecas,
		pelos[0], barba,
		alto_ojo, iris,
		alto_ojo, iris,
		28.8 - float(ceja) * 0.8, pc, 1.7 + float(ceja) * 0.35,
		28.8 - float(ceja) * 0.8, pc, 1.7 + float(ceja) * 0.35,
		narices[int(lk["nariz"])],
		bocas[b],
		extras, acc,
	]

static func _indice_fotos_de() -> Dictionary:
	if not _indice_fotos_listo:
		_indice_fotos = {}
		_creditos_fotos = {}
		if FileAccess.file_exists(RUTA_RETRATOS):
			var fr := FileAccess.open(RUTA_RETRATOS, FileAccess.READ)
			var jr := JSON.new()
			if jr.parse(fr.get_as_text()) == OK and jr.data is Dictionary:
				for nombre: String in (jr.data as Dictionary):
					var fila: Variant = (jr.data as Dictionary)[nombre]
					if fila is Dictionary and String((fila as Dictionary).get("archivo", "")) != "":
						_indice_fotos[nombre] = "res://" + String((fila as Dictionary)["archivo"])
						_creditos_fotos[nombre] = "%s · %s" % [String((fila as Dictionary).get("autor", "desconocido")),
							String((fila as Dictionary).get("licencia", ""))]
			fr.close()
		if _indice_fotos.is_empty() and FileAccess.file_exists(RUTA_REPORTE_FOTOS):
			var f := FileAccess.open(RUTA_REPORTE_FOTOS, FileAccess.READ)
			var texto := f.get_as_text()
			f.close()
			var jp := JSON.new()
			if jp.parse(texto) == OK and jp.data is Array:
				for fila: Variant in (jp.data as Array):
					if fila is Dictionary and bool((fila as Dictionary).get("encontrado", false)):
						var archivo := String((fila as Dictionary).get("archivo", ""))
						if archivo != "":
							_indice_fotos[String((fila as Dictionary).get("nombre", ""))] = "res://" + archivo
		_indice_fotos_listo = true
	return _indice_fotos

## Lee un retrato por su ruta (cacheado).
static func foto_de_ruta(ruta: String) -> Texture2D:
	var clave := "foto_%s" % ruta
	if _cache.has(clave):
		return _cache[clave]
	## Se lee el archivo A MANO -bytes crudos, `Image.load_png/jpg_from_buffer()`-
	## en vez de `load()`/`ResourceLoader`, por dos motivos que costó encontrar:
	## 1) `load()` exige que Godot ya haya importado el archivo (un `.import`
	##    generado en un reimportado previo), y la búsqueda de fotos sigue
	##    bajando archivos nuevos sesión tras sesión -habría que reimportar el
	##    proyecto entero cada vez que aparece uno nuevo para que se vieran-.
	## 2) Un tramo de la búsqueda guardó PNG con extensión ".jpg" -el nombre
	##    sale del nombre del jugador, no del formato real del archivo que
	##    devuelve Wikimedia-, y `load()` decide el decodificador POR LA
	##    EXTENSIÓN: un PNG llamado ".jpg" fallaba con "Failed loading
	##    resource" aunque el archivo fuera perfectamente válido. Mirando los
	##    primeros bytes -la firma de cada formato- se decodifica con el que
	##    corresponde de verdad, sin que importe cómo se llame el archivo.
	var f := FileAccess.open(ruta, FileAccess.READ)
	if f == null:
		return null
	var datos := f.get_buffer(f.get_length())
	f.close()
	if datos.size() < 8:
		return null
	var img := Image.new()
	var es_png := datos.size() >= 8 and datos[0] == 0x89 and datos[1] == 0x50 and datos[2] == 0x4E and datos[3] == 0x47
	var err := img.load_png_from_buffer(datos) if es_png else img.load_jpg_from_buffer(datos)
	if err != OK:
		## Firma no reconocida a la primera -o un jpg mal etiquetado de png-:
		## se prueba el decodificador contrario antes de rendirse.
		err = img.load_jpg_from_buffer(datos) if es_png else img.load_png_from_buffer(datos)
	if err != OK:
		return null
	var w := img.get_width()
	var h := img.get_height()
	var lado := mini(w, h)
	## Recorte centrado, algo por encima de la mitad: las fotos de prensa
	## suelen dejar mucho hombro y poco pelo si se recorta desde el centro
	## exacto de la imagen.
	var x := (w - lado) / 2
	var y := maxi(0, int(float(h - lado) * 0.28))
	img = img.get_region(Rect2i(x, y, lado, lado))
	if lado > 256:
		img.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t

static func foto_real(j: Jugador) -> Texture2D:
	## Con la base ficticia no se enseña ninguna foto de una persona real,
	## aunque el guardado traiga jugadores marcados como reales.
	if not j.real or not Datos.base_real or not usar_fotos:
		return null
	var ruta := String(_indice_fotos_de().get(Nombres.limpiar(j.nombre), ""))
	if ruta == "":
		return null
	return foto_de_ruta(ruta)

## El retrato 2D antiguo (SVG o foto): solo para pruebas sin pantalla.
static func textura_2d(j: Jugador, k1: String, k2: String, alto_px: int = 40) -> Texture2D:
	var foto := foto_real(j)
	if foto != null:
		return foto
	var clave := "%s_%d_%s" % [j.id, alto_px, k1]
	if _cache.has(clave):
		return _cache[clave]
	var img := Image.new()
	if img.load_svg_from_string(svg_de(j, k1, k2), float(alto_px) * 3.0 / 64.0) != OK:
		return null
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t

## El retrato rasterizado. Se cachea por jugador y tamaño: la lista del plantel
## pide 25 caras en cada repintado y rasterizar SVG no es gratis.
##
## Si es un futbolista real Y ya se le encontró una foto libre, esa foto pisa
## al retrato procedural -ver `foto_real()`-. El resto sigue con la cara de
## siempre, tenga o no `j.real`: no hay nada que fingir mientras la búsqueda
## en segundo plano no le haya encontrado nada.
static func textura(j: Jugador, k1: String, k2: String, alto_px: int = 40) -> Texture2D:
	## EL RETRATO ES EL MODELO 3D (14-10-2026): la cara que sale en cualquier lista
	## o ficha es el busto del mismo modelo que juega (`Retrato3D`). Sin pantalla
	## (pruebas headless) se cae al retrato de siempre.
	if Retrato3D.disponible():
		return Retrato3D.textura(j, k1, k2, alto_px)
	return textura_2d(j, k1, k2, alto_px)

## La ruta del retrato real de un jugador, o "" (mismas reglas que `foto_real`).
static func ruta_foto(j: Jugador) -> String:
	if not j.real or not Datos.base_real or not usar_fotos:
		return ""
	return String(_indice_fotos_de().get(Nombres.limpiar(j.nombre), ""))

## El crédito de la foto que se está enseñando, o "" si no hay foto real. Las
## licencias de Commons (CC BY / BY-SA) exigen nombrar autor y licencia allí
## donde se muestra la foto, y avisar de que se modificó: la ficha lo pone bajo
## el retrato, y la lista completa va en `datos/creditos_fotos.txt`.
static func credito_foto(j: Jugador) -> String:
	if foto_real(j) == null:
		return ""
	var c := String(_creditos_fotos.get(Nombres.limpiar(j.nombre), ""))
	return "Foto: %s · Wikimedia Commons, recortada" % c if c != "" else ""

## Cuántos reales tienen ya foto encontrada, para enseñarlo en algún sitio sin
## tener que releer el reporte entero cada vez.
static func fotos_encontradas() -> int:
	return _indice_fotos_de().size()

static func limpiar_cache() -> void:
	_cache.clear()
	_indice_fotos_listo = false

static func svg_rasgos(lk: Dictionary) -> String:
	var cara := clampi(int(lk.get("cara", 0)), 0, CARAS_RX.size() - 1)
	var rx: float = CARAS_RX[cara]
	var pc := String(lk.get("peloC", "#231a14"))
	var b := clampi(int(lk.get("boca", 0)), 0, 2)
	var bocas := [
		"M28 %.1fq4 2.2 8 0" % (43.5 + float(b)),
		"M28 %.1fq4 .6 8 0" % (43.5 + float(b)),
		"M28 %.1fq4 -1.8 8 0" % (44.0 + float(b)),
	]
	var narices := [
		"M30.3 39.4q1.7 1 3.4 0",
		"M30.6 39.2q1.4 1.1 2.8 0",
		"M29.6 39.3q2.4 1.4 4.8 0",
		"M30.2 39.1q1.8 .9 3.6 0",
	]
	var s := '<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">'
	s += '<defs><radialGradient id="mej" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#e89080" stop-opacity=".45"/><stop offset="1" stop-color="#e89080" stop-opacity="0"/></radialGradient>'
	s += '<radialGradient id="och" cx="0.5" cy="0.35" r="0.6"><stop offset="0" stop-color="#8a6a58" stop-opacity=".55"/><stop offset="1" stop-color="#8a6a58" stop-opacity="0"/></radialGradient></defs>'
	## Mejillas y cuenca de los ojos (sombra suave).
	s += '<ellipse cx="25.2" cy="38.6" rx="3.6" ry="2.6" fill="url(#mej)"/><ellipse cx="38.8" cy="38.6" rx="3.6" ry="2.6" fill="url(#mej)"/>'
	s += '<ellipse cx="26" cy="33" rx="4.4" ry="3.4" fill="url(#och)"/><ellipse cx="38" cy="33" rx="4.4" ry="3.4" fill="url(#och)"/>'
	if bool(lk.get("pecas", false)):
		s += '<g fill="#9a6040" opacity=".55">'
		var h := hash(lk)
		var rng := RandomNumberGenerator.new()
		rng.seed = h
		for i in 22:
			var lado := -1.0 if i % 2 == 0 else 1.0
			var px := 32.0 + lado * rng.randf_range(2.0, 9.5)
			var py := rng.randf_range(35.0, 40.5) - maxf(0.0, 4.0 - absf(px - 32.0)) * 0.6
			s += '<circle cx="%.2f" cy="%.2f" r="%.2f" opacity="%.2f"/>' % [px, py, rng.randf_range(0.2, 0.42), rng.randf_range(0.4, 1.0)]
		s += "</g>"
	## La barba va aparte (`textura_barba`): el shader la pinta como pelo
	## corto con ruido, no como una mancha lisa.
	## Pestañas: la línea del párpado de arriba y la sombra de abajo.
	s += '<path d="M22.8 32.4q3.2 -2.6 6.4 0M34.8 32.4q3.2 -2.6 6.4 0" stroke="#1a0f0a" stroke-opacity=".75" stroke-width=".9" fill="none" stroke-linecap="round"/>'
	s += '<path d="M23.4 34.6q2.6 1.3 5.2 0M35.4 34.6q2.6 1.3 5.2 0" stroke="#3a2418" stroke-opacity=".3" stroke-width=".7" fill="none" stroke-linecap="round"/>'
	## Nariz: aletas y sombra lateral.
	s += '<path d="%s" stroke="#3a2418" stroke-opacity=".45" stroke-width=".9" fill="none" stroke-linecap="round"/>' % narices[clampi(int(lk.get("nariz", 0)), 0, 3)]
	s += '<path d="M30.6 34.6q-.5 2.4 -.4 4" stroke="#3a2418" stroke-opacity=".16" stroke-width="1" fill="none"/>'
	## Boca: labios y la comisura.
	s += '<path d="%s" stroke="#d8a098" stroke-width="1.6" fill="none" stroke-linecap="round"/>' % bocas[b]
	s += '<path d="%s" stroke="#4a2a24" stroke-opacity=".7" stroke-width=".55" fill="none" stroke-linecap="round"/>' % bocas[b]
	s += '<path d="M29 %.1fq3 1.4 6 0" stroke="#e0aaa0" stroke-opacity=".7" stroke-width="1.3" fill="none" stroke-linecap="round"/>' % (45.4 + float(b))
	if bool(lk.get("cicatriz", false)):
		s += '<path d="M%.1f 27l2.4 5.4" stroke="#a8756a" stroke-width=".9" opacity=".7"/>' % (32.0 + rx * 0.5)
	if bool(lk.get("lunar", false)):
		s += '<circle cx="%.1f" cy="41.6" r=".7" fill="#5a3a2a" opacity=".75"/>' % (32.0 - rx * 0.62)
	return s + "</svg>"

## Los rasgos rasterizados a 256x256, cacheados por aspecto.
static func textura_rasgos(lk: Dictionary) -> Texture2D:
	var clave := "rasgos_%d" % hash(lk)
	if _cache.has(clave):
		return _cache[clave]
	var img := Image.new()
	if img.load_svg_from_string(svg_rasgos(lk), 4.0) != OK:
		return null
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t

## La barba sola, en blanco (el shader la tiñe y le pone el ruido del pelo).
## null si no lleva.
static func textura_barba(lk: Dictionary) -> Texture2D:
	var bi := int(lk.get("barba", 0))
	if bi <= 0:
		return null
	var clave := "barba_%d_%d" % [bi, int(lk.get("cara", 0))]
	if _cache.has(clave):
		return _cache[clave]
	var rx: float = CARAS_RX[clampi(int(lk.get("cara", 0)), 0, CARAS_RX.size() - 1)]
	var svg := '<svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">%s</svg>' % _barba(bi, "#ffffff", rx)
	var img := Image.new()
	if img.load_svg_from_string(svg, 4.0) != OK:
		return null
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_cache[clave] = t
	return t

## El nombre (clave de los índices de retratos) de la foto en `ruta`.
static func nombre_de_ruta(ruta: String) -> String:
	for k: String in _indice_fotos_de():
		if String(_indice_fotos[k]) == ruta:
			return k
	return ruta.get_file().get_basename()

## Ojos, boca y (si está) nariz del retrato real, de 0 a 1, o [] si no se
## encontraron.
static func puntos_foto(ruta: String) -> Array:
	if not _puntos_listos:
		_puntos_listos = true
		if FileAccess.file_exists(PUNTOS_FOTOS):
			var jp := JSON.new()
			if jp.parse(FileAccess.get_file_as_string(PUNTOS_FOTOS)) == OK and jp.data is Dictionary:
				_puntos_fotos = jp.data
	var p: Variant = _puntos_fotos.get(nombre_de_ruta(ruta))
	return p if p is Array and (p as Array).size() >= 6 else []

## Todo lo que el 3D necesita para poner la cara de un jugador (lo arma
## `Puente3D.jugador`): el aspecto y, si es real y tiene retrato calzable, la foto.
static func datos_3d(j: Jugador) -> Dictionary:
	var d := {"look": look_de(j)}
	var ruta := ruta_foto(j)
	## Una foto marcada como mala para 3D (muy de lado o desde arriba) no se
	## proyecta: queda la recreación con sus colores.
	if ruta != "" and (not puntos_foto(ruta).is_empty() or CaraMalla.tiene(nombre_de_ruta(ruta))):
		d["foto"] = ruta
	return d
