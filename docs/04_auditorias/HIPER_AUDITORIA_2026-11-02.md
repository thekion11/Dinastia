# HIPER AUDITORÍA — 2-11-2026

Mismo estándar que la MEGA AUDITORÍA 3: cifras repetibles con `python3 herramientas/auditoria_repo.py` (datos del día en
`datos_auditoria_2026-11-02.json`) y búsquedas `grep`/`git` sobre `main` (`5c4082de`). Lo medido se dice medido; lo estimado
va marcado **(est.)**. Sin GPU en el contenedor: nada de esto es un FPS real (M-337 sigue siendo del dueño).

## 1. Resumen

| Área | Estado | Cifra clave (24-10 → 2-11) |
|---|---|---|
| Código | Sólido, creciendo rápido | scripts del juego 476 → 904; líneas del juego 135 k → 191 k; 0 scripts propios > 450 (el único de 480 es el addon `debug_menu`) |
| Funciones largas | Peor | > 100 líneas: 143 → 190; > 200: 21 → 14 |
| Por fotograma | Peor | `_process` 60 → 145 (128 en código del juego), `_physics_process` 3 → 4 |
| Pruebas | Más, con huecos | escenas de prueba 395 → 763; sin ninguna mención 53 → 123 |
| Texturas | Deuda sin cambio | 3.471 importadas, **3.406 sin comprimir (98 %)**, 3.342 sin mipmaps |
| Render | Muy cargado en ALTO/ULTRA | SDFGI 6 cascadas + SSIL + SSR + niebla volumétrica + glow; ULTRA apila MSAA 8× + FXAA + TAA |
| Física | Propia, no del motor | 3 `RigidBody3D`, 0 `Area3D`, 0 navegación; balón con arrastre LINEAL y Euler |
| Pendientes del plan | Muchos abiertos | 170 PENDIENTE · 110 PARCIAL · 8 SIN VERIFICAR · 31 filas P1 · 1 P0 (M-337) |
| Idiomas | Casi al día | 6.848 frases en inglés, 522 patrones, 106 frases medidas sin traducir |
| `TODO/FIXME/XXX` | Subiendo | 37+2 → 44+5 (71 en `visor/`, `nucleo/`, `ui/`) |

## 2. Errores encontrados (H-xx; ninguno arreglado en esta auditoría)

| id | Gravedad | Qué | Dónde / prueba |
|---|---|---|---|
| H-01 | ALTA | **El partido corre a 60 Hz y se dibuja sin interpolación**: el motor mueve balón y jugadores en `_physics_process` (`motor_jugable.gd:90`) y `physics/common/physics_interpolation` no está activado en `project.godot`. A 120 FPS cada posición se repite dos fotogramas: tirones visibles justo en la meta de 120 FPS. | `project.godot` (no hay sección `[physics]`) |
| H-02 | ALTA | **Prueba inestable en `main`**: «estadio y ciudad por partes: ciudad: por partes = de una vez» falló en el CI del PR #107 (solo documentos) y pasó en el #106. Además «cede fotogramas (0)» falla siempre en local. Es el mismo sistema que causaba la pantalla gris del prólogo. | `especiales 0/6`, `probar_por_partes` |
| H-03 | MEDIA | **Arrastre del balón lineal** (`vel × 0,06`): un balón real pierde ∝ v² (≈0,013·v² m/s², **est.**). A 30 m/s el motor frena 1,8 m/s² y el real ≈12: los disparos lejanos no «caen», los pases largos van de más. | `motor_jugable_p4.gd:77`, `ARRASTRE` en `_p1.gd:60` |
| H-04 | MEDIA | **El efecto (giro) del balón no se gasta en el aire** y en el suelo se gasta por fotograma (`giro_balon *= 0.97`): si algún día cambia la frecuencia de física, cambia la curva. El bote (0,55) y el frenado (×0,72) no dependen del giro: un balón con efecto bota igual que uno sin él. | `motor_jugable_p4.gd:83-95` |
| H-05 | MEDIA | **Dos gravedades distintas**: el partido usa 9,81 y el balón suelto de la ciudad 18,0 («para que se sienta»), y `ciudad_expansion_p6` usa 9,8. El mismo balón cae el doble de rápido en el parque. | `balon_suelto.gd:7` |
| H-06 | MEDIA | **Texturas creadas en tiempo de ejecución sin comprimir**: 82 llamadas a `ImageTexture.create_from_image` en el juego, ninguna comprime (`Image.compress`), y solo 24 generan mipmaps. Escudos, uniformes, banderas y trofeos viven en VRAM como RGBA8 (4 B/píxel) y parpadean a distancia. | `visor/kit_texture_factory.gd`, `banderas.gd`, `trofeo_modelo.gd`, … |
| H-07 | MEDIA | **Texturas 3D importadas sin comprimir ni mipmaps**: `assets/characters` 35 de 50 sin comprimir (≈126 MiB en RGBA8, **est.**), `assets/kenney` 19 de 19, `assets/escudos_especiales` 40 de 40, `recursos/` 2.535 de 2.539. La detección «3D» del importador solo actúa si un `.tscn` las usa en el editor; los materiales armados por código no la disparan. | `*.import` (`compress/mode=0`, `mipmaps/generate=false`) |
| H-08 | MEDIA | **4 autoloads globales del minijuego `retro5v5`** (`KeyUtils`, `DataLoader`, `GameEvents`, `GameManager`) se cargan siempre, aunque nunca se abra el minijuego, y con nombres genéricos que pueden chocar con clases futuras. | `project.godot` [autoload] |
| H-09 | BAJA | Comentario desfasado en `calidad.gd:250-262`: dice «x4 se guarda para ULTRA» y el código pone `MSAA_8X` + FXAA + TAA (tres antialias a la vez: más coste y más borrosidad). | `visor/calidad.gd` |
| H-10 | BAJA | `CLAUDE.md` tiene dos órdenes numeradas «19.». | `CLAUDE.md` |
| H-11 | BAJA | 25 `print` sueltos en el juego (p. ej. `calidad_auto.gd:48`, `medicion.gd`, `paquete_real.gd`): ensucian el registro del jugador. | `grep print(` |

