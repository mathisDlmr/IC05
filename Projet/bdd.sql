DROP TABLE IF EXISTS Realisateurs;
DROP TABLE IF EXISTS Films;
DROP TABLE IF EXISTS Acteurs;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Commentaires;

CREATE TABLE Realisateurs (
    id INTEGER AUTO_INCREMENT,
    nom VARCHAR(32) NOT NULL,
    prenom VARCHAR(32) NOT NULL,
    PRIMARY KEY(id)
);

CREATE TABLE Genres (
    nom VARCHAR(32),
    PRIMARY KEY(nom)
);

CREATE TABLE Films (
    nom VARCHAR(64),
    annee INTEGER(4) NOT NULL,
    realisateur INTEGER NOT NULL,
    pays VARCHAR(32),
    note FLOAT(3),                     /* Vérifier la taille du float */
    vues INTEGER(9),
    likes INTEGER(9),
    PRIMARY KEY(nom),                  /* On suppose que les films ont un nom unique */
    FOREIGN KEY(realisateur) REFERENCES Realisateurs
);

CREATE TABLE genreFilms (
    film VARCHAR(64),
    genre VARCHAR(32),
    PRIMARY KEY(film, genre),
    FOREIGN KEY(film) REFERENCES Films,
    FOREIGN KEY(genre) REFERENCES Genres
);

CREATE TABLE Acteurs (
    id INTEGER AUTO_INCREMENT,
    nom VARCHAR(32) NOT NULL,
    prenom VARCHAR(32) NOT NULL,
    PRIMARY KEY(id)
);

CREATE TABLE Jouer (
    film VARCHAR(64),
    acteur INTEGER,
    PRIMARY KEY(film, acteur)
    FOREIGN KEY(film) REFERENCES Films,
    FOREIGN KEY(acteur) REFERENCES Acteurs
);

CREATE TABLE Users (
    username VARCHAR(64),
    pays VARCHAR(32),                   /* Créer une table Pays ? */
    PRIMARY KEY(username)
);

CREATE TABLE Commentaires (
    film VARCHAR(64),
    commentateur VARCHAR(64),
    note FLOAT(3),
    date DATE,
    likes INTEGER(6),
    PRIMARY KEY(film, commentateur),
    FOREIGN KEY(film) REFERENCES Films,
    FOREIGN KEY(commentateur) REFERENCES Users
);