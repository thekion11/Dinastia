class_name EscaparateMarcas
extends RefCounted
## LOS COLABORADORES OFICIALES DEL ESCAPARATE (17-11-2026, segunda ronda): marcas FICTICIAS pero creíbles y DEL PAÍS del club (nombres típicos de su idioma), con un
## LOGOTIPO DIBUJADO (forma, anillo e inicial o monograma con colores propios; nada de un rectángulo de color con texto). Primero salen las que el club ya lleva de verdad
## (el patrocinador de la camiseta, `Auspicio.contrato`, y las zonas de publicidad del estadio firmadas, `Comercial.zonas_firmadas`); si faltan, se completan con las del país,
## elegidas de forma estable por club. Ninguna marca real.

const GRUPO_DE := {"ESP": "es", "ARG": "es", "CHI": "es", "URU": "es", "PAR": "es", "PER": "es", "BOL": "es", "ECU": "es", "COL": "es", "VEN": "es", "MEX": "es", "CRC": "es",
	"PAN": "es", "HON": "es", "GUA": "es", "ESA": "es", "NCA": "es", "AND": "es", "ENG": "en", "SCO": "en", "WAL": "en", "NIR": "en", "IRL": "en", "USA": "en", "AUS": "en", "NZL": "en",
	"CAN": "en", "RSA": "en", "JAM": "en", "TRI": "en", "ITA": "it", "SMR": "it", "GER": "de", "AUT": "de", "SUI": "de", "FRA": "fr", "BEL": "fr", "LUX": "fr", "CIV": "fr", "SEN": "fr",
	"CMR": "fr", "MAD": "fr", "POR": "pt", "BRA": "pt", "ANG": "pt", "MOZ": "pt", "CPV": "pt", "NED": "nl", "SUR": "nl", "CUR": "nl", "TUR": "tr"}
const MARCAS := {
	"es": ["Banco Alcázar", "Cervezas Montaraz", "Aceites del Guadiana", "Seguros La Estrella", "Telecom Solana", "Iberia Motor", "Lácteos Vega Real"],
	"en": ["Brookfield Building Society", "Kestrel Motors", "Northgate Brewery", "Lumen Telecom", "Thornbury Insurance", "Albion Energy", "Harrow & Finch"],
	"it": ["Banca Valdarno", "Birra Lunigiana", "Moto Ferrante", "Assicurazioni Meridiana", "Olio Santa Rosa", "Telecom Adria", "Pasta Vallegrande"],
	"de": ["Rheinland Bank", "Brauerei Schwarzwald", "Autohaus Berg", "Versicherung Eintracht", "Energie Elbtal", "Telekom Havel", "Stahlwerk Nordmark"],
	"fr": ["Banque Beaumont", "Brasserie du Nord", "Moteurs Lorraine", "Assurances Saint-Loup", "Énergie Garonne", "Télécom Armor", "Fromagerie Les Alpes"],
	"pt": ["Banco Atlântida", "Cervejas Douro", "Seguros Tejo", "Autos Minho", "Telecom Lusa", "Azeites do Alentejo", "Café Planalto"],
	"nl": ["Noordzee Bank", "Brouwerij De Molen", "Verzekering Maasland", "Energie Delta", "Autohuis Kennemer", "Telecom Zuiderzee", "Kaasmakerij Alkmaar"],
	"tr": ["Boğaz Bankası", "Anadolu Enerji", "Ege Sigorta", "Marmara Otomotiv", "Karadeniz Çay", "Toros Telekom", "Çinar Gıda"]}
## Algunas marcas con carácter propio de su país, para que no sean todas iguales dentro de un idioma.
const POR_PAIS := {"ARG": ["Banco del Plata", "Yerba Los Andes", "Alfajores Costanera", "Seguros Pampeanos"], "CHI": ["Banco Austral", "Vinos del Maule", "Salmones del Sur", "Cobre Atacama"],
	"MEX": ["Banco Tenochtitlán", "Cervecería del Valle", "Tortillas La Milpa", "Telecom Azteca Nova"], "BRA": ["Banco Tupã", "Cervejaria Serra Azul", "Seguradora Cruzeiro", "Café Planalto"],
	"ENG": ["Brookfield Building Society", "Kestrel Motors", "Albion Energy", "Northgate Brewery"], "ESP": ["Banco Alcázar", "Aceites del Guadiana", "Turrones Cervera", "Iberia Motor"]}
