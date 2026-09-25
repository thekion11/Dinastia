setTimeout(function(){
  var out=[];
  function di(s){out.push(s);}
  function fin(){var p=document.createElement('pre');p.id='MEDIDA';p.textContent=out.join('\n');document.body.appendChild(p);}
  try{
    di('CompressionStream disponible: '+(typeof CompressionStream!=='undefined'));
    if(typeof CompressionStream==='undefined'){di('VEREDICTO: no se puede comprimir'); return fin();}
    nuevaPartida('c1','Tester'); G.miClub='c1'; armarXI();
    var crudo=serializar();
    di('crudo            = '+crudo.length+' caracteres');

    var t0=performance.now();
    var cs=new CompressionStream('deflate-raw');
    var w=cs.writable.getWriter();
    w.write(new TextEncoder().encode(crudo)); w.close();
    new Response(cs.readable).arrayBuffer().then(function(buf){
      var bytes=new Uint8Array(buf);
      di('comprimido       = '+bytes.length+' bytes  ('+(crudo.length/bytes.length).toFixed(1)+'x)');
      /* localStorage guarda cadenas: hay que pasar los bytes a texto. base64 infla un 33%. */
      var s=''; for(var i=0;i<bytes.length;i+=8192) s+=String.fromCharCode.apply(null,bytes.subarray(i,i+8192));
      var b64=btoa(s);
      di('en base64        = '+b64.length+' caracteres');
      di('tiempo comprimir = '+Math.round(performance.now()-t0)+' ms');
      localStorage.clear();
      var cabe=false;
      try{ localStorage.setItem('dinastia_auto',b64); cabe=true; }catch(e){ di('setItem fallo: '+e.name); }
      di('CABE EN localStorage: '+cabe);
      /* Y que la vuelta atras devuelva exactamente lo mismo. */
      var ds=new DecompressionStream('deflate-raw');
      var w2=ds.writable.getWriter();
      var bin=atob(localStorage.getItem('dinastia_auto')||'');
      var u=new Uint8Array(bin.length); for(var k=0;k<bin.length;k++)u[k]=bin.charCodeAt(k);
      w2.write(u); w2.close();
      new Response(ds.readable).arrayBuffer().then(function(b2){
        var vuelta=new TextDecoder().decode(b2);
        di('ida y vuelta identica: '+(vuelta===crudo));
        di('VEREDICTO: '+(cabe&&vuelta===crudo?'LA COMPRESION RESUELVE EL PROBLEMA':'no basta'));
        fin();
      });
    }).catch(function(e){di('fallo comprimiendo: '+e.message);fin();});
  }catch(e){di('EXCEPCION: '+e.message);fin();}
},400);
