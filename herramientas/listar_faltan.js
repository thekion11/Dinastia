setTimeout(function(){
  var out=[];
  try{
    nuevaPartida('c1','Tester');
    var porPais={};
    for(var cid in G.clubes){
      var c=G.clubes[cid], l=realesDe(c.nombre);
      if(l&&l.length)continue;
      (porPais[c.pais]=porPais[c.pais]||[]).push(descensurar(c.nombre)+' (d'+c.div+',rep'+c.rep+')');
    }
    var paises=Object.keys(porPais).sort(function(a,b){return porPais[b].length-porPais[a].length;});
    paises.forEach(function(p){
      out.push('### '+p+' ('+porPais[p].length+')');
      out.push('   '+porPais[p].join(' | '));
    });
  }catch(e){out.push('ERR '+e.message);}
  var pre=document.createElement('pre');pre.id='MEDIDA';pre.textContent=out.join('\n');document.body.appendChild(pre);
},400);
