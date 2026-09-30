# Auditoría de caras reales

Generado por `herramientas/auditoria_caras.py`. Automático: marca lo que se sale de lo
razonable para mirarlo en las hojas de lotes (`pruebas/captura_lote_caras.gd`).

- Jugadores con cara 3D: **1133** de 1146 (recreación: 13).
- Sin ninguna marca: **964**.

## Revisión a ojo (30-9-2026, las 96 hojas de 12 jugadores)

Hecha mirando cada hoja (`pruebas/captura_lote_caras.gd`, luz de retrato). Estimación
honesta, no una medida: en una muestra de ~190 jugadores contados uno a uno,
**≈85 % se ven bien** (tono de piel y ojos creíbles y parecidos a la foto) y **≈15 %
tienen un problema visible**:

- **Tono más oscuro que el real (≈7 %)**: la cara estaba en sombra dentro de una foto
  bien expuesta (p. ej. Ben White, Benjamin André, Benjamin Šeško, Benjamin Lecomte,
  Robert Lewandowski). Con una sola foto no se distingue de una piel morena; el
  auto-niveles solo corrige las fotos oscuras enteras (Pavard quedó bien).
- **Manchas de la foto (≈5 %)**: brillos, sombras duras o mala resolución que
  sobreviven a la piel replicada (Óscar de Marcos, Álvaro Vadillo, Rani Khedira,
  Alex Valera, Eric Ramírez).
- **Forma rara (≈3 %)**: fotos muy de lado o con la boca muy abierta.

Además, en TODOS: el peinado es todavía el genérico (paso 2, pendiente por orden del
usuario) y la barba/cejas vienen de la textura, no en 3D.

Corregido durante la revisión: pieles claras rojas o quemadas, pieles claras en fotos
oscuras (auto-niveles), iris negros o amarillos, pelo azul/verde (cielo o césped),
calvas de más.

## Marcas por tipo

- foto muy de lado: 147
- sin pelo medido: 15
- recreación: 13
- cara tapada en la foto: 9
- pelo muy alto: 1

## Por jugador

