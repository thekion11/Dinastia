# Días de memoria por país (17-11-2026)

Orden del dueño: «busca en Wikipedia los importantes de todos los países». Método: se bajó el texto de las páginas «Public holidays in…» de
Wikipedia (inglés) de los 123 países que no tenían ninguna fecha de memoria, se filtraron las líneas con *remembrance, memorial, martyrs,
victims, fallen, genocide, uprising…* y se cruzaron con lo que cada país tiene por ley o por costumbre. Resultado: `nucleo/calendario_memorias.gd`
(59 países, 67 fechas; antes 12 países). Cada una abre la pantalla de reflexión (`DiasMemoria`, `EventoReflexion`) la semana en que cae.

- **Confirmadas con la página de Wikipedia**: ARM, AZE, BLR, CPV, CRO, EST, GEO, HUN, KAZ, LBN, LBY, MAD, MLI, MLT, MOZ, NAM, PAN, PHI, POL, ROU, RUS, SRB, SYR, TUN, TUR, UKR, UZB, VIE, ZIM, SGP, CHN.
- **De conocimiento general, sin página que las confirme en esta pasada** (revisar si se quiere certeza): AUT 5-5, BEL 11-11, BIH 11-7, BUL 2-6, CAN 11-11, COL 9-4, DEN 9-4, GRE 17-11, GUA 25-2, IND 30-1, IDN 10-11, ITA 27-1, JPN 15-8 y 11-3, KOR 3-4 y 18-5, LTU 13-1, LVA 25-3, MEX 13-9 y 2-10, NED 4-5, NGA 15-1, NOR 22-7, NZL 25-4, SVK 9-9, UAE 30-11, URU 20-5, SCO/WAL/NIR 11-11.
- **Fuera a propósito**: fechas del calendario hebreo o islámico (Israel: Yom HaShoah y Yom HaZikaron; Ashura, Eid), fechas muy disputadas (Chipre, Palestina, Azerbaiyán-Joyalí, Kosovo), aniversarios de reyes o presidentes sin duelo nacional (Tailandia) y países cuyas páginas de Wikipedia no listan ningún día de recuerdo (Brasil, Ecuador, Bolivia, Perú, Portugal, Suiza, Suecia, Irlanda…; Brasil, Perú y Ecuador se pueden añadir si el dueño da el día).
- **Móviles**: Zimbabue (segundo lunes de agosto) y Ucrania-Holodomor (cuarto sábado de noviembre) se calculan cada año (día negativo en la tabla).
- Traducciones: 119 textos × 8 idiomas con `sumar_traducciones.py`; redactadas sin revisión nativa (revisar, sobre todo ca, pl, tr).
