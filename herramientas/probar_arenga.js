setTimeout(function(){
  var out=[];function di(s){out.push(s);}
  try{
    nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
    di('arengas en partida NUEVA = '+arengasDe()+'  '+(arengasDe()===3?'OK':'MAL'));

    var v=0;while(G.fase!=='previa'&&G.fase!=='envivo'&&v<400){try{avanzarUnDia();}catch(e){}v++;}
    if(G.fase==='previa')iniciarEnVivo();
    di('fase = '+G.fase);
    var M=G.matchLive, pid=M.xiMi[5], j=G.jug[pid];

    /* Lo importante: que el motor NOTE la arenga, no que se pinte una etiqueta. */
    var antes=fuerzaJug(j);
    arengar(pid);
    var luego=fuerzaJug(j);
    di('');
    di('fuerzaJug('+j.nombre+') antes = '+antes.toFixed(2));
    di('fuerzaJug('+j.nombre+') tras arengar = '+luego.toFixed(2));
    di('subida real = '+(((luego/antes)-1)*100).toFixed(1)+'%  '+(luego>antes?'EL MOTOR LO NOTA: OK':'MAL, es solo cosmetico'));
    di('arengas restantes = '+arengasDe()+'  '+(arengasDe()===2?'OK':'MAL'));
    di('no se puede arengar dos veces al mismo: ');
    arengar(pid);
    di('   arengas siguen en '+arengasDe()+'  '+(arengasDe()===2?'OK':'MAL'));

    /* Y que se le pase. */
    M.min+=ARENGA_MIN+1;
    di('');
    di('pasados '+(ARENGA_MIN+1)+' minutos -> conImpulso = '+conImpulso(pid)+'  '+(!conImpulso(pid)?'OK, se le paso':'MAL, es permanente'));
    di('fuerzaJug vuelve a la base: '+(Math.abs(fuerzaJug(j)-antes)<0.5?'OK':'MAL ('+fuerzaJug(j).toFixed(2)+' vs '+antes.toFixed(2)+')'));

    /* Se ganan ganando. */
    var ar0=arengasDe();
    M.hg=2;M.ag=0;M.min=90;
    try{finPartido();}catch(e){di('finPartido: '+e.message);}
    di('');
    di('tras ganar 2-0 (victoria + valla invicta): '+ar0+' -> '+arengasDe()+'  '+(arengasDe()===ar0+2?'OK':'MAL'));
  }catch(e){di('EXCEPCION: '+e.message+'\n'+e.stack);}
  var p=document.createElement('pre');p.id='MEDIDA';p.textContent=out.join('\n');document.body.appendChild(p);
},400);