- **Aaron Martín**: foto muy de lado: 56°
- **Adam Wharton**: foto muy de lado: -55°
- **Adrien Rabiot**: foto muy de lado: 45°
- **Adrien Tameze**: recreación: foto inservible para 3D (giro -58.0, cabeceo -56.7)
- **Adrien Thomasson**: foto muy de lado: -55°
- **Adrián Mora**: recreación: foto inservible para 3D (giro 39.6, cabeceo -40.5)
- **Agustín Bouzat**: foto muy de lado: 46°
- **Aihen Muñoz**: foto muy de lado: -41°
- **Ainsley Maitland-Niles**: foto muy de lado: 41°
- **Albert Guðmundsson**: recreación: foto inservible para 3D (giro -12.5, cabeceo -39.7)
- **Alex Iwobi**: foto muy de lado: -43°
- **Alex Valera**: foto muy de lado: -42°
- **Alexsandro**: foto muy de lado: -55°
- **Angeliño**: foto muy de lado: 48°
- **Angelo Rodríguez**: foto muy de lado: -60°
- **Anton Stach**: cara tapada en la foto: 17%
- **Arnaud Kalimuendo**: foto muy de lado: -48°
- **Artem Dovbyk**: foto muy de lado: -50°
- **Atakan Karazor**: foto muy de lado: -50°
- **Augusto Batalla**: foto muy de lado: 47°
- **Bamo Meïté**: sin pelo medido
- **Ben White**: foto muy de lado: 45°
- **Benjamin André**: foto muy de lado: -45°
- **Benjamín Chandía**: foto muy de lado: -41°
- **Berat Djimsiti**: foto muy de lado: -44°
- **Brad Guzan**: sin pelo medido
- **Bryan Carvallo**: cara tapada en la foto: 20%
- **Callum Hudson-Odoi**: foto muy de lado: 48°
- **Chris Durkin**: foto muy de lado: -52°
- **Christopher Jullien**: foto muy de lado: -51°
- **Corentin Tolisso**: recreación: foto inservible para 3D (giro 62.4, cabeceo -12.6)
- **Cristhian Mosquera**: foto muy de lado: -49°
- **Cristián Zavala**: foto muy de lado: -57°
- **Cucho Hernández**: cara tapada en la foto: 23%
- **Daniel Muñoz**: cara tapada en la foto: 27%
- **Dante**: foto muy de lado: 47°
- **Destiny Udogie**: foto muy de lado: -41°
- **Diego Campos**: foto muy de lado: 58°
- **Diego Chará**: foto muy de lado: -51°
- **Djibril Sidibé**: foto muy de lado: 45°
- **Duván Vergara**: foto muy de lado: -62°
- **Dušan Vlahović**: recreación: foto inservible para 3D (giro -64.5, cabeceo -11.9)
- **Edmond Tapsoba**: foto muy de lado: -46°
- **Elías Hernández**: recreación: foto inservible para 3D (giro -28.4, cabeceo -41.7)
- **Emanuel Herrera**: foto muy de lado: 43°
- **Emile Smith Rowe**: foto muy de lado: 42°
- **Emiliano Martínez**: foto muy de lado: -41°
- **Eric Ramírez**: cara tapada en la foto: 18%
- **Eric Remedi**: foto muy de lado: 58°
- **Esteban Pavez**: foto muy de lado: 42°
- **Estêvão**: foto muy de lado: 54°
- **Fafà Picault**: foto muy de lado: -41°
- **Federico Mateos**: foto muy de lado: 40°
- **Felipe Mora**: foto muy de lado: -43°
- **Felix Passlack**: foto muy de lado: 42°
- **Fernando Beltrán**: foto muy de lado: -42°
- **Fernando Gaibor**: foto muy de lado: -55°
- **Fernando de Paul**: foto muy de lado: 44°
- **Florian Thauvin**: foto muy de lado: -58°
- **Franco Mastantuono**: recreación: foto inservible para 3D (giro 1.1, cabeceo -41.8)
- **Frederik Rönnow**: foto muy de lado: 48°
- **Gerard Moreno**: foto muy de lado: -51°
- **Gianluca Mancini**: foto muy de lado: 61°
- **Giorgi Mamardashvili**: foto muy de lado: -56°
- **Giovanni Fabbian**: foto muy de lado: 41°
- **Gonzalo Valle**: foto muy de lado: -44°
- **Guido Carrillo**: foto muy de lado: 43°
- **Guilherme**: foto muy de lado: -56°
- **Guzmán Rodríguez**: foto muy de lado: -59°
- **Hugo Ekitiké**: foto muy de lado: 43°
- **Hugo Fernández**: foto muy de lado: 41°
- **Hugo Larsson**: foto muy de lado: 60°
- **Hugo Souza**: sin pelo medido
- **Igor Jesus**: foto muy de lado: 54°
- **Iliman Ndiaye**: foto muy de lado: -46°
- **Irven Ávila**: foto muy de lado: 46°
- **Isak Hien**: foto muy de lado: -53°
- **James Maddison**: foto muy de lado: -59°
- **James Pantemis**: foto muy de lado: -49°
- **James Tarkowski**: foto muy de lado: 61°
- **Janik Haberer**: foto muy de lado: -44°
- **Jarrod Bowen**: foto muy de lado: 42°
- **Jean-Charles Castelletto**: sin pelo medido; foto muy de lado: 42°
- **Jean-Clair Todibo**: foto muy de lado: -41°
- **Jean-Philippe Mateta**: sin pelo medido
- **Jeff Chabot**: foto muy de lado: 44°
- **Jesús Gallardo**: foto muy de lado: 48°
- **Johann Lepenant**: foto muy de lado: 52°
- **John Kennedy**: recreación: foto inservible para 3D (giro 6.8, cabeceo -8.7)
- **José Enamorado**: foto muy de lado: 49°
- **João Neves**: foto muy de lado: -45°
- **Juan Cornejo**: foto muy de lado: -46°
- **Junior Alonso**: foto muy de lado: 60°
- **Jérémy Jacquet**: foto muy de lado: -49°
- **Kamory Doumbia**: cara tapada en la foto: 17%; sin pelo medido
- **Keito Nakamura**: foto muy de lado: 43°
- **Lameck Banda**: pelo muy alto (¿mal medido?): 14.1
- **Lassine Sinayoko**: sin pelo medido
- **Leonardo Gil**: foto muy de lado: 41°
- **Lorenz Assignon**: foto muy de lado: -44°
- **Loïs Openda**: sin pelo medido
- **Luca Waldschmidt**: foto muy de lado: 53°
- **Lucas Assadi**: foto muy de lado: 47°
- **Lucas Cavallini**: foto muy de lado: -50°
- **Lucas Hernández**: foto muy de lado: 46°
- **Lucas Moura**: foto muy de lado: 46°
- **Lucas Romero**: foto muy de lado: 54°
- **Ludovic Blas**: foto muy de lado: -49°
- **Luis Cangá**: recreación: foto inservible para 3D (giro -69.0, cabeceo -57.9)
- **Luis Mejía**: sin pelo medido
- **Lukasz Skorupski**: foto muy de lado: -48°
- **Mahdi Camara**: foto muy de lado: 44°
- **Manuel Locatelli**: foto muy de lado: 49°
- **Mario Gila**: foto muy de lado: -42°
- **Marius Wolf**: foto muy de lado: 48°
- **Marlon**: sin pelo medido
- **Matthijs de Ligt**: foto muy de lado: 48°
- **Mattias Svanberg**: foto muy de lado: 42°
- **Matías Cóccaro**: foto muy de lado: -42°
- **Matías Di Benedetto**: foto muy de lado: -50°
- **Matías Palavecino**: foto muy de lado: 61°
- **Matías Sepúlveda**: foto muy de lado: -41°
- **Matías Zaldivia**: foto muy de lado: -41°
- **Miguel Borja**: foto muy de lado: -47°
- **Miguel Navarro**: foto muy de lado: -42°
- **Mikayil Faye**: cara tapada en la foto: 12%; sin pelo medido
- **Morten Frendrup**: foto muy de lado: -54°
- **Moussa Niakhaté**: foto muy de lado: -47°
- **Myrto Uzuni**: foto muy de lado: 43°
- **Nicolás Castillo**: foto muy de lado: -43°
- **Nicolò Rovella**: foto muy de lado: -43°
- **Noah Atubolu**: foto muy de lado: -47°
- **Noussair Mazraoui**: sin pelo medido
- **Néstor Camacho**: recreación: foto inservible para 3D (giro 63.8, cabeceo -10.6)
- **Oihan Sancet**: foto muy de lado: 41°
- **Oussama Idrissi**: foto muy de lado: -48°
- **Pablo Barrera**: foto muy de lado: -42°
- **Patricio Rubio**: foto muy de lado: -54°
- **Patrick Agyemang**: sin pelo medido
- **Paulo Gazzaniga**: foto muy de lado: -51°
- **Pervis Estupiñán**: foto muy de lado: 44°
- **Philipp Köhn**: foto muy de lado: 42°
- **Piotr Zieliński**: foto muy de lado: -48°
- **Péter Gulácsi**: foto muy de lado: 41°
- **Rafael Carioca**: foto muy de lado: -40°
- **Rafael Gava**: foto muy de lado: -44°
- **Raúl Rangel**: foto muy de lado: 61°
- **Riccardo Orsolini**: cara tapada en la foto: 31%
- **Riqui Puig**: foto muy de lado: 41°
- **Robert Lewandowski**: foto muy de lado: -44°
- **Robert Mejía**: foto muy de lado: 46°
- **Robert Sánchez**: foto muy de lado: -45°
- **Romelu Lukaku**: sin pelo medido
- **Ronald Araújo**: foto muy de lado: -60°
- **Ronald Hernández**: foto muy de lado: -48°
- **Sebastián Cáceres**: recreación: foto inservible para 3D (giro -65.8, cabeceo -14.0)
- **Serge Gnabry**: recreación: foto inservible para 3D (giro -70.4, cabeceo 21.9)
- **Sergio Canales**: foto muy de lado: 54°
- **Sergio Peña**: foto muy de lado: -59°
- **Shavy Babicka**: foto muy de lado: 58°
- **Stefan Bell**: foto muy de lado: 43°
- **Stefan Medina**: foto muy de lado: 43°
- **Stefano Turati**: foto muy de lado: 46°
- **Stian Gregersen**: foto muy de lado: 47°
- **Tadeu**: cara tapada en la foto: 20%
- **Thiago Martins**: foto muy de lado: -62°
- **Thilo Kehrer**: foto muy de lado: -48°
- **Tom Louchet**: foto muy de lado: -54°
- **Tomás Ahumada**: foto muy de lado: -53°
- **Vanja Milinkovic-Savic**: sin pelo medido
- **Will Hughes**: foto muy de lado: 46°
- **Willi Orbán**: foto muy de lado: 40°
- **Yehvann Diouf**: foto muy de lado: -57°
- **Yerko Leiva**: foto muy de lado: -43°
- **Yoel Bárcenas**: foto muy de lado: 50°
- **Youssouf Ndayishimiye**: foto muy de lado: -41°
- **Yuri Berchiche**: recreación: foto inservible para 3D (giro -62.7, cabeceo -8.8)
- **Álex Valera**: foto muy de lado: -42°
- **Álvaro Fernández**: foto muy de lado: -61°
- **Ángelo Rodríguez**: foto muy de lado: -60°
- **Óscar Opazo**: foto muy de lado: -56°
- **Ørjan Nyland**: foto muy de lado: -43°
