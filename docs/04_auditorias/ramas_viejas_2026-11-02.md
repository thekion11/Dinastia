# Ramas viejas: por qué no se unen a `main` (2-11-2026)

Revisión hecha el 2-11 sobre las 100 ramas remotas distintas de `main`. **No se borró ni se tocó ninguna** (regla: irreversible solo con orden explícita; no tocar `borrar-*` ni `respaldo-historia-2026-10-24`).

## Resultado

- **24 ramas ya están dentro de `main`** (0 commits por delante): no hay nada que unir; son borrables sin perder trabajo.
- **76 ramas no comparten historia con `main`**: `main` se reescribió el 24-10 y el 27-10 (se quitaron 530 rutas de capturas e informes, 802 a 682 MiB). Por eso `git` las ve como historia sin relación y no se pueden fusionar: un PR o un merge traería de vuelta cientos de miles de líneas de historia vieja (p. ej. `ccr-76d707c5-dwse9h` difiere de `main` en 4.120 archivos). Su trabajo útil ya se integró en `main` a mano por las sesiones (PR #12, #13, #90-#106); lo que no se integró solo se rescata con cherry-pick de un commit concreto, nunca fusionando la rama.
- **PR #83, #84 y #85** (`inspiring-hamilton-…-rend2/rend3/rend4`) siguen abiertos; `rend2` y `rend4` tienen 0 commits por delante (ya en `main`). Se pueden cerrar sin pérdida.

## Qué decide el dueño

1. Borrar las ramas que ya están en `main` (lista A).
2. Decidir qué hacer con las ramas sin base común (lista B): borrarlas, o dejarlas como archivo. `respaldo-historia-2026-10-24` y las `borrar-*` se conservan hasta su orden.
3. Cerrar los PR #83-#85 y borrar la etiqueta `latest` (`git push origin --delete latest`).
4. Si en una rama de la lista B falta algo, pedir el cherry-pick del commit concreto (no fusionar la rama).

## Lista A: ya en `main` (0 por delante)

Ojo: incluye ramas recientes de las sesiones del 2-11 (`ccr-2b01929a-qdnwp5`, `ccr-fallos-crear-partida`, `ccr-120fps-optimizar`, `ccr-1749cbc2-dmhp94*`, `ccr-2625acd2-02al7q`, `m476-*`, `claude/coordination-active-sessions-eyjhfl`): se pueden borrar cuando se archiven esas sesiones.

- `ccr-120fps-optimizar`
- `ccr-1749cbc2-dmhp94`
- `ccr-1749cbc2-dmhp94-docs`
- `ccr-1749cbc2-dmhp94-flaky`
- `ccr-1749cbc2-dmhp94-ideas`
- `ccr-1749cbc2-dmhp94-prologo`
- `ccr-2625acd2-02al7q`
- `ccr-2b01929a-qdnwp5`
- `ccr-630aba3a-nnd93p`
- `ccr-fallos-crear-partida`
- `claude/coordination-active-sessions-eyjhfl`
- `claude/dazzling-rubin-v7rfyi`
- `claude/happy-carson-qao1ph`
- `claude/inspiring-hamilton-667tns-caras`
- `claude/inspiring-hamilton-667tns-ciclo`
- `claude/inspiring-hamilton-667tns-escudos5`
- `claude/inspiring-hamilton-667tns-rend2`
- `claude/inspiring-hamilton-667tns-rend3`
- `claude/inspiring-hamilton-667tns-rend4`
- `claude/segunda-sesion-guion`
- `claude/segunda-sesion-guion-2`
- `m476-estado-plan`
- `m476-fundir-pruebas-y-datos`
- `m476-pasajeros-y-medidas`

## Lista B: sin historia común con `main` (commits propios entre paréntesis)

- `ccr-76d707c5-dwse9h` (794)
- `ccr-76d707c5-dwse9h-respaldo-wip` (748)
- `ccr-a64d04fd-r5uoai` (164)
- `claude/inspiring-hamilton-667tns` (167)
- `claude/inspiring-hamilton-667tns-amarillas` (504)
- `claude/inspiring-hamilton-667tns-auto` (453)
- `claude/inspiring-hamilton-667tns-banco` (405)
- `claude/inspiring-hamilton-667tns-bus` (453)
- `claude/inspiring-hamilton-667tns-caja-tienda` (407)
- `claude/inspiring-hamilton-667tns-cajero` (376)
- `claude/inspiring-hamilton-667tns-canchapatos` (446)
- `claude/inspiring-hamilton-667tns-cartera` (357)
- `claude/inspiring-hamilton-667tns-cartera-movil` (374)
- `claude/inspiring-hamilton-667tns-clubes` (583)
- `claude/inspiring-hamilton-667tns-comida` (324)
- `claude/inspiring-hamilton-667tns-crisis` (543)
- `claude/inspiring-hamilton-667tns-crisis2` (560)
- `claude/inspiring-hamilton-667tns-diseno-pagos` (351)
- `claude/inspiring-hamilton-667tns-escudos2` (597)
- `claude/inspiring-hamilton-667tns-escudos3` (597)
- `claude/inspiring-hamilton-667tns-escudos4` (636)
- `claude/inspiring-hamilton-667tns-estacion-fachada` (418)
- `claude/inspiring-hamilton-667tns-expendedora` (378)
- `claude/inspiring-hamilton-667tns-expendedoras2` (404)
- `claude/inspiring-hamilton-667tns-fachadas` (322)
- `claude/inspiring-hamilton-667tns-gasolinera` (262)
- `claude/inspiring-hamilton-667tns-incidentes` (498)
- `claude/inspiring-hamilton-667tns-interiores` (433)
- `claude/inspiring-hamilton-667tns-leyenda` (526)
- `claude/inspiring-hamilton-667tns-m199` (539)
- `claude/inspiring-hamilton-667tns-museo` (266)
- `claude/inspiring-hamilton-667tns-obra` (327)
- `claude/inspiring-hamilton-667tns-oeste` (326)
- `claude/inspiring-hamilton-667tns-oficina` (446)
- `claude/inspiring-hamilton-667tns-palmares` (604)
- `claude/inspiring-hamilton-667tns-palmares2` (613)
- `claude/inspiring-hamilton-667tns-palmares3` (621)
- `claude/inspiring-hamilton-667tns-parque` (424)
- `claude/inspiring-hamilton-667tns-pasajeros` (472)
- `claude/inspiring-hamilton-667tns-pasonivel` (478)
- `claude/inspiring-hamilton-667tns-peluches` (491)
- `claude/inspiring-hamilton-667tns-peluches-texto` (503)
- `claude/inspiring-hamilton-667tns-penales` (446)
- `claude/inspiring-hamilton-667tns-portico` (323)
- `claude/inspiring-hamilton-667tns-portico2` (325)
- `claude/inspiring-hamilton-667tns-precontratos` (526)
- `claude/inspiring-hamilton-667tns-presets` (552)
- `claude/inspiring-hamilton-667tns-presupuesto` (615)
- `claude/inspiring-hamilton-667tns-presupuesto2` (630)
- `claude/inspiring-hamilton-667tns-rebajas` (641)
- `claude/inspiring-hamilton-667tns-regalos` (220)
- `claude/inspiring-hamilton-667tns-relleno` (241)
- `claude/inspiring-hamilton-667tns-relleno2` (267)
- `claude/inspiring-hamilton-667tns-relleno3` (310)
- `claude/inspiring-hamilton-667tns-relleno4` (324)
- `claude/inspiring-hamilton-667tns-rend1` (656)
- `claude/inspiring-hamilton-667tns-ribera2` (250)
- `claude/inspiring-hamilton-667tns-sin-dinero` (511)
- `claude/inspiring-hamilton-667tns-sin-red` (517)
- `claude/inspiring-hamilton-667tns-sirenas` (515)
- `claude/inspiring-hamilton-667tns-surtidor` (367)
- `claude/inspiring-hamilton-667tns-tactil` (578)
- `claude/inspiring-hamilton-667tns-tactil2` (607)
- `claude/inspiring-hamilton-667tns-tareas` (218)
- `claude/inspiring-hamilton-667tns-tele` (455)
- `claude/inspiring-hamilton-667tns-televisual` (476)
- `claude/inspiring-hamilton-667tns-tienda` (372)
- `claude/inspiring-hamilton-667tns-tiron` (548)
- `claude/inspiring-hamilton-667tns-tren` (455)
- `claude/inspiring-hamilton-667tns-trinchera` (493)
- `claude/inspiring-hamilton-667tns-trofeos` (596)
- `claude/inspiring-hamilton-667tns-tutorial` (576)
- `claude/inspiring-hamilton-667tns-via` (473)
- `claude/inspiring-hamilton-667tns-viajeros` (482)
- `claude/segunda-sesion-comparacion` (197)
- `respaldo-historia-2026-10-24` (672)
