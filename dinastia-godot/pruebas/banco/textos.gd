extends "res://pruebas/banco/base.gd"
## [Banco · grupo «textos»] Generado al partir el banco por grupos (26-10).

## M-240 (20-10): la política es ficticia y no se atribuye religión a nadie. Se
## vigila que no se cuelen políticos o partidos reales ni religiones en los textos
## del juego (código y narración). El calendario (fiestas como el Ramadán) es la
## única excepción: habla de fechas, no de personas.
const PROHIBIDAS_POLITICA := "PSOE|Bolsonaro|Trump|Biden|Boric|Milei|Lula|Macron|Pinochet|Maduro|peronismo|peronista|kirchnerismo|kirchnerista|franquismo|chavismo|chavista"

const PROHIBIDAS_RELIGION := "católico|católica|musulmán|musulmana|evangélico|evangélica|judío|judía|protestante|budista|ateo|atea"

## LAS TRES ESCENAS RAÍZ CARGAN Y COMPILAN (25-9-2026).
##
## Pedido del usuario tras encontrar y arreglar un bug crítico el mismo día:
## "que no sea tan frágil". El bug era este de libro: `principal.gd` -15.000+
## líneas, un solo archivo del que depende TODO el juego- tenía un bloque de
## código muerto que citaba una variable (`_lista_mercado`) borrada al conectar
## `PanelMercado`. GDScript con tipado estático no tolera un identificador no
## declarado: el archivo entero dejaba de PARSEAR, y como `ui/inicio.gd` (la
## escena `run/main_scene`) depende de esa clase, **el juego no arrancaba desde
## ningún lanzador** -ni el .exe, ni el proyecto abierto en el editor-.
##
## Y este mismo banco, que se corrió una decena de veces esa sesión siempre en
## 0 fallos, JAMÁS LO VIO: `banco.gd` prueba el `nucleo/` -economía, partidos,
## mercado, todo lo que no necesita ventana-, pero nunca había cargado una sola
## escena de `ui/`. Un error de sintaxis ahí era invisible para "0 fallos".
##
## La prueba es deliberadamente simple: cargar e instanciar cada escena raíz ES
## SUFICIENTE para forzar a Godot a compilar el script y todo lo que importa
## -no hace falta meterlas al árbol ni esperar a `_ready()`, el error de
## parseo ya habría reventado en `load()`/`instantiate()`-. Así que esto es
## barato (no dispara sonido, música, ni construye el mundo 3D) y cubre
## exactamente el hueco que dejó pasar el bug de hoy, para siempre, en TODAS
## las escenas raíz y no solo en la que falló esta vez.
func _probar_carga_de_ui() -> void:
	_titulo("LAS ESCENAS RAÍZ COMPILAN Y CARGAN (red contra un archivo roto en silencio)")
	for ruta in ["res://escenas/inicio.tscn", "res://escenas/eleccion_club.tscn",
			"res://escenas/principal.tscn"]:
		var paquete: PackedScene = load(ruta)
		_comprobar(paquete != null, "%s se carga como recurso" % ruta)
		if paquete == null:
			continue
		## BUG DE VERIFICACIÓN REAL, ENCONTRADO ESCRIBIENDO ESTA MISMA PRUEBA
		## (25-9-2026): `PackedScene.instantiate()` NUNCA devuelve null aunque
		## el script de la raíz esté completamente roto -Godot igual crea el
		## `Node` base, simplemente sin el script pegado-. Comprobar
		## `nodo != null` es un candado que siempre pasa: es exactamente el
		## tipo de prueba que miente por ausencia que ya advierte
		## `feedback-verification-discipline` en la memoria del proyecto.
		## `get_script()` sí distingue los dos casos -confirmado con un script
		## roto de mentira antes de confiar en esto-: da `null` cuando el
		## script no pudo compilar y el recurso real cuando sí.
		var nodo := paquete.instantiate()
		_comprobar(nodo != null and nodo.get_script() != null,
			"%s instancia CON su script compilado (no solo el Node vacío)" % ruta)
		if nodo != null:
			nodo.free()

