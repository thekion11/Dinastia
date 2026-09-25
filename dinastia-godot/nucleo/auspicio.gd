class_name Auspicio
extends RefCounted
## LA MARCA DEL PECHO: ofertas, firma y exigencia contractual.
##
## `vSponsor()` del HTML. Es el único ingreso grande del club que se DECIDE: la
## televisión llega, las cuotas llegan, la taquilla depende del domingo. Esto se
## firma, y la firma tiene condiciones.
##
## POR QUÉ IMPORTA QUE HAYA EXIGENCIA. Sin ella, elegir auspiciador sería mirar
## tres cifras y quedarse con la más alta: no habría decisión. Con exigencia de
## puesto, la marca que más paga suele ser también la que más pide, y aceptar
## un contrato caro con un plantel flojo es hipotecar el año siguiente: si no
## cumples, las ofertas de la próxima pretemporada llegan un 30% más flacas.
##
## LAS TREINTA Y OCHO MARCAS salen de la tabla `MARCAS`, que ya venía exportada
## del HTML y no la leía nadie. Van desde la cervecera y el banco hasta la
## funeraria, la app de citas y el podcast «Fútbol y Terapia»: es la mitad del
## chiste de la pantalla y el motivo de que el escudo importe.

signal firmado(marca: String, monto: int)
signal noticia(titulo: String, cuerpo: String)

## Cuántas marcas se sientan a la mesa cada pretemporada. Tres: con una no hay
## elección y con seis la pantalla se convierte en una hoja de cálculo.
const OFERTAS := 3

## En cuántas semanas se reparte el aporte de la temporada. Es el `monto/42` del
## HTML: el auspicio no entra de golpe, gotea todas las semanas.
const SEMANAS_TEMPORADA := 42

## Lo que se encoge la oferta del año siguiente si dejaste al auspiciador
## colgado. No es una multa: es que la marca cuenta lo que pasó.
const DESCUENTO_SI_FALLASTE := 0.7

var contrato: Dictionary = {}    ## {marca, color, monto, exig_pos, anio}
var ofertas: Array = []          ## {marca, color, monto, exig_pos}
## Se enciende al terminar por debajo de lo pactado y se apaga al generar las
## ofertas siguientes, que es cuando se cobra.
var quedaron_molestos: bool = false

var _ref: WeakRef

func _init(mundo: Mundo = null) -> void:
	_ref = weakref(mundo)

func _mundo() -> Mundo:
	return _ref.get_ref() as Mundo if _ref != null else null

## El catálogo de marcas, ya limpio de leetspeak. La tabla las guarda escritas
## con ceros y cuatros -`Banc0 Austral`- por el mismo motivo que los clubes:
## para no usar nombres reales. `Nombres.limpiar()` las deja legibles al leerlas.
static func marcas() -> Array:
	var t: Variant = Datos.tabla("MARCAS")
	return t as Array if t is Array else []

## Lo que una marca pagaría por la camiseta de este club. Exponencial sobre la
## reputación, como todo lo demás: la diferencia entre un grande y un mediano no
## es de un 20%, es de varias veces.
static func base_de(c: Club) -> int:
	return int(round(1400000.0 \
		* pow(Eco.factor_club(float(c.rep)), 0.9) \
		* pow(Eco.tier_pais(c.pais) / Eco.tier_pais("CHI"), 0.5) \
		* (0.3 if c.division == 2 else 1.0)))