## 3. Optimización (qué más se puede ganar)

Orden por impacto **(est.)** sobre la meta de 120 FPS en equipos modestos (orden 19):

1. **Interpolación de física** (H-01): `physics/common/physics_interpolation=true` + `reset_physics_interpolation()` en los saltos (saques, repeticiones). Coste casi nulo; sin esto 120 FPS se ven como 60.
2. **Tráfico**: `trafico_ciudad.gd::_process` tiene 215 líneas (la función por fotograma más larga del juego) y es el mayor coste de CPU medido (2,08 ms, `rendimiento_120fps.md`). Pasarlo a tick escalonado (10-20 Hz con interpolación) o a la extensión C++.
3. **128 `_process` en el juego**: un gestor central que recorra arrays (`PackedVector3Array`) para peatones, coches, buses, semáforos, personal del estadio; los nodos sin trabajo con `set_process(false)`.
4. **VRAM** (H-06, H-07): comprimir las texturas 3D (VRAM S3TC/ETC2 + mipmaps) y las de tiempo de ejecución grandes con `Image.compress`; bajar a 1024 las ≥ 2048 que no lo necesiten (19 imágenes, entre ellas `fronteras4k.png` y las tres `T_Peasant_*` de 4096). Ahorro esperado: cientos de MiB **(est.)**, clave con 4 GB de RAM compartida con la gráfica integrada.
5. **ALTO pasa de 4 GB** (medido por la sesión de optimización): SDFGI de 6 cascadas + SSIL + SSR + niebla volumétrica + atlas de sombras 8192 en ULTRA (≈256 MiB solo el atlas, **est.**). Ofrecer SDFGI de 4 cascadas en ALTO y dejar 6 solo en ULTRA.
6. **Césped en capas** ≈230 k triángulos y 57 llamadas (M-339): un solo `MultiMesh` o shader de hierba.
7. **Ciudad +50 % de coste tras el guion** (M-476): recorte por celdas fuera del prólogo también (hoy solo el prólogo se recorta al barrio).
8. **Arranque del motor ligero**: hoy arranca en Vulkan, detecta la gráfica y se relanza en OpenGL (dos arranques). Guardar la elección en `override.cfg` en la primera ejecución para que los siguientes arranques vayan directos.
9. **Autoloads de `retro5v5`** (H-08): instanciarlos al abrir el minijuego.

## 4. Calidad y pruebas

