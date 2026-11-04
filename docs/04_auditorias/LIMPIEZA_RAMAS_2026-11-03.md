# Limpieza de ramas (3-11-2026, pedido del dueño)

Auditoría: para cada rama remota se probó si unirla a `claude/dazzling-rubin-v7rfyi` cambia algo (`git merge-tree`).
Si el árbol resultante es idéntico, todo su contenido ya está en la rama de trabajo. Los commits siguen recuperables por su SHA.

## Se conservan
- `main`, `claude/dazzling-rubin-v7rfyi` (líder, PR #120), `ccr-630aba3a-nnd93p` (sesión de ciudad, activa), `claude/inspiring-hamilton-667tns` (ejecutora).
- `ccr-454350d9-9chain` y su PR #128: experimento personal del dueño (no se toca).
- `respaldo-historia-2026-10-24` (regla de CLAUDE.md).

## DECISIÓN DEL DUEÑO (3-11): borrar las 117
Desde el contenedor GitHub rechaza borrar ramas (solo deja subir a la rama propia): se borran con
`herramientas/limpiar_github.ps1` en el PC del dueño (y con `-Fallidas`, las ejecuciones fallidas del CI).

- `ccr-76d707c5-dwse9h` y `ccr-76d707c5-dwse9h-respaldo-wip` (historia de antes del 24-10): verificado que no se pierde nada. La carpeta
  «Escudos especiales» (111 imágenes) ya está en `material/escudos_especiales_originales` (se movió el 24-10); los otros 42 archivos que
  solo tiene su punta son pruebas y scripts de antes del 26-10 sustituidos después.

## Con contenido propio ya superado
- `ccr-a64d04fd-r5uoai` (6d600ea3): Cierre 26-10: estado de ramas y pendientes de las sesiones
- `claude/inspiring-hamilton-667tns-escudos2` (77e81092): Escudos: biblioteca de figuras y letras vectoriales (en curso)
- `claude/inspiring-hamilton-667tns-presupuesto` (0ae56070): Presupuesto del partido: API de estadísticas de dibujo corregida
- `claude/inspiring-hamilton-667tns-rend3` (5f3cbeb1): Rendimiento §3: medido el repintado de la semana (el escudo cuesta 0,2 ms) y _probar_motor_libre; documentado
- `claude/inspiring-hamilton-667tns-tactil` (c21c8533): Escena de la prueba tac_controles y archivos .uid
- `claude/segunda-sesion-comparacion` (c30a8a60): Plan: M-475, comparación visual main ↔ rama optimizada (todo igual salvo los remates de azotea del horizont
  (borradores «en curso» de piezas que ya existen terminadas en la rama de trabajo; `ccr-a64d04fd-r5uoai` trae solo un estado de cierre del 26-10, superado)

## Totalmente unidas: 109 ramas (propuesta: borrar)

```
ccr-120fps-optimizar cfa994b37b3462576f3eabe8211094a2add9b3ee
ccr-1749cbc2-dmhp94 3d6bf4a61567bf27bc29e2ec4743287efabed1e9
ccr-1749cbc2-dmhp94-docs 171ca3543ae03ec55ce8b9826efd0bcb823c2f89
ccr-1749cbc2-dmhp94-flaky 5b056ce71c779d821de0ee60e7b7ad2346da09f9
ccr-1749cbc2-dmhp94-ideas 430736153c31661372b3b8d281c07f86b7062db5
ccr-1749cbc2-dmhp94-prologo c581077768a04deefd91418592bbc1072dfeb118
ccr-2625acd2-02al7q 0f60c0f9308cc65523444cd134463377a6b29d87
ccr-2b01929a-qdnwp5 27c42d5eb180b784507c12c8c8c1190844d08793
ccr-fallos-crear-partida 3c714613725d6c3e3ae766d3daea00883450d452
claude/coordination-active-sessions-eyjhfl 7e82c922c101174ed3d04099c8b4869d474a6106
claude/happy-carson-qao1ph a10241f90ba0cad7c82a3af57b24255ac5cae7ee
claude/inspiring-hamilton-667tns-amarillas 11481073691202374fe02df08cf8334676d04d8f
claude/inspiring-hamilton-667tns-arena 5ed550527fd720bf42ff5b21d5935d2e8c94161b
claude/inspiring-hamilton-667tns-auto 9ef11a0748abccd1eacf1073a637ef81697a190d
claude/inspiring-hamilton-667tns-balance 4ca374b4436ab99314641066b57289eb73449692
claude/inspiring-hamilton-667tns-banco 86006ab81372011a0c11028237a885e008bb2ce5
claude/inspiring-hamilton-667tns-bus b29fa0c7896ccf9c0502421259ea17dadab177b2
claude/inspiring-hamilton-667tns-caja-tienda dd2ca88e7d1c53cf163128620329eb9a1d744560
claude/inspiring-hamilton-667tns-cajero c30356d4ba98cd8d343ab5bd68a594c9b79b093f
claude/inspiring-hamilton-667tns-canchapatos f4b065a04fc1543403fe7c41920d12bd9ee25ac8
claude/inspiring-hamilton-667tns-caras deda33cb6373669430b82ef0103a34cf279b1cf5
claude/inspiring-hamilton-667tns-cartera aa1e4915e5154d91764703b235525bfcf8000843
claude/inspiring-hamilton-667tns-cartera-movil 70343f6201e5ea95512b2efe7229f3cadd9e9096
claude/inspiring-hamilton-667tns-ceremonia 4fc4b5ff17cc4a260119647fed16f442966f7552
claude/inspiring-hamilton-667tns-ciclo 2847dca8598ade88d1e7429e6faee63ff7a5f0e1
claude/inspiring-hamilton-667tns-clubes 4dff34e5da626c519a060a4d767b0ddf8c3a1d5e
claude/inspiring-hamilton-667tns-comida 1fa21f4b2b41a4d4ad9bb4cc5ddd3a368100f1a7
claude/inspiring-hamilton-667tns-crisis 4be0b49122256912e5a27a94c6d567c4d43437e8
claude/inspiring-hamilton-667tns-crisis2 73af15623db09bb4eb615bf53c198016b1e45704
claude/inspiring-hamilton-667tns-diseno-pagos dab494e1ee5af3f4d4260b387b1435c7cda66857
claude/inspiring-hamilton-667tns-dispositivo 006052093f09e3d9a7948fee557a1ed3f0040fcf
claude/inspiring-hamilton-667tns-escudos3 26243b0806d9b8e190fcb4b5db7c384d321b9aee
claude/inspiring-hamilton-667tns-escudos4 9d9a337cf8d7c9c64d88758bb501c0d6846776ba
claude/inspiring-hamilton-667tns-escudos5 147c3d4e41e4fbebb64fd64e86731bfcca2ad02a
claude/inspiring-hamilton-667tns-estacion-fachada 14870b315c905f8fdd134d8d5850439c5fb3fcd2
claude/inspiring-hamilton-667tns-expendedora e0517c719fb2c706c4c2a4b2bc9cf84f1357406e
claude/inspiring-hamilton-667tns-expendedoras2 47cb9f37cb6814d9546a36472094f2dccb6c71b2
claude/inspiring-hamilton-667tns-fachadas 75d55152564fa1e8e631c799c331e95fd4c06107
claude/inspiring-hamilton-667tns-filas af3bbce4cf13e8da5b126016edaf560b5aabafeb
claude/inspiring-hamilton-667tns-fisica ea551f00dc082307608021524f00373356404023
claude/inspiring-hamilton-667tns-foto c4c8ac1a39eae1f32ed4b5a0c5d9b93183f1fccd
claude/inspiring-hamilton-667tns-gasolinera 4e5c2fa5dadf2dc79733474ae36159977f3e6409
claude/inspiring-hamilton-667tns-incidentes 9cd8efbd75221811a6a25feeb9a32d4990ea6333
claude/inspiring-hamilton-667tns-interiores 1a0daa6c4ffbfd41ce14970c9a3ea3d4c1ce9344
claude/inspiring-hamilton-667tns-interp 8c6d11774f4c991dcacb04b0aa6cafd0d0afef5a
claude/inspiring-hamilton-667tns-leyenda a2ad709553b364680aff65e10da735cb8ae69d32
claude/inspiring-hamilton-667tns-m199 02289645181c2e8bf5e5063b61295d7c6e11d04f
claude/inspiring-hamilton-667tns-m386 de77b2f766f1c986fc61677b0a386f454d0a8568
claude/inspiring-hamilton-667tns-m391 0f6b715a279d5e63477e0a93e1304cc82aa17af7
claude/inspiring-hamilton-667tns-museo 75c6daf9d186bc8239f315d9d18df918a65692dd
claude/inspiring-hamilton-667tns-obra 9e188f6a090b0d5a0167e29ca7b1b6165c87caef
claude/inspiring-hamilton-667tns-oeste f8cb9f0f4168a86f745ddea2f29c8f0fe56bf9bc
claude/inspiring-hamilton-667tns-oficina 0e1e94eead87f903c38f208d5519e32e972717f8
claude/inspiring-hamilton-667tns-p2 5893de616d57e27372eef0fab71deb9564c7e71c
claude/inspiring-hamilton-667tns-p3 4ecec51bbe6007ec7b6f572f756f41c4d050a51f
claude/inspiring-hamilton-667tns-p4 53f542af4c45fc92526f96c8798333c693ea00f0
claude/inspiring-hamilton-667tns-palmares 4d7bf4d3f6ef7ba754d63dff6377b99b322e74b8
claude/inspiring-hamilton-667tns-palmares2 b8caefe14c5339150c6b332b880abbe94ad86a53
claude/inspiring-hamilton-667tns-palmares3 0948463fbbdcddc7f7a08adcf56f1b7bdf22b27d
claude/inspiring-hamilton-667tns-parque 6ce1940339cecec5f25c33305e01d62e04388b15
claude/inspiring-hamilton-667tns-pasajeros 28c5d0f5e83fdc359feab7e3367ecdf51e9439a0
claude/inspiring-hamilton-667tns-pasonivel 9206f87acd28103ae2543730fca319057dadb177
claude/inspiring-hamilton-667tns-peluches a7e5da8ff8a7abcff2a9a59b98fca96e68ab7277
claude/inspiring-hamilton-667tns-peluches-texto 73e65244ad81f47de26b3967d56bd226fe4fd78d
claude/inspiring-hamilton-667tns-penales 97eb2e59e316e0e67c5c06884876fcec3805551a
claude/inspiring-hamilton-667tns-pin 5c2b79f9b564581403d49c87992aa71aa0759b4e
claude/inspiring-hamilton-667tns-plantel 9de53f64a27a9cf190dc58b806648f387fd448b8
claude/inspiring-hamilton-667tns-portico dab5d1aca625b327ac1057db980d003bc49ac451
claude/inspiring-hamilton-667tns-portico2 f78e05177884a9edc5c86995cd50bf8f6d3750ff
claude/inspiring-hamilton-667tns-precontratos d4b70570d9a5e732a43f1589da06257c251ca29c
claude/inspiring-hamilton-667tns-presets 13024fb3404b7928141f5f24a13879ce0b222e24
claude/inspiring-hamilton-667tns-presupuesto2 1a9580d283dc2a6ca278c438802621b5f8830f70
claude/inspiring-hamilton-667tns-r2 f0d9363cf7e3191969dc6b89e58f14864b7b0280
claude/inspiring-hamilton-667tns-r5 fde2e8cb121d622ec4750dcb4ec04ca6b84123d3
claude/inspiring-hamilton-667tns-r7 25cf1458b4df8de55c98c7d88a85316e0305fe1c
claude/inspiring-hamilton-667tns-rebajas c0eaf5e6e2709ba881a9e9d17f5b137fb545d4a9
claude/inspiring-hamilton-667tns-regalos 4b18ecd68437b9417637940e5a55ae212de5966d
claude/inspiring-hamilton-667tns-relleno 68a111cfe3392c7827a7daa5711d323178b75a7d
claude/inspiring-hamilton-667tns-relleno2 e6f5aa2687734eb48bfd5ef6bc767b844623792f
claude/inspiring-hamilton-667tns-relleno3 e20c17302d574896512dde8446c1c71d2342ddcb
claude/inspiring-hamilton-667tns-relleno4 05b43c6228e3355d2a44d0169c5d5c57b127a7c5
claude/inspiring-hamilton-667tns-rend1 45a449b2ab2d01d362c3c4effb9e62e234cddfbd
claude/inspiring-hamilton-667tns-rend2 1e72100bd97fb3e66e03a8132aeb9ad096f78b9f
claude/inspiring-hamilton-667tns-rend4 919746360ed0ac686839cae1da7f3d556debbaf3
claude/inspiring-hamilton-667tns-ribera2 2ae4525048668a1cd2fd88819b77a3a51311402c
claude/inspiring-hamilton-667tns-sin-dinero 1b6cfd6cad66c6a2b2cab65b2d071691895a8297
claude/inspiring-hamilton-667tns-sin-red bb0ebb485073c84424a0e6b62cb947ef2876a180
claude/inspiring-hamilton-667tns-sirenas ee683577046811e9f253a3d60fbf03fb41e9a3cb
claude/inspiring-hamilton-667tns-sonda-penales 54ceca7cadf7060a0c477ca8a24b69c76149367c
claude/inspiring-hamilton-667tns-surtidor ca1a377c9e3a43ac8e49eb66498b4218a5b4cd0f
claude/inspiring-hamilton-667tns-tactil2 cae69eda8b7a565e1f00b695f0e82c13f8329672
claude/inspiring-hamilton-667tns-tareas d268bd20fa5f6c4a4bc007dc89fdbb56b2a8ed66
claude/inspiring-hamilton-667tns-tele 1270c1cc40f0631b455b8bf9aa1cd5d56e76fbf0
claude/inspiring-hamilton-667tns-televisual 8bb032dc111221647a4ebd4e653b9924514561c1
claude/inspiring-hamilton-667tns-tienda 01bca5f259980885463d33c06a50ff0cf7c31f6b
claude/inspiring-hamilton-667tns-tiron 1b72d3bb511c470c06320a7494bf45ce25493e3f
claude/inspiring-hamilton-667tns-tren 2d299f4bd3d8bcaa025f4dd513ece4b67a861880
claude/inspiring-hamilton-667tns-trinchera 50c7013fb7eb993df9512c455ec82c1ca9aa2512
claude/inspiring-hamilton-667tns-trofeos d87441cfd9654a0cd380bb8606dda288eaeca11a
claude/inspiring-hamilton-667tns-tutorial ecea12eddf5738f2a6af24e287a86bbd957b2ae2
claude/inspiring-hamilton-667tns-via f8da8b7238d7005f9f57b9aea86240ff59bdb769
claude/inspiring-hamilton-667tns-viaje 24d10e778c1316591a44c62809dabbfc0c04c1e2
claude/inspiring-hamilton-667tns-viajeros b83b6153d93a303b3a91e1269766221b76bfe3fc
claude/inspiring-hamilton-667tns-vram a676f8a60e1e4928dac40e47ac9af8c911a0a7d2
claude/segunda-sesion-guion 5004bc2f9bed1af2e5ddca5d4901ad693be865ef
claude/segunda-sesion-guion-2 8b7916b64fe1f572c0d2d2e96b146f21a626a963
m476-estado-plan 24e7ebd0f7d1f7fc792a378512147819d5441638
m476-fundir-pruebas-y-datos fe927f9a7bd35c9bd5ebc3c3ffc2fba6f88e780d
m476-pasajeros-y-medidas 11cfa835e7fcbd1b78c5dd7af8a8cf818ff1e24c
```
