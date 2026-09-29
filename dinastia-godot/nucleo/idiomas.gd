extends Node
## (Sin `class_name`: este script ES el autoload `Idiomas`.)
## LOS IDIOMAS DE LA INTERFAZ. Siete: castellano, inglés, portugués de Brasil,
## francés, italiano, alemán y catalán.
##
## CÓMO FUNCIONA, Y POR QUÉ ASÍ. Lo normal en Godot es marcar cada cadena con
## `tr("CLAVE")` y llevar un CSV de claves. Aquí eso costaba tocar más de dos mil
## sitios en `ui/principal.gd` —un archivo de diez mil líneas— y cada uno era una
## oportunidad de romper algo que ya funcionaba.
##
## Lo que se hace en cambio es traducir DESPUÉS de pintar: la interfaz se dibuja
## en castellano como siempre, y al final de cada repintado se recorre el árbol y
## se cambia el texto de las etiquetas y los botones que estén en la tabla. La
## clave ES la frase en castellano.
##
## Las tres consecuencias buenas de hacerlo así:
##  - Añadir un idioma es añadir una columna. No se toca ni una pantalla.
##  - Lo que no esté traducido sigue leyéndose, en castellano, en vez de aparecer
##    como `MENU_SAVE_BTN` que es lo que pasa cuando falta una clave.
##  - Ninguna lógica depende de esto. Las pestañas se siguen buscando por su
##    nombre castellano (`_ir_a_pestana("Táctica")`), los `match` del motor
##    siguen comparando cadenas castellanas, y el guardado no cambia. Traducir
##    es solo lo último que se hace antes de enseñar la pantalla.
##
## POR QUÉ ESTOS SEIS Y NO CHINO O JAPONÉS. Por la fuente. La tipografía que
## Godot trae dentro cubre el alfabeto latino con sus acentos y diéresis, pero no
## los ideogramas: un juego en japonés se vería como una pantalla de cuadraditos.
## Añadirlos exige empaquetar una fuente CJK —varios megas— y es una decisión
## aparte, no una columna más en esta tabla.
##
## LO QUE NO SE TRADUCE, Y SE DICE CLARO. La narración —las noticias, las
## preguntas de la prensa, los diálogos del vestuario, los textos de ayuda
## largos— sigue en castellano. Son varios miles de frases escritas con voz
## propia, muchas armadas por trozos con nombres dentro, y traducirlas a medias
## quedaría peor que no traducirlas. Lo que sí está entero es el ESQUELETO:
## menús, pestañas, botones, títulos de sección, ajustes y etiquetas de datos,
## que es lo que hace falta para orientarse.

const ORDEN := ["en", "pt", "fr", "it", "de", "ca"]

## clave -> [nombre en su propio idioma, bandera]
const NOMBRES := {
	"es": ["Español", "🇪🇸"],
	"en": ["English", "🇬🇧"],
	"pt": ["Português (BR)", "🇧🇷"],
	"fr": ["Français", "🇫🇷"],
	"it": ["Italiano", "🇮🇹"],
	"de": ["Deutsch", "🇩🇪"],
	"ca": ["Català", "🏴"],
}

var idioma := "es"

