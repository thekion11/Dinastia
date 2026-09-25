(function(){
  try{
    nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
    var v=0;while(G.fase!=='previa'&&G.fase!=='envivo'&&v<400){try{avanzarUnDia();}catch(e){}v++;}
    if(G.fase==='previa')iniciarEnVivo();
    var M=G.matchLive;setVel(0);
    for(var i=0;i<22;i++){M.min++;try{simularMinuto();}catch(e){}}
    G.jug[M.xiMi[3]].fis=28; G.jug[M.xiMi[4]].fis=52; G.jug[M.xiMi[5]].fis=97;
    try{arengar(M.xiMi[5]);}catch(e){}
    render();
    document.body.innerHTML='<div id="mv2d" style="width:1000px"></div>';
    document.body.style.margin='0';document.body.style.background='#0b140e';
    for(var k=0;k<30;k++)mvPintar();
    /* mvPintar se reprograma solo con requestAnimationFrame y vuelve a escribir el
       innerHTML, borrando cualquier retoque. Hay que anularlo ANTES de tocar nada. */
    if(window.__mvRAF){cancelAnimationFrame(window.__mvRAF);window.__mvRAF=0;}
    window.mvPintar=function(){};
    var svg=document.querySelector('#mv2d svg');
    if(svg){svg.setAttribute('viewBox','300 130 380 240');svg.style.width='1000px';}
    else document.body.innerHTML='<pre style="color:#f66">sin svg</pre>';
  }catch(e){document.body.innerHTML='<pre style="color:#f66">'+e.message+'\n'+e.stack+'</pre>';}
})();
