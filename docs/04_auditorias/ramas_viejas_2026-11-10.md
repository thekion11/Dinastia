# Ramas viejas: cuáles se pueden borrar (10-11-2026)

El dueño DIO PERMISO para borrarlas (orden 36). Desde el contenedor de las sesiones GitHub RECHAZA el borrado (error 403 del proxy de git): **las borra el dueño** en GitHub → pestaña *Branches* (icono de papelera), o con `git push origin --delete <rama>` desde su PC.

Método: `git cherry origin/main origin/<rama>` compara cada commit de la rama con los de `main` por su CONTENIDO (el parche), no por el identificador, porque `main` se reescribió y los identificadores ya no coinciden. Si ningún commit queda sin equivalente, todo el trabajo de la rama ya está en `main`.

Nunca se tocan: `main`, `respaldo-*` (incluida `respaldo-historia-2026-10-24` y los `respaldo-main-*`), `borrar-*`, `entregas/`, la rama de trabajo del líder y las de las sesiones activas al cierre.

## Lista A — ya son parte de `main` (ancestros directos): BORRABLES (19)
- `arreglos-especiales`
- `arreglos-especiales-2`
- `caras-modelo`
- `escudos-93`
- `escudos-figuras`
- `escudos-realistas`
- `escudos-resto`
- `especiales-datos`
- `especiales-motor`
- `legible-baja`
- `museo-lod`
- `presupuesto-cabeza`
- `prueba-cara-pais`
- `sesion3-estadios-2`
- `sesion3-estadios-3`
- `sesion7-club`
- `uniformes-3d`
- `uniformes-caras`
- `uniformes-legible`

## Lista B — todos sus commits tienen equivalente en `main`: BORRABLES (49)
- `ccr-454350d9-9chain`
- `ccr-630aba3a-nnd93p`
- `ccr-a55b5f7a-qxnert`
- `ccr-bda53eb8-4ss3b7`
- `ccr-da27fb86-i59x88`
- `claude/dazzling-rubin-v7rfyi`
- `claude/inspiring-hamilton-667tns`
- `claude/inspiring-hamilton-667tns-actualizador`
- `claude/inspiring-hamilton-667tns-ajustes`
- `claude/inspiring-hamilton-667tns-atajos`
- `claude/inspiring-hamilton-667tns-auditoria4`
- `claude/inspiring-hamilton-667tns-ayuda`
- `claude/inspiring-hamilton-667tns-bancos`
- `claude/inspiring-hamilton-667tns-chicos`
- `claude/inspiring-hamilton-667tns-codigos`
- `claude/inspiring-hamilton-667tns-fotos`
- `claude/inspiring-hamilton-667tns-goles`
- `claude/inspiring-hamilton-667tns-guardado`
- `claude/inspiring-hamilton-667tns-local`
- `claude/inspiring-hamilton-667tns-memoria`
- `claude/inspiring-hamilton-667tns-menus`
- `claude/inspiring-hamilton-667tns-nomina`
- `claude/inspiring-hamilton-667tns-once`
- `claude/inspiring-hamilton-667tns-pais`
- `claude/inspiring-hamilton-667tns-penales`
- `claude/inspiring-hamilton-667tns-presu`
- `claude/inspiring-hamilton-667tns-pulido`
- `claude/inspiring-hamilton-667tns-r2`
- `claude/inspiring-hamilton-667tns-ruido1`
- `claude/inspiring-hamilton-667tns-ruido2`
- `claude/inspiring-hamilton-667tns-sem`
- `claude/inspiring-hamilton-667tns-sim`
- `claude/inspiring-hamilton-667tns-stats`
- `claude/inspiring-hamilton-667tns-tactil`
- `claude/inspiring-hamilton-667tns-tarjetas`
- `claude/inspiring-hamilton-667tns-telefono`
- `claude/inspiring-hamilton-667tns-ui`
- `pulido/codigo2`
- `pulido/ram2`
- `sesion2-caza-fallos`
- `sesion3-celebraciones`
- `sesion3-festejos3d`
- `sesion3-festejos3d-2`
- `sesion3-festejos3d-3`
- `sesion3-repaso`
- `sesion4-motor-league`
- `sesion4-motor-league-v2`
- `sonar/ciclo3`
- `sonar/regla`

## Lista C — tienen commits SIN equivalente en `main`: NO borrar sin revisar (37; entre paréntesis, cuántos)
Pueden ser commits de unión (merge), arreglos que luego se rehicieron de otra forma o trabajo de verdad perdido. Hay que mirarlos uno por uno (`git cherry -v origin/main origin/<rama>`) antes de decidir.
- `ccr-e3f86f68-8dnizh` (2)
- `claude/godot-performance-benchmark-ci-7e0dcs` (1)
- `claude/inspiring-hamilton-667tns-guia` (1)
- `pulido/carga` (7)
- `pulido/ciudad` (2)
- `pulido/ciudad2` (2)
- `pulido/ciudad3` (6)
- `pulido/codigo` (2)
- `pulido/fallos` (4)
- `pulido/fallos_7_11` (3)
- `pulido/integracion` (38)
- `pulido/lista_a_pie` (1)
- `pulido/llamadas` (3)
- `pulido/nativo_obstaculos` (3)
- `pulido/ram` (13)
- `pulido/ram3` (3)
- `pulido/sin_aerea` (3)
- `pulido/texturas_hilo` (9)
- `sesion3-estadios` (1)
- `sesion3-fin-temporada` (1)
- `sesion3-fin-temporada-2` (1)
- `sesion3-rueda-prensa` (2)
- `sonar/bancos` (19)
- `sonar/bancos2` (7)
- `sonar/bancos3` (5)
- `sonar/bancos4` (13)
- `sonar/ciclo2` (3)
- `sonar/ciclo4` (2)
- `sonar/consejos` (3)
- `sonar/correcciones` (9)
- `sonar/plan8h` (1)
- `sonar/plataformas` (17)
- `sonar/plataformas2` (14)
- `sonar/plataformas3` (23)
- `sonar/rendimiento` (9)
- `sonar/rendimiento2` (1)
- `sonar/sin_3d` (6)

La etiqueta `latest` sigue en el repositorio (pendiente del dueño desde el 24-10).