## clave castellana -> [en, pt, fr, it, de, ca]
const TABLA := {
	# --- grupos y pestañas ---
	"Club": ["Club", "Clube", "Club", "Club", "Verein", "Club"],
	"Plantel": ["Squad", "Elenco", "Effectif", "Rosa", "Kader", "Plantilla"],
	"Partido": ["Match", "Partida", "Match", "Partita", "Spiel", "Partit"],
	"Finanzas": ["Finances", "Finanças", "Finances", "Finanze", "Finanzen", "Finances"],
	"Mundo": ["World", "Mundo", "Monde", "Mondo", "Welt", "Món"],
	"Ajustes": ["Settings", "Ajustes", "Réglages", "Impostazioni", "Einstellungen", "Ajustos"],
	"Inicio": ["Home", "Início", "Accueil", "Home", "Start", "Inici"],
	"Estadio": ["Stadium", "Estádio", "Stade", "Stadio", "Stadion", "Estadi"],
	"Ciudad": ["City", "Cidade", "Ville", "Città", "Stadt", "Ciutat"],
	"Gente": ["People", "Pessoas", "Personnel", "Persone", "Leute", "Gent"],
	"Comparar": ["Compare", "Comparar", "Comparer", "Confronta", "Vergleichen", "Comparar"],
	"Récords": ["Records", "Recordes", "Records", "Record", "Rekorde", "Rècords"],
	"Logros": ["Achievements", "Conquistas", "Succès", "Obiettivi", "Erfolge", "Assoliments"],
	"Premios": ["Awards", "Prêmios", "Trophées", "Premi", "Auszeichnungen", "Premis"],
	"Legado": ["Legacy", "Legado", "Héritage", "Eredità", "Vermächtnis", "Llegat"],
	"Mi plantel": ["My squad", "Meu elenco", "Mon effectif", "La mia rosa", "Mein Kader", "La meva plantilla"],
	"Táctica": ["Tactics", "Tática", "Tactique", "Tattica", "Taktik", "Tàctica"],
	"Entrenar": ["Training", "Treino", "Entraînement", "Allenamento", "Training", "Entrenar"],
	"Enfermería": ["Medical", "Enfermaria", "Infirmerie", "Infermeria", "Medizin", "Infermeria"],
	"Camarín": ["Dressing room", "Vestiário", "Vestiaire", "Spogliatoio", "Kabine", "Vestidor"],
	"Cantera": ["Academy", "Base", "Centre de formation", "Vivaio", "Nachwuchs", "Planter"],
	"Contratos": ["Contracts", "Contratos", "Contrats", "Contratti", "Verträge", "Contractes"],
	"Mercado": ["Transfers", "Mercado", "Transferts", "Mercato", "Transfers", "Mercat"],
	"Libres": ["Free agents", "Livres", "Agents libres", "Svincolati", "Ablösefrei", "Lliures"],
	"Clubes": ["Clubs", "Clubes", "Clubs", "Club", "Vereine", "Clubs"],
	"Copa": ["Cup", "Copa", "Coupe", "Coppa", "Pokal", "Copa"],
	"Continental": ["Continental", "Continental", "Continentale", "Continentale", "Kontinental", "Continental"],
	"Selección": ["National team", "Seleção", "Sélection", "Nazionale", "Nationalelf", "Selecció"],
	"Federación": ["Federation", "Federação", "Fédération", "Federazione", "Verband", "Federació"],
	"Correo": ["Inbox", "Correio", "Messagerie", "Posta", "Postfach", "Correu"],
	"Redes": ["Social", "Redes", "Réseaux", "Social", "Netzwerke", "Xarxes"],
	"Desafíos": ["Challenges", "Desafios", "Défis", "Sfide", "Herausforderungen", "Reptes"],
	"Editor": ["Editor", "Editor", "Éditeur", "Editor", "Editor", "Editor"],
	"Glosario": ["Glossary", "Glossário", "Glossaire", "Glossario", "Glossar", "Glossari"],

	# --- barra de acciones ---
	"Dirigir el partido": ["Manage match", "Dirigir jogo", "Diriger le match", "Dirigi partita", "Spiel leiten", "Dirigir partit"],
	"▶ Dirigir el partido": ["▶ Manage match", "▶ Dirigir jogo", "▶ Diriger le match", "▶ Dirigi partita", "▶ Spiel leiten", "▶ Dirigir partit"],
	"Avanzar semana": ["Next week", "Avançar semana", "Semaine suivante", "Settimana avanti", "Nächste Woche", "Avançar setmana"],
	"Jugar la temporada": ["Play season", "Jogar temporada", "Jouer la saison", "Gioca stagione", "Saison spielen", "Jugar temporada"],
	"Temporada siguiente": ["Next season", "Próxima temp.", "Saison suivante", "Prossima stag.", "Nächste Saison", "Temporada seg."],
	"Guardar": ["Save", "Salvar", "Sauvegarder", "Salva", "Speichern", "Desar"],
	"Cargar": ["Load", "Carregar", "Charger", "Carica", "Laden", "Carregar"],
	"Otro mundo": ["New world", "Outro mundo", "Autre monde", "Altro mondo", "Neue Welt", "Un altre món"],
	"Ver la competición  ▸": ["View competition  ▸", "Ver a competição  ▸", "Voir la compétition  ▸", "Vedi la competizione  ▸", "Wettbewerb ansehen  ▸", "Veure la competició  ▸"],

	# --- botones corrientes ---
	"Aceptar": ["Accept", "Aceitar", "Accepter", "Accetta", "Annehmen", "Acceptar"],
	"Rechazar": ["Decline", "Recusar", "Refuser", "Rifiuta", "Ablehnen", "Rebutjar"],
	"Cerrar": ["Close", "Fechar", "Fermer", "Chiudi", "Schließen", "Tancar"],
	"Elegir": ["Choose", "Escolher", "Choisir", "Scegli", "Wählen", "Triar"],
	"Elegido": ["Chosen", "Escolhido", "Choisi", "Scelto", "Gewählt", "Triat"],
	"Firmar": ["Sign", "Assinar", "Signer", "Firma", "Unterschreiben", "Signar"],
	"Firmado": ["Signed", "Assinado", "Signé", "Firmato", "Unterschrieben", "Signat"],
	"Renovar": ["Renew", "Renovar", "Prolonger", "Rinnova", "Verlängern", "Renovar"],
	"Retirar": ["Withdraw", "Retirar", "Retirer", "Ritira", "Zurückziehen", "Retirar"],
	"Romper": ["Break off", "Romper", "Rompre", "Rompi", "Abbrechen", "Trencar"],
	"Nombrar": ["Appoint", "Nomear", "Nommer", "Nomina", "Ernennen", "Nomenar"],
	"Cesar": ["Dismiss", "Demitir", "Limoger", "Esonera", "Entlassen", "Destituir"],
	"Apelar": ["Appeal", "Recorrer", "Faire appel", "Ricorri", "Berufung", "Apel·lar"],
	"Atender": ["Attend", "Atender", "Recevoir", "Ricevi", "Empfangen", "Atendre"],
	"Aprender": ["Learn", "Aprender", "Apprendre", "Impara", "Lernen", "Aprendre"],
	"Blindar": ["Lock in", "Blindar", "Sécuriser", "Blinda", "Absichern", "Blindar"],
	"Emparejar": ["Match up", "Emparelhar", "Apparier", "Abbina", "Zuordnen", "Aparellar"],
	"Exportar": ["Export", "Exportar", "Exporter", "Esporta", "Exportieren", "Exportar"],
	"📥 Importar": ["📥 Import", "📥 Importar", "📥 Importer", "📥 Importa", "📥 Importieren", "📥 Importar"],
	"Vaciar": ["Clear", "Limpar", "Vider", "Svuota", "Leeren", "Buidar"],
	"Tomar": ["Take over", "Assumir", "Prendre en main", "Assumi", "Übernehmen", "Assumir"],
	"Tuyo": ["Yours", "Seu", "Le vôtre", "Tuo", "Deiner", "Teu"],
	"Todos": ["All", "Todos", "Tous", "Tutti", "Alle", "Tots"],
	"Titular": ["Starter", "Titular", "Titulaire", "Titolare", "Stammspieler", "Titular"],
	"Puesto": ["Position", "Posição", "Poste", "Ruolo", "Position", "Posició"],
	"Pedido": ["Requested", "Pedido", "Demandé", "Richiesto", "Angefragt", "Demanat"],
	"Operando": ["Operating", "Operando", "En activité", "In attività", "In Betrieb", "Operant"],
	"Terapia": ["Therapy", "Terapia", "Thérapie", "Terapia", "Therapie", "Teràpia"],
	"Enviar oferta": ["Send offer", "Enviar oferta", "Envoyer une offre", "Invia offerta", "Angebot senden", "Enviar oferta"],
	"Ofrecer contrato": ["Offer contract", "Oferecer contrato", "Proposer un contrat", "Offri contratto", "Vertrag anbieten", "Oferir contracte"],
	"Ofrecer lo que piden": ["Offer what they ask", "Oferecer o que pedem", "Offrir ce qu'ils demandent", "Offri quanto chiedono", "Bieten, was sie fordern", "Oferir el que demanen"],
	"Solo lo que puedo pagar": ["Only what I can afford", "Só o que posso pagar", "Seulement ce que je peux payer", "Solo quanto posso permettermi", "Nur was ich zahlen kann", "Només el que puc pagar"],
	"Negociar en la mesa": ["Negotiate at the table", "Negociar na mesa", "Négocier à la table", "Tratta al tavolo", "Am Tisch verhandeln", "Negociar a la taula"],
	"Escuchar ofertas por el nombre": ["Listen to naming offers", "Ouvir ofertas pelo nome", "Écouter les offres de naming", "Ascolta offerte per il nome", "Namensrechte anhören", "Escoltar ofertes pel nom"],
	"Poner en venta": ["List for sale", "Colocar à venda", "Mettre en vente", "Metti in vendita", "Zum Verkauf stellen", "Posar a la venda"],
	"Ceder a préstamo": ["Send on loan", "Emprestar", "Prêter", "Manda in prestito", "Ausleihen", "Cedir en préstec"],
	"Con obligación": ["With obligation", "Com obrigação", "Avec obligation", "Con obbligo", "Mit Kaufpflicht", "Amb obligació"],
	"Con opción": ["With option", "Com opção", "Avec option", "Con opzione", "Mit Kaufoption", "Amb opció"],
	"Quitar del comparador": ["Remove from comparison", "Tirar do comparador", "Retirer du comparateur", "Togli dal confronto", "Aus Vergleich nehmen", "Treure del comparador"],
	"Vaciar comparador": ["Clear comparison", "Limpar comparador", "Vider le comparateur", "Svuota confronto", "Vergleich leeren", "Buidar comparador"],
	"Quitar al portavoz": ["Remove spokesperson", "Tirar o porta-voz", "Retirer le porte-parole", "Togli il portavoce", "Sprecher absetzen", "Treure el portaveu"],
	"Deshacer la última decisión": ["Undo last decision", "Desfazer a última decisão", "Annuler la dernière décision", "Annulla l'ultima decisione", "Letzte Entscheidung rückgängig", "Desfer l'última decisió"],
	"Que lo arme el ayudante": ["Let the assistant set it up", "Deixar o auxiliar montar", "Laisser l'adjoint s'en charger", "Lascia fare al vice", "Assistent aufstellen lassen", "Que ho munti l'ajudant"],
	"Rotación automática": ["Automatic rotation", "Rodízio automático", "Rotation automatique", "Rotazione automatica", "Automatische Rotation", "Rotació automàtica"],
	"Descanso mental": ["Mental rest", "Descanso mental", "Repos mental", "Riposo mentale", "Mentale Pause", "Descans mental"],
	"Abstenerse": ["Abstain", "Abster-se", "S'abstenir", "Astieniti", "Enthalten", "Abstenir-se"],
	"A favor": ["In favour", "A favor", "Pour", "A favore", "Dafür", "A favor"],
	"En contra": ["Against", "Contra", "Contre", "Contro", "Dagegen", "En contra"],
	"Hacer esto": ["Do this", "Fazer isto", "Faire ceci", "Fai questo", "Das tun", "Fer això"],
	"Emitir bono social": ["Issue social bond", "Emitir título social", "Émettre une obligation sociale", "Emetti obbligazione sociale", "Sozialanleihe ausgeben", "Emetre bo social"],
	"Bono de productividad": ["Productivity bonus", "Bônus de produtividade", "Prime de rendement", "Bonus produttività", "Leistungsprämie", "Bo de productivitat"],
	"Precios dinámicos": ["Dynamic pricing", "Preços dinâmicos", "Tarification dynamique", "Prezzi dinamici", "Dynamische Preise", "Preus dinàmics"],
	"✅ Marcar todo como leído": ["✅ Mark all as read", "✅ Marcar tudo como lido", "✅ Tout marquer comme lu", "✅ Segna tutto come letto", "✅ Alles als gelesen markieren", "✅ Marcar-ho tot com a llegit"],
	"👁️ Dejar de seguir": ["👁️ Stop following", "👁️ Deixar de seguir", "👁️ Ne plus suivre", "👁️ Smetti di seguire", "👁️ Nicht mehr folgen", "👁️ Deixar de seguir"],
	"🔄 Salir a buscar ofertas": ["🔄 Go looking for offers", "🔄 Sair em busca de ofertas", "🔄 Aller chercher des offres", "🔄 Vai a cercare offerte", "🔄 Angebote suchen gehen", "🔄 Sortir a buscar ofertes"],
	"🕊️ Mediar con el grupo": ["🕊️ Mediate with the group", "🕊️ Mediar com o grupo", "🕊️ Servir de médiateur", "🕊️ Media con il gruppo", "🕊️ Mit der Gruppe vermitteln", "🕊️ Mediar amb el grup"],
	"⚔️ Ir a por su patrocinador": ["⚔️ Go after their sponsor", "⚔️ Ir atrás do patrocinador deles", "⚔️ Viser leur sponsor", "⚔️ Punta al loro sponsor", "⚔️ Ihren Sponsor angreifen", "⚔️ Anar a pel seu patrocinador"],
	"🎤 Arrendar para un concierto": ["🎤 Rent out for a concert", "🎤 Alugar para um show", "🎤 Louer pour un concert", "🎤 Affitta per un concerto", "🎤 Für ein Konzert vermieten", "🎤 Llogar per a un concert"],
	"☀️ Paneles solares": ["☀️ Solar panels", "☀️ Painéis solares", "☀️ Panneaux solaires", "☀️ Pannelli solari", "☀️ Solarpaneele", "☀️ Plaques solars"],
	"Avión propio para giras": ["Own plane for tours", "Avião próprio para excursões", "Avion privé pour les tournées", "Aereo proprio per le tournée", "Eigenes Flugzeug für Touren", "Avió propi per a gires"],
	"Ampliación del estadio": ["Stadium expansion", "Ampliação do estádio", "Agrandissement du stade", "Ampliamento dello stadio", "Stadionausbau", "Ampliació de l'estadi"],
	"📋 Pegar desde el portapapeles": ["📋 Paste from clipboard", "📋 Colar da área de transferência", "📋 Coller depuis le presse-papiers", "📋 Incolla dagli appunti", "📋 Aus Zwischenablage einfügen", "📋 Enganxar del porta-retalls"],
	"¿SEGURO? Anunciar mi retirada": ["ARE YOU SURE? Announce my retirement", "TEM CERTEZA? Anunciar minha aposentadoria", "ÊTES-VOUS SÛR ? Annoncer ma retraite", "SICURO? Annuncia il mio ritiro", "SICHER? Meinen Rücktritt bekannt geben", "SEGUR? Anunciar la meva retirada"],
	"¿SEGURO? Vender el club": ["ARE YOU SURE? Sell the club", "TEM CERTEZA? Vender o clube", "ÊTES-VOUS SÛR ? Vendre le club", "SICURO? Vendi il club", "SICHER? Verein verkaufen", "SEGUR? Vendre el club"],

	# --- títulos de sección ---
	"RESUMEN": ["SUMMARY", "RESUMO", "RÉSUMÉ", "RIEPILOGO", "ÜBERSICHT", "RESUM"],
	"SONIDO": ["SOUND", "SOM", "SON", "AUDIO", "TON", "SO"],
	"MÚSICA": ["MUSIC", "MÚSICA", "MUSIQUE", "MUSICA", "MUSIK", "MÚSICA"],
	"ACCESIBILIDAD": ["ACCESSIBILITY", "ACESSIBILIDADE", "ACCESSIBILITÉ", "ACCESSIBILITÀ", "BARRIEREFREIHEIT", "ACCESSIBILITAT"],
	"ACERCA DE": ["ABOUT", "SOBRE", "À PROPOS", "INFORMAZIONI", "ÜBER", "QUANT A"],
	"GUARDADO": ["SAVING", "SALVAMENTO", "SAUVEGARDE", "SALVATAGGIO", "SPEICHERN", "DESAT"],
	"FONDO DE PANTALLA": ["WALLPAPER", "PAPEL DE PAREDE", "FOND D'ÉCRAN", "SFONDO", "HINTERGRUNDBILD", "FONS DE PANTALLA"],
	"FOTOGRAMAS POR SEGUNDO": ["FRAMES PER SECOND", "QUADROS POR SEGUNDO", "IMAGES PAR SECONDE", "FOTOGRAMMI AL SECONDO", "BILDER PRO SEKUNDE", "FOTOGRAMES PER SEGON"],
	"PANTALLA Y DISPOSITIVO": ["SCREEN AND DEVICE", "TELA E DISPOSITIVO", "ÉCRAN ET APPAREIL", "SCHERMO E DISPOSITIVO", "BILDSCHIRM UND GERÄT", "PANTALLA I DISPOSITIU"],
	"RANURAS DE GUARDADO": ["SAVE SLOTS", "ESPAÇOS DE SALVAMENTO", "EMPLACEMENTS DE SAUVEGARDE", "SLOT DI SALVATAGGIO", "SPEICHERPLÄTZE", "RANURES DE DESAT"],
	"SACAR Y METER LA PARTIDA": ["EXPORT AND IMPORT THE SAVE", "EXPORTAR E IMPORTAR O JOGO", "EXPORTER ET IMPORTER LA PARTIE", "ESPORTA E IMPORTA IL SALVATAGGIO", "SPIELSTAND EXPORTIEREN UND IMPORTIEREN", "TREURE I POSAR LA PARTIDA"],
	"🎨 ASPECTO DE LA INTERFAZ": ["🎨 INTERFACE LOOK", "🎨 APARÊNCIA DA INTERFACE", "🎨 APPARENCE DE L'INTERFACE", "🎨 ASPETTO DELL'INTERFACCIA", "🎨 AUSSEHEN DER OBERFLÄCHE", "🎨 ASPECTE DE LA INTERFÍCIE"],
	"🎨 IDENTIDAD VISUAL": ["🎨 VISUAL IDENTITY", "🎨 IDENTIDADE VISUAL", "🎨 IDENTITÉ VISUELLE", "🎨 IDENTITÀ VISIVA", "🎨 VISUELLE IDENTITÄT", "🎨 IDENTITAT VISUAL"],
	"RUEDA DE PRENSA": ["PRESS CONFERENCE", "COLETIVA DE IMPRENSA", "CONFÉRENCE DE PRESSE", "CONFERENZA STAMPA", "PRESSEKONFERENZ", "RODA DE PREMSA"],
	"HAY QUE DECIDIR": ["A DECISION IS NEEDED", "É PRECISO DECIDIR", "IL FAUT DÉCIDER", "BISOGNA DECIDERE", "ES MUSS ENTSCHIEDEN WERDEN", "CAL DECIDIR"],
	"UN REPRESENTANTE PRESIONA": ["AN AGENT IS PUSHING", "UM EMPRESÁRIO PRESSIONA", "UN AGENT FAIT PRESSION", "UN PROCURATORE FA PRESSIONE", "EIN BERATER MACHT DRUCK", "UN REPRESENTANT PRESSIONA"],
	"PRÓXIMO COMPROMISO": ["NEXT FIXTURE", "PRÓXIMO COMPROMISSO", "PROCHAINE ÉCHÉANCE", "PROSSIMO IMPEGNO", "NÄCHSTE PARTIE", "PROPER COMPROMÍS"],
	"ÚLTIMOS RESULTADOS": ["RECENT RESULTS", "ÚLTIMOS RESULTADOS", "DERNIERS RÉSULTATS", "ULTIMI RISULTATI", "LETZTE ERGEBNISSE", "DARRERS RESULTATS"],
	"ESTA TEMPORADA": ["THIS SEASON", "ESTA TEMPORADA", "CETTE SAISON", "QUESTA STAGIONE", "DIESE SAISON", "AQUESTA TEMPORADA"],
	"ESTADO DE RESULTADOS": ["INCOME STATEMENT", "DEMONSTRAÇÃO DE RESULTADOS", "COMPTE DE RÉSULTAT", "CONTO ECONOMICO", "GEWINN- UND VERLUSTRECHNUNG", "COMPTE DE RESULTATS"],
	"BALANCE": ["BALANCE SHEET", "BALANÇO", "BILAN", "BILANCIO", "BILANZ", "BALANÇ"],
	"FLUJO DE CAJA A 12 MESES": ["12-MONTH CASH FLOW", "FLUXO DE CAIXA DE 12 MESES", "TRÉSORERIE SUR 12 MOIS", "FLUSSO DI CASSA A 12 MESI", "CASHFLOW ÜBER 12 MONATE", "FLUX DE CAIXA A 12 MESOS"],
	"PLUSVALÍAS PENDIENTES": ["PENDING CAPITAL GAINS", "MAIS-VALIAS PENDENTES", "PLUS-VALUES EN ATTENTE", "PLUSVALENZE IN SOSPESO", "OFFENE VERÄUSSERUNGSGEWINNE", "PLUSVÀLUES PENDENTS"],
	"CLÁUSULAS DE RESCISIÓN": ["RELEASE CLAUSES", "CLÁUSULAS DE RESCISÃO", "CLAUSES LIBÉRATOIRES", "CLAUSOLE RESCISSORIE", "AUSSTIEGSKLAUSELN", "CLÀUSULES DE RESCISSIÓ"],
	"TIENE CLÁUSULA DE RESCISIÓN": ["HAS A RELEASE CLAUSE", "TEM CLÁUSULA DE RESCISÃO", "A UNE CLAUSE LIBÉRATOIRE", "HA UNA CLAUSOLA RESCISSORIA", "HAT EINE AUSSTIEGSKLAUSEL", "TÉ CLÀUSULA DE RESCISSIÓ"],
	"RESCINDIR CONTRATO": ["TERMINATE CONTRACT", "RESCINDIR CONTRATO", "RÉSILIER LE CONTRAT", "RESCINDI IL CONTRATTO", "VERTRAG AUFLÖSEN", "RESCINDIR CONTRACTE"],
	"OFERTAS RECIBIDAS": ["OFFERS RECEIVED", "OFERTAS RECEBIDAS", "OFFRES REÇUES", "OFFERTE RICEVUTE", "ERHALTENE ANGEBOTE", "OFERTES REBUDES"],
	"PARA FICHARLO": ["TO SIGN HIM", "PARA CONTRATÁ-LO", "POUR LE RECRUTER", "PER INGAGGIARLO", "UM IHN ZU VERPFLICHTEN", "PER FITXAR-LO"],
	"A QUIÉN CEDER": ["WHO TO LOAN OUT", "QUEM EMPRESTAR", "QUI PRÊTER", "CHI MANDARE IN PRESTITO", "WEN VERLEIHEN", "A QUI CEDIR"],
	"FILTRAR": ["FILTER", "FILTRAR", "FILTRER", "FILTRA", "FILTERN", "FILTRAR"],
	"FORMACIÓN": ["FORMATION", "FORMAÇÃO", "FORMATION", "MODULO", "FORMATION", "FORMACIÓ"],
	"PIZARRA": ["TACTICS BOARD", "PRANCHETA", "TABLEAU TACTIQUE", "LAVAGNA TATTICA", "TAKTIKTAFEL", "PISSARRA"],
	"ROLES DEL ONCE": ["ROLES IN THE XI", "FUNÇÕES NO ONZE", "RÔLES DU ONZE", "RUOLI DELL'UNDICI", "ROLLEN DER ELF", "ROLS DE L'ONZE"],
	"ROLES PROMETIDOS": ["PROMISED ROLES", "FUNÇÕES PROMETIDAS", "RÔLES PROMIS", "RUOLI PROMESSI", "VERSPROCHENE ROLLEN", "ROLS PROMESOS"],
	"CÓMO QUIERES QUE JUEGUE": ["HOW YOU WANT THEM TO PLAY", "COMO VOCÊ QUER QUE JOGUEM", "COMMENT VOUS VOULEZ QU'ILS JOUENT", "COME VUOI CHE GIOCHINO", "WIE SIE SPIELEN SOLLEN", "COM VOLS QUE JUGUIN"],
	"PLANES SEGÚN EL MARCADOR": ["PLANS BY SCORELINE", "PLANOS CONFORME O PLACAR", "PLANS SELON LE SCORE", "PIANI IN BASE AL PUNTEGGIO", "PLÄNE JE NACH SPIELSTAND", "PLANS SEGONS EL MARCADOR"],
	"BALÓN PARADO": ["SET PIECES", "BOLA PARADA", "COUPS DE PIED ARRÊTÉS", "PALLE INATTIVE", "STANDARDS", "PILOTA ATURADA"],
	"PLAN DE LA SEMANA": ["THE WEEK'S PLAN", "PLANO DA SEMANA", "PLAN DE LA SEMAINE", "PIANO DELLA SETTIMANA", "WOCHENPLAN", "PLA DE LA SETMANA"],
	"RIESGO DE LESIÓN": ["INJURY RISK", "RISCO DE LESÃO", "RISQUE DE BLESSURE", "RISCHIO INFORTUNIO", "VERLETZUNGSRISIKO", "RISC DE LESIÓ"],
	"EN RIESGO ESTA SEMANA": ["AT RISK THIS WEEK", "EM RISCO ESTA SEMANA", "À RISQUE CETTE SEMAINE", "A RISCHIO QUESTA SETTIMANA", "DIESE WOCHE GEFÄHRDET", "EN RISC AQUESTA SETMANA"],
	"HISTORIAL MÉDICO": ["MEDICAL HISTORY", "HISTÓRICO MÉDICO", "ANTÉCÉDENTS MÉDICAUX", "STORIA CLINICA", "KRANKENGESCHICHTE", "HISTORIAL MÈDIC"],
	"PEDIR DESCANSO": ["REQUEST REST", "PEDIR DESCANSO", "DEMANDER DU REPOS", "CHIEDI RIPOSO", "RUHE ANFORDERN", "DEMANAR DESCANS"],
	"CLIMA DEL VESTUARIO": ["DRESSING-ROOM MOOD", "CLIMA DO VESTIÁRIO", "AMBIANCE DU VESTIAIRE", "CLIMA DELLO SPOGLIATOIO", "STIMMUNG IN DER KABINE", "CLIMA DEL VESTIDOR"],
	"CLANES Y CAMARILLAS": ["CLIQUES AND FACTIONS", "PANELINHAS", "CLANS ET COTERIES", "CLAN E CRICCHE", "CLIQUEN UND LAGER", "CLANS I CAMARILLES"],
	"PROMESA Y SATISFACCIÓN": ["PROMISES AND SATISFACTION", "PROMESSA E SATISFAÇÃO", "PROMESSES ET SATISFACTION", "PROMESSE E SODDISFAZIONE", "VERSPRECHEN UND ZUFRIEDENHEIT", "PROMESA I SATISFACCIÓ"],
	"HABILIDADES": ["SKILLS", "HABILIDADES", "COMPÉTENCES", "ABILITÀ", "FÄHIGKEITEN", "HABILITATS"],
	"🎓 TUS HABILIDADES DE ENTRENADOR": ["🎓 YOUR COACHING SKILLS", "🎓 SUAS HABILIDADES DE TREINADOR", "🎓 VOS COMPÉTENCES D'ENTRAÎNEUR", "🎓 LE TUE ABILITÀ DA ALLENATORE", "🎓 DEINE TRAINERFÄHIGKEITEN", "🎓 LES TEVES HABILITATS D'ENTRENADOR"],
	"TU CARRERA": ["YOUR CAREER", "SUA CARREIRA", "VOTRE CARRIÈRE", "LA TUA CARRIERA", "DEINE KARRIERE", "LA TEVA CARRERA"],
	"TU CARGO": ["YOUR POSITION", "SEU CARGO", "VOTRE POSTE", "IL TUO INCARICO", "DEIN AMT", "EL TEU CÀRREC"],
	"TU LEGADO": ["YOUR LEGACY", "SEU LEGADO", "VOTRE HÉRITAGE", "LA TUA EREDITÀ", "DEIN VERMÄCHTNIS", "EL TEU LLEGAT"],
	"TU PARTIDO": ["YOUR MATCH", "SUA PARTIDA", "VOTRE MATCH", "LA TUA PARTITA", "DEIN SPIEL", "EL TEU PARTIT"],
	"PUNTAJE DE CARRERA": ["CAREER SCORE", "PONTUAÇÃO DE CARREIRA", "SCORE DE CARRIÈRE", "PUNTEGGIO DI CARRIERA", "KARRIEREPUNKTE", "PUNTUACIÓ DE CARRERA"],
	"📄 CURRÍCULUM": ["📄 RÉSUMÉ", "📄 CURRÍCULO", "📄 CV", "📄 CURRICULUM", "📄 LEBENSLAUF", "📄 CURRÍCULUM"],
	"📈 CARRERA PROFESIONAL": ["📈 PROFESSIONAL CAREER", "📈 CARREIRA PROFISSIONAL", "📈 CARRIÈRE PROFESSIONNELLE", "📈 CARRIERA PROFESSIONALE", "📈 BERUFLICHE LAUFBAHN", "📈 CARRERA PROFESSIONAL"],
	"📖 TU CARRERA HASTA AQUÍ": ["📖 YOUR CAREER SO FAR", "📖 SUA CARREIRA ATÉ AQUI", "📖 VOTRE CARRIÈRE JUSQU'ICI", "📖 LA TUA CARRIERA FINORA", "📖 DEINE KARRIERE BISHER", "📖 LA TEVA CARRERA FINS AQUÍ"],
	"📜 TEMPORADA A TEMPORADA": ["📜 SEASON BY SEASON", "📜 TEMPORADA A TEMPORADA", "📜 SAISON PAR SAISON", "📜 STAGIONE PER STAGIONE", "📜 SAISON FÜR SAISON", "📜 TEMPORADA A TEMPORADA"],
	"📖 EL AÑO CONTADO": ["📖 THE YEAR IN WORDS", "📖 O ANO CONTADO", "📖 L'ANNÉE RACONTÉE", "📖 L'ANNO RACCONTATO", "📖 DAS JAHR ERZÄHLT", "📖 L'ANY EXPLICAT"],
	"📋 INFORME DE LA SEMANA": ["📋 THE WEEK'S REPORT", "📋 RELATÓRIO DA SEMANA", "📋 RAPPORT DE LA SEMAINE", "📋 RAPPORTO DELLA SETTIMANA", "📋 WOCHENBERICHT", "📋 INFORME DE LA SETMANA"],
	"📊 LO QUE TE HA FUNCIONADO": ["📊 WHAT HAS WORKED FOR YOU", "📊 O QUE FUNCIONOU PARA VOCÊ", "📊 CE QUI A MARCHÉ POUR VOUS", "📊 COSA HA FUNZIONATO", "📊 WAS BEI DIR FUNKTIONIERT HAT", "📊 EL QUE T'HA FUNCIONAT"],
	"📊 ENCUESTA A LOS SOCIOS": ["📊 MEMBERS' SURVEY", "📊 PESQUISA COM OS SÓCIOS", "📊 SONDAGE DES MEMBRES", "📊 SONDAGGIO TRA I SOCI", "📊 MITGLIEDERUMFRAGE", "📊 ENQUESTA ALS SOCIS"],
	"🏁 FIN DE CARRERA": ["🏁 END OF CAREER", "🏁 FIM DE CARREIRA", "🏁 FIN DE CARRIÈRE", "🏁 FINE CARRIERA", "🏁 KARRIEREENDE", "🏁 FI DE CARRERA"],
	"🏅 RANKING DE ENTRENADORES": ["🏅 MANAGER RANKINGS", "🏅 RANKING DE TREINADORES", "🏅 CLASSEMENT DES ENTRAÎNEURS", "🏅 CLASSIFICA ALLENATORI", "🏅 TRAINER-RANGLISTE", "🏅 RÀNQUING D'ENTRENADORS"],
	"🌱 RANKING DE CANTERAS": ["🌱 ACADEMY RANKINGS", "🌱 RANKING DE CATEGORIAS DE BASE", "🌱 CLASSEMENT DES CENTRES DE FORMATION", "🌱 CLASSIFICA VIVAI", "🌱 NACHWUCHS-RANGLISTE", "🌱 RÀNQUING DE PLANTERS"],
	"🌍 EL MAPA DEL TALENTO": ["🌍 THE TALENT MAP", "🌍 O MAPA DO TALENTO", "🌍 LA CARTE DES TALENTS", "🌍 LA MAPPA DEI TALENTI", "🌍 DIE TALENTKARTE", "🌍 EL MAPA DEL TALENT"],
	"🌿 SOSTENIBILIDAD": ["🌿 SUSTAINABILITY", "🌿 SUSTENTABILIDADE", "🌿 DURABILITÉ", "🌿 SOSTENIBILITÀ", "🌿 NACHHALTIGKEIT", "🌿 SOSTENIBILITAT"],
	"🎖️ HOMENAJES": ["🎖️ TRIBUTES", "🎖️ HOMENAGENS", "🎖️ HOMMAGES", "🎖️ OMAGGI", "🎖️ EHRUNGEN", "🎖️ HOMENATGES"],
	"🎗️ BONO SOCIAL": ["🎗️ SOCIAL BOND", "🎗️ TÍTULO SOCIAL", "🎗️ OBLIGATION SOCIALE", "🎗️ OBBLIGAZIONE SOCIALE", "🎗️ SOZIALANLEIHE", "🎗️ BO SOCIAL"],
	"🎙️ LA PRENSA": ["🎙️ THE PRESS", "🎙️ A IMPRENSA", "🎙️ LA PRESSE", "🎙️ LA STAMPA", "🎙️ DIE PRESSE", "🎙️ LA PREMSA"],
	"🎤 EVENTOS NO DEPORTIVOS": ["🎤 NON-SPORTING EVENTS", "🎤 EVENTOS NÃO ESPORTIVOS", "🎤 ÉVÉNEMENTS NON SPORTIFS", "🎤 EVENTI NON SPORTIVI", "🎤 NICHT-SPORTLICHE EVENTS", "🎤 ESDEVENIMENTS NO ESPORTIUS"],
	"🎤 QUIÉN DA LA CARA": ["🎤 WHO FRONTS IT", "🎤 QUEM DÁ AS CARAS", "🎤 QUI MONTE AU CRÉNEAU", "🎤 CHI CI METTE LA FACCIA", "🎤 WER DEN KOPF HINHÄLT", "🎤 QUI DÓNA LA CARA"],
	"🎭 JUEGOS MENTALES": ["🎭 MIND GAMES", "🎭 JOGOS MENTAIS", "🎭 GUERRE PSYCHOLOGIQUE", "🎭 GIOCHI PSICOLOGICI", "🎭 PSYCHOSPIELCHEN", "🎭 JOCS MENTALS"],
	"🎰 CASA DE APUESTAS": ["🎰 BETTING HOUSE", "🎰 CASA DE APOSTAS", "🎰 MAISON DE PARIS", "🎰 CASA DI SCOMMESSE", "🎰 WETTANBIETER", "🎰 CASA D'APOSTES"],
	"🎺 DETALLES DEL CLUB": ["🎺 CLUB DETAILS", "🎺 DETALHES DO CLUBE", "🎺 DÉTAILS DU CLUB", "🎺 DETTAGLI DEL CLUB", "🎺 VEREINSDETAILS", "🎺 DETALLS DEL CLUB"],
	"🏗️ NEGOCIOS ANEXOS": ["🏗️ SIDE BUSINESSES", "🏗️ NEGÓCIOS ANEXOS", "🏗️ ACTIVITÉS ANNEXES", "🏗️ ATTIVITÀ COLLATERALI", "🏗️ NEBENGESCHÄFTE", "🏗️ NEGOCIS ANNEXOS"],
	"🏙️ EL CLUB Y SU CIUDAD": ["🏙️ THE CLUB AND ITS CITY", "🏙️ O CLUBE E SUA CIDADE", "🏙️ LE CLUB ET SA VILLE", "🏙️ IL CLUB E LA SUA CITTÀ", "🏙️ DER VEREIN UND SEINE STADT", "🏙️ EL CLUB I LA SEVA CIUTAT"],
	"🏛️ MUNICIPALIDAD Y VECINOS": ["🏛️ COUNCIL AND NEIGHBOURS", "🏛️ PREFEITURA E VIZINHOS", "🏛️ MAIRIE ET RIVERAINS", "🏛️ COMUNE E VICINI", "🏛️ STADT UND NACHBARN", "🏛️ AJUNTAMENT I VEÏNS"],
	"🏟️ NOMBRE DEL ESTADIO": ["🏟️ STADIUM NAME", "🏟️ NOME DO ESTÁDIO", "🏟️ NOM DU STADE", "🏟️ NOME DELLO STADIO", "🏟️ STADIONNAME", "🏟️ NOM DE L'ESTADI"],
	"🏦 TUS CLUBES": ["🏦 YOUR CLUBS", "🏦 SEUS CLUBES", "🏦 VOS CLUBS", "🏦 I TUOI CLUB", "🏦 DEINE VEREINE", "🏦 ELS TEUS CLUBS"],
	"🏭 PROVEEDOR DE INDUMENTARIA": ["🏭 KIT SUPPLIER", "🏭 FORNECEDOR DE MATERIAL", "🏭 ÉQUIPEMENTIER", "🏭 SPONSOR TECNICO", "🏭 AUSRÜSTER", "🏭 PROVEÏDOR D'EQUIPACIÓ"],
	"👔 TU RIVAL": ["👔 YOUR RIVAL", "👔 SEU RIVAL", "👔 VOTRE RIVAL", "👔 IL TUO RIVALE", "👔 DEIN RIVALE", "👔 EL TEU RIVAL"],
	"👔 UNIFORME DEL CUERPO TÉCNICO": ["👔 STAFF UNIFORM", "👔 UNIFORME DA COMISSÃO", "👔 TENUE DU STAFF", "👔 DIVISA DELLO STAFF", "👔 STAB-KLEIDUNG", "👔 UNIFORME DEL COS TÈCNIC"],
	"👕 LA MARCA DEL PECHO": ["👕 THE SHIRT SPONSOR", "👕 A MARCA DO PEITO", "👕 LE SPONSOR MAILLOT", "👕 LO SPONSOR DI MAGLIA", "👕 DER TRIKOTSPONSOR", "👕 LA MARCA DEL PIT"],
	"👕 LAS TRES CAMISETAS": ["👕 THE THREE KITS", "👕 OS TRÊS UNIFORMES", "👕 LES TROIS MAILLOTS", "👕 LE TRE MAGLIE", "👕 DIE DREI TRIKOTS", "👕 LES TRES SAMARRETES"],
	"💰 EXPLOTACIÓN COMERCIAL": ["💰 COMMERCIAL OPERATION", "💰 EXPLORAÇÃO COMERCIAL", "💰 EXPLOITATION COMMERCIALE", "💰 SFRUTTAMENTO COMMERCIALE", "💰 KOMMERZIELLE NUTZUNG", "💰 EXPLOTACIÓ COMERCIAL"],
	"💸 FONDOS DE INVERSIÓN": ["💸 INVESTMENT FUNDS", "💸 FUNDOS DE INVESTIMENTO", "💸 FONDS D'INVESTISSEMENT", "💸 FONDI DI INVESTIMENTO", "💸 INVESTMENTFONDS", "💸 FONS D'INVERSIÓ"],
	"💸 PATROCINIOS POR ZONA": ["💸 REGIONAL SPONSORSHIPS", "💸 PATROCÍNIOS POR REGIÃO", "💸 PARRAINAGES PAR ZONE", "💸 SPONSORIZZAZIONI PER AREA", "💸 SPONSORING NACH REGION", "💸 PATROCINIS PER ZONA"],
	"💼 TU PATRIMONIO": ["💼 YOUR WEALTH", "💼 SEU PATRIMÔNIO", "💼 VOTRE PATRIMOINE", "💼 IL TUO PATRIMONIO", "💼 DEIN VERMÖGEN", "💼 EL TEU PATRIMONI"],
	"📡 MEDIOS PROPIOS": ["📡 CLUB MEDIA", "📡 MÍDIA PRÓPRIA", "📡 MÉDIAS DU CLUB", "📡 MEDIA DEL CLUB", "📡 VEREINSMEDIEN", "📡 MITJANS PROPIS"],
	"📣 CAMPAÑAS PUBLICITARIAS": ["📣 AD CAMPAIGNS", "📣 CAMPANHAS PUBLICITÁRIAS", "📣 CAMPAGNES PUBLICITAIRES", "📣 CAMPAGNE PUBBLICITARIE", "📣 WERBEKAMPAGNEN", "📣 CAMPANYES PUBLICITÀRIES"],
	"📱 LO DIGITAL": ["📱 DIGITAL", "📱 O DIGITAL", "📱 LE NUMÉRIQUE", "📱 IL DIGITALE", "📱 DIGITALES", "📱 EL DIGITAL"],
	"📺 DERECHOS DE TELEVISIÓN": ["📺 TV RIGHTS", "📺 DIREITOS DE TV", "📺 DROITS TV", "📺 DIRITTI TV", "📺 TV-RECHTE", "📺 DRETS DE TELEVISIÓ"],
	"📺 MESA DE DEBATE": ["📺 PUNDITS' PANEL", "📺 MESA DE DEBATE", "📺 PLATEAU DE DÉBAT", "📺 SALOTTO TV", "📺 TALKRUNDE", "📺 TAULA DE DEBAT"],
	"🔁 ROTACIÓN Y VIDEOANÁLISIS": ["🔁 ROTATION AND VIDEO ANALYSIS", "🔁 RODÍZIO E ANÁLISE DE VÍDEO", "🔁 ROTATION ET ANALYSE VIDÉO", "🔁 ROTAZIONE E VIDEOANALISI", "🔁 ROTATION UND VIDEOANALYSE", "🔁 ROTACIÓ I VIDEOANÀLISI"],
	"🔥 DESGASTE EN EL CARGO": ["🔥 WEAR IN THE JOB", "🔥 DESGASTE NO CARGO", "🔥 USURE DANS LE POSTE", "🔥 LOGORIO NELL'INCARICO", "🔥 VERSCHLEISS IM AMT", "🔥 DESGAST EN EL CÀRREC"],
	"🔥 MAPA DE RIVALIDADES": ["🔥 RIVALRY MAP", "🔥 MAPA DE RIVALIDADES", "🔥 CARTE DES RIVALITÉS", "🔥 MAPPA DELLE RIVALITÀ", "🔥 RIVALITÄTSKARTE", "🔥 MAPA DE RIVALITATS"],
	"🔥 ¡ES CLÁSICO!": ["🔥 IT'S A DERBY!", "🔥 É CLÁSSICO!", "🔥 C'EST UN DERBY !", "🔥 È DERBY!", "🔥 ES IST EIN DERBY!", "🔥 ÉS CLÀSSIC!"],
	"🕰️ LEYENDA VIVA DEL CLUB": ["🕰️ LIVING CLUB LEGEND", "🕰️ LENDA VIVA DO CLUBE", "🕰️ LÉGENDE VIVANTE DU CLUB", "🕰️ LEGGENDA VIVENTE DEL CLUB", "🕰️ LEBENDE VEREINSLEGENDE", "🕰️ LLEGENDA VIVA DEL CLUB"],
	"🕴️ AGENCIAS DEL PLANTEL": ["🕴️ SQUAD AGENCIES", "🕴️ AGÊNCIAS DO ELENCO", "🕴️ AGENCES DE L'EFFECTIF", "🕴️ AGENZIE DELLA ROSA", "🕴️ BERATER DES KADERS", "🕴️ AGÈNCIES DE LA PLANTILLA"],
	"🗞️ ARCHIVO DE PORTADAS": ["🗞️ FRONT-PAGE ARCHIVE", "🗞️ ARQUIVO DE CAPAS", "🗞️ ARCHIVES DES UNES", "🗞️ ARCHIVIO DELLE PRIME PAGINE", "🗞️ TITELSEITEN-ARCHIV", "🗞️ ARXIU DE PORTADES"],
	"🗺️ TERRENOS": ["🗺️ LAND", "🗺️ TERRENOS", "🗺️ TERRAINS", "🗺️ TERRENI", "🗺️ GRUNDSTÜCKE", "🗺️ TERRENYS"],
	"🚪 EL CLUB POR DENTRO": ["🚪 INSIDE THE CLUB", "🚪 O CLUBE POR DENTRO", "🚪 LE CLUB DE L'INTÉRIEUR", "🚪 IL CLUB DALL'INTERNO", "🚪 DER VEREIN VON INNEN", "🚪 EL CLUB PER DINS"],
	"🛠️ EDITOR": ["🛠️ EDITOR", "🛠️ EDITOR", "🛠️ ÉDITEUR", "🛠️ EDITOR", "🛠️ EDITOR", "🛠️ EDITOR"],
	"🛡️ SEGURIDAD DEL ESTADIO": ["🛡️ STADIUM SECURITY", "🛡️ SEGURANÇA DO ESTÁDIO", "🛡️ SÉCURITÉ DU STADE", "🛡️ SICUREZZA DELLO STADIO", "🛡️ STADIONSICHERHEIT", "🛡️ SEGURETAT DE L'ESTADI"],
	"🧠 CABEZA": ["🧠 MIND", "🧠 CABEÇA", "🧠 MENTAL", "🧠 TESTA", "🧠 KOPF", "🧠 CAP"],
	"🧠 SALUD MENTAL": ["🧠 MENTAL HEALTH", "🧠 SAÚDE MENTAL", "🧠 SANTÉ MENTALE", "🧠 SALUTE MENTALE", "🧠 PSYCHISCHE GESUNDHEIT", "🧠 SALUT MENTAL"],
	"🧢 TRABAJAS PARA ÉL": ["🧢 YOU WORK FOR HIM", "🧢 VOCÊ TRABALHA PARA ELE", "🧢 VOUS TRAVAILLEZ POUR LUI", "🧢 LAVORI PER LUI", "🧢 DU ARBEITEST FÜR IHN", "🧢 TREBALLES PER A ELL"],
	"🧳 PRETEMPORADA": ["🧳 PRE-SEASON", "🧳 PRÉ-TEMPORADA", "🧳 PRÉSAISON", "🧳 PRECAMPIONATO", "🧳 VORBEREITUNG", "🧳 PRETEMPORADA"],
	"🪑 LA SUCESIÓN": ["🪑 THE SUCCESSION", "🪑 A SUCESSÃO", "🪑 LA SUCCESSION", "🪑 LA SUCCESSIONE", "🪑 DIE NACHFOLGE", "🪑 LA SUCCESSIÓ"],
	"⚔️ GUERRA DE MARCAS": ["⚔️ BRAND WAR", "⚔️ GUERRA DE MARCAS", "⚔️ GUERRE DES MARQUES", "⚔️ GUERRA DEI MARCHI", "⚔️ MARKENKRIEG", "⚔️ GUERRA DE MARQUES"],
	"⚖️ AQUEL EQUIPO Y ESTE": ["⚖️ THAT TEAM AND THIS ONE", "⚖️ AQUELE TIME E ESTE", "⚖️ CETTE ÉQUIPE-LÀ ET CELLE-CI", "⚖️ QUELLA SQUADRA E QUESTA", "⚖️ JENE MANNSCHAFT UND DIESE", "⚖️ AQUELL EQUIP I AQUEST"],
	"⭐ ACCESOS RÁPIDOS": ["⭐ SHORTCUTS", "⭐ ATALHOS", "⭐ RACCOURCIS", "⭐ SCORCIATOIE", "⭐ SCHNELLZUGRIFFE", "⭐ ACCESSOS RÀPIDS"],
	"✨ ESTADIO PREMIUM": ["✨ PREMIUM STADIUM", "✨ ESTÁDIO PREMIUM", "✨ STADE PREMIUM", "✨ STADIO PREMIUM", "✨ PREMIUM-STADION", "✨ ESTADI PREMIUM"],
	"☎️ TE QUIEREN EN OTRO CLUB": ["☎️ ANOTHER CLUB WANTS YOU", "☎️ QUEREM VOCÊ EM OUTRO CLUBE", "☎️ UN AUTRE CLUB VOUS VEUT", "☎️ TI VOGLIONO IN UN ALTRO CLUB", "☎️ EIN ANDERER VEREIN WILL DICH", "☎️ ET VOLEN EN UN ALTRE CLUB"],
	"EL RECINTO": ["THE GROUND", "O RECINTO", "L'ENCEINTE", "L'IMPIANTO", "DIE ANLAGE", "EL RECINTE"],
	"EMBAJADOR DEL CLUB": ["CLUB AMBASSADOR", "EMBAIXADOR DO CLUBE", "AMBASSADEUR DU CLUB", "AMBASCIATORE DEL CLUB", "VEREINSBOTSCHAFTER", "AMBAIXADOR DEL CLUB"],
	"EQUIPACIÓN": ["KIT", "UNIFORME", "MAILLOT", "DIVISA", "TRIKOT", "EQUIPACIÓ"],
	"EQUIPO IDEAL": ["TEAM OF THE SEASON", "SELEÇÃO DA TEMPORADA", "ÉQUIPE TYPE", "SQUADRA IDEALE", "MANNSCHAFT DER SAISON", "EQUIP IDEAL"],
	"ESCALAFÓN MUNDIAL": ["WORLD RANKING", "RANKING MUNDIAL", "CLASSEMENT MONDIAL", "CLASSIFICA MONDIALE", "WELTRANGLISTE", "ESCALAFÓ MUNDIAL"],
	"CAMPEONES CONTINENTALES": ["CONTINENTAL CHAMPIONS", "CAMPEÕES CONTINENTAIS", "CHAMPIONS CONTINENTAUX", "CAMPIONI CONTINENTALI", "KONTINENTALMEISTER", "CAMPIONS CONTINENTALS"],
	"CARA A CARA": ["HEAD TO HEAD", "CONFRONTO DIRETO", "FACE À FACE", "SCONTRI DIRETTI", "DIREKTER VERGLEICH", "CARA A CARA"],
	"CONTROLES ANTIDOPAJE": ["ANTI-DOPING TESTS", "EXAMES ANTIDOPING", "CONTRÔLES ANTIDOPAGE", "CONTROLLI ANTIDOPING", "DOPINGKONTROLLEN", "CONTROLS ANTIDOPATGE"],
	"COPA DEL MUNDO": ["WORLD CUP", "COPA DO MUNDO", "COUPE DU MONDE", "COPPA DEL MONDO", "WELTMEISTERSCHAFT", "COPA DEL MÓN"],
	"CORREO RECIENTE": ["RECENT MAIL", "CORREIO RECENTE", "COURRIER RÉCENT", "POSTA RECENTE", "NEUE POST", "CORREU RECENT"],
	"CON EL CLUB": ["WITH THE CLUB", "COM O CLUBE", "AVEC LE CLUB", "CON IL CLUB", "MIT DEM VEREIN", "AMB EL CLUB"],
	"CON ÉL": ["WITH HIM", "COM ELE", "AVEC LUI", "CON LUI", "MIT IHM", "AMB ELL"],
	"DE DÓNDE SALE": ["WHERE IT COMES FROM", "DE ONDE VEM", "D'OÙ ÇA VIENT", "DA DOVE ARRIVA", "WOHER ES KOMMT", "D'ON SURT"],
	"GABINETE DE COMUNICACIÓN": ["COMMUNICATIONS OFFICE", "ASSESSORIA DE IMPRENSA", "SERVICE DE COMMUNICATION", "UFFICIO COMUNICAZIONE", "PRESSESTELLE", "GABINET DE COMUNICACIÓ"],
	"GOLEADORES HISTÓRICOS DE TU ERA": ["ALL-TIME SCORERS OF YOUR ERA", "ARTILHEIROS HISTÓRICOS DA SUA ERA", "BUTEURS HISTORIQUES DE VOTRE ÈRE", "MARCATORI STORICI DELLA TUA ERA", "REKORDTORSCHÜTZEN DEINER ÄRA", "GOLEJADORS HISTÒRICS DE LA TEVA ERA"],
	"MÁXIMOS GOLEADORES DE TU ERA": ["TOP SCORERS OF YOUR ERA", "MAIORES ARTILHEIROS DA SUA ERA", "MEILLEURS BUTEURS DE VOTRE ÈRE", "MIGLIORI MARCATORI DELLA TUA ERA", "TOPTORJÄGER DEINER ÄRA", "MÀXIMS GOLEJADORS DE LA TEVA ERA"],
	"MÁS PARTIDOS DISPUTADOS": ["MOST APPEARANCES", "MAIS JOGOS DISPUTADOS", "PLUS DE MATCHS JOUÉS", "PIÙ PRESENZE", "MEISTE EINSÄTZE", "MÉS PARTITS DISPUTATS"],
	"HISTORIAL DE VOTACIONES": ["VOTING HISTORY", "HISTÓRICO DE VOTAÇÕES", "HISTORIQUE DES VOTES", "STORICO DELLE VOTAZIONI", "ABSTIMMUNGSVERLAUF", "HISTORIAL DE VOTACIONS"],
	"HORARIO DEL PARTIDO EN CASA": ["HOME KICK-OFF TIME", "HORÁRIO DO JOGO EM CASA", "HORAIRE DU MATCH À DOMICILE", "ORARIO DELLA GARA IN CASA", "ANSTOSSZEIT DER HEIMSPIELE", "HORARI DEL PARTIT A CASA"],
	"NACIONALIZACIÓN DEPORTIVA": ["SPORTING NATURALISATION", "NATURALIZAÇÃO ESPORTIVA", "NATURALISATION SPORTIVE", "NATURALIZZAZIONE SPORTIVA", "SPORTLICHE EINBÜRGERUNG", "NACIONALITZACIÓ ESPORTIVA"],
	"PALMARÉS POR COMPETICIÓN": ["HONOURS BY COMPETITION", "TÍTULOS POR COMPETIÇÃO", "PALMARÈS PAR COMPÉTITION", "ALBO D'ORO PER COMPETIZIONE", "TITEL NACH WETTBEWERB", "PALMARÈS PER COMPETICIÓ"],
	"PRECIO DE LA ENTRADA": ["TICKET PRICE", "PREÇO DO INGRESSO", "PRIX DU BILLET", "PREZZO DEL BIGLIETTO", "TICKETPREIS", "PREU DE L'ENTRADA"],
	"PRETEMPORADA": ["PRE-SEASON", "PRÉ-TEMPORADA", "PRÉSAISON", "PRECAMPIONATO", "VORBEREITUNG", "PRETEMPORADA"],
	"RACHAS": ["STREAKS", "SEQUÊNCIAS", "SÉRIES", "STRISCE", "SERIEN", "RATXES"],
	"REGLAMENTO INTERNO": ["INTERNAL RULES", "REGULAMENTO INTERNO", "RÈGLEMENT INTÉRIEUR", "REGOLAMENTO INTERNO", "INTERNE REGELN", "REGLAMENT INTERN"],
	"REGLAMENTO VIGENTE": ["RULES IN FORCE", "REGULAMENTO VIGENTE", "RÈGLEMENT EN VIGUEUR", "REGOLAMENTO IN VIGORE", "GELTENDE REGELN", "REGLAMENT VIGENT"],
	"RELACIÓN CON EL ARBITRAJE": ["RELATIONSHIP WITH REFEREES", "RELAÇÃO COM A ARBITRAGEM", "RELATION AVEC L'ARBITRAGE", "RAPPORTO CON GLI ARBITRI", "VERHÄLTNIS ZU DEN SCHIEDSRICHTERN", "RELACIÓ AMB L'ARBITRATGE"],
	"RÉCORDS DEL CLUB": ["CLUB RECORDS", "RECORDES DO CLUBE", "RECORDS DU CLUB", "RECORD DEL CLUB", "VEREINSREKORDE", "RÈCORDS DEL CLUB"],
	"SALÓN DE LA FAMA DEL CLUB": ["CLUB HALL OF FAME", "GALERIA DE HONRA DO CLUBE", "TEMPLE DE LA RENOMMÉE DU CLUB", "HALL OF FAME DEL CLUB", "RUHMESHALLE DES VEREINS", "SALÓ DE LA FAMA DEL CLUB"],
	"SEGMENTOS DE LA HINCHADA": ["FAN SEGMENTS", "SEGMENTOS DA TORCIDA", "SEGMENTS DES SUPPORTERS", "SEGMENTI DELLA TIFOSERIA", "FANGRUPPEN", "SEGMENTS DE L'AFICIÓ"],
	"TRIBUNAL DE DISCIPLINA": ["DISCIPLINARY PANEL", "TRIBUNAL DISCIPLINAR", "COMMISSION DE DISCIPLINE", "GIUDICE SPORTIVO", "SPORTGERICHT", "TRIBUNAL DE DISCIPLINA"],
	"UN DÍA COMO HOY": ["ON THIS DAY", "UM DIA COMO HOJE", "UN JOUR COMME AUJOURD'HUI", "UN GIORNO COME OGGI", "HEUTE VOR JAHREN", "UN DIA COM AVUI"],
	"VENDER": ["SELL", "VENDER", "VENDRE", "VENDI", "VERKAUFEN", "VENDRE"],
	"VITRINA": ["TROPHY CABINET", "GALERIA DE TROFÉUS", "VITRINE", "BACHECA", "TROPHÄENSCHRANK", "VITRINA"],
	"VOTACIÓN ABIERTA": ["VOTE OPEN", "VOTAÇÃO ABERTA", "VOTE OUVERT", "VOTAZIONE APERTA", "ABSTIMMUNG OFFEN", "VOTACIÓ OBERTA"],
	"ARCHIVO DE PLANTELES": ["SQUAD ARCHIVE", "ARQUIVO DE ELENCOS", "ARCHIVE DES EFFECTIFS", "ARCHIVIO DELLE ROSE", "KADER-ARCHIV", "ARXIU DE PLANTILLES"],
	"AL MÁXIMO": ["MAXED OUT", "NO MÁXIMO", "AU MAXIMUM", "AL MASSIMO", "AM MAXIMUM", "AL MÀXIM"],
	"ESTÁS SIN BANCO": ["YOU ARE WITHOUT A CLUB", "VOCÊ ESTÁ SEM CLUBE", "VOUS ÊTES SANS CLUB", "SEI SENZA PANCHINA", "DU BIST OHNE VEREIN", "ESTÀS SENSE BANQUETA"],
	"¿DÓNDE QUIERES EMPEZAR?": ["WHERE DO YOU WANT TO START?", "ONDE VOCÊ QUER COMEÇAR?", "OÙ VOULEZ-VOUS COMMENCER ?", "DOVE VUOI COMINCIARE?", "WO WILLST DU ANFANGEN?", "ON VOLS COMENÇAR?"],
	"FICHA DEL JUGADOR": ["PLAYER PROFILE", "FICHA DO JOGADOR", "FICHE DU JOUEUR", "SCHEDA GIOCATORE", "SPIELERPROFIL", "FITXA DEL JUGADOR"],

	# --- ajustes ---
	"🔊 Sonido y música": ["🔊 Sound and music", "🔊 Som e música", "🔊 Son et musique", "🔊 Audio e musica", "🔊 Ton und Musik", "🔊 So i música"],
	"🎨 Aspecto": ["🎨 Look", "🎨 Aparência", "🎨 Apparence", "🎨 Aspetto", "🎨 Aussehen", "🎨 Aspecte"],
	"🖥 Pantalla": ["🖥 Screen", "🖥 Tela", "🖥 Écran", "🖥 Schermo", "🖥 Bildschirm", "🖥 Pantalla"],
	"🎮 Juego": ["🎮 Game", "🎮 Jogo", "🎮 Jeu", "🎮 Gioco", "🎮 Spiel", "🎮 Joc"],
	"♿ Accesibilidad": ["♿ Accessibility", "♿ Acessibilidade", "♿ Accessibilité", "♿ Accessibilità", "♿ Barrierefreiheit", "♿ Accessibilitat"],
	"💾 Partida": ["💾 Save game", "💾 Jogo salvo", "💾 Partie", "💾 Partita", "💾 Spielstand", "💾 Partida"],
	"Sonidos del partido": ["Match sounds", "Sons da partida", "Sons du match", "Suoni della partita", "Spielgeräusche", "Sons del partit"],
	"Música": ["Music", "Música", "Musique", "Musica", "Musik", "Música"],
	"Volumen": ["Volume", "Volume", "Volume", "Volume", "Lautstärke", "Volum"],
	"Que la elija el juego": ["Let the game choose", "Deixar o jogo escolher", "Laisser le jeu choisir", "Lascia scegliere al gioco", "Das Spiel wählen lassen", "Que la triï el joc"],
	"Autoguardado": ["Autosave", "Salvamento automático", "Sauvegarde auto", "Salvataggio automatico", "Autospeichern", "Desat automàtic"],
	"Paleta": ["Palette", "Paleta", "Palette", "Palette", "Palette", "Paleta"],
	"Paleta para daltonismo": ["Colour-blind palette", "Paleta para daltonismo", "Palette daltonisme", "Palette per daltonici", "Farbenblind-Palette", "Paleta per a daltonisme"],
	"Forma de las tarjetas": ["Card shape", "Formato dos cartões", "Forme des cartes", "Forma delle schede", "Kartenform", "Forma de les targetes"],
	"Marca de las tarjetas": ["Card mark", "Marca dos cartões", "Marque des cartes", "Marchio delle schede", "Kartenmarkierung", "Marca de les targetes"],
	"Brillo en las tarjetas": ["Card gloss", "Brilho nos cartões", "Brillance des cartes", "Lucentezza delle schede", "Kartenglanz", "Brillantor de les targetes"],
	"Tipografia": ["Typeface", "Tipografia", "Police", "Carattere", "Schriftart", "Tipografia"],
	"Clima encima del fondo": ["Weather over the background", "Clima sobre o fundo", "Météo par-dessus le fond", "Meteo sopra lo sfondo", "Wetter über dem Hintergrund", "Clima sobre el fons"],
	"El clima sigue al ratón": ["Weather follows the mouse", "O clima segue o mouse", "La météo suit la souris", "Il meteo segue il mouse", "Wetter folgt der Maus", "El clima segueix el ratolí"],
	"Tamaño del texto": ["Text size", "Tamanho do texto", "Taille du texte", "Dimensione del testo", "Textgröße", "Mida del text"],
	"Tamaño de la interfaz": ["Interface size", "Tamanho da interface", "Taille de l'interface", "Dimensione dell'interfaccia", "Oberflächengröße", "Mida de la interfície"],
	"Vista compacta": ["Compact view", "Visão compacta", "Vue compacte", "Vista compatta", "Kompakte Ansicht", "Vista compacta"],
	"Pantalla completa": ["Fullscreen", "Tela cheia", "Plein écran", "Schermo intero", "Vollbild", "Pantalla completa"],
	"Calidad gráfica del estadio en 3D": ["3D stadium graphics quality", "Qualidade gráfica do estádio 3D", "Qualité graphique du stade 3D", "Qualità grafica dello stadio 3D", "Grafikqualität des 3D-Stadions", "Qualitat gràfica de l'estadi en 3D"],
	"Censurar los nombres importados": ["Censor imported names", "Censurar nomes importados", "Censurer les noms importés", "Censura i nomi importati", "Importierte Namen zensieren", "Censurar els noms importats"],
	"Idioma": ["Language", "Idioma", "Langue", "Lingua", "Sprache", "Idioma"],
	"Sin fondo (verde plano)": ["No background (flat green)", "Sem fundo (verde liso)", "Sans fond (vert uni)", "Senza sfondo (verde piatto)", "Kein Hintergrund (einfarbig grün)", "Sense fons (verd pla)"],
	"Todas las líneas": ["All lines", "Todas as linhas", "Toutes les lignes", "Tutti i reparti", "Alle Mannschaftsteile", "Totes les línies"],
	"Cómo lo dices:": ["How you say it:", "Como você diz:", "Comment vous le dites :", "Come lo dici:", "Wie du es sagst:", "Com ho dius:"],
	"Activado": ["On", "Ativado", "Activé", "Attivo", "Ein", "Activat"],
	"SÍ": ["YES", "SIM", "OUI", "SÌ", "JA", "SÍ"],
	"NO": ["NO", "NÃO", "NON", "NO", "NEIN", "NO"],
	"MÁX": ["MAX", "MÁX", "MAX", "MAX", "MAX", "MÀX"],
	"gratis": ["free", "grátis", "gratuit", "gratis", "kostenlos", "gratis"],
	"sin límite": ["no limit", "sem limite", "sans limite", "senza limite", "ohne Limit", "sense límit"],
	"al máximo": ["maxed", "no máximo", "au maximum", "al massimo", "am Maximum", "al màxim"],
	"becado": ["scholarship", "bolsista", "boursier", "borsista", "Stipendiat", "becat"],
	"en obra": ["under construction", "em obras", "en travaux", "in costruzione", "im Bau", "en obres"],

	# --- mensajes de estado ---
	"Sin novedades.": ["Nothing new.", "Sem novidades.", "Rien de neuf.", "Nessuna novità.", "Nichts Neues.", "Sense novetats."],
	"Sin títulos todavía.": ["No trophies yet.", "Sem títulos ainda.", "Pas encore de titres.", "Ancora nessun titolo.", "Noch keine Titel.", "Encara sense títols."],
	"Sin leyendas disponibles todavía.": ["No legends available yet.", "Sem lendas disponíveis ainda.", "Aucune légende disponible pour l'instant.", "Nessuna leggenda disponibile.", "Noch keine Legenden verfügbar.", "Encara no hi ha llegendes disponibles."],
	"No queda nada por leer.": ["Nothing left to read.", "Não há mais nada para ler.", "Plus rien à lire.", "Non c'è altro da leggere.", "Nichts mehr zu lesen.", "No queda res per llegir."],
	"Aún sin partidos jugados.": ["No matches played yet.", "Ainda sem partidas jogadas.", "Aucun match joué pour l'instant.", "Ancora nessuna partita giocata.", "Noch keine Spiele absolviert.", "Encara sense partits jugats."],
	"Tu club descansa esta jornada.": ["Your club has a bye this round.", "Seu clube folga nesta rodada.", "Votre club est exempt cette journée.", "Il tuo club riposa in questa giornata.", "Dein Verein hat diese Runde spielfrei.", "El teu club descansa aquesta jornada."],
	"Ya hablasteis": ["You already spoke", "Vocês já conversaram", "Vous avez déjà parlé", "Avete già parlato", "Ihr habt schon gesprochen", "Ja heu parlat"],
	"Foto real del club.": ["Real club photo.", "Foto real do clube.", "Vraie photo du club.", "Foto reale del club.", "Echtes Vereinsfoto.", "Foto real del club."],
	"(sin silueta para este país)": ["(no outline for this country)", "(sem silhueta para este país)", "(pas de silhouette pour ce pays)", "(nessuna sagoma per questo paese)", "(keine Silhouette für dieses Land)", "(sense silueta per a aquest país)"],
	"Últimos hallazgos del modelo:": ["Latest findings from the model:", "Últimas descobertas do modelo:", "Derniers résultats du modèle :", "Ultime scoperte del modello:", "Neueste Erkenntnisse des Modells:", "Darrers descobriments del model:"],
	"Relación tibia con el vecindario.": ["Lukewarm relations with the neighbourhood.", "Relação morna com a vizinhança.", "Relations tièdes avec le quartier.", "Rapporti tiepidi con il quartiere.", "Laues Verhältnis zur Nachbarschaft.", "Relació tèbia amb el veïnat."],
}

