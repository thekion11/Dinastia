/* Con retraso: el juego repinta la portada en su propio window.load, asi que
   hacer esto durante el parseo no sirve de nada. */
setTimeout(function(){
  try{
    var cap=document.getElementById('capaIdioma'); if(cap&&cap.parentNode)cap.parentNode.removeChild(cap);
    var ic=document.getElementById('introCapa'); if(ic&&ic.parentNode)ic.parentNode.removeChild(ic);
    nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
    var c=G.clubes[G.miClub];
    var hay=0,tot=0;
    for(var id in G.clubes){tot++;if(equipReal(G.clubes[id],0))hay++;}
    setTab('club','kit');
    var info=document.createElement('pre');
    info.style.cssText='color:#7fe0a8;font:11px monospace;padding:5px;margin:0;background:#0b1210';
    info.textContent='club: '+descensurar(c.nombre)+'  ->  '+(equipReal(c,0)||'SIN EQUIPACION REAL')+
      '\nclubes con equipacion real: '+hay+' de '+tot;
    document.body.insertBefore(info,document.body.firstChild);
  }catch(e){document.body.innerHTML='<pre style="color:#f66">'+e.message+'\n'+e.stack+'</pre>';}
},900);
