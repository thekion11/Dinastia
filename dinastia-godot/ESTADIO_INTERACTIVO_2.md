# Estadio interactivo 2.0

Pedido del usuario (7-10-2026):
- recorrer el estadio junto a la ciudad, entrando y saliendo;
- todos los lugares creados en el estadio, físicamente dentro;
- todo lo que tiene un estadio: pisos negativos, oficina del DT…;
- si sancionan al DT, ver el partido desde la grada, recorrer con el personaje y sentarse en las tribunas;
- el personal del club con presencia física, diálogos en persona, interacción y rutinas;
- habitaciones personalizables: colores, decoración, las fotos sacadas en las paredes, la oficina con objetos propios;
- los nombres de los jugadores donde corresponde.

## Lo que ya existe (revisado en el código)
- **Estadio en la ciudad.** Está construido con el modelo real en `CityBuilder.ESTADIO_EN = (0, 0, −150)`. Pulsar E delante abría el editor, no el estadio.
- **Túnel y vestuario** (`TunelVestuario`), y el recorrido a pie (`ExploradorEstadio`), los dos del 7-10.
- **Lugares del estadio en los datos:**
  - `ClubDentro`: vestuario, sala de prensa y palco, con su nivel;
  - `Instalaciones`: tribunas, museo, tienda, estacionamiento, sala de prensa, cocina, médico, gimnasio, vídeo…;
  - `Comercial`: naming y zonas de patrocinio.
- **Personas:**
  - `Trabajadores`: jefe de cada instalación con nombre y carácter, más otros puestos;
  - `Gente`: utilero, jardinero, cocinera, conserje, secretaria, chófer, médico…, con `charlar()`;
  - `Junta`: presidente y accionistas;
  - `Staff`: los niveles del cuerpo técnico.
- **Cuerpo del DT:** `PersonajeDT.crear(padre, PersonajeDT.del_usuario, c1, c2)`.
- **Fotos:** `ModoFoto.fotos()`, en `user://fotos/*.png`.
- **Sanción al DT:** solo existe la expulsión en el partido. La sanción de varias fechas (`dtSusp` del HTML) no se portó.

## Fases
1. **Ciudad ↔ estadio, con tu personaje.**
   - A pie por la ciudad se llega a la puerta del estadio y con E se entra, en el mismo mundo y sin pantallas de carga.
   - Dentro se recorren el vestuario, el túnel y la cancha; se sale por la misma puerta a la calle.
   - El caminante es tu DT (con su aspecto), no un peatón al azar.
2. **El edificio del club bajo la tribuna, por plantas.**
   - **Planta −2:** estacionamiento (nivel de `park`), cuarto de máquinas y almacén.
   - **Planta −1:**
     - vestuario local con los NOMBRES y dorsales de tu plantilla;
     - vestuario visitante;
     - túnel, enfermería (`med`) y gimnasio de calentamiento (`gim`);
     - utilería con el utilero.
   - **Planta 0:** vestíbulo, tienda y museo (`com` y `museo`), y sala de prensa (`ClubDentro.sala_prensa`).
   - **Planta 1:**
     - oficina del DT;
     - despacho del presidente;
     - sala de vídeo (`video`);
     - palco (`ClubDentro.palco`), con salida a la grada.
   - Escaleras y ascensor entre plantas (E).
   - Cada sala refleja su nivel: lo que no está construido sale «en obras» o vacío.
3. **La grada.** Sentarse en cualquier tribuna con E y ver el estadio desde ahí.
   - Sanción de varias fechas al DT (portar `dtSusp`). Sancionado, el partido se ve desde el palco o desde tu asiento, sin poder dar órdenes desde la banda.
4. **El personal en persona.**
   - Cada trabajador y cada persona de `Gente` tiene cuerpo, puesto y rutina según la hora: llega, trabaja, come, se va.
   - Con E se habla en persona (diálogo con opciones que usa `Gente.charlar`, los asuntos `pendiente` de `Trabajadores` y la junta del presidente).
5. **Personalizar.**
   - Cada sala con color de paredes y suelo, decoración de un catálogo (plantas, sofás, trofeos, banderas, pantallas…) y cuadros con TUS FOTOS del modo foto.
   - La oficina del DT con objetos propios.
   - Se guarda con la partida.
6. **Pulido.** Capturas por planta, pruebas en el banco y documentación.
