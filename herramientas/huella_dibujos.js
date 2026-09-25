/* ============================================================================
   HUELLA DE LOS DIBUJOS Y DE LOS EVENTOS
   ============================================================================
   Igual que huella_estadio.js pero para las otras funciones largas que hay que
   partir: las nueve portadas del menú (heroPortada), los retratos de jugador y
   de entrenador (caraSVG, caraDT) y el reparto de decisiones (resolverEvento).

   Si estas huellas no cambian tras mover código, el resultado es idéntico. El
   banco de pruebas dice si el juego revienta; esto dice si dibuja distinto, que
   es otra cosa y no la caza ninguna otra prueba.

   Con resolverEvento se hace algo distinto: no dibuja, decide. Se le pasa una
   partida con semilla fija y se anota el ESTADO que deja (saldo, moral, ánimo,
   confianza), que es lo que de verdad importa que no cambie.

   Uso:  run_harness.ps1 -Script huella_dibujos.js
   ============================================================================ */
(function () {
  'use strict';
  var salida = [];
  function anota(s) { salida.push(s); }

  function huella(s) {
    var h = 5381;
    for (var i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0;
    return (h >>> 0).toString(16).padStart(8, '0');
  }

  try {
    if (typeof difSel !== 'undefined') difSel = 'normal';
    if (typeof rolSel !== 'undefined') rolSel = 'dt';
    if (typeof desafiosSel !== 'undefined') desafiosSel = [];
    nuevaPartida('c1', 'Huella');
    G.miClub = 'c1';
    if (typeof armarXI === 'function') armarXI();

    anota('HUELLA DE DIBUJOS Y EVENTOS');
    anota('='.repeat(70));
    anota('');

    /* --- portadas del menú: nueve, una por modo de juego --------------- */
    if (typeof heroPortada === 'function') {
      /* heroPortada NO recibe cual dibujar: la lee de portadaSel(), que a su vez
         mira window.__port. Llamandola nueve veces seguidas salia NUEVE VECES LA
         MISMA portada, asi que la huella solo cubria un estilo de los nueve y el
         resto se habria refactorizado a ciegas. Se fija __port en cada vuelta. */
      var estilos = PORTADAS.map(function (p) { return p[0]; });
      estilos.forEach(function (nombre) {
        window.__port = nombre;
        var svg = '';
        try { svg = String(heroPortada()); }
        catch (e) { svg = 'FALLO ' + (e && e.message); }
        anota('  portada ' + nombre.padEnd(12) + ' huella=' + huella(svg) + '  largo=' + svg.length);
      });
      window.__port = null;
    }

    /* --- retratos: se cogen jugadores fijos de la plantilla ------------ */
    if (typeof caraSVG === 'function') {
      /* OJO: NO se pueden usar los jugadores de la partida. Se generan al azar en
         cada nuevaPartida, asi que la huella salia distinta en cada pasada y no
         servia para comparar nada. Se fabrican jugadores con el aspecto fijado a
         mano, que es lo unico que hace la prueba reproducible. */
      var pl = [];
      for (var q = 0; q < 12; q++) {
        pl.push({
          id: 'h' + q, nombre: 'Prueba ' + q, club: 'c1', pos: ['POR','DEF','MED','DEL'][q % 4],
          posE: ['POR','DFC','MC','DC'][q % 4], edad: 20 + q, ovr: 60 + q, dorsal: q + 1,
          look: { piel: ['#f0c39b','#d7a377','#b97f4f','#8a5a34'][q % 4],
                  pelo: q % 23, peloC: ['#231a14','#3d2a19','#6b4a2a','#c8a05a'][q % 4],
                  barba: q % 8, ceja: q % 3, ojos: q % 4, acc: q % 5,
                  nariz: q % 4, boca: q % 3, menton: q % 3, orejas: q % 3, cara: q % 4,
                  pecas: q % 5 === 0, tatu: q % 7 === 0, lunar: q % 6 === 0, cicatriz: q % 9 === 0 }
        });
      }
      var caras = '';
      for (var j = 0; j < Math.min(12, pl.length); j++) {
        for (var t = 0; t < 3; t++) caras += String(caraSVG(pl[j], [34, 54, 66][t]));
      }
      anota('  caraSVG      (12 jug x 3)   huella=' + huella(caras) + '  largo=' + caras.length);
    }

    if (typeof caraDT === 'function') {
      var dts = '';
      for (var d = 0; d < 6; d++) {
        try { dts += String(caraDT({ nombre: 'DT ' + d, id: 'dt' + d }, 48)); }
        catch (e2) { }
      }
      if (dts) anota('  caraDT       (6 tecnicos)   huella=' + huella(dts) + '  largo=' + dts.length);
    }

    /* --- resolverEvento: no dibuja, decide. Se mira lo que DEJA -------- */
    if (typeof resolverEvento === 'function' && typeof crearEventoDecision === 'function') {
      /* OJO: el evento vive en G.eventoPend, no en G.evento, y las respuestas son
         'a' y 'b', no un indice. Mirando el campo equivocado el bucle salia por
         `continue` las cuarenta vueltas y la huella se calculaba sobre una lista
         VACIA: daba siempre el mismo valor y habria dado por bueno cualquier
         cambio en las decisiones. Ademas crearEventoDecision solo dispara con un
         5% de probabilidad y entre las semanas 3 y 38, asi que hay que moverle la
         semana e insistir. */
      var estados = [];
      for (var k = 0; k < 400 && estados.length < 40; k++) {
        try {
          G.sem = 3 + (k % 35);
          G.eventoPend = null;
          crearEventoDecision();
          if (!G.eventoPend) continue;
          var idEv = G.eventoPend.id || G.eventoPend.tipo || '?';
          resolverEvento((estados.length % 2) ? 'b' : 'a');
          estados.push(idEv + ':' + [G.saldo, G.confianza,
                        plantelDe('c1').reduce(function (s, p) { return s + p.moral; }, 0)].join('/'));
        } catch (e3) { estados.push('ERR:' + (e3 && e3.message)); }
      }
      anota('  resolverEvento (' + estados.length + ' decisiones)  huella=' + huella(estados.join('|')));
      var rotas = estados.filter(function (s) { return s.indexOf('ERR:') === 0; });
      if (rotas.length) anota('  OJO: ' + rotas.length + ' decisiones reventaron -> ' + rotas[0]);
    }
  } catch (e) {
    anota('FALLO: ' + (e && e.message));
    anota(e && e.stack ? String(e.stack).split('\n').slice(0, 3).join(' | ') : '');
  }

  var pre = document.createElement('pre');
  pre.id = 'RESULTADO';
  pre.textContent = salida.join('\n');
  document.body.appendChild(pre);
})();
