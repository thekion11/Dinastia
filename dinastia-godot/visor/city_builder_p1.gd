extends Node3D
## (Parte 1 de 12 de `city_builder.gd`: la norma de 450 líneas lo partió en capas, cada una extiende a la anterior; la última, `city_builder.gd`, conserva la clase.)

## Levanta la CIUDAD DEPORTIVA del club en 3D a partir de sus instalaciones.
##
## La idea que manda aqui: lo que el jugador ha construido se tiene que VER. Cada
## instalacion de G.inst es un edificio de verdad, y su NIVEL decide su tamano y
## su altura. Un club que no ha invertido nada tiene barracones; uno que lleva
## quince temporadas mejorando tiene un complejo. De un vistazo, sin leer numeros.
##
## Los edificios NO son el modelo de manzana de ciudad estirado: ese OBJ trae una
## manzana entera con calles y no sirve como edificio suelto. Se construyen con
## cajas, que es lo que permite que crezcan de verdad con el nivel. El estadio y
## las farolas si son modelos importados.

const RUTA_ESTADIO := "res://assets/ciudad/estadio.obj"
const RUTA_FAROLA := "res://assets/ciudad/farola.obj"

## LOS DOS MODELOS QUE TRAJO EL USUARIO (12-9-2026), convertidos con
## `herramientas/fbx_a_glb.py` -texturas bajadas a 1024 px, malla decimada-.
## Ver `dinastia-modelos-3d-usuario.md`: "ДОМ скетч" (casa boceto) y "Жилой
## комплекс" (complejo residencial), ambos en `recursos/modelos3d/`.
const RUTA_OFICINA_DT := "res://assets/ciudad/oficina_dt.glb"
## `complejo_residencial.glb` ya no se usa (26-9-2026): en su solar va la finca
## amurallada con enredadera (`_finca_enredadera`), a pedido del usuario.

## Los cinco rascacielos CC0 de Kenney (`recursos/modelos3d/cc0_web/LEEME.md`
## tiene la licencia completa: CC0, "City Kit Commercial" v2.1). Solo para el
## SKYLINE lejano -ver `_horizonte()`-, nunca dentro del recinto: son props
## sueltos, no el complejo que ya se levanta a mano con cajas medidas.
const RUTAS_HORIZONTE := [
	"res://assets/ciudad/kenney_buildings/building-skyscraper-a.glb",
	"res://assets/ciudad/kenney_buildings/building-skyscraper-b.glb",
	"res://assets/ciudad/kenney_buildings/building-skyscraper-c.glb",
	"res://assets/ciudad/kenney_buildings/building-skyscraper-d.glb",
	"res://assets/ciudad/kenney_buildings/building-skyscraper-e.glb",
]

## Siete autos CC0 de Kenney ("Car Kit") para el aparcamiento, en vez de
## alternar solo entre `coche1.fbx`/`coche2.fbx`. Se suman a los dos viejos,
## no los reemplazan -por si alguno de los GLB no cargara, el aparcamiento
## nunca se queda sin nada-.
const RUTAS_COCHES_KENNEY := [
	"res://assets/ciudad/kenney_cars/sedan.glb",
	"res://assets/ciudad/kenney_cars/sedan-sports.glb",
	"res://assets/ciudad/kenney_cars/suv.glb",
	"res://assets/ciudad/kenney_cars/suv-luxury.glb",
	"res://assets/ciudad/kenney_cars/hatchback-sports.glb",
	"res://assets/ciudad/kenney_cars/taxi.glb",
	"res://assets/ciudad/kenney_cars/van.glb",
]

