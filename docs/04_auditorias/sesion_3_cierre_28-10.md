# Sesión 3 · cierre del 28-10 (rama `ccr-630aba3a-nnd93p`)

## Qué hice
- **Paraderos y buses «Red»**: paraderos con código/recorridos por sector y luz real de noche; bus con modelo propio (`AutobusModelo`), números de una cara, letrero trasero luminoso, puertas opacas, faros/luces traseras y foco de noche; la gente sube por la puerta de la acera.
- **Gente**: rutinas de peatones por sector y hora (`RutinaPeatones`), maletines y mochilas, pelo del Drive (3 cortes), pasajeros del teleférico por rampa y camino.
- **Ciudad**: pasto y flores (+2 % triángulos), lavado de autos con un auto en bucle y aparcamiento alineado, semáforos peatonales con hombrecito y botón (prueba de fases), rotonda, charcos y lluvia fina (gotas en anillo, suelo y aceras que se oscurecen), tarjeta de transporte (M-182), salas de comercio nuevas.
- **Celebración del título** (`CelebracionTrofeo`) y sillón de oficina.
- Cerradas y borradas del plan: M-168, M-170, M-177, M-182, M-190, M-193. Limpieza: `.uid` huérfano de `ayudante_menu`; test nuevo `p6_cierre_ciudad` (bus, lavado, rampa).

## Capturas a mirar (`docs/04_auditorias/capturas_ciudad_c2/`)
`bus_red_modelo`, `paraderos_de_noche_antes_despues`, `semaforo_peatonal`, `teleferico_gente`, `gasolinera_lavado_aparcamiento`, `charcos_seco` / `charcos_lluvia`, `rotonda_antes_despues`, `pasto_antes_despues`, `flores_antes_despues`, `peatones_suben_bus_antes_despues`.

## FALLOS CONOCIDOS (vistos y no arreglados)
- Los peatones NPC no respetan la fase del semáforo peatonal (la cabeza y la lógica sí).
- La rotonda no tiene tráfico real girando; metro y tren sin librea.
- Los paraderos no tienen luz de acera; los charcos de noche no reflejan las farolas.
- Solo el bus del DT cobra pasaje; el saldo de la tarjeta no sale en la app «Red».
- Al construir la ciudad sale un error de script en `vestidor_q_p2.gd:77` (`vestir_equipacion`, llamado desde `mascota_q.gd`); no es de estos cambios y no lo investigué.
- Charcos en cualquier superficie plana: se colocan a `altura_en` + 0,22 m, así que sobre aceras o césped pueden quedar a otra altura.
- M-180 (metro con vendedores/música) y M-187 (casas con habitantes y horarios) no empezadas: quedan para el lunes.
