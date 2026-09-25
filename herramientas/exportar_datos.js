/* ============================================================================
   EXPORTAR LAS TABLAS DE DATOS DEL JUEGO A JSON
   ============================================================================
   Primer paso de la mudanza a Godot. Todo lo que en el juego es DATO -los 384
   clubes, las ligas de 23 paises, los jugadores reales, los nombres, las
   lesiones, los logros- no se reescribe en GDScript: se saca tal cual y Godot
   lo carga. Transcribir a mano miles de lineas de tablas es la forma mas segura
   de colar una errata que nadie encuentra hasta dentro de un mes.

   La lista de nombres NO esta escrita a mano: sale de grepear las declaraciones
   `const` del propio codigo, asi que no se puede olvidar ninguna. De cada una se
   intenta JSON.stringify; las que no son datos se descartan solas y quedan
   anotadas en el informe.

   POR QUE TODAS LAS VARIABLES DE AQUI EMPIEZAN POR __x
   Porque este script lee las constantes del juego con eval(nombre), y eval mira
   el ambito LOCAL primero. La primera version tenia una variable llamada
   `NOMBRES` -la lista de tablas a exportar- que tapaba a la constante NOMBRES
   del juego, que es la de los nombres de pila. Resultado: todos los futbolistas
   generados en Godot se llamaban "IDIOMAS Valenzuela" o "VALOR_PIVOTE Ahumada",
   con nombres de tabla por nombre de pila. Con el prefijo no puede repetirse.

   Uso:  run_harness.ps1 -Script exportar_datos.js
   ============================================================================ */
