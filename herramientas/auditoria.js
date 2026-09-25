export const meta = {
  name: 'dinastia-auditoria-v36',
  description: 'Audita DINASTIA en 9 frentes, verifica cada hallazgo de forma adversarial y planifica pendientes + migracion a 3D',
  phases: [
    { title: 'Auditar', detail: '9 lentes independientes sobre el HTML de 18.582 lineas' },
    { title: 'Verificar', detail: 'refutar cada hallazgo leyendo el codigo real' },
    { title: 'Planificar', detail: 'pendientes de alto valor, migracion 3D y checklist APK' },
  ],
}

const FILE = 'C:\\Users\\Alumno\\Desktop\\Proyecto x\\dinastia-futbol-manager base.html'

const CONTEXTO = `
PROYECTO: "DINASTIA · Futbol Manager", un juego indie de gestion futbolistica que vive ENTERO
en un unico archivo HTML sin dependencias ni conexion:
  ${FILE}
Tiene 18.582 lineas / 1,1 MB. Todo el JS esta en un solo <script>. Las funciones son declaraciones
(function nombre(){}), asi que el orden no importa; los const de datos SI deben quedar antes de
usarse en top-level. Hay 830 funciones y 72 vistas (funciones vXxx). El estado global vive en el
objeto G. El idioma del codigo y de los comentarios es espanol.

COMO LEERLO (IMPORTANTE): NO leas el archivo entero, son 1,1 MB y te quedas sin contexto.
Usa el tool Bash con grep -n para localizar, y sed -n 'A,Bp' para leer solo las regiones que
te interesan. Ejemplo:
  grep -n "function finTemporada" "${FILE}"
  sed -n '4100,4260p' "${FILE}"
Puedes leer con generosidad regiones de 100-400 lineas, pero siempre dirigidas.

ERES DE SOLO LECTURA. NO edites el archivo bajo ningun concepto. Tu trabajo es ENCONTRAR y
REPORTAR con precision quirurgica (numero de linea + el codigo exacto que falla).

HISTORIAL DE BUGS REALES YA ENCONTRADOS EN ESTE PROYECTO (el mismo patron suele repetirse,
usalo como olfato, pero NO los reportes de nuevo porque ya estan arreglados):
- Estado que se ESCRIBE y nadie LEE: G.impuesto, G.cantera1, flags de la federacion (F.playoffs,
  F.cupoJuv) que se pintaban como etiqueta y no tenian ningun lector. REGLA: todo flag nuevo
  necesita al menos un lector ademas de la etiqueta que lo pinta.
- Objetos de estado escritos A MANO en el literal de nuevaPartida cuando ya existia una tabla de
  definicion (G.staff vs STAFF_DEF, G.inst vs instDefs()). Las claves que faltaban solo se
  rellenaban en migrar(), que unicamente corre al CARGAR partida => en partida nueva daba NaN
  contagioso en el saldo.
- Constantes de pais/liga cableadas a Chile ('CHI') en funciones genericas.
- Literales que se pintan sin pasar por descensurar() y salen con digitos ("Prem1er League").
- Funciones completas construidas y nunca llamadas (ideas hechas pero invisibles al jugador).
- Condiciones de logro puestas en ()=>false, inalcanzables para siempre.
- Bucles de calendario donde un tipo de semana no tiene dia de partido y el contador se topa,
  impidiendo llegar a finTemporada().

ESTANDAR DEL USUARIO: una idea no cuenta como terminada si no se VE en el menu y no se NOTA al
jugar. Codigo que existe pero al que el jugador no puede llegar = bug reportable.

CONTEXTO DE HOY: esta tarde se empaqueta el juego como APK de Android para ensenarselo a un amigo.
Por eso pesan mucho los fallos que rompen la partida, los que se ven feos en pantalla tactil
horizontal, y los que hacen que algo prometido no ocurra.
`

const HALLAZGOS_SCHEMA = {
  type: 'object',
  properties: {
    hallazgos: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          titulo: { type: 'string', description: 'Una linea, concreta' },
          linea: { type: 'integer', description: 'Numero de linea donde vive el fallo' },
          gravedad: { type: 'string', enum: ['critico', 'alto', 'medio', 'bajo'] },
          codigo_actual: { type: 'string', description: 'El fragmento exacto de codigo tal cual esta hoy en el archivo, copiado literal' },
          por_que_falla: { type: 'string', description: 'El mecanismo del fallo: que entrada o que estado lo dispara y que sale mal' },
          como_lo_ve_el_jugador: { type: 'string', description: 'Que nota el usuario jugando, o "nada, es invisible"' },
          parche_propuesto: { type: 'string', description: 'El codigo de reemplazo exacto, listo para sustituir a codigo_actual' },
        },
        required: ['titulo', 'linea', 'gravedad', 'codigo_actual', 'por_que_falla', 'como_lo_ve_el_jugador', 'parche_propuesto'],
      },
    },
  },
  required: ['hallazgos'],
}

