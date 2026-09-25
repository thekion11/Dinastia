/* ============================================================================
   HUELLA DEL ESTADIO 3D
   ============================================================================
   Genera el SVG del estadio con una configuración fija y saca su huella. Sirve
   para refactorizar `estadio3D` —985 líneas— con red de seguridad: si la huella
   de antes y la de después coinciden, el dibujo es idéntico byte a byte y el
   cambio no ha alterado NADA, por mucho que se hayan movido las secciones de
   sitio.

   POR QUÉ HACE FALTA
   El banco de pruebas dice si el juego revienta, no si el estadio se dibuja
   distinto. Un refactor puede dejar el juego funcionando y el estadio torcido, y
   eso no lo caza ninguna prueba de las que hay. Esto sí.

   Se prueban varias configuraciones (formas, techos, climas, niveles de
   detalle) porque las secciones se comportan distinto según el diseño: un fallo
   podría esconderse en la forma 'herradura' y no verse en 'cuenco'.

   Uso:  run_harness.ps1 -Script huella_estadio.js
   ============================================================================ */
(function () {
  'use strict';
  var salida = [];
  function anota(s) { salida.push(s); }

  /* Huella sencilla y estable (djb2 de 32 bits). No hace falta criptografía:
     solo detectar que dos cadenas larguísimas son distintas. */
  function huella(s) {
    var h = 5381;
    for (var i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0;
    return (h >>> 0).toString(16).padStart(8, '0');
  }

  var CASOS = [
    { forma: 'cuenco',    techo: 'anillo', clima: 'tarde',  niveles: 2, detalle: 'medio' },
    { forma: 'ingles',    techo: 'total',  clima: 'noche',  niveles: 3, detalle: 'alto' },
    { forma: 'herradura', techo: 'sin',    clima: 'dia',    niveles: 1, detalle: 'bajo' },
    { forma: 'caldera',   techo: 'anillo', clima: 'lluvia', niveles: 3, detalle: 'ultra' },
  ];

  try {
    if (typeof difSel !== 'undefined') difSel = 'normal';
    if (typeof rolSel !== 'undefined') rolSel = 'dt';
    if (typeof desafiosSel !== 'undefined') desafiosSel = [];
    nuevaPartida('c1', 'Huella');
    G.miClub = 'c1';
    if (typeof armarXI === 'function') armarXI();

    anota('HUELLA DEL ESTADIO 3D');
    anota('='.repeat(70));
    anota('Si estas huellas no cambian tras un refactor, el dibujo es idéntico.');
    anota('');

    var S = initEst();
    CASOS.forEach(function (caso, n) {
      /* Se fija la semilla del club y su diseño para que el dibujo sea
         reproducible: sin esto, cada pasada saldría distinta y la huella no
         valdría para nada. */
      S.forma = caso.forma; S.techo = caso.techo; S.clima = caso.clima;
      S.niveles = caso.niveles; S.detalle = caso.detalle;
      S.publico = 'lleno';
      G.ultAsist = 30000;
      var svg = '';
      try {
        svg = String(estadio3D({ detalle: caso.detalle }));
      } catch (e) {
        anota('  caso ' + n + ' (' + caso.forma + '): FALLO ' + (e && e.message));
        return;
      }
      anota('  caso ' + n + '  ' + caso.forma.padEnd(10) +
            ' techo=' + caso.techo.padEnd(7) +
            ' ' + caso.clima.padEnd(7) +
            ' det=' + caso.detalle.padEnd(6) +
            '  huella=' + huella(svg) +
            '  largo=' + svg.length);
    });
  } catch (e) {
    anota('FALLO: ' + (e && e.message));
    anota(e && e.stack ? String(e.stack).split('\n').slice(0, 3).join(' | ') : '');
  }

  var pre = document.createElement('pre');
  pre.id = 'RESULTADO';
  pre.textContent = salida.join('\n');
  document.body.appendChild(pre);
})();
