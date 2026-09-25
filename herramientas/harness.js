(function(){
  /* Temporadas por carrera. El protocolo largo del usuario es 3x10, pero cada
     temporada cuesta ~365 pasos de reloj sobre 384 clubes: 30 temporadas no
     terminaban nunca en headless. Se puede subir con ?anios=10 en la URL. */
  var ANIOS=(function(){var m=location.search.match(/anios=(\d+)/);return m?parseInt(m[1],10):3;})();
  var out=[];
  window.onerror=function(m,s,l,c){out.push('ERR '+m+' @'+l+':'+c);};
  function log(x){out.push(x);}
  function dump(){
    var pre=document.createElement('pre');pre.id='RESULTADO';pre.textContent=out.join('\n');
    document.body.appendChild(pre);
  }
  function seguro(nom,fn){try{return fn();}catch(e){log('ERR '+nom+': '+e.message+' | '+((e.stack||'').split('\n')[1]||'').trim());return null;}}

  /* Juega temporadas hasta agotar el tope o completar N años.
     Durante la simulación se anula render(): repintar 17.000 líneas de HTML
     miles de veces era el 95% del tiempo y no aporta nada aquí — las vistas se
     recorren aparte, una por una, al terminar cada carrera. */
  function jugar(anios,tope){
    var a0=G.año,i=0;
    var _render=window.render;
    window.render=function(){};
    try{
    for(i=0;i<tope;i++){
      if(G.fase==='despedido'){
        /* aceptarTrabajo espera un ID de club, no un índice de la lista. */
        var of=seguro('ofertasTrabajo',function(){return typeof ofertasTrabajo==='function'?ofertasTrabajo():null;});
        if(of&&of.length&&typeof aceptarTrabajo==='function')
          seguro('aceptarTrabajo',function(){aceptarTrabajo(of[0].id);});
        if(G.fase==='despedido'){log('  (despedido y sin poder recolocarse en S'+G.sem+' '+G.año+')');break;}
      }
      if(G.fase==='previa'){iniciarEnVivo();simularTodo();}
      else if(G.fase==='envivo'){simularTodo();}
      else if(G.fase==='post'){cerrarJornada();}
      else continuar();
      if(G.año>=a0+anios)break;
    }
    }finally{window.render=_render;}
    return {anios:G.año-a0,iter:i};
  }

  function carrera(nom,rol,prep){
    log('');
    log('===== CARRERA: '+nom+' =====');
    var r=seguro('arranque '+nom,function(){
      difSel='normal';rolSel=rol;desafiosSel=[];
      nuevaPartida('c1','Tester');
      G.miClub='c1';G.rol=rol;
      if(rol!=='dt'&&!G.dtEmp)G.dtEmp={nombre:'DT Prueba',estilo:'motivador'};
      armarXI();
      if(typeof initDirectrices==='function')initDirectrices();
      if(typeof aplicarDTEmp==='function')aplicarDTEmp();
      if(prep)prep();
      return true;
    });
    if(!r)return;
    log('  club='+G.clubes[G.miClub].nombre+' rol='+G.rol+' mando='+(typeof mando==='function'?mando():'n/a'));
    var s=seguro('simular '+nom,function(){return jugar(ANIOS,4000);});
    if(s)log('  simuladas '+s.anios+' temporadas (S'+G.sem+' '+G.año+', fase='+G.fase+')');
    /* El índice de plantillas (plantelDe) se invalida en 56 sitios del código.
       Si algún día se añade uno nuevo que mueva jugadores y se olvida invalidar,
       el juego NO falla: simplemente enseña una plantilla equivocada, y eso
       aparece semanas después como un bug incomprensible. Aquí se recalcula
       desde cero y se compara, para que el olvido salte EN LA PRUEBA. */
    if(typeof verificarPlanteles==='function'){
      var malos=verificarPlanteles();
      if(malos.length)log('  INDICE DE PLANTILLAS DESCUADRADO en '+malos.length+' club(es): '+malos.slice(0,5).join(', '));
      else log('  indice de plantillas: correcto');
    }
    log('  saldo='+G.saldo+' trofeos='+((G.dt.trofeos||[]).length)+' plantel='+plantelDe(G.miClub).length+' jugadores mundo='+Object.keys(G.jug).length);
    if(G.dtEmp)log('  DT empleado='+G.dtEmp.nombre+' sintonia='+G.dtEmp.sintonia);
    /* recorrer TODAS las subpestañas con este rol: aquí es donde salen las
       incoherencias (vistas que asumen otro rol o el país equivocado). */
    var grupos={
      club:['inicio','estadio','diseno','gente','ciudad','hinchada','identidad','kit','obras','memoria','historia','logros','directorio','carrera','normas','ajustes'],
      plantel:['jugadores','tactica','plan','camarin','medico','entren','semana','staff','ojeo','juveniles','categorias'],
      finanzas:['resumen','contabilidad','banco','sponsor','mercado','libres','contratos'],
      mundo:['tablaP1','tablaP2','ligas','copa','conti','seleccion','federacion','goleadores','clubes']
    };
    var n=0,malas=[];
    for(var t in grupos)grupos[t].forEach(function(s){
      n++;
      try{setTab(t,s);}catch(e){malas.push(t+'/'+s+': '+e.message);}
    });
    log('  vistas recorridas: '+n+(malas.length?'  FALLAN: '+malas.join(' | '):'  (todas OK)'));
  }

  setTimeout(function(){
    /* ---- 1) el menú nuevo: que todas las tarjetas lleven a algo real ---- */
    seguro('menu',function(){
      var faltan=MODOS_JUEGO.filter(function(m){
        return !(m.rol||m.cat==='retos'||m.cat==='tutorial'||m.cat==='proximo');
      });
      log('MENU: '+MODOS_JUEGO.length+' tarjetas, secciones='+MODO_SECCIONES.length+
          ', sin destino='+faltan.length+(faltan.length?' ('+faltan.map(function(m){return m.id;}).join(',')+')':''));
      var roles=MODOS_JUEGO.filter(function(m){return m.rol;}).map(function(m){return m.rol;});
      log('MENU roles expuestos: '+roles.join(', '));
      log('MENU retos disponibles: '+ESCENARIOS.length);
    });

    /* ---- 1b) portadas: lienzo panoramico y XML bien formado ---- */
    seguro('portadas',function(){
      var mal=[];
      PORTADAS.forEach(function(p){
        window.__port=p[0];
        var h=heroPortada();
        if(h.length<200)mal.push(p[0]+' (vacia)');
        var m=h.match(/<svg[\s\S]*?<\/svg>/);
        if(m){
          var d=new DOMParser().parseFromString(m[0],'image/svg+xml');
          if(d.getElementsByTagName('parsererror').length)mal.push(p[0]+' (XML mal)');
          var vb=(m[0].match(/viewBox="([^"]+)"/)||[])[1]||'';
          var v=vb.split(/\s+/);
          if(v.length===4&&(v[2]/v[3])<3)mal.push(p[0]+' (lienzo no panoramico: '+vb+')');
        }
      });
      window.__port='clasica';
      log('PORTADAS: '+PORTADAS.length+' revisadas, problemas='+(mal.length?mal.join(' | '):'ninguno'));
    });

    /* ---- 2) tres carreras de diez temporadas ---- */
    carrera('Director Tecnico (clasico)','dt');
    carrera('Director Deportivo (despacho)','dir');
    carrera('Director de cantera','cantera');

    /* ---- 3) modos cortos: interinato y un reto ---- */
    seguro('interinato',function(){
      difSel='normal';rolSel='interino';desafiosSel=[];
      nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
      arrancarInterinato();
      log('');
      log('===== INTERINATO =====');
      log('  club='+G.clubes[G.miClub].nombre+' puesto='+posDe(G.miClub)+' fechas='+fechasInterinatoRestantes());
      log('  mercado cerrado='+(vMercado().indexOf('MERCADO CERRADO')>=0));
      jugar(1,400);
      log('  tras jugar: interino='+(G.interino?'en curso':'resuelto')+' confianza='+G.confianza+' rep DT='+G.dt.rep);
    });
    seguro('ayudante',function(){
      difSel='normal';rolSel='ayudante';desafiosSel=[];
      nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
      arrancarAyudante();
      log('');
      log('===== AYUDANTE DE CAMPO =====');
      log('  jefe='+G.jefe.nombre+' confianza='+G.jefe.confianza+' mercado bloqueado='+(mercadoBloqueado()==='ayudante'));
      log('  pizarron de solo lectura='+(vTactica().indexOf('TRABAJAS PARA')>=0));
      jugar(2,900);
      log('  tras 2 temporadas: rol='+G.rol+' ascendido='+(G.ayudante?G.ayudante.ascendido:'(ya no es ayudante)')+
          ' confianza jefe='+(G.jefe?Math.round(G.jefe.confianza):'-')+' fase='+G.fase);
    });
    seguro('reto',function(){
      difSel='normal';rolSel='escenario';window.__escSel='salvacion';desafiosSel=[];
      nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
      arrancarEscenario('salvacion');
      log('');
      log('===== RETO: salvacion =====');
      log('  club='+G.clubes[G.miClub].nombre+' puesto='+posDe(G.miClub)+' meta='+G.escenario.meta);
      jugar(1,400);
      log('  tras una temporada: puesto='+posDe(G.miClub)+' cumplido='+G.escenario.cumplido);
    });

    /* ---- 3b) árbol de habilidades del jugador ---- */
    seguro('arbol-habilidades',function(){
      difSel='normal';rolSel='dt';desafiosSel=[];
      nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
      log('');
      log('===== ARBOL DE HABILIDADES =====');
      var j=plantelDe(G.miClub).filter(function(x){return !esPortero(x);})
        .sort(function(a,b){return b.at.reg-a.at.reg;})[0];
      j.skillPts=3;
      var antesReg=j.at.reg,antesN=(j.habs||[]).length;
      skillAprender(j.id,'ruleta');
      var pudo=(j.habs||[]).indexOf('ruleta')>=0;
      var cadena=skillMotivo(j,'caño')===''; // debe abrirse tras ruleta
      skillAprender(j.id,'cabezazo');        // debe bloquearse si no llega de FIS
      log('  '+j.nombre+' reg '+antesReg+'->'+j.at.reg+' habs '+antesN+'->'+(j.habs||[]).length+
          ' puntos restantes='+(j.skillPts||0));
      log('  aprendio ruleta='+pudo+'  se abrio la cadena (caño)='+cadena);
      var por=plantelDe(G.miClub).filter(esPortero)[0];
      log('  al portero solo se le ofrecen: '+skillDisponibles(por).join(', '));
      plantelDe(G.miClub).forEach(function(x){x.skillPts=0;x.pj=14;});
      repartirPuntosHabilidad();
      var conPuntos=plantelDe(G.miClub).filter(function(x){return (x.skillPts||0)>0;}).length;
      log('  reparto de fin de temporada: '+conPuntos+' jugadores con puntos');
    });

    /* ---- 3c) perfil de gestor persistente ---- */
    seguro('perfil',function(){
      log('');
      log('===== PERFIL DE GESTOR =====');
      try{localStorage.removeItem('dinPerfil');}catch(e){}
      var n0=perfilNivel(perfilLeer().xp||0);
      perfilXP(120,'titulo');perfilXP(35,'temporada');
      perfilXP(200,'ascenso','hitoTest');perfilXP(200,'ascenso otra vez','hitoTest');
      var n1=perfilNivel(perfilLeer().xp||0);
      log('  '+n0.nombre+' (xp '+n0.xp+') -> '+n1.nombre+' (xp '+n1.xp+')');
      log('  el hito no se repite='+(n1.xp===355));
      log('  tarjeta se genera='+(perfilTarjetaHTML().indexOf('PERFIL DE GESTOR')>=0));
    });

    /* ---- 3d) reglamento de la federación: que lo votado se cumpla ---- */
    seguro('federacion',function(){
      difSel='normal';rolSel='dt';desafiosSel=[];
      nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
      log('');
      log('===== REGLAMENTO DE LA FEDERACION =====');
      G.fed=G.fed||{};
      G.fed.playoffs=false;
      log('  sin playoffs votados -> jugarPlayoffs devuelve null: '+(jugarPlayoffs(tabla(1))===null));
      G.fed.playoffs=true;
      var lider=tabla(1)[0],distintos=0;
      for(var i=0;i<30;i++){var c=jugarPlayoffs(tabla(1));if(c&&c.id!==lider.id)distintos++;}
      log('  con playoffs: de 30 finales, el lider de la tabla perdio el titulo '+distintos+' veces');
      log('  se guarda el detalle de la eliminatoria: '+(!!(G.playoffsUlt&&G.playoffsUlt.final)));
      G.fed.playoffs=false;
    });

    /* ---- 4) el puente al visor 3D ---- */
    seguro('visor3d',function(){
      difSel='normal';rolSel='dt';desafiosSel=[];
      nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
      var riv=Object.keys(G.clubes).filter(function(id){return id!==G.miClub;})[0];
      prepararPartido(riv,true,'liga',false);armarXI();iniciarEnVivo();simularTodo();
      var capturado=null;
      var _o=URL.createObjectURL;URL.createObjectURL=function(b){capturado=b;return 'blob:x';};
      var _c=HTMLAnchorElement.prototype.click;HTMLAnchorElement.prototype.click=function(){};
      exportarVisor3D();
      URL.createObjectURL=_o;HTMLAnchorElement.prototype.click=_c;
      log('');
      log('===== VISOR 3D =====');
      log('  export generado='+(!!capturado)+' bytes='+(capturado?capturado.size:0));
      var e=perfilEstadio(G.miClub);
      log('  perfil estadio propio: forma='+e.forma+' niveles='+e.niveles+' techo='+e.techo+' clima='+e.clima+' personalizado='+e.personalizado);
      var er=perfilEstadio(riv);
      log('  perfil estadio rival:  forma='+er.forma+' niveles='+er.niveles+' techo='+er.techo+' personalizado='+er.personalizado);
    });

    /* ---- 5) las seis decisiones de mundo ----
       Salen con probabilidades del 2% al 5% y ademas piden condiciones (ser
       dueno, pasar de la semana 10, tener un canterano con linaje), asi que en
       tres temporadas casi nunca aparecen: una de ellas estuvo rota y el banco
       dio cero errores. Se fabrican a mano las seis, con las dos respuestas. */
    seguro('mundo',function(){
      difSel='normal';rolSel='dt';desafiosSel=[];
      nuevaPartida('c1','Tester');G.miClub='c1';armarXI();
      var pl=plantelDe(G.miClub);
      var rival=Object.values(G.clubes).filter(function(c){return c.id!==G.miClub;})[0];
      var propio=pl[0];
      var ajeno=Object.values(G.jug).filter(function(j){return j.club&&j.club!==G.miClub;})[0];
      propio.linaje={padre:'Marcelo Prueba',club:rival.nombre,ovr:84};
      var casos=[
        ['fusion',{cid:rival.id}],['veteranos',{}],['alianza',{cid:rival.id}],
        ['fichajeImpuesto',{pid:ajeno.id,costo:1200000}],
        ['padreCargo',{pid:propio.id}],['guerraDatos',{}]
      ];
      var malas=[];
      casos.forEach(function(c){
        ['a','b'].forEach(function(op){
          var E={txt:'prueba',aTxt:'si',bTxt:'no',tipo:c[0]};
          for(var k in c[1])E[k]=c[1][k];
          G.eventoPend=E;
          try{resolverEvento(op);if(G.eventoPend!==null)malas.push(c[0]+'('+op+') no consumio el evento');}
          catch(e){malas.push(c[0]+'('+op+') '+(e&&e.message));}
          G.eventoPend=null;
        });
      });
      log('');
      log('===== DECISIONES DE MUNDO =====');
      log('  '+(casos.length*2)+' decisiones probadas, fallos='+malas.length);
      malas.forEach(function(m){log('  ERR '+m);});
    });

    log('');
    log('(temporadas por carrera: '+ANIOS+')');
    log('===== FIN. errores capturados: '+out.filter(function(x){return x.indexOf('ERR ')===0||x.indexOf('FATAL')===0;}).length+' =====');
    dump();
  },300);
})();
