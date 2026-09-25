setTimeout(async function(){
  var out=[];function di(s){out.push(s);}
  try{
    /* Se simula el camino real: elegir el modo Jeque en el menu y luego un club. */
    modoSandboxJeque=true; rolSel='dt'; difSel='normal';
    nuevaPartida('c1','Tester');
    di('tras nuevaPartida()      saldo = '+G.saldo);
    /* Y ahora lo que hacian elegir()/elegirExt(): pisar el saldo con el del club. */
    var target=Object.values(G.clubes)[3];
    G.miClub=target.id; G.saldo=Math.round(target.saldo*DIF[G.dif].plata);
    di('tras elegir club         saldo = '+G.saldo+'   <-- aqui se perdia');
    arrancarModoEspecial();
    di('tras arrancarModoEspecial saldo = '+G.saldo+'  '+(G.saldo>=999000000?'OK':'MAL'));
    di('marca guardada en la partida: G.jeque = '+G.jeque);

    /* Gastar mucho no debe vaciar la caja. */
    armarXI();
    mov(-800000000,'Fichaje galactico');
    di('');
    di('tras gastar 800 millones  saldo = '+G.saldo+'  '+(G.saldo>=999000000?'OK, se repone':'MAL, se gasta'));

    /* Y tiene que sobrevivir a guardar y volver a cargar. */
    localStorage.clear();
    await guardarAhora();
    var antes=G.saldo;
    G=null; modoSandboxJeque=false;          // como si se recargara la pagina
    await continuarPartida();
    di('');
    di('tras recargar             G.jeque = '+G.jeque+'   esJeque() = '+esJeque());
    mov(-500000000,'Otro fichaje');
    di('y tras gastar de nuevo    saldo = '+G.saldo+'  '+(G.saldo>=999000000?'OK, sigue ilimitado':'MAL, se apago al cargar'));
  }catch(e){di('EXCEPCION: '+e.message+'\n'+e.stack);}
  var p=document.createElement('pre');p.id='MEDIDA';p.textContent=out.join('\n');document.body.appendChild(p);
},400);
