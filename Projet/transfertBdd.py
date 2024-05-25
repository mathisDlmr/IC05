import sqlite3

# Connexion aux deux bases de données
source_conn = sqlite3.connect('films2010s copy 2.sqlite')
source_curseur = source_conn.cursor()
dest_conn = sqlite3.connect('films2010s.sqlite')
dest_curseur = dest_conn.cursor()

# Fonction pour obtenir le prochain ID disponible
def get_next_id(table_name):
    dest_curseur.execute(f'SELECT MAX(id) FROM {table_name}')
    row = dest_curseur.fetchone()
    return (row[0] or 0) + 1

# Fonction pour obtenir ou insérer un réalisateur et retourner son ID
def get_or_insert_realisateur(nom, prenom, page):
    dest_curseur.execute('SELECT id FROM Realisateurs WHERE nom = ? AND prenom = ?', (nom, prenom))
    row = dest_curseur.fetchone()
    if row:
        return row[0]
    else:
        new_id = get_next_id('Realisateurs')
        dest_curseur.execute('INSERT INTO Realisateurs (id, nom, prenom, page) VALUES (?, ?, ?, ?)', (new_id, nom, prenom, page))
        dest_conn.commit()
        return new_id

# Fonction pour obtenir ou insérer un acteur et retourner son ID
def get_or_insert_acteur(nom, prenom, page):
    dest_curseur.execute('SELECT id FROM Acteurs WHERE nom = ? AND prenom = ?', (nom, prenom))
    row = dest_curseur.fetchone()
    if row:
        return row[0]
    else:
        new_id = get_next_id('Acteurs')
        dest_curseur.execute('INSERT INTO Acteurs (id, nom, prenom, page) VALUES (?, ?, ?, ?)', (new_id, nom, prenom, page))
        dest_conn.commit()
        return new_id

# Fonction pour obtenir ou insérer un thème et retourner son ID
def get_or_insert_theme(nom):
    dest_curseur.execute('SELECT id FROM Themes WHERE nom = ?', (nom,))
    row = dest_curseur.fetchone()
    if row:
        return row[0]
    else:
        new_id = get_next_id('Themes')
        dest_curseur.execute('INSERT INTO Themes (id, nom) VALUES (?, ?)', (new_id, nom))
        dest_conn.commit()
        return new_id

# Fonction pour obtenir ou insérer un genre et retourner son ID
def get_or_insert_genre(nom):
    dest_curseur.execute('SELECT id FROM Genres WHERE nom = ?', (nom,))
    row = dest_curseur.fetchone()
    if row:
        return row[0]
    else:
        new_id = get_next_id('Genres')
        dest_curseur.execute('INSERT INTO Genres (id, nom) VALUES (?, ?)', (new_id, nom))
        dest_conn.commit()
        return new_id

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

    dest_curseur.execute('SELECT id FROM Films WHERE id = ?', (film_id,))
    row = dest_curseur.fetchone()
    if row:
        print(f"Le film {film_id} était déjà dans la BDD")
    else:
        # Récupérer l'ID du réalisateur dans la base de données de destination
        source_curseur.execute('SELECT nom, prenom FROM Realisateurs WHERE id = ?', (realisateur,))
        realisateur_row = source_curseur.fetchone()
        if realisateur_row:
            nom_realisateur, prenom_realisateur = realisateur_row
            realisateur_id = get_or_insert_realisateur(nom_realisateur, prenom_realisateur, None)
            
            # Insérer le film dans la base de données de destination
            dest_curseur.execute('''
            INSERT INTO Films (id, nom, annee, realisateur, pays, note, nbNotes, vues, fans, likes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            ''', (film_id, nom, annee, realisateur_id, pays, note, nbNotes, vues, fans, likes))
            dest_conn.commit()
        else:
            print(f"Réalisateur ID {realisateur} non trouvé pour le film {film_id}")

# Transférer les relations entre films et acteurs (table Jouer)
source_curseur.execute('SELECT film, acteur FROM Jouer')
jouer = source_curseur.fetchall()
for film, acteur in jouer:
    # Récupérer l'ID de l'acteur dans la base de données de destination
    source_curseur.execute('SELECT nom, prenom FROM Acteurs WHERE id = ?', (acteur,))
    acteur_row = source_curseur.fetchone()
    if acteur_row:
        nom_acteur, prenom_acteur = acteur_row
        acteur_id = get_or_insert_acteur(nom_acteur, prenom_acteur, None)

        dest_curseur.execute('SELECT film, acteur FROM Jouer WHERE film = ? AND acteur = ?', (film, acteur_id))
        row = dest_curseur.fetchone()
        if row:
            print(f"La relation film-acteur ({film}, {acteur_id}) était déjà dans la BDD")
        else:
            # Insérer la relation dans la base de données de destination
            dest_curseur.execute('''
            INSERT INTO Jouer (film, acteur) VALUES (?, ?);
            ''', (film, acteur_id))
            dest_conn.commit()
    else:
        print(f"Acteur ID {acteur} non trouvé pour le film {film}")

# Transférer les relations entre films et genres (table genreFilms)
source_curseur.execute('SELECT film, genre FROM genreFilms')
genre_films = source_curseur.fetchall()
for film, genre in genre_films:
    # Récupérer l'ID du genre dans la base de données de destination
    source_curseur.execute('SELECT nom FROM Genres WHERE id = ?', (genre,))
    genre_row = source_curseur.fetchone()
    if genre_row:
        (nom_genre,) = genre_row
        genre_id = get_or_insert_genre(nom_genre)

        dest_curseur.execute('SELECT film, genre FROM genreFilms WHERE film = ? AND genre = ?', (film, genre_id))
        row = dest_curseur.fetchone()
        if row:
            print(f"La relation film-genre ({film}, {genre_id}) était déjà dans la BDD")
        else:
            # Insérer la relation dans la base de données de destination
            dest_curseur.execute('''
            INSERT INTO genreFilms (film, genre) VALUES (?, ?);
            ''', (film, genre_id))
            dest_conn.commit()
    else:
        print(f"Genre ID {genre} non trouvé pour le film {film}")

# Transférer les relations entre films et thèmes (table themeFilms)
source_curseur.execute('SELECT film, theme FROM themeFilms')
theme_films = source_curseur.fetchall()
for film, theme in theme_films:
    # Récupérer l'ID du thème dans la base de données de destination
    source_curseur.execute('SELECT nom FROM Themes WHERE id = ?', (theme,))
    theme_row = source_curseur.fetchone()
    if theme_row:
        (nom_theme,) = theme_row
        theme_id = get_or_insert_theme(nom_theme)

        dest_curseur.execute('SELECT film, theme FROM themeFilms WHERE film = ? AND theme = ?', (film, theme_id))
        row = dest_curseur.fetchone()
        if row:
            print(f"La relation film-thème ({film}, {theme_id}) était déjà dans la BDD")
        else:
            # Insérer la relation dans la base de données de destination
            dest_curseur.execute('''
            INSERT INTO themeFilms (film, theme) VALUES (?, ?);
            ''', (film, theme_id))
            dest_conn.commit()
    else:
        print(f"Thème ID {theme} non trouvé pour le film {film}")

# Fermeture des connexions
source_conn.close()
dest_conn.close()
