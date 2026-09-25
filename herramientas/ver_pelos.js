(function(){
  try{
    var base=lookDTPorDefecto();
    var html='<div style="display:grid;grid-template-columns:repeat(8,1fr);gap:4px;padding:10px;background:#0e1512">';
    /* Los 23 cortes, cada uno con su nombre. */
    DT_PELOS.forEach(function(p){
      var L=Object.assign({},base,{pelo:p,edad:38,peloC:'#2e2018',barba:0,gafas:false});
      html+='<div style="text-align:center">'+caraDT(L,74)+
        '<div style="font:9px sans-serif;color:#9fb3a6;margin-top:2px">'+(PELO_NOM[p]||p)+'</div></div>';
    });
    html+='</div><div style="color:#7fe0a8;font:12px sans-serif;padding:6px 12px">VARIANTES del mismo corte (melena): volumen, raya y rapado lateral</div>';
    html+='<div style="display:grid;grid-template-columns:repeat(8,1fr);gap:4px;padding:0 10px 10px;background:#0e1512">';
    [[0,0,false],[1,0,false],[2,0,false],[1,1,false],[1,2,false],[1,3,false],[1,0,true],[2,2,true]].forEach(function(v){
      var L=Object.assign({},base,{pelo:'melena',edad:38,peloC:'#4a3320',vol:v[0],raya:v[1],lados:v[2],barba:0,gafas:false});
      html+='<div style="text-align:center">'+caraDT(L,74)+
        '<div style="font:9px sans-serif;color:#9fb3a6">'+DT_VOLS[v[0]].slice(0,4)+' · '+DT_RAYAS[v[1]].replace('Raya a la ','').replace('Raya al ','').slice(0,4)+(v[2]?' · rap':'')+'</div></div>';
    });
    html+='</div><div style="color:#7fe0a8;font:12px sans-serif;padding:6px 12px">COLORES libres: barba, ojos y ropa aparte del pelo</div>';
    html+='<div style="display:grid;grid-template-columns:repeat(8,1fr);gap:4px;padding:0 10px 10px;background:#0e1512">';
    [['#2f5f86','#b9903f'],['#3f6b3a','#1a1310'],['#6b3a2a','#c7c7c7'],['#5b6b74','#7a1f4f']].forEach(function(cc){
      var L=Object.assign({},base,{pelo:'corto',edad:40,peloC:'#1a1310',barba:1,barbaC:cc[1],ojosC:cc[0],gafas:false});
      html+='<div style="text-align:center">'+caraDT(L,74)+'<div style="font:9px sans-serif;color:#9fb3a6">ojos+barba</div></div>';
    });
    [['#c43b6b','#ffffff'],['#1f8a54','#e8e8e8'],['#e8632a','#141414'],['#3a2f6b','#d8bd77']].forEach(function(cc){
      var L=Object.assign({},base,{pelo:'corto',edad:40,peloC:'#2e2018',ropaC:cc[0],ropaC2:cc[1],barba:0,gafas:false});
      html+='<div style="text-align:center">'+caraDT(L,74)+'<div style="font:9px sans-serif;color:#9fb3a6">ropa</div></div>';
    });
    html+='</div>';
    document.body.innerHTML=html;document.body.style.margin='0';document.body.style.background='#0e1512';
  }catch(e){document.body.innerHTML='<pre style="color:#f66">'+e.message+'\n'+e.stack+'</pre>';}
})();
