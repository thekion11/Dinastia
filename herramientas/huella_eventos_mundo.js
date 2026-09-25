/* ============================================================================
   LAS SEIS DECISIONES DE MUNDO
   ============================================================================
   Por que existe esta prueba: al sacar el bloque de mundo de resolverEvento a
   su propia funcion se quedo sin el parametro `op`, y su primera linea moria
   con "op is not defined". El banco de pruebas dio CERO ERRORES en tres
   carreras de tres temporadas, porque estos seis eventos salen con
   probabilidades de entre el 2% y el 5% y ademas piden condiciones (ser dueno,
   pasar de la semana 10, tener un canterano con linaje). Confiar en que el azar
   los saque es no probarlos.

   Aqui se fabrican los seis a mano, con las dos respuestas cada uno, y se
   comprueba que ninguno revienta y que todos dejan el evento consumido
   (G.eventoPend a null), que es la senal de que la decision se aplico.

   Uso:  run_harness.ps1 -Script huella_eventos_mundo.js
   ============================================================================ */
(function () {
  'use strict';
  var salida = [];
  function anota(s) { salida.push(s); }

  try {
    if (typeof difSel !== 'undefined') difSel = 'normal';
    if (typeof rolSel !== 'undefined') rolSel = 'dt';
    if (typeof desafiosSel !== 'undefined') desafiosSel = [];
    nuevaPartida('c1', 'Eventos');
    G.miClub = 'c1';
    if (typeof armarXI === 'function') armarXI();

    var pl = plantelDe(G.miClub);
    var rival = Object.values(G.clubes).filter(function (c) { return c.id !== G.miClub; })[0];
    var propio = pl[0];
    var ajeno = Object.values(G.jug).filter(function (j) { return j.club && j.club !== G.miClub; })[0];

    /* padreCargo necesita un canterano CON linaje: sin el, la rama no se recorre
       entera y la prueba pasaria sin haber probado nada. */
    propio.linaje = { padre: 'Marcelo Prueba', club: rival.nombre, ovr: 84 };

    var casos = [
      { tipo: 'fusion',          extra: { cid: rival.id } },
      { tipo: 'veteranos',       extra: {} },
      { tipo: 'alianza',         extra: { cid: rival.id } },
      { tipo: 'fichajeImpuesto', extra: { pid: ajeno.id, costo: 1200000 } },
      { tipo: 'padreCargo',      extra: { pid: propio.id } },
      { tipo: 'guerraDatos',     extra: {} }
    ];

    anota('DECISIONES DE MUNDO');
    anota('='.repeat(70));
    anota('');

    var fallos = 0;
    casos.forEach(function (c) {
      ['a', 'b'].forEach(function (op) {
        var E = { txt: 'prueba', aTxt: 'si', bTxt: 'no', tipo: c.tipo };
        for (var k in c.extra) E[k] = c.extra[k];
        G.eventoPend = E;
        var res;
        try {
          resolverEvento(op);
          res = (G.eventoPend === null) ? 'aplicada' : 'NO CONSUMIO EL EVENTO';
        } catch (e) {
          res = 'REVIENTA: ' + (e && e.message);
        }
        if (res !== 'aplicada') fallos++;
        anota('  ' + (c.tipo + ' (' + op + ')').padEnd(28) + res);
        G.eventoPend = null;
      });
    });

    anota('');
    anota('  ' + casos.length * 2 + ' decisiones probadas, fallos=' + fallos);
  } catch (e) {
    anota('FALLO: ' + (e && e.message));
    anota(e && e.stack ? String(e.stack).split('\n').slice(0, 3).join(' | ') : '');
  }

  var pre = document.createElement('pre');
  pre.id = 'RESULTADO';
  pre.textContent = salida.join('\n');
  document.body.appendChild(pre);
})();