const PALETA := ["#c8102e", "#1f4e9c", "#1f8a4c", "#e0a800", "#6a2fa0", "#0b7a75", "#d9622b", "#2c3a4f"]

## Hasta 3 colaboradores del club: [{nombre, color (Color), forma (0-4)}].
static func de_club(p: Principal, c: Club) -> Array:
	var nombres: Array[String] = []
	if p.mundo != null and p.mundo.auspicio != null and not p.mundo.auspicio.contrato.is_empty():   ## el de la camiseta
		nombres.append(Nombres.limpiar(String(p.mundo.auspicio.contrato.get("marca", ""))))
	if p.mundo != null and p.mundo.comercial != null:   ## y los de la publicidad del estadio
		for z: Variant in p.mundo.comercial.zonas_firmadas.values():
			var n := Nombres.limpiar(String((z as Dictionary).get("marca", "")))
			if n != "" and not nombres.has(n):
				nombres.append(n)
	var pool: Array = (POR_PAIS.get(c.pais, []) as Array) + (MARCAS.get(String(GRUPO_DE.get(c.pais, "en")), MARCAS["en"]) as Array)
	var i := absi(hash("marcas|" + c.id))
	var k := 0
	while nombres.size() < 3 and k < 40:
		var n: String = pool[(i + k * 3) % pool.size()]
		if not nombres.has(n):
			nombres.append(n)
		k += 1
	var out: Array = []
	for n: String in nombres.slice(0, 3):
		var h := absi(hash(n))
		out.append({"nombre": n, "color": Color(PALETA[h % PALETA.size()]), "forma": (h / 7) % 5})
	return out

## El monograma: la inicial de las dos primeras palabras (o las dos primeras letras de una sola).
static func monograma(nombre: String) -> String:
	var ps := nombre.split(" ", false)
	if ps.size() >= 2:
		return (ps[0].left(1) + ps[1].left(1)).to_upper()
	return nombre.left(2).to_upper()

## El logotipo dibujado: una forma con su anillo y el monograma al centro.
class Logo extends Control:
	var color := Color("1f4e9c")
	var forma := 0
	var texto := "AB"
	func _init() -> void:
		custom_minimum_size = Vector2(30, 30)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var d := minf(size.x, size.y)
		var c := Vector2(size.x * 0.5, size.y * 0.5)
		var r := d * 0.5 - 1.0
		var pts := PackedVector2Array()
		match forma:
			0:
				draw_circle(c, r, color)
				draw_arc(c, r * 0.82, 0.0, TAU, 40, Color(1, 1, 1, 0.55), 1.6)
			1:
				draw_rect(Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), color)
				draw_rect(Rect2(c - Vector2(r, r) * 0.8, Vector2(r, r) * 1.6), Color(1, 1, 1, 0.5), false, 1.5)
			2:
				for i in 6:
					pts.append(c + Vector2(cos(TAU * i / 6.0 + PI / 6.0), sin(TAU * i / 6.0 + PI / 6.0)) * r)
				draw_colored_polygon(pts, color)
			3:
				pts = PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
				draw_colored_polygon(pts, color)
			_:
				pts = PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r), c + Vector2(r, r * 0.2), c + Vector2(0, r), c + Vector2(-r, r * 0.2)])
				draw_colored_polygon(pts, color)
		var tinta := Color.WHITE if color.get_luminance() < 0.5 else Color("101820")
		var fuente := EstiloAvanzar.fuente_titulo()
		var tam := int(d * 0.46)
		var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		draw_string(fuente, Vector2(c.x - ancho * 0.5, c.y + tam * 0.34), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, tinta)
