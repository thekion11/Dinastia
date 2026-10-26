# Competiciones del juego: nombre ficticio y referencia real

Regla: los nombres reales solo viven en `dinastia-godot/datos/pack_real.json`. La base del juego es ficticia.
El núcleo guarda las competiciones con su nombre interno (partidas guardadas, logros y narración generada). Lo que se ve
en pantalla pasa por `CompeticionInfo.nombre_visible()` (`ui/competiciones/competicion_info.gd`). Con la base ficticia,
los nombres internos que aún coinciden con los reales se cambian por los de la tabla 3. Con el pack real, se muestra el
nombre interno tal cual. Siempre pasa por `Idiomas.t`.

El tipo de cada competición (columna «Tipo») decide su logo (`LogoCompeticion`) y su trofeo 3D (`Trofeo3D`).

## 1. Ligas y copas nacionales (tipo `liga` y `copa`)

Las ligas y copas de la base ya son genéricas («Liga Argentina», «Copa de Francia»). El pack real cambia algunas.

| País | Liga (base ficticia) | Liga (pack real) | Copa (base) | Copa (pack real) |
|---|---|---|---|---|
| ARG | Liga Argentina | Liga Argentina | Copa Argentina | Copa Argentina |
| BRA | Liga Brasileña | Brasileirão | Copa de Brasil | Copa de Brasil |
| URU | Primera de Uruguay | Primera de Uruguay | Copa Uruguay | Copa Uruguay |
| PAR | Primera de Paraguay | Primera de Paraguay | Copa Paraguay | Copa Paraguay |
| COL | Liga de Colombia | Liga de Colombia | Copa Colombia | Copa Colombia |
| PER | Liga de Perú | Liga de Perú | Copa Perú | Copa Perú |
| ECU | Liga de Ecuador | Liga de Ecuador | Copa Ecuador | Copa Ecuador |
| ESP | Liga Española | La Liga | Copa de España | Copa del Rey |
| ENG | Liga Inglesa | Premier League | Copa de Inglaterra | FA Cup |
| ITA | Liga Italiana | Serie A | Copa Italia | Copa Italia |
| GER | Liga Alemana | Bundesliga | Copa de Alemania | Copa de Alemania |
| FRA | Liga Francesa | Ligue 1 | Copa de Francia | Copa de Francia |
| BOL | Div. Profesional de Bolivia | Div. Profesional de Bolivia | Copa Bolivia | Copa Bolivia |
| JPN | Liga Japonesa | J-Liga | Copa de Japón | Copa del Emperador |
| KOR | Liga Coreana | K-League | Copa de Corea | Copa de Corea |
| KSA | Liga Saudí | Liga Saudí | Copa de Arabia | Copa del Rey de Campeones |
| EGY | Liga de Egipto | Liga de Egipto | Copa de Egipto | Copa de Egipto |
| MAR | Liga Marroquí | Botola de Marruecos | Copa de Marruecos | Copa del Trono |
| RSA | Liga de Sudáfrica | Liga de Sudáfrica | Copa de Sudáfrica | Copa Nedbank |
| AUS | Liga Australiana | A-League | Copa de Australia | Copa de Australia |
| MEX | Liga Mexicana | Liga MX | Copa de México | Copa MX |
| USA | Liga Norteamericana | Major League | Copa de EE.UU. | US Open Cup |

La supercopa nacional (tipo `supercopa`) se llama «Supercopa de <país>» en las dos bases.

## 2. Copas continentales de clubes (tipo `continental` y `continental2`)

| Clave | Continental (base ficticia) | Referencia real (pack real) |
|---|---|---|
| lib | Copa Cóndor | Copa Libertadores |
| sud | Copa Cruz del Sur | Copa Sudamericana |
| ucl | Copa de las Estrellas | Champi0ns Le4gue |
| uel | Copa del Viejo Continente | Eur0pa Le4gue |
| asia | Copa Asiática de Clubes | Champi0ns de As1a |
| afr | Copa África de Clubes | C0pa África de Clubes |
| oce | Liga de Oceanía | L1ga de Oceanía |
| conc | Copa Norte y Centro | C0ncachampions |

`sud` y `uel` son la segunda copa del continente: tipo `continental2` (copa alta y fina, sin asas).
El resto es `continental` (copa grande de asas enormes).

## 3. Mundial y torneos de selecciones (nombre interno real -> nombre visible ficticio)

| Nombre interno (núcleo) | Nombre visible con la base ficticia | Referencia real | Tipo |
|---|---|---|---|
| Mundial de Clubes | Copa Intercontinental de Campeones | Mundial de Clubes | `mundial_clubes` |
| Copa del Mundo | Copa Mundial de Naciones | Copa del Mundo | `mundial_sel` |
| Eurocopa | Copa de Naciones del Viejo Continente | Eurocopa | `selecciones` |
| Copa América | Copa de Naciones del Sur | Copa América | `selecciones` |
| Copa de Asia | Copa Asiática de Naciones | Copa Asiática | `selecciones` |
| Copa África | Copa de Naciones del Sol | Copa Africana de Naciones | `selecciones` |
| Copa Oro | Copa de Naciones del Norte | Copa Oro | `selecciones` |
| Copa de Oceanía | Copa de Naciones del Pacífico | Copa de Naciones de la OFC | `selecciones` |

Fuentes en el código: `nucleo/selecciones_p1.gd` (`TORNEO_POR_CONFED`), `nucleo/selecciones_p2.gd` (Copa del Mundo,
Eurocopa, Copa América y Mundial de Clubes), `nucleo/mundo_p6.gd` (Supercopa), `datos/tablas.json` (`PAISES_LIGAS`,
`COPA_NOM`, `CONFED`) y `datos/pack_real.json` (lo mismo en real).

## Pendiente

Las pantallas que todavía escriben el nombre interno sin pasar por `CompeticionInfo.nombre_visible()`: noticias,
calendario, sorteos y la ficha de la competición. Ya pasan por él la rueda de prensa, el legado y su vitrina 3D.
