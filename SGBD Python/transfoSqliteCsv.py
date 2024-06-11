import sqlite3
import csv

conn = sqlite3.connect('films2010s.sqlite')
cursor = conn.cursor()

cursor.execute(f"SELECT genreFilms.film, Genres.nom FROM genreFilms JOIN Genres ON genreFilms.genre=Genres.id JOIN Films ON genreFilms.film=Films.id WHERE Films.note!=-1 AND Films.pays='USA'")
with open('genreFilms2U.csv', 'w', newline='', encoding='utf-8') as csvfile:
    csv_writer = csv.writer(csvfile)
    csv_writer.writerow([i[0] for i in cursor.description])
    csv_writer.writerows(cursor)

conn.close()

print("Conversion terminée.")