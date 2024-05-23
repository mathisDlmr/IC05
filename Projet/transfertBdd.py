import sqlite3

# Connexion aux deux bases de données
source_conn = sqlite3.connect('films2010s copy 2.sqlite')
source_curseur = source_conn.cursor()
dest_conn = sqlite3.connect('films2010s.sqlite')
dest_curseur = dest_conn.cursor()

# Fonction pour obtenir ou insérer un réalisateur et retourner son ID
def get_or_insert_realisateur(nom, prenom, page):
    dest_curseur.execute('''
    SELECT id FROM Realisateurs WHERE nom = ? AND prenom = ?;
    ''', (nom, prenom))
    row = dest_curseur.fetchone()
    if row:
        return row[0]
    else:
        dest_curseur.execute('''
        INSERT INTO Realisateurs (nom, prenom, page) VALUES (?, ?, ?);
        ''', (nom, prenom, page))
        dest_conn.commit()
        return dest_curseur.lastrowid

# Fonction pour obtenir ou insérer un acteur et retourner son ID
def get_or_insert_acteur(nom, prenom, page):
    dest_curseur.execute('''
    SELECT id FROM Acteurs WHERE nom = ? AND prenom = ?;
    ''', (nom, prenom))
    row = dest_curseur.fetchone()
    if row:
        return row[0]
    else:
        dest_curseur.execute('''
        INSERT INTO Acteurs (nom, prenom, page) VALUES (?, ?, ?);
        ''', (nom, prenom, page))
        dest_conn.commit()
        return dest_curseur.lastrowid

# Fonction pour obtenir ou insérer un thème et retourner son ID
def get_or_insert_theme(nom):
    dest_curseur.execute('''
    SELECT id FROM Themes WHERE nom = ?;
    ''', (nom,))
    row = dest_curseur.fetchone()
    if row:
        return row[0]
    else:
        dest_curseur.execute('''
        INSERT INTO Themes (nom) VALUES (?);
        ''', (nom,))
        dest_conn.commit()
        return dest_curseur.lastrowid

# Fonction pour obtenir ou insérer un genre et retourner son ID
def get_or_insert_genre(nom):
    dest_curseur.execute('''
    SELECT id FROM Genres WHERE nom = ?;
    ''', (nom,))
    row = dest_curseur.fetchone()
    if row:
        return row[0]
    else:
        dest_curseur.execute('''
        INSERT INTO Genres (nom) VALUES (?);
        ''', (nom,))
        dest_conn.commit()
        return dest_curseur.lastrowid

# Transférer les réalisateurs
source_curseur.execute('SELECT nom, prenom, page FROM Realisateurs')
realisateurs = source_curseur.fetchall()
for nom, prenom, page in realisateurs:
    get_or_insert_realisateur(nom, prenom, page)

# Transférer les acteurs
source_curseur.execute('SELECT nom, prenom, page FROM Acteurs')
acteurs = source_curseur.fetchall()
for nom, prenom, page in acteurs:
    get_or_insert_acteur(nom, prenom, page)

# Transférer les thèmes
source_curseur.execute('SELECT nom FROM Themes')
themes = source_curseur.fetchall()
for (nom,) in themes:
    get_or_insert_theme(nom)

# Transférer les genres
source_curseur.execute('SELECT nom FROM Genres')
genres = source_curseur.fetchall()
for (nom,) in genres:
    get_or_insert_genre(nom)

# Transférer les films
source_curseur.execute('SELECT id, nom, annee, realisateur, pays, note, nbNotes, vues, fans, likes FROM Films')
films = source_curseur.fetchall()
for film in films:
    film_id, nom, annee, realisateur, pays, note, nbNotes, vues, fans, likes = film
    # Récupérer l'ID du réalisateur dans la base de données de destination
    source_curseur.execute('SELECT nom, prenom FROM Realisateurs WHERE id = ?', (realisateur,))
    nom_realisateur, prenom_realisateur = source_curseur.fetchone()
    realisateur_id = get_or_insert_realisateur(nom_realisateur, prenom_realisateur, None)
    
    # Insérer le film dans la base de données de destination
    dest_curseur.execute('''
    INSERT INTO Films (id, nom, annee, realisateur, pays, note, nbNotes, vues, fans, likes)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''', (film_id, nom, annee, realisateur_id, pays, note, nbNotes, vues, fans, likes))
    dest_conn.commit()

# Transférer les relations entre films et acteurs (table Jouer)
source_curseur.execute('SELECT film, acteur FROM Jouer')
jouer = source_curseur.fetchall()
for film, acteur in jouer:
    # Récupérer l'ID de l'acteur dans la base de données de destination
    source_curseur.execute('SELECT nom, prenom FROM Acteurs WHERE id = ?', (acteur,))
    nom_acteur, prenom_acteur = source_curseur.fetchone()
    acteur_id = get_or_insert_acteur(nom_acteur, prenom_acteur, None)
    
    # Insérer la relation dans la base de données de destination
    dest_curseur.execute('''
    INSERT INTO Jouer (film, acteur) VALUES (?, ?);
    ''', (film, acteur_id))
    dest_conn.commit()

# Transférer les relations entre films et genres (table genreFilms)
source_curseur.execute('SELECT film, genre FROM genreFilms')
genre_films = source_curseur.fetchall()
for film, genre in genre_films:
    # Récupérer l'ID du genre dans la base de données de destination
    source_curseur.execute('SELECT nom FROM Genres WHERE id = ?', (genre,))
    (nom_genre,) = source_curseur.fetchone()
    genre_id = get_or_insert_genre(nom_genre)
    
    # Insérer la relation dans la base de données de destination
    dest_curseur.execute('''
    INSERT INTO genreFilms (film, genre) VALUES (?, ?);
    ''', (film, genre_id))
    dest_conn.commit()

# Transférer les relations entre films et thèmes (table themeFilms)
source_curseur.execute('SELECT film, theme FROM themeFilms')
theme_films = source_curseur.fetchall()
for film, theme in theme_films:
    # Récupérer l'ID du thème dans la base de données de destination
    source_curseur.execute('SELECT nom FROM Themes WHERE id = ?', (theme,))
    (nom_theme,) = source_curseur.fetchone()
    theme_id = get_or_insert_theme(nom_theme)
    
    # Insérer la relation dans la base de données de destination
    dest_curseur.execute('''
    INSERT INTO themeFilms (film, theme) VALUES (?, ?);
    ''', (film, theme_id))
    dest_conn.commit()

# Fermeture des connexions
source_conn.close()
dest_conn.close()