## LA NARRACIÓN, AL INGLÉS Y AL PORTUGUÉS (punto 10 del MEGAPLAN): los
## titulares de las noticias.
func _probar_narracion_traducida() -> void:
	_titulo("NARRACIÓN TRADUCIDA: TITULARES DE NOTICIAS")
	var antes := Idiomas.idioma
	Idiomas.idioma = "en"
	Idiomas._cache.clear()
	_comprobar(Idiomas.t("🗳️ Campaña electoral") == "🗳️ Election campaign", "titular con icono en inglés: %s" % Idiomas.t("🗳️ Campaña electoral"))
	_comprobar(Idiomas.t("Llega la camada juvenil") == "The youth intake arrives", "titular en inglés")
	_comprobar(Idiomas.t("Representantes: R. Prueba") == "Agents: R. Prueba", "titular con nombre (patrón)")
	Idiomas.idioma = "pt"
	Idiomas._cache.clear()
	_comprobar(Idiomas.t("Se retira una figura") == "Um craque se aposenta", "titular en portugués")
	## Los cuerpos (7-10-2026): con nombres y cifras dentro, por patrón.
	var cuerpo_pt := Idiomas.t("Juan Ríos se lesiona entrenando: 3 semanas de baja.")
	_comprobar(cuerpo_pt == "Juan Ríos se machuca no treino: 3 semanas fora.", "cuerpo con nombre en portugués: %s" % cuerpo_pt)
	Idiomas.idioma = "en"
	Idiomas._cache.clear()
	var cuerpo_en := Idiomas.t("Juan Ríos se lesiona entrenando: 3 semanas de baja.")
	_comprobar(cuerpo_en == "Juan Ríos gets injured in training: out for 3 weeks.", "cuerpo con nombre en inglés: %s" % cuerpo_en)
	var fijo_en := Idiomas.t("El estadio vuelve a abrir con normalidad.")
	_comprobar(fijo_en == "The stadium reopens as normal.", "cuerpo fijo en inglés")
	var tv := Idiomas.t("Ana Sol termina su préstamo y se reincorpora a la pretemporada.")
	_comprobar(tv == "Ana Sol ends his loan and rejoins pre-season.", "otro cuerpo en inglés: %s" % tv)
	## La prensa y la carrera de jugador (7-10-2026), y frases pegadas.
	_comprobar(Idiomas.t("Prensa: '¿Le preocupa la falta de gol?'") == "Press: 'Are you worried about the lack of goals?'", "pregunta de prensa en inglés")
	_comprobar(Idiomas.t("Los chicos empujan fuerte, tendrán su chance").contains("pushing hard"), "respuesta de prensa en inglés")
	var pegadas := Idiomas.t("Sumamos; el equipo dio la cara. Tardaste en contestar: en la sala se notó.")
	_comprobar(pegadas.contains("You took a while to answer"), "frases pegadas, oración por oración: %s" % pegadas)
	var cesion := Idiomas.t("Leo Mar se va cedido una temporada. Juega en Cumbres. Pagan el 50% del sueldo.")
	_comprobar(cesion.begins_with("Leo Mar leaves on a season-long loan.") and cesion.ends_with("They pay 50% of his wages."), "texto de varias oraciones con patrón entero: %s" % cesion)
	## Los otros seis idiomas (7-10-2026): la misma narración en fr/it/de/ca/pl/tr.
	var esperado := {
		"fr": "Juan Ríos se blesse à l'entraînement : 3 semaines d'absence.",
		"it": "Juan Ríos si infortuna in allenamento: 3 settimane di stop.",
		"de": "Juan Ríos verletzt sich im Training: 3 Wochen Pause.",
		"ca": "Juan Ríos es lesiona entrenant: 3 setmanes de baixa.",
		"pl": "Juan Ríos doznaje kontuzji na treningu: 3 tyg. przerwy.",
		"tr": "Juan Ríos antrenmanda sakatlandı: 3 hafta yok.",
	}
	for k: String in esperado:
		Idiomas.idioma = k
		Idiomas._cache.clear()
		var c := Idiomas.t("Juan Ríos se lesiona entrenando: 3 semanas de baja.")
		_comprobar(c == esperado[k], "cuerpo con nombre en %s: %s" % [k, c])
		_comprobar(Idiomas.t("Se retira una figura") != "Se retira una figura", "titular fijo en %s" % k)
	Idiomas.idioma = antes
	Idiomas._cache.clear()

func _frases_de_idiomas_t(dir: String, re: RegEx, frases: Dictionary) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			for m in re.search_all(FileAccess.get_file_as_string(dir + "/" + f)):
				frases[m.get_string(1).c_unescape()] = true
	for d in DirAccess.get_directories_at(dir):
		_frases_de_idiomas_t(dir + "/" + d, re, frases)

