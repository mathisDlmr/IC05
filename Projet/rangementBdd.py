import sqlite3

def rangement():
    conn = sqlite3.connect('films2010s.sqlite')
    curseur = conn.cursor()

    curseur.execute("""
        DELETE FROM Films WHERE id=4361;
    """)

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