## EL DICCIONARIO AMPLIADO (29-9-2026, mapa de metas 17): inglés y portugués
## de Brasil, los dos idiomas que más venden después del castellano. La tabla de
## arriba se queda con las siete columnas del esqueleto; esto es lo demás que se
## VE en la interfaz -medido con `pruebas/recorrido_pantallas.gd`, que recoge
## cada texto de cada pantalla- en `datos/idiomas_extra.json`:
##   {"en": {castellano: inglés}, "pt": {...}, "patrones": [[regex, en, pt]]}
const EXTRA := "res://datos/idiomas_extra.json"
var _extra := {}
var _patrones: Array = []   ## [RegEx, {"en": plantilla, "pt": plantilla}]
var _cache := {}

func _ready() -> void:
	_cargar_extra()

## Traduce un árbol de interfaz entero (etiquetas, botones y ayudas). Para las
## pantallas que no cuelgan de la principal -la Carrera de Jugador, el
## partido jugable-. Guarda el castellano original en el propio nodo para poder
## volver a él o repintar en otro idioma.
func traducir_arbol(n: Node) -> void:
	if idioma == "es":
		return
	if n is Button:
		var b := n as Button
		if not b.has_meta("_i18n_src"):
			b.set_meta("_i18n_src", b.text)
		b.text = t(String(b.get_meta("_i18n_src")))
	elif n is Label:
		var l := n as Label
		if not l.has_meta("_i18n_src") or String(l.get_meta("_i18n_out", "")) != l.text:
			l.set_meta("_i18n_src", l.text)
		l.text = t(String(l.get_meta("_i18n_src")))
		l.set_meta("_i18n_out", l.text)
	if n is Control and (n as Control).tooltip_text != "":
		(n as Control).tooltip_text = t((n as Control).tooltip_text)
	for h in n.get_children():
		traducir_arbol(h)

