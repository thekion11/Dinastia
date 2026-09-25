setTimeout(function(){
  var out=[];
  try{
    var cap=document.getElementById('capaIdioma'); if(cap&&cap.parentNode)cap.parentNode.removeChild(cap);
    nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
    /* Un club con historia: varias instalaciones subidas y una obra en marcha,
       para que la ciudad tenga algo que ensenar. */
    G.inst={trib:6,cal:4,med:3,ct:5,acad:4,com:3,gim:3,resid:2,video:2,
            rehab:2,museo:2,park:3,pren:1,cocina:2,piscina:2};
    G.obras=[{k:'esports',sem:4},{k:'guarderia',sem:2}];
    G.estadioNom='Estadio Monumental';
    var c=G.clubes[G.miClub];
    var k=colKit(c);
    var data={club:{nombre:descensurar(c.nombre),c1:k[0],c2:k[1],cap:capEfectivo(),rep:c.rep,estadioNom:G.estadioNom},
              inst:Object.assign({},G.inst),obras:G.obras.map(function(o){return{k:o.k,semanas:o.sem};})};
    out.push(JSON.stringify(data));
  }catch(e){out.push('ERR '+e.message);}
  var p=document.createElement('pre');p.id='MEDIDA';p.textContent=out.join('\n');document.body.appendChild(p);
},900);
