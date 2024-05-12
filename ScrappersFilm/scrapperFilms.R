install.packages(c("RCurl", "XML", "RSQLite", "rvest", "jsonlite"))

#Reste à faire : Users, Commentaires

library(RCurl)
library(XML)
library(RSQLite)
library(jsonlite)

conn <- dbConnect(SQLite(), "films.sqlite")

recupererLien <- function(id) {
    query <- "SELECT lien FROM LiensFilms WHERE id = ?;"
    result <- dbGetQuery(conn, query, id)

    if (nrow(result) == 0) {
        return(NULL)
    }

    return(result$lien[1])
}

scrapperInfoBasiques <- function(page, id) {
    nomFilm <- ifelse(length(xpathSApply(page, '//div[@class="details"]/h1/span/text()', xmlValue)) == 0, "NA", xpathSApply(page, '//div[@class="details"]/h1/span/text()', xmlValue))
    annee <- ifelse(length(xpathSApply(page, '//div[@class="releaseyear"]/a/text()', xmlValue)) == 0, -1, xpathSApply(page, '//div[@class="releaseyear"]/a/text()', xmlValue))

    PositionPaysLangue <- xpathSApply(page, '//*[@id="tab-details"]/h3/span/text()', xmlValue)
    
    pays <- NULL
    position <- 1
    positionLangue <- NULL

    for (textPosition in PositionPaysLangue) {
        if (textPosition == "Country") {
            pays <- xpathSApply(page, paste('//*[@id="tab-details"]/div[', position, ']/p/a[1]', sep = ''), xmlValue)
        }

        if(textPosition == "Language") {
            positionLangue <- position
        }

        position <- position + 1
    }

    if (is.null(pays) && !is.null(positionLangue)) {
        pays <- xpathSApply(page, paste('//*[@id="tab-details"]/div[', positionLangue, ']/p/a[1]', sep = ''), xmlValue)
    } else if (is.null(pays) && is.null(positionLangue)) {
        pays <- "NA"
    }

    dbExecute(conn, "INSERT INTO Films (id, nom, annee, pays) VALUES (?, ?, ?, ?)", params = c(id, nomFilm, annee, pays))
    print("Info Basiques OK")
}


scrapperInfoJSON <- function(page, id) {
    jsonScript <- xpathSApply(page, '//script[@type="application/ld+json"]', xmlValue)
    filmJson <- fromJSON(jsonScript)
    note <- filmJson$aggregateRating$ratingValue

    if (length(note) == 0) {
        note <- -1
    }

    dbExecute(conn, "UPDATE Films SET note = ? WHERE id = ?", params = c(note, id))
    print("Info JSON OK")
}

scrapperInfoJS <- function(link, id) {
    remDr$navigate(link)
    Sys.sleep(2)

    convertK <- function(x) {
        if(grepl("K", x)) {
            return(as.numeric(sub("K", "", x)) * 1000)
        } else {
            return(as.numeric(x))
        }
    }

    vues <- ifelse(length(remDr$findElement(using = "xpath", value = "//li[@class='stat filmstat-watches']/a")) == 0, -1, {
        vues <- remDr$findElement(using = "xpath", value = "//li[@class='stat filmstat-watches']/a")
        vues <- vues$getElementText()
        vues <- unlist(vues)
        convertK(vues)
    })
    
    likes <- ifelse(length(remDr$findElement(using = "xpath", value = "//li[@class='stat filmstat-likes']/a")) == 0, -1, {
        likes <- remDr$findElement(using = "xpath", value = "//li[@class='stat filmstat-likes']/a")
        likes <- likes$getElementText()
        likes <- unlist(likes)
        convertK(likes)
    })
    
    dbExecute(conn, "UPDATE Films SET vues = ?, likes = ? WHERE id = ?", params = c(vues, likes, id))

    print("Info JS OK")
}

scrapperRealisateur <- function(page, id) {
    realisateurLien <- ifelse(length(xpathApply(page, '//p[@class="credits"]/span[2]/a', xmlAttrs)) == 0, "NA", {
        realisateurLien <- xpathApply(page, '//p[@class="credits"]/span[2]/a', xmlAttrs)[[1]]
        realisateurLien[['href']]
    })

    nom <- ifelse(length(xpathSApply(page, '//p[@class="credits"]/span[2]/a/span/text()', xmlValue)) == 0, "NA", {
        realisateur <- xpathSApply(page, '//p[@class="credits"]/span[2]/a/span/text()', xmlValue)
        nomSplit <- strsplit(realisateur, " ")
        nomSplit[[1]][1]
    })

    prenom <- ifelse(length(xpathSApply(page, '//p[@class="credits"]/span[2]/a/span/text()', xmlValue)) == 0, "NA", {
        realisateur <- xpathSApply(page, '//p[@class="credits"]/span[2]/a/span/text()', xmlValue)
        nomSplit <- strsplit(realisateur, " ")
        paste(nomSplit[[1]][-1], collapse = " ")
    })

    query <- "SELECT id FROM Realisateurs WHERE nom = ? AND prenom = ?;"
    result <- dbGetQuery(conn, query, params = c(nom, prenom))
    idReal <- result$id[1]

    if (nrow(result) == 0) {
        queryMaxID <- "SELECT MAX(id) FROM Realisateurs;"
        maxIDResult <- dbGetQuery(conn, queryMaxID)
        maxID <- maxIDResult[[1]]

        if (is.na(maxID)) {
            maxID <- 0
        }

        idReal <- maxID + 1

        dbExecute(conn, "INSERT INTO Realisateurs (id, nom, prenom, page) VALUES (?, ?, ?, ?);", params = c(idReal, nom, prenom, realisateurLien))
    }
    
    dbExecute(conn, "UPDATE Films SET realisateur = ? WHERE id = ?", params = c(idReal, id))

    print("Info Realisateur OK")
}

