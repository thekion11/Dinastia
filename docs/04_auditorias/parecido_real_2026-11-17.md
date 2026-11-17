# Parecido real: auditoría de jugadores, escudos y uniformes (17-11-2026)

Meta del dueño: que CADA jugador real esté en el juego y se PAREZCA al real; escudos y uniformes más parecidos a los reales.
Cifras reproducibles: `python3 herramientas/auditar_parecido_real.py` → `parecido_real_cifras_2026-11-17.json` (lee `pack_real.json`, solo uso privado; en lo público todo con nombres ficticios).
Referencia de «real»: cantidad de clubes por liga conocida [C = de memoria, sin verificar hoy]; plantilla de primer equipo = 25. Wikipedia devolvió 429 desde este contenedor; Wikidata (SPARQL) sí responde, pero su «miembro de» sin fecha de fin mezcla plantillas actuales con históricas (probado con Arsenal: sale gente de 1875): hay que filtrar por nacimiento, sexo y fecha de fin, y aun así hay que revisar.

## 1. Clubes (cantidad por liga)
Las 8 ligas pedidas tienen la cantidad real de clubes: ENG 20, ESP 20, ITA 20, GER 18, FRA 18, ARG 30, BRA 20, CHI 16 (0 clubes de menos). Total del pack: 1.958 clubes en 135 países.

## 2. Jugadores: plantilla real por club
El pack `REALES` trae **339 clubes con jugadores reales y 3.911 jugadores** (200 clubes con 12, 36 con 14; media ≈ 11,5). Una plantilla de primer equipo tiene ~25: faltan **4.564 jugadores** solo para completar los clubes que ya tienen plantilla.

| Liga | Clubes | Con plantilla real | Jugadores reales | Faltan hasta 25/club | Sin plantilla real |
|---|---|---|---|---|---|
| ENG | 20 | 16 | 170 | 230 | Bournemouth, Burnley, Leeds, Sunderland |
| ESP | 20 | 16 | 149 | 251 | Alavés, Elche, Levante, Oviedo |
| ITA | 20 | 14 | 153 | 197 | Como, Parma, Cagliari, Verona, Cremonese, Pisa |
| GER | 18 | 15 | 168 | 207 | Hamburgo, St. Pauli, Heidenheim |
| FRA | 18 | 14 | 149 | 201 | Paris FC, Angers, Le Havre, Metz |
| ARG | 30 | 14 | 140 | 210 | 16 clubes (Argentinos, Belgrano, Gimnasia LP…) |
| BRA | 20 | 14 | 135 | 215 | Bragantino, Mirassol, Vitória, Coritiba, Chapecoense, Remo |
| CHI | 16 | 16 | 145 | 255 | — |

En las 8 ligas faltan **2.841 jugadores** (1.766 para completar los clubes con plantilla + 43 clubes sin plantilla × 25). Fuera de estas 8: 24 países tienen alguna plantilla real y **111 de 135 países no tienen ninguna** (se generan con nombres inventados).

Campos que el pack NO trae para un jugador real: **dorsal, altura, pie, complexión/peso**. Solo `nombre|puesto|edad|media|país[|región]`. Hoy la altura y el pie salen del generador (semilla del nombre), no del jugador real.

## 3. Aspecto del jugador (rasgos)
Del total de 3.911 jugadores reales: **954 con rasgos medidos** (piel, color de pelo, barba: `caras_reales_rasgos.json`), **319 con malla/tono** (`caras_reales_mallas.json`) y **2.638 sin dato de aspecto** (usan el promedio de su país, `CaraPrior`): **67 %**. Peor cubiertas: ARG 99 de 140 sin dato, BRA 73 de 135, CHI 56 de 145. Mejor: ENG 18 de 170.
No existe en datos: corte de pelo concreto, complexión, altura; el modelo 3D y el retrato los inventan por semilla.

## 4. Escudos y uniformes (proxy medible)
No hay imagen oficial en el repo (y no deben entrar), así que el parecido se mide por **rasgos propios en datos**:
- Escudo propio = al menos 2 de {patrón distinto de «liso», emblema, letras}: **1.443 de 1.958 (74 %)**; genérico: **515**. En las 8 ligas: ENG 8/20, ESP 13/20, ITA 14/20, GER 4/18, FRA 6/18, ARG 17/30, BRA 7/20, CHI 7/16 con escudo propio.
- Uniforme completo (diseño ≠ liso o pantalón y medias propios, y visita con diseño) en **910**; básico **1.048**; sin visita **57**.
- Revisión manual de los 160 clubes de las 8 ligas contra lo que sé del uniforme local real (diseño y colores): coinciden en el diseño de camiseta casi todos. Candidatos a corregir: **Parma** (el local real es blanco con cruz amarillo-azul; el pack tiene franjas amarillas/azules), **Hamburgo** (el local real es blanco; el pack tiene azul). Por tanto el mayor hueco NO es el color ni el diseño de camiseta, sino la **figura principal del escudo** (515 genéricos) y los **detalles** (cuello, pantalón, medias) de unos 1.048 uniformes básicos.

