(function(){
  try{
    document.body.innerHTML='<div id="globo3d" style="width:680px;background:#04080e"></div><pre id="DBG" style="color:#7fe0a8;font:12px monospace;padding:6px"></pre>';
    document.body.style.margin='0';document.body.style.background='#04080e';
    window.__pP='ESP';
    var c=GLOBO_PAIS['ESP'];
    var g=globoEstado(); g.lon=c[0]; g.lat=Math.max(-55,Math.min(55,c[1]*0.72));
    g.tLon=g.lon; g.tLat=g.lat;
    pintarGlobo();
    var t=0, esperar=setInterval(function(){
      t++;
      if(__glListo||__texDatos){
        pintarGlobo();
        /* Medimos FPS de verdad: 60 repintados seguidos y cuanto tardan. */
        var t0=performance.now();
        for(var k=0;k<60;k++)pintarGlobo();
        var ms=(performance.now()-t0)/60;
        document.getElementById('DBG').textContent=
          'motor: '+(__glListo?'WebGL':'canvas 2D (respaldo)')+
          '   ms por fotograma: '+ms.toFixed(2)+
          '   FPS posibles: '+Math.round(1000/Math.max(ms,0.01))+
          '   textura: '+(__glImposible?'sin GL':'ok');
        clearInterval(esperar);
      } else if(t>200){ clearInterval(esperar);
        document.getElementById('DBG').textContent='NO cargo ningun motor'; }
    },50);
  }catch(e){document.body.innerHTML='<pre id="DBG" style="color:#f66">'+e.message+'\n'+e.stack+'</pre>';}
})();
