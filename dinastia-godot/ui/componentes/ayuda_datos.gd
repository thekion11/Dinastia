class_name AyudaDatos
extends RefCounted
## LA AYUDA DE LAS FILAS DE DATOS (2-11-2026, M-305). `PiezasUI._dato` ponía de ayuda el mismo rótulo; con esta
## tabla, los datos del club que no se entienden solos explican qué son y qué los mueve. El rótulo es la clave
## (en castellano, como se escribe en el código); lo que no está aquí sigue con el rótulo de ayuda.

const TEXTOS := {
	"Socios": "Pagan cuota todo el año: ingreso fijo y voto en la asamblea. Suben con títulos, buen juego y precios justos.",
	"Abonados": "Tienen la entrada de toda la temporada: llenan el estadio aunque el equipo vaya mal.",
	"Ánimo de la hinchada": "Cómo está la grada. Alto empuja al equipo en casa; bajo trae pitos, menos público y presión a la directiva.",
	"Presión en redes (funa)": "Lo que se dice del club en redes. Si sube mucho, la prensa y la directiva te aprietan.",
	"Fair play de la hinchada": "El comportamiento de tu grada. Si baja, llegan multas y cierres parciales del estadio.",
	"Días del hincha organizados": "Jornadas de puertas abiertas: suben el ánimo y los socios.",
	"Taquilla por partido": "Lo que deja un partido en casa con el precio de entrada actual, ya descontado el día de partido.",
	"Sueldos del plantel": "Lo que pagas cada mes a la plantilla. Si se come la caja, la directiva lo nota.",
	"Valor de tasación": "Lo que vale en el mercado hoy: sube con la media, la juventud y los años de contrato.",
	"Récord de público": "La mejor entrada de la historia del club en su estadio.",
	"Riesgo de incidente por partido en casa": "Probabilidad de bengalas, peleas o invasión en tu estadio: depende del ánimo, el rival y la seguridad.",
	"Relación con los vecinos": "Cómo te ven los vecinos del estadio. Baja con ruido y obras; alta facilita los permisos.",
	"Subvención estimada al cierre": "La ayuda pública que llegaría al cerrar la temporada, según la postura del gobierno y tu relación con él.",
	"Resultado del ejercicio": "Ingresos menos gastos de la temporada. En negativo seguido, el banco y la directiva se preocupan.",
	"Reparto votado en la asamblea": "Cómo decidió la asamblea repartir el dinero: fichajes, cantera, estadio o deuda.",
	"Profesionalidad": "Cómo se cuida fuera del campo: entrena mejor, se lesiona menos y da menos problemas.",
	"Tensión": "La rivalidad con ese entrenador. Desde 80, los cruces se calientan: declaraciones, tarjetas y partidos más duros.",
	"Riesgo declarado": "Lo que dice el médico de su historial y su físico: alto significa que puede romperse si se le exige.",
	"Peso político en la asamblea": "Aliados que votan contigo en la federación: pesan en sanciones, calendarios y repartos.",
	"Apelaciones perdidas acumuladas": "Recursos que perdiste ante la federación: si se acumulan, apelar sale más caro y pesa menos.",
	"Techo retráctil": "Se cierra con mal tiempo: la gente no se queda en casa por la lluvia o el frío.",
}

static func de(etiqueta: String) -> String:
	var t := String(TEXTOS.get(etiqueta, ""))
	return Idiomas.t(t) if t != "" else etiqueta