(function () {
  'use strict';
  var __xLista = [
    "$",
    "ACCES",
    "ACC_NOM",
    "AGENTES",
    "AG_PERFIL",
    "ALT_DEM",
    "APELLIDOS",
    "APELLIDOS_BRA",
    "APELLIDOS_EXT",
    "APODOS",
    "ARBITROS",
    "ARB_D",
    "ARENGA_BOOST",
    "ARENGA_MIN",
    "ARENGA_TOPE",
    "AT_CAMPO",
    "AT_LARGO",
    "AT_NOM",
    "AT_POR",
    "BALON_SKINS",
    "BANCOS",
    "BANDERA",
    "BARBA_NOM",
    "BLOQUES",
    "BOTINES",
    "CAJA_JEQUE",
    "CAMPANAS",
    "CATEGORIAS",
    "CELEBRAS",
    "CLIMAS",
    "CONFED",
    "CONSEJ",
    "CONTI_KEYS",
    "COPA_NOM",
    "CORNERS",
    "CT_ROPA",
    "CUENTAS",
    "CUERPOS",
    "CURVA_CLUB",
    "CURVA_JUG",
    "DATA_P1",
    "DATA_P2",
    "DECO_MAPA",
    "DEMARCA",
    "DEM_DEF",
    "DESAFIOS",
    "DIAS",
    "DIAS_COR",
    "DIAS_SEM",
    "DIF",
    "DIRECTRICES",
    "DT_COMPRAS",
    "DT_ESTILOS",
    "DT_ESTILOS_P",
    "DT_PELOS",
    "DT_RAYAS",
    "DT_SKILLS",
    "DT_TRAJES",
    "DT_VOLS",
    "ECO",
    "EQUIP_REAL",
    "ESCALA_CIEGA",
    "ESCENARIOS",
    "ESC_FORMAS",
    "ESC_PATRON",
    "ESC_SIM",
    "ESPEC",
    "ESPECIALES",
    "ESPERA_GUARDADO",
    "EST_A",
    "EST_ARCOS",
    "EST_ASIENTOS",
    "EST_BANDERAS",
    "EST_BANQUILLOS",
    "EST_CAMS",
    "EST_CESPED",
    "EST_CLIMAS",
    "EST_CORNER",
    "EST_DEF",
    "EST_ESCENAS",
    "EST_ESCUDOS",
    "EST_FOCOS",
    "EST_FONT",
    "EST_FORMAS",
    "EST_LINEAS",
    "EST_PANTALLAS",
    "EST_PRESETS",
    "EST_REDES",
    "EST_REDTIPO",
    "EST_SONIDOS",
    "EST_TECHOS",
    "EST_TONOS",
    "EST_TUNELES",
    "EST_VEL",
    "EURO",
    "FAMOSOS",
    "FENOTIPO",
    "FESTEJOS",
    "FONDOS",
    "FORMS",
    "GENTE_ROLES",
    "GLOBO_FS",
    "GLOBO_PAIS",
    "GLOBO_TIERRA",
    "GLOBO_VS",
    "GLOSARIO",
    "HABS",
    "HAB_CAMPO",
    "HAB_POR",
    "HORARIOS",
    "IDIOMAS",
    "IMPORTA",
    "INFLUENCERS",
    "INSTAL",
    "INSTAL_EXTRA",
    "INST_SEMANAS",
    "KITS",
    "LEET",
    "LESIONES",
    "LIBRES",
    "LOGO_ANIM",
    "LOGROS",
    "LOGROS_OCULTOS",
    "LOOK_NUM",
    "LS_AUTO",
    "MARCAS",
    "MARCA_LZ",
    "MASCOTAS",
    "MAX_SISTEMAS",
    "MEDIOS",
    "MEDIOS_PROPIOS",
    "MESES",
    "MODOS_JUEGO",
    "MODO_SECCIONES",
    "MONUMENTOS_PAIS",
    "NEGOCIOS",
    "NIVELES_PERFIL",
    "NOMBRES",
    "NOMBRES_BRA",
    "NOMBRES_EXT",
    "N_LEYENDAS_SEMILLA",
    "ORIGENES",
    "ORIG_PESO",
    "PAISES_EXT",
    "PAISES_LIGAS",
    "PAIS_SELECCION",
    "PALCO_EST",
    "PELOC",
    "PELOS",
    "PELO_NOM",
    "PERIODISTAS",
    "PERSONAL",
    "PIELES",
    "PLANES_ABONO",
    "PLAN_PLANTEL",
    "POOLS_EU",
    "PORTADAS",
    "POSD",
    "POS_ADY",
    "POS_POR_GRUPO",
    "PPE",
    "PREGUNTAS",
    "PREMIUM",
    "PRENSA_EST",
    "PRESENTA",
    "PRESUP_PIVOTE",
    "PRETEMP",
    "PROVEEDORES",
    "R",
    "RAMAS",
    "RAMA_NIV",
    "RAMA_PERFIL",
    "RASGOS",
    "REALES",
    "REGISTRO_ERRORES",
    "REP_PIVOTE",
    "RF",
    "ROLES",
    "ROL_PLANTEL",
    "SEGMENTOS",
    "SELECCIONES",
    "SESGOS",
    "SFX_BTN",
    "SKILL_JUG",
    "SOLICITUDES",
    "STAFF_DEF",
    "TABS_ORDEN",
    "TATU_DISENOS",
    "TATU_DIS_NOM",
    "TATU_TINTAS",
    "TERRENOS",
    "TERTULIANOS",
    "TICKER_BASE",
    "TICKER_PLANTILLA",
    "TICKER_PPS",
    "TIENDA_DEF",
    "TIERRA_DIA",
    "TIERRA_NOCHE",
    "TIERRA_NUBES",
    "TIERRA_TEX",
    "TIERRA_TEX_EMB",
    "TIER_PAIS",
    "TIPOGRAFIAS",
    "TONOS",
    "TORNEOS_CORTOS",
    "TRAD",
    "TUT_PASOS",
    "UNLEET",
    "VALOR_PIVOTE",
    "VELS",
    "VEL_DEF",
    "VESTUARIO_EST",
    "VOTACIONES",
    "WIDGETS",
    "ZONAS_SPONSOR",
    "avg",
    "clamp",
    "esc",
    "float",
    "fmt$",
    "fmtEntrada",
    "ingresoEspectador",
    "pick",
    null
  ].filter(Boolean);

  var __xInforme = [], __xPaquete = {}, __xFuera = [];
  function __xAnota(s) { __xInforme.push(s); }

  __xLista.forEach(function (__xN) {
    var __xV;
    try { __xV = eval(__xN); }
    catch (e) { __xFuera.push(__xN + ' (no accesible)'); return; }
    if (typeof __xV === 'function') { __xFuera.push(__xN + ' (es una funcion)'); return; }
    if (__xV === undefined) { __xFuera.push(__xN + ' (undefined)'); return; }
    var __xT;
    try { __xT = JSON.stringify(__xV); }
    catch (e2) { __xFuera.push(__xN + ' (no serializable: ' + (e2 && e2.message) + ')'); return; }
    if (__xT === undefined) { __xFuera.push(__xN + ' (stringify dio undefined)'); return; }
    __xPaquete[__xN] = __xV;
  });

  __xAnota('EXPORTACION DE DATOS A JSON');
  __xAnota('='.repeat(70));
  __xAnota('');
  var __xClaves = Object.keys(__xPaquete).sort(function (a, b) {
    return JSON.stringify(__xPaquete[b]).length - JSON.stringify(__xPaquete[a]).length;
  });
  var __xTotal = 0;
  __xClaves.forEach(function (k) {
    var n = JSON.stringify(__xPaquete[k]).length; __xTotal += n;
    if (n > 8000) __xAnota('  ' + k.padEnd(22) + (n + ' bytes').padStart(12));
  });
  __xAnota('');
  __xAnota('  ' + __xClaves.length + ' tablas exportadas, ' + Math.round(__xTotal / 1024) + ' KB');
  __xAnota('  ' + __xFuera.length + ' descartadas (no son datos)');

  /* --- comprobacion contra el fallo de la sombra ------------------------
     Si una tabla exportada resulta ser IDENTICA a la lista de nombres que
     este script recorre, es que eval() devolvio la variable local en vez de
     la constante del juego. Se comprueba a proposito, porque el sintoma
     aparece mucho despues y en otro programa. */
  var __xSospechosas = [];
  var __xFirmaLista = JSON.stringify(__xLista);
  __xClaves.forEach(function (k) {
    if (JSON.stringify(__xPaquete[k]) === __xFirmaLista) __xSospechosas.push(k);
  });
  __xAnota('  tablas tapadas por una variable de este script: ' +
    (__xSospechosas.length ? __xSospechosas.join(', ') : 'ninguna'));

  /* Dos sondas de contenido, por si alguna tabla clave saliera vacia o mal. */
  __xAnota('  NOMBRES[0..2]  = ' + JSON.stringify((__xPaquete.NOMBRES || []).slice(0, 3)));
  __xAnota('  APELLIDOS[0..2]= ' + JSON.stringify((__xPaquete.APELLIDOS || []).slice(0, 3)));
  __xAnota('  DATA_P1[0]     = ' + JSON.stringify((__xPaquete.DATA_P1 || [])[0]));

  /* El volcado va dentro del propio <pre> del resultado, entre marcas: bajo
     file:// la pagina no puede escribir un fichero y en modo headless no hay
     descargador. PowerShell lo corta por las marcas. */
  var __xPre = document.createElement('pre');
  __xPre.id = 'RESULTADO';
  __xPre.textContent = __xInforme.join('\n') +
    '\n<<<<JSON>>>>\n' + JSON.stringify(__xPaquete) + '\n<<<<FIN>>>>';
  document.body.appendChild(__xPre);
})();
