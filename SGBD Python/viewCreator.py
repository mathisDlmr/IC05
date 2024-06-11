import sqlite3
import csv

conn = sqlite3.connect('films2010s.sqlite')
cursor = conn.cursor()

#Acteurs classés en fonction des notes moyennes des films dans lesquels ils ont joué
create_view_query = """     
CREATE VIEW noteMoyenneActeur AS
SELECT 
    Acteurs.prenom || ' ' || Acteurs.nom AS Acteur, 
    AVG(Films.note) AS noteMoy
FROM 
    Acteurs 
JOIN 
    Jouer ON Acteurs.id = Jouer.acteur 
JOIN 
    Films ON Jouer.film = Films.id
GROUP BY 
    Acteurs.id
HAVING 
    COUNT(Films.id)>5
ORDER BY
    noteMoy DESC
"""
cursor.execute(create_view_query)
conn.commit()

cursor.execute(f"SELECT * FROM noteMoyenneActeur ORDER BY noteMoy DESC")
with open("noteMoyActeur.csv", 'w', newline='', encoding='utf-8') as csvfile:
    csv_writer = csv.writer(csvfile)
    csv_writer.writerow([i[0] for i in cursor.description])
    csv_writer.writerows(cursor)

conn.close()