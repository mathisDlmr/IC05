# Introduction à R
# Anne BELLON



## R comme calculatrice
1 + 2
37 * 496
2^10

#############################
##### Création d'objets et arithmétique vectorielle

a<-1:10 ## initialisation d'un vecteur de 1 à 10
a ##Imprimer a
a<-c(1,2,3,5,7,11) ## initialisation d'un vecteur de nombres premiers
a+2 ## ajoute deux à chaque élément du vecteur
a*2 ## multiplie chaque élément par deux

b<-c("IC05", "Analyse", "critique", "de", "données", "numérique")
## initalisation d'un vecteur de mots

mode(a)   ##Type des vecteurs
mode(b)

## matrices
m <- matrix(a, nrow = 2, ncol = 3)
m
##les opérateurs arithmétiques de base s'appliquent aux matrices
m * 3
m ^ 2

##Eliminer les trois dernières colonnes pour avoir une matrice carrée
m <- m[,-3]
t(m) ## transposée de la matrice

## Listes

x <- list(UV = c("IC05","S0O7"), user = "Joe", GI = TRUE)
x
x$UV    ##$ permet d'indexer
x[[3]]

## data.frame
base<-rbind(a,b) ## collage de vecteurs par ligne
base<-cbind(a,b) ## collage de vecteurs par colonnes 
base<-as.data.frame(base)
base[1,] ##indiçage de la première ligne
base[2,2] ## indiçage de l'élement de la deuxième ligne, deuxième colonne

#### Enregistrer des objets
write.csv(base,"mapremierebase.csv")
rm(base)


### Liste des objets dans l'espace de travail.
ls()

### Nettoyage.
rm(a,m)

#### Pour nettoyer tout son environnement de travail
rm(list=ls())

###################################
###Explorer une base de données : la base iris

head(iris)                 ##Affiche les données
mean(iris$Sepal.Width)     ##Moyenne
summary(iris)              ##Un peu toutes les données utiles

#
## Importer, exporter des données
data(iris)

write.csv(iris, "iris-file.csv")

iris <- read.csv("iris-file.csv")

###########
#L'indexation 
# Pour prendre les iris dont le sepal.length est > 5
# 1. On fait une condition 
iris$Sepal.Length > 5
# 2. On la repasse en ligne du dataframe
iris[iris$Sepal.Length > 5, ]
iris2 <- iris[iris$Species == "setosa", ]

#Deux conditions
iris4 <- iris[(iris$Species == "setosa") & (iris$Sepal.Length > 5), ]


#######Visualiser les données

plot(iris$Sepal.Length, iris$Petal.Length)
hist(iris$Sepal.Length)

##### Installer et charger une librairie

install.packages("swirl")
library(swirl)

swirl()
bye()
