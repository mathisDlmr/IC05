################TD n°2################
### Collecter des donnees en ligne ###

install.packages(c("RCurl","XML" ))

library(RCurl)          #Recuperer des pages URL
library(XML)            #Parser : parcourir un texte Html pour en extraire des �l�ments

# Partie 1 - Créer une base de données sur les députés ----
###1a/ Pour récupérer le code une page web : la fonction getURL ----
page<-getURL("https://www.nosdeputes.fr/deputes", ssl.verifypeer=FALSE)

###1b/ Enregistrer la page dans son répertoire (fonction writeLines) ----

###1c/ Parser la page (fonction "htmlParse") ----
page<-htmlParse(page)
page<-htmlParse(getURL("https://www.nosdeputes.fr/deputes", ssl.verifypeer=FALSE))

##2// Sélectionner les données ----
###2a/ Ecrire l'expression Xpath qui permet d'obtenir le nom de tous les députés ----
noms<-xpathSApply(page, "//div[@class='list_dep jstitle phototitle block']/span[@class='list_nom']", xmlValue)
partis<-xpathSApply(page, "//div[@class='list_dep jstitle phototitle block']/span[@class='list_left']/span", xmlValue)

###2b/ Ecrire l'expression Xpath qui permet d'obtenir la circonscription d'origine ----
circonscriptions<-xpathSApply(page, "//div[@class='list_dep jstitle phototitle block']/span[@class='list_right'][1]", xmlValue)  #Attention, on ne veut que le premier élément

###2c/ Créer une base de donn�es des d�put�s avec trois variables ----
deputes<-as.data.frame(cbind(noms, partis, circonscriptions)) #Dataframe pour garder les noms de colonnes
deputes

##3/ Automatisation de la collecte sur plusieurs pages ----
adresses<-xpathSApply(page, "//div[@class='list_dep jstitle phototitle block']/span[@class='urlphoto']", xmlGetAttr, "title")
adressesWebs<-paste0("https://www.nosdeputes.fr", adresses)

for (i in 1:577) {
  pageDepute <- htmlParse(getURL(adressesWebs[i], ssl.verifypeer = F))
  deputes$profession[i] <- xpathSApply(pageDepute, "//li[contains (text(), 'Profession :')]", xmlValue)
  deputes$amendements[i] <- xpathSApply(pageDepute, "//div[@class='barre_activite']//li[6]/a/text()", xmlValue)
  deputes$semainesPresent[i] <- xpathSApply(pageDepute, "//div[@class='barre_activite']//li[1]/a/text()", xmlValue)
}

###3a/ Chercher la profession du Député Damien Abad. Créer un objet R avec cette information. ----

###3b/ Chercher le nombre d'amendements déposés par le député Damien Abad. Créer un objet avec cette information. ----

###3c/ Vérifier que le chemin défini fonctionne pour la page de la députée Caroline Abadie ----

###3d/ Créer un objet avec les adresses de toutes les pages personnelles des députés ----

###3e/ Créer une boucle pour récupérer les professions et le nombre d'amendements pour tous les députés ----
