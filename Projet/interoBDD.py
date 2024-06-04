import sqlite3
import csv

conn = sqlite3.connect('films2010s.sqlite')
cursor = conn.cursor()

cursor.execute(f"SELECT themeFilms.film, Themes.nom FROM themeFilms JOIN Themes ON themeFilms.theme=Themes.id JOIN Films ON themeFilms.film=Films.id WHERE Films.note!=-1")
with open('themeFilms2.csv', 'w', newline='', encoding='utf-8') as csvfile:
    csv_writer = csv.writer(csvfile)
    csv_writer.writerow([i[0] for i in cursor.description])
    csv_writer.writerows(cursor)

conn.close()

print("Conversion terminée.")
