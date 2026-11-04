# Pasada visual de la ciudad n.º 3 (4-11-2026) — transporte, estadio por fuera, centro de las parcelas industriales
Mismo método (`pruebas/captura_pasada_ciudad.tscn`, Forward+, MEDIA, 13:00).

## Revisado
- **Transporte** (paradero, viaducto del metro): sin cambios necesarios. Las pilas del viaducto, la escalera de acceso, el paradero «Red» con su poste y los buses se leen bien; el asfalto y las marcas viales están coherentes con el resto.
- **Estadio por fuera**: vallado perimetral, gente sobre el césped exterior y terminal de buses coherentes; el corte diagonal del campo es la sombra de la grada. Sin cambios.
- Parcela marrón sin construir junto a la terminal: es el solar a la venta (terreno del club), intencionado.

## Cambio
| Zona | Cambio | Antes / después |
|---|---|---|
| Parcelas industriales (centro) | Tres pilas de palés con cajas azules y grises (3×2 palés por pila, 1-2 cajas de alto) en los MultiMesh de detalles por celda. **Solo en MEDIA o más**: en MÍNIMA `CiudadIndustrial.patio_central` no hace nada. | `capturas_ciudad_c2/pasada3_barrio_industrial_aerea_{antes,despues}.jpg` |

Calidad MÍNIMA: `medir_prologo` 1 120 llamadas (sin cambio; el patio no se monta).

## Pendiente
- El centro de la parcela sigue siendo mayormente asfalto vacío; las pilas ocupan la franja norte del centro. Más relleno (camiones, grúas) sumaría piezas.