scrapperGenre <- function(page, id) {
    genres <- xpathApply(page, '//div[@class="text-sluglist capitalize"]/p/a/text()', xmlValue)
    for (genre in genres) {
        queryGenre <- "SELECT id FROM Genres WHERE nom = ?;"
        result <- dbGetQuery(conn, queryGenre, genre)
        idGenre <- result$id[1]

        if (nrow(result) == 0) {
            queryMaxID <- "SELECT MAX(id) FROM Genres;"
            maxIDResult <- dbGetQuery(conn, queryMaxID)
            maxID <- maxIDResult[[1]]

            if (is.na(maxID)) {
                maxID <- 0
            }

            idGenre <- maxID + 1

            dbExecute(conn, "INSERT INTO Genres (id, nom) VALUES (?, ?);", params = c(idGenre, genre))
        } else {
            idGenre <- result$id[1]
        }

        dbExecute(conn, "INSERT INTO genreFilms (film, genre) VALUES (?, ?);", params = c(id, idGenre))
    }
    print("Info Genre OK")
}

scrapperActeurs <- function(page, id) {
    acteurs <- xpathApply(page, '//div[@class="cast-list text-sluglist"]/p/a/text()', xmlValue)
    for (acteur in acteurs) {
        nom <- ifelse(length(strsplit(acteur, " ")[[1]]) == 0, "NA", {
            nomSplit <- strsplit(acteur, " ")
            nomSplit[[1]][1]
        })

        prenom <- ifelse(length(strsplit(acteur, " ")[[1]]) == 0, "NA", {
            nomSplit <- strsplit(acteur, " ")
            paste(nomSplit[[1]][-1], collapse = " ")
        })

        query <- "SELECT id FROM Acteurs WHERE nom = ? AND prenom = ?;"
        result <- dbGetQuery(conn, query, params = c(nom, prenom))
        idActeur <- result$id[1]

        if (nrow(result) == 0) {
            queryMaxID <- "SELECT MAX(id) FROM Acteurs;"
            maxIDResult <- dbGetQuery(conn, queryMaxID)
            maxID <- maxIDResult[[1]]

            if (is.na(maxID)) {
                maxID <- 0
            }

            idActeur <- maxID + 1

            dbExecute(conn, "INSERT INTO Acteurs (id, nom, prenom) VALUES (?, ?, ?);", params = c(idActeur, nom, prenom))
        }

        query2 <- "SELECT film FROM Jouer WHERE film = ? AND acteur = ?;"
        result2 <- dbGetQuery(conn, query2, params = c(id, idActeur))

        if (nrow(result2) == 0) {
            dbExecute(conn, "INSERT INTO Jouer (film, acteur) VALUES (?, ?);", params = c(id, idActeur))
        }
    }
    print("Info Acteurs OK")
}

scrapper <- function(link, id) {
    print(id)
    page <- htmlParse(getURL(link, ssl.verifypeer = FALSE)) #Ctrl+F pour vérifier la syntaxe des XPath
    scrapperInfoBasiques(page, id)
    scrapperInfoJSON(page, id)
    scrapperRealisateur(page, id)
    scrapperGenre(page, id)
    scrapperActeurs(page, id)
}

i <- 141527 #Clé primaire incrémentée à la main pour la stocker en variable et reprendre le script de n'importe où
while (i < 533918) {
    tryCatch({
        lienFilm <- recupererLien(i)

        if (is.null(lienFilm)) {
            print("Fin du programme")
            break
        }

        page <- htmlParse(getURL(lienFilm, ssl.verifypeer = FALSE))
        nom <- xpathSApply(page, '//div[@class="details"]/h1/span/text()', xmlValue)
        query <- "SELECT id FROM Films WHERE nom = ?;"
        result <- dbGetQuery(conn, query, nom)

        if (nrow(result) == 0) {
            scrapper(lienFilm, i)
        }

    }, error = function(e) {
        print(paste(i, " : ",e))  
    })
    
    i <- i + 1
}

dbDisconnect(conn)