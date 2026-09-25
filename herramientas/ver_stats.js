(function(){
  try{
    nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
    var v=0;while(G.fase!=='previa'&&G.fase!=='envivo'&&v<400){try{avanzarUnDia();}catch(e){}v++;}
    if(G.fase==='previa')iniciarEnVivo();
    var M=G.matchLive;setVel(0);
    for(var i=0;i<62;i++){M.min++;try{simularMinuto();}catch(e){}}
    M.entretiempo=false;
    vista.mvModo='datos';
    render();
    var cards=document.querySelectorAll('#main .card'), panel=null, lista=[];
    for(var k=0;k<cards.length;k++){
      var s=cards[k].querySelector('small');
      var txt=s?s.textContent:'(sin small)';
      lista.push(txt);
      if(txt.indexOf('ESTAD')>=0&&!panel)panel=cards[k];
    }
    if(panel){
      document.body.innerHTML='<div style="width:380px;padding:12px">'+panel.outerHTML+'</div>';
    }else{
      document.body.innerHTML='<pre id="DBG" style="color:#fc6;font:12px monospace">fase='+G.fase+
        ' tarjetas='+cards.length+'\n'+lista.join('\n')+'</pre>';
    }
    document.body.style.margin='0';
  }catch(e){document.body.innerHTML='<pre id="DBG" style="color:#f66">'+e.message+'\n'+e.stack+'</pre>';}
})();
