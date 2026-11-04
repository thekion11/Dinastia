# Revisión visual de la ciudad del 3-11 (Forward+, cámaras colocadas a mano)
Forward+ con lavapipe (`apt-get install mesa-vulkan-drivers`; `--rendering-driver vulkan`), 960×540 (las de «tanda1» a 960×540), hora 13:00, en MÍNIMO y en MEDIO. Script: `pruebas/captura_revision_ciudad.gd` (`NIVEL=minimo|medio`, `SOLO=a,b`).
Carpetas: `tanda1/` (primera pasada, todas las tomas, ya con los carteles de banco/tienda bajados), `despues/` (carteles ajustados), `hoja_contacto_*.jpg`, `oclusion_*.jpg` (estadio: con entorno / sin entorno / diferencia ×4).

## Lo que se veía mal y se arregló (pequeño y claro)
1. **Carteles de banco y tienda deportiva tapados por la viga de los soportales** (se leía «TIENDA DEP…»): bajados 1 m (y 3,35 sobre el suelo), letra 30 → 22 y el de la tienda dice «DEPORTES» (cabe en el panel y entre columnas).
2. **Carteles de lugares** (Karting, parque, atracciones, puerto, puente…) diminutos a 30-40 m: letra ×4 (antes ×1) y alcance ~170 m. Karting ya se lee a 30 m (`despues/rev_medio_c_karting`).
3. **Oclusión del entorno del estadio en MÍNIMO: HUECO REAL.** Desde la cámara de TV y la «Tribuna alta» desaparecía el horizonte de edificios lejanos que asoma sobre las gradas (`oclusion_5.jpg`, centro vs izquierda). Ahora el horizonte (grupo `sin_agrupar`) no se oculta nunca (`oclusion_5b.jpg`: solo difieren jugadores y público en movimiento).
   Coste: el partido TV en MÍNIMO pasa de 336 a 505 llamadas (esos 64 edificios cuestan ~170). Fundirlos en pocas mallas (`FundirPiezas.fundir_profundo`) no ahorró nada y subió los triángulos: revertido. DECISIÓN pendiente: aspecto correcto (505) o horizonte recortado (336).

## Comprobado y bien
- Ropero puesto en el DT de la ciudad (gorra, bufanda y polo con los colores del club) y a pie en la plaza (`tanda1/rev_*_plaza_tienda_pie`, `*_dt_ropero`).
- Rincón deportivo de la casa (balones junto a la cama, maniquí con la camiseta, botines): `tanda1/rev_minimo_casa_rincon`.
- Carteles del parque (Jardines del Mirador), parque de atracciones, montaña rusa, puente, puerto, VIP, gasolinera («Gasolina»), Autopista y lavado: presentes y legibles de cerca; las etiquetas del mapa no aparecen a pie.
- MÍNIMO y MEDIO salen iguales en los carteles; la diferencia es solo de sombras y resolución.

## Pendiente / no concluyente
- **Peaje y metro**: la toma del peaje (`c_peaje`) y las del metro no se obtuvieron en esta pasada (el proceso se pasó de tiempo en la primera tanda); el peaje y el metro tienen su captura propia anterior (`captura_peaje`, `captura_metro_usable`), revisadas el mismo día en opengl3, no en Forward+.
- **Casa Grande y lavado**: las dos tomas salen con la cámara dentro de geometría (agua / techo): es de la colocación manual del script, no del juego; sin revisar.
- Carteles de banco y tienda: desde algunos ángulos una columna del soportal tapa la mitad del texto (es la arquitectura: hay que colocarse delante).
- Las diferencias de oclusión en las cámaras 0, 2, 3, 4 y 10 (≈99 %) son movimiento de la propia cámara entre las dos tomas, no un hueco.
