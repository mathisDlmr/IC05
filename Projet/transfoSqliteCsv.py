import sqlite3
import csv

conn = sqlite3.connect('films.sqlite')
cursor = conn.cursor()

def table_to_csv(table_name, csv_file_name):
    cursor.execute(f"SELECT * FROM {table_name}")
    with open(csv_file_name, 'w', newline='', encoding='utf-8') as csvfile:
        csv_writer = csv.writer(csvfile)
        csv_writer.writerow([i[0] for i in cursor.description])
        csv_writer.writerows(cursor)

tables = ['LiensFilms', 'Realisateurs', 'Genres', 'Films', 'genreFilms', 'Acteurs', 'Jouer', 'Users', 'Commentaires']

for table in tables:
    table_to_csv(table, f'{table}.csv')

conn.close()

print("Conversion terminée.")