const VEREDICTO_SCHEMA = {
  type: 'object',
  properties: {
    es_real: { type: 'boolean' },
    razon: { type: 'string' },
    gravedad_corregida: { type: 'string', enum: ['critico', 'alto', 'medio', 'bajo'] },
    parche_corregido: { type: 'string', description: 'El parche, corregido si hacia falta; vacio si el hallazgo no es real' },
  },
  required: ['es_real', 'razon', 'gravedad_corregida', 'parche_corregido'],
}

const LENTES = [
  {
    key: 'estado-muerto',
    prompt: `Barrido sistematico de ESTADO MUERTO. Lista todas las propiedades que se asignan sobre el
objeto G (grep -o "G\\.[a-zA-Z_][a-zA-Z0-9_]*" y cuenta apariciones) y quedate con las que aparecen
una o dos veces en todo el archivo: casi siempre son estado que se ESCRIBE y nadie LEE. Para cada
candidata, comprueba a mano si tiene un lector de verdad (no solo la etiqueta que la pinta).
Haz lo mismo con las propiedades del objeto de federacion y con los flags de eventos.
Reporta solo las que sean promesas incumplidas al jugador, no residuos inofensivos.`,
  },
  {
    key: 'medio-tiempo',
    prompt: `El usuario reporto POR ESCRITO este fallo y hay que verificar si sigue vivo:
"Hay una falla, despues de la charla en Medio tiempo del equipo, no deja continuar el partido".
Localiza toda la maquinaria del entretiempo (busca 'entretiempo', 'medioTiempo', 'descanso',
'charla', 'vestuario', 'min===45', 'segundaParte') y sigue el flujo COMPLETO: minuto 45 -> pantalla
de charla -> eleccion del usuario -> reanudacion. Busca cualquier camino donde el partido se quede
colgado: un estado que no se limpia, un boton que no aparece, un return temprano, un flag de pausa
que nadie levanta. El usuario tambien pidio explicitamente separar los botones de accion del
camarino del boton de aceptar la segunda parte, y un boton para simular el partido entero de golpe:
comprueba si ambas cosas existen y son alcanzables. Reporta lo que falte o falle.`,
  },
  {
    key: 'movil-tactil',
    prompt: `Auditoria de COMPATIBILIDAD MOVIL, TACTIL Y HORIZONTAL, que es lo critico para el APK de
esta tarde. Revisa: el meta viewport y el CSS de @media (orientation:landscape); si hay controles
que solo responden a click/mouse y no a touch; areas tactiles demasiado pequenas (menos de 40px);
tablas o rejillas que se desbordan horizontalmente en una pantalla de 360-420 px de ancho; texto
con tamano fijo en px que quedara ilegible; elementos con position:fixed que chocan con el notch o
la barra de gestos (safe-area-inset); scroll atrapado o rebote; el gesto de swipe entre pestanas y
si puede dispararse por accidente; dobles disparos de evento (click + touchstart en el mismo
elemento); y cualquier :hover que en tactil deje un estado pegado. Da parches CSS/JS concretos.`,
  },
  {
    key: 'runtime-crash',
    prompt: `Caza de ERRORES DE EJECUCION que rompen la partida. Busca especificamente:
acceso a elemento de array sin comprobar que el array tiene elementos (patron .filter(...)[0].algo,
o [Math.floor(rnd*arr.length)] sobre un array que puede quedar vacio); divisiones donde el
denominador puede ser 0; propagacion de NaN (una suma con undefined que luego se guarda en el saldo
o en una media); acceso a G.algo.otro donde G.algo puede no existir en partidas viejas; JSON.parse
sin try; bucles while que pueden no terminar; y funciones que asumen que el plantel tiene un portero
o un numero minimo de jugadores. Prioriza los caminos que un jugador recorre de verdad
(fin de temporada, mercado, lesiones, partido, ascenso/descenso).`,
  },
  {
    key: 'guardado',
    prompt: `Auditoria del GUARDADO Y LA CARGA, que es lo que mas duele si se rompe con una partida
avanzada. Localiza guardarLS, cargar, migrar, schemaVersion y el serializado del estado. Comprueba:
que todo campo nuevo anadido en las ultimas versiones tenga su rama en migrar(); que migrar() sea
idempotente y no rompa una partida ya migrada; que no se guarde algo que exceda la cuota de
localStorage (el estado con miles de jugadores puede acercarse a los 5 MB: calcula el tamano real
del volcado y mira si hay manejo de QuotaExceededError); que exista alguna forma de exportar o
importar la partida como archivo, imprescindible en un APK donde el usuario puede perder los datos
al reinstalar; y si hay guardado automatico y cada cuanto.`,
  },
  {
    key: 'promesas-invisibles',
    prompt: `Busca IDEAS IMPLEMENTADAS PERO INVISIBLES, el estandar del usuario: si no se ve en el
menu y no se nota jugando, no cuenta. Metodo: extrae la lista de funciones declaradas
(grep -n "^function ") y para cada una comprueba cuantas veces aparece su nombre en el archivo; las
que aparecen UNA sola vez (su propia declaracion) no se llaman nunca. Descarta las que sean
manejadores asignados por string en onclick= (buscalas antes de reportarlas: grep del nombre entre
comillas). Haz lo mismo con las vistas vXxx: comprueba que todas esten enlazadas desde la lista de
pestanas o desde algun boton. Reporta cada sistema construido al que el jugador no puede llegar.`,
  },
  {
    key: 'datos-realismo',
    prompt: `Auditoria de REALISMO DE LOS DATOS, que es lo primero que un amigo va a mirar.
El usuario pidio expresamente que los presupuestos, las medias y las edades esten ajustados a los
del FIFA/FC, que los estadios partan con los AFOROS REALES de cada equipo y que los dorsales de los
jugadores reales sean los suyos. Localiza las tablas de datos (clubes, REALES, presupuestos,
aforos, dorsales) y comprueba: si el aforo del estadio es real por club o un numero inventado o
derivado; si los presupuestos guardan proporcion creible entre un grande europeo y un club chileno;
si los dorsales se asignan por convencion generica o son los reales; si las edades de los jugadores
reales estan actualizadas a la temporada que simula el juego. Reporta desajustes concretos con
ejemplos de clubes o jugadores especificos, y di cual es el arreglo mas barato para cada uno.`,
  },
  {
    key: 'rendimiento',
    prompt: `Auditoria de RENDIMIENTO pensando en un movil Android de gama media, que es donde va a
correr el APK. Busca: funciones de render que reconstruyen todo el DOM con innerHTML en cada tick;
bucles anidados sobre los ~11.000 jugadores del mundo que se ejecuten dentro de un render o de un
intervalo; setInterval/setTimeout encadenados que no se limpian al salir de una vista (fugas que
acumulan temporizadores); SVG con un numero enorme de nodos redibujado por frame (el motor 3D del
estadio y la vista 2D del partido son los sospechosos naturales); y recalculos caros repetidos que
podrian memorizarse. Mide donde puedas contando nodos o iteraciones, y propon el arreglo mas barato
que no reescriba el sistema entero.`,
  },
  {
    key: 'coherencia-roles',
    prompt: `Auditoria de COHERENCIA ENTRE MODOS DE JUEGO. El juego tiene 6 roles (dt, dir, dueno,
cantera, ayudante, interino) y cada uno deberia jugarse DISTINTO. Ya se corrigio que dir/dueno no
pudieran tocar tactica y alineacion (funcion mando()) y que el interinato cerrara el mercado.
Busca lo que quede sin cubrir: acciones que un rol no deberia poder hacer y sigue pudiendo (fichar,
vender, renovar, despedir staff, tocar instalaciones, elegir el once); textos de la interfaz que
hablan como si siempre fueras el DT; y al reves, roles a los que se les niega algo que SI deberian
poder hacer. Recorre las 72 vistas buscando botones sin guarda de rol. Reporta cada fuga con la
vista y la linea.`,
  },
]