## LOS 8 IDIOMAS CON LAS MISMAS FRASES (15-10-2026, INFORME_INTERNO §9 / I-01).
## Las frases castellanas son la UNIÓN de todos los catálogos: la tabla del
## esqueleto (`Idiomas.TABLA`), `datos/idiomas_extra.json` de cada idioma (con
## los diálogos de la ciudad dentro) y las directas de la narración. Ningún
## idioma puede tener menos que esa unión; los patrones (con números o nombres)
## tienen que tener plantilla en los 8, y las frases de `DialogosCiudad`
## (generado por `herramientas/dialogos_ciudad.py`) tienen que estar en todos.
func _probar_paridad_idiomas() -> void:
	_titulo("IDIOMAS: LOS 8 TIENEN LAS MISMAS FRASES QUE EL CASTELLANO")
	var antes := Idiomas.idioma
	var castellano := {}
	for k: String in Idiomas.TABLA:
		castellano[k] = true
	for idi: String in Idiomas.ORDEN:
		for k: String in (Idiomas._extra.get(idi, {}) as Dictionary):
			castellano[k] = true
	## Las frases de los vecinos, sacadas del propio script generado.
	var re := RegEx.new()
	re.compile('Idiomas\\.t\\("((?:[^"\\\\]|\\\\.)*)"\\)')
	var vecinos := 0
	for m in re.search_all(FileAccess.get_file_as_string("res://nucleo/dialogos_ciudad.gd")):
		castellano[m.get_string(1).c_unescape()] = true
		vecinos += 1
	_comprobar(vecinos >= 72, "los diálogos de la ciudad aportan sus frases (%d)" % vecinos)
	_comprobar(castellano.size() > 2500, "frases castellanas en los catálogos: %d" % castellano.size())
	for idi: String in Idiomas.ORDEN:
		Idiomas.idioma = idi
		var faltan: Array[String] = []
		for k: String in castellano:
			if Idiomas._directa(k) == "":
				faltan.append(k)
		_comprobar(faltan.is_empty(), "«%s» tiene las %d frases (faltan %d%s)" % [idi, castellano.size(),
			faltan.size(), "" if faltan.is_empty() else ": " + ", ".join(faltan.slice(0, 6))])
	var cortos := {}
	for par: Array in Idiomas._patrones:
		for idi: String in Idiomas.ORDEN:
			if String((par[1] as Dictionary).get(idi, "")) == "":
				cortos[idi] = int(cortos.get(idi, 0)) + 1
	_comprobar(cortos.is_empty(), "los %d patrones tienen plantilla en los 8 idiomas %s" % [Idiomas._patrones.size(),
		"" if cortos.is_empty() else str(cortos)])
	## Cada `Idiomas.t("…")` escrito en el código (M-446): traducido en los 8.
	## Lo mismo que `pruebas/frases_sin_traducir.gd`, pero aquí falla.
	var del_codigo := {}
	for dir: String in ["res://ui", "res://visor", "res://nucleo"]:
		_frases_de_idiomas_t(dir, re, del_codigo)
	var sin: Array[String] = []
	for f: String in del_codigo:
		if f.strip_edges() == "%s":
			continue
		for idi: String in Idiomas.ORDEN:
			Idiomas.idioma = idi
			if Idiomas._directa(f) == "" and Idiomas._t(f, 0) == f:
				sin.append("%s: %s" % [idi, f])
	_comprobar(del_codigo.size() > 200 and sin.is_empty(), "las %d frases de Idiomas.t(\"…\") del código, en los 8 idiomas (%d sin traducir%s)" % [
		del_codigo.size(), sin.size(), "" if sin.is_empty() else ": " + ", ".join(sin.slice(0, 6))])
	## Y los marcadores no se pierden al traducir: lo que lleva %s/%d en
	## castellano lo lleva igual en cada idioma (si no, el `%` revienta).
	var huecos := RegEx.new()
	huecos.compile("%[+-]?(?:\\.\\d+)?[sd]")
	var malos: Array[String] = []
	for idi: String in Idiomas.ORDEN:
		var ex: Dictionary = Idiomas._extra.get(idi, {})
		for k: String in ex:
			if huecos.search_all(k).size() != huecos.search_all(String(ex[k])).size():
				malos.append("%s: %s" % [idi, k])
	_comprobar(malos.is_empty(), "los %%s y %%d se conservan en cada idioma (%d mal%s)" % [malos.size(),
		"" if malos.is_empty() else ": " + ", ".join(malos.slice(0, 4))])
	Idiomas.idioma = antes
	Idiomas._cache.clear()

