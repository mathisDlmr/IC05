install.packages(c("RCurl", "XML", "RSQLite", "rvest"))

library(RCurl)
library(XML)
library(RSQLite)
library(rvest)

conn <- dbConnect(SQLite(), "films.sqlite")

recupererLien <- function(id) {
  query <- "SELECT lien FROM LiensFilms WHERE id = ?;"
  result <- dbGetQuery(conn, query, id)
  if (nrow(result) == 0) {
    return(NULL)
  }
  return(result$lien[1])
}

scrapper <- function(link, id) {
  page <- htmlParse(getURL(link, ssl.verifypeer = F))
  nomFilm <- xpathSApply(page, '//*[@id="featured-film-header"]/h1', xmlValue)
  annee <-xpathSApply(page, '//*[@id="featured-film-header"]/p/small/a', xmlValue)
  realisateurLien <- xpathApply(page, "//section[@id='featured-film-header']/p/a", xmlAttrs)[[1]]
  realisateurLien <- realisateurLien[['href']]
  realisateur <-xpathSApply(page, "//section[@id='featured-film-header']/p/a/span", xmlValue)
  pays <- xpathSApply(page, '//*[@id="tab-details"]/div[2]/p/a', xmlValue)
  note <- xpathSApply(page, '//*[@id="film-page-wrapper"]/div[2]/aside/section[2]/span/a/text()', xmlValue)
  vues <- xpathSApply(page, '//*[@id="js-poster-col"]/section[1]/ul/li[1]/a/text()', xmlValue)
  likes <- xpathSApply(page, '//*[@id="js-poster-col"]/section[1]/ul/li[3]/a/text()', xmlValue)

  print(link)
  #print(page)
  print(nomFilm)
  print(annee)
  print(realisateurLien)
  print(realisateur)

  #dbExecute(conn, "INSERT INTO Films (nom, annee, realisateur, pays) VALUES (?, ?, ?, ?)",
            #nomFilm, annee, realisateur, pays)
}

i <- 1
while (i<3) {
  lienFilm <- recupererLien(i)
  if (is.null(lienFilm)) {
    print("Fin du programme")
    break
  }
  scrapper(lienFilm)
  i <- i + 1
}

dbDisconnect(conn)
