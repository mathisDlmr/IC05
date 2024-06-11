import sqlite3

conn = sqlite3.connect('films2010s.sqlite')
curseur = conn.cursor()

curseur.execute("""
    SELECT Films.nom FROM Films JOIN genreFilms ON Films.id=genreFilms.film JOIN Genres On Genres.id=genreFilms.genre WHERE Films.pays='India' AND Genres.nom='Western'
""")

rows=curseur.fetchall()
for row in rows:
    print(row)

conn.commit()
conn.close()