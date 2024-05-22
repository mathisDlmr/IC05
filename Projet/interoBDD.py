import sqlite3

conn = sqlite3.connect('films2010s.sqlite')
curseur = conn.cursor()

curseur.execute("SELECT nom, prenom FROM Acteurs WHERE id IN(SELECT acteur FROM Jouer JOIN Films ON Jouer.film=Films.id WHERE nom='Khola Hawa')")

result = curseur.fetchall()
for row in result:
    print(row)

conn.close()
