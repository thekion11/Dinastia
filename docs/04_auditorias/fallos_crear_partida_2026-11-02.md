# Fallos de «crear personaje / crear partida» (informe del dueño, 2-11-2026, Windows)

Rama `ccr-fallos-crear-partida`. Prueba: `pruebas/ideas/fcp_crear_partida` (banco de ideas); capturas con clics reales: `pruebas/fcp_captura.tscn` (`QUE=personaje|equipacion`).

| # | Fallo | Estado |
|---|---|---|
| 1 | «Tras elegir un modelo de personaje no deja elegir otro» → el dueño aclara: es el MODELO BASE 3D (hoy solo Hombre/Mujer Quaternius). Quiere como opciones básicas: «Modular Character Outfits», los del Drive, Kenney `characterMedium` y MakeHuman | PENDIENTE (ver abajo) |
| 2 | Pantalla gris con «…a primera persona.» al confirmar | Es `PantallaCarga` del prólogo (`visor/prologo.gd` construye la ciudad bloqueando el hilo). Lo lleva la sesión del prólogo |
| 3 | Mascotas: cola flotando | ARREGLADO: la cola sigue a la pelvis (`visor/mascota_q.gd`, `ColaSoporte`). «Feas»: pendiente |
| 4 | Escudo propio no sale en el uniforme | ARREGLADO en la camiseta 2D (`DisenosKit.textura_completa` dibuja `escudo_tex` de frente) |
| 5 | «Uniforme» debe ser el editor completo | HECHO: `DisenadorKit.incrustar` dentro del paso «Equipación»; cada cambio va al club al momento. `_abrir_disenador` de `config_club_pasos.gd` ya no se usa (se deja) |
| 6 | Acompañante del bienvenido atraviesa un arbusto | PENDIENTE |
| + | Personaje del estudio tieso | Gestos de banda en bucle (`personaje_estudio.gd`); falta mejor esqueleto/movimiento |

## Modelos base (fallo 1): estado de los candidatos
- Quaternius Superhero M/F: los dos actuales (esqueleto de 65 huesos, vestidor por shader).
- «Modular Character Outfits» (`recursos/*.zip`, ya bajado de LFS): Peasant/Ranger M/F en glTF, rig Quaternius (compatible), pero son atuendos de fantasía y traerían archivos nuevos al repo (regla: sin LFS nuevo; hace falta OK del dueño).
- Kenney `characterMedium.fbx`: otro esqueleto; hay que retargetear animaciones y vestuario.
- MakeHuman: `visor/persona_mh.gd`; faltan los .glb por LFS (`assets/personas/persona_mh_*.glb`).
- Drive: sin acceso desde esta sesión (conector desconectado).
