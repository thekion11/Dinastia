# Pasada visual de la ciudad n.º 2 (4-11-2026) — hoja antes/después
Mismo método que la n.º 1 (`pruebas/captura_pasada_ciudad.tscn`, Forward+, MEDIA, 13:00). Las tomas a pie ya no se hacen a 26 m del centro de la zona (caían dentro de rótulos y muros) sino a 48 m, mirando 7 m más arriba, para que el antes/después sea comparable.

| Zona | Problema | Cambio | Antes / después |
|---|---|---|---|
| Mercado municipal | Nave de base ocre lisa, sin una ventana | `MuroCivico.vestir` en la base (ventanas por piso, de noche encendidas); la bóveda verde se queda | `capturas_ciudad_c2/pasada2_centro_mercado_aerea_{antes,despues}.jpg` |
| Plaza mayor, volumen crema al norte | Era el edificio de los soportales de `CiudadPlaza`: solo llevaba piel de fachada por delante, por detrás una caja lisa | `MuroCivico.vestir` en ese volumen | `capturas_ciudad_c2/pasada2_centro_plaza_mayor_aerea_{antes,despues}.jpg` |
| Parcelas industriales | Muy vacías y sin marcas | Hilera de 9 plazas de aparcamiento (blancas) y línea amarilla de carga por parcela, en los MultiMesh de detalles por celda (`_lote_det`: sin llamadas nuevas) | `capturas_ciudad_c2/pasada2_barrio_industrial_aerea_{antes,despues}.jpg` |

Calidad MÍNIMA: `medir_prologo` 1 112 llamadas (antes de la pasada 1 153, tras la pasada 1 1 120): no sube.

## Visto y no cambiado
- Matas de hierba grandes y aisladas en los parques y el césped de las casas: son el pasto del Drive del dueño (`PastoCiudad`, licencia confirmada, 7-8 mil triángulos cada una); no se toca sin su OK. Si se quiere menos «aislado»: subir `AZAR_INTERIOR` o bajar `DISTANCIA` (decisión del dueño).
- Las marcas de patio industrial quedan en la franja de las naves (sur); el centro de cada parcela sigue vacío. Rellenarlo del todo (camiones, palés, grúas) sumaría piezas; en MÍNIMA habría que contar llamadas.
- Plaza mayor y ayuntamiento a pie: aún se ven muy de cerca del muro; la plaza a pie necesita una posición propia (de pie en una esquina, no centrada en la zona).
