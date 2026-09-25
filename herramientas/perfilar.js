/* ============================================================================
   PERFILADOR DE DINASTIA
   ============================================================================
   Mide cuanto tarda de verdad cada parte del motor, en vez de suponerlo. Se
   inyecta igual que el banco de pruebas: envuelve las funciones sospechosas,
   juega una temporada completa y vuelca los tiempos.

   POR QUE ASI Y NO A OJO
   Optimizar sin medir es adivinar. Una funcion de 300 lineas puede correr una
   vez por temporada y no costar nada, y una de tres lineas dentro del bucle de
   minutos puede llevarse la mitad del tiempo. Lo unico que lo dice es el reloj.

   Se envuelve cada funcion global por su nombre (son todas globales, asi que
   basta con reasignar window.nombre). Se guarda cuantas veces se llama y el
   total acumulado; el coste PROPIO se aproxima restando lo que gastaron las
   funciones envueltas llamadas desde dentro, para que una funcion no se lleve
   el merito del trabajo de sus hijas.
   ============================================================================ */
(function () {
  'use strict';

  var OBJETIVO = [
    'simularMinuto', 'procesoSemanal', 'finTemporada', 'finPartido',
    'render', 'cerrarJornada', 'continuar', 'iniciarEnVivo', 'simularTodo',
    'fuerzaJug', 'calcEco', 'genAtributos', 'lookDe', 'caraSVG', 'escudo',
    'plantelDe', 'tablaLiga', 'ovrEnPos', 'nuevaPartida', 'estadio3D',
    'mvPintar', 'heroPortada', 'guardarLS',
    // Segunda ronda de sospechosos: cerrarJornada salia con 41 ms PROPIOS por
    // llamada, pero solo tiene 37 lineas. Ese tiempo no era suyo: era de las
    // funciones que llama y que no estaban instrumentadas, asi que se le
    // apuntaban a ella. Anadirlas es la unica forma de saber de quien es.
    'simRapido', 'resolverRondaCopa', 'resolverRondaConti', 'chequeoDirectorio',
    'nuevaPrensa', 'tablaLiga', 'armarXI', 'aptitud', 'clamp', 'setTab',
    'noticiaResultado', 'cerrarApertura', 'valorJug', 'aplicarEntreno'
  ];

  var stats = {};
  var pila = [];

  function envolver(nombre) {
    var orig = window[nombre];
    if (typeof orig !== 'function') return false;
    stats[nombre] = { n: 0, total: 0, propio: 0 };
    window[nombre] = function () {
      var s = stats[nombre];
      s.n++;
      var marco = { hijos: 0 };
      pila.push(marco);
      var t0 = performance.now();
      try {
        return orig.apply(this, arguments);
      } finally {
        var dt = performance.now() - t0;
        pila.pop();
        s.total += dt;
        s.propio += dt - marco.hijos;
        if (pila.length) pila[pila.length - 1].hijos += dt;
      }
    };
    return true;
  }

  var envueltas = OBJETIVO.filter(envolver);

  /* Arranque IDENTICO al del banco de pruebas (harness.js). No vale con llamar a
     nuevaPartida('dt'): el primer argumento es el ID del club, no el rol, y con
     un id inexistente el juego revienta al generar las ofertas de auspicio
     ("Cannot read properties of undefined (reading 'rep')"). */
  function arrancar() {
    if (typeof difSel !== 'undefined') difSel = 'normal';
    if (typeof rolSel !== 'undefined') rolSel = 'dt';
    if (typeof desafiosSel !== 'undefined') desafiosSel = [];
    nuevaPartida('c1', 'Perfil');
    G.miClub = 'c1'; G.rol = 'dt';
    if (typeof armarXI === 'function') armarXI();
    if (typeof initDirectrices === 'function') initDirectrices();
  }

  /* Se juega con render() DESACTIVADO, igual que el banco de pruebas. Es lo que
     hay que medir aqui: el coste del MOTOR. Si se deja pintando, el reloj se lo
     lleva la interfaz y no se ve donde esta el trabajo de verdad. El coste de
     pintar se mide aparte, mas abajo. */
  function jugarTemporada(anios) {
    var a0 = G.año, i = 0;
    var _render = window.render;
    window.render = function () {};
    try {
      for (i = 0; i < 4000; i++) {
        if (G.fase === 'despedido') break;
        if (G.fase === 'previa') { iniciarEnVivo(); simularTodo(); }
        else if (G.fase === 'envivo') { simularTodo(); }
        else if (G.fase === 'post') { cerrarJornada(); }
        else { continuar(); }
        if (G.año >= a0 + anios) break;
      }
    } finally { window.render = _render; }
    return i;
  }

  var salida = [];
  function anota(s) { salida.push(s); }

  try {
    var t0 = performance.now();
    arrancar();
    var tNueva = performance.now() - t0;

    var t1 = performance.now();
    var vueltas = jugarTemporada(2);
    var tTemporada = performance.now() - t1;

    /* Coste de PINTAR, medido aparte: se recorren las pantallas principales unas
       cuantas veces. Es lo que nota el jugador al cambiar de pestana. */
    var tPintar = 0, nPintar = 0;
    try {
      var pantallas = [['club', 'inicio'], ['plantel', 'jugadores'], ['finanzas', 'mercado'],
                       ['mundo', 'tablaP1'], ['plantel', 'tactica']];
      var tp0 = performance.now();
      for (var r = 0; r < 6; r++) {
        for (var q = 0; q < pantallas.length; q++) {
          vista.tab = pantallas[q][0]; vista.sub = pantallas[q][1];
          render(); nPintar++;
        }
      }
      tPintar = performance.now() - tp0;
    } catch (e2) { anota('(no se pudo medir el pintado: ' + (e2 && e2.message) + ')'); }

    anota('PERFILADO DE DINASTIA');
    anota('='.repeat(70));
    anota('funciones instrumentadas: ' + envueltas.length + ' de ' + OBJETIVO.length);
    anota('nuevaPartida:   ' + tNueva.toFixed(0) + ' ms');
    anota('dos temporadas: ' + tTemporada.toFixed(0) + ' ms  (' + vueltas + ' vueltas de bucle)');
    anota('pintar:         ' + tPintar.toFixed(0) + ' ms en ' + nPintar + ' render() = ' +
          (nPintar ? (tPintar / nPintar).toFixed(1) : '?') + ' ms por pantalla');
    anota('');
    anota('  funcion                 llamadas      total ms    propio ms   ms/llamada');
    anota('  ' + '-'.repeat(68));

    var filas = Object.keys(stats).map(function (k) {
      return { n: k, c: stats[k].n, t: stats[k].total, p: stats[k].propio };
    }).filter(function (f) { return f.c > 0; })
      .sort(function (a, b) { return b.p - a.p; });

    filas.forEach(function (f) {
      anota('  ' + f.n.padEnd(22) +
        String(f.c).padStart(10) +
        f.t.toFixed(1).padStart(13) +
        f.p.toFixed(1).padStart(13) +
        (f.t / f.c).toFixed(3).padStart(13));
    });

    anota('');
    anota('LECTURA: "propio" es lo que cuesta la funcion SIN contar las que llama.');
    anota('Es la columna que dice donde optimizar; "total" solo dice quien manda.');
  } catch (e) {
    anota('FALLO AL PERFILAR: ' + (e && e.message));
    anota(e && e.stack ? String(e.stack).split('\n').slice(0, 4).join(' | ') : '');
  }

  var pre = document.createElement('pre');
  pre.id = 'RESULTADO';
  pre.textContent = salida.join('\n');
  document.body.appendChild(pre);
})();