## Las 18 instalaciones, con donde va cada una y de que color es su tejado.
## El orden importa: define la posicion en la parrilla del complejo.
## EL DOBLE DE GRANDES (12-9-2026). Con 9-16 m de fachada, al lado de un
## estadio de 110 m las instalaciones eran cajitas: el usuario dijo "no se ven
## los edificios, se siente un poco vacío, deben ser más grandes y detalladas",
## y tenía razón -un centro de entrenamiento de verdad es una nave de 40 m, no
## un quiosco-. Se doblan las medidas y la parrilla se separa en consecuencia.
const EDIFICIOS := [
	{"k": "ct",        "n": "Centro de entrenamiento", "col": Color(0.24, 0.52, 0.32), "ancho": 34.0, "fondo": 23.0},
	{"k": "acad",      "n": "Academia juvenil",        "col": Color(0.30, 0.46, 0.62), "ancho": 30.0, "fondo": 21.0},
	{"k": "med",       "n": "Centro médico",           "col": Color(0.78, 0.80, 0.82), "ancho": 24.0, "fondo": 19.0},
	{"k": "gim",       "n": "Gimnasio",                "col": Color(0.52, 0.34, 0.28), "ancho": 26.0, "fondo": 19.0},
	{"k": "resid",     "n": "Residencia",              "col": Color(0.62, 0.55, 0.40), "ancho": 28.0, "fondo": 21.0},
	{"k": "rehab",     "n": "Rehabilitacion",          "col": Color(0.70, 0.74, 0.78), "ancho": 22.0, "fondo": 17.0},
	{"k": "piscina",   "n": "Piscina",                 "col": Color(0.24, 0.58, 0.72), "ancho": 26.0, "fondo": 17.0},
	{"k": "cocina",    "n": "Comedor",                 "col": Color(0.72, 0.58, 0.34), "ancho": 22.0, "fondo": 17.0},
	{"k": "video",     "n": "Sala de video",           "col": Color(0.32, 0.32, 0.40), "ancho": 19.0, "fondo": 15.0},
	{"k": "pren",      "n": "Sala de prensa",          "col": Color(0.40, 0.36, 0.48), "ancho": 19.0, "fondo": 15.0},
	{"k": "museo",     "n": "Museo",                   "col": Color(0.66, 0.50, 0.22), "ancho": 24.0, "fondo": 19.0},
	{"k": "com",       "n": "Tienda",                  "col": Color(0.74, 0.36, 0.30), "ancho": 22.0, "fondo": 17.0},
	{"k": "guarderia", "n": "Guarderia",               "col": Color(0.80, 0.66, 0.34), "ancho": 19.0, "fondo": 15.0},
	{"k": "bienestar", "n": "Bienestar",               "col": Color(0.56, 0.60, 0.52), "ancho": 19.0, "fondo": 15.0},
	{"k": "esports",   "n": "Sala de juegos",          "col": Color(0.36, 0.30, 0.56), "ancho": 19.0, "fondo": 15.0},
]

## EL HUERTO NO ES UN EDIFICIO y por eso faltaba (12-9-2026). `Instalaciones`
## tiene DIECINUEVE obras y aquí solo se dibujaban quince. De las cuatro que
## faltaban, tres no son edificios y está bien que no lo sean -`trib` y `cal`
## SON el estadio, y `park` son los coches del aparcamiento-, pero `huerto`
## -"Huerto y zona sustentable"- sí ocupa suelo y no se veía en ninguna parte.
## Va aparte de `EDIFICIOS` porque lo suyo no es una caja con ventanas: son
## bancales de cultivo y un invernadero, y crecen a lo ancho con el nivel.
const HUERTO_EN := Vector3(-112.0, 0, 45.0)
const FILA_0_Z := 108.0
const FILA_PASO := 43.0

var datos: Dictionary = {}
var expansion: CiudadExpansion
## Huellas sólidas que no son fachadas (estadio, edificios del club): para el
## modo a pie / al volante (`ExploradorCiudad`).
var huellas: Array[Rect2] = []
var etiquetas: Array = []          ## [{pos:Vector3, texto:String, nivel:int}]
## LO QUE SE PUEDE TOCAR EN EL MAPA (plan maestro B7): cada instalación, su
## solar si todavía no existe, y el estadio. `VistaCiudad` proyecta `pos` a la
## pantalla para saber qué se clicó (el mapa no tiene colisiones).
## [{k, n, pos: Vector3, estado: "hecho"|"obra"|"solar"|"estadio"}]
var puntos_clic: Array = []
var _rotulos: Node3D

## LAS LUCES QUE DEPENDEN DE LA HORA. Se guardan al construir para poder
## encenderlas y apagarlas con el ciclo del sol sin recorrer el árbol entero
## cada fotograma -son decenas de farolas y todas las ventanas del complejo.
var _farolas_luz: Array[OmniLight3D] = []
var _ventanas_mat: Array[StandardMaterial3D] = []

