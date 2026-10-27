extends "res://ui/principal_p7.gd"
## [Capa 8/17 de `principal.gd`] _jugador_de_la_semana (y el puente de `_ver_ficha` a `PantallaFicha`)

## Puente (fase 6, paso 7): la ficha del jugador la pinta `PantallaFicha`.
func _ver_ficha(j: Jugador) -> void: _ui_ficha._ver_ficha(j)

## A quién enseña la ficha cuando no has elegido a nadie.
##
## Antes se quedaba vacía o clavada en el mismo jugador semana tras semana, y un
## plantel de veinticuatro se convertía en uno. Rotar por rotar tampoco sirve:
## lo que se enseña es a quien tiene ALGO que contar esta semana, y solo si no
## hay nadie así se pasa el turno por la plantilla.
func _jugador_de_la_semana(c: Club) -> Jugador:
	if c.plantilla.is_empty():
		return null
	## 1 · El que está roto: es lo primero que uno querría saber al abrir.
	for j in c.plantilla:
		if j.lesion > 0:
			return j
	## 2 · El que está en racha: mejor nota media de las tres últimas, y solo si
	## de verdad ha jugado.
	var mejor: Jugador = null
	var mejor_nota := 6.8
	for j in c.plantilla:
		if j.notas.size() < 3:
			continue
		var ultimas := j.notas.slice(maxi(0, j.notas.size() - 3))
		var s := 0.0
		for x in ultimas:
			s += float(x)
		var media := s / float(ultimas.size())
		if media > mejor_nota:
			mejor_nota = media
			mejor = j
	if mejor != null:
		return mejor
	## 3 · Y si no hay noticia, el turno rota con la semana: cada una le toca a
	## uno distinto, y en un año pasan todos por la ficha.
	return c.plantilla[(mundo.semana + mundo.anio) % c.plantilla.size()]