- 123 escenas de prueba sin ninguna mención (antes 53): las 62 reutilizadas ya están en `especiales.sh`; repasar las nuevas.
- M-279/M-280/M-404: 27 + 8 + 105 módulos sin prueba directa.
- 190 funciones de más de 100 líneas; las de juego más grandes: `autobus_modelo.crear` (243), `catalogo_jugadas._f` (239), `interior_instalacion_p3._estacion` (233), `pantalla_opciones._pintar_dispositivo` (216), `trafico_ciudad._process` (215), `pantalla_ficha._ver_ficha` (214). La norma de 450 es de archivo, no de responsabilidad.
- Sin comparación automática de imágenes (capturas antes/después a ojo).
- El PR #99 se fusionó con el CI a medias (salió verde después): fusionar solo con el CI terminado.

## 5. Efectos y visual

- Pendientes del plan: estadio real solo en 46 % de clubes (M-359), butacas con color propio en 47 de 176 estadios (M-005), formas de estadio no continuas (M-003), túnel de vestuario solo en +Z (M-017), sin diferencia día/noche en la iluminación del estadio (M-014), afición sin bufandas ni banderas en la mano (M-035), ropa con volumen solo en retratos (M-054), sin arrugas dinámicas (M-055), botines sin modelos distintos (M-091), retrato real 13 % (M-079).
- Partículas: 16 `GPUParticles3D` + 5 `CPUParticles3D`; en Compatibilidad las GPU van peor: preferir CPU o desactivar en LIGERO.
- `OccluderInstance3D` solo en 1 sitio: los interiores (estadio, museo, centro comercial) no tienen oclusión.
- Sin LOD manual (`lod_bias` 0 usos) aunque hay 78 `visibility_range_end`: comprobar que los `.glb` importan con LOD generado.
- Visto por el dueño: mascotas «feas», arbusto atravesado (resuelto por geometría, sin confirmar a ojo), prólogo gris (corregido, sin probar en Windows).

## 6. Jugabilidad

- Penales: el portero decide una vez y no lee al lanzador (M-119).
- Tráfico sin comportamiento complejo (M-171); eventos únicos y agenda parciales (M-263).
- Mercado sin burbujas ni crisis (M-210); `Banco`/`Insolvencia` con pocos eventos (M-219); lesiones sin prevención visible en pantalla (M-235).
- Hitbox balón-cuerpo: 0 casos atravesando en la sonda, pero parcial (M-147).
- Táctica, IA de la CPU y comportamiento van en la pasada FINAL del motor (orden 13).
- Las 8 dificultades existen; falta medir que se noten (prueba de equilibrio: M-209 solo comprueba que no haya errores).

## 7. Físicas

- Todo el partido es física propia (bien: determinista, sin depender del motor): Euler con paso fijo de 60 Hz.
- Mejoras concretas: arrastre cuadrático (H-03); giro que se gasta en el aire y cambia el bote (H-04); una sola gravedad (H-05); al palo y al larguero se los mira con la posición del FINAL del paso al cruzar la línea (`motor_jugable_p3.gd:374-382`), no con el punto exacto de cruce: a 30 m/s el balón avanza 0,5 m por paso y, en un tiro cruzado, el «al palo» o el gol pueden decidirse con hasta medio metro de error lateral **(est.)**; interpolar el punto de cruce o sub-pasos a 120 Hz; interpolación visual (H-01).
- La ciudad no tiene colisión de motor (altura `ExploradorCiudad.altura_suelo`): el balón y los peatones no chocan con fachadas; `Area3D` = 0. Para policía/bomberos/coches convendría `Area3D` simples o la extensión C++.
- Jolt Physics (incluido en Godot 4.4+) solo importa si se pasa a cuerpos del motor; hoy no aporta.

## 8. Prioridad propuesta

| Prioridad | Qué | Quién |
|---|---|---|
| P0 | M-337 FPS en hardware real (benchmark en Vivo Y36 y laptop modesta); probar el prólogo en Windows | dueño |
| P0 | H-01 interpolación de física · H-02 prueba inestable | sesión de motor |
| P1 | H-03/H-04/H-05 física del balón · tráfico a tick escalonado · H-06/H-07 VRAM | sesión de motor / optimización |
| P1 | H-08 autoloads · SDFGI más ligero en ALTO · `override.cfg` del motor ligero | optimización |
| P2 | H-09, H-10, H-11 · funciones > 200 líneas · pruebas sin mención · filas visuales M-xxx | cualquiera |

Nada de esto se ha cambiado en el código: es la lista para la próxima sesión. Lo que se cierre se borra de aquí y de
`PLAN_DEL_LUNES.md` tras su prueba (banco / especiales / captura con la cámara real).