## CRONÓMETRO DE LA CONSTRUCCIÓN (etapa 3): con TIEMPOS=1 imprime lo que tarda
## cada parte. Sirve para saber qué conviene aligerar o repartir.
var _t_marca := 0
## Círculos [x, z, radio] de lo pequeño y sólido (farolas, troncos, coches...).
var circulos := PackedVector3Array()
static var _medir_tiempos := OS.get_environment("TIEMPOS") != ""

## ============================================================================
##  EL TERRENO (12-9-2026, tercera pasada)
## ============================================================================
##
## Antes esto era UN `PlaneMesh` de 5.000 m: perfectamente plano hasta el
## horizonte, y por eso el mapa se leía como una maqueta sobre una mesa. Un
## terreno de verdad ONDULA. Ahora es una malla generada con ruido, con una
## regla que es la clave de todo: **la zona construida se queda plana**.
##
## Por qué plana en el centro: las calles, las parcelas, el recinto y el
## estadio son planos rígidos colocados a y=0. Si el terreno subiera y bajara
## debajo de ellos, asomarían flotando por un lado y enterrados por el otro.
## Así que la altura vale 0 dentro del radio construido, y de ahí hacia fuera
## sube suavemente -con una transición larga, o se vería el escalón-. Es el
## mismo truco que usa cualquier juego de gestión con un mapa "natural"
## alrededor de una parcela edificable.
const TERRENO_LADO := 7600.0
const TERRENO_CELDAS := 160          ## 121x121 vértices: suficiente para que las
                                     ## lomas se lean y barato de generar.
const LLANO_RADIO := 1480.0          ## dentro de esto, altura 0 garantizada
const LLANO_TRANSICION := 520.0      ## y esto es lo que tarda en empezar a subir
const TERRENO_ALTURA := 78.0

## Se guardan para poder preguntar la altura en cualquier punto DESPUÉS de
## generar la malla: lo que se plante fuera del llano -los edificios del
## horizonte- tiene que apoyarse en la loma, no flotar sobre ella.
var _ruido_terreno: FastNoiseLite
var _ruido_detalle: FastNoiseLite

## EN BALDOSAS, NO EN UNA SOLA MALLA (12-9-2026, segunda vuelta del terreno).
## Con el terreno entero en un único `MeshInstance3D` las farolas no iluminaban
## el suelo: en el render de Compatibility -el que usa el móvil, y el que usan
## estas pruebas- cada OBJETO recibe como mucho un puñado de luces (8 por
## defecto), y una malla de 5 km es UN objeto. Las 54 farolas se repartían ocho
## plazas para todo el mapa, así que de noche el suelo salía negro mientras las
## canchas -que sí son mallas sueltas- se veían iluminadas. Troceado en
## baldosas, cada una elige sus luces cercanas y el alumbrado funciona.
const TERRENO_BALDOSAS := 8

# ---------------------------------------------------------------- estadio

## EL ESTADIO DE VERDAD, EL MISMO QUE SE JUEGA (12-9-2026).
##
## Antes aquí había una maqueta: `estadio.obj`, una malla genérica escalada por
## el aforo. Servía como bulto, pero el usuario lo dijo claro: "el estadio debe
## estar tal cual como esté en el club, si fue modificado debe notarse". Y ya
## existía la pieza exacta para eso -`StadiumBuilder`, el mismo constructor que
## levanta el recinto en el partido en vivo, alimentado por el perfil que
## devuelve `EstadioPropio`-: la forma, las bandejas, el techo, el corte del
## césped, el color de las butacas y hasta los focos que elegiste salen ahí.
## Reformar el estadio en Club → Estadio ahora se ve TAMBIÉN desde el mapa.
##
## Va dentro de un nodo propio y desplazado al norte: `StadiumBuilder` lo
## construye siempre centrado en el origen (es su contrato con el visor de
## partido, donde el estadio ES la escena), así que aquí se mueve entero.
const ESTADIO_EN := Vector3(0, 0, -150)