phase('Auditar')
log('9 lentes independientes sobre el HTML; cada hallazgo se verifica en cuanto sale, sin esperar a los demas')

const porLente = await pipeline(
  LENTES,
  (lente) => agent(`${CONTEXTO}\n\nTU LENTE:\n${lente.prompt}\n\nDevuelve solo hallazgos que hayas COMPROBADO leyendo el codigo real, con su numero de linea y el fragmento literal. Mas vale un hallazgo solido que diez sospechas. Si no encuentras nada real, devuelve la lista vacia.`, {
    label: `auditar:${lente.key}`,
    phase: 'Auditar',
    schema: HALLAZGOS_SCHEMA,
  }),
  (res, lente) => {
    if (!res || !res.hallazgos || !res.hallazgos.length) return []
    return parallel(res.hallazgos.map((h) => () =>
      agent(`${CONTEXTO}\n\nEres un VERIFICADOR ESCEPTICO. Otro agente afirma haber encontrado este fallo:

TITULO: ${h.titulo}
LINEA: ${h.linea}
GRAVEDAD QUE LE PUSO: ${h.gravedad}
CODIGO QUE DICE QUE ESTA AHI:
${h.codigo_actual}
POR QUE DICE QUE FALLA: ${h.por_que_falla}
PARCHE QUE PROPONE:
${h.parche_propuesto}

Tu trabajo es REFUTARLO. Ve al archivo, lee esa region de verdad con sed -n y comprueba:
1. Que el codigo citado exista TAL CUAL en esa linea (si no coincide, es_real=false).
2. Que el mecanismo del fallo se sostenga: rastrea de verdad si hay o no un lector, un guarda, una
   comprobacion defensiva mas arriba, o una llamada por onclick= en string que el otro agente no vio.
3. Que el parche sea correcto, minimo, y no rompa nada alrededor: comprueba que las variables que
   usa existen en ese ambito, que respeta el estilo del archivo y que codigo_actual aparezca UNA
   SOLA VEZ en todo el archivo (si aparece varias veces, amplia el fragmento hasta que sea unico y
   devuelvelo asi en parche_corregido junto a su contexto).
Ante la duda, es_real=false. Solo confirma lo que puedas demostrar leyendo el codigo.
En parche_corregido devuelve el bloque de reemplazo definitivo (o vacio si no es real).`, {
        label: `verificar:${lente.key}:L${h.linea}`,
        phase: 'Verificar',
        schema: VEREDICTO_SCHEMA,
      }).then((v) => (v && v.es_real ? { ...h, gravedad: v.gravedad_corregida, parche_propuesto: v.parche_corregido || h.parche_propuesto, lente: lente.key, razon_verificador: v.razon } : null))
    ))
  }
)

