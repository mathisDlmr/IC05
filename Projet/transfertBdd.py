import sqlite3

conn_src = sqlite3.connect('films2010s.sqlite')
cursor_src = conn_src.cursor()

conn_dest = sqlite3.connect('films2010s copy 10.sqlite')
cursor_dest = conn_dest.cursor()

tables_to_transfer = ['LiensFilms', 'Realisateurs', 'Genres', 'Films', 'Acteurs', 'Themes', 'themeFilms', 'genreFilms', 'Jouer']

def entry_exists(cursor, table, id_value, id_value2):
    if (table in ('LiensFilms', 'Realisateurs', 'Genres', 'Films', 'Acteurs', 'Themes')):
        cursor.execute(f"SELECT id FROM {table} WHERE id=?", (id_value,))
    elif (table == 'Jouer'):
        cursor.execute(f"SELECT film, acteur FROM {table} WHERE film=? AND acteur=?", (id_value, id_value2))
    elif (table == 'themeFilms'):
        cursor.execute(f"SELECT film, theme FROM {table} WHERE film=? AND theme=?", (id_value, id_value2))
    elif (table == 'genreFilms'):
        cursor.execute(f"SELECT film, genre FROM {table} WHERE film=? AND genre=?", (id_value, id_value2))

    return cursor.fetchone() is not None

def transfer_data(src_cursor, dest_cursor, table):
    try:
        src_cursor.execute(f"SELECT * FROM {table}")
        data = src_cursor.fetchall()
        for row in data:
            if (table in ('LiensFilms', 'Realisateurs', 'Genres', 'Films', 'Acteurs', 'Themes')):
                id_value = row[0]
                if not entry_exists(dest_cursor, table, id_value, 0):
                    dest_cursor.execute(f"INSERT INTO {table} VALUES ({', '.join(['?' for _ in range(len(row))])})", row)
            elif (table in ('themeFilms', 'genreFilms', 'Jouer')):
                id_values = row[:2]  # Les IDs sont les deux premiers éléments dans chaque ligne de genreFilms et Jouer
                if not entry_exists(dest_cursor, table, id_values[0], id_values[1]):
                    dest_cursor.execute(f"INSERT INTO {table} VALUES ({', '.join(['?' for _ in range(len(row))])})", row)
    except Exception as e:
        print(f"Erreur lors du transfert des données de la table {table} : {e}")

for table in tables_to_transfer:
    transfer_data(cursor_src, cursor_dest, table)

conn_dest.commit()
conn_src.close()
conn_dest.close()

print("Transfert de données terminé.")
