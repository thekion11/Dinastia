setTimeout(async function(){
  var out=[];
  function di(s){out.push(s);}
  try{
    nuevaPartida('c1','Tester'); G.miClub='c1'; armarXI();
    /* Jugamos un poco para que el estado no sea el recien creado. */
    for(var i=0;i<40;i++){try{avanzarUnDia();}catch(e){}}
    var antesJug=Object.keys(G.jug).length,
        antesSaldo=G.saldo, antesSem=G.sem, antesAño=G.año,
        unId=Object.keys(G.jug)[500],
        antesCara=JSON.stringify(G.jug[unId].look),
        antesAt=JSON.stringify(G.jug[unId].at),
        antesNom=G.jug[unId].nombre;

    localStorage.clear();
    var ok=await guardarAhora();
    di('guardarAhora() -> '+ok);
    var raw=localStorage.getItem('dinastia_auto');
    di('dinastia_auto  = '+(raw?raw.length+' caracteres':'NULL'));
    di('comprimido     = '+(raw&&raw.indexOf('LZ1:')===0));
    di('leerAuto()     = '+(leerAuto()?'ofrece Continuar':'NULL'));

    /* Simulamos cerrar y reabrir: se tira el mundo y se recarga desde el guardado. */
    G=null;
    await continuarPartida();
    di('--- tras reabrir ---');
    di('jugadores  '+antesJug+' -> '+Object.keys(G.jug).length+'  '+(antesJug===Object.keys(G.jug).length?'OK':'MAL'));
    di('saldo      '+(antesSaldo===G.saldo?'OK':'MAL ('+antesSaldo+' -> '+G.saldo+')'));
    di('fecha      '+(antesSem===G.sem&&antesAño===G.año?'OK':'MAL'));
    di('nombre     '+(antesNom===G.jug[unId].nombre?'OK':'MAL'));
    di('cara       '+(antesCara===JSON.stringify(G.jug[unId].look)?'OK (identica)':'MAL (cambio)'));
    di('atributos  '+(antesAt===JSON.stringify(G.jug[unId].at)?'OK (identicos)':'MAL (cambiaron)'));

    /* Ranura manual. */
    await guardarRanura(2);
    di('ranura 2 escrita = '+(localStorage.getItem('dinastia_slot_2')?'SI':'NO'));
    di('meta ranura 2    = '+(metaRanura(2)?'SI':'NO'));

    /* Y que un JSON que no sea un guardado ya no destruya la partida. */
    var ta=document.createElement('textarea');ta.id='saveArea';ta.value='{"otraCosa":1}';document.body.appendChild(ta);
    var clubAntes=G.miClub;
    await importarSave();
    di('importar basura NO rompe la partida: '+(G&&G.miClub===clubAntes?'OK':'MAL'));
  }catch(e){di('EXCEPCION: '+e.message+'\n'+e.stack);}
  var p=document.createElement('pre');p.id='MEDIDA';p.textContent=out.join('\n');document.body.appendChild(p);
},400);
