setTimeout(function(){
  var out=[];
  try{
    nuevaPartida('c1','T');
    for(var cid in G.clubes){var c=G.clubes[cid];out.push(descensurar(c.nombre)+'\t'+c.pais+'\t'+c.div);}
  }catch(e){out.push('ERR '+e.message);}
  var p=document.createElement('pre');p.id='MEDIDA';p.textContent=out.join('\n');document.body.appendChild(p);
},400);
