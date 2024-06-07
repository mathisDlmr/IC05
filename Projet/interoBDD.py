import sqlite3

conn = sqlite3.connect('films2010s.sqlite')
cursor = conn.cursor()

#Acteurs classés en fonction des notes moyennes des films dans lesquels ils ont joué
create_view_query = """     
CREATE VIEW IF NOT EXISTS noteMoyenneActeur AS
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
ORDER BY
    noteMoy DESC
"""
cursor.execute(create_view_query)
conn.commit()

#Thèmes avec le plus de films
create_view_query = """     
CREATE VIEW themesLesPlusCommuns AS
SELECT
    t.nom AS Theme,
    COUNT(tf.film) AS NombreDeFilms
FROM
    Themes t
JOIN
    themeFilms tf ON t.id = tf.theme
GROUP BY
    t.nom
ORDER BY
    NombreDeFilms DESC;
"""
cursor.execute(create_view_query)
conn.commit()

#Genres classés en fonction de la note moyenne des films qui l'ont pour genre
create_view_query = """     
CREATE VIEW genresQuiMarchentLeMieux AS
SELECT
    g.nom AS Genre,
    AVG(f.note) AS NoteMoyenne
FROM
    Genres g
JOIN
    genreFilms gf ON g.id = gf.genre
JOIN
    Films f ON gf.film = f.id
GROUP BY
    g.nom
ORDER BY
    NoteMoyenne DESC;
"""
cursor.execute(create_view_query)
conn.commit()

#La proportion des Genres par année pour voir l'évolution de la popularité des genres
create_view_query = """     
CREATE VIEW proportionGenresParAnnee AS
SELECT
    f.annee AS Annee,
    g.nom AS Genre,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY f.annee) AS Proportion
FROM
    Films f
JOIN
    genreFilms gf ON f.id = gf.film
JOIN
    Genres g ON gf.genre = g.id
GROUP BY
    f.annee, g.nom
ORDER BY
    f.annee, Proportion DESC;
"""
cursor.execute(create_view_query)
conn.commit()

#Réalisateurs avec le plus de films
create_view_query = """     
CREATE VIEW realisateursLesPlusProlifiques AS
SELECT
    r.prenom || ' ' || r.nom AS Realisateur,
    COUNT(f.id) AS NombreDeFilms
FROM
    Realisateurs r
JOIN
    Films f ON r.id = f.realisateur
GROUP BY
    r.id
ORDER BY
    NombreDeFilms DESC;
"""
cursor.execute(create_view_query)
conn.commit()

#Films les plus populaires par pays
create_view_query = """     
CREATE VIEW filmsLesPlusPopulairesParPays AS
SELECT
    f.pays AS Pays,
    AVG(f.note) AS NoteMoyenne
FROM
    Films f
GROUP BY
    f.pays
ORDER BY
    NoteMoyenne DESC;
"""
cursor.execute(create_view_query)
conn.commit()

test_query = "SELECT * FROM noteMoyenneActeur ORDER BY noteMoy DESC LIMIT 10"
cursor.execute(test_query)
results = cursor.fetchall()

for row in results:
    print(row)

conn.close()