setTimeout(function(){
  var out=[];function di(s){out.push(s);}
  try{
    nuevaPartida('c1','Tester');G.miClub='c1';armarXI();

    /* 1. ¿Cuantos clubes tienen datos reales y cuantos no? */
    var conReales=0,sinReales=0,fallos=[];
    for(var cid in G.clubes){
      var c=G.clubes[cid], l=realesDe(c.nombre);
      if(l&&l.length)conReales++; else {sinReales++; if(fallos.length<8)fallos.push(c.nombre);}
    }
    di('clubes con plantilla real = '+conReales+'   sin ella = '+sinReales);
    di('ejemplos sin datos: '+fallos.join(', '));

    /* 2. ¿Las medias de los cracks coinciden con lo escrito en REALES? */
    di('');
    di('--- CONTRASTE con lo que dice REALES ---');
    var busca=['Kylian Mbappé','Jude Bellingham','Vinícius Júnior','Thibaut Courtois','Arturo Vidal','Fernando Zampedri'];
    busca.forEach(function(n){
      var j=null;
      for(var id in G.jug){ if(descensurar(G.jug[id].nombre)===n){j=G.jug[id];break;} }
      di('  '+n+': '+(j?('media en juego = '+j.ovr+'  edad '+j.edad+'  real='+(j.real?'si':'NO')):'NO ESTA EN EL MUNDO'));
    });

    /* 3. ¿Cual es el mejor jugador del mundo y de que club? */
    di('');
    var top=Object.values(G.jug).sort(function(a,b){return b.ovr-a.ovr;}).slice(0,8);
    di('--- LOS 8 MEJORES DEL MUNDO ---');
    top.forEach(function(j){
      var c=G.clubes[j.club];
      di('  '+j.ovr+'  '+descensurar(j.nombre)+'  ('+(c?descensurar(c.nombre):'libre')+')  real='+(j.real?'si':'NO'));
    });

    /* 4. ¿Como quedan los suplentes GENERADOS de un club grande? */
    di('');
    var rm=null; for(var cid2 in G.clubes) if(descensurar(G.clubes[cid2].nombre).indexOf('Real Madrid')>=0){rm=G.clubes[cid2];break;}
    if(rm){
      var pl=plantelDe(rm.id).sort(function(a,b){return b.ovr-a.ovr;});
      di('--- PLANTEL DE '+descensurar(rm.nombre)+' ('+pl.length+' jugadores) ---');
      pl.forEach(function(j){di('  '+j.ovr+'  '+(j.real?'REAL ':'gen  ')+descensurar(j.nombre)+'  '+j.posE+'  '+j.edad+'a');});
    }
  }catch(e){di('EXCEPCION: '+e.message+'\n'+e.stack);}
  var p=document.createElement('pre');p.id='MEDIDA';p.textContent=out.join('\n');document.body.appendChild(p);
},400);
