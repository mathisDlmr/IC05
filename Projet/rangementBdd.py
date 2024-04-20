import sqlite3

def lire_liens_film(base_de_donnees):
    conn = sqlite3.connect(base_de_donnees)
    curseur = conn.cursor()
    curseur.execute("SELECT lien FROM LiensFilms;")
    liens = curseur.fetchall()
    conn.close()
    return liens

liens = lire_liens_film('films2020s.sqlite')

conn = sqlite3.connect('films.sqlite')
curseur = conn.cursor()
curseur.execute("CREATE TABLE IF NOT EXISTS LiensFilms (id INTEGER PRIMARY KEY, lien TEXT NOT NULL);")
i = 367258
for lien in liens:
    curseur.execute("INSERT INTO LiensFilms VALUES (?, ?);", (i, lien[0]))
    i += 1
conn.commit()
conn.close()
