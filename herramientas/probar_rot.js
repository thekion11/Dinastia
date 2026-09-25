setTimeout(function(){
  var out=[];function di(s){out.push(s);}
  try{
    document.body.innerHTML='<div id="globo3d" style="width:400px"></div><pre id="MEDIDA"></pre>';
    var g=globoEstado();
    di('partida desde  lon='+g.lon.toFixed(1)+' lat='+g.lat.toFixed(1));
    globoIr('JPN');
    var d=GLOBO_PAIS['JPN'];
    di('destino JPN    lon='+d[0]+'  -> tLon='+g.tLon.toFixed(1)+' tLat='+g.tLat.toFixed(1));
    di('bucle activo   __globRAF='+(window.__globRAF?'si':'NO'));
    /* Simulamos 90 pasos del bucle sin depender de requestAnimationFrame. */
    for(var i=0;i<90;i++){
      if(!g.arr){
        g.lon+=(g.tLon-g.lon)*0.075;
        g.lat+=(g.tLat-g.lat)*0.075;
      }
    }
    di('tras 90 pasos  lon='+g.lon.toFixed(1)+' lat='+g.lat.toFixed(1));
    var cerca=Math.abs(g.lon-g.tLon)<2;
    di('llego al pais: '+(cerca?'SI':'NO'));
  }catch(e){di('EXCEPCION: '+e.message);}
  document.getElementById('MEDIDA').textContent=out.join('\n');
},400);
