import sqlite3

conn = sqlite3.connect('films.sqlite')
curseur = conn.cursor()

curseur.execute("SELECT COUNT(*) FROM Films WHERE id NOT IN (SELECT film FROM genreFilms)")

nombre_de_lignes = curseur.fetchone()[0]
print("Nombre de lignes :", nombre_de_lignes)

conn.close()