func _cargar_extra() -> void:
	if not FileAccess.file_exists(EXTRA):
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(EXTRA))
	if not (d is Dictionary):
		return
	for k: String in ["en", "pt"]:
		_extra[k] = (d as Dictionary).get(k, {})
	_patrones.clear()
	for fila: Array in (d as Dictionary).get("patrones", []):
		var re := RegEx.new()
		if re.compile(String(fila[0])) == OK:
			_patrones.append([re, {"en": String(fila[1]), "pt": String(fila[2]) if fila.size() > 2 else ""}])

## Traduce una frase suelta. Si no está en la tabla, devuelve la castellana: una
## interfaz medio traducida se lee; una llena de claves crudas, no.
## En orden: la frase entera; sin el icono o la flecha de los extremos; por
## tramos separados con « · »; y por patrones con números ("Jornada 3 de 30").
func t(frase: String) -> String:
	if idioma == "es" or frase == "":
		return frase
	var cache: Dictionary = _cache.get(idioma, {})
	if cache.has(frase):
		return cache[frase]
	var r := _t(frase, 0)
	cache[frase] = r
	_cache[idioma] = cache
	return r

func _directa(frase: String) -> String:
	var ex: Dictionary = _extra.get(idioma, {})
	if ex.has(frase) and String(ex[frase]) != "":
		return String(ex[frase])
	var i := ORDEN.find(idioma)
	if i >= 0 and TABLA.has(frase):
		var fila: Array = TABLA[frase]
		if i < fila.size() and String(fila[i]) != "":
			return String(fila[i])
	return ""