## Abre el mercado de auspicios: tres marcas sobre la mesa. Se llama en la
## pretemporada y borra lo que hubiera antes: un contrato dura un año.
## `mult_rep` es el prestigio del DT (`Roles.multiplicador_sponsor()`),
## `bonusReputacion().sponsor` del HTML. Llega de fuera porque `Auspicio` no
## conoce a `Mundo`; por defecto 1.0, que es lo que usan las pruebas.
func generar_ofertas(c: Club, bono_marketing: bool = false, mult_rep: float = 1.0) -> void:
	if c == null:
		return
	contrato = {}
	ofertas = []
	var todas := marcas()
	if todas.is_empty():
		return
	var descuento := DESCUENTO_SI_FALLASTE if quedaron_molestos else 1.0
	quedaron_molestos = false
	var base := base_de(c)
	var elegidas := {}
	for i in OFERTAS:
		## Se sortea sin repetir: dos ofertas de la misma marca serían una sola
		## oferta enseñada dos veces.
		var intento := 0
		var idx := Azar.ent(0, todas.size() - 1)
		while elegidas.has(idx) and intento < 20:
			idx = Azar.ent(0, todas.size() - 1)
			intento += 1
		elegidas[idx] = true
		var m: Array = todas[idx]
		var monto := int(round(float(base) \
			* (0.9 + Azar.f() * 0.5) \
			* descuento \
			* (1.1 if bono_marketing else 1.0) \
			* mult_rep / 10000.0)) * 10000
		ofertas.append({
			"marca": Nombres.limpiar(String(m[0])),
			"color": String(m[1]) if m.size() > 1 else "#e8b13a",
			"monto": monto,
			"exig_pos": Azar.ent(4, 10),
		})
	noticia.emit("Mercado de auspicios abierto",
		"Tres marcas quieren la camiseta de %s. Compara montos y exigencias: la que más paga suele ser también la que más pide. Sin firma no hay ingreso semanal." % c.nombre)

## Firmar. Devuelve "" si se hizo, o el motivo.
func firmar(i: int) -> String:
	if not contrato.is_empty():
		return "ya luces una marca en el pecho esta temporada"
	if i < 0 or i >= ofertas.size():
		return "esa oferta no existe"
	var o: Dictionary = ofertas[i]
	var m := _mundo()
	contrato = {
		"marca": String(o["marca"]), "color": String(o["color"]),
		"monto": int(o["monto"]), "exig_pos": int(o["exig_pos"]),
		"anio": m.anio if m != null else 0,
	}
	ofertas = []
	noticia.emit("Firmado: %s" % String(contrato["marca"]),
		"La marca lucirá en el pecho por %s la temporada. Exigencia contractual: terminar top %d de la liga." % [
			Cesiones.dinero(int(contrato["monto"])), int(contrato["exig_pos"])])
	firmado.emit(String(contrato["marca"]), int(contrato["monto"]))
	return ""

## Lo que entra cada semana. Cero sin contrato, que es justo el castigo de no
## firmar: la pantalla enseña tres cifras y no firmar también es una decisión.
func semanal() -> int:
	if contrato.is_empty():
		return 0
	return int(round(float(int(contrato["monto"])) / float(SEMANAS_TEMPORADA)))

## El nombre que va estampado en el pecho, o "" si no hay marca.
func marca_en_camiseta() -> String:
	return String(contrato.get("marca", ""))

## Cierre de temporada: la marca mira en qué puesto acabaste. Devuelve el texto
## de lo que pasó, o "" si no había contrato.
func cierre(puesto: int) -> String:
	if contrato.is_empty():
		return ""
	var marca := String(contrato["marca"])
	var pedido := int(contrato["exig_pos"])
	var texto := ""
	if puesto > pedido and puesto > 0:
		quedaron_molestos = true
		texto = "%s esperaba un top %d y terminaste %d.º. Las ofertas del próximo año llegarán más flacas." % [marca, pedido, puesto]
		noticia.emit("Auspiciador molesto", texto)
	else:
		texto = "%s renueva la confianza tras el top %d." % [marca, puesto]
		noticia.emit("Auspiciador conforme", texto)
	contrato = {}
	return texto

func a_dic() -> Dictionary:
	return {
		"contrato": contrato.duplicate(true),
		"ofertas": ofertas.duplicate(true),
		"molestos": quedaron_molestos,
	}

func desde_dic(d: Dictionary) -> void:
	contrato = (d.get("contrato", {}) as Dictionary).duplicate(true)
	ofertas = (d.get("ofertas", []) as Array).duplicate(true)
	quedaron_molestos = bool(d.get("molestos", false))
