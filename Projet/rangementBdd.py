import sqlite3

def rangement():
    conn = sqlite3.connect('films2010s.sqlite')
    curseur = conn.cursor()

    curseur.execute("""
        DELETE FROM Jouer WHERE film>8300 AND film NOT LIKE '%0';
    """)

    curseur.execute("""
        DELETE FROM genreFilms WHERE film>8300 AND film NOT LIKE '%0';
    """)

    curseur.execute("""
        DELETE FROM themeFilms WHERE film>8300 AND film NOT LIKE '%0';
    """)

    curseur.execute("""
        DELETE FROM Films WHERE id>8300 AND id NOT LIKE '%0';
    """)    
    


    query_themes_duplicates = '''
    SELECT MIN(id) as id_to_keep, nom
    FROM Themes
    GROUP BY nom
    HAVING COUNT(*) > 1;
    '''
    curseur.execute(query_themes_duplicates)
    themes_duplicates = curseur.fetchall()

    for id_to_keep, nom in themes_duplicates:
        curseur.execute('''
        UPDATE themeFilms
        SET theme = ?
        WHERE theme IN (
            SELECT id FROM Themes
            WHERE nom = ?
            AND id != ?
        );
        ''', (id_to_keep, nom, id_to_keep))

    for id_to_keep, nom in themes_duplicates:
        curseur.execute('''
        DELETE FROM Themes
        WHERE nom = ? AND id != ?;
        ''', (nom, id_to_keep))



    # Suppression des doublons dans la table Genres
    query_genres_duplicates = '''
    SELECT MIN(id) as id_to_keep, nom
    FROM Genres
    GROUP BY nom
    HAVING COUNT(*) > 1;
    '''
    curseur.execute(query_genres_duplicates)
    genres_duplicates = curseur.fetchall()

    for id_to_keep, nom in genres_duplicates:
        curseur.execute('''
        UPDATE genreFilms
        SET genre = ?
        WHERE genre IN (
            SELECT id FROM Genres
            WHERE nom = ?
            AND id != ?
        );
        ''', (id_to_keep, nom, id_to_keep))

    for id_to_keep, nom in genres_duplicates:
        curseur.execute('''
        DELETE FROM Genres
        WHERE nom = ? AND id != ?;
        ''', (nom, id_to_keep))




    # Suppression des doublons dans la table Themes
    query_themes_duplicates = '''
    SELECT MIN(id) as id_to_keep, nom
    FROM Themes
    GROUP BY nom
    HAVING COUNT(*) > 1;
    '''
    curseur.execute(query_themes_duplicates)
    themes_duplicates = curseur.fetchall()

    for id_to_keep, nom in themes_duplicates:
        curseur.execute('''
        UPDATE themeFilms
        SET theme = ?
        WHERE theme IN (
            SELECT id FROM Themes
            WHERE nom = ?
            AND id != ?
        );
        ''', (id_to_keep, nom, id_to_keep))

    for id_to_keep, nom in themes_duplicates:
        curseur.execute('''
        DELETE FROM Themes
        WHERE nom = ? AND id != ?;
        ''', (nom, id_to_keep))





    # Suppression des doublons dans la table Genres
    query_genres_duplicates = '''
    SELECT MIN(id) as id_to_keep, nom
    FROM Genres
    GROUP BY nom
    HAVING COUNT(*) > 1;
    '''
    curseur.execute(query_genres_duplicates)
    genres_duplicates = curseur.fetchall()

    for id_to_keep, nom in genres_duplicates:
        curseur.execute('''
        UPDATE genreFilms
        SET genre = ?
        WHERE genre IN (
            SELECT id FROM Genres
            WHERE nom = ?
            AND id != ?
        );
        ''', (id_to_keep, nom, id_to_keep))

    for id_to_keep, nom in genres_duplicates:
        curseur.execute('''
        DELETE FROM Genres
        WHERE nom = ? AND id != ?;
        ''', (nom, id_to_keep))



    # Suppression des doublons dans la table Realisateurs
    query_realisateurs_duplicates = '''
    SELECT MIN(id) as id_to_keep, nom, prenom
    FROM Realisateurs
    GROUP BY nom, prenom
    HAVING COUNT(*) > 1;
    '''
    curseur.execute(query_realisateurs_duplicates)
    realisateurs_duplicates = curseur.fetchall()

    for id_to_keep, nom, prenom in realisateurs_duplicates:
        curseur.execute('''
        UPDATE Films
        SET realisateur = ?
        WHERE realisateur IN (
            SELECT id FROM Realisateurs
            WHERE nom = ? AND prenom = ?
            AND id != ?
        );
        ''', (id_to_keep, nom, prenom, id_to_keep))

    for id_to_keep, nom, prenom in realisateurs_duplicates:
        curseur.execute('''
        DELETE FROM Realisateurs
        WHERE nom = ? AND prenom = ? AND id != ?;
        ''', (nom, prenom, id_to_keep))




    # Suppression des doublons dans la table Acteurs
    query_acteurs_duplicates = '''
    SELECT MIN(id) as id_to_keep, nom, prenom
    FROM Acteurs
    GROUP BY nom, prenom
    HAVING COUNT(*) > 1;
    '''
    curseur.execute(query_acteurs_duplicates)
    acteurs_duplicates = curseur.fetchall()

    for id_to_keep, nom, prenom in acteurs_duplicates:
        curseur.execute('''
        UPDATE Jouer
        SET acteur = ?
        WHERE acteur IN (
            SELECT id FROM Acteurs
            WHERE nom = ? AND prenom = ?
            AND id != ?
        );
        ''', (id_to_keep, nom, prenom, id_to_keep))

    for id_to_keep, nom, prenom in acteurs_duplicates:
        curseur.execute('''
        DELETE FROM Acteurs
        WHERE nom = ? AND prenom = ? AND id != ?;
        ''', (nom, prenom, id_to_keep))

    conn.commit()
    conn.close()

def lireLiensFilms(base_de_donnees):
    conn = sqlite3.connect(base_de_donnees)
    curseur = conn.cursor()
    curseur.execute("SELECT lien FROM LiensFilms;")
    liens = curseur.fetchall()
    conn.close()
    return liens

def transfertLiensFilms():
    liens = lireLiensFilms('films2020s.sqlite')

    conn = sqlite3.connect('films.sqlite')
    curseur = conn.cursor()
    curseur.execute("CREATE TABLE IF NOT EXISTS LiensFilms (id INTEGER PRIMARY KEY, lien TEXT NOT NULL);")

    i = 367258
    for lien in liens:
        curseur.execute("INSERT INTO LiensFilms VALUES (?, ?);", (i, lien[0]))
        i += 1
    conn.commit()
    conn.close()


rangement()