func _t(frase: String, prof: int) -> String:
	var d := _directa(frase)
	if d != "" or prof > 3:
		return d if d != "" else frase
	## El icono de delante (emoji, flecha) y lo de detrás (▸, :, …) aparte.
	var ini := 0
	while ini < frase.length() and not _es_letra(frase.unicode_at(ini)):
		ini += 1
	var fin := frase.length()
	while fin > ini and not _es_letra(frase.unicode_at(fin - 1)) and frase.unicode_at(fin - 1) != 41:
		fin -= 1
	if ini > 0 or fin < frase.length():
		var medio := frase.substr(ini, fin - ini)
		if medio != "" and medio != frase:
			var tm := _t(medio, prof + 1)
			if tm != medio:
				return frase.substr(0, ini) + tm + frase.substr(fin)
	## Por tramos.
	for sep: String in ["  ·  ", " · ", " — ", " | "]:
		if frase.contains(sep):
			var partes := frase.split(sep)
			var cambio := false
			for k in partes.size():
				var tp := _t(partes[k], prof + 1)
				if tp != partes[k]:
					cambio = true
				partes[k] = tp
			if cambio:
				return sep.join(partes)
	## Por patrones: los grupos con letras también se traducen.
	for par: Array in _patrones:
		var m: RegExMatch = (par[0] as RegEx).search(frase)
		if m == null or m.get_start() != 0 or m.get_end() != frase.length():
			continue
		var plantilla := String((par[1] as Dictionary).get(idioma, ""))
		if plantilla == "":
			continue
		for g in range(m.get_group_count(), 0, -1):
			var v := m.get_string(g)
			if _tiene_letras(v):
				v = _t(v, prof + 1)
			plantilla = plantilla.replace("$%d" % g, v)
		return plantilla
	return frase

static func _es_letra(c: int) -> bool:
	return (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or (c >= 192 and c <= 687) or (c >= 48 and c <= 57) or c == 191 or c == 161

static func _tiene_letras(s: String) -> bool:
	for i in s.length():
		var c := s.unicode_at(i)
		if (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or (c >= 192 and c <= 687):
			return true
	return false

## Cuántas frases hay traducidas a cada idioma. Lo usa la propia pantalla de
## ajustes para decir la verdad sobre la cobertura en vez de prometer un juego
## entero traducido.
func cobertura(cual: String) -> int:
	var i := ORDEN.find(cual)
	if i < 0:
		return TABLA.size()
	var n := 0
	var ex: Dictionary = _extra.get(cual, {})
	for k: String in ex:
		if not TABLA.has(k):
			n += 1
	for k: String in TABLA:
		var fila: Array = TABLA[k]
		if i < fila.size() and String(fila[i]) != "":
			n += 1
	return n