const confirmados = porLente.flat().filter(Boolean)
log(`${confirmados.length} hallazgos sobrevivieron a la verificacion adversarial`)

phase('Planificar')

const PLAN_SCHEMA = {
  type: 'object',
  properties: {
    resumen: { type: 'string' },
    items: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          titulo: { type: 'string' },
          por_que_importa: { type: 'string' },
          esfuerzo: { type: 'string', enum: ['pequeno', 'medio', 'grande'] },
          impacto_al_ensenarlo: { type: 'string', enum: ['alto', 'medio', 'bajo'] },
          donde_tocar: { type: 'string', description: 'Funciones y lineas concretas del archivo' },
          como_hacerlo: { type: 'string' },
        },
        required: ['titulo', 'por_que_importa', 'esfuerzo', 'impacto_al_ensenarlo', 'donde_tocar', 'como_hacerlo'],
      },
    },
  },
  required: ['resumen', 'items'],
}

const planes = await parallel([
  () => agent(`${CONTEXTO}

TAREA: decidir QUE PENDIENTES MERECE LA PENA INTEGRAR HOY, antes de empaquetar el APK que el
usuario le va a ensenar a un amigo esta tarde.

Las especificaciones viven en:
  C:\\Users\\Alumno\\Desktop\\Proyecto x\\instruciones profundas\\
  - instrucciones_extras.txt  (la lista de prioridad mas reciente, MANDA sobre las otras dos)
  - 300-ideas-juego-futbol-manager-1.md
  - 750-ideas-adicionales.md
Lee instrucciones_extras.txt entero (son 15 KB) y hojea los otros dos con grep.

Auditorias anteriores ya establecieron que de las 1.100 ideas la gran mayoria estan hechas, y que
~125 son imposibles sin servidor (nube, multijugador, comunidad, monetizacion): NO las propongas.

Tu criterio de seleccion es muy concreto: el usuario va a ENSENAR el juego a un amigo. Prioriza lo
que se nota en los primeros 20 minutos de partida y en las primeras pantallas, no lo que solo se
aprecia en la temporada 8. Comprueba con grep si cada cosa que propongas ya existe en el codigo
antes de proponerla: si ya esta, no la propongas.

Devuelve entre 8 y 15 items ordenados por (impacto al ensenarlo / esfuerzo).`, { label: 'plan:pendientes', phase: 'Planificar', schema: PLAN_SCHEMA }),

  () => agent(`${CONTEXTO}

TAREA: trazar la MIGRACION PROGRESIVA A 3D. El usuario ha dicho que "los estadios, los partidos y
otras cosas las vamos cambiando poco a poco a 3D porque ese sera el estandar".

Lo que ya existe hoy y tienes que leer antes de proponer nada:
- estadio3D(op) en la linea 14475 del HTML: un motor 3D propio que dibuja el estadio en SVG con
  proyeccion y algoritmo del pintor. Lee esa funcion entera y lo que la rodea.
- La vista 2D del partido: mvInit / mvTick / mvPintar / mvFigura / mvBalonSVG a partir de la linea
  16778, estilo Soccer Manager, que solo DIBUJA e interpola mientras el motor de siempre
  (simularMinuto, linea 2397) resuelve la logica.
- Un visor 3D aparte hecho en Godot que vive fuera del HTML, en
  C:\\Users\\Alumno\\Desktop\\Proyecto x\\visor3d\\  (lee su carpeta scripts\\ y su LEEME).
  El HTML exporta un JSON de partido que ese visor consume.

Restricciones duras que NO puedes ignorar:
- El juego es UN SOLO archivo HTML sin dependencias y sin conexion. No se puede meter three.js ni
  ninguna libreria externa. Lo que propongas se escribe a mano.
- Va a correr dentro de un WebView de Android en un movil de gama media.
- El usuario ha dicho que el juego es principalmente 2D y que se permiten "sombras y detalles 3D":
  la migracion es progresiva, no una reescritura.

Propon la ESCALERA concreta de pasos, del mas barato y vistoso al mas caro: que se pasa a 3D
primero, con que tecnica (SVG proyectado como ya hace estadio3D, canvas 2D con proyeccion propia,
o WebGL crudo sin libreria), que gana el jugador en cada peldano, y donde esta el punto en que deja
de compensar. Se especifico con nombres de funciones y numeros de linea.`, { label: 'plan:3d', phase: 'Planificar', schema: PLAN_SCHEMA }),

  () => agent(`${CONTEXTO}

TAREA: preparar el CHECKLIST TECNICO DEL APK que se compila esta tarde.

Situacion real de la maquina, ya comprobada (no la vuelvas a comprobar, dala por cierta):
- Windows 11. HAY internet.
- NO hay: java, javac, JDK, Android SDK, gradle, adb, node, npm, cordova, capacitor, keytool.
- Python solo como alias de la Microsoft Store (inservible).
- Godot 4.7.2 portable esta en herramientas\\godot\\ pero sus plantillas de exportacion instaladas
  son solo Windows y Web: NO hay plantillas de Android.
- El juego es un unico HTML de 1,1 MB, autocontenido, sin conexion.

No tienes que compilar nada. Tienes que devolver el plan y las trampas. Cubre:
1. Las rutas posibles para convertir un HTML autocontenido en APK, comparadas con honestidad:
   (a) WebView nativo minimo con Android command-line tools + JDK 17 + gradle,
   (b) exportar desde Godot con plantillas de Android,
   (c) cualquier otra que sea real y no requiera subir el juego a un servicio de terceros.
   Para cada una: cuanto hay que descargar, cuantos pasos, y donde suele romperse.
2. Que hay que cambiar EN EL HTML para que se comporte como app y no como pagina: bloqueo de
   orientacion, pantalla completa sin barra del navegador, que el boton ATRAS de Android no cierre
   la app sino que retroceda de pestana, que el audio arranque tras el primer toque (los WebView
   bloquean el autoplay), persistencia de localStorage entre versiones de la app, y desactivar el
   menu contextual y la seleccion de texto al mantener pulsado.
3. La cinematica de marca del estudio (Nexus Digital) esta en marca\\nexus-digital-intro.mp4,
   9,96 s, 848x480, 2 MB. En el APK SI va incluida como intro. Di como integrarla de forma que se
   pueda saltar con un toque y que no bloquee el arranque si falla la decodificacion.
Devuelve los pasos como items del schema, ordenados por el orden en que hay que hacerlos.`, { label: 'plan:apk', phase: 'Planificar', schema: PLAN_SCHEMA }),
])

return {
  confirmados,
  por_gravedad: {
    critico: confirmados.filter((h) => h.gravedad === 'critico').length,
    alto: confirmados.filter((h) => h.gravedad === 'alto').length,
    medio: confirmados.filter((h) => h.gravedad === 'medio').length,
    bajo: confirmados.filter((h) => h.gravedad === 'bajo').length,
  },
  plan_pendientes: planes[0],
  plan_3d: planes[1],
  plan_apk: planes[2],
}
