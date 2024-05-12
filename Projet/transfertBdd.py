import sqlite3

conn_src = sqlite3.connect('films copy 2.sqlite')
cursor_src = conn_src.cursor()

conn_dest = sqlite3.connect('films.sqlite')
cursor_dest = conn_dest.cursor()

tables_to_transfer = ['LiensFilms', 'Realisateurs', 'Genres', 'Films', 'genreFilms', 'Acteurs', 'Jouer', 'Users', 'Commentaires']

def entry_exists(cursor, table, id_value):
    if (table in ('LiensFilms', 'Realisateurs', 'Genres', 'Films', 'Acteurs', 'Users', 'Commentaires')):
        cursor.execute(f"SELECT id FROM {table} WHERE id=?", (id_value,))
    elif (table in ('genreFilms', 'Jouer')):
        cursor.execute(f"SELECT film, acteur FROM {table} WHERE id=?", (id_value,))

    return cursor.fetchone() is not None

def transfer_data(src_cursor, dest_cursor, table):
    try:
        src_cursor.execute(f"SELECT * FROM {table}")
        data = src_cursor.fetchall()
        for row in data:
            if (table in ('LiensFilms', 'Realisateurs', 'Genres', 'Films', 'Acteurs', 'Users', 'Commentaires')):
                id_value = row[0]
                if not entry_exists(dest_cursor, table, id_value):
                    dest_cursor.execute(f"INSERT INTO {table} VALUES ({', '.join(['?' for _ in range(len(row))])})", row)
            elif (table in ('genreFilms', 'Jouer')):
                id_values = row[:2]  # Les IDs sont les deux premiers éléments dans chaque ligne de genreFilms et Jouer
                if not entry_exists(dest_cursor, table, id_values):
                    dest_cursor.execute(f"INSERT INTO {table} VALUES ({', '.join(['?' for _ in range(len(row))])})", row)
    except Exception as e:
        print(f"Erreur lors du transfert des données de la table {table} : {e}")

for table in tables_to_transfer:
    transfer_data(cursor_src, cursor_dest, table)

conn_dest.commit()
conn_src.close()
conn_dest.close()

print("Transfert de données terminé.")
