/* Arranca una partida, mete al equipo en un partido en vivo, adelanta unos minutos
   para que los jugadores se hayan movido de su formacion inicial, y deja el campo
   pintado a pantalla completa para poder capturarlo. */
(function(){
  try{
    nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
    var v=0;while(G.fase!=='previa'&&G.fase!=='envivo'&&v<400){try{avanzarUnDia();}catch(e){}v++;}
    if(G.fase==='previa')iniciarEnVivo();
    var M=G.matchLive;
    setVel(0);
    for(var i=0;i<22;i++){M.min++;try{simularMinuto();}catch(e){}}
    /* Una arenga encendida para ver tambien su aro. */
    try{arengar(M.xiMi[7]);}catch(e){}
    render();
    /* El contenedor del campo, solo y a lo grande. */
    document.body.innerHTML='<div id="mv2d" style="width:1000px"></div>';
    document.body.style.margin='0';document.body.style.background='#0b140e';
    for(var k=0;k<40;k++)mvPintar();
  }catch(e){
    document.body.innerHTML='<pre style="color:#f66;font:14px monospace">'+e.message+'\n'+e.stack+'</pre>';
  }
})();