const FORMAS := {
	"ct": "nave", "gim": "nave", "piscina": "cristal", "resid": "torre",
	"med": "clinica", "rehab": "clinica", "museo": "templo", "acad": "escuela",
	"guarderia": "escuela", "cocina": "pabellon", "bienestar": "pabellon",
	"video": "medios", "pren": "medios", "esports": "medios", "com": "tienda",
}

## Lo que convierte una caja con ventanas en un EDIFICIO: la marquesina de la
## entrada con sus pilares, las máquinas de la cubierta y una banda de rótulo
## del color del club sobre la puerta. Son cuatro piezas y cambian la lectura
## por completo -sin ellas, a media distancia todas las instalaciones son la
## misma caja pintada de otro color.
## ============================================================================
##  CADA INSTALACIÓN CON SU CARA (26-9-2026)
## ============================================================================
## "Que las instalaciones sean mejores": hasta hoy las quince eran la misma caja
## con marquesina y tres bultos en el techo, solo cambiaba el color. Ahora cada
## una lleva lo que la delata desde el mapa: la cruz roja y la ambulancia del
## centro médico, la cristalera del gimnasio, las parabólicas de la sala de
## prensa, el pórtico con la copa del museo, los toldos de la tienda, los
## columpios de la guardería, el neón de la sala de juegos... Y más cuanto más
## nivel: una instalación grande se nota también en lo que tiene alrededor.
## TINTES PARA EL KIT (7-10-2026): los edificios del kit de Kenney salían
## todos del mismo blanco. Se multiplica su textura por un tono pastel (uno de
## ocho, cacheado por material) para que las calles tengan fachadas de colores.
const TINTES := [Color(1.0, 0.86, 0.72), Color(0.86, 0.93, 1.0), Color(0.9, 1.0, 0.88), Color(1.0, 0.82, 0.8),
	Color(1.0, 0.95, 0.75), Color(0.92, 0.86, 1.0), Color(0.95, 0.78, 0.62), Color(0.82, 0.9, 0.9)]
var _cache_tintes := {}

## FACHADAS DE TORRE (etapa 6): el kit de rascacielos trae una textura de
## cuadros azules borrosos. Se cambia por `fachada_torre.gdshader`, con seis
## tonos de pared, y de noche las ventanas se encienden (`encender_luces`).
var _mats_torre: Array[ShaderMaterial] = []
const TONOS_TORRE := [Color(0.80, 0.82, 0.86), Color(0.86, 0.80, 0.72), Color(0.74, 0.78, 0.82), Color(0.84, 0.84, 0.80), Color(0.70, 0.74, 0.70), Color(0.88, 0.84, 0.86)]

## EL PERSONAL, A LA VISTA (26-9-2026, "que tengan trabajadores reales"): en la
## puerta de cada instalación está su gente, con el uniforme de su oficio
## (bata blanca en el médico, chaquetilla en el comedor, chándal del club en el
## centro de entrenamiento...). Uno por instalación, dos desde nivel 4 y tres
## desde nivel 7, como su plantilla de verdad (`Trabajadores`).
const UNIFORMES := {
	"med": ["f2f2f2", "cfe0f5"], "rehab": ["f2f2f2", "b3d4f0"], "cocina": ["ffffff", "222222"],
	"gim": ["111111", "c62828"], "piscina": ["d32f2f", "ffeb3b"], "guarderia": ["f9a825", "2e7d32"],
	"museo": ["2b2b33", "d4af37"], "com": ["club", "ffffff"], "ct": ["club", "club2"],
	"acad": ["club", "club2"], "resid": ["455a64", "ffffff"], "video": ["263238", "90a4ae"],
	"pren": ["1f2a44", "ffffff"], "bienestar": ["8d6e63", "d7ccc8"], "esports": ["6a1b9a", "00e5ff"],
}

var _personal_pendiente: Array = []

# ---------------------------------------------------------------- aparcamiento

