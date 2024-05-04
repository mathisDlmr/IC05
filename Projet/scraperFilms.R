install.packages(c("RCurl", "XML", "RSQLite", "rvest", "jsonlite", "RSelenium"))

#Reste à faire : Genres, Acteurs, Jouer, (Users, Commentaires)

library(RCurl)
library(XML)
library(RSQLite)
library(jsonlite)
library(RSelenium)

conn <- dbConnect(SQLite(), "films.sqlite")

Sys.setenv(JAVA_HOME = "C:\\Program Files\\Java\\jre-1.8\\bin")
driver <- rsDriver(browser="firefox", port=4435L, verbose=F, chromever = NULL)
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

  #dbExecute(conn, "INSERT INTO Films (id, nom, annee, pays) VALUES (?, ?, ?, ?)", id, nomFilm, annee, pays)
}

scrapperInfoJSON <- function(page, id) {
  jsonScript <- xpathSApply(page, '//script[@type="application/ld+json"]', xmlValue)
  filmJson <- fromJSON(jsonScript)
  note <- filmJson$aggregateRating$ratingValue

  #dbExecute(conn, "UPDATE Films SET note = ? WHERE id = ?", note, id)
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

  #dbExecute(conn, "UPDATE Films SET vues = ?, likes = ? WHERE id = ?", vues, likes, id)
}

scrapperRealisateur <- function(page, id) {
  realisateurLien <- xpathApply(page, '//p[@class="credits"]/span[2]/a', xmlAttrs)[[1]]
  realisateurLien <- realisateurLien[['href']]
  realisateur <-xpathSApply(page, '//p[@class="credits"]/span[2]/a/span/text()', xmlValue)
  nomSplit <- strsplit(realisateur, " ")
  nom <- nomSplit[[1]][1]
  prenom <- nomSplit[[1]][2]

  #query <- "SELECT id FROM Realisateurs WHERE nom = ? AND prenom = ?;"
  #result <- dbGetQuery(conn, query, nom, prenom)

  if (nrow(result) == 0) {
    #dbExecute(conn, "INSERT INTO Realisateurs (nom, prenom, page) VALUES (?, ?, ?);", nom, prenom, realisateurLien)
    #result <- dbGetQuery(conn, query, nom, prenom)
  }

  #idReal <- result$id[1]
  #dbExecute(conn, "UPDATE Films SET realisateur = ? WHERE id = ?", idReal, id)

}

scrapper <- function(link, id) {
  page <- htmlParse(getURL(link, ssl.verifypeer = FALSE)) #Ctrl+F pour vérifier la syntaxe des XPath
  scrapperInfoBasiques(page, id)
  scrapperInfoJSON(page, id)
  scrapperInfoJS(page, link, id)
  scrapperRealisateur(page, id)
}

i <- 1 #Clé primaire incrémentée à la main pour la stocker en variable
while (TRUE) {
  lienFilm <- recupererLien(i)
  if (is.null(lienFilm)) {
    print("Fin du programme")
    break
  }
  scrapper(lienFilm)
  i <- i + 1
}

dbDisconnect(conn)