## 5. Plan por ligas (orden: ENG, ESP, ITA, GER, FRA, ARG, BRA, CHI)
1. **Jugadores** (herramienta `herramientas/jugadores_parecido.py`, pendiente): completar cada club hasta 25 con nombre, puesto, edad, país, dorsal, altura y pie de fuentes abiertas (Wikidata con filtros; anotando fuente); media = regla por reputación del club y puesto (no hay fuente abierta de medias); luego regenerar la base pública con `jugadores_guino.py`.
2. **Rasgos**: añadir en los datos `piel`, `peloC`, `pelo` (corte), `barba`, `complexión` por jugador real: primero de lo ya medido (1.273), después por país y reglas de la liga; sin fotos en lo público.
3. **Escudos y uniformes**: figura/emblema y detalles por club con los generadores existentes (`aspecto_clubes.py`), empezando por los clubes de mayor reputación de cada liga; hojas de comparación con 6+ clubes de 3 países.

Fuente: cifras de `herramientas/auditar_parecido_real.py` (medidas hoy); cantidades reales [C].

## 6. Estado a 17-11 (tarde) y puntos a revisar
- **Plantillas**: 43 de 43 clubes sin plantilla cubiertos (ENG, ESP, ITA, GER, FRA con Wikipedia en inglés; ARG con Wikipedia en español; BRA en inglés), hasta 26 por club equilibrados por línea; dorsal, edad y altura de Wikipedia/Wikidata cuando existen. Media ESTIMADA (reputación − 9, puesto, edad, dorsal, variación estable) con un bono por notoriedad (artículos en otros idiomas) para los 3-5 más conocidos de cada club.
- **Rasgos de aspecto**: 61 conocidos a mano (`rasgos_jugadores.py`, tabla `RASGOS_JUG`), estimados; el resto, el promedio de su NACIONALIDAD (`CaraPrior` usa `j.pais`; comprobado en el banco: `_probar_cara_por_nacionalidad`). Corregido un tono equivocado (Son Heung-min tenía la piel de un tono medio-oscuro en vez de clara).
- **Escudos**: un cambio por club en `_escudos.txt` (Torino toro, Lecce lobo, Genoa cruz, Sevilla y Betis con corona, Newcastle con caballito de mar, Heidenheim con castillo, Hamburgo con contorno de rombo). Hoja antes/después: `capturas_parecido_real/escudos_antes_despues_2026-11-17.jpg`.
- **A REVISAR (sin fuente abierta)**: uniforme local de **Parma** (blanco con cruz) y de **Hamburgo** (blanco con pantalón azul): están de MEMORIA. Wikidata P6364 de Hamburgo da «azul, negro y blanco» (compatible, no lo confirma); la de Parma no tiene colores. No darlos por buenos hasta contrastarlos con la ficha de Wikipedia del uniforme.
- **Nombres largos** en la lista del plantel: el botón del nombre se corta ya con puntos suspensivos (la hoja de captura es solo una escena de revisión).

## 7. Cierre (17-11, tarde): comprobaciones y fallos encontrados
- **Legal**: la comprobación de nombres reales vive ahora dentro de `base_ficticia.py` (`comprobar_nombres_reales.py`, 4.260 nombres completos de `reales_lista`, créditos y pack): primera pasada = 1 coincidencia en el banco (`Francisco González`) y 12 con la comprobación más estricta (un guiño era el real con una letra añadida); corregidas todas, hoy 0.
- **Nacionalidades**: tabla de equivalencias a los 151 códigos de `Banderas.ISO`; 3 desconocidas (DOM, MTN, PUR) y 133 sin dato pasan al país de la liga con la marca «e».
- **Causas del resultado** (`CausasPartido`): en un partido parejo y neutro solo salían 2 causas (localía y posesión); ahora hay un relleno honesto con la diferencia real de plantilla, forma o físico. `s5_causas` en 0.
- **Porteros**: los de cada club importado quedan a ≤3 de media del mejor.
- **Estabilidad de edades** (`cant_estabilidad`): tope de media por edad en lo importado (≤19: 74; ≤21: 78; ≤22: 81). La prueba falla según la semilla, con o sin estos datos (ver el mensaje a la auditoría).
