# Modelos 3D gratuitos de la web (11-9-2026)

Recopilados por el propio agente, sin que el usuario tuviera que descargar nada -pidió "ve si
puedes agarrar contenido ya hecho de Godot y los vas recopilando como recursos". Los tres son
**dominio público (CC0)**, verificado en la propia página de origen antes de bajarlos, siguiendo la
orden permanente de [[dinastia-orden-calidad]]. Formato conservado: **GLB** (el que Godot 4 importa
sin pasos extra, con las texturas ya embebidas); se descartaron las copias en FBX/OBJ de los packs
de Kenney para no triplicar el peso -el .zip original queda guardado por si algún día hace falta
otro formato-.

## `soccer_field.zip` / `soccer_field/`

- **Fuente:** OpenGameArt.org, `https://opengameart.org/content/soccer-field` (verificar la página
  si se necesita el enlace vivo; el zip se descargó de
  `https://opengameart.org/sites/default/files/soccer_field.zip`).
- **Licencia:** CC0 (dominio público), declarada en la propia página de OpenGameArt.
- **Contenido:** `Soccer Field.fbx` -cancha, arcos y graderías en un único modelo-. 116 KB.
- **Nota:** viene solo en FBX, no en GLB -es el pack más chico y no traía otro formato-.

## `kenney_city-kit-commercial.zip` / `kenney_city-kit-commercial/`

- **Fuente:** Kenney (`kenney.nl/assets/city-kit-commercial`), pack "City Kit Commercial" v2.1.
- **Licencia:** CC0 ("Creative Commons Zero"), texto completo en `License.txt` dentro de la carpeta.
  Kenney pide -no exige- crédito a "Kenney" o "www.kenney.nl".
- **Contenido:** 50 edificios y detalles de zona comercial (locales, rascacielos, toldos, carteles)
  en `Models/GLB format/`. 3,7 MB.

## `kenney_car-kit.zip` / `kenney_car-kit/`

- **Fuente:** Kenney (`kenney.nl/assets/car-kit`), pack "Car Kit".
- **Licencia:** CC0, mismo texto que el de arriba.
- **Contenido:** 45 autos y variantes para las calles de la ciudad deportiva. `Models/GLB format/`.
  5,6 MB.

## Qué se integró (11-9-2026, más tarde la misma noche)

**Cinco de los rascacielos de `kenney_city-kit-commercial`** (`building-skyscraper-a` a `-e`, copiados
a `visor3d/assets/ciudad/kenney_buildings/` junto con su `Textures/colormap.png` -la ruta relativa
importa: el GLB la referencia así, aplanarla rompe la textura en el import-) ahora forman el
**horizonte lejano** de la ciudad deportiva, en `CityBuilder._horizonte()` (`visor3d/scripts/
city_builder.gd`): 26 copias repartidas en un anillo a 280-430 m del centro, siempre fuera del
recinto del complejo. Verificado con `captura_ciudad.gd` -el primer intento las puso a 600-900 m
"porque la cámara no pasa de 700" y no se veía NINGUNA: la niebla volumétrica de `Calidad.gd` solo
alcanza 220 m, así que todo lo de más lejos se lava contra el cielo aunque el motor lo siga
dibujando-. El resto de `soccer_field.zip` y del propio `kenney_car-kit.zip` sigue sin integrar.

## Qué falta todavía

`soccer_field/Soccer Field.fbx` (cancha con arcos y graderías) y `kenney_car-kit` (45 autos) siguen
**recopilados, sin usar**. El complejo ya tiene sus propios `coche1.fbx`/`coche2.fbx` a mano para el
aparcamiento -el car-kit serviría para darle más variedad, reemplazando o sumándose a esos dos-.

Relacionado: [[dinastia-recursos-sorpresa]], [[dinastia-ciudad-3d]], [[dinastia-orden-calidad]].
