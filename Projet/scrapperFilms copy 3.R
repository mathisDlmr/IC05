install.packages(c("RCurl", "XML", "RSQLite", "RSelenium", "jsonlite"))

library(RCurl)
library(XML)
library(RSQLite)
library(RSelenium)
library(jsonlite)

conn <- dbConnect(SQLite(), "films2010s copy 3.sqlite")

Sys.setenv(JAVA_HOME = "C:\\Program Files\\Java\\jre-1.8\\bin")
driver <- rsDriver(browser = "firefox", port = 4438L, verbose = F, chromever = NULL)
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
    nbNotes <- filmJson$aggregateRating$reviewCount 

    if (length(note) == 0) {
        note <- -1
    }

    if (length(nbNotes) == 0) {
        nbNotes <- -1
    }

    dbExecute(conn, "UPDATE Films SET note = ?, nbNotes = ? WHERE id = ?", params = c(note, nbNotes, id))
    print("Info JSON OK")
}

scrapperInfoJS <- function(link, id) {
    remDr$navigate(link)
    Sys.sleep(2)

    convertK <- function(x) {
        num <- as.numeric(sub("[^0-9.]", "", x))
        if (grepl("k", x, fixed = TRUE)) {
            num <- num * 1000
        }
        return(num)
    }

    vues <- ifelse(length(remDr$findElement(using = "xpath", value = "//li[@class='stat filmstat-watches']/a")) == 0, -1, {
        tryCatch({
            vues <- remDr$findElement(using = "xpath", value = "//li[@class='stat filmstat-watches']/a")
            vues <- vues$getElementText()
            vues <- unlist(vues)
            convertK(vues)
            dbExecute(conn, "UPDATE Films SET vues = ? WHERE id = ?", params = c(vues, id))
        }, error = function(e) {
            print("----- Vues pas trouvés.")
        })
    })
    
    likes <- ifelse(length(remDr$findElement(using = "xpath", value = "//li[@class='stat filmstat-likes']/a")) == 0, -1, {
        tryCatch({
            likes <- remDr$findElement(using = "xpath", value = "//li[@class='stat filmstat-likes']/a")
            likes <- likes$getElementText()
            likes <- unlist(likes)
            convertK(likes)
            dbExecute(conn, "UPDATE Films SET likes = ? WHERE id = ?", params = c(likes, id))
        }, error = function(e) {
            print("----- Likes pas trouvés.")
        })
    })

    fans <- ifelse(length(remDr$findElement(using = "xpath", value = '//section[@class="section ratings-histogram-chart"]/a')) == 0, -1, {
        tryCatch({
            fans <- remDr$findElement(using = "xpath", value = '//section[@class="section ratings-histogram-chart"]/a')
            fans <- fans$getElementText()
            fans <- unlist(fans)
            convertK(fans)
            dbExecute(conn, "UPDATE Films SET fans = ? WHERE id = ?", params = c(fans, id))

        }, error = function(e) {
            print("----- Fans pas trouvés.")
            fans <- -1
        })
    })
    
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
    genres <- xpathApply(page, '//div[@class="text-sluglist capitalize"][1]/p/a/text()', xmlValue)
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

scrapperTheme <- function(page, id) {
    themes <- xpathApply(page, '//div[@class="text-sluglist capitalize"][2]/p/a/text()', xmlValue)
    for (theme in themes) {
        queryTheme <- "SELECT id FROM Themes WHERE nom = ?;"
        result <- dbGetQuery(conn, queryTheme, theme)
        idTheme <- result$id[1]

        if (nrow(result) == 0) {
            queryMaxID <- "SELECT MAX(id) FROM Themes;"
            maxIDResult <- dbGetQuery(conn, queryMaxID)
            maxID <- maxIDResult[[1]]

            if (is.na(maxID)) {
                maxID <- 0
            }

            idTheme <- maxID + 1

            dbExecute(conn, "INSERT INTO Themes (id, nom) VALUES (?, ?);", params = c(idTheme, theme))
        } else {
            idTheme <- result$id[1]
        }

        dbExecute(conn, "INSERT INTO themeFilms (film, theme) VALUES (?, ?);", params = c(id, idTheme))
    }
    print("Info Thèmes OK")
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

    tryCatch({
        scrapperInfoBasiques(page, id)
    }, error = function(e) {
        print(paste("Erreur Info Basiques", e))  
    })

    tryCatch({
        scrapperInfoJSON(page, id)
    }, error = function(e) {
        print(paste("Erreur Info JSON", e))  
    })

    tryCatch({
        scrapperInfoJS(link, id)
    }, error = function(e) {
        print(paste("Erreur Info JavaScript", e))  
    })

    tryCatch({
        scrapperRealisateur(page, id)
    }, error = function(e) {
        print(paste("Erreur Info Réalisateur", e))  
    })

    tryCatch({
        scrapperGenre(page, id)
    }, error = function(e) {
        print(paste("Erreur Info Genre", e))  
    })

    tryCatch({
        scrapperTheme(page, id)
    }, error = function(e) {
        print(paste("Erreur Info Thèmes", e))  
    })

    tryCatch({
        scrapperActeurs(page, id)
    }, error = function(e) {
        print(paste("Erreur Info Acteurs", e))  
    })
}

i <- 184302 #Clé primaire incrémentée à la main pour la stocker en variable et reprendre le script de n'importe où
while (i < 248961) {
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
    
    i <- i + 10
}

dbDisconnect(conn)