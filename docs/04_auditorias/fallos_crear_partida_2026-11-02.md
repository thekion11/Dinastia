# Fallos de «crear personaje / crear partida» (informe del dueño, 2-11-2026, Windows)

Rama `ccr-fallos-crear-partida`. Prueba: `pruebas/ideas/fcp_crear_partida` (banco de ideas); capturas con clics reales: `pruebas/fcp_captura.tscn` (`QUE=personaje|equipacion`).

| # | Fallo | Estado |
|---|---|---|
| 1 | «Tras elegir un modelo de personaje no deja elegir otro» → el dueño aclara: es el MODELO BASE 3D (hoy solo Hombre/Mujer Quaternius). Quiere como opciones básicas: «Modular Character Outfits», los del Drive, Kenney `characterMedium` y MakeHuman | PENDIENTE (ver abajo) |
| 2 | Pantalla gris con «…a primera persona.» al confirmar | Es `PantallaCarga` del prólogo (`visor/prologo.gd` construye la ciudad bloqueando el hilo). Lo lleva la sesión del prólogo |
| 3 | Mascotas: cola flotando | ARREGLADO: la cola sigue a la pelvis (`visor/mascota_q.gd`, `ColaSoporte`). «Feas»: pendiente |
| 4 | Escudo propio no sale en el uniforme | ARREGLADO en la camiseta 2D (`DisenosKit.textura_completa` dibuja `escudo_tex` de frente). Los SÍMBOLOS del escudo tampoco salían donde no hay etiqueta encima (el rasterizador SVG no dibuja `<text>`): nuevo `ui/escudo_texto.gd` los hornea en la imagen (vista previa de configuración, camiseta, carga, resumen) |
| 7 | El jugador 3D del diseñador no cambiaba de uniforme ni de botines tras el primer vestido | ARREGLADO en `VestidorQ.vestir_equipacion`: tras vestir, el material activo del cuerpo ya era el del shader y no se reconocía; ahora se busca por el material de la malla. Afectaba a cualquier re-vestido |
| 8 | Pantalla de carga gris y pobre | REHECHA: fondo con el color del club y franjas, anillo con balón, barra, consejo que rota (18 consejos, 9 idiomas); `PantallaCarga.dejar_pintar` espera al dibujo real antes de bloquear |
| 5 | «Uniforme» debe ser el editor completo | HECHO: `DisenadorKit.incrustar` dentro del paso «Equipación»; cada cambio va al club al momento. `_abrir_disenador` de `config_club_pasos.gd` ya no se usa (se deja) |
| 6 | Acompañante del bienvenido atraviesa un arbusto | PENDIENTE |
| + | Personaje del estudio tieso | Gestos de banda en bucle (`personaje_estudio.gd`); falta mejor esqueleto/movimiento |

## Modelos base (fallo 1): estado de los candidatos
- Quaternius Superhero M/F: los dos actuales (esqueleto de 65 huesos, vestidor por shader).
- «Modular Character Outfits» (`recursos/*.zip`, ya bajado de LFS): Peasant/Ranger M/F en glTF, rig Quaternius (compatible), pero son atuendos de fantasía y traerían archivos nuevos al repo (regla: sin LFS nuevo; hace falta OK del dueño).
- Kenney `characterMedium.fbx`: otro esqueleto; hay que retargetear animaciones y vestuario.
- MakeHuman: `visor/persona_mh.gd`; faltan los .glb por LFS (`assets/personas/persona_mh_*.glb`).
- Drive: sin acceso desde esta sesión (conector desconectado).

## Modelos 3D extra encontrados en GitHub (búsqueda del 2-11-2026; NADA descargado ni añadido al repo)
Licencia indicada por GitHub; confirmar la del propio pack antes de importar (y la regla de «sin LFS nuevo»).
| # | Repositorio | Licencia | Qué trae / notas |
|---|---|---|---|
| 1 | `KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0` | CC0 según KayKit (GitHub: sin identificar) | 4 aventureros de estilo cartoon, riggeados, GLTF/FBX |
| 2 | `KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0` | ídem | esqueletos cartoon riggeados (sirve de mascota/peluche) |
| 3 | `Makehuman-2/MH2_Asset_Repository_CCO` | CC0-1.0 | ropa, pelo y cuerpos de la comunidad MakeHuman 2 |
| 4 | `makehumancommunity/makehuman` | assets CC0, código AGPL | malla base humana (la que ya usa `persona_mh.gd`) |
| 5 | `NitroxNova/humanizer` | AGPL-3.0 (herramienta) | convierte MakeHuman a Godot 4 con esqueleto; solo para generar, no se distribuye |
| 6 | `WithinAmnesia/Vitruvian-Project` | CC0-1.0 | humano digital CC0 |
| 7 | `PabloFMM/numinia-digital-goods-data` | CC0-1.0 | avatares VRM y GLB (VRM = humanoide estándar, retargeteable) |
| 8 | `ToxSam/3d-anvil` | CC0-1.0 | avatares VRM y GLB |
| 9 | `trebeljahr/quaternius-showcase` | (índice) | navegador de los packs Quaternius CC0: «Ultimate Modular Men/Women», «Animated Men», «Zombie»… mismo autor y esqueleto que los actuales |
| 10 | `godotengine/godot-demo-projects` | MIT | personajes de demostración (robot, maniquí) con rig para Godot |
| 11 | `GeorgeQLe/assets-kaykit-3d-characters` | sin identificar | copia de KayKit; mejor ir a la fuente (1-2) |
Siguiente paso: que el dueño elija cuáles (la pregunta de los cuatro modelos base sigue abierta) y bajar solo esos a una carpeta propia, con retargeting al esqueleto de 65 huesos de Quaternius.