## EL SISTEMA DE DISEÑO Y LA ORTOGRAFÍA (25-9-2026, plan maestro B13). Dos redes
## contra la regresión: (1) ninguna pantalla vuelve a escribir a mano los
## colores canónicos -apuntan a `Tema`-; (2) las palabras que se corrigieron no
## vuelven a aparecer sin tilde en un texto que ve el jugador.
func _probar_tema_y_ortografia() -> void:
	_titulo("TEMA ÚNICO Y ORTOGRAFÍA DE LOS TEXTOS")
	var canonicos := ["e9eeea", "8ea595", "c9a227", "0c1510", "3fa06a", "141c16", "16211a"]
	var copias: Array[String] = []
	var sin_tilde: Array[String] = []
	var vetadas := ["cesped", "policia", "tunel", "camarin", "tactica", "paises", "tambien", "detras", "INVASION", "Division"]
	var rx := RegEx.new()
	rx.compile("\"((?:[^\"\\\\]|\\\\.)*)\"")
	for carpeta: String in ["res://ui", "res://ui/componentes", "res://nucleo", "res://visor"]:
		var dir := DirAccess.open(carpeta)
		if dir == null:
			continue
		for f: String in dir.get_files():
			if not f.ends_with(".gd") or f == "tema.gd" or f == "idiomas.gd" or f == "pantalla_estadio.gd":
				continue
			var texto := FileAccess.get_file_as_string(carpeta + "/" + f)
			for linea: String in texto.split("\n"):
				var t := linea.strip_edges()
				if t.begins_with("#"):
					continue
				if t.begins_with("const COL_"):
					for c: String in canonicos:
						if t.contains('Color("%s")' % c):
							copias.append(f)
				for m in rx.search_all(linea):
					var v := m.get_string(1)
					if not v.contains(" "):
						continue
					for w: String in vetadas:
						var r2 := RegEx.new()
						r2.compile("\\b" + w + "\\b")
						if r2.search(v) != null:
							sin_tilde.append("%s: %s" % [f, w])
	_comprobar(copias.is_empty(), "ninguna pantalla copia la paleta a mano: todas apuntan a Tema %s" % str(copias))
	_comprobar(sin_tilde.is_empty(), "sin palabras corregidas que vuelvan sin tilde %s" % str(sin_tilde))

func _probar_glifos_idiomas() -> void:
	_titulo("M-335: GLIFOS DE LOS 9 IDIOMAS")
	var fuente: Font = ThemeDB.fallback_font
	var vistos := {}
	for idi: String in Idiomas.ORDEN:
		for v: Variant in (Idiomas._extra.get(idi, {}) as Dictionary).values():
			for ch in String(v):
				vistos[ch] = idi
	var faltan: Array = []
	for ch: String in vistos:
		var cp := ch.unicode_at(0)
		## Emojis y símbolos gráficos los pone la fuente de emojis del sistema.
		if cp >= 0x2190 or cp < 0x20 or (cp >= 0x200B and cp <= 0x200F):
			continue
		if not fuente.has_char(cp):
			faltan.append("%s (%s)" % [ch, vistos[ch]])
	_comprobar(vistos.size() > 100, "caracteres distintos en las traducciones: %d" % vistos.size())
	_comprobar(faltan.is_empty(), "la letra los tiene todos (faltan: %s)" % str(faltan.slice(0, 12)))

func _listar_gd(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		_listar_gd(dir + "/" + sub, out)

func _probar_palabras_prohibidas() -> void:
	_titulo("M-240: SIN POLÍTICA NI RELIGIÓN REAL EN LOS TEXTOS")
	var re_pol := RegEx.create_from_string("(?i)\\b(" + PROHIBIDAS_POLITICA + ")\\b")
	var re_rel := RegEx.create_from_string("(?i)(?<![\\wáéíóúñ])(" + PROHIBIDAS_RELIGION + ")(?![\\wáéíóúñ])")
	var archivos: Array = []
	for dir in ["res://nucleo", "res://ui", "res://visor"]:
		_listar_gd(dir, archivos)
	archivos.append_array(["res://datos/narracion.json", "res://datos/idiomas_extra.json"])
	var malos: Array = []
	for f: String in archivos:
		if f.ends_with("calendario.gd"):
			continue
		var txt := FileAccess.get_file_as_string(f)
		for r: RegEx in [re_pol, re_rel]:
			var m := r.search(txt)
			if m != null:
				malos.append("%s: %s" % [f.get_file(), m.get_string()])
	_comprobar(re_rel.search("un delantero Católico") != null and re_pol.search("votó a Trump") != null
		and re_rel.search("catolicismo") == null, "el detector caza lo prohibido (y no palabras parecidas)")
	_comprobar(archivos.size() > 100, "se revisan los textos de todo el juego (%d archivos)" % archivos.size())
	_comprobar(malos.is_empty(), "ningún político, partido ni religión real (%s)" % str(malos))
