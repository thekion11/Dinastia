setTimeout(function(){
  var out=[];function di(s){out.push(s);}
  try{
    nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
    di('--- VELOCIDADES ---');
    di('tabla VELS: '+VELS.map(function(V,i){return i?i+'='+V.lab+'('+V.ms+'ms)':'';}).filter(Boolean).join('  '));
    di('por defecto = '+VEL_DEF+' ('+VELS[VEL_DEF].lab+', '+VELS[VEL_DEF].ms+'ms) '+
       (VELS[VEL_DEF].ms>VELS[2].ms?'MAS LENTA que la x1 vieja: OK':'MAL'));

    /* Migracion de una partida vieja: la escala antigua iba de 1 a 4 y la x8 era la 4. */
    G.ajustes.vel=4;delete G.ajustes.velV2;
    migrar();
    di('partida vieja en x8 (4) -> ahora '+G.ajustes.vel+' = '+VELS[G.ajustes.vel].lab+
       ' '+(VELS[G.ajustes.vel].lab==='x8'?'OK':'MAL'));
    migrar();  // no debe volver a desplazarse
    di('segunda carga no la desplaza otra vez: '+(VELS[G.ajustes.vel].lab==='x8'?'OK':'MAL'));

    di('');
    di('--- EL PARTIDO SE COME LA PANTALLA ---');
    /* Llevamos el juego hasta un partido en vivo. */
    var vueltas=0;
    while(G.fase!=='envivo'&&vueltas<400){try{avanzarUnDia();}catch(e){}vueltas++;}
    if(G.fase==="previa"){try{iniciarEnVivo();}catch(e){di("iniciarEnVivo fallo: "+e.message);}}
    di("fase alcanzada = "+G.fase);
    if(G.fase==='envivo'){
      render();
      di('body.modoPartido = '+document.body.classList.contains('modoPartido'));
      var tabs=getComputedStyle(document.getElementById('tabs')).display;
      di('barra de pestanas = '+tabs+'  '+(tabs==='none'?'OK':'MAL'));

      var antes=vista.tab;
      setTab('finanzas');
      di('setTab("finanzas") en vivo -> pestana sigue en "'+vista.tab+'"  '+(vista.tab===antes?'OK':'MAL'));

      /* La ficha de un jugador no debe sacarnos del partido. */
      var pid=Object.keys(G.jug)[0];
      abrirJug(pid);
      var sigue=document.body.classList.contains('modoPartido');
      di('abrir ficha de jugador -> sigue en modo partido: '+sigue+'  '+(sigue?'OK':'MAL'));
      cerrarJug();
      di('cerrar ficha -> vuelve al campo: '+(document.body.classList.contains('modoPartido')?'OK':'MAL'));

      di('dinastiaAtras() en vivo no sale: '+(dinastiaAtras()===true?'OK':'MAL'));
    }
  }catch(e){di('EXCEPCION: '+e.message+'\n'+e.stack);}
  var p=document.createElement('pre');p.id='MEDIDA';p.textContent=out.join('\n');document.body.appendChild(p);
},400);
