/* Mide si la partida CABE en localStorage. Escribe el resultado en un <pre id="MEDIDA">
   para poder leerlo con --dump-dom. */
setTimeout(function(){
  var out = [];
  function di(s){ out.push(s); }
  try{
    nuevaPartida('c1','Tester'); G.miClub='c1'; armarXI();

    var dump = serializar();
    var nJug = Object.keys(G.jug).length;
    var nClu = Object.keys(G.clubes).length;
    di('clubes=' + nClu + '  jugadores=' + nJug);
    di('serializar() = ' + dump.length + ' caracteres');

    /* Capacidad real del localStorage de ESTE origen, por biseccion con una clave de prueba. */
    localStorage.clear();
    var lo = 0, hi = 20000000;
    while (hi - lo > 20000){
      var mid = Math.floor((lo + hi) / 2);
      try { localStorage.setItem('__cap', new Array(mid + 1).join('x')); lo = mid; }
      catch(e){ hi = mid; }
    }
    try { localStorage.removeItem('__cap'); } catch(e){}
    di('cuota real     = ~' + lo + ' caracteres');
    di('VEREDICTO: ' + (dump.length > lo ? 'NO CABE — el juego NUNCA guarda' : 'cabe'));

    /* Y ahora la prueba que de verdad importa: ¿guardarLS() consigue guardar? */
    localStorage.clear();
    var ok = guardarLS();
    di('guardarLS() devolvio ' + ok);
    di('dinastia_auto quedo ' + (localStorage.getItem('dinastia_auto') ? 'ESCRITO' : 'NULL'));
    di('leerAuto() devuelve ' + (leerAuto() ? 'una partida' : 'NULL (la portada no ofrecera Continuar)'));

    /* Reparto del peso, para saber donde recortar. */
    var pesoJug = JSON.stringify(G.jug).length;
    di('peso de G.jug  = ' + pesoJug + '  (' + Math.round(pesoJug * 100 / dump.length) + '% del total)');
    var unId = Object.keys(G.jug)[0], campos = [];
    for (var k in G.jug[unId]) campos.push(k);
    var porCampo = {};
    campos.forEach(function(k){
      var t = 0;
      for (var id in G.jug) t += JSON.stringify(G.jug[id][k] === undefined ? null : G.jug[id][k]).length;
      porCampo[k] = t;
    });
    campos.sort(function(a,b){ return porCampo[b] - porCampo[a]; });
    di('campos mas gordos por jugador:');
    campos.slice(0, 10).forEach(function(k){
      di('   ' + k + ' = ' + porCampo[k] + ' car (' + Math.round(porCampo[k] * 100 / pesoJug) + '% de G.jug)');
    });
  } catch(e){
    di('EXCEPCION: ' + (e && e.message) + '\n' + (e && e.stack));
  }
  var pre = document.createElement('pre');
  pre.id = 'MEDIDA';
  pre.textContent = out.join('\n');
  document.body.appendChild(pre);
}, 400);
