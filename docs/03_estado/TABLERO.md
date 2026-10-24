# TABLERO — solo lo abierto (24-10-2026)

Se actualiza cada bloque. Lo terminado SALE de aquí. Catálogo completo: `ESTADO_MEJORAS.md`; 356 ideas: `ideas_pendientes.csv` (regenerar con `python3 herramientas/tablero_ideas.py`).

## A. Dueño (no puedo hacerlo yo)
- [ ] Borrar 8 ramas viejas y etiqueta `latest` (lista en `docs/06_historial/PENDIENTES_hasta_2026-10-24.md` §0.a); más adelante, la rama `respaldo-historia-2026-10-24`.
- [ ] Lunes 26-10: probar Foundry/Azure; abrir red a Wikimedia; `compilar.yml`: ruta y preset ya corregidos (24-10); falta imagen de Godot 4.7 (la 4.3 no abre el proyecto) y cuenta de exportación.
- [ ] Perfil de FPS en hardware real (M-337, P0); builds, keystore, licencias.
- [ ] Subir binarios pesados (`recursos/`, `marca/`, `material/`) al Drive con `herramientas/drive_subir.ps1`.

## B. Siguiente (Cascada: fase 0 real, desde el lunes)
- [ ] Fase 0: separar `Principal` por responsabilidades (MEGAPLAN §7.1) + las 143 funciones > 100 líneas (21 > 200).
- [ ] Reloj único y necesidades (base de la vida en 3D).
- [ ] Traducir las 506 frases pendientes y exigir 0 en la prueba de paridad.
- [ ] Veredicto de `estres_menus.tscn` (no termina en headless).
- [ ] Colisiones de la ciudad fuera del club.
- [ ] Comprimir texturas (3.103 sin comprimir) y reapuntar 38 duplicados exactos.
- [ ] Archivar o borrar 53 escenas de prueba sin mención; quitar 16 `print` sueltos y 37 TODO.

## C. Ideas P0/P1 abiertas (43)

| id | fase | estado | idea |
|---|---|---|---|
| M-337 | dueño | 🔒 DUEÑO | No hay perfil en hardware real (R-01) |
| M-003 | F5 club ampliado / pulido | PENDIENTE | Las formas no varían de forma continua |
| M-004 | F5 club ampliado / pulido | PENDIENTE | El «estadio real» sólo copia forma/niveles/techo/pista/focos/fachada |
| M-005 | F5 club ampliado / pulido | PENDIENTE | Colores propios de butacas en 47 de 176 estadios reales |
| M-014 | F5 club ampliado / pulido | PARCIAL | Sin diferencia día/noche en el aspecto de la iluminación… |
| M-017 | F5 club ampliado / pulido | PENDIENTE | Túnel de vestuario sólo en +Z |
| M-035 | F6 pulido | PARCIAL | Sin bufandas/banderas/camisetas del club en la mano |
| M-054 | F6 pulido | PENDIENTE | Ropa con volumen sólo en retratos (K-02) |
| M-055 | F6 pulido | PARCIAL | Sin arrugas dinámicas según animación |
| M-058 | F6 pulido | PARCIAL | 30 marcas de patrocinio (K-03) |
| M-063 | F6 pulido | PENDIENTE | Escudos reales sólo 26 (7 %) |
| M-068 | F6 pulido | PENDIENTE | Diseño de camiseta por hash en el 63 % de clubes (ya hay tabla… |
| M-079 | F6 pulido | PENDIENTE | Retrato real 13 % (base real) |
| M-091 | F6 pulido | PARCIAL | Botines: variedad añadida, pero sin modelos distintos por forma |
| M-094 | F6 pulido | PARCIAL | Animación de caminata del DT: 6 estilos (✅) |
| M-095 | F6 pulido | PENDIENTE | 335 clips; muchos sin uso en partido |
| M-119 | F6 pulido (motor) | PARCIAL | Penales: el portero «decide una vez» pero sin lectura del lanzador |
| M-147 | F6 pulido (motor) | PARCIAL | Hitbox del balón vs cuerpo: 0 casos atravesando (sonda); pero… |
| M-167 | F3 vida en 3D | PENDIENTE | Calzadas = cajas de asfalto con marcas propias; Kenney sólo… |
| M-171 | F3 vida en 3D | PARCIAL | Tráfico sin comportamiento complejo (adelantar, ceder en cruce) |
| M-207 | F4 personas | PENDIENTE | Plantillas de 25 en todos los clubes (C-05) |
| M-208 | F4 personas | PARCIAL | Caja del club propio crece de forma casi monótona (prueba larga:… |
| M-210 | F4 personas | PARCIAL | Mercado: precios por reputación sin burbujas ni crisis |
| M-219 | F4 personas | PARCIAL | `Banco` e `Insolvencia` existen pero con pocos eventos de gravedad |
| M-235 | F4 personas | PARCIAL | Lesiones: duración y recaídas ok; sin prevención visible (carga… |
| M-241 | F4 personas | PENDIENTE | Prensa 2.541 líneas (la mayor del núcleo): `resolver` 476 líneas |
| M-263 | F3 vida en 3D | PENDIENTE | Eventos únicos (13) y control real; pocos días de «vida» entre… |
| M-277 | F1 entrada al juego | PARCIAL | 274 textos en español directamente en `ui/` (I-02), concentrados… |
| M-278 | F1 entrada al juego | PENDIENTE | `ui/principal.gd` 6.655 líneas (y 3 funciones >330) |
| M-279 | F1 entrada al juego | PENDIENTE | 27 módulos de `visor/` y 8 de `nucleo/` sin referencia directa en… |
| M-280 | F1 entrada al juego | PENDIENTE | 105 módulos de UI/visor sin referencia en banco/pruebas |
| M-338 | F6 pulido (rendimiento) | PARCIAL | Partido ALTO ≈ 2,3 M tris/700 llamadas |
| M-339 | F6 pulido (rendimiento) | PENDIENTE | Césped en capas ≈ 230 k tris/57 llamadas |
| M-341 | dueño | 🔒 DUEÑO | Sombras: 4 cortes en ALTO; sin ahorro medible al bajar (probado),… |
| M-359 | F4 personas | PENDIENTE | Estadio real en 46 % de clubes (C-01) |
| M-403 | F0 cimientos | PARCIAL | 8 módulos de `nucleo/` sin referencia en pruebas:… |
| M-404 | F0 cimientos | PENDIENTE | 27 módulos de `visor/` sin referencia: `Ambience`, `Autopista`,… |
| M-405 | F0 cimientos | PENDIENTE | Pruebas visuales manuales (242 capturas) |
| M-419 | dueño | 🔒 DUEÑO | `.git` 5,5 GB con punteros LFS antiguos (D-03) |
| M-420 | dueño | PENDIENTE | Builds públicos sin datos reales (caras, fotos): comprobar con… |
| M-421 | dueño | 🔒 DUEÑO | Derechos de imagen de jugadores reales (decisión del dueño) |
| M-433 | F1 entrada al juego | PARCIAL | Controles táctiles sólo en la ciudad (cruceta/E) |
| M-447 | F6 pulido | PARCIAL | Las cadenas en español escritas directo en `ui/` (I-02): antes 573… |

Las 302 ideas P2 y 11 P3 están en el CSV, agrupadas por fase (F6 pulido 136, F4 personas 56, F3 vida 42, F1 entrada 36, F0 cimientos 33, F5 club 26).
