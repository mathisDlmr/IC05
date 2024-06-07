DROP TABLE IF EXISTS LiensFilms;
DROP TABLE IF EXISTS Realisateurs;
DROP TABLE IF EXISTS Genres;
DROP TABLE IF EXISTS Thèmes;
DROP TABLE IF EXISTS Films;
DROP TABLE IF EXISTS genreFilms;
DROP TABLE IF EXISTS themeFilms;
DROP TABLE IF EXISTS Acteurs;
DROP TABLE IF EXISTS Jouer;

CREATE TABLE LiensFilms (
    id INTEGER PRIMARY KEY,
    lien TEXT NOT NULL
);

CREATE TABLE Realisateurs (
    id INTEGER AUTO_INCREMENT,
    nom VARCHAR(32),
    prenom VARCHAR(32),
    page TEXT,
    PRIMARY KEY(id)
);

CREATE TABLE Genres (
    id INTEGER AUTO_INCREMENT,
    nom VARCHAR(32),
    PRIMARY KEY(id)
);

CREATE TABLE Themes (
    id INTEGER AUTO_INCREMENT,
    nom VARCHAR(32),
    PRIMARY KEY(id)
);

CREATE TABLE Films (
    id INTEGER,
    nom VARCHAR(64),
    annee INTEGER(4),
    realisateur INTEGER,
    pays VARCHAR(32),
    note DECIMAL(1,2),
    nbNotes INTEGER(9),
    vues INTEGER(9),
    fans INTEGER(9),
    likes INTEGER(9),
    PRIMARY KEY(id),
    FOREIGN KEY(realisateur) REFERENCES Realisateurs
);

CREATE TABLE genreFilms (
    film INTEGER,
    genre INTEGER,
    PRIMARY KEY(film, genre),
    FOREIGN KEY(film) REFERENCES Films,
    FOREIGN KEY(genre) REFERENCES Genres
);

CREATE TABLE themeFilms (
    film INTEGER,
    theme INTEGER,
    PRIMARY KEY(film, theme),
    FOREIGN KEY(film) REFERENCES Films,
    FOREIGN KEY(theme) REFERENCES Themes
);

CREATE TABLE Acteurs (
    id INTEGER AUTO_INCREMENT,
    nom VARCHAR(32),
    prenom VARCHAR(32),
    page TEXT,
    PRIMARY KEY(id)
);

CREATE TABLE Jouer (
    film INTEGER,
    acteur INTEGER,
    PRIMARY KEY(film, acteur)
    FOREIGN KEY(film) REFERENCES Films,
    FOREIGN KEY(acteur) REFERENCES Acteurs
);