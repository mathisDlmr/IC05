install.packages(c("RCurl","XML","tidyverse","RSelenium", "DBI", "RSQLite"))
library(RCurl)
library(XML)
library(tidyverse)
library(RSelenium)
library(DBI)
library(RSQLite)

# Définir le chemin d'accès à Java
Sys.setenv(JAVA_HOME = "C:\\Program Files\\Java\\jre-1.8\\bin")

# Démarrer le serveur Selenium
rd <- rsDriver(browser="firefox", port=4441L, verbose=F, chromever = NULL)
client <- rd$client
client$open()
client$navigate("https://letterboxd.com/films/decade/2000s/by/release-earliest/page/999/")

# Connexion à la base de données SQLite
conn <- DBI::dbConnect(RSQLite::SQLite(), "films2000s.sqlite")

# Créer la table LiensFilms si elle n'existe pas
DBI::dbExecute(conn, "CREATE TABLE IF NOT EXISTS LiensFilms (
                        id INTEGER PRIMARY KEY,
                        lien TEXT NOT NULL
                      );")

# Extraire les liens et les insérer dans la base de données
for (i in 1:1644) {  #1644 en 2000s ; 3467 en 2010s ; 2316 en 2020s
  elements <- client$findElements(using = "xpath", "//a[@class='frame']")
  for (element in elements) {
    lien <- element$getElementAttribute("href")
    # Insérer chaque lien dans la base de données
    DBI::dbExecute(conn, "INSERT INTO LiensFilms (lien) VALUES (?)", lien)
  }
  next_button <- client$findElement(using = "xpath", "//a[@class='next']")
  if (!is.null(next_button)) {
    next_button$clickElement()
    Sys.sleep(5)
  } else {
    break  # Sortir de la boucle si le bouton "next" n'est pas trouvé
  }
}

# Déconnexion de la base de données
DBI::dbDisconnect(conn)