## ============================================================================
##  LOS COCHES (26-9-2026)
## ============================================================================
## "En nuestra ciudad están conduciendo mal": los del kit de Kenney tienen el
## morro en +Z (medido: su lado largo es Z, y en una captura de perfil el capó
## queda del lado +Z), pero el tráfico los giraba -90° creyendo que miraban a
## X. Iban todos DE LADO, como cangrejos. Ahora cada coche se instancia ya
## mirando a +Z y el tráfico no les suma ningún giro.
##
## Y "tenemos mejores": `coche1.fbx`/`coche2.fbx`, los realistas. Su licencia
## no está verificada (ver `LICENCIAS.md`) y las versiones publicables no los
## llevan (`export_presets.cfg`), así que entran SOLO si el archivo está: en la
## copia de trabajo sí, en una versión exportada no, y ahí queda Kenney.
## Vienen con Z hacia arriba y el morro en -X: se enderezan dentro de un nodo.
const RUTA_COCHE_REAL_1 := "res://assets/ciudad/coche1.fbx"
const RUTA_COCHE_REAL_2 := "res://assets/ciudad/coche2.fbx"

## VEHÍCULOS PROPORCIONADOS (7-10-2026, «vehículos más realistas y que sean
## proporcionados»): los del kit de Kenney son de juguete -a escala 1,65 un
## turismo medía 2,1 m de alto y 2,5 de ancho, y un camión de bomberos 5 m de
## largo-. Cada modelo se lleva a sus medidas reales (ancho, alto, largo en
## metros) midiéndolo una vez; la deformación se limita para que las ruedas
## no se vean ovaladas (el alto nunca baja del 72 % del factor del largo).
const MEDIDAS_REALES := {
	"sedan": Vector3(1.9, 1.65, 4.6), "sedan-sports": Vector3(1.9, 1.45, 4.5), "suv": Vector3(1.95, 1.8, 4.7),
	"suv-luxury": Vector3(2.0, 1.85, 4.95), "hatchback-sports": Vector3(1.85, 1.5, 4.2), "taxi": Vector3(1.9, 1.7, 4.6),
	"van": Vector3(2.0, 2.1, 5.1), "truck": Vector3(2.5, 3.3, 8.0), "truck-flat": Vector3(2.5, 3.0, 8.0),
	"tractor-police": Vector3(2.1, 2.6, 4.4), "ambulance": Vector3(2.1, 2.7, 6.0), "police": Vector3(1.9, 1.65, 4.8),
	"delivery": Vector3(2.1, 2.6, 6.0), "garbage-truck": Vector3(2.5, 3.4, 8.5), "firetruck": Vector3(2.5, 3.3, 9.0),
	"delivery-flat": Vector3(2.1, 2.4, 6.0),
}
static var _escalas_reales := {}

## ============================================================================
##  LAS FAROLAS (12-9-2026, a petición del usuario)
## ============================================================================
##
## Antes eran `farola.obj` -un modelo descargado, gris, pequeño y con la misma
## silueta en todas partes-. El usuario pidió "negras y más grandes, y que sus
## luces sean de colores que uno pueda escoger durante la noche", y tiene
## sentido más allá del capricho: de noche las farolas son lo único que dibuja
## el trazado de la ciudad, así que son un elemento de IDENTIDAD, no un adorno.
## Elegir su color es elegir de qué color se ve tu ciudad a las 23:00.
##
## Se construyen por código -y no con un modelo- por dos razones: se puede
## teñir la luminaria en tiempo real cuando el jugador cambia el color, y la
## silueta se controla (negra, alta, con brazo curvo) en vez de heredarla.
const FAROLA_ALTO := 13.0

## El color por defecto si la partida no tiene uno elegido: ámbar de sodio, el
## de toda la vida.
const LUZ_POR_DEFECTO := Color("#ffb75e")

var _luz_color: Color = LUZ_POR_DEFECTO
var _luminarias: Array[StandardMaterial3D] = []

