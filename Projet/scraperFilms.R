install.packages(c("RCurl", "XML", "RSQLite", "rvest", "jsonlite", "RSelenium"))

#Reste à faire : Users, Commentaires

library(RCurl)
library(XML)
library(RSQLite)
library(jsonlite)
library(RSelenium)

conn <- dbConnect(SQLite(), "films.sqlite")

Sys.setenv(JAVA_HOME = "C:\\Program Files\\Java\\jre-1.8\\bin")
driver <- rsDriver(browser="firefox", port=4420L, verbose=F, chromever = NULL)
remDr <- driver[["client"]]

recupererLien <- function(id) {
  query <- "SELECT lien FROM LiensFilms WHERE id = ?;"
  result <- dbGetQuery(conn, query, id)
  if (nrow(result) == 0) {
    return(NULL)
  }
  return(result$lien[1])
}

scrapperInfoBasiques <- function(page, id) {
  nomFilm <- xpathSApply(page, '//div[@class="details"]/h1/span/text()', xmlValue)   #Ctrl+F pour vérifier la syntaxe
  annee <-xpathSApply(page, '//div[@class="releaseyear"]/a/text()', xmlValue)
  pays <- xpathSApply(page, '//*[@id="tab-details"]/div[2]/p/a', xmlValue)

  dbExecute(conn, "INSERT INTO Films (id, nom, annee, pays) VALUES (?, ?, ?, ?)", id, nomFilm, annee, pays)
}

scrapperInfoJSON <- function(page, id) {
  jsonScript <- xpathSApply(page, '//script[@type="application/ld+json"]', xmlValue)
  filmJson <- fromJSON(jsonScript)
  note <- filmJson$aggregateRating$ratingValue

  dbExecute(conn, "UPDATE Films SET note = ? WHERE id = ?", note, id)
}

scrapperInfoJS <- function(page, link, id) {
  remDr$navigate(link)
  Sys.sleep(5)
  vues <- remDr$findElement(using = "xpath", value = "//li[@class='stat filmstat-watches']/a")
  vues <- vues$getElementText()
  vues <- unlist(vues)

  likes <- remDr$findElement(using = "xpath", value = "//li[@class='stat filmstat-likes']/a")
  likes <- likes$getElementText()
  likes <- unlist(likes)

  dbExecute(conn, "UPDATE Films SET vues = ?, likes = ? WHERE id = ?", vues, likes, id)
}

scrapperRealisateur <- function(page, id) {
  realisateurLien <- xpathApply(page, '//p[@class="credits"]/span[2]/a', xmlAttrs)[[1]]
  realisateurLien <- realisateurLien[['href']]
  realisateur <-xpathSApply(page, '//p[@class="credits"]/span[2]/a/span/text()', xmlValue)
  nomSplit <- strsplit(realisateur, " ")
  nom <- nomSplit[[1]][1]
  prenom <- nomSplit[[1]][2]

  query <- "SELECT id FROM Realisateurs WHERE nom = ? AND prenom = ?;"
  result <- dbGetQuery(conn, query, nom, prenom)

  if (nrow(result) == 0) {
    dbExecute(conn, "INSERT INTO Realisateurs (nom, prenom, page) VALUES (?, ?, ?);", nom, prenom, realisateurLien)
    result <- dbGetQuery(conn, query, nom, prenom)
  }

  idReal <- result$id[1]
  dbExecute(conn, "UPDATE Films SET realisateur = ? WHERE id = ?", idReal, id)

}

scrapperGenre <- function(page, id) {
  genres <- xpathApply(page, '//div[@class="text-sluglist capitalize"]/p/a/text()', xmlValue)
    for (genre in genres) {
      query <- "SELECT id FROM Genres WHERE nom = ?;"
      result <- dbGetQuery(conn, query, genre)

      if (nrow(result) == 0) {
        dbExecute(conn, "INSERT INTO Genres (nom) VALUES (?);", genre)
        result <- dbGetQuery(conn, query, genre)
      }

      idGenre <- result$id[1]
      dbExecute(conn, "INSERT INTO genreFilms (film, genre) VALUES (?, ?);", id, idGenre)
    }
}

scrapperActeurs <- function(page, id) {
  acteurs <- xpathApply(page, '//div[@class="cast-list text-sluglist"]/p/a/text()', xmlValue)
    for (acteur in acteurs) {
      nomSplit <- strsplit(acteur, " ")
      nom <- nomSplit[[1]][1]
      prenom <- nomSplit[[1]][2]
      query <- "SELECT id FROM Acteurs WHERE nom = ? AND prenom = ?;"
      result <- dbGetQuery(conn, query, nom, prenom)

      if (nrow(result) == 0) {
        dbExecute(conn, "INSERT INTO Acteurs (nom, prenom) VALUES (?, ?);", nom, prenom)
        result <- dbGetQuery(conn, query, nom, prenom)
      }

      idActeur <- result$id[1]
      dbExecute(conn, "INSERT INTO Jouer (film, acteur) VALUES (?, ?);", id, idActeur)
    }
}

scrapper <- function(link, id) {
  page <- htmlParse(getURL(link, ssl.verifypeer = FALSE)) #Ctrl+F pour vérifier la syntaxe des XPath
  scrapperInfoBasiques(page, id)
  scrapperInfoJSON(page, id)
  scrapperInfoJS(page, link, id)
  scrapperRealisateur(page, id)
  scrapperGenre(page, id)
  scrapperActeurs(page, id)
}

i <- 1 #Clé primaire incrémentée à la main pour la stocker en variable
while (i<10) {
  lienFilm <- recupererLien(i)
  if (is.null(lienFilm)) {
    print("Fin du programme")
    break
  }
  scrapper(lienFilm, i)
  i <- i + 1
}

dbDisconnect(conn)