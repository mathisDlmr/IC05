install.packages(c("RCurl", "XML", "RSQLite", "rvest"))

library(RCurl)
library(XML)
library(RSQLite)
library(rvest)

conn <- dbConnect(SQLite(), "films.sqlite")

recupererLien <- function() {
  query <- "SELECT lien FROM LiensFilms;"
  result <- dbGetQuery(conn, query)
  # Si aucun résultat n'est retourné, cela signifie que la table est vide
  if (nrow(result) == 0) {
    return(NULL)
  }
  return(result$lien[1])
}

scrapper <- function(link, id) {
  page <- htmlParse(getURL(link, ssl.verifypeer = F))
  nomFilm <- xpathSApply(page, "//h1[@class = 'headline-1']", xmlValue)       #Vérifier les xpath
  annee <-xpathSApply(page, "//smal[@class='number']/a/text()", xmlValue)
  realisateurLien <-xpathSApply(page, "//section[@id='featured-film-header']/p/a]", xmlValue)    #Vérifier qu'on récupère bien le href
  realisateur <-xpathSApply(page, "//section[@id='featured-film-header']/p/a/span]", xmlValue)
  pays <- xpathSApply(page, "//ul[@class='relase-country-list']/li/span/span[@class='details']/span", xmlValue)    #récupérer que le premier pays (ou il est sorti)
  note <- xpathSApply(page, "//li[@class='filmstat-watches'/a/text()]", xmlValue)
  vues <- xpathSApply(page, "//li[@class='filmstat-lists'/a/text()]", xmlValue)
  likes <- xpathSApply(page, "//li[@class='filmstat-likes'/a/text()]", xmlValue)
  dbExecute(conn, "INSERT INTO Films (nom) VALUES (?)", nomFilm)
}

while (TRUE) {
  lienFilm <- recupererLien()
  if (is.null(lienFilm)) {
    print("La base de données est vide.")
    break
  }
  scrapper(lienFilm)
}

dbDisconnect(conn)