## ============================================================================
##  EL PLANO DEL MAPA (12-9-2026)
## ============================================================================
##
## Antes esto era UN recinto con todo dentro y césped hasta el horizonte: no
## se entendía como un sitio, no había forma de recorrerlo con la vista y los
## CINCO TERRENOS que el jugador compra en Club → Ciudad no existían en 3D -eran
## solo una lista de texto-. El usuario lo dijo claro: "las instalaciones deben
## tener su espacio, los terrenos deben estar delimitados, la cosa residencial
## conectada con calles; primero planifica el espacio".
##
## EL PLANO, de norte (-z) a sur (+z):
##
##      ╔═══ calle norte (z=-250) ══════════════════════╗
##      ║  [RIBERA]        ESTADIO         [NORTE]      ║
##      ║  x=-290,z=-170   (0,-150)        x=290,z=-170 ║
##   calle                                            calle
##   oeste        ┌── RECINTO DEL CLUB ──┐            este
##  (x=-200)      │ campos · aparcamiento │          (x=200)
##      ║         │ instalaciones (PERIFERIA)         ║
##      ║  [CENTRO]       └──────────────┘  [SUR]     ║
##      ║  x=-295,z=150                   x=295,z=190 ║
##      ╚═══ calle sur (z=+340) ════════════════════════╝
##                      │ ramal
##                [BARRIO RESIDENCIAL]  (-70, 470)
##
## El sitio de cada parcela NO es decorativo: sale de lo que dice su propia
## descripción en la tabla `TERRENOS` -"norte, pegado al estadio", "ribera del
## río", "solar en el centro", "fundo en la periferia" (que es el propio
## recinto del club) y "terreno sur, zona industrial"-.

## MEDIDAS DEL MAPA. El estadio de verdad (`StadiumBuilder`) ocupa unos 110 x
## 150 m reales y va al norte, así que el recinto del club llega hasta z=-280;
## el anillo de calles lo rodea por fuera y las parcelas quedan al otro lado de
## la calle, que es lo que las hace leerse como terrenos vecinos y no como
## trozos sueltos del mismo sitio. Queda hueco de sobra entre el anillo y el
## horizonte (a 620 m) para lo que venga después.
const ANCHO_CALLE := 16.0
const RING_X := 205.0
const RING_Z_NORTE := -320.0
const RING_Z_SUR := 350.0
## La circunvalación exterior cruza los tramos este y oeste del anillo aquí.
const EX_N := -282.0
const EX_S := 262.0

## Dónde cae cada terreno comprable. "periferia" no tiene parcela propia: ES el
## recinto del club, así que solo lleva cartel.
##
## TODO ESTO SE APRETÓ (12-9-2026, segunda pasada): con el anillo a 235 m y las
## parcelas a 360, el estadio -que ahora es el de verdad y mide 110x150 m
## REALES- quedaba como un sello en mitad de un prado y el mapa no se leía de
## una vez. La regla aquí es que la referencia de tamaño la pone el estadio, no
## al revés: todo lo demás se acerca hasta que un vistazo abarque el conjunto.
const PARCELAS := {
	"norte":  {"pos": Vector2(300, -180), "ancho": 130.0, "fondo": 160.0},
	"ribera": {"pos": Vector2(-304, -180), "ancho": 130.0, "fondo": 160.0},
	"centro": {"pos": Vector2(-306, 110), "ancho": 140.0, "fondo": 180.0},
	"sur":    {"pos": Vector2(306, 140), "ancho": 140.0, "fondo": 180.0},
}

## Los negocios que SÍ se pueden ver: los que la tabla `NEGOCIOS` ata a un
## terreno concreto. `resto` y `escuela` no tienen terreno (`null` en la tabla),
## así que no ocupan suelo y no se dibujan: no es un olvido, es que el propio
## juego dice que no están en ningún sitio.
const NEGOCIOS_EN_PARCELA := {
	"hotel": "norte",
	"parking": "norte",
	"comercial": "centro",
	"clinica": "periferia",
}

## LA MANZANA COMERCIAL: ocho edificios distintos del kit CC0, no cuatro
## repetidos. Una manzana de verdad no tiene dos edificios iguales seguidos, y
## con solo cuatro modelos el patrón se cantaba desde la cámara del mapa.
const RUTAS_COMERCIAL := [
	"res://assets/ciudad/kenney_comercial/building-a.glb",
	"res://assets/ciudad/kenney_comercial/building-c.glb",
	"res://assets/ciudad/kenney_comercial/building-e.glb",
	"res://assets/ciudad/kenney_comercial/building-g.glb",
	"res://assets/ciudad/kenney_comercial/building-i.glb",
	"res://assets/ciudad/kenney_comercial/building-k.glb",
	"res://assets/ciudad/kenney_comercial/building-m.glb",
	"res://assets/ciudad/kenney_comercial/building-n.glb",
	## 26-9-2026: los seis que faltaban del kit ("hay un pack completo sin usar").
	"res://assets/ciudad/kenney_comercial_extra/building-b.glb",
	"res://assets/ciudad/kenney_comercial_extra/building-d.glb",
	"res://assets/ciudad/kenney_comercial_extra/building-f.glb",
	"res://assets/ciudad/kenney_comercial_extra/building-h.glb",
	"res://assets/ciudad/kenney_comercial_extra/building-j.glb",
	"res://assets/ciudad/kenney_comercial_extra/building-l.glb",
	## 7-10-2026: las seis versiones del kit básico que quedaban sin poner.
	"res://assets/ciudad/kenney_comercial/building-b.glb",
	"res://assets/ciudad/kenney_comercial/building-d.glb",
	"res://assets/ciudad/kenney_comercial/building-f.glb",
	"res://assets/ciudad/kenney_comercial/building-h.glb",
	"res://assets/ciudad/kenney_comercial/building-j.glb",
	"res://assets/ciudad/kenney_comercial/building-l.glb",
]

## Naves para la zona industrial del terreno sur: los modelos "de poco
## detalle" del mismo kit, que son justo bloques simples -perfectos para una
## nave y baratos de dibujar-.
const RUTAS_NAVES := [
	"res://assets/ciudad/kenney_comercial/low-detail-building-wide-a.glb",
	"res://assets/ciudad/kenney_comercial/low-detail-building-wide-b.glb",
	"res://assets/ciudad/kenney_comercial/low-detail-building-a.glb",
	"res://assets/ciudad/kenney_comercial/low-detail-building-e.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-b.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-c.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-d.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-f.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-g.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-h.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-i.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-j.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-k.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-l.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-m.glb",
	"res://assets/ciudad/kenney_comercial_extra/low-detail-building-n.glb",
]

## Los toldos y parasoles del kit: el detalle de calle que separa "unos bloques
## puestos en fila" de "una calle comercial".
const RUTAS_MOBILIARIO := [
	"res://assets/ciudad/kenney_comercial/detail-awning.glb",
	"res://assets/ciudad/kenney_comercial/detail-awning-wide.glb",
	"res://assets/ciudad/kenney_comercial/detail-parasol-a.glb",
	"res://assets/ciudad/kenney_comercial/detail-parasol-b.glb",
	"res://assets/ciudad/kenney_comercial_extra/detail-overhang.glb",
	"res://assets/ciudad/kenney_comercial_extra/detail-overhang-wide.glb",
]

## VEHÍCULOS DE SERVICIO, más raros que los coches normales: una ambulancia, un
## camión de basura o un coche de policía cada tanto es lo que hace que el
## tráfico parezca de una ciudad y no de un circuito. Van aparte de
## `RUTAS_COCHES_KENNEY` precisamente para poder dosificarlos.
## EL AUTOBÚS. El kit CC0 de coches no trae un bus de verdad -se revisó el
## catálogo completo-, así que se usa la furgoneta de reparto a una escala
## mucho mayor: más grande que cualquier coche de la calle y a menor
## velocidad, que es justo cómo se distingue un autobús de un auto en
## cualquier ciudad.
const RUTA_BUS := "res://assets/ciudad/kenney_cars/van.glb"

const RUTAS_SERVICIO := [
	## 26-9-2026: los que faltaban del kit (camiones y la patrulla rural).
	"res://assets/ciudad/kenney_cars_extra/truck.glb",
	"res://assets/ciudad/kenney_cars_extra/truck-flat.glb",
	"res://assets/ciudad/kenney_cars_extra/tractor-police.glb",
	"res://assets/ciudad/kenney_cars/ambulance.glb",
	"res://assets/ciudad/kenney_cars/police.glb",
	"res://assets/ciudad/kenney_cars/delivery.glb",
	"res://assets/ciudad/kenney_cars/garbage-truck.glb",
	"res://assets/ciudad/kenney_cars/firetruck.glb",
	"res://assets/ciudad/kenney_cars/delivery-flat.glb",